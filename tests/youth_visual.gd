extends SceneTree
## Real-control graphical proof. No health/position/outcome injection. Headless may only
## validate the same control route under --validate-youth-inputs, never claim rendered proof.
const Store := preload("res://scripts/campaign_store.gd")
const Driver := preload("res://tests/youth_input_driver.gd")
var scene: Node
var controls: RefCounted
var failed := false
var graphical := false
var captures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func check(value: bool, message: String) -> void:
	if not value:
		failed = true
		push_error(message)

func capture(name: String) -> void:
	if graphical:
		check(await controls.capture(name), "Failed graphical capture: " + name)
		captures.append(name)

func _run() -> void:
	graphical = DisplayServer.get_name() != "headless"
	if not graphical and "--validate-youth-inputs" not in OS.get_cmdline_user_args():
		push_error("Youth graphical proof requires a real graphical renderer")
		quit(1)
		return
	scene = load("res://scenes/battle.tscn").instantiate()
	scene.campaign_store = Store.new("youth_visual_" + Crypto.new().generate_random_bytes(8).hex_encode())
	root.add_child(scene)
	controls = Driver.new(self, scene)
	await controls.settle_ui()
	await controls.click(scene.hud.youth_button)
	var ui: Control = scene.youth
	check(ui.get_global_rect().encloses(ui.scroll.get_global_rect()), "Narrative viewport fits 1280x800")
	for id in ["close", "map", "saves"]:
		check(ui.get_global_rect().encloses(ui.buttons[id].get_global_rect()), "Header control is fully visible: " + id)
	var font: Font = ui.get_theme_font("font")
	for character in "乱世少年军旅征发求生守乡":
		check(font.has_char(character.unicode_at(0)), "System font must contain actual Chinese glyph: " + character)
	await capture("youth-enlistment-proof")
	await controls.youth_click("start") # Actual default forced/survival control selections.
	check(ui.view.enlistment == "forced" and ui.view.motivation == "survival", "Visible start controls establish the chosen origin")
	await controls.youth_click("first_march")
	await controls.youth_click("battle")
	check(scene.campaign_adapter != null and scene.sim.units.size() == 8, "Narrative enters actual small battle")
	var first: Dictionary = await controls.fight("youth-first-battle-proof" if graphical else "")
	check(first.report.player_alive and first.report.enemy_casualties > 0 and first.report.player_damage > 0 and first.moving_frames > 0 and first.pointer_error_max < 2.0 and scene.campaign_settlement.get("ok", false), "Actual movement, aim and attacks must create personal damage, merit and a settled surviving result")
	if not first.report.player_alive or not scene.sim.ended:
		_finish(first, {})
		return
	controls.key(KEY_R)
	await controls.settle_ui()
	await controls.youth_click("return_to_camp")
	check(ui.view.stage == "injustice" and ui.action_buttons.size() == 4, "Four meaningful injustice choices appear")
	ui.scroll.ensure_control_visible(ui.action_buttons.endure)
	await controls.settle_ui()
	await capture("youth-injustice-proof")
	await controls.youth_click("keep_evidence")
	await controls.youth_click("accept_appointment")
	check(ui.view.command_authority == "squad", "Commission unlocks real squad authority")
	await controls.youth_click("dangerous_march")
	await controls.youth_click("battle")
	controls.key(KEY_F5)
	await controls.settle_ui()
	controls.key(KEY_F9)
	await controls.settle_ui()
	check(scene.paused and scene.save_panel.visible and scene.campaign_adapter != null, "Saved dangerous mission resumes paused and bound to the real world")
	await capture("youth-active-save-proof")
	controls.key(KEY_ESCAPE)
	controls.key(KEY_P)
	var second: Dictionary = await controls.skirmish_and_withdraw("youth-withdrawal-proof" if graphical else "")
	check(scene.campaign_settlement.get("result", "") == "retreat" and second.player_alive and second.friendly_casualties > 0, "A physical withdrawal produces a real non-scripted retreat result")
	controls.key(KEY_R)
	await controls.settle_ui()
	await controls.youth_click("return_to_camp")
	await controls.youth_click("replenish")
	check(ui.view.stage == "endpoint" and ui.view.evidence.size() == 1, "Final army, evidence and relationships persist")
	ui.scroll.scroll_vertical = 0
	await controls.settle_ui()
	await capture("youth-endpoint-proof")
	ui.scroll.ensure_control_visible(ui.relations_label)
	await controls.settle_ui()
	await capture("youth-records-proof")
	check(scene.strategy.world.audit().is_empty(), "Rendered playthrough conserves resources and people")
	_finish(first, second)

func _finish(first: Dictionary, second: Dictionary) -> void:
	controls.release_inputs()
	var evidence := {"display": DisplayServer.get_name(), "device": RenderingServer.get_video_adapter_name(), "personal_first_combat": first, "dangerous_withdrawal": second, "captures": captures, "failures": 1 if failed else 0}
	var marker := "YOUTH_VISUAL" if graphical else "YOUTH_INPUT_VALIDATION"
	print(marker + ("_FAIL " if failed else "_PASS ") + JSON.stringify(evidence))
	scene.queue_free()
	quit(1 if failed else 0)
