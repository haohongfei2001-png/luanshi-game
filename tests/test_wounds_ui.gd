extends SceneTree
const Setup := preload("res://scripts/wound_persistence_smoke.gd")
const UI := preload("res://scripts/youth_ui.gd")
const Map := preload("res://scripts/strategy_view.gd")
var checks := 0
var failures: Array[String] = []
func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label); push_error(label)
func press(panel: Control, button: Button) -> void:
	for i in range(3): await process_frame
	panel.scroll.ensure_control_visible(button)
	for i in range(4): await process_frame
	check(panel.scroll.get_global_rect().encloses(button.get_global_rect()), "control reachable")
	button.grab_focus()
	var key := InputEventKey.new(); key.keycode = KEY_ENTER; key.physical_keycode = KEY_ENTER; key.pressed = true
	root.push_input(key, true)
	key.pressed = false; root.push_input(key, true)
	for i in range(4): await process_frame
func run() -> void:
	root.size = Vector2i(1280, 800)
	var helper := Setup.new(); var w := helper.build()
	check(helper.failures.is_empty(), "real injured youth")
	var ui := UI.new(); ui.world = w; root.add_child(ui)
	ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for i in range(3): await process_frame
	check(ui.action_buttons.size() == 4 and ui.action_buttons.has("endure") and ui.action_buttons.has("appeal") and ui.action_buttons.has("keep_evidence") and ui.action_buttons.has("protect_comrade"), "injustice original four options intact")
	check(ui.wounds_label.text.contains("1:1") and ui.wounds_label.text.contains("90.3") and not ui.buttons.rest_wounds_1.disabled, "injury and actual source visible")
	check(ui.wounds_label.text.contains("世界") and ui.buttons.rest_wounds_6.text.contains("最多"), "cost and duration visible")
	var before := w.export_campaign_state()
	ui.set_blocked(true)
	check(ui.buttons.rest_wounds_1.disabled and ui.buttons.rest_wounds_6.disabled, "blocked care disabled")
	ui.buttons.rest_wounds_1.pressed.emit()
	check(w.export_campaign_state() == before, "blocked signal does not act")
	ui.set_blocked(false)
	await press(ui, ui.buttons.rest_wounds_1)
	check(w.snapshot().time_seconds == before.world.time_seconds + 3600.0 and w.snapshot().commander.hp == before.world.commander.hp + 5.0, "keyboard triggers real hour and recovery")
	check(ui.feedback.text.contains("恢复 5.0") and ui.action_buttons.size() == 4, "feedback with intact story options")
	await capture(ui, "wounds-care")
	var after := w.export_campaign_state()
	ui.hide(); await process_frame; ui.show(); ui.refresh()
	check(w.export_campaign_state() == after, "hide show no healing")
	check(w.restore_campaign_state(before).ok, "reload before care")
	ui.refresh()
	check(ui.wounds_label.text.contains("恢复 0.0"), "read-before restores injury")
	await press(ui, ui.buttons.rest_wounds_1)
	check(w.export_campaign_state() == after, "repeat from same save exact no duplication")
	check(w.youth_action("keep_evidence").ok and w.youth_action("accept_appointment").ok and w.youth_action("dangerous_march").ok, "head toward battle")
	ui.refresh(); check(ui.buttons.rest_wounds_1.disabled, "hostile depot disables care")
	var r := w.create_battle_ticket(); check(r.ok, "reserve actual fight")
	ui.refresh(); check(ui.buttons.rest_wounds_1.disabled and ui.buttons.rest_wounds_6.disabled, "reservation disables UI")
	ui.queue_free(); await process_frame
	helper = Setup.new(); var tech := helper.build("technical")
	check(helper.failures.is_empty(), "real technical injured retreat")
	var map := Map.new(); map.world = tech; root.add_child(map)
	map.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for i in range(3): await process_frame
	check(not map.buttons.rest1.disabled and map.wounds_label.text.contains("战斗 1:1"), "technical care source")
	before = tech.export_campaign_state()
	await press(map, map.buttons.rest1)
	check(tech.snapshot().commander.hp == before.world.commander.hp + 5.0 and tech.snapshot().time_seconds == before.world.time_seconds + 3600.0, "technical real keyboard action")
	await capture(map, "wounds-technical")
	map.queue_free(); await process_frame
	print("WOUNDS_UI_SUMMARY " + JSON.stringify({"checks": checks, "failures": failures, "input": "Viewport keyboard events", "rendered": DisplayServer.get_name() != "headless"}))
	quit(0 if failures.is_empty() else 1)
func capture(panel: Control, label: String) -> void:
	if "--capture-wounds" not in OS.get_cmdline_user_args(): return
	check(DisplayServer.get_name() != "headless", "real display required")
	if DisplayServer.get_name() == "headless": return
	panel.scroll.ensure_control_visible(panel.wounds_label)
	for i in range(5): await process_frame
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://artifacts")
	var picture := root.get_texture().get_image()
	check(not picture.is_empty() and picture.save_png("res://artifacts/%s-proof.png" % label) == OK, "rendered " + label)
