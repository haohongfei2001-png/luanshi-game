extends RefCounted
## Company officers and their escorts use the field's permanent roster, grid and weapon moves.
## The company keeps its founding officer ID. Command may pass to a living soldier already in it.
const Arms := preload("res://scripts/field/arms.gd")
const Ground := preload("res://scripts/field/ground.gd")

enum Rank { COMMANDER, VANGUARD, CHALLENGER, ELITE, CAPTAIN }
enum Duty { FIT, WOUNDED, EVACUATED, CAPTIVE, SLAIN, WITHDRAWN }
const TITLES := ["战场主将", "先锋", "叫阵骁将", "精锐军官", "队正"]
const KITS := [Arms.Kit.GLAIVE, Arms.Kit.SPEAR, Arms.Kit.DAO, Arms.Kit.SHIELD, Arms.Kit.SWORD]
const HEALTH := [102.0, 92.0, 88.0, 90.0, 78.0]
const ARMOR := [0.19, 0.14, 0.12, 0.23, 0.13]
const WOUND_LIMIT := 0.34
const SIGHT := 12.0
const ESCORT_REACH := 3.2
const CAPTURE_STEPS := 20
const COMMAND_DELAY := 32
const SERIAL := [&"duty", &"leader", &"vacant_since", &"handover_pos", &"contact", &"pressure",
	&"relief", &"seen_tick", &"offense_ready", &"defense_ready", &"challenged", &"challenge_tick",
	&"capture_steps", &"captor", &"rescuer", &"handovers", &"skills", &"kills"]

class Command:
	var primary := -1
	var rank: int = Rank.CAPTAIN
	var guards: Array[int] = []
	var deputies: Array[int] = []
	var duty: int = Duty.FIT
	var leader := -1
	var vacant_since := -1
	var handover_pos := Vector2.ZERO
	var contact := -1
	var pressure := 0
	var relief := -1
	var seen_tick := -1
	var offense_ready := 0
	var defense_ready := 0
	var challenged := -1
	var challenge_tick := -1
	var capture_steps := 0
	var captor := -1
	var rescuer := -1
	var handovers := 0
	var skills := 0
	var kills := 0

var enabled := false
var companies: Array[Command] = []
var escort_of := PackedInt32Array()
var first_primary := -1

func setup(b, ranked: bool = true) -> void:
	enabled = ranked
	companies.clear()
	escort_of = PackedInt32Array()
	first_primary = -1
	if not enabled:
		return
	first_primary = b.companies[0].officer_id
	escort_of.resize(b.roster.size())
	escort_of.fill(-1)
	var ordinals := [0, 0]
	for i in b.companies.size():
		var c = b.companies[i]
		var r := Command.new()
		r.rank = mini(ordinals[c.team], Rank.CAPTAIN)
		ordinals[c.team] += 1
		r.primary = c.officer_id
		r.leader = r.primary
		var u = b.roster[r.primary]
		u.kit = KITS[r.rank]
		u.max_hp = HEALTH[r.rank]
		u.hp = u.max_hp
		u.armor = ARMOR[r.rank]
		companies.append(r)
	# These four jobs come out of each existing company. No mounts, archers,
	# wall posts or ram crew are pulled off their assigned work.
	for u in b.roster:
		if u.hero or u.officer or u.engineer or u.wall_post or u.mounted or Arms.issue(u.kit) > 0:
			continue
		var r := companies[u.squad]
		if u.kit == Arms.Kit.SHIELD and r.guards.size() < 2:
			r.guards.append(u.id)
			escort_of[u.id] = u.squad
			u.armor = minf(0.30, u.armor + 0.07)
		elif r.deputies.size() < 2:
			r.deputies.append(u.id)

func _record(b, c) -> Command:
	return companies[b.roster[c.officer_id].squad]

func recipient(b, c):
	if enabled:
		var r := _record(b, c)
		if r.leader >= 0:
			return b.roster[r.leader]
	return b.roster[c.officer_id]

func can_command(b, c) -> bool:
	if not enabled:
		return b.active(b.roster[c.officer_id])
	var r := _record(b, c)
	return _eligible(b, r, r.leader)

func _eligible(b, r: Command, id: int) -> bool:
	if id < 0:
		return false
	var u = b.roster[id]
	return b.active(u) and u.state != b.State.ROUT and (id != r.primary or r.duty == Duty.FIT)

func is_captive(id: int) -> bool:
	# Founding officers occupy a contiguous range between the two armies' troops and the hero.
	var squad := id - first_primary
	return enabled and squad >= 0 and squad < companies.size() and companies[squad].duty == Duty.CAPTIVE

func is_wounded(id: int) -> bool:
	var squad := id - first_primary
	return enabled and squad >= 0 and squad < companies.size() and companies[squad].duty == Duty.WOUNDED

func support_partner(b, u) -> int:
	if not enabled or u.hero or not b.active(u):
		return -1
	var r := companies[u.squad]
	if r.duty != Duty.WOUNDED or r.rescuer < 0:
		return -1
	if u.id != r.primary and u.id != r.rescuer:
		return -1
	var guard = b.roster[r.rescuer]
	var wounded = b.roster[r.primary]
	if not _eligible(b, r, guard.id) or not b.active(wounded) or guard.pos.distance_squared_to(wounded.pos) > ESCORT_REACH * ESCORT_REACH:
		return -1
	return r.rescuer if u.officer else r.primary

func title_of(_b, u) -> String:
	if not enabled or u.hero:
		return ""
	var r := companies[u.squad]
	if u.officer:
		return TITLES[r.rank]
	if r.leader == u.id:
		return "代领队正"
	if escort_of[u.id] >= 0:
		return "亲卫"
	return ""

func _vacate(b, r: Command, at: Vector2) -> void:
	if r.leader < 0:
		return
	r.leader = -1
	r.vacant_since = b.tick
	r.handover_pos = at
	r.contact = -1
	r.relief = -1
	r.pressure = 0
	var original = b.roster[r.primary]
	# Only witnesses near their own standard feel the immediate shock.
	for id in b._near(at, 7.5, original.team):
		var u = b.roster[id]
		if u.squad == original.squad and not u.officer and not u.hero and Ground.clear_shot(at, u.pos, b.gate_hp <= 0):
			u.morale = maxf(0.0, u.morale - (0.13 if r.rank == Rank.COMMANDER else 0.08))

func _try_succession(b, r: Command) -> void:
	if b.tick - r.vacant_since < COMMAND_DELAY:
		return
	for id in r.deputies:
		if not _eligible(b, r, id):
			continue
		var u = b.roster[id]
		if u.morale < 0.46 or u.pos.distance_squared_to(r.handover_pos) > 18.0 * 18.0:
			continue
		if not Ground.clear_shot(u.pos, r.handover_pos, b.gate_hp <= 0):
			continue
		r.leader = id
		r.vacant_since = -1
		r.handovers += 1
		return

func after_hit(b, source, target) -> void:
	if not enabled:
		return
	if source.officer and target.hp <= 0.0:
		companies[source.squad].kills += 1
	if not target.officer:
		return
	var r := companies[target.squad]
	if target.hp <= 0.0:
		r.duty = Duty.SLAIN
		r.rescuer = -1
		r.captor = -1
		r.capture_steps = 0
	elif r.duty == Duty.FIT and target.hp <= target.max_hp * WOUND_LIMIT:
		r.duty = Duty.WOUNDED
		b._set_state(target, b.State.STAGGER, 0.28)
	else:
		return
	if r.leader == r.primary:
		_vacate(b, r, target.pos)

func advance(b) -> void:
	if not enabled:
		return
	for r in companies:
		var u = b.roster[r.primary]
		if r.leader >= 0 and not _eligible(b, r, r.leader):
			_vacate(b, r, b.roster[r.leader].pos)
		if r.leader < 0 and (b.tick + r.primary) % 4 == 0:
			_try_succession(b, r)
		if r.duty == Duty.WOUNDED:
			_contest_wounded(b, u, r)
		if r.leader >= 0 and (b.tick + r.primary) % 12 == 0:
			_observe(b, b.roster[r.leader], r)

func _observe(b, u, r: Command) -> void:
	r.contact = -1
	r.relief = -1
	r.pressure = 0
	r.seen_tick = b.tick
	var best := INF
	for id in b._near(u.pos, SIGHT, 1 - u.team):
		var v = b.roster[id]
		if v.state == b.State.ROUT or not Ground.clear_shot(u.pos, v.pos, b.gate_hp <= 0):
			continue
		var distance: float = u.pos.distance_to(v.pos)
		if distance < 7.0:
			r.pressure += 1
		var priority := 1.6 if r.rank == Rank.CHALLENGER and (v.officer or v.hero) else 0.0
		var score := distance - priority
		if score < best or (score == best and id < r.contact):
			best = score
			r.contact = id
	if r.rank == Rank.CHALLENGER and r.leader == r.primary and r.contact >= 0:
		var rival = b.roster[r.contact]
		if (rival.hero or rival.officer) and (r.challenge_tick < 0 or b.tick - r.challenge_tick > 240):
			r.challenged = rival.id
			r.challenge_tick = b.tick
			if rival.hero and b.hero.pos.distance_squared_to(u.pos) < 81.0:
				b.notice = "敌方骁将举刀叫阵，可战可避"
	if b.companies[u.squad].mission != b.Mission.RESERVE:
		return
	best = INF
	for id in b._near(u.pos, SIGHT, u.team):
		var v = b.roster[id]
		if not v.officer or v.squad == u.squad or companies[v.squad].duty != Duty.WOUNDED:
			continue
		var distance: float = u.pos.distance_squared_to(v.pos)
		if distance < best and Ground.clear_shot(u.pos, v.pos, b.gate_hp <= 0):
			r.relief = id
			best = distance

func guide_company(b, c, assigned: Vector2) -> Vector2:
	if not enabled or c.regrouping:
		return assigned
	var r := _record(b, c)
	if r.leader < 0 or b.tick - r.seen_tick > 18:
		return assigned
	var leader = b.roster[r.leader]
	if c.mission == b.Mission.RESERVE and r.relief >= 0:
		var wounded = b.roster[r.relief]
		if b.active(wounded) and companies[wounded.squad].duty == Duty.WOUNDED and leader.pos.distance_squared_to(wounded.pos) <= SIGHT * SIGHT and Ground.clear_shot(leader.pos, wounded.pos, b.gate_hp <= 0):
			return c.home + (wounded.pos - c.home).limit_length(10.0)
	if r.contact < 0 or not b.active(b.roster[r.contact]):
		return assigned
	var v = b.roster[r.contact]
	if leader.pos.distance_squared_to(v.pos) > SIGHT * SIGHT or not Ground.clear_shot(leader.pos, v.pos, b.gate_hp <= 0):
		return assigned
	if c.mission == b.Mission.INTERCEPT:
		return c.home + (v.pos - c.home).limit_length(12.0)
	if c.mission == b.Mission.RESERVE and r.pressure >= 3:
		return c.home + (v.pos - c.home).limit_length(7.0)
	return assigned

func _contest_wounded(b, u, r: Command) -> void:
	r.rescuer = -1
	for id in r.guards:
		var guard = b.roster[id]
		if _eligible(b, r, id) and guard.pos.distance_squared_to(u.pos) <= ESCORT_REACH * ESCORT_REACH and Ground.clear_shot(guard.pos, u.pos, b.gate_hp <= 0):
			r.rescuer = id
			break
	if r.rescuer >= 0:
		r.capture_steps = 0
		r.captor = -1
		return
	var holder := -1
	var nearest := INF
	for id in b._near(u.pos, 2.0, 1 - u.team):
		var v = b.roster[id]
		var d: float = u.pos.distance_squared_to(v.pos)
		if v.state == b.State.ROUT or not Ground.clear_shot(u.pos, v.pos, b.gate_hp <= 0):
			continue
		if d < nearest or (d == nearest and id < holder):
			holder = id
			nearest = d
	if holder >= 0:
		for id in b._near(u.pos, 2.4, u.team):
			var ally = b.roster[id]
			if id != u.id and ally.state != b.State.ROUT and Ground.clear_shot(u.pos, ally.pos, b.gate_hp <= 0):
				holder = -1
				break
	if holder < 0 or holder != r.captor:
		r.capture_steps = 0
	r.captor = holder
	if holder >= 0:
		r.capture_steps += 1
		if r.capture_steps == CAPTURE_STEPS:
			r.duty = Duty.CAPTIVE
			b._set_state(u, b.State.ESCAPED, 0.0)

func _exit(u) -> Vector2:
	return Vector2(-98.0 if u.team == 0 else 100.0, -32.0 if u.station.y < 0.0 else 32.0)

func _walk(b, u, goal: Vector2, speed: float, retreat: bool = false) -> void:
	var next := Ground.retreat_waypoint(u.pos, goal, b.gate_hp <= 0,b.bridgehead) if retreat else Ground.waypoint(u.pos, goal,b.bridgehead)
	var dist: float = u.pos.distance_to(next)
	if dist <= 0.10:
		return
	var direction: Vector2 = u.pos.direction_to(next)
	u.facing = direction
	var stride := minf(dist, speed * Ground.pace(u.pos,false,b.bridgehead) * b.DT)
	b._move(u, direction * stride + u.separation.limit_length(0.9) * b.DT)

func _retire(b, u, r: Command) -> void:
	var goal := _exit(u)
	if u.pos.distance_squared_to(goal) <= 2.3 * 2.3:
		if r.leader == r.primary:
			_vacate(b, r, u.pos)
		r.duty = Duty.EVACUATED if r.duty == Duty.WOUNDED else Duty.WITHDRAWN
		r.capture_steps = 0
		r.captor = -1
		b._set_state(u, b.State.ESCAPED, 0.0)
		return
	var speed := 3.3
	if r.duty == Duty.WOUNDED:
		speed = 2.65 if r.rescuer >= 0 else 1.05
	_walk(b, u, goal, speed, true)

func act(b, u) -> bool:
	if not enabled:
		return false
	if not u.officer:
		if u.state == b.State.ROUT or escort_of[u.id] < 0:
			return false
		return _escort(b, u, companies[escort_of[u.id]])
	var r := companies[u.squad]
	var c = b.companies[u.squad]
	if r.duty == Duty.WOUNDED or u.state == b.State.ROUT or c.mission == b.Mission.WITHDRAW:
		_retire(b, u, r)
		return true
	var target := r.contact if r.contact >= 0 else int(u.target)
	var forward := Vector2.RIGHT if u.team == 0 else Vector2.LEFT
	var goal: Vector2 = c.aim + forward * (1.85 if r.rank in [Rank.VANGUARD, Rank.CHALLENGER] else -1.5)
	# Respect the formation's home station in a garrison. Independently patrol
	# its frontage, but do not chase a player across the map or through a wall.
	if target >= 0 and b.active(b.roster[target]):
		var v = b.roster[target]
		var distance: float = u.pos.distance_to(v.pos)
		var leash := 7.0 if c.mission == b.Mission.RESERVE else SIGHT
		if distance <= leash and Ground.clear_shot(u.pos, v.pos, b.gate_hp <= 0):
			u.target = target
			if _fight(b, u, v, r, distance):
				return true
			goal = v.pos
	if u.team == 0 and b.gate_hp > 0.0 and c.mission in [b.Mission.PRESS, b.Mission.ESCORT] and u.pos.distance_to(Ground.GATE) < 3.3 and u.fatigue <= 0.0:
		b._begin(u, 0, u.pos.direction_to(Ground.GATE))
		u.fatigue = 0.45
		return true
	_walk(b, u, goal, 3.55 if r.rank in [Rank.VANGUARD, Rank.CHALLENGER] else 2.90)
	return true

func _fight(b, u, enemy, r: Command, distance: float) -> bool:
	var toward: Vector2 = u.pos.direction_to(enemy.pos)
	if u.fatigue > 0.0:
		if distance <= b._basic(u).reach * 0.9:
			u.facing = toward
			return true
		return false
	var slot := 0
	if enemy.state == b.State.WINDUP and b.tick >= r.defense_ready:
		var attack: Arms.Move = b._committed_move(enemy)
		var in_arc: bool = enemy.locked.dot(-toward) > 0.40
		if in_arc and distance <= attack.reach + maxf(attack.step, 0.0) + 0.35 and enemy.timer <= 0.36:
			slot = 3
	if slot == 0 and b.tick >= r.offense_ready:
		# Sweeps/short combinations punish a close group; lunges can reach a
		# retreating opponent, and miss if that opponent moves off the locked line.
		var choice := 1 if r.pressure >= 3 or distance < 2.0 else 2
		var skill: Arms.Move = b.moves[u.kit][choice]
		if distance <= skill.reach + maxf(skill.step, 0.0) * 0.80:
			slot = choice
	if slot == 0 and distance > b._basic(u).reach:
		return false
	if slot > 0:
		r.skills += 1
		if slot == 3:
			r.defense_ready = b.tick + 54
		else:
			r.offense_ready = b.tick + (58 if r.rank in [Rank.VANGUARD, Rank.CHALLENGER] else 78)
	b._begin(u, slot, toward)
	u.fatigue = 0.20
	return true

func _escort(b, guard, r: Command) -> bool:
	var u = b.roster[r.primary]
	var c = b.companies[guard.squad]
	if not b.active(u) or (c.mission == b.Mission.WITHDRAW and r.duty != Duty.WOUNDED):
		return false
	var target: int = guard.target
	if target >= 0 and b.active(b.roster[target]):
		var v = b.roster[target]
		var d: float = guard.pos.distance_to(v.pos)
		if d <= 2.15 and u.pos.distance_squared_to(v.pos) <= 30.25 and Ground.clear_shot(guard.pos, v.pos, b.gate_hp <= 0):
			if guard.fatigue <= 0.0 and guard.pos.distance_squared_to(u.pos) <= 25.0:
				var slot := 1 if v.state == b.State.WINDUP else 0
				if slot == 1 or d <= b._basic(guard).reach:
					b._begin(guard, slot, guard.pos.direction_to(v.pos))
					guard.fatigue = 0.35
					return true
	var facing: Vector2 = u.facing
	if r.duty == Duty.WOUNDED and r.rescuer >= 0:
		facing = -facing
	var side := -1.0 if guard.id == r.guards[0] else 1.0
	var post: Vector2 = u.pos + facing * 0.75 + facing.orthogonal() * side * 0.95
	if guard.pos.distance_squared_to(post) < 0.38:
		guard.facing = facing
	else:
		_walk(b, guard, post, 3.75)
	return true

func summary(b) -> Dictionary:
	var commanders := [-1, -1]
	var active_commands := [0, 0]
	var successors := [0, 0]
	var skills := [0, 0]
	var kills := [0, 0]
	var wounded := [[], []]
	var rescued := [[], []]
	var evacuated := [[], []]
	var captive := [[], []]
	var fallen := [[], []]
	for r in companies:
		var u = b.roster[r.primary]
		var team: int = u.team
		if r.rank == Rank.COMMANDER:
			commanders[team] = r.primary
		if _eligible(b, r, r.leader):
			active_commands[team] += 1
		successors[team] += r.handovers
		skills[team] += r.skills
		kills[team] += r.kills
		match r.duty:
			Duty.WOUNDED: wounded[team].append(r.primary)
			Duty.CAPTIVE: captive[team].append(r.primary)
			Duty.SLAIN: fallen[team].append(r.primary)
			Duty.EVACUATED:
				evacuated[team].append(r.primary)
				if r.rescuer >= 0:
					rescued[team].append(r.primary)
	return {"ranked": enabled, "commanders": commanders, "active_commands": active_commands,
		"successions": successors, "skills": skills, "kills": kills, "wounded": wounded, "rescued": rescued,
		"evacuated": evacuated, "captives": captive, "fallen": fallen}

func snapshot() -> Dictionary:
	var rows := []
	for r in companies:
		var row := []
		for field in SERIAL:
			row.append(r.get(field))
		rows.append(row)
	return {"version": 1, "enabled": enabled, "companies": rows}

func restore(b, data: Variant) -> bool:
	if not data is Dictionary or data.get("version") != 1 or not data.get("enabled") is bool or data.enabled != enabled:
		return false
	var rows: Variant = data.get("companies")
	if not rows is Array or rows.size() != companies.size():
		return false
	var decoded: Array[Command] = []
	for i in rows.size():
		var row: Variant = rows[i]
		if not row is Array or row.size() != SERIAL.size():
			return false
		var r := Command.new()
		var original := companies[i]
		r.primary = original.primary
		r.rank = original.rank
		r.guards = original.guards
		r.deputies = original.deputies
		for j in row.size():
			var field: StringName = SERIAL[j]
			if typeof(row[j]) != typeof(r.get(field)):
				return false
			r.set(field, row[j])
		if not _valid_record(b, r):
			return false
		decoded.append(r)
	companies = decoded
	return true

func _valid_record(b, r: Command) -> bool:
	var u = b.roster[r.primary]
	if r.duty < Duty.FIT or r.duty > Duty.WITHDRAWN:
		return false
	if not r.handover_pos.is_finite() or absf(r.handover_pos.x) > Ground.LIMIT.x or absf(r.handover_pos.y) > Ground.LIMIT.y:
		return false
	if r.leader != -1 and r.leader != r.primary and not r.deputies.has(r.leader):
		return false
	if (r.leader < 0) != (r.vacant_since >= 0) or (r.leader == r.primary and r.duty != Duty.FIT):
		return false
	for stamp in [r.vacant_since, r.seen_tick, r.challenge_tick]:
		if stamp < -1 or stamp > b.tick:
			return false
	for ready in [r.offense_ready, r.defense_ready]:
		if ready < 0 or ready > b.tick + 78:
			return false
	if r.pressure < 0 or r.pressure > b.roster.size():
		return false
	if r.handovers < 0 or r.handovers > r.deputies.size() or r.skills < 0 or r.skills > b.attacks or r.kills < 0 or r.kills > u.impacts:
		return false
	if r.rescuer != -1 and not r.guards.has(r.rescuer):
		return false
	if r.relief != -1:
		if r.relief < 0 or r.relief >= b.roster.size():
			return false
		var patient = b.roster[r.relief]
		if not patient.officer or patient.team != u.team or patient.id == u.id:
			return false
	for id in [r.contact, r.captor, r.challenged]:
		if id != -1 and (id < 0 or id >= b.roster.size() or b.roster[id].team == u.team):
			return false
	if (r.challenged < 0) != (r.challenge_tick < 0):
		return false
	if r.capture_steps < 0 or r.capture_steps > CAPTURE_STEPS or (r.capture_steps > 0) != (r.captor >= 0):
		return false
	if (r.capture_steps == CAPTURE_STEPS) != (r.duty == Duty.CAPTIVE):
		return false
	if r.captor >= 0 and r.duty not in [Duty.WOUNDED, Duty.CAPTIVE]:
		return false
	if (r.duty == Duty.SLAIN) != (u.state == b.State.DEAD):
		return false
	if (r.duty in [Duty.CAPTIVE, Duty.EVACUATED, Duty.WITHDRAWN]) != (u.state == b.State.ESCAPED):
		return false
	return r.duty not in [Duty.WOUNDED, Duty.CAPTIVE, Duty.EVACUATED] or u.hp <= u.max_hp * WOUND_LIMIT
