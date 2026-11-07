extends SceneTree
## Real scene/Viewport UI tests. Each run uses a new isolated user:// campaign.
const Store := preload("res://scripts/campaign_store.gd")
var failures: Array[String] = []
var checks := 0
var scene: Node
var ui: Control
var panel: Control
var test_id := ""

func _initialize() -> void:
	call_deferred("_run")

func check(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures.append(description)
		push_error(description)

func key(code: Key) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.keycode = code
	event.pressed = true
	root.push_input(event, true)
	event.pressed = false
	root.push_input(event, true)

func click_control(control: Control) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.position = control.get_global_rect().get_center()
	event.pressed = true
	root.push_input(event, true)
	event.pressed = false
	root.push_input(event, true)
	await process_frame
	await process_frame

func map_click(id: String) -> void:
	ui.scroll.ensure_control_visible(ui.buttons[id])
	await process_frame
	await click_control(ui.buttons[id])

func select_save(id: String, checkpoints: bool = false) -> void:
	panel.category.select(1 if checkpoints else 0)
	panel.category.item_selected.emit(panel.category.selected)
	await process_frame
	for index in range(panel.entries.item_count):
		if panel.entries.get_item_metadata(index) == id:
			panel.entries.select(index)
			panel.entries.ensure_current_is_visible()
			await process_frame
			var item: Rect2 = panel.entries.get_item_rect(index)
			var point: Vector2 = panel.entries.global_position + item.get_center()
			point.y -= panel.entries.get_v_scroll_bar().value
			panel.entries.deselect_all()
			var event := InputEventMouseButton.new()
			event.button_index = MOUSE_BUTTON_LEFT
			event.position = point
			event.pressed = true
			root.push_input(event, true)
			event.pressed = false
			root.push_input(event, true)
			await process_frame
			check(not panel.buttons.load.disabled and panel.entries.is_selected(index), "mouse selects listed save: " + id)
			return
	check(false, "save visible in GUI list: " + id)

func save_named(id: String) -> void:
	if not panel.visible:
		key(KEY_F6)
	panel.category.select(0)
	panel.category.item_selected.emit(0)
	panel.slot_name.text = id
	await process_frame
	await process_frame
	await click_control(panel.buttons.save)

func load_named(id: String, checkpoints: bool = false) -> void:
	if not panel.visible:
		key(KEY_F6)
	await select_save(id, checkpoints)
	await click_control(panel.buttons.load)

func battle_state(sim: BattleSimulation) -> Dictionary:
	var state := sim.export_campaign_state()
	state.erase("events") # One-frame visual effects are consumed when views refresh.
	return state

func world_state() -> Dictionary:
	return ui.world.export_campaign_state()

func _run() -> void:
	test_id = "scene_saves_" + Crypto.new().generate_random_bytes(8).hex_encode()
	scene = load("res://scenes/battle.tscn").instantiate()
	scene.campaign_store = Store.new(test_id)
	root.add_child(scene)
	await process_frame
	await process_frame
	ui = scene.strategy
	panel = scene.save_panel
	check(scene.campaign_store.list_saves().saves.is_empty() and scene.campaign_store.list_saves(true).saves.is_empty(), "startup never writes or overwrites a slot/checkpoint")
	check(InputMap.has_action("campaign_saves") and InputMap.has_action("campaign_quicksave") and InputMap.has_action("campaign_quickload"), "save controls have device-independent semantic actions")
	scene.sim._hurt(scene.sim.units[1], 1000.0, false)
	await click_control(scene.hud.saves_button)
	check(panel.visible and not scene.paused and not ui.visible, "HUD save button opens overlay without toggling the underlying pause")
	var before_training := battle_state(scene.training_sim)
	for i in range(5):
		await physics_frame
	check(battle_state(scene.training_sim) == before_training, "save overlay freezes training without saving its state")
	var initial_world := world_state()
	ui._command("advance", "", 6)
	key(KEY_R)
	key(KEY_Q)
	check(world_state() == initial_world and battle_state(scene.training_sim) == before_training, "modal blocks commands and battle hotkeys behind the panel")
	key(KEY_ESCAPE)
	check(not panel.visible and not scene.paused and not ui.visible, "Escape dismisses only save overlay and restores running training")
	key(KEY_P)
	key(KEY_F6)
	key(KEY_M)
	check(scene.paused and not panel.visible and not ui.visible, "M backs out of save overlay without navigating or changing an existing pause")
	before_training = battle_state(scene.training_sim)
	key(KEY_M)
	await map_click("saves")
	check(panel.visible and ui.visible, "campaign map offers a mouse-accessible save entry")
	check(panel.get_global_rect().encloses(panel.panel.get_global_rect()), "save panel fits within the 1280x800 viewport")
	for button in panel.buttons.values():
		check(panel.panel.get_global_rect().encloses(button.get_global_rect()), "save panel action is fully visible: " + button.text)
	await save_named("../bad")
	check(panel.feedback.text.contains("Save failed") and world_state() == initial_world, "invalid named slot shows readable failure without changing world")
	scene._request_save_operation("save", "busy_once")
	check(scene.save_busy and panel.feedback.text.contains("Saving") and panel.buttons.close.disabled, "busy status is visible before save work and controls are locked")
	key(KEY_ESCAPE)
	key(KEY_F9)
	scene._request_save_operation("save", "busy_duplicate")
	check(panel.visible and world_state() == initial_world, "back and repeated/reentrant requests cannot interrupt or modify a pending save")
	await process_frame
	await process_frame
	await process_frame
	check(not scene.save_busy and scene.campaign_store.list_saves().saves.has("busy_once") and not scene.campaign_store.list_saves().saves.has("busy_duplicate"), "one pending operation finishes once and unlocks controls")
	await save_named("map_start")
	check(panel.feedback.text.contains("Saved campaign") and scene.campaign_store.list_saves().saves.has("map_start"), "GUI Save writes selected full campaign slot")
	check(panel.context_label.text.contains("World h0.00"), "overlay describes actual campaign rather than training time")
	key(KEY_ESCAPE)
	await map_click("wait1")
	check(ui.view.hour == 1, "campaign changes after save")
	await load_named("map_start")
	check(world_state() == initial_world and ui.view.hour == 0 and ui.world == scene.strategy.world, "GUI Load restores full world into same authority")
	await click_control(panel.buttons.load)
	check(world_state() == initial_world, "repeated load is idempotent")
	await click_control(panel.buttons.checkpoint)
	var life_id: String = panel.entries.get_item_metadata(panel.entries.get_selected_items()[0])
	check(life_id.begins_with("life_") and scene.campaign_store.list_saves(true).saves.has(life_id), "GUI creates a reusable full-world life checkpoint")
	check(panel.feedback.text.contains("after death"), "checkpoint persistence is explained to player")
	var state_before_failure := world_state()
	var sim_before_failure: BattleSimulation = scene.sim
	check(not scene._load_campaign("missing").ok, "missing save rejected")
	check(world_state() == state_before_failure and scene.sim == sim_before_failure and scene.paused, "missing load preserves campaign, local simulation and prior pause")
	var broken := FileAccess.open("user://campaigns/%s/slots/broken.save.json" % test_id, FileAccess.WRITE)
	broken.store_string("{broken")
	broken.close()
	check(not scene._load_campaign("broken").ok and panel.feedback.text.contains("unchanged"), "corrupt save produces readable error")
	check(world_state() == state_before_failure, "corrupt load leaves entire live authority unchanged")
	key(KEY_ESCAPE)
	ui.world.observe_city("pingling", 8)
	await map_click("river")
	var marching := world_state()
	await save_named("marching")
	key(KEY_ESCAPE)
	await map_click("wait1")
	await load_named("marching")
	check(world_state() == marching and ui.view.local_city.is_empty() and not ui.view.army.march.is_empty(), "marching save restores route, future reports and travel progress without remote truth")
	key(KEY_ESCAPE)
	for i in range(3):
		await map_click("wait1")
	var before_assault: Dictionary = ui.world.player_view()
	var checkpoint_count: int = scene.campaign_store.list_saves(true).saves.size()
	await map_click("seize")
	key(KEY_P)
	check(scene.campaign_adapter != null and scene.paused, "real assault opens adapter-backed roster before save")
	var all_checkpoints: Array = scene.campaign_store.list_saves(true).saves
	check(all_checkpoints.size() == checkpoint_count + 1, "user-initiated assault creates one preserved pre-battle checkpoint")
	var prebattle_id := ""
	for id in all_checkpoints:
		if str(id).begins_with("prebattle_"):
			prebattle_id = id
	var old_adapter: RefCounted = scene.campaign_adapter
	var active_world: Dictionary = ui.world.snapshot()
	var active_sim := battle_state(scene.sim)
	key(KEY_F5)
	await process_frame
	await process_frame
	await process_frame
	check(panel.feedback.text.contains("'quick'") and scene.campaign_store.list_saves().saves.has("quick"), "F5 saves current campaign into the quick slot")
	check(not scene._load_campaign("missing").ok and scene.campaign_adapter == old_adapter, "failed load retains exact live campaign adapter")
	check(old_adapter.sync_world() and battle_state(scene.sim) == active_sim, "adapter remains usable after failed load")
	var old_ticket: Dictionary = old_adapter.ticket.duplicate(true)
	check(not old_adapter.resume("missing").ok and old_adapter.ticket == old_ticket and old_adapter.simulation == scene.sim, "failed adapter resume does not damage the current presentation binding")
	check(old_adapter.sync_world(), "adapter can still synchronize after failed resume")
	scene.sim.use_action("guard")
	scene.sim._hurt(scene.sim.units[1], 1000.0, false)
	key(KEY_F9)
	await process_frame
	await process_frame
	await process_frame
	check(ui.world.snapshot() == active_world and battle_state(scene.sim) == active_sim, "F9 restores exact active battle wounds, RNG, cooldowns, orders and elapsed time")
	check(scene.campaign_adapter != old_adapter and scene.sim == scene.campaign_adapter.simulation, "successful load replaces stale adapter and binds the restored simulation")
	check(not old_adapter.sync_world() and not old_adapter.settle().ok, "discarded adapter cannot synchronize or settle replacement battle")
	check(scene.views.size() == scene.sim.units.size() and scene.hud.sim == scene.sim, "all unit views and HUD reference the new loaded session")
	check(not ui.visible and scene.paused and panel.visible, "loaded battle waits paused behind overlay for explicit continuation")
	var elapsed: float = scene.sim.elapsed
	key(KEY_ESCAPE)
	key(KEY_P)
	for i in range(10):
		await physics_frame
	key(KEY_P)
	check(scene.sim.elapsed > elapsed, "loaded active battle continues via actual Resume input")
	key(KEY_F6)
	# Finish while modal is open, keeping the legal ended-awaiting-settlement state.
	for unit in scene.sim.units:
		if unit.team == 1:
			scene.sim._hurt(unit, 1000.0, false)
	scene.sim._check_result()
	var pending_id: String = ui.world.player_view().active_battle
	await save_named("pending")
	check(scene.sim.ended and ui.world.battle_ticket(pending_id).status == "running", "ended but uncommitted battle can be saved without prematurely settling")
	await load_named("pending")
	check(scene.sim.ended and ui.world.battle_ticket(pending_id).status == "running" and not scene.campaign_settlement.get("ok", false), "pending load preserves the settlement boundary")
	key(KEY_ESCAPE)
	await physics_frame
	await physics_frame
	check(scene.campaign_settlement.get("ok", false) and ui.world.battle_ticket(pending_id).status == "committed", "resumed ended encounter settles through the ordinary exactly-once path")
	var committed := world_state()
	await save_named("committed")
	await load_named("committed")
	check(ui.visible and scene.campaign_adapter == null and scene.sim == scene.training_sim, "committed load returns to map, clears tactical references and restores separate training")
	check(world_state() == committed and ui.feedback.text.contains("already recorded"), "committed receipt is shown without replaying losses or rewards")
	await click_control(panel.buttons.load)
	check(world_state() == committed and battle_state(scene.training_sim) == before_training, "repeated committed loading changes neither resources nor suspended training")
	# A saved pending outcome intentionally rewinds before receipt, then commits once.
	await load_named("pending")
	key(KEY_ESCAPE)
	await physics_frame
	await physics_frame
	check(world_state() == committed, "reloading pending outcome and completing produces exactly the same final world")
	await load_named(prebattle_id, true)
	check(ui.view.commander.alive and ui.view.army.soldiers == before_assault.army.soldiers and ui.view.active_battle == "", "pre-battle life checkpoint restores the entire live army before reservation")
	key(KEY_ESCAPE)
	await map_click("seize")
	key(KEY_F6)
	scene.sim._hurt(scene.sim.player(), 1000.0, false)
	scene.sim._check_result()
	key(KEY_ESCAPE)
	await physics_frame
	await physics_frame
	check(ui.world.player_view().campaign_ended, "real commander death ends the current life")
	await save_named("dead")
	await load_named("dead")
	check(ui.view.campaign_ended and ui.status_label.text.contains("Load an earlier") and not ui.buttons.saves.disabled, "dead save remains readable and exposes recovery, not forced permadeath")
	await load_named(life_id, true)
	check(ui.view.commander.alive and not ui.view.campaign_ended and ui.view.hour == 0, "life checkpoint can recover from saved death")
	check(battle_state(scene.training_sim) == before_training and scene.sim == scene.training_sim, "death and checkpoint recovery never reset separate training")
	key(KEY_ESCAPE)
	checkpoint_count = scene.campaign_store.list_saves(true).saves.size()
	await map_click("reset")
	check(scene.campaign_store.list_saves(true).saves.size() == checkpoint_count + 1, "explicit new campaign creates a unique life checkpoint")
	# Reserved tickets are legal even before a BattleSim has been instantiated.
	await map_click("river")
	for i in range(3):
		await map_click("wait1")
	var reservation: Dictionary = ui.world.create_battle_ticket()
	check(reservation.ok, "legal reserved-ticket test fixture created")
	await save_named("reserved")
	await load_named("reserved")
	check(scene.campaign_adapter != null and scene.sim.units.size() == 35 and ui.world.battle_ticket(reservation.ticket.battle_id).status == "running", "reserved save resumes one actual roster rather than training")
	check(ui.world.audit().is_empty(), "save/load lifecycle keeps resource audit clean")
	var checkpoints_before_restart: Array = scene.campaign_store.list_saves(true).saves
	scene.queue_free()
	await process_frame
	scene = load("res://scenes/battle.tscn").instantiate()
	scene.campaign_store = Store.new(test_id)
	root.add_child(scene)
	await process_frame
	await process_frame
	ui = scene.strategy
	panel = scene.save_panel
	check(scene.campaign_store.list_saves(true).saves == checkpoints_before_restart, "new application scene does not overwrite earlier life checkpoints")
	await load_named(life_id, true)
	check(ui.view.commander.alive and ui.view.hour == 0, "checkpoint remains loadable in a fresh scene/session")
	scene.queue_free()
	await process_frame
	print("CAMPAIGN_SAVE_SCENE_SUMMARY " + JSON.stringify({"assertions": checks, "failures": failures.size(), "messages": failures, "isolated_campaign": test_id}))
	quit(0 if failures.is_empty() else 1)
