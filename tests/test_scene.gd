extends SceneTree
## Headless event/scene integration, not a visual or manual playtest.
var failures: Array[String] = []
var checks := 0

func _initialize() -> void:
	call_deferred("_run")

func check(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures.append(description)
		push_error(description)

func action(scene: Node, name: String) -> void:
	var keys := {"pause_battle": KEY_P, "guard": KEY_SPACE, "restart_battle": KEY_R}
	var event := InputEventKey.new()
	event.physical_keycode = keys[name]
	event.keycode = keys[name]
	event.pressed = true
	scene.get_viewport().push_input(event, true)
	event.pressed = false
	scene.get_viewport().push_input(event, true)

func click_button(scene: Node, name: String) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.position = scene.hud.buttons[name].get_global_rect().get_center()
	event.pressed = true
	scene.get_viewport().push_input(event, true)
	event.pressed = false
	scene.get_viewport().push_input(event, true)

func _run() -> void:
	var scene: Node = load("res://scenes/battle.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	check(scene.sim.hero_profile.id == "early_v1" and scene.sim.player().max_hp == 100.0, "normal scene uses finite early profile")
	check(scene.views.size() == 41, "all unit views instantiated")
	check(scene.hud.buttons.size() == 7, "all skill and order buttons connected")
	for name in ["attack", "sweep", "lunge", "guard", "order_attack", "order_follow", "order_retreat"]:
		check(InputMap.has_action(name), "input action exists: " + name)
	for x in [-31.0, 31.0]:
		for z in [-19.0, 19.0]:
			for height in [0.0, 2.1]:
				var pixel: Vector2 = scene.camera.unproject_position(Vector3(x, height, z))
				check(scene.hud.is_world_pointer(pixel), "entire walkable field and unit heads remain outside HUD")
	var pos: Vector2 = scene.sim.player().pos
	Input.action_press("move_right")
	for i in range(15):
		await physics_frame
	Input.action_release("move_right")
	check(scene.sim.player().pos.x > pos.x, "device-independent movement action reaches simulation")
	action(scene, "pause_battle")
	var elapsed: float = scene.sim.elapsed
	for i in range(10):
		await physics_frame
	check(scene.sim.elapsed == elapsed, "pause freezes authoritative state")
	click_button(scene, "sweep")
	check(scene.sim.cooldowns.sweep == 0.0, "paused UI cannot cast a skill")
	action(scene, "pause_battle")
	action(scene, "guard")
	check(scene.sim.player().guard > 0.0, "mapped guard key activates skill")
	await physics_frame
	await process_frame
	click_button(scene, "order_attack")
	check(scene.sim.order == "attack", "attack button reaches simulation")
	click_button(scene, "order_follow")
	check(scene.sim.order == "follow", "follow button reaches simulation")
	click_button(scene, "order_retreat")
	check(scene.sim.order == "retreat", "retreat button reaches simulation")
	await process_frame
	var buttons: Array = scene.hud.buttons.values()
	for i in range(buttons.size() - 1):
		check(not buttons[i].get_rect().intersects(buttons[i + 1].get_rect()), "adjacent HUD buttons do not overlap: %d" % i)
	check(not scene.hud.is_world_pointer(Vector2(100, 750)), "HUD area does not aim or attack the world")
	var hp: float = scene.sim.player().hp
	action(scene, "restart_battle")
	check(scene.sim.player().hp == hp and scene.sim.elapsed > 0.0, "restart key cannot reset an active encounter")
	scene.sim._hurt(scene.sim.player(), 100000, false)
	await physics_frame
	await physics_frame
	check(scene.sim.ended and scene.hud.result_panel.visible, "death reveals results UI")
	action(scene, "restart_battle")
	await process_frame
	check(not scene.sim.ended and scene.views.size() == 41, "restart rebuilds one full roster")
	check(not scene.hud.result_panel.visible, "restart dismisses old results")
	scene.queue_free()
	await process_frame
	print("SCENE_TEST_SUMMARY " + JSON.stringify({"assertions": checks, "failures": failures.size(), "messages": failures}))
	quit(0 if failures.is_empty() else 1)
