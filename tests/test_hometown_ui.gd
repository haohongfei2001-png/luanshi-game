extends SceneTree
const W := preload("res://scripts/world_sim.gd")
const UI := preload("res://scripts/youth_ui.gd")
const Setup := preload("res://scripts/hometown_persistence_smoke.gd")
var checks := 0
var failures: Array[String] = []
var ui := UI.new()
var world: WorldSimulation
var setup := Setup.new()
func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label); push_error(label)
func click(id: String) -> void:
	check(ui.action_buttons.has(id), "real control " + id)
	if not ui.action_buttons.has(id): return
	var button: Button = ui.action_buttons[id]
	for i in range(3): await process_frame
	ui.scroll.ensure_control_visible(button)
	for i in range(4): await process_frame
	check(ui.scroll.get_global_rect().encloses(button.get_global_rect()), "reachable " + id)
	button.grab_focus()
	var key := InputEventKey.new()
	key.keycode = KEY_ENTER; key.physical_keycode = KEY_ENTER; key.pressed = true
	root.push_input(key, true)
	key.pressed = false; root.push_input(key, true)
	for i in range(4): await process_frame
func run() -> void:
	root.size = Vector2i(1280, 800)
	world = W.new()
	check(world.start_youth("forced", "homeland").ok, "new life")
	ui.world = world; root.add_child(ui)
	ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.action_requested.connect(func(id: String):
		check(world.youth_action(id).ok, "input causes actual action " + id)
		ui.refresh())
	for i in range(3): await process_frame
	check(not ui.action_buttons.has("attach_hometown_letter"), "no magical carrier")
	await click("arrange_courier")
	ui.set_blocked(true)
	check(ui.action_buttons.attach_hometown_letter.disabled, "busy blocked")
	ui.set_blocked(false)
	await click("attach_hometown_letter")
	check(not ui.action_buttons.has("attach_hometown_letter") and ui.hometown_label.text.contains("近况未知"), "no duplicate and no instant information")
	var pending := world.export_campaign_state()
	await click("first_march"); await click("wait_courier")
	check(ui.hometown_label.text.contains("亲收乡信") and ui.hometown_label.text.contains("第 1.00 时写下，第 4.00 时收到") and not ui.hometown_label.text.contains("眼下要回家照料"), "old letter visible without current omniscience")
	await capture("hometown-received")
	await click("courier_comply")
	check(setup.fight_return(world), "actual battlefield return")
	ui.refresh()
	await click("keep_evidence")
	await click("visit_hometown")
	check(ui.hometown_label.text.contains("当面相见") and not ui.action_buttons.has("visit_hometown"), "real reunion visible once")
	await capture("hometown-reunion")
	var after := world.export_campaign_state()
	ui.hide(); await process_frame
	ui.show(); ui.refresh()
	check(world.export_campaign_state() == after and not ui.action_buttons.has("visit_hometown"), "close/reopen no extra action")
	check(world.restore_campaign_state(pending).ok, "restore before travel")
	ui.refresh()
	for i in range(7): await click("wait_courier")
	check(ui.hometown_label.text.contains("近况未知") and ui.hometown_label.text.contains("可能延误或失联") and not ui.hometown_label.text.contains("仍在平陵作坊"), "unknown loss no secret text")
	await capture("hometown-unknown")
	check(setup.failures.is_empty(), "public combat setup")
	print("HOMETOWN_UI_SUMMARY " + JSON.stringify({"checks": checks, "failures": failures, "input": "Viewport keyboard events", "rendered": DisplayServer.get_name() != "headless"}))
	ui.queue_free(); await process_frame
	quit(0 if failures.is_empty() else 1)
func capture(label: String) -> void:
	if "--capture-hometown" not in OS.get_cmdline_user_args(): return
	check(DisplayServer.get_name() != "headless", "real display required")
	if DisplayServer.get_name() == "headless": return
	ui.scroll.ensure_control_visible(ui.hometown_label)
	for i in range(5): await process_frame
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://artifacts")
	var picture := root.get_texture().get_image()
	check(not picture.is_empty() and picture.save_png("res://artifacts/%s-proof.png" % label) == OK, "rendered " + label)
