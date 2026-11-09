extends SceneTree
## Explicit legacy mechanics/parity fixture; normal early gameplay tested separately.

const Simulation := preload("res://scripts/battle_sim.gd")
var assertions := 0
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func check(condition: bool, message: String) -> void:
	assertions += 1
	if not condition:
		failures.append(message)
		push_error("FAIL: " + message)

func fresh() -> BattleSimulation:
	var battle := Simulation.new()
	battle.reset(184, "legacy_test_v0")
	return battle

func _run() -> void:
	var sim := fresh()
	check(sim.units.size() == 41, "20 friendly + 20 enemy soldiers + one commander")
	check(sim.alive_count(0) == 20 and sim.alive_count(1) == 20, "initial roster counts")
	check(sim.player().hero and sim.player().id == 40, "commander is separate from soldiers")
	var before: Vector2 = sim.player().pos
	sim.set_player_input(Vector2.RIGHT, Vector2.RIGHT)
	sim.step(1.0 / 60.0)
	check(sim.player().pos.x > before.x, "player moves")
	sim.player().pos = Vector2(31, 19)
	sim.set_player_input(Vector2.ONE, Vector2.RIGHT)
	sim.step(1.0 / 60.0)
	check(sim.player().pos == Vector2(31, 19), "player stays within field")

	sim = fresh()
	sim.units[20].pos = sim.player().pos + Vector2(2, 0)
	sim.units[21].pos = sim.player().pos + Vector2(-2, 0)
	check(sim.use_action("attack"), "basic attack activates")
	check(sim.units[20].hp == 74.0, "basic attack deals directional damage")
	check(sim.units[21].hp == 100.0, "basic attack does not hit behind commander")
	check(not sim.use_action("attack"), "cooldown rejects repeat attack")
	check(sim.use_action("sweep") and sim.units[20].hp == 30.0, "sweep damages targets")
	check(sim.use_action("lunge") and sim.units[20].hp == 0.0, "lunge hits along path")
	check(sim.player().pos.x > -16.0, "lunge moves commander")
	check(sim.use_action("guard"), "brace activates")
	var hp: float = sim.player().hp
	sim._hurt(sim.player(), 40, false)
	check(sim.player().hp == hp - 10, "brace reduces incoming damage by 75 percent")
	check(sim.alive_count(1) == 19, "dead soldiers remain casualties")
	check(sim.report().enemy_casualties == 1, "report accounts for deaths")
	check(not sim.use_action("unknown"), "unknown actions rejected")
	check(not sim.issue_order("unknown"), "unknown commands rejected")
	check(sim.issue_order("attack") and sim.order == "attack", "attack order")
	check(sim.issue_order("follow") and sim.order == "follow", "follow order")
	check(sim.issue_order("retreat") and sim.order == "retreat", "retreat order")

	sim = fresh()
	var initial_distance: float = sim.units[0].pos.distance_to(sim.player().pos)
	for i in range(120):
		sim.step(Simulation.FIXED_DELTA)
	check(sim.units[0].pos.distance_to(sim.player().pos) < initial_distance, "follow order closes distance")
	sim.issue_order("retreat")
	sim.player().pos = Vector2(-29, 0)
	for i in range(900):
		sim.step(Simulation.FIXED_DELTA)
	check(sim.ended and sim.result == "The company withdrew", "survivors can withdraw through gate")
	check(sim.report().friendly_survivors + sim.report().friendly_casualties == 20, "retreat roster conserved")

	sim = fresh()
	sim._hurt(sim.player(), 9999, false)
	sim.step(Simulation.FIXED_DELTA)
	check(sim.ended and not sim.report().player_alive, "protagonist death ends run")
	var elapsed := sim.elapsed
	sim.step(1.0)
	check(sim.elapsed == elapsed, "finished encounter cannot advance")
	check(not sim.issue_order("attack") and not sim.use_action("sweep"), "dead commander cannot act")
	sim.reset(184, "legacy_test_v0")
	check(not sim.ended and sim.alive_count(0) == 20 and sim.player().hp == 360, "new encounter resets state")

	var first := run_battle(184)
	var second := run_battle(184)
	check(first.report == second.report, "seeded battles are reproducible")
	check(first.report.enemy_casualties > 0 and first.report.friendly_casualties > 0, "20v20 actually fight and die")
	check(first.ended, "20v20 reaches an ending within 180 simulated seconds")
	check(first.report.enemy_survivors + first.report.enemy_casualties == 20, "enemy roster conserved")
	check(first.report.friendly_survivors + first.report.friendly_casualties == 20, "friendly roster conserved")
	print("BATTLE_REPORT " + JSON.stringify(first))
	print("TEST_SUMMARY " + JSON.stringify({"profile": "legacy_test_v0", "assertions": assertions, "failures": failures.size(), "messages": failures}))
	quit(0 if failures.is_empty() else 1)

func run_battle(seed_number: int) -> Dictionary:
	var battle := Simulation.new()
	battle.reset(seed_number, "legacy_test_v0")
	battle.issue_order("attack")
	# Commander stays outside combat to measure the two soldier armies themselves.
	battle.player().pos = Vector2(-30, -18)
	var started := Time.get_ticks_usec()
	var steps := 0
	while not battle.ended and steps < 10800:
		battle.step(Simulation.FIXED_DELTA)
		battle.events.clear()
		steps += 1
	return {"report": battle.report(), "ended": battle.ended, "steps": steps,
		"mean_step_ms": float(Time.get_ticks_usec() - started) / steps / 1000.0}
