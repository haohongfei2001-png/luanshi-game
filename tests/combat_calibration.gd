class_name CombatCalibration
extends RefCounted
## Repeatable input policies on actual BattleSim movement/actions and soldier AI.
## Fixture arrangement is the only direct state setup. No direct damage in runs.

const Simulation := preload("res://scripts/battle_sim.gd")
const Profiles := preload("res://scripts/hero_combat_profiles.gd")
const SEEDS := [184, 7, 19, 41, 73, 101, 227, 389, 613, 997]
const POLICIES := ["advance_basic", "advance_skills", "retreat_skills"]
const HORIZON_SECONDS := 45.0
const ACTION_INTERVAL_STEPS := 6 # One action at most every 100 ms, not same-frame macros.

static func fixture(profile_id: String, count: int, seed_number: int, layout: String = "front") -> BattleSimulation:
	var battle := Simulation.new()
	var reset_ok := battle.reset(seed_number, profile_id)
	assert(reset_ok)
	battle.units.clear()
	battle._initial_counts = [0, count]
	battle._player_index = count
	for i in range(count):
		var pos := Vector2(3.6, (float(i) - float(count - 1) / 2.0) * 1.2)
		if layout == "contact":
			# Ten fit around this circumference. Thirty is an intentionally crowded
			# effective-contact stress fixture, NOT a formation/archery simulation.
			pos = Vector2.RIGHT.rotated(TAU * float(i) / count) * 1.6
		battle.units.append(battle._unit(i, 1, pos, false))
	battle.units.append(battle._unit(count, 0, Vector2.ZERO, true))
	return battle

static func nearest_enemy(battle: BattleSimulation) -> Dictionary:
	var nearest: Dictionary = {}
	var best := INF
	for unit in battle.units:
		if unit.team != 1 or unit.hp <= 0.0:
			continue
		var distance: float = unit.pos.distance_squared_to(battle.player().pos)
		if distance < best:
			best = distance
			nearest = unit
	return nearest

static func input_frame(battle: BattleSimulation, policy: String, accepted: Dictionary, action_tick: bool) -> void:
	var target := nearest_enemy(battle)
	if target.is_empty():
		return
	var delta: Vector2 = target.pos - battle.player().pos
	var distance := delta.length()
	var toward := delta.normalized()
	var movement := toward if distance > battle.player().range * 0.85 else Vector2.ZERO
	if policy == "retreat_skills" and distance < battle.player().range * 0.92:
		movement = -toward
	battle.set_player_input(movement, toward)
	if not action_tick:
		return
	if policy != "advance_basic":
		# Decisions use observable distance and the player's own action availability,
		# not enemy RNG, hidden attack cooldowns, or foreknowledge of future hits.
		if distance <= 1.9 and battle.use_action("guard"):
			accepted.guard += 1
			return
		if distance <= battle.hero_profile.sweep_range and battle.use_action("sweep"):
			accepted.sweep += 1
			return
		# Forward lunge can commit into a group. No teleport/reposition bypass.
		if distance <= battle.hero_profile.lunge_distance and distance > 0.65 and battle.use_action("lunge"):
			accepted.lunge += 1
			return
	# Re-aim after lunge using the actual current position.
	target = nearest_enemy(battle)
	if not target.is_empty():
		delta = target.pos - battle.player().pos
		battle.set_player_input(movement, delta)
		if delta.length() <= battle.player().range and battle.use_action("attack"):
			accepted.attack += 1

static func run(profile_id: String, count: int, seed_number: int, policy: String) -> Dictionary:
	var battle := fixture(profile_id, count, seed_number)
	var accepted := {"attack": 0, "sweep": 0, "lunge": 0, "guard": 0}
	var steps := 0
	var distance_moved := 0.0
	var received := 0.0
	var lowest_hp: float = battle.player().hp
	var digest := HashingContext.new()
	digest.start(HashingContext.HASH_SHA256)
	while not battle.ended and steps < int(HORIZON_SECONDS / Simulation.FIXED_DELTA):
		var before: Vector2 = battle.player().pos
		var hp: float = battle.player().hp
		input_frame(battle, policy, accepted, steps % ACTION_INTERVAL_STEPS == 0)
		battle.step(Simulation.FIXED_DELTA)
		distance_moved += before.distance_to(battle.player().pos)
		received += hp - battle.player().hp
		lowest_hp = minf(lowest_hp, battle.player().hp)
		# State transcript includes all positions/HP, cooldowns, events and RNG state;
		# wall-clock timings are deliberately excluded from repeatability evidence.
		digest.update(var_to_bytes([battle.units, battle.cooldowns, battle.events, battle.rng.state]))
		battle.events.clear()
		steps += 1
	return {"profile": profile_id, "enemy_count": count, "seed": seed_number,
		"policy": policy, "steps": steps, "seconds": snappedf(battle.elapsed, 0.0001),
		"outcome": "victory" if battle.alive_count(1) == 0 else ("dead" if battle.player().hp <= 0.0 else "timeout"),
		"kills": count - battle.alive_count(1), "hp": snappedf(battle.player().hp, 0.0001),
		"damage_dealt": snappedf(battle.damage_dealt, 0.0001),
		"damage_received": snappedf(received, 0.0001), "minimum_hp": snappedf(lowest_hp, 0.0001),
		"distance_moved": snappedf(distance_moved, 0.0001), "accepted_actions": accepted,
		"trace_sha256": digest.finish().hex_encode()}

static func focused_contact(profile_id: String, count: int, seed_number: int, guarded: bool) -> Dictionary:
	var battle := fixture(profile_id, count, seed_number, "contact")
	if guarded:
		battle.use_action("guard")
	var ready := 0
	for unit in battle.units:
		if not unit.hero and unit.pos.distance_to(battle.player().pos) <= unit.range and unit.attack_cd <= 0.0:
			ready += 1
	# This is the real soldier AI/hit queue, not N * damage or direct _hurt calls.
	battle.set_player_input(Vector2.ZERO, Vector2.RIGHT)
	battle.step(Simulation.FIXED_DELTA)
	var fired := 0
	for unit in battle.units:
		if not unit.hero and unit.attack_cd > 0.0:
			fired += 1
	return {"profile": profile_id, "enemy_count": count, "seed": seed_number,
		"guarded": guarded, "eligible_contact_attackers": ready, "scheduled_attacks": fired,
		"player_hp": snappedf(battle.player().hp, 0.0001), "ended": battle.ended,
		"seconds": snappedf(battle.elapsed, 0.0001)}

static func organized_surround(profile_id: String, count: int, seed_number: int) -> Dictionary:
	var battle := fixture(profile_id, count, seed_number)
	for i in range(count):
		# Ten per ring; bodies start separated. All movement and later spacing are AI.
		var ring := i / 10
		var angle := TAU * float(i % 10) / 10.0 + float(ring) * 0.12
		battle.units[i].pos = Vector2.RIGHT.rotated(angle) * (2.4 + float(ring) * 1.2)
	battle.use_action("guard")
	battle.set_player_input(Vector2.ZERO, Vector2.RIGHT)
	var total_attacks := 0
	var maximum_same_step := 0
	var steps := 0
	while not battle.ended and steps < 180:
		var previous_cooldowns: Array[float] = []
		for unit in battle.units:
			if not unit.hero:
				previous_cooldowns.append(unit.attack_cd)
		battle.step(Simulation.FIXED_DELTA)
		var fired := 0
		for i in range(count):
			# A soldier's cooldown only increases when its actual AI schedules a hit.
			if battle.units[i].attack_cd > previous_cooldowns[i]:
				fired += 1
		total_attacks += fired
		maximum_same_step = maxi(maximum_same_step, fired)
		steps += 1
	return {"profile": profile_id, "enemy_count": count, "seed": seed_number,
		"policy": "stationary_guard_once", "total_scheduled_attacks": total_attacks,
		"maximum_attacks_in_one_step": maximum_same_step, "player_hp": battle.player().hp,
		"ended": battle.ended, "seconds": snappedf(battle.elapsed, 0.0001)}

static func summarize(rows: Array[Dictionary]) -> Array[Dictionary]:
	var aggregates: Array[Dictionary] = []
	for profile_id in [Profiles.EARLY, Profiles.LATE, Profiles.LEGACY]:
		for policy in POLICIES:
			for count in [1, 2, 5]:
				var group: Array[Dictionary] = []
				for row in rows:
					if row.profile == profile_id and row.policy == policy and row.enemy_count == count:
						group.append(row)
				if group.is_empty():
					continue
				var item := {"profile": profile_id, "policy": policy, "enemies": count, "runs": group.size(),
					"victories": 0, "deaths": 0, "timeouts": 0, "mean_hp": 0.0, "mean_seconds": 0.0,
					"mean_kills": 0.0, "min_hp": INF, "max_hp": 0.0}
				for row in group:
					item.victories += 1 if row.outcome == "victory" else 0
					item.deaths += 1 if row.outcome == "dead" else 0
					item.timeouts += 1 if row.outcome == "timeout" else 0
					item.mean_hp += row.hp / group.size()
					item.mean_seconds += row.seconds / group.size()
					item.mean_kills += float(row.kills) / group.size()
					item.min_hp = minf(item.min_hp, row.hp)
					item.max_hp = maxf(item.max_hp, row.hp)
				for key in ["mean_hp", "mean_seconds", "mean_kills", "min_hp", "max_hp"]:
					item[key] = snappedf(item[key], 0.001)
				aggregates.append(item)
	return aggregates
