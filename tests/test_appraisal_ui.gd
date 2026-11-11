extends SceneTree
const Smoke := preload("res://scripts/appraisal_persistence_smoke.gd")
const UI := preload("res://scripts/youth_ui.gd")
const W := preload("res://scripts/world_sim.gd")
var checks := 0
var failures: Array[String] = []
var ui := UI.new()
var world: WorldSimulation
func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label); push_error(label)
func click(id: String) -> void:
	check(ui.action_buttons.has(id), "real control exists: " + id)
	if not ui.action_buttons.has(id): return
	var button: Button = ui.action_buttons[id]
	for frame in range(3): await process_frame
	ui.scroll.ensure_control_visible(button)
	for frame in range(4): await process_frame
	check(ui.scroll.get_global_rect().encloses(button.get_global_rect()), "button reachable " + id)
	button.grab_focus()
	var key := InputEventKey.new()
	key.keycode = KEY_ENTER
	key.physical_keycode = KEY_ENTER
	key.pressed = true
	root.push_input(key, true)
	key.pressed = false
	root.push_input(key, true)
	for frame in range(4): await process_frame
func run() -> void:
	root.size = Vector2i(1280, 800)
	var builder := Smoke.new()
	world = builder.build("keep_evidence")
	check(builder.failures.is_empty(), "real pre-appraisal life")
	ui.world = world
	root.add_child(ui)
	ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.action_requested.connect(func(id: String):
		check(world.youth_action(id).ok, "real input action " + id)
		ui.refresh())
	for frame in range(3): await process_frame
	await click("camp_appraisal")
	check(world.youth_view().appraisal.outcome == "bargain", "keyboard activated real appraisal")
	check(ui.story_label.text.contains("四份营粮") and ui.story_label.text.contains("一点军功"), "terms visible before acceptance")
	check(ui.action_buttons.has("dangerous_march") and ui.action_buttons.has("refuse_order"), "old choices remain alongside offer")
	await capture("appraisal-offer")
	var pending := world.export_campaign_state()
	ui.set_blocked(true)
	check(ui.action_buttons.appraisal_accept.disabled, "busy disabled acceptance")
	ui.set_blocked(false)
	ui.hide()
	for frame in range(2): await process_frame
	ui.show(); ui.refresh()
	check(world.export_campaign_state() == pending and ui.action_buttons.has("appraisal_accept"), "close reopen retains pending choice without grant")
	await click("appraisal_accept")
	check(not ui.action_buttons.has("appraisal_accept") and not ui.action_buttons.has("camp_appraisal"), "accepted actions removed")
	check(ui.story_label.text.contains("已按以下条件领粮一次") and ui.records_label.text.contains("自愿按明示条件"), "accepted history distinguishes voluntary transfer")
	await capture("appraisal-accepted")
	check(world.snapshot().youth.recorded_merit == 0, "actual accepted credit change")
	check(world.restore_campaign_state(pending).ok, "load prior full life")
	ui.refresh()
	await click("appraisal_decline")
	check(world.snapshot().youth.recorded_merit == 1 and ui.story_label.text.contains("已拒绝以下配给"), "decline input keeps credit and explains result")
	await capture("appraisal-declined")
	await click("refuse_order")
	check(world.snapshot().youth.endpoint.reason == "order_refused", "old refusal real input works")
	world = builder.build("appeal")
	check(builder.failures.is_empty(), "real support life")
	ui.world = world; ui.refresh()
	await click("camp_appraisal")
	check(world.youth_view().appraisal.outcome == "support" and ui.story_label.text.contains("八份营粮") and ui.story_label.text.contains("不改军功归属"), "support terms visible")
	await capture("appraisal-support")
	var merit: int = world.snapshot().youth.recorded_merit
	await click("appraisal_accept")
	check(world.snapshot().youth.recorded_merit == merit, "support input preserves credit")
	world = builder.build("appeal", "refuse")
	check(builder.failures.is_empty(), "real returned-refusal life")
	ui.world = world; ui.refresh()
	await click("camp_appraisal")
	check(world.youth_view().appraisal.outcome == "denied" and not ui.action_buttons.has("appraisal_accept"), "returned refusal prevents grant control")
	check(ui.story_label.text.contains("已经带回的拒令答复") and not ui.story_label.text.contains("尚无带回营中的回执"), "refusal account has consistent knowledge")
	await capture("appraisal-denied")
	print("APPRAISAL_UI_SUMMARY " + JSON.stringify({"checks": checks, "failures": failures, "input": "Viewport keyboard events, not emitted button signals", "rendered": DisplayServer.get_name() != "headless"}))
	ui.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)

func capture(label: String) -> void:
	if "--capture-appraisal" not in OS.get_cmdline_user_args(): return
	check(DisplayServer.get_name() != "headless", "capture requires a real display")
	if DisplayServer.get_name() == "headless": return
	ui.scroll.scroll_vertical = 0
	for frame in range(5): await process_frame
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://artifacts")
	var picture := root.get_texture().get_image()
	check(not picture.is_empty() and picture.save_png("res://artifacts/%s-proof.png" % label) == OK, "rendered screenshot " + label)
