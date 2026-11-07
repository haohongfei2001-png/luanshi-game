extends SceneTree
## Graphical CI only. Uses the actual modal and real Viewport input.
func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Strategy visual proof requires a real graphical renderer")
		quit(1)
		return
	var scene: Node = load("res://scenes/battle.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	var event := InputEventKey.new()
	event.physical_keycode = KEY_M
	event.pressed = true
	root.push_input(event, true)
	event.pressed = false
	root.push_input(event, true)
	for id in ["river", "wait1", "wait1", "wait1", "seize", "observe"]:
		await process_frame
		await process_frame
		var button: Button = scene.strategy.buttons[id]
		var mouse := InputEventMouseButton.new()
		mouse.button_index = MOUSE_BUTTON_LEFT
		mouse.position = button.get_global_rect().get_center()
		mouse.pressed = true
		root.push_input(mouse, true)
		mouse.pressed = false
		root.push_input(mouse, true)
	await process_frame
	await process_frame
	if not scene.strategy.visible or scene.strategy.view.hour != 3 or scene.strategy.view.local_city.owner != "sheng":
		push_error("Graphical strategic action flow failed")
		quit(1)
		return
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://artifacts")
	var error := root.get_texture().get_image().save_png("res://artifacts/strategy-proof.png")
	if error != OK:
		push_error("Could not save strategic visual evidence: " + str(error))
		quit(1)
		return
	print("STRATEGY_VISUAL_PASS")
	quit(0)
