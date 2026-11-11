extends SceneTree
## Real youth actions and GUI signals. Hidden-fate assertion uses only projected data.
const W := preload("res://scripts/world_sim.gd")
const UI := preload("res://scripts/youth_ui.gd")
const Map := preload("res://scripts/strategy_view.gd")
const Driver := preload("res://tests/youth_combat_driver.gd")
var checks := 0
var failures: Array[String] = []
var world := W.new()
var ui := UI.new()
var strategy := Map.new()
func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label); push_error(label)
func refresh() -> void:
	ui.refresh()
	strategy.refresh()
	check(ui.courier_label.text == strategy.courier_label.text, "life and map share player-known account")
func click(id: String) -> void:
	check(ui.action_buttons.has(id), "action exists: " + id)
	if not ui.action_buttons.has(id): return
	check(not ui.action_buttons[id].disabled, "action enabled: " + id)
	ui.action_buttons[id].pressed.emit()
	refresh()
func run() -> void:
	root.size = Vector2i(1280, 800)
	ui.world = world
	strategy.world = world
	root.add_child(strategy)
	root.add_child(ui)
	ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	strategy.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.start_requested.connect(func(origin: String, motive: String): check(world.start_youth(origin, motive).ok, "real youth start"))
	ui.action_requested.connect(func(id: String): check(world.youth_action(id).ok, "real youth action: " + id))
	ui.buttons.start.pressed.emit()
	refresh()
	check(not ui.courier_label.visible, "no invented orders before arrangement")
	click("arrange_courier")
	check(ui.courier_label.text.contains("乔队正 → 外出巡队：回营呈报") and ui.courier_label.text.contains("已安排传令，尚未收到"), "superior order and actual pending state")
	check(ui.courier_label.text.contains("原预计送达第 4.0 时"), "expected time is marked as estimate")
	click("first_march")
	check(ui.courier_label.text.contains("已过 3.0 小时") and not ui.action_buttons.has("courier_comply"), "march advances clock without invented delivery")
	click("wait_courier")
	check(ui.courier_label.text.contains("军令已送达本人") and ui.courier_label.text.contains("最近确认第 4.0 时"), "one-hour wait physically delivers order")
	for i in range(3): await process_frame
	check(ui.get_global_rect().encloses(ui.scroll.get_global_rect()), "scroll panel fits viewport")
	for id in ["map", "saves", "close"]:
		check(ui.get_global_rect().encloses(ui.buttons[id].get_global_rect()), "header fits viewport: " + id)
	ui.scroll.ensure_control_visible(ui.courier_label)
	for i in range(3): await process_frame
	check(ui.scroll.get_global_rect().encloses(ui.courier_label.get_global_rect()), "full compact order panel reachable without clipping")
	await capture("courier-delivered")
	var army: Dictionary = world.player_view().army.duplicate(true)
	click("courier_comply")
	check(ui.courier_label.text.contains("回执已发出，营中是否收到仍未知") and ui.courier_label.text.contains("愿遵令回营"), "sent receipt is not camp confirmation")
	check(world.player_view().army == army and ui.courier_label.text.contains("答应遵令不会移动部队"), "compliance explicitly not teleportation")
	for i in range(3): click("wait_courier")
	check(ui.courier_label.text.contains("营中是否收到仍未知"), "actual distant receipt cannot leak through UI")
	var ticket: Dictionary = world.create_battle_ticket()
	check(ticket.get("ok", false), "real battle opens physical return route")
	if ticket.get("ok", false):
		var battle := world.start_battle(ticket.ticket.battle_id)
		var outcome := Driver.play(battle)
		check(world.commit_battle_outcome(outcome).ok, "real combat settles")
		refresh()
		click("return_to_camp")
		check(ui.courier_label.text.contains("回营核实：营中已收到回报"), "camp confirmation requires physical return")
	world = W.new()
	ui.world = world
	strategy.world = world
	check(world.start_youth("volunteer", "homeland").ok, "refusal life starts")
	refresh()
	click("arrange_courier")
	click("first_march")
	click("wait_courier")
	ui.set_blocked(true)
	check(ui.action_buttons.courier_refuse.disabled and ui.action_buttons.courier_comply.disabled, "busy state disables both reply controls")
	ui.set_blocked(false)
	click("courier_refuse")
	check(ui.courier_label.text.contains("回报内容：拒绝此令") and not ui.action_buttons.has("courier_comply"), "refusal presented once without a replacement reply")
	for i in range(3): await process_frame
	strategy.scroll.ensure_control_visible(strategy.courier_label)
	for i in range(3): await process_frame
	check(strategy.scroll.get_global_rect().encloses(strategy.courier_label.get_global_rect()), "map order panel fully reachable without clipping")
	ui.hide()
	await capture("courier-map-reply")
	ui.show()
	# Independent real life leaves rendezvous absent; it cannot learn the hidden fate.
	world = W.new()
	ui.world = world
	strategy.world = world
	check(world.start_youth("forced", "survival").ok, "second real life")
	refresh()
	click("arrange_courier")
	for i in range(7): click("wait_courier")
	var text: String = ui.courier_label.text
	check(text.contains("逾期未获进一步确认") and text.contains("不能据此确认传令兵死亡"), "overdue is uncertainty rather than confirmed death")
	for forbidden in ["lost", "intercepted", "被截杀", "已阵亡", "recruited"]:
		check(not text.contains(forbidden), "no hidden fate or recruitment claim: " + forbidden)
	check(not world.player_view().courier_orders[0].has("status"), "UI receives no hidden courier status")
	ui.scroll.ensure_control_visible(ui.courier_label)
	await capture("courier-overdue")
	print("COURIER_UI_SUMMARY " + JSON.stringify({"checks": checks, "failures": failures}))
	ui.queue_free()
	strategy.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)

func capture(label: String) -> void:
	if "--capture-couriers" not in OS.get_cmdline_user_args(): return
	check(DisplayServer.get_name() != "headless", "capture uses actual display")
	if DisplayServer.get_name() == "headless": return
	for i in range(5): await process_frame
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://artifacts")
	var picture := root.get_texture().get_image()
	check(not picture.is_empty() and picture.save_png("res://artifacts/%s-proof.png" % label) == OK, "actual rendered screenshot: " + label)
