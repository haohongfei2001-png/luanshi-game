extends SceneTree
## Reference source is materialized by the runner from the unmodified base commit.
## It is deliberately not checked in as a second production BattleSim.
const Simulation := preload("res://scripts/battle_sim.gd")
var checks := 0
var failures: Array[String] = []

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error(message)

func state(battle: RefCounted) -> Array:
	var original_units: Array = battle.units.duplicate(true)
	for unit in original_units:
		unit.erase("received_order"); unit.erase("received_order_sequence")
	return [original_units, battle.events, battle.rng.state, battle.cooldowns,
		battle.elapsed, battle.order, battle.ended, battle.result, battle.damage_dealt,
		battle.player_move, battle.player_aim, battle.report()]

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var reference_script := load("res://artifacts/legacy_reference.gd")
	if reference_script == null:
		push_error("Run tools/calibrate-combat.sh to materialize the base reference first")
		quit(1)
		return
	for seed_number in [184, 7, 997]:
		var before: RefCounted = reference_script.new()
		var after := Simulation.new()
		before.reset(seed_number)
		after.reset(seed_number, "legacy_test_v0")
		# Historical active sessions preserve this model only via explicit migration.
		after.signal_model = "legacy_global_v0"
		check(state(before) == state(after), "legacy initial state parity")
		for step_number in range(3600):
			var movement := Vector2.RIGHT if step_number < 240 else Vector2.ZERO
			var aim := Vector2.RIGHT.rotated(float(step_number / 180) * 0.2)
			before.set_player_input(movement, aim)
			after.set_player_input(movement, aim)
			for action in ["attack", "sweep", "lunge", "guard"]:
				if step_number % {"attack": 31, "sweep": 89, "lunge": 151, "guard": 191}[action] == 0:
					check(before.use_action(action) == after.use_action(action), "legacy action accepted identically")
			if step_number % 180 == 0:
				check(before.issue_order("attack") == after.issue_order("attack"), "legacy order accepted identically")
			before.step(Simulation.FIXED_DELTA)
			after.step(Simulation.FIXED_DELTA)
			check(state(before) == state(after), "legacy complete frame state parity seed=%d frame=%d" % [seed_number, step_number])
			before.events.clear()
			after.events.clear()
			if after.ended:
				break
	print("LEGACY_PROFILE_PARITY " + JSON.stringify({"checks": checks, "failures": failures}))
	quit(0 if failures.is_empty() else 1)
