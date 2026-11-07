extends SceneTree
## Graphical CI only: real map clicks, adapter roster, physical retreat and return.
var scene: Node

func _initialize() -> void:
	call_deferred("_run")

func key(code: Key) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.keycode = code
	event.pressed = true
	root.push_input(event, true)
	event.pressed = false
	root.push_input(event, true)

func click(id: String) -> void:
	var button: Button = scene.strategy.buttons[id]
	scene.strategy.scroll.ensure_control_visible(button)
	await process_frame
	var mouse := InputEventMouseButton.new()
	mouse.button_index = MOUSE_BUTTON_LEFT
	mouse.position = button.get_global_rect().get_center()
	mouse.pressed = true
	root.push_input(mouse, true)
	mouse.pressed = false
	root.push_input(mouse, true)
	await process_frame
	await process_frame

func capture(path: String) -> bool:
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://artifacts")
	return root.get_texture().get_image().save_png(path) == OK

func _run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Strategy visual proof requires a real graphical renderer")
		quit(1)
		return
	scene = load("res://scenes/battle.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	key(KEY_M)
	for id in ["river", "wait1", "wait1", "wait1", "seize"]:
		await click(id)
	if scene.strategy.visible or scene.campaign_adapter == null or scene.views.size() != 35 or scene.hud._unarmed(0) != 10:
		push_error("Graphical campaign launch failed")
		quit(1)
		return
	if not await capture("res://artifacts/campaign-launch-proof.png"):
		push_error("Could not save campaign roster visual evidence")
		quit(1)
		return
	key(KEY_3)
	Input.action_press("move_left")
	for i in range(360):
		if scene.sim.ended:
			break
		await physics_frame
	Input.action_release("move_left")
	await physics_frame
	if not scene.sim.ended or scene.campaign_settlement.get("result", "") != "retreat":
		push_error("Graphical campaign withdrawal failed")
		quit(1)
		return
	key(KEY_R)
	await process_frame
	scene.strategy.scroll.scroll_vertical = 0
	await process_frame
	await process_frame
	var known: Dictionary = scene.strategy.world.player_view()
	if not scene.strategy.visible or known.hour != 3 or known.local_city.owner != "bei" or known.active_battle != "" or known.army.soldiers != 60:
		push_error("Graphical strategic return failed")
		quit(1)
		return
	if not await capture("res://artifacts/strategy-proof.png"):
		push_error("Could not save strategic visual evidence")
		quit(1)
		return
	print("STRATEGY_VISUAL_PASS " + JSON.stringify({"flow": "map_to_campaign_to_retreat_to_map", "roster": "20 including commander vs 15", "unarmed": 10, "world_time_seconds": known.time_seconds}))
	quit(0)
