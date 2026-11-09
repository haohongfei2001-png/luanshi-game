class_name BattleSimulation
extends RefCounted
## Authoritative, seeded battle state. No scene nodes, physics or input devices.

const HeroProfiles := preload("res://scripts/hero_combat_profiles.gd")
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
# Versioned identity; profile data are reconstructed, never accepted from a save.
var hero_profile: Dictionary = HeroProfiles.get_profile(HeroProfiles.EARLY)

func reset(battle_seed: int = 184, profile_id: String = HeroProfiles.EARLY) -> bool:
	var selected := HeroProfiles.get_profile(profile_id)
	if selected.is_empty():
		return false
	hero_profile = selected
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
	return true

func _unit(id: int, team: int, pos: Vector2, hero: bool) -> Dictionary:
	return {"id": id, "team": team, "hero": hero, "pos": pos,
		"facing": Vector2.RIGHT if team == 0 else Vector2.LEFT,
		"hp": hero_profile.max_hp if hero else 100.0, "max_hp": hero_profile.max_hp if hero else 100.0,
		"speed": hero_profile.speed if hero else 3.0, "damage": hero_profile.damage if hero else 13.0,
		"condition_damage_scale": 1.0, "condition_speed_scale": 1.0,
		"range": hero_profile.range if hero else 1.65, "weapon": "spear", "attack_cd": 0.0,
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
			cooldowns.attack = hero_profile.attack_cooldown
			_cone_attack(hero.range, hero.damage, hero_profile.attack_min_dot, hero_profile.attack_targets)
		"sweep":
			cooldowns.sweep = hero_profile.sweep_cooldown
			_cone_attack(hero_profile.sweep_range, hero_profile.sweep_damage * hero.condition_damage_scale, hero_profile.sweep_min_dot, hero_profile.sweep_targets)
		"lunge":
			cooldowns.lunge = hero_profile.lunge_cooldown
			var start: Vector2 = hero.pos
			var finish := _clamp_position(start + player_aim * hero_profile.lunge_distance * hero.condition_speed_scale)
			hero.pos = finish
			var candidates: Array[Dictionary] = []
			for unit in units:
				if unit.team == 1 and unit.hp > 0.0:
					var nearest := Geometry2D.get_closest_point_to_segment(unit.pos, start, finish)
					if nearest.distance_to(unit.pos) < hero_profile.lunge_radius:
						candidates.append(unit)
			_apply_player_hits(candidates, hero_profile.lunge_damage * hero.condition_damage_scale, hero_profile.lunge_targets, start)
		"guard":
			cooldowns.guard = hero_profile.guard_cooldown
			hero.guard = hero_profile.guard_duration
		_:
			return false
	hero.swing = 0.24
	events.append({"type": "skill", "name": action, "pos": hero.pos, "facing": player_aim})
	_check_result()
	return true

func _cone_attack(reach: float, damage: float, min_dot: float, target_limit: int = 0) -> void:
	var candidates: Array[Dictionary] = []
	for unit in units:
		if unit.team != 1 or unit.hp <= 0.0:
			continue
		var offset: Vector2 = unit.pos - player().pos
		if offset.length() <= reach and (offset.length() < 0.7 or player_aim.dot(offset.normalized()) >= min_dot):
			candidates.append(unit)
	_apply_player_hits(candidates, damage, target_limit, player().pos)

func _apply_player_hits(candidates: Array[Dictionary], damage: float, target_limit: int, origin: Vector2) -> void:
	if target_limit > 0:
		candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
			var ad: float = a.pos.distance_squared_to(origin)
			var bd: float = b.pos.distance_squared_to(origin)
			return a.id < b.id if ad == bd else ad < bd)
	var hit_count := mini(target_limit, candidates.size()) if target_limit > 0 else candidates.size()
	for i in range(hit_count):
		_hurt(candidates[i], damage, true)

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
	var guard_factor: float = hero_profile.guard_incoming_factor if unit.hero else 0.25
	var applied := damage * (guard_factor if unit.guard > 0.0 else 1.0)
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


func reset_from_ticket(ticket: Dictionary) -> bool:
	## Only WorldSim supplies canonical tickets; no soldier or weapon is invented here.
	if not HeroProfiles.valid_reference(ticket.get("hero_profile")):
		return false
	reset(int(ticket.tactical_seed), ticket.hero_profile.id)
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
			unit.condition_damage_scale = float(entry.condition_modifiers.damage_percent) / 100.0
			unit.condition_speed_scale = float(entry.condition_modifiers.speed_percent) / 100.0
			unit.damage *= unit.condition_damage_scale
			unit.speed *= unit.condition_speed_scale
			units.append(unit)
	return true

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


func export_campaign_state() -> Dictionary:
	## Explicit causal state only. Derived roster indices are rebuilt from the ticket.
	return {"hero_profile": HeroProfiles.profile_reference(hero_profile.id), "units": units.duplicate(true), "events": events.duplicate(true),
		"seed": seed_value, "rng_state": rng.state, "elapsed": elapsed, "order": order,
		"ended": ended, "result": result, "player_move": player_move, "player_aim": player_aim,
		"cooldowns": cooldowns.duplicate(true), "damage_dealt": damage_dealt}

func restore_campaign_state(saved: Variant, ticket: Dictionary) -> Dictionary:
	## Validate into a separate simulation; failed restoration never changes self.
	var schema := preload("res://scripts/campaign_schema.gd")
	if not schema.ticket(ticket) or not schema.keys(saved, ["hero_profile", "units", "events", "seed", "rng_state", "elapsed", "order", "ended", "result", "player_move", "player_aim", "cooldowns", "damage_dealt"]):
		return {"ok": false, "reason": "invalid_battle_shape"}
	if not schema.types(saved, {"units": TYPE_ARRAY, "events": TYPE_ARRAY, "seed": TYPE_INT, "rng_state": TYPE_INT, "elapsed": TYPE_FLOAT, "order": TYPE_STRING, "ended": TYPE_BOOL, "result": TYPE_STRING, "player_move": TYPE_VECTOR2, "player_aim": TYPE_VECTOR2, "cooldowns": TYPE_DICTIONARY, "damage_dealt": TYPE_FLOAT}):
		return {"ok": false, "reason": "invalid_battle_field_types"}
	if not HeroProfiles.valid_reference(saved.hero_profile) or saved.hero_profile != ticket.hero_profile:
		return {"ok": false, "reason": "battle_profile_mismatch"}
	var selected := HeroProfiles.from_reference(ticket.hero_profile)
	if not saved.seed is int or saved.seed != ticket.tactical_seed or not saved.rng_state is int or not schema.number(saved.elapsed, ticket.elapsed_world_time, 8760 * 3600.0) or saved.order not in ["follow", "attack", "retreat"] or not saved.ended is bool or not schema.text(saved.result) or not schema.number(saved.damage_dealt, 0, 2000):
		return {"ok": false, "reason": "invalid_battle_fields"}
	if not _save_direction(saved.player_move) or not _save_direction(saved.player_aim) or not is_equal_approx(saved.player_aim.length(), 1.0) or not schema.keys(saved.cooldowns, ["attack", "sweep", "lunge", "guard"]):
		return {"ok": false, "reason": "invalid_battle_input"}
	for action in saved.cooldowns:
		var maximum: float = selected[action + "_cooldown"]
		if not schema.number(saved.cooldowns[action], 0, maximum):
			return {"ok": false, "reason": "invalid_battle_cooldown"}
	var candidate := BattleSimulation.new()
	candidate.reset_from_ticket(ticket)
	if not schema.array(saved.units, 40) or saved.units.size() != candidate.units.size() or not schema.array(saved.events):
		return {"ok": false, "reason": "invalid_battle_roster"}
	for index in range(saved.units.size()):
		var unit: Variant = saved.units[index]
		var initial: Dictionary = candidate.units[index]
		if not schema.keys(unit, initial.keys()):
			return {"ok": false, "reason": "invalid_unit_shape"}
		for field in ["id", "team", "hero", "max_hp", "speed", "damage", "condition_damage_scale", "condition_speed_scale", "range", "weapon", "roster_id", "force_id"]:
			if typeof(unit[field]) != typeof(initial[field]) or unit[field] != initial[field]:
				return {"ok": false, "reason": "changed_unit_identity_or_equipment"}
		if not schema.number(unit.hp, 0, initial.hp) or not unit.pos is Vector2 or not unit.pos.is_finite() or unit.pos != unit.pos.clamp(-FIELD_HALF, FIELD_HALF) or not _save_direction(unit.facing) or not schema.integer(unit.target, -1, saved.units.size() - 1):
			return {"ok": false, "reason": "invalid_unit_state"}
		for pair in [["attack_cd", 1.1], ["guard", selected.guard_duration if initial.hero else 0.0], ["flash", 0.12], ["swing", 0.24]]:
			if not schema.number(unit[pair[0]], 0, pair[1]):
				return {"ok": false, "reason": "invalid_unit_timer"}
	for event in saved.events:
		if not _save_event_valid(event, saved.units.size()):
			return {"ok": false, "reason": "invalid_battle_event"}
	candidate.units.assign(saved.units.duplicate(true))
	candidate.order = saved.order
	candidate._check_result()
	if candidate.ended != saved.ended or candidate.result != saved.result:
		return {"ok": false, "reason": "inconsistent_battle_end"}
	# Everything that can fail is above. These assignments cannot execute game code.
	reset_from_ticket(ticket)
	units.assign(saved.units.duplicate(true))
	events.assign(saved.events.duplicate(true))
	rng.state = saved.rng_state
	elapsed = saved.elapsed
	order = saved.order
	ended = saved.ended
	result = saved.result
	player_move = saved.player_move
	player_aim = saved.player_aim
	cooldowns = saved.cooldowns.duplicate(true)
	damage_dealt = saved.damage_dealt
	return {"ok": true}

func _save_direction(value: Variant) -> bool:
	return value is Vector2 and value.is_finite() and value.length_squared() <= 1.00001

func _save_event_valid(event: Variant, count: int) -> bool:
	var schema := preload("res://scripts/campaign_schema.gd")
	if not event is Dictionary or not event.get("type") is String or (event.has("name") and not event.name is String) or not event.get("pos") is Vector2 or not event.pos.is_finite():
		return false
	match event.get("type"):
		"order":
			return schema.keys(event, ["type", "name", "pos"]) and event.name in ["follow", "attack", "retreat"]
		"death":
			return schema.keys(event, ["type", "id", "pos"]) and schema.integer(event.id, 0, count - 1)
		"skill":
			return schema.keys(event, ["type", "name", "pos", "facing"]) and cooldowns.has(event.name) and _save_direction(event.facing)
	return false
