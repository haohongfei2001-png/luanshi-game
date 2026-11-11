class_name BattleSimulation
extends RefCounted
## Authoritative, seeded battle state. No scene nodes, physics or input devices.

const SOLDIERS_PER_SIDE := 20
const FIELD_HALF := Vector2(31.0, 19.0)
const PLAYER_ID := 40
const FIXED_DELTA := 1.0 / 60.0
const SKILL_COOLDOWNS := {"sweep": 5.0, "lunge": 7.0, "guard": 9.0}
var units: Array[Dictionary] = []
var events: Array[Dictionary] = []
var rng := RandomNumberGenerator.new()
var elapsed := 0.0
var order := "follow"
var ended := false
var result := ""
var player_move := Vector2.ZERO
var player_aim := Vector2.RIGHT
var cooldowns := {"attack": 0.0, "sweep": 0.0, "lunge": 0.0, "guard": 0.0}
var damage_dealt := 0.0
var seed_value := 184
var _player_index := PLAYER_ID
var _initial_counts := [20, 20]
var _ticket: Dictionary = {}

func reset(battle_seed: int = 184) -> void:
	_ticket = {}
	_player_index = PLAYER_ID
	_initial_counts = [20, 20]
	seed_value = battle_seed
	rng.seed = battle_seed
	units.clear()
	events.clear()
	elapsed = 0.0
	ended = false
	result = ""
	order = "follow"
	player_move = Vector2.ZERO
	player_aim = Vector2.RIGHT
	damage_dealt = 0.0
	for key in cooldowns:
		cooldowns[key] = 0.0
	for team in range(2):
		for i in range(SOLDIERS_PER_SIDE):
			var side := -1.0 if team == 0 else 1.0
			var pos := Vector2(side * (13.0 + (i / 5) * 1.65), (i % 5 - 2) * 2.15)
			units.append(_unit(units.size(), team, pos, false))
	units.append(_unit(PLAYER_ID, 0, Vector2(-21.0, 0.0), true))

func _unit(id: int, team: int, pos: Vector2, hero: bool) -> Dictionary:
	return {"id": id, "team": team, "hero": hero, "pos": pos,
		"facing": Vector2.RIGHT if team == 0 else Vector2.LEFT,
		"hp": 360.0 if hero else 100.0, "max_hp": 360.0 if hero else 100.0,
		"speed": 7.0 if hero else 3.0, "damage": 26.0 if hero else 13.0,
		"range": 3.1 if hero else 1.65, "weapon": "spear", "attack_cd": 0.0,
		"guard": 0.0, "flash": 0.0, "swing": 0.0, "target": -1}

func player() -> Dictionary:
	return units[_player_index]

func alive_count(team: int, include_hero: bool = false) -> int:
	var count := 0
	for unit in units:
		if unit.team == team and unit.hp > 0.0 and (include_hero or not unit.hero):
			count += 1
	return count

func issue_order(next_order: String) -> bool:
	if ended or next_order not in ["follow", "attack", "retreat"]:
		return false
	order = next_order
	events.append({"type": "order", "name": order, "pos": player().pos})
	return true

func set_player_input(movement: Vector2, aim: Vector2) -> void:
	player_move = movement.limit_length()
	if aim.length_squared() > 0.01:
		player_aim = aim.normalized()

func use_action(action: String) -> bool:
	if ended or player().hp <= 0.0 or not cooldowns.has(action) or cooldowns[action] > 0.0:
		return false
	var hero := player()
	if hero.weapon == "" and action in ["sweep", "lunge"]:
		return false
	hero.facing = player_aim
	match action:
		"attack":
			cooldowns.attack = 0.55
			_cone_attack(hero.range, hero.damage, 0.25)
		"sweep":
			cooldowns.sweep = SKILL_COOLDOWNS.sweep
			_cone_attack(4.4, 44.0, -0.35)
		"lunge":
			cooldowns.lunge = SKILL_COOLDOWNS.lunge
			var start: Vector2 = hero.pos
			var finish := _clamp_position(start + player_aim * 5.8)
			hero.pos = finish
			for unit in units:
				if unit.team == 1 and unit.hp > 0.0:
					var nearest := Geometry2D.get_closest_point_to_segment(unit.pos, start, finish)
					if nearest.distance_to(unit.pos) < 1.8:
						_hurt(unit, 58.0, true)
		"guard":
			cooldowns.guard = SKILL_COOLDOWNS.guard
			hero.guard = 2.6
		_:
			return false
	hero.swing = 0.24
	events.append({"type": "skill", "name": action, "pos": hero.pos, "facing": player_aim})
	_check_result()
	return true

func _cone_attack(reach: float, damage: float, min_dot: float) -> void:
	for unit in units:
		if unit.team != 1 or unit.hp <= 0.0:
			continue
		var offset: Vector2 = unit.pos - player().pos
		if offset.length() <= reach and (offset.length() < 0.7 or player_aim.dot(offset.normalized()) >= min_dot):
			_hurt(unit, damage, true)

func step(delta: float) -> void:
	if ended or not is_finite(delta) or delta <= 0.0:
		return
	elapsed += delta
	for key in cooldowns:
		cooldowns[key] = maxf(0.0, cooldowns[key] - delta)
	for unit in units:
		unit.attack_cd = maxf(0.0, unit.attack_cd - delta)
		unit.guard = maxf(0.0, unit.guard - delta)
		unit.flash = maxf(0.0, unit.flash - delta)
		unit.swing = maxf(0.0, unit.swing - delta)
	var hero := player()
	if hero.hp > 0.0:
		hero.pos = _clamp_position(hero.pos + player_move * hero.speed * delta)
		hero.facing = player_aim
	var hits: Array[Dictionary] = []
	var planned_positions: Array[Vector2] = []
	for unit in units:
		planned_positions.append(unit.pos)
	for unit in units:
		if unit.hero or unit.hp <= 0.0:
			continue
		var target_id := _nearest_enemy(unit)
		unit.target = target_id
		var destination: Vector2 = unit.pos
		var engaging := target_id >= 0
		if engaging:
			destination = units[target_id].pos
		if unit.team == 0 and order == "follow":
			var slot := Vector2(-2.8 - (unit.id / 5) * 1.4, (unit.id % 5 - 2) * 1.7)
			var station := _clamp_position(hero.pos + slot)
			if not engaging or unit.pos.distance_to(destination) > 3.2 or unit.pos.distance_to(station) > 6.0:
				destination = station
				engaging = false
		elif unit.team == 0 and order == "retreat":
			destination = Vector2(-29.0, (unit.id % 5 - 2) * 2.0)
			engaging = false
		var distance: float = unit.pos.distance_to(destination)
		if engaging and distance <= unit.range:
			unit.facing = (destination - unit.pos).normalized()
			if unit.attack_cd <= 0.0:
				unit.attack_cd = 0.85 + rng.randf_range(0.0, 0.25)
				unit.swing = 0.20
				hits.append({"target": target_id, "damage": unit.damage * rng.randf_range(0.9, 1.1)})
		elif distance > 0.18:
			var direction: Vector2 = (destination - unit.pos).normalized()
			unit.facing = direction
			planned_positions[unit.id] = _clamp_position(unit.pos + direction * minf(unit.speed * delta, distance))
	# Separation uses the same snapshot for all units, avoiding update-order bias.
	for unit in units:
		if unit.hero or unit.hp <= 0.0:
			continue
		var correction := Vector2.ZERO
		for other in units:
			if other.id == unit.id or other.hp <= 0.0:
				continue
			var offset: Vector2 = unit.pos - other.pos
			var distance := offset.length()
			var spacing := 0.9 if not other.hero else 1.2
			if distance < spacing:
				var direction := offset / distance if distance > 0.001 else Vector2.RIGHT.rotated(float(unit.id) * 2.4)
				correction += direction * (spacing - distance) * 5.0 * delta
		planned_positions[unit.id] = _clamp_position(planned_positions[unit.id] + correction.limit_length(0.12))
	for unit in units:
		if not unit.hero and unit.hp > 0.0:
			unit.pos = planned_positions[unit.id]
	for hit in hits:
		_hurt(units[hit.target], hit.damage, false)
	_check_result()

func _nearest_enemy(unit: Dictionary) -> int:
	var best := -1
	var best_distance := INF
	for other in units:
		if other.hp <= 0.0 or other.team == unit.team:
			continue
		var distance: float = unit.pos.distance_squared_to(other.pos)
		if distance < best_distance:
			best_distance = distance
			best = other.id
	return best

func _hurt(unit: Dictionary, damage: float, from_player: bool) -> void:
	if unit.hp <= 0.0:
		return
	var applied := damage * (0.25 if unit.guard > 0.0 else 1.0)
	if from_player:
		damage_dealt += minf(unit.hp, applied)
	unit.hp = maxf(0.0, unit.hp - applied)
	unit.flash = 0.12
	if unit.hp <= 0.0:
		events.append({"type": "death", "id": unit.id, "pos": unit.pos})

func _clamp_position(pos: Vector2) -> Vector2:
	return pos.clamp(-FIELD_HALF, FIELD_HALF)

func _check_result() -> void:
	if ended:
		return
	if player().hp <= 0.0:
		ended = true
		result = "The commander has fallen"
	elif alive_count(1) == 0:
		ended = true
		result = "Victory at the border"
	elif order == "retreat" and player().pos.x < -27.0:
		var extracted := true
		for unit in units:
			if unit.team == 0 and not unit.hero and unit.hp > 0.0 and unit.pos.x > -25.5:
				extracted = false
		if extracted:
			ended = true
			result = "The company withdrew"

func report() -> Dictionary:
	return {"seed": seed_value, "elapsed_seconds": snappedf(elapsed, 0.01), "result": result,
		"friendly_survivors": alive_count(0), "friendly_casualties": _initial_counts[0] - alive_count(0),
		"enemy_survivors": alive_count(1), "enemy_casualties": _initial_counts[1] - alive_count(1),
		"player_alive": player().hp > 0.0, "player_hp": snappedf(player().hp, 0.01),
		"player_damage": snappedf(damage_dealt, 0.01)}


func reset_from_ticket(ticket: Dictionary) -> void:
	## Only WorldSim supplies canonical tickets; no soldier or weapon is invented here.
	reset(int(ticket.tactical_seed))
	_ticket = ticket.duplicate(true)
	units.clear()
	_initial_counts = [0, 0]
	for team in range(2):
		var roster: Array = ticket.reserved_roster_snapshot[team]
		for slot in range(roster.size()):
			var entry: Dictionary = roster[slot]
			var side := -1.0 if team == 0 else 1.0
			var pos := Vector2(side * (13.0 + (slot / 5) * 1.65), (slot % 5 - 2) * 2.15)
			var unit := _unit(units.size(), team, pos, entry.hero)
			unit["roster_id"] = entry.id
			unit["force_id"] = entry.force_id
			unit.weapon = entry.weapon
			if entry.hero:
				_player_index = unit.id
				unit.pos = Vector2(-21.0, 0.0)
				unit.hp = entry.hp
			else:
				_initial_counts[team] += 1
			if unit.weapon == "":
				unit.damage = 7.0 if entry.hero else 4.0
				unit.range = 0.85
			units.append(unit)

func outcome() -> Dictionary:
	## Stable, unrounded battle facts. WorldSim compares these to the bound simulation.
	if _ticket.is_empty() or not ended:
		return {}
	var status := "victory" if alive_count(1) == 0 else "retreat"
	if player().hp <= 0.0:
		status = "commander_dead"
	var forces: Array[Dictionary] = []
	for team in range(2):
		var survivors: Array[String] = []
		var dead_ids: Array[String] = []
		var dead_weapons := 0
		for unit in units:
			if unit.team != team:
				continue
			if unit.hp > 0.0:
				survivors.append(unit.roster_id)
			else:
				dead_ids.append(unit.roster_id)
				dead_weapons += 1 if unit.weapon != "" else 0
		forces.append({"force_id": _ticket.participating_force_ids[team], "surviving_ids": survivors,
			"dead_ids": dead_ids, "wounded": [], "missing": [], "captured": [],
			"recovered_equipment": dead_weapons if status == "victory" else 0,
			"destroyed_equipment": dead_weapons if status != "victory" else 0})
	return {"battle_id": _ticket.battle_id, "result": status, "forces": forces,
		"elapsed_world_time": elapsed, "player_alive": player().hp > 0.0, "player_hp": player().hp,
		"spoils": {"weapons": forces[1].recovered_equipment if status == "victory" else 0},
		"retreat_positions": {"relief": _ticket.location} if status != "victory" else {}}
