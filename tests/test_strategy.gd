extends SceneTree
## Real Viewport keyboard/mouse integration. No hidden WorldSim truth reads.
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

func battle_state() -> String:
	return var_to_str([scene.sim.units, scene.sim.elapsed, scene.sim.cooldowns, scene.sim.order, scene.sim.ended, scene.sim.result])

func _run() -> void:
	scene = load("res://scenes/battle.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	ui = scene.strategy
	check(not ui.visible, "battle remains initial experience")
	check(InputMap.has_action("toggle_strategy"), "M has a device-independent action")
	# Kill a real soldier before opening so persistence checks include casualties.
	scene.sim._hurt(scene.sim.units[1], 100000, false)
	key(KEY_M)
	var original := battle_state()
	check(ui.visible and scene.paused and not scene.hud.visible, "M opens strategic modal and suspends battle")
	for i in range(5):
		await physics_frame
	check(battle_state() == original, "battle state including casualties is frozen")
	key(KEY_P)
	key(KEY_R)
	key(KEY_SPACE)
	check(battle_state() == original and scene.paused, "battle keys cannot pause/restart/cast through modal")
	check(ui.view.army.soldiers == 60 and ui.view.army.weapons == 30 and ui.view.army.food == 120, "independent force starts with actual inventory")
	check(ui.view.local_city.id == "pingling", "only local city truth presented")
	check(ui.view.known.anping.observed_at == -72 and not ui.view.known.has("hequ"), "old Anping intel and unknown Hequ retained")
	check(ui.reports_label.text.contains("observed h-72 / delivered h0") and ui.reports_label.text.contains("Anping relief messenger"), "report provenance and both timestamps visible in English")
	await click("food")
	check(ui.view.army.food == 180 and ui.view.local_city.food == 440, "food button transfers real stocks")
	await click("weapons")
	check(ui.view.army.weapons == 40 and ui.view.local_city.weapons == 10, "equipment button withdraws real garrison weapons")
	await click("observe")
	check(ui.view.known.pingling.observed_at == 0 and ui.reports_label.text.contains("Local eyewitness scout"), "observe creates delivered local report")
	await click("river")
	check(ui.view.army.march.destination == "hequ" and ui.view.local_city.is_empty(), "route button dispatches real army and hides local truth")
	check(ui.buttons.road.disabled and ui.buttons.observe.disabled and ui.buttons.food.disabled and ui.buttons.seize.disabled, "illegal transit actions disabled")
	await click("wait1")
	check(ui.view.hour == 1 and ui.view.army.food == 174, "advance button moves clock and consumes food")
	await click("wait1")
	await click("wait1")
	check(ui.view.local_city.id == "hequ" and ui.view.local_city.owner == "bei", "arrival reveals actual local ownership")
	check(not ui.buttons.seize.disabled and ui.buttons.food.disabled, "enemy depot can be attacked but not freely looted")
	await click("seize")
	check(ui.view.army.soldiers == 56 and ui.view.army.weapons == 36 and ui.view.local_city.owner == "sheng", "depot action incurs actual soldiers and weapon losses")
	check(not ui.buttons.food.disabled and ui.buttons.seize.disabled, "capture enables supplies but not repeated assault")
	await click("food")
	check(ui.view.army.food == 222, "captured existing supplies can be taken locally")
	check(battle_state() == original, "world combat and resources never alter suspended battle")
	await click("reset")
	check(ui.view.hour == 0 and ui.view.army.soldiers == 60 and ui.view.army.food == 120, "restart resets independent WorldSim only")
	check(battle_state() == original, "world restart preserves battle casualties")
	# Remain away from Anping while its unseen siege resolves; reports stay historical.
	for i in range(4):
		await click("wait6")
	check(ui.view.hour == 24 and ui.view.known.anping.observed_at == -72, "remote fall is not leaked before messenger arrives")
	check(ui.view.known.anping.contents.owner == "sheng", "stale reported ownership is not silently refreshed")
	check(not ui.local_label.text.contains("Anping"), "local inventory panel does not show remote truth")
	await click("wait6")
	check(ui.view.known.anping.contents.owner == "bei" and ui.view.known.anping.observed_at == 15, "delayed outcome becomes known only upon delivery")
	check(ui.reports_label.text.contains("observed h15 / delivered h27"), "twelve-hour messenger delay remains explicit")
	await click("reset")
	# Late arrival exposes local truth without replacing stale delivered intelligence.
	await click("wait6")
	for i in range(4):
		await click("wait1")
	await click("road")
	await click("wait6")
	check(ui.view.hour == 16 and ui.view.local_city.owner == "bei", "late arrival reveals local captured city")
	check(ui.view.known.anping.contents.owner == "sheng", "local truth does not rewrite past report")
	await click("observe")
	check(ui.view.known.anping.contents.owner == "bei" and ui.view.known.anping.observed_at == 16, "observation explicitly updates delivered knowledge")
	await click("close")
	check(not ui.visible and not scene.paused and scene.hud.visible, "close button restores battle's previous running state")
	# Click entry from an already-paused battle, close by M, preserve prior pause.
	key(KEY_P)
	check(scene.paused, "battle pause activated")
	var paused_state := battle_state()
	click_control(scene.hud.strategy_button)
	await process_frame
	check(ui.visible and scene.paused, "clickable HUD entry opens strategy")
	key(KEY_M)
	check(not ui.visible and scene.paused, "M restores previously paused state")
	check(battle_state() == paused_state, "repeated openings never reset battle")
	# Completed encounter must remain completed after independently restarting world.
	key(KEY_P)
	scene.sim._hurt(scene.sim.player(), 100000, false)
	await physics_frame
	await physics_frame
	var ended_state := battle_state()
	key(KEY_M)
	await click("reset")
	key(KEY_R)
	key(KEY_M)
	check(scene.sim.ended and battle_state() == ended_state, "ended battle cannot be resurrected by strategy reset or R")
	scene.queue_free()
	await process_frame
	print("STRATEGY_TEST_SUMMARY " + JSON.stringify({"assertions": checks, "failures": failures.size(), "messages": failures}))
	quit(0 if failures.is_empty() else 1)
