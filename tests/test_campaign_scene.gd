extends SceneTree
## Routed Viewport input verifies presentation lifecycle; controlled damage fixtures test
## casualty/death edges. Real no-injection battle is separately covered by --campaign-smoke.
var failures: Array[String] = []
var checks := 0
var scene: Node
var ui: Control

func _initialize() -> void:
	call_deferred("_run")

func check(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures.append(description)
		push_error(description)

func key(code: Key) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.keycode = code
	event.pressed = true
	root.push_input(event, true)
	event.pressed = false
	root.push_input(event, true)

func click_control(button: Control) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.position = button.get_global_rect().get_center()
	event.pressed = true
	root.push_input(event, true)
	event.pressed = false
	root.push_input(event, true)

func click(id: String) -> void:
	ui.scroll.ensure_control_visible(ui.buttons[id])
	await process_frame
	click_control(ui.buttons[id])
	await process_frame
	await process_frame

func known_state() -> String:
	return var_to_str(ui.world.player_view())

func battle_state() -> String:
	return var_to_str([scene.sim.units, scene.sim.elapsed, scene.sim.cooldowns, scene.sim.order, scene.sim.ended])

func launch() -> void:
	if not ui.visible:
		key(KEY_M)
	await click("river")
	for i in range(3):
		await click("wait1")
	await click("seize")

func _run() -> void:
	scene = load("res://scenes/battle.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	ui = scene.strategy
	scene.sim._hurt(scene.sim.units[1], 100000, false)
	key(KEY_M)
	var training: BattleSimulation = scene.sim
	var training_state := battle_state()
	await launch()
	check(not ui.visible and scene.hud.visible and not scene.paused, "assault button opens actual playable battle")
	check(scene.sim.hero_profile.id == "early_v1" and ui.world.player_view().commander.hero_profile.id == "early_v1", "normal campaign uses finite early profile")
	check(scene.campaign_adapter != null and scene.sim != training, "campaign uses adapter session, not training state")
	check(scene.views.size() == 35 and scene.sim.alive_count(0, true) == 20 and scene.sim.alive_count(1) == 15, "20 world people including hero meet the actual 15 defenders")
	check(scene.hud.campaign_mode and scene.hud._unarmed(0) == 10, "ten unarmed soldiers visibly match the scarce world weapon allocation")
	check(ui.world.player_view().army.soldiers == 60, "forty reserves are neither duplicated nor removed by presentation")
	check(scene.hud.restart_button.text.contains("RETURN TO CAMPAIGN"), "campaign result button is not a tactical restart")
	var first_id: String = ui.world.player_view().active_battle
	check(not first_id.is_empty(), "running battle has one world reservation")
	var elapsed: float = scene.sim.elapsed
	for i in range(10):
		await physics_frame
	check(scene.sim.elapsed > elapsed and is_equal_approx(ui.world.player_view().time_seconds, 10800.0 + scene.sim.elapsed), "real scene steps advance the same world clock")
	key(KEY_M)
	var pending_state := known_state()
	var pending_sim := battle_state()
	for id in ["wait1", "wait6", "river", "grain_road", "observe", "food", "weapons", "seize", "reset"]:
		check(ui.buttons[id].disabled, "pending battle locks world button: " + id)
		await click(id)
	key(KEY_R)
	key(KEY_P)
	key(KEY_SPACE)
	ui._command("reset")
	ui._command("advance", "", 6)
	ui._command("seize")
	check(known_state() == pending_state and battle_state() == pending_sim, "disabled clicks, hotkeys and command guard cannot mutate a pending battle")
	await click("close")
	key(KEY_P)
	check(scene.paused, "pause key still works after returning to campaign combat")
	key(KEY_R)
	check(scene.sim.ended == false and ui.world.player_view().active_battle == first_id, "R cannot replace active campaign roster")
	key(KEY_P)
	key(KEY_1)
	check(scene.sim.order == "attack", "routed army order reaches campaign BattleSim")
	# Controlled outcomes verify casualties/equipment through normal automatic settlement.
	var killed := 0
	for unit in scene.sim.units:
		if unit.team == 0 and not unit.hero and killed < 2:
			scene.sim._hurt(unit, 100000, false)
			killed += 1
		elif unit.team == 1:
			scene.sim._hurt(unit, 100000, false)
	scene.sim._hurt(scene.sim.player(), 17.0, false)
	await physics_frame
	await physics_frame
	check(scene.sim.ended and scene.campaign_settlement.get("ok", false), "finished real roster automatically settles before results return")
	var won: Dictionary = ui.world.player_view()
	check(won.army.soldiers == 58 and won.army.weapons == 45, "two actual casualties return once and existing enemy weapons transfer once")
	check(won.local_city.owner == "sheng" and won.local_city.soldiers == 0 and won.active_battle == "", "victory captures local depot and releases reservation")
	check(is_equal_approx(won.commander.hp, scene.sim.player().hp) and won.commander.hp < 100, "hero damage persists beyond battle")
	check(scene.hud.result_panel.visible and scene.hud.result_label.text.contains("recorded"), "results explicitly confirm world settlement")
	var settled_state := known_state()
	key(KEY_R)
	check(ui.visible and ui.buttons.seize.disabled and not ui.buttons.food.disabled, "R returns to usable campaign without respawning conquered enemy")
	check(ui.feedback.text.contains("2 fallen"), "map reports actual detachment casualty count")
	key(KEY_M)
	click_control(scene.hud.restart_button)
	await process_frame
	check(ui.visible and known_state() == settled_state, "result return button and reopening do not repeat transaction")
	ui._command("seize")
	check(ui.visible and known_state() == settled_state, "repeated assault cannot replay already captured depot")
	await click("food")
	check(ui.view.army.food == won.army.food + 60, "victory unlocks existing captured supplies through the UI")
	await click("reset")
	check(ui.view.hour == 0 and ui.view.army.soldiers == 60 and not ui.view.campaign_ended, "explicit new-campaign button starts a new world")
	check(scene.sim == training and battle_state() == training_state, "new campaign restores suspended training including its fallen soldier")
	# Death must settle casualties first, then lock every world action in that same life.
	await launch()
	var death_id: String = ui.world.player_view().active_battle
	scene.sim._hurt(scene.sim.player(), 100000, false)
	await physics_frame
	await physics_frame
	var dead: Dictionary = ui.world.player_view()
	check(scene.campaign_settlement.get("ok", false) and dead.campaign_ended and not dead.commander.alive, "hero death ends campaign only after consequences settle")
	check(dead.army.soldiers == 59 and dead.army.weapons == 29 and dead.active_battle == "", "dead hero and his destroyed weapon are counted exactly once")
	check(scene.hud.result_label.text.contains("Campaign ended"), "death result communicates permanent end of this life")
	key(KEY_R)
	var death_state := known_state()
	for id in ["wait1", "wait6", "river", "grain_road", "observe", "food", "weapons", "seize"]:
		check(ui.buttons[id].disabled, "dead commander cannot issue action: " + id)
		await click(id)
	check(not ui.buttons.reset.disabled and ui.status_label.text.contains("CAMPAIGN ENDED"), "new life is explicit and old known reports remain viewable")
	key(KEY_R)
	key(KEY_M)
	key(KEY_R)
	check(ui.visible and scene.sim.ended and known_state() == death_state, "R and reopening do not revive hero or duplicate death settlement")
	check(ui.view.known.anping.observed_at == -72 and not ui.local_label.text.contains("Anping"), "death epilogue never leaks unseen remote world truth")
	await click("reset")
	check(not ui.view.campaign_ended and ui.view.commander.alive and ui.view.army.soldiers == 60, "only explicit new campaign permits a new protagonist life")
	await launch()
	check(ui.world.player_view().active_battle != death_id and ui.world.player_view().active_battle != first_id, "new campaigns cannot reuse prior transaction IDs")
	# Wounded commander/real soldier loss survive a withdrawal and a later encounter.
	scene.sim._hurt(scene.sim.player(), 20.0, false)
	scene.sim._hurt(scene.sim.units[1], 100000, false)
	var retreat_id: String = ui.world.player_view().active_battle
	# Real routed physical withdrawal, no fabricated end flag or position edits.
	key(KEY_3)
	Input.action_press("move_left")
	for i in range(360):
		if scene.sim.ended:
			break
		await physics_frame
	Input.action_release("move_left")
	await physics_frame
	check(scene.sim.ended and scene.campaign_settlement.get("result", "") == "retreat", "physical player movement plus retreat order ends and settles campaign encounter")
	key(KEY_R)
	check(ui.visible and ui.view.local_city.owner == "bei" and not ui.buttons.seize.disabled, "retreat returns survivors and permits a later distinct assault")
	check(ui.view.army.soldiers == 59 and ui.view.army.weapons == 29 and is_equal_approx(ui.view.commander.hp, 80.0), "withdrawal preserves actual casualty, lost equipment and hero wound")
	await click("seize")
	check(not ui.visible and ui.world.player_view().active_battle != retreat_id, "a renewed assault receives a distinct transaction")
	check(is_equal_approx(scene.sim.player().hp, 80.0) and scene.hud._unarmed(0) == 11, "later battle reads wounded hero and increased scarcity rather than reset defaults")
	key(KEY_3)
	Input.action_press("move_left")
	for i in range(360):
		if scene.sim.ended:
			break
		await physics_frame
	Input.action_release("move_left")
	await physics_frame
	key(KEY_R)
	check(ui.visible and ui.view.army.soldiers == 59 and ui.view.army.weapons == 29, "second safe withdrawal does not count old casualties or weapon loss again")
	check(ui.reports_label.text.contains("Exact: observed h3") and ui.reports_label.text.contains(" / age 0h"), "fractional battle observation exposes exact timestamps and report age")
	var departure: float = ui.view.time_seconds
	check(departure > 10800.0 and departure < 10860.0 and ui.army_label.text.contains("World h3 00m"), "campaign clock visibly retains battle seconds")
	await click("river")
	check(is_equal_approx(ui.view.army.march.arrives_at_seconds - departure, 10800.0), "routed departure after battle schedules exactly three hours")
	check(ui.army_label.text.contains("3h 00m 00.0s remaining") and not ui.army_label.text.contains("4h"), "fractional departure displays three-hour travel, not rounded-up four-hour ETA")
	await click("wait1")
	check(ui.army_label.text.contains("2h 00m 00.0s remaining"), "routed time advancement reduces precise remaining duration")
	await click("wait1")
	await click("wait1")
	check(ui.view.army.location == "pingling" and is_equal_approx(ui.view.time_seconds, departure + 10800.0), "route arrival preserves the fractional world clock")
	check(ui._time_text(1.0) == "0h 00m 01.0s" and ui._time_text(3599.96) == "1h 00m 00.0s", "ETA formatter displays seconds near arrival and carries rounding correctly")
	check(ui.world.audit().is_empty(), "UI flow ends with conserved world resources")
	scene.queue_free()
	await process_frame
	print("CAMPAIGN_SCENE_TEST_SUMMARY " + JSON.stringify({"assertions": checks, "failures": failures.size(), "messages": failures}))
	quit(0 if failures.is_empty() else 1)
