extends SceneTree
## Graphical CI proof: click named saves, restore an active encounter, and revisit checkpoints.
const Store := preload("res://scripts/campaign_store.gd")
var scene: Node
var failed := false

func _initialize() -> void:
	call_deferred("_run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failed = true
		push_error(message)

func key(code: Key) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.keycode = code
	event.pressed = true
	root.push_input(event, true)
	event.pressed = false
	root.push_input(event, true)

func click(button: Control) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.position = button.get_global_rect().get_center()
	event.pressed = true
	root.push_input(event, true)
	event.pressed = false
	root.push_input(event, true)
	await process_frame
	await process_frame

func map_click(id: String) -> void:
	scene.strategy.scroll.ensure_control_visible(scene.strategy.buttons[id])
	await process_frame
	await click(scene.strategy.buttons[id])

func capture(name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://artifacts")
	check(root.get_texture().get_image().save_png("res://artifacts/" + name + ".png") == OK, "Save visual capture failed: " + name)

func _run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Campaign save visual proof requires a real graphical renderer")
		quit(1)
		return
	scene = load("res://scenes/battle.tscn").instantiate()
	scene.campaign_store = Store.new("visual_saves_" + Crypto.new().generate_random_bytes(8).hex_encode())
	root.add_child(scene)
	await process_frame
	await process_frame
	key(KEY_M)
	await map_click("saves")
	var panel: Control = scene.save_panel
	check(panel.get_global_rect().encloses(panel.panel.get_global_rect()), "Save overlay must fit inside 1280x800")
	for button in panel.buttons.values():
		check(panel.panel.get_global_rect().encloses(button.get_global_rect()), "Save action clipped: " + button.text)
	panel.slot_name.text = "before_departure"
	await click(panel.buttons.save)
	check(panel.feedback.text.contains("Saved campaign"), "Mouse Save must write the live campaign")
	await capture("save-slots-proof")
	await click(panel.buttons.checkpoint)
	check(panel.entries.item_count == 1 and panel.entries.get_item_text(0).contains("Life checkpoint"), "Life checkpoint appears with a readable creation time")
	await capture("life-checkpoints-proof")
	key(KEY_ESCAPE)
	for id in ["river", "wait1", "wait1", "wait1", "seize"]:
		await map_click(id)
	key(KEY_P)
	key(KEY_F5)
	await process_frame
	await process_frame
	await process_frame
	check(panel.feedback.text.contains("'quick'"), "F5 saves active battle")
	key(KEY_F9)
	await process_frame
	await process_frame
	await process_frame
	check(scene.campaign_adapter != null and scene.paused and scene.sim.units.size() == 35, "F9 rebinds saved real roster and waits paused")
	await capture("battle-load-proof")
	key(KEY_ESCAPE)
	key(KEY_P)
	key(KEY_3)
	Input.action_press("move_left")
	for i in range(360):
		if scene.sim.ended:
			break
		await physics_frame
	Input.action_release("move_left")
	await physics_frame
	check(scene.sim.ended and scene.campaign_settlement.get("result", "") == "retreat", "Loaded battle must continue to a real physical retreat")
	key(KEY_F6)
	panel.slot_name.text = "after_withdrawal"
	await click(panel.buttons.save)
	await click(panel.buttons.load)
	check(scene.strategy.visible and scene.campaign_adapter == null and scene.strategy.feedback.text.contains("already recorded"), "Committed save loads onto map with stored receipt")
	key(KEY_ESCAPE)
	await capture("saved-result-proof")
	check(scene.strategy.world.audit().is_empty(), "Graphical save flow keeps world audit clean")
	scene.queue_free()
	await process_frame
	if not failed:
		print("CAMPAIGN_SAVE_VISUAL_PASS named_slot checkpoint active_reload physical_retreat committed_receipt")
	quit(1 if failed else 0)
