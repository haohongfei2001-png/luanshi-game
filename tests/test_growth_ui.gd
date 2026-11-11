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
	check(panel.scroll.get_global_rect().encloses(button.get_global_rect()), "training reachable by scrolling")
	button.grab_focus()
	var key := InputEventKey.new(); key.keycode = KEY_ENTER; key.physical_keycode = KEY_ENTER; key.pressed = true
	root.push_input(key, true)
	key.pressed = false; root.push_input(key, true)
	for i in range(4): await process_frame
func run() -> void:
	root.size = Vector2i(1280, 800)
	var helper := Setup.new(); var w := helper.build()
	check(helper.failures.is_empty(), "actual shared youth combat fixture")
	var ui := UI.new(); ui.world = w; root.add_child(ui)
	ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for i in range(3): await process_frame
	check(ui.action_buttons.size() == 4 and ui.action_buttons.has("endure") and ui.action_buttons.has("appeal") and ui.action_buttons.has("keep_evidence") and ui.action_buttons.has("protect_comrade"), "original injustice choices preserved")
	check(ui.growth_label.get_index() > ui.actions.get_index(), "growth below narrative choices")
	check(not ui.buttons.train_combat_1.disabled and not ui.buttons.train_combat_2.disabled, "shared experience permits practice")
	check(ui.buttons.train_combat_1.text.contains("耗时耗粮") and ui.buttons.train_combat_2.text.contains("最多 2") and ui.buttons.train_combat_2.text.contains("不疗伤"), "explicit costs and duration")
	var before := w.export_campaign_state()
	ui.set_blocked(true)
	check(ui.buttons.train_combat_1.disabled and ui.buttons.train_combat_2.disabled, "interaction block disables practice")
	ui.buttons.train_combat_1.pressed.emit()
	check(w.export_campaign_state() == before, "blocked signal cannot act")
	ui.set_blocked(false)
	await press(ui, ui.buttons.train_combat_1)
	check(w.snapshot().time_seconds == before.world.time_seconds + 3600.0 and w.snapshot().commander.hp == before.world.commander.hp, "youth keyboard spends actual hour without healing")
	check(w.player_view().growth.hours_completed == 1 and w.player_view().army.food < before.world.armies.relief.food, "practice progress and rations are real")
	await press(ui, ui.buttons.train_combat_2)
	check(w.snapshot().time_seconds == before.world.time_seconds + 7200.0 and w.snapshot().commander.hp == before.world.commander.hp, "up to two finishes only remaining hour")
	check(ui.buttons.train_combat_1.disabled and ui.buttons.train_combat_2.disabled and ui.action_buttons.size() == 4, "completed tier disables training without removing story")
	var after := w.export_campaign_state()
	ui.hide(); await process_frame; ui.show(); ui.refresh()
	check(w.export_campaign_state() == after, "refresh cannot train")
	check(w.restore_campaign_state(before).ok, "reload before training")
	ui.refresh(); await press(ui, ui.buttons.train_combat_1)
	await press(ui, ui.buttons.train_combat_2)
	check(w.export_campaign_state() == after, "same save produces same training without duplication")
	await capture(ui, "growth-youth")
	ui.queue_free(); await process_frame
	var map := Map.new(); map.world = w; root.add_child(map)
	map.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for i in range(3): await process_frame
	check(map.buttons.train1.disabled and map.buttons.train2.disabled, "map cannot bypass youth command panel")
	before = w.export_campaign_state(); map.buttons.train1.pressed.emit()
	check(w.export_campaign_state() == before, "youth map signal cannot bypass commands")
	map.queue_free(); await process_frame
	helper = Setup.new(); var tech := helper.build("technical")
	check(helper.failures.is_empty(), "actual technical combat fixture")
	map = Map.new(); map.world = tech; root.add_child(map)
	map.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for i in range(4): await process_frame
	check(map.scroll.get_global_rect().encloses(map.map.get_global_rect()), "map remains in first viewport")
	check(map.growth_label.get_index() > map.map.get_index() and not map.buttons.train1.disabled, "technical practice below map")
	before = tech.export_campaign_state()
	map.interaction_blocked = true; map.refresh()
	check(map.buttons.train1.disabled and map.buttons.train2.disabled, "technical interaction disabled")
	map.buttons.train1.pressed.emit()
	check(tech.export_campaign_state() == before, "technical blocked signal cannot train")
	map.interaction_blocked = false; map.refresh()
	await press(map, map.buttons.train2)
	check(tech.snapshot().time_seconds == before.world.time_seconds + 7200.0 and tech.snapshot().commander.hp == before.world.commander.hp, "technical keyboard spends two actual hours without healing")
	check(map.buttons.train1.disabled and map.buttons.train2.disabled, "technical completed tier disabled")
	await capture(map, "growth-technical")
	map.queue_free(); await process_frame
	var fresh := preload("res://scripts/world_sim.gd").new()
	map = Map.new(); map.world = fresh; root.add_child(map)
	map.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for i in range(3): await process_frame
	check(map.buttons.train1.disabled and map.buttons.train2.disabled and not map.buttons.train1.tooltip_text.is_empty(), "no combat disables practice with explanation")
	before = fresh.export_campaign_state(); map.buttons.train1.pressed.emit()
	check(fresh.export_campaign_state() == before, "no source cannot train through emitted signal")
	map.queue_free(); await process_frame
	check(w.restore_campaign_state(before).ok, "fresh state can load into youth panel world")
	ui = UI.new(); ui.world = w; root.add_child(ui)
	ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for i in range(3): await process_frame
	check(not ui.growth_controls.visible and ui.buttons.train_combat_1.disabled, "unenlisted youth hides and disables practice")
	ui.buttons.train_combat_1.pressed.emit()
	check(w.export_campaign_state() == before, "hidden youth controls cannot train technical world")
	ui.queue_free(); await process_frame
	print("GROWTH_UI_SUMMARY " + JSON.stringify({"checks": checks, "failures": failures, "input": "Viewport keyboard events", "rendered": DisplayServer.get_name() != "headless"}))
	quit(0 if failures.is_empty() else 1)
func capture(panel: Control, label: String) -> void:
	if "--capture-growth" not in OS.get_cmdline_user_args(): return
	check(DisplayServer.get_name() != "headless", "real display required")
	if DisplayServer.get_name() == "headless": return
	panel.scroll.ensure_control_visible(panel.growth_label)
	for i in range(5): await process_frame
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://artifacts")
	var picture := root.get_texture().get_image()
	check(not picture.is_empty() and picture.save_png("res://artifacts/%s-proof.png" % label) == OK, "rendered " + label)
