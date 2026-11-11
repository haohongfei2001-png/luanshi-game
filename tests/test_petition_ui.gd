extends SceneTree
const Smoke := preload("res://scripts/appraisal_persistence_smoke.gd")
const UI := preload("res://scripts/youth_ui.gd")
const P := preload("res://scripts/comrade_petition.gd")
var checks := 0
var failures: Array[String] = []
var ui := UI.new()
var world: WorldSimulation
func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label); push_error(label)
func click(id: String) -> void:
	check(ui.action_buttons.has(id), "real control exists " + id)
	if not ui.action_buttons.has(id): return
	var button: Button = ui.action_buttons[id]
	for frame in range(3): await process_frame
	ui.scroll.ensure_control_visible(button)
	for frame in range(4): await process_frame
	check(ui.scroll.get_global_rect().encloses(button.get_global_rect()), "control reachable " + id)
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
	check(builder.failures.is_empty(), "genuine public battle and appointment")
	ui.world = world
	root.add_child(ui)
	ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.action_requested.connect(func(id: String):
		check(world.youth_action(id).ok, "real input action " + id)
		ui.refresh())
	for frame in range(3): await process_frame
	check(ui.action_buttons.has("comrade_petition") and ui.action_buttons.has("camp_appraisal") and ui.action_buttons.has("dangerous_march") and ui.action_buttons.has("refuse_order"), "optional addition keeps existing branches")
	ui.set_blocked(true)
	check(ui.action_buttons.comrade_petition.disabled, "busy petition disabled")
	ui.set_blocked(false)
	var before := world.export_campaign_state()
	await click("comrade_petition")
	check(P.record(world.snapshot().youth).restored > 0, "keyboard causes real surviving witness testimony")
	check(not ui.action_buttons.has("comrade_petition"), "no reroll button")
	check(ui.story_label.text.contains("同袍补证") and ui.story_label.text.contains("已联署") and ui.records_label.text.contains("同袍补证"), "testimony and history visible")
	await capture("petition-signed")
	var after := world.export_campaign_state()
	ui.hide()
	for frame in range(2): await process_frame
	ui.show(); ui.refresh()
	check(world.export_campaign_state() == after and not ui.action_buttons.has("comrade_petition"), "close reopen neither rerolls nor rewards")
	await click("camp_appraisal")
	check(not ui.action_buttons.has("comrade_petition"), "appraisal preserves closed petition")
	await click("refuse_order")
	check(world.snapshot().youth.endpoint.reason == "order_refused", "old refusal still works by keyboard")
	check(world.restore_campaign_state(before).ok, "load pre-petition exact life")
	ui.refresh()
	await click("camp_appraisal")
	check(not ui.action_buttons.has("comrade_petition"), "quote first removes petition")
	world = builder.build("endure", "", "survival")
	ui.world = world; ui.refresh()
	await click("comrade_petition")
	check(P.record(world.snapshot().youth).restored == 0 and ui.story_label.text.contains("未联署"), "refusal visible as real choice")
	await capture("petition-refused")
	world = builder.build("protect_comrade")
	ui.world = world; ui.refresh()
	await click("comrade_petition")
	check(ui.story_label.text.contains("让我留营") and ui.story_label.text.contains("已联署"), "protected camp survivor visible")
	await capture("petition-protected")
	check(builder.failures.is_empty(), "all real UI setup lives valid")
	print("PETITION_UI_SUMMARY " + JSON.stringify({"checks": checks, "failures": failures, "input": "Viewport keyboard events, not emitted button signals", "rendered": DisplayServer.get_name() != "headless"}))
	ui.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
func capture(label: String) -> void:
	if "--capture-petition" not in OS.get_cmdline_user_args(): return
	check(DisplayServer.get_name() != "headless", "capture requires real display")
	if DisplayServer.get_name() == "headless": return
	ui.scroll.scroll_vertical = 0
	for frame in range(5): await process_frame
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://artifacts")
	var picture := root.get_texture().get_image()
	check(not picture.is_empty() and picture.save_png("res://artifacts/%s-proof.png" % label) == OK, "rendered screenshot " + label)
