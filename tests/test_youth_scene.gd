extends SceneTree
## Headless scene integration using real GUI and combat controls. Explicit failure fixtures only
## cover unavailable disk writes; gameplay outcomes below are never injected.
const Store := preload("res://scripts/campaign_store.gd")
const Driver := preload("res://tests/youth_input_driver.gd")
var scene: Node
var controls: RefCounted
var failures: Array[String] = []
var checks := 0

func _initialize() -> void:
	call_deferred("_run")

func check(value: bool, label: String) -> void:
	checks += 1
	if not value:
		failures.append(label)
		push_error(label)

func state() -> Dictionary:
	return scene.strategy.world.export_campaign_state()

func roundtrip_stage(label: String) -> void:
	var saved_stage: String = scene.youth.view.stage
	controls.key(KEY_F5)
	await controls.settle_ui()
	var before := state()
	controls.key(KEY_F9)
	await controls.settle_ui()
	check(scene.youth.visible and scene.youth.view.stage == saved_stage and state() == before, "save/load preserves the exact " + label + " narrative stage")
	controls.key(KEY_ESCAPE)

func _run() -> void:
	scene = load("res://scenes/battle.tscn").instantiate()
	scene.campaign_store = Store.new("youth_scene_" + Crypto.new().generate_random_bytes(8).hex_encode())
	root.add_child(scene)
	controls = Driver.new(self, scene)
	await controls.settle_ui()
	check(not scene.strategy.world.youth_view().enabled, "training starts independently from a youth life")
	check(scene.campaign_store.list_saves(true).saves.is_empty(), "launch never resets or writes an old save")
	await controls.click(scene.hud.youth_button)
	check(scene.youth.visible and scene.paused and not scene.hud.visible, "prominent youth entry opens narrative panel and pauses training")
	var training: Dictionary = scene.training_sim.export_campaign_state()
	for i in range(5): await physics_frame
	check(scene.training_sim.export_campaign_state() == training, "reading narrative does not advance suspended training")
	check(scene.youth.get_theme_font("font").has_char("军".unicode_at(0)), "selected system font supplies actual Chinese glyphs")
	await controls.youth_click("close")
	check(not scene.youth.visible and not scene.paused, "closing setup restores the prior running training pause state")
	await controls.click(scene.hud.youth_button)
	# Headless selector fixture chooses a non-default combination, then uses the real start button.
	scene.youth.enlistment.select(1)
	scene.youth.motivation.select(2)
	var old_world := state()
	var real_store: RefCounted = scene.campaign_store
	scene.campaign_store = Store.new("../invalid_failure_fixture")
	await controls.youth_click("start")
	check(state() == old_world and scene.youth.feedback.text.contains("没有开始"), "failed archive blocks new life without touching the old world")
	scene.campaign_store = real_store
	await controls.youth_click("start")
	var y: Dictionary = scene.strategy.world.youth_view()
	check(y.enabled and y.stage == "first_orders" and y.enlistment == "volunteer" and y.motivation == "homeland", "distinct enlistment and motivation controls enter the requested authoritative life")
	check(y.age_years == 15.0 and y.rank == "recruit", "new life begins as a fifteen-year-old recruit")
	check(scene.campaign_store.list_saves(true).saves.size() == 2, "old campaign and new youth start both receive unique preserved checkpoints")
	var old_id := ""
	for id in scene.campaign_store.list_saves(true).saves:
		if str(id).begins_with("before_youth_"): old_id = id
	var earlier := preload("res://scripts/world_sim.gd").new()
	check(scene.campaign_store.load_checkpoint(earlier, old_id).ok and earlier.export_campaign_state() == old_world, "archived pre-youth world is an exact independently loadable snapshot")
	check(scene.youth.action_buttons.has("first_march") and not scene.youth.buttons.battle.visible, "first orders display only authoritative phase actions")
	await roundtrip_stage("first orders")
	var before_march := state()
	scene.campaign_store = Store.new("../invalid_failure_fixture")
	await controls.youth_click("first_march")
	check(state() == before_march and scene.youth.feedback.text.contains("尚未执行"), "failed pre-action checkpoint leaves time, supplies and story untouched")
	scene.campaign_store = real_store
	scene._youth_action("first_march")
	check(scene.youth_busy and scene.youth.action_buttons.first_march.disabled, "pre-action checkpoint visibly gates repeated requests")
	scene._youth_action("first_march")
	controls.key(KEY_F9)
	controls.key(KEY_ESCAPE)
	check(scene.youth.visible and state() == before_march, "busy gate blocks escape, load and duplicate actions before state mutation")
	await controls.settle_ui()
	check(scene.strategy.world.youth_view().stage == "first_battle" and scene.strategy.world.player_view().hour == 3, "first march advances exactly three world hours once")
	await roundtrip_stage("first battle preparation")
	await controls.youth_click("battle")
	check(scene.campaign_adapter != null and scene.sim.units.size() == 8 and not scene.youth.visible, "battle entry uses real five-person patrol and three existing enemies")
	check(scene.hud.buttons.order_attack.disabled and scene.hud.buttons.order_follow.disabled and not scene.hud.buttons.order_retreat.disabled, "recruit lacks command buttons but retains legal personal withdrawal")
	var order: String = scene.sim.order
	controls.key(KEY_2)
	check(scene.sim.order == order, "keyboard cannot bypass displayed command authority")
	var fought: Dictionary = await controls.fight()
	print("YOUTH_SCENE_FIRST_COMBAT " + JSON.stringify(fought))
	check(scene.sim.ended and scene.sim.report().player_alive and scene.sim.report().enemy_casualties > 0 and scene.sim.report().player_damage > 0, "real movement and attacks produce a surviving first merit record")
	check(scene.campaign_settlement.get("ok", false), "real scene settlement writes first battle once")
	if not scene.sim.ended or not scene.sim.report().player_alive:
		_finish()
		return
	controls.key(KEY_R)
	await controls.settle_ui()
	check(scene.youth.visible and scene.youth.view.stage == "first_return", "R returns from combat to the current authoritative youth stage")
	await roundtrip_stage("first return")
	await controls.youth_click("return_to_camp")
	check(scene.youth.view.stage == "injustice" and scene.youth.action_buttons.size() == 4, "all four military-injustice choices are mouse-accessible")
	for choice in scene.youth.view.choices:
		check(scene.youth.action_buttons.has(choice.id) and not choice.description.is_empty(), "choice displays known real consequences: " + str(choice.id))
	controls.key(KEY_F5)
	await controls.settle_ui()
	var injustice_saved := state()
	check(scene.save_panel.visible, "free quicksave works during injustice")
	controls.key(KEY_ESCAPE)
	await controls.youth_click("keep_evidence")
	check(scene.youth.view.stage == "appointment" and scene.youth.view.evidence.size() == 1, "evidence action creates a real persistent record")
	controls.key(KEY_F9)
	await controls.settle_ui()
	check(scene.youth.visible and state() == injustice_saved and scene.youth.view.stage == "injustice", "quickload restores the correct narrative panel without replaying the choice")
	controls.key(KEY_ESCAPE)
	await controls.youth_click("keep_evidence")
	var chosen := state()
	controls.key(KEY_F5)
	await controls.settle_ui()
	controls.key(KEY_F9)
	await controls.settle_ui()
	check(state() == chosen and scene.youth.view.evidence.size() == 1, "repeated save/load grants neither duplicate evidence nor duplicate supplies")
	controls.key(KEY_ESCAPE)
	await controls.youth_click("accept_appointment")
	check(scene.youth.view.stage == "dangerous_orders" and scene.youth.view.command_authority == "squad", "accepted actual commission reveals squad authority")
	await roundtrip_stage("dangerous orders")
	await controls.youth_click("dangerous_march")
	await roundtrip_stage("dangerous battle preparation")
	await controls.youth_click("battle")
	check(not scene.hud.buttons.order_attack.disabled and not scene.hud.buttons.order_follow.disabled, "appointment enables real local army command")
	controls.key(KEY_F5)
	await controls.settle_ui()
	var tactical_saved := state()
	controls.key(KEY_F9)
	await controls.settle_ui()
	check(state() == tactical_saved and scene.campaign_adapter != null and scene.paused and not scene.youth.visible, "active youth battle restores exact session paused behind save overlay")
	controls.key(KEY_ESCAPE)
	controls.key(KEY_P)
	var withdrawn: Dictionary = await controls.skirmish_and_withdraw()
	check(scene.campaign_settlement.get("result", "") == "retreat" and withdrawn.player_alive and withdrawn.friendly_casualties > 0 and scene.campaign_settlement.get("ok", false), "dangerous mission permits actual physical retreat without scripted losses")
	controls.key(KEY_R)
	await controls.settle_ui()
	await controls.youth_click("return_to_camp")
	check(scene.youth.view.stage == "replenishment", "retreat follows real return travel into replenishment")
	await roundtrip_stage("replenishment")
	await controls.youth_click("replenish")
	check(scene.youth.view.stage == "endpoint" and not scene.youth.view.endpoint.is_empty(), "existing garrison resources replenish and preserve final army endpoint")
	check(scene.youth.records_label.text.contains("军功") and scene.youth.relations_label.text.contains("阵亡"), "final summary exposes merit, evidence, known relationships and casualties")
	var endpoint_saved := state()
	controls.key(KEY_F5)
	await controls.settle_ui()
	controls.key(KEY_F9)
	await controls.settle_ui()
	check(state() == endpoint_saved and scene.youth.view.stage == "endpoint", "endpoint roundtrip neither replays recruitment nor changes history")
	controls.key(KEY_ESCAPE)
	await controls.youth_click("map")
	check(scene.strategy.visible and scene.strategy.buttons.reset.disabled and scene.strategy.buttons.wait1.disabled, "youth world map is read-only, avoiding technical-fixture action bypass")
	var guard_state := state()
	scene.strategy._command("reset")
	check(state() == guard_state, "technical reset cannot silently wipe youth life")
	controls.key(KEY_M)
	await controls.settle_ui()
	check(scene.youth.visible, "world map returns to youth panel")
	check(scene.strategy.world.audit().is_empty(), "full playable path conserves world resources and persons")
	# Restore an existing pre-battle checkpoint only as branch setup, then use actual
	# reckless forward movement with no attacks to verify death presentation naturally.
	var dangerous_id := ""
	for id in scene.campaign_store.list_saves(true).saves:
		if not str(id).begins_with("prebattle_"): continue
		var candidate := preload("res://scripts/world_sim.gd").new()
		if scene.campaign_store.load_checkpoint(candidate, id).ok and candidate.youth_view().stage == "dangerous_battle":
			dangerous_id = id
	check(not dangerous_id.is_empty(), "dangerous pre-battle checkpoint is preserved for a different tactical branch")
	if not dangerous_id.is_empty():
		scene._open_save_panel()
		check(scene._load_campaign(dangerous_id, true).ok, "existing checkpoint restores branch through normal validated load")
		controls.key(KEY_ESCAPE)
		await controls.settle_ui()
		await controls.youth_click("battle")
		controls.movement(Vector2.RIGHT)
		for i in range(1800):
			if scene.sim.ended: break
			await physics_frame
		controls.release_inputs()
		await physics_frame
		await physics_frame
		check(scene.sim.ended and not scene.sim.report().player_alive and scene.strategy.world.player_view().campaign_ended, "real unguarded advance can kill the protagonist and end the life")
		controls.key(KEY_R)
		await controls.settle_ui()
		check(scene.youth.visible and scene.youth.title_label.text == "此生至此" and scene.youth.action_buttons.is_empty(), "death displays finite known-life summary without continuing as an heir")
		await roundtrip_stage("dead endpoint")
		check(scene.strategy.world.player_view().campaign_ended and not scene.youth.buttons.saves.disabled, "dead saves remain ended and earlier checkpoints stay accessible")
	# A tactical extraction is not an unearned three-hour march back to camp.
	var first_battle_id := ""
	for id in scene.campaign_store.list_saves(true).saves:
		if not str(id).begins_with("prebattle_"): continue
		var candidate := preload("res://scripts/world_sim.gd").new()
		if scene.campaign_store.load_checkpoint(candidate, id).ok and candidate.youth_view().stage == "first_battle": first_battle_id = id
	check(not first_battle_id.is_empty(), "first patrol checkpoint remains available")
	if not first_battle_id.is_empty():
		scene._open_save_panel()
		check(scene._load_campaign(first_battle_id, true).ok, "first patrol can be replayed without merit")
		controls.key(KEY_ESCAPE)
		await controls.settle_ui()
		await controls.youth_click("battle")
		controls.key(KEY_3)
		controls.movement(Vector2.LEFT)
		for i in range(1800):
			if scene.sim.ended: break
			await physics_frame
		controls.release_inputs()
		await physics_frame
		await physics_frame
		controls.key(KEY_R)
		await controls.settle_ui()
		check(scene.youth.view.endpoint.get("reason") == "first_patrol_withdrawn", "empty-handed extraction is a legitimate endpoint")
		check(scene.strategy.world.player_view().army.location == "hequ" and scene.youth.records_label.text.contains("已撤离初阵") and not scene.youth.records_label.text.contains("撤回营地"), "endpoint text does not invent a return journey")
	_finish()

func _finish() -> void:
	controls.release_inputs()
	scene.queue_free()
	print("YOUTH_SCENE_SUMMARY " + JSON.stringify({"assertions": checks, "failures": failures.size(), "messages": failures}))
	quit(0 if failures.is_empty() else 1)
