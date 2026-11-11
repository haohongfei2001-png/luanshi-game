extends SceneTree
## Same deployment, seed, input, clock and close-contact sample window on both runs.
const Battle := preload("res://scripts/field/battle.gd")
const Ground := preload("res://scripts/field/ground.gd")
const Traffic := preload("res://scripts/field/formation_traffic.gd")
const FIRST_SAMPLE := 100
const LAST_SAMPLE := 620
const PERIOD := 10
const OVERLAP := 0.52
var failures: Array[String] = []

func check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
		push_error(message)

func _initialize() -> void:
	_check_passages()
	_check_serving_crew()
	_check_gate_leaves()
	var old := _siege(false)
	var current := _siege(true)
	print("FIELD_TRAFFIC_AB " + JSON.stringify({"seed": Battle.SEED, "window_ticks": [FIRST_SAMPLE, LAST_SAMPLE],
			"every_ticks": PERIOD, "overlap_m": OVERLAP, "before": old, "after": current}))
	check(old.samples == current.samples and current.samples == 53, "Identical congestion observation window")
	check(current.hull_occupant_samples < old.hull_occupant_samples, "Fewer living bodies overlapping the wooden chassis")
	check(current.peak_3m_square < old.peak_3m_square, "Smaller bulk concentration in a three-metre patch; nearby fighting pairs remain allowed")
	for row: Dictionary in [old, current]:
		check(row.ordinary == [512, 512], "Both samples retain ordinary soldier identities")
		check(row.hits[0] > 0 and row.hits[1] > 0 and row.dead[0] > 0 and row.dead[1] > 0, "Attacker and defender exchange real damage")
		check(row.wall_defenders > 0 and row.breach > row.gate_contact and row.gate_contact > 0, "Defended gate damaged and breached in natural simulation")
		check(row.ram_farthest_x > 27.0, "Living engineers advanced the real ram")
	print("FIELD_TRAFFIC_" + ("PASS" if failures.is_empty() else "FAIL") + " " + JSON.stringify(failures))
	quit(0 if failures.is_empty() else 1)

func _check_passages() -> void:
	var lanes := {}
	for landmark: Vector2 in [Vector2(Ground.RIVER_X, 35), Ground.GATE]:
		for dir: float in [-1.0, 1.0]:
			for file: float in [-5.5, -2.4, 0.8, 5.5]:
				var p := landmark + Vector2(-dir * 15.0, dir * 9.0)
				var goal := landmark + Vector2(dir * 14.0, dir * -8.0)
				var crossed := false
				for t in 380:
					var next := Traffic.waypoint(p, goal, file, 4, true)
					var q := Ground.travel(p, p.direction_to(next) * minf(p.distance_to(next), 0.19), true)
					if (p.x - landmark.x) * dir < 0.0 and (q.x - landmark.x) * dir >= 0.0:
						crossed = true
						lanes[Vector3i(int(landmark.x), int(dir), roundi(q.y - landmark.y))] = true
					p = q
					if p.distance_to(goal) < 0.3: break
				check(crossed and p.distance_to(goal) < 0.3, "Movement crosses the physical passage and reaches its destination")
	check(lanes.size() >= 12, "Traversing troops use distinct lateral files in both directions")
	for file: float in [-5.5, -1.8, 0.8, 5.5]:
		for dir: float in [-1.0, 1.0]:
			var parked := Ground.GATE - Vector2(3.05, 0)
			var p := Ground.GATE + Vector2(-dir * 15.0, dir * 7.0)
			var goal := Ground.GATE + Vector2(dir * 12.0, -dir * 6.0)
			for frame in 410:
				var next := Traffic.waypoint(p, goal, file, 3, true, true)
				next = Traffic.around_ram(p, next, parked, 3, true)
				var offset := p.direction_to(next) * minf(0.17, p.distance_to(next))
				p = Ground.travel(p, Traffic.ram_motion(p, offset, parked, 3), true)
				if p.distance_to(goal) < 0.3: break
			check(p.distance_to(goal) < 0.3, "Open gate retains a usable route around a parked ram in each direction")
	for i in 4:
		var p: Vector2 = [Vector2(-6, 0), Vector2(6, 0), Vector2(0, -4), Vector2(0, 4)][i]
		var goal := -p
		for t in 220:
			var next := Traffic.around_ram(p, goal, Vector2.ZERO, i)
			var offset := p.direction_to(next) * minf(0.15, p.distance_to(next))
			p += Traffic.ram_motion(p, offset, Vector2.ZERO, i)
			check(not Traffic._inside(p), "Route stays outside the hull")
			if p.distance_to(goal) < 0.2: break
		check(p.distance_to(goal) < 0.2, "A unit can pass the vehicle from either end or side")

func _check_serving_crew() -> void:
	# Isolated damage attribution. Then remove the crew and repeat with no defenders
	# killed and no timer/gate edits: a parked, unserved ram cannot land a second hit.
	var b := Battle.new()
	b.setup(20)
	b.ram = Ground.GATE - Vector2(3.1, 0)
	var engineers: Array[Battle.Unit] = []
	for u in b.roster:
		if u.engineer:
			u.pos = Traffic.crew_station(b.ram, u.id)
			check(not Traffic._inside(u.pos - b.ram) and u.pos.distance_to(b.ram) < 4.8, "Engineers occupy reachable service handles")
			engineers.append(u)
	b._rebuild_grid()
	var original := b.gate_hp
	b.tick = 4
	b._siege()
	check(engineers.size() == 4 and b.gate_hp == original - 20.0, "All four counted engineers drove an actual siege strike")
	for u in engineers:
		u.pos.x -= 12.0
	b._rebuild_grid()
	var damaged := b.gate_hp
	for j in 20:
		b.tick += 4
		b._siege()
	check(b.gate_hp == damaged, "No gate damage from an abandoned engine")

func _check_gate_leaves() -> void:
	var b := Battle.new()
	b.setup(20)
	b.traffic_enabled = true
	var u := b.roster[0]
	var move := b.moves[Battle.Arms.Kit.SHIELD][0] as Battle.Arms.Move
	for z: float in [-3.15, 3.15]:
		u.pos = Vector2(Ground.WALL_X - 2.10, z)
		u.locked = Vector2.RIGHT
		var hp := b.gate_hp
		b._melee(u, move)
		check(b.gate_hp < hp, "A shield fighter at either wooden leaf reaches it")
		hp = b.gate_hp
		u.locked = Vector2.LEFT
		b._melee(u, move)
		check(b.gate_hp == hp, "Swing aimed away from the gate misses")
	u.pos = Vector2(Ground.WALL_X - 2.0, Ground.GATE_HALF + 3.0)
	u.locked = Vector2.RIGHT
	var hp := b.gate_hp
	b._melee(u, move)
	check(b.gate_hp == hp, "Hitting stone outside the jamb does not damage the door")

func _siege(enabled: bool) -> Dictionary:
	var b := Battle.new()
	b.setup(512)
	b.traffic_enabled = enabled
	for i in b.companies_per_side:
		var mission := Battle.Mission.PRESS
		if i in [2, 7]: mission = Battle.Mission.ESCORT
		elif i in [0, 4]: mission = Battle.Mission.FLANK
		check(b.command(i, mission, Battle.Channel.FLAG), "Identical muster task in each replay")
	var row := {"samples": 0, "hull_occupant_samples": 0, "overlapping_person_samples": 0, "crowded_pairs": 0,
			"peak_3m_square": 0, "peak_half_metre_cell": 0, "peak_same_coordinate": 0, "bridge_file_metres": [], "bridge_crossers": 0, "gate_crossers": 0,
			"low_motion_passage_samples": 0, "breach": -1, "gate_contact": -1, "ram_strikes": 0,
			"ram_farthest_x": b.ram.x, "wall_defenders": 0, "ordinary": [0, 0]}
	for u in b.roster:
		if not u.hero and not u.officer:
			row.ordinary[u.team] += 1
			if u.team == 1 and u.station.x > Ground.WALL_X:
				row.wall_defenders += 1
	var post_breach := {"samples": 0, "overlapping_person_samples": 0, "hull_occupant_samples": 0, "crowded_pairs": 0, "peak_3m_square": 0, "peak_half_metre_cell": 0, "peak_same_coordinate": 0, "low_motion_passage_samples": 0, "gate_crossers": 0}
	var service_log := []
	var escort_spread := []
	var sim_us := PackedInt64Array()
	var bridge_users := {}
	var gate_users := {}
	var bridge_files := {}
	b.start()
	for t in 3600:
		var timer_before := b.ram_timer
		var start := Time.get_ticks_usec()
		b.step()
		var step_cost := Time.get_ticks_usec() - start
		if b.tick >= FIRST_SAMPLE and b.tick <= LAST_SAMPLE: sim_us.append(step_cost)
		if b.tick in [200, 400, 600]: escort_spread.append(_escort_spread(b))
		if b.tick % 200 == 0:
			var crew := []
			var close_attackers := 0
			for u in b.roster:
				if u.engineer and b.active(u): crew.append([u.id, u.state, snappedf(u.pos.distance_to(b.ram), 0.1)])
				if u.team == 0 and b.active(u) and u.pos.distance_to(Traffic.gate_face(u.pos)) < 2.8: close_attackers += 1
			service_log.append([b.tick, snappedf(b.ram.x, 0.1), snappedf(b.gate_hp, 0.1), close_attackers, crew])
		if b.ram_timer > timer_before: row.ram_strikes += 1
		row.ram_farthest_x = maxf(row.ram_farthest_x, b.ram.x)
		if b.gate_hp < 260 and row.gate_contact < 0: row.gate_contact = b.tick
		if b.gate_hp <= 0 and row.breach < 0: row.breach = b.tick
		if b.tick % PERIOD == 0:
			if b.tick >= FIRST_SAMPLE and b.tick <= LAST_SAMPLE:
				_sample(b, row)
			for u in b.roster:
				if u.team != 0 or u.hero or u.officer or not b.active(u): continue
				if u.station.x < Ground.RIVER_X - 4.8 and u.pos.x > Ground.RIVER_X + 4.8:
					bridge_users[u.id] = true
				if absf(u.pos.x - Ground.RIVER_X) < 2.3:
					bridge_files[roundi(u.pos.y - Ground.crossing(u.pos.y))] = true
				if u.pos.x > Ground.WALL_X + 1.4 and absf(u.pos.y) < Ground.WALL_Z - 1.2:
					gate_users[u.id] = true
		if row.breach > 0:
			var elapsed: int = b.tick - row.breach
			if elapsed > 0 and elapsed <= 120 and elapsed % PERIOD == 0:
				_sample(b, post_breach, true)
				if elapsed == 120: post_breach.gate_crossers = gate_users.size()
		if not b.result.is_empty(): break
	sim_us.sort()
	if not sim_us.is_empty():
		var timings := {}
		for p: int in [50, 95, 99]:
			var index := ceili(sim_us.size() * p / 100.0) - 1
			timings["p%d" % p] = sim_us[index] / 1000.0
		timings.samples = sim_us.size()
		row.sim_tick_ms = timings
	row.escort_formation = escort_spread
	row.service = service_log
	row.after_breach_6s = post_breach
	row.bridge_crossers = bridge_users.size()
	row.gate_crossers = gate_users.size()
	row.bridge_file_metres = bridge_files.keys()
	row.bridge_file_metres.sort()
	row.merge({"tick": b.tick, "end": b.result, "hits": b.hits, "dead": b.losses, "escaped": b.escaped,
			"ram_hp": b.ram_hp, "gate_hp": b.gate_hp, "dropped_weapons": b.equipment})
	return row

func _escort_spread(b: Battle) -> Dictionary:
	# Interdecile frontage/depth of all available ordinary escort soldiers.
	# An isolated skirmisher or a single horse cannot dominate the measurement.
	var x := PackedFloat32Array()
	var z := PackedFloat32Array()
	var occupied := {}
	for u in b.roster:
		if u.team != 0 or u.officer or u.hero or not b.active(u) or u.state == Battle.State.ROUT: continue
		if b.companies[u.squad].mission != Battle.Mission.ESCORT: continue
		x.append(u.pos.x)
		z.append(u.pos.y)
		occupied[Vector2i(u.pos.floor())] = true
	var row := {"tick": b.tick, "ordinary": x.size(), "occupied_1m_cells": occupied.size(), "depth_m": 0.0, "frontage_m": 0.0}
	if x.size() >= 2:
		x.sort()
		z.sort()
		var low := floori((x.size() - 1) * 0.10)
		var high := ceili((x.size() - 1) * 0.90)
		row.depth_m = snappedf(x[high] - x[low], 0.01)
		row.frontage_m = snappedf(z[high] - z[low], 0.01)
	return row

func _sample(b: Battle, row: Dictionary, only_gate: bool = false) -> void:
	row.samples += 1
	var close := {}
	var coordinates := {}
	var cells := {}
	var density := {}
	for u in b.roster:
		if u.hero or u.officer or not b.active(u): continue
		var offset := u.pos - b.ram
		var near_ram := absf(offset.x) <= 8.0 and absf(offset.y) <= 8.0
		var near_gate := absf(u.pos.x - Ground.WALL_X) <= 8.0 and absf(u.pos.y) <= 10.0
		var near_bridge := absf(u.pos.x - Ground.RIVER_X) <= 7.0 and absf(u.pos.y - Ground.crossing(u.pos.y)) <= 4.0
		if only_gate and not near_gate: continue
		if not (near_ram or near_gate or near_bridge): continue
		if absf(offset.x) < 1.95 and absf(offset.y) < 0.88:
			row.hull_occupant_samples += 1
		if (near_bridge or (near_gate and b.gate_hp <= 0)) and u.state == Battle.State.MARCH and u.target < 0 and u.before.distance_squared_to(u.pos) < 0.0001:
			row.low_motion_passage_samples += 1
		coordinates[u.pos] = int(coordinates.get(u.pos, 0)) + 1
		row.peak_same_coordinate = maxi(row.peak_same_coordinate, coordinates[u.pos])
		var tile := Vector2i((u.pos / 3.0).floor())
		density[tile] = int(density.get(tile, 0)) + 1
		row.peak_3m_square = maxi(row.peak_3m_square, density[tile])
		var cell := Vector2i((u.pos / OVERLAP).floor())
		for dz in range(-1, 2):
			for dx in range(-1, 2):
				var key := cell + Vector2i(dx, dz)
				if not cells.has(key): continue
				for id: int in cells[key]:
					if u.pos.distance_squared_to(b.roster[id].pos) < OVERLAP * OVERLAP:
						close[u.id] = true
						close[id] = true
						row.crowded_pairs += 1
		if not cells.has(cell): cells[cell] = []
		cells[cell].append(u.id)
		row.peak_half_metre_cell = maxi(row.peak_half_metre_cell, cells[cell].size())
	row.overlapping_person_samples += close.size()
