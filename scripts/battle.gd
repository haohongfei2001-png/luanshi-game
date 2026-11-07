extends Node3D

const Simulation := preload("res://scripts/battle_sim.gd")
const UnitView := preload("res://scripts/unit_view.gd")
const InputActions := preload("res://scripts/input_actions.gd")
const Strategy := preload("res://scripts/strategy_view.gd")
const Hud := preload("res://scripts/battle_hud.gd")
const Adapter := preload("res://scripts/battle_adapter.gd")
const SavePanel := preload("res://scripts/campaign_save_panel.gd")
const Store := preload("res://scripts/campaign_store.gd")
const World := preload("res://scripts/world_sim.gd")
var campaign_store := Store.new("campaign")
var save_panel: Control
var save_busy := false
var strategy: Control
var paused_before_strategy := false
var sim := Simulation.new()
# Training is deliberately separate. Only adapter-backed encounters affect the campaign.
var training_sim: BattleSimulation
var training_paused := false
var campaign_adapter: RefCounted
var campaign_settlement: Dictionary = {}
var camera: Camera3D
var hud: Control
var views: Array[Node3D] = []
var paused := false
var scene_smoke := false
var campaign_smoke := false
var campaign_smoke_complete := false
var smoke_steps := 0
var smoke_actions: Dictionary = {}
var simulation_usec := 0
var physics_steps := 0
var cursor: MeshInstance3D
var effects: Array[Dictionary] = []
var capture_pending := false
var capture_complete := false
var frame_samples_ms: Array[float] = []
var last_frame_usec := 0
var rendered_frames := 0

func _ready() -> void:
	var arguments := OS.get_cmdline_user_args()
	if "--persistence-smoke-prepare" in arguments or "--persistence-smoke-resume" in arguments:
		set_process(false)
		set_physics_process(false)
		set_process_input(false)
		set_process_unhandled_input(false)
		var phase := "prepare" if "--persistence-smoke-prepare" in arguments else "resume"
		var smoke_id := "export_v1"
		for argument in arguments:
			if argument.begins_with("--persistence-smoke-id="):
				smoke_id = argument.trim_prefix("--persistence-smoke-id=")
		var proof: Dictionary = preload("res://scripts/campaign_persistence_smoke.gd").run(phase, smoke_id)
		print("PERSISTENCE_SMOKE_%s_%s %s" % [phase.to_upper(), "PASS" if proof.ok else "FAIL", JSON.stringify(proof)])
		get_tree().quit(0 if proof.ok else 1)
		return
	for argument in arguments:
		if argument.begins_with("--campaign-save-id="):
			campaign_store = Store.new(argument.trim_prefix("--campaign-save-id="))
	InputActions.install()
	scene_smoke = "--smoke-scene" in OS.get_cmdline_user_args()
	campaign_smoke = "--campaign-smoke" in OS.get_cmdline_user_args()
	_build_battlefield()
	var canvas := CanvasLayer.new()
	add_child(canvas)
	hud = Hud.new()
	hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(hud)
	hud.action_requested.connect(_request_action)
	hud.restart_requested.connect(_restart)
	hud.pause_requested.connect(_toggle_pause)
	hud.strategy_requested.connect(_toggle_strategy)
	hud.saves_requested.connect(_open_save_panel)
	strategy = Strategy.new()
	strategy.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(strategy)
	strategy.hide()
	strategy.close_requested.connect(_toggle_strategy)
	strategy.assault_requested.connect(_start_campaign_battle)
	strategy.campaign_reset.connect(_on_campaign_reset)
	strategy.saves_requested.connect(_open_save_panel)
	save_panel = SavePanel.new()
	save_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(save_panel)
	save_panel.hide()
	save_panel.close_requested.connect(_close_save_panel)
	save_panel.save_requested.connect(func(slot: String): _request_save_operation("save", slot))
	save_panel.load_requested.connect(func(id: String, checkpoint: bool): _request_save_operation("load", id, checkpoint))
	save_panel.checkpoint_requested.connect(func(): _request_save_operation("checkpoint"))
	save_panel.list_requested.connect(func(_checkpoints: bool): _refresh_save_list())
	training_sim = sim
	_restart()
	if campaign_smoke:
		_start_campaign_smoke()
	print("LUANSHI_READY engine=%s soldiers=%d+%d renderer=%s" % [Engine.get_version_info().string, sim.alive_count(0), sim.alive_count(1), RenderingServer.get_current_rendering_method()])

func _build_battlefield() -> void:
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color("7e9089")
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color("ffffff")
	environment.environment.ambient_light_energy = 0.30
	environment.environment.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	add_child(environment)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-58, -28, 0)
	sun.light_color = Color("fff2dc")
	sun.light_energy = 0.75
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 90
	add_child(sun)
	camera = Camera3D.new()
	camera.position = Vector3(0, 46, 36)
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 80.0
	camera.near = 0.1
	camera.far = 150
	camera.keep_aspect = Camera3D.KEEP_WIDTH
	add_child(camera)
	camera.look_at(Vector3(0, 0, 2))
	camera.current = true
	UnitView.add_box(self, Vector3(76, 0.5, 52), UnitView.material(Color("5d6850")), Vector3(0, -0.28, 0))
	UnitView.add_box(self, Vector3(62, 0.04, 38), UnitView.material(Color("857959")), Vector3(0, -0.01, 0))
	UnitView.add_box(self, Vector3(64, 0.02, 7), UnitView.material(Color("978768")), Vector3(0, 0.02, 0))
	# Furrow lines, border posts and camp banners give a grounded sense of scale.
	var line_material := UnitView.material(Color("756b50"))
	for z in [-15.0, -11.0, 11.0, 15.0]:
		UnitView.add_box(self, Vector3(62, 0.02, 0.12), line_material, Vector3(0, 0.025, z))
	var wood := UnitView.material(Color("4e4030"))
	for x in range(-30, 31, 5):
		for z in [-19.7, 19.7]:
			UnitView.add_box(self, Vector3(0.22, 1.0, 0.22), wood, Vector3(x, 0.5, z))
	for side in [-1, 1]:
		var camp_color := Color("397a79") if side == -1 else Color("a04a35")
		for z in [-13, 13]:
			UnitView.add_box(self, Vector3(0.18, 5.0, 0.18), wood, Vector3(side * 27, 2.5, z))
			UnitView.add_box(self, Vector3(2.5, 1.5, 0.08), UnitView.material(camp_color), Vector3(side * 27 + 1.2, 4.1, z))
	var retreat_material := UnitView.material(Color("557d6a"))
	UnitView.add_box(self, Vector3(4.0, 0.03, 36), retreat_material, Vector3(-29, 0.03, 0))
	var stone := UnitView.material(Color("5b6056"))
	for i in range(18):
		var rock := SphereMesh.new()
		rock.radius = 0.5 + (i % 3) * 0.22
		rock.height = rock.radius
		rock.radial_segments = 6
		rock.rings = 3
		UnitView.add_mesh(self, rock, stone, Vector3(-32 + (i % 9) * 8, 0.2, -22 if i < 9 else 22))
	var marker := TorusMesh.new()
	marker.inner_radius = 0.33
	marker.outer_radius = 0.43
	marker.rings = 16
	marker.ring_segments = 5
	cursor = UnitView.add_mesh(self, marker, UnitView.material(Color("ead9aa")), Vector3.ZERO)
	cursor.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

func _restart() -> void:
	if save_panel != null and save_panel.visible:
		return
	if strategy != null and strategy.visible:
		return
	if campaign_adapter != null:
		# R never rewinds a campaign transaction or revives its commander.
		if sim.ended and campaign_settlement.get("ok", false):
			_toggle_strategy()
		return
	sim.reset()
	paused = false
	_rebuild_unit_views()

func _rebuild_unit_views() -> void:
	for view in views:
		view.queue_free()
	views.clear()
	for effect in effects:
		effect.node.queue_free()
	effects.clear()
	for unit in sim.units:
		var view := UnitView.new()
		add_child(view)
		view.configure(unit)
		views.append(view)
	_sync_visuals(0.0)
	_refresh_hud()

func _start_campaign_battle() -> void:
	if save_busy or (campaign_adapter != null and not sim.ended):
		return
	var current: Dictionary = strategy.world.player_view()
	if current.campaign_ended or not current.active_battle.is_empty() or current.local_city.get("id", "") != "hequ" or current.local_city.get("owner", "") == current.army.owner or current.local_city.get("soldiers", 0) <= 0 or current.army.soldiers <= 0:
		strategy.set_feedback("Assault unavailable: no eligible local hostile force.")
		return
	_request_save_operation("prebattle")

func _begin_campaign_battle(checkpoint: Dictionary) -> void:
	var next_adapter := Adapter.new(strategy.world)
	var started: Dictionary = next_adapter.begin_local_depot()
	if not started.get("ok", false):
		strategy.set_feedback("Assault unavailable: " + str(started.get("reason", "The force cannot engage.")))
		return
	if campaign_adapter == null:
		training_paused = paused_before_strategy
	campaign_adapter = next_adapter
	campaign_settlement = {}
	sim = campaign_adapter.simulation
	paused = false
	paused_before_strategy = false
	strategy.hide()
	hud.show()
	strategy.set_battle_context(true, true)
	_rebuild_unit_views()
	if not checkpoint.ok:
		_open_save_panel()
		save_panel.set_feedback("Battle ready, but the pre-battle checkpoint could not be saved. " + _save_error(checkpoint), true)

func _settle_campaign_battle() -> void:
	if campaign_adapter == null or not sim.ended or campaign_settlement.get("ok", false):
		return
	campaign_settlement = campaign_adapter.settle()
	if campaign_settlement.get("ok", false):
		strategy.set_battle_context(true, false)
		strategy.show_battle_result(sim.report())
	else:
		# A rejected settlement must not unlock actions, discard the roster or reset the world.
		paused = true
		strategy.set_feedback("Battle settlement blocked: " + str(campaign_settlement.get("reason", "Unknown error")))

func _on_campaign_reset() -> void:
	if campaign_adapter != null:
		campaign_adapter = null
		campaign_settlement = {}
		sim = training_sim
		paused_before_strategy = training_paused
		paused = true
		strategy.set_battle_context(false, false)
		_rebuild_unit_views()
	_request_save_operation("newlife")

func _open_save_panel() -> void:
	if save_panel.visible:
		return
	# A separate presentation gate freezes play without changing the prior pause.
	strategy.interaction_blocked = true
	save_panel.set_context(strategy.world.player_view())
	save_panel.show()
	cursor.hide()
	save_panel.set_feedback("Select a save or enter a slot name. Loading replaces this campaign; training is unchanged.")
	_refresh_save_list()
	save_panel.buttons.close.grab_focus()

func _close_save_panel() -> void:
	if save_busy:
		return
	save_panel.hide()
	strategy.interaction_blocked = false
	get_viewport().gui_release_focus()

func _request_save_operation(operation: String, id: String = "", checkpoint: bool = false) -> void:
	if save_busy:
		return
	_open_save_panel()
	save_busy = true
	save_panel.set_busy(true)
	var busy_messages := {"load": "Loading campaign... Please wait.", "prebattle": "Preparing encounter / saving pre-battle checkpoint...", "newlife": "Saving the new life's checkpoint..."}
	save_panel.set_feedback(busy_messages.get(operation, "Saving campaign... Please wait."))
	# Let the status draw before disk/validation work, including long histories.
	await get_tree().process_frame
	await get_tree().process_frame
	var result: Dictionary = {}
	match operation:
		"save": _save_campaign(id)
		"load": _load_campaign(id, checkpoint)
		"checkpoint": _create_checkpoint()
		"prebattle", "newlife": result = _save_life_checkpoint(operation)
	save_busy = false
	save_panel.set_busy(false)
	if operation == "prebattle":
		_close_save_panel()
		_begin_campaign_battle(result)
	elif operation == "newlife":
		if result.ok:
			_close_save_panel()
		else:
			save_panel.set_feedback("New campaign started, but its life checkpoint could not be saved. " + _save_error(result), true)

func _refresh_save_list(selected_id: String = "") -> void:
	var listed: Dictionary = campaign_store.list_saves(save_panel.is_checkpoint_mode())
	save_panel.show_entries(listed.get("saves", []), selected_id)
	if not listed.ok:
		save_panel.set_feedback("Could not list saves. " + _save_error(listed), true)

func _save_campaign(slot: String) -> Dictionary:
	var result: Dictionary = campaign_store.save_slot(strategy.world, slot)
	if result.ok:
		save_panel.category.select(0)
		save_panel._update_mode()
		_refresh_save_list(slot)
		save_panel.set_context(strategy.world.player_view())
		save_panel.set_feedback("Saved campaign to '%s'. Full world and any active battle preserved; training is not included." % slot)
	else:
		save_panel.set_feedback("Save failed. Current play and previous saves are unchanged. " + _save_error(result), true)
	return result

func _save_life_checkpoint(kind: String) -> Dictionary:
	# Unique across launches, even for the same game hour or restored life.
	# App startup never writes a checkpoint, and old checkpoints are never pruned.
	var id := "%s_%d_%s" % [kind, int(Time.get_unix_time_from_system()), Crypto.new().generate_random_bytes(6).hex_encode()]
	return campaign_store.save_checkpoint(strategy.world, id)

func _create_checkpoint() -> Dictionary:
	var result: Dictionary = _save_life_checkpoint("life")
	if result.ok:
		save_panel.category.select(1)
		save_panel._update_mode()
		_refresh_save_list(result.id)
		save_panel.set_feedback("Life checkpoint created. It remains available after death, new campaigns, and later launches.")
	else:
		save_panel.set_feedback("Checkpoint failed. " + _save_error(result), true)
	return result

func _load_campaign(id: String, checkpoint: bool = false) -> Dictionary:
	# Disk, schema and presentation preflight touch only a detached candidate.
	# Failed loads leave the live world, adapter, scene and pause state untouched.
	var candidate := World.new()
	var result: Dictionary = campaign_store.load_checkpoint(candidate, id) if checkpoint else campaign_store.load_slot(candidate, id)
	var active := ""
	if result.ok:
		active = candidate.player_view().active_battle
		if not active.is_empty():
			result = Adapter.new(candidate).resume(active)
	if not result.ok:
		save_panel.set_feedback("Load failed. Your current campaign is unchanged. " + _save_error(result), true)
		return result
	result = strategy.world.restore_campaign_state(candidate.export_campaign_state())
	if not result.ok:
		save_panel.set_feedback("Load failed. Your current campaign is unchanged. " + _save_error(result), true)
		return result
	if campaign_adapter == null:
		training_paused = paused_before_strategy if strategy.visible else paused
	campaign_adapter = null
	campaign_settlement = {}
	if not active.is_empty():
		# The same graph and resume operation passed above; authority remains the
		# existing strategy.world. Every old adapter/view is discarded explicitly.
		campaign_adapter = Adapter.new(strategy.world)
		campaign_adapter.resume(active)
		sim = campaign_adapter.simulation
		strategy.hide()
		hud.show()
		paused = true
		paused_before_strategy = true
		strategy.set_battle_context(true, true)
	else:
		sim = training_sim
		paused = true
		paused_before_strategy = training_paused
		strategy.show()
		hud.hide()
		strategy.set_battle_context(false, false)
		var known: Dictionary = strategy.world.player_view()
		var last_id: String = known.get("last_battle_id", "")
		if not last_id.is_empty():
			strategy.show_saved_battle_result(strategy.world.battle_ticket(last_id))
		else:
			strategy.set_feedback("Campaign loaded. Earlier saves and life checkpoints remain available.")
	_rebuild_unit_views()
	save_panel.set_context(strategy.world.player_view())
	save_panel.set_feedback("Loaded '%s'. %s" % [id, "Battle is paused. Close this panel, then Resume to continue." if not active.is_empty() else "Campaign restored. Close this panel to return to the map."])
	return {"ok": true}

func _save_error(result: Dictionary) -> String:
	var reason: String = result.get("reason", "unknown_error")
	match reason:
		"invalid_save_identifier": return "Use 1-48 letters, numbers, hyphens or underscores for a slot name."
		"save_read_failed": return "The save is missing or could not be read."
		"save_open_failed", "save_directory_failed", "save_write_failed", "save_replace_failed": return "The save folder could not be written. Check available disk space and access."
		"unsupported_save_schema": return "This save version is not supported by this build."
		_: return "Save data could not be used (%s)." % reason.replace("_", " ")

func _refresh_hud() -> void:
	hud.campaign_mode = campaign_adapter != null
	hud.settlement_complete = campaign_settlement.get("ok", false)
	hud.update_state(sim, paused, Engine.get_frames_per_second())

func _process(_delta: float) -> void:
	var now := Time.get_ticks_usec()
	if last_frame_usec > 0 and rendered_frames > 20:
		frame_samples_ms.append(float(now - last_frame_usec) / 1000.0)
	last_frame_usec = now
	rendered_frames += 1
	var capture_training := scene_smoke and "--capture-proof" in OS.get_cmdline_user_args() and smoke_steps >= 280
	var capture_campaign := campaign_smoke and "--capture-campaign" in OS.get_cmdline_user_args() and smoke_steps >= 360
	if (capture_training or capture_campaign) and not capture_pending:
		capture_pending = true
		await RenderingServer.frame_post_draw
		var snapshot := get_viewport().get_texture().get_image()
		var error := snapshot.save_png("res://artifacts/campaign-battle-proof.png" if capture_campaign else "res://artifacts/battle-proof.png")
		capture_complete = error == OK
		print("VISUAL_CAPTURE " + str(error))

func _input(event: InputEvent) -> void:
	if save_busy:
		get_viewport().set_input_as_handled()
		return
	if event.is_echo():
		return
	if event.is_action_pressed("campaign_saves"):
		_close_save_panel() if save_panel.visible else _open_save_panel()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("campaign_quicksave"):
		_request_save_operation("save", "quick")
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("campaign_quickload"):
		_request_save_operation("load", "quick")
		get_viewport().set_input_as_handled()
	elif save_panel.visible:
		if event.is_action_pressed("pause_battle") or event.is_action_pressed("toggle_strategy"):
			_close_save_panel()
			get_viewport().set_input_as_handled()
	elif event.is_action_pressed("toggle_strategy"):
		_toggle_strategy()
		get_viewport().set_input_as_handled()

func _toggle_strategy() -> void:
	if save_panel.visible:
		return
	if strategy.visible:
		strategy.hide()
		hud.show()
		paused = paused_before_strategy
	else:
		paused_before_strategy = paused
		paused = true
		hud.hide()
		strategy.refresh()
		strategy.show()
		cursor.hide()

func _unhandled_input(event: InputEvent) -> void:
	if strategy.visible or save_panel.visible:
		return
	if event.is_action_pressed("pause_battle"):
		_toggle_pause()
	elif event.is_action_pressed("toggle_help"):
		hud.show_help = not hud.show_help
	elif event.is_action_pressed("restart_battle") and sim.ended:
		_restart()
	elif not paused and not sim.ended:
		for action in ["sweep", "lunge", "guard", "order_attack", "order_follow", "order_retreat"]:
			if event.is_action_pressed(action):
				_request_action(action)

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and not scene_smoke and not campaign_smoke:
		paused = true

func _toggle_pause() -> void:
	if strategy.visible or save_panel.visible:
		return
	if not sim.ended:
		paused = not paused

func _request_action(action: String) -> void:
	if paused or sim.ended or save_panel.visible:
		return
	if action.begins_with("order_"):
		sim.issue_order(action.trim_prefix("order_"))
	else:
		sim.use_action(action)

func _physics_process(delta: float) -> void:
	if strategy.visible or save_panel.visible:
		return
	if sim.units.is_empty():
		return
	var mouse := get_viewport().get_mouse_position()
	var origin := camera.project_ray_origin(mouse)
	var direction := camera.project_ray_normal(mouse)
	var impact: Variant = Plane(Vector3.UP, 0).intersects_ray(origin, direction)
	var aim := sim.player_aim
	if impact != null and hud.is_world_pointer(mouse):
		cursor.position = impact + Vector3(0, 0.09, 0)
		aim = Vector2(impact.x, impact.z) - sim.player().pos
	cursor.visible = hud.is_world_pointer(mouse) and not sim.ended
	if not paused and not sim.ended:
		sim.set_player_input(InputActions.movement(), aim)
		if Input.is_action_pressed("attack") and (Input.is_physical_key_pressed(KEY_J) or hud.is_world_pointer(mouse)):
			sim.use_action("attack")
		if scene_smoke or campaign_smoke:
			_smoke_input()
		var start := Time.get_ticks_usec()
		sim.step(delta)
		simulation_usec += Time.get_ticks_usec() - start
		physics_steps += 1
		if campaign_adapter != null and not campaign_adapter.sync_world():
			paused = true
			push_error("Campaign world clock synchronization failed")
	_settle_campaign_battle()
	_sync_visuals(delta)
	_refresh_hud()
	if campaign_smoke and not campaign_smoke_complete:
		smoke_steps += 1
		if sim.ended or smoke_steps >= 7200:
			_finish_campaign_smoke()
	if scene_smoke:
		smoke_steps += 1
		if smoke_steps >= 3600 or sim.ended:
			var required := ["attack", "sweep", "lunge", "guard", "order_attack", "order_follow"]
			for action in required:
				if not smoke_actions.has(action):
					push_error("Scene smoke did not exercise " + action)
					get_tree().quit(1)
					return
			if not sim.ended:
				push_error("Scene smoke timed out without a result")
				get_tree().quit(1)
				return
			if "--capture-proof" in OS.get_cmdline_user_args() and not capture_complete:
				push_error("Scene smoke did not produce its required visual evidence")
				get_tree().quit(1)
				return
			print("SCENE_SMOKE_PASS " + JSON.stringify({"steps": smoke_steps, "mean_simulation_ms": float(simulation_usec) / max(physics_steps, 1) / 1000.0, "actions": smoke_actions, "report": sim.report(), "frame_timing": _frame_timing()}))
			get_tree().quit(0)

func _start_campaign_smoke() -> void:
	# Uses the real campaign command path and adapter; no injected casualties or outcome.
	_toggle_strategy()
	strategy._command("march", "river")
	strategy._command("advance", "", 3)
	strategy._command("seize")
	while save_busy:
		await get_tree().process_frame
	if campaign_adapter == null or sim.units.size() != 35 or sim.alive_count(0, true) != 20 or sim.alive_count(1) != 15:
		push_error("Campaign smoke failed to launch a real 20 vs 15 roster")
		get_tree().quit(1)

func _finish_campaign_smoke() -> void:
	campaign_smoke_complete = true
	var current: Dictionary = strategy.world.player_view()
	var report: Dictionary = sim.report()
	var loss_count: int = report.friendly_casualties + (0 if report.player_alive else 1)
	var before_repeat := var_to_str(current)
	var repeated: Dictionary = campaign_adapter.settle()
	var valid: bool = sim.ended and campaign_settlement.get("ok", false) and repeated.get("already_committed", false)
	valid = valid and current.active_battle == "" and strategy.world.audit().is_empty()
	valid = valid and current.army.soldiers == 60 - loss_count and current.army.soldiers >= 40
	valid = valid and absf(current.time_seconds - (10800.0 + sim.elapsed)) < 0.00001
	valid = valid and before_repeat == var_to_str(strategy.world.player_view())
	if "--capture-campaign" in OS.get_cmdline_user_args():
		valid = valid and capture_complete
	for action in ["attack", "sweep", "lunge", "guard", "order_attack", "order_follow"]:
		valid = valid and smoke_actions.has(action)
	if not valid:
		push_error("Campaign smoke did not finish a conserved, exactly-once encounter: " + JSON.stringify(campaign_settlement))
		get_tree().quit(1)
		return
	print("CAMPAIGN_SMOKE_PASS " + JSON.stringify({"steps": smoke_steps, "report": report,
		"settlement": campaign_settlement, "army": current.army, "world_time_seconds": current.time_seconds,
		"actions": smoke_actions, "mean_simulation_ms": float(simulation_usec) / max(physics_steps, 1) / 1000.0,
		"frame_timing": _frame_timing()}))
	get_tree().quit(0)

func _smoke_input() -> void:
	# Runs the real scene and views using deterministic scripted controls.
	if smoke_steps == 0:
		sim.issue_order("attack")
		smoke_actions["order_attack"] = true
	if smoke_steps == 120:
		sim.issue_order("follow")
		smoke_actions["order_follow"] = true
	if smoke_steps == 180:
		sim.issue_order("attack")
	var target_id := sim._nearest_enemy(sim.player())
	if target_id >= 0:
		var offset: Vector2 = sim.units[target_id].pos - sim.player().pos
		sim.set_player_input(offset.normalized() if offset.length() > 2.3 else Vector2.ZERO, offset)
		if offset.length() < 7:
			for action in ["attack", "sweep", "lunge", "guard"]:
				if sim.use_action(action):
					smoke_actions[action] = true

func _sync_visuals(delta: float) -> void:
	for i in range(views.size()):
		views[i].update_state(sim.units[i], sim.elapsed)
	for event in sim.events:
		if event.type == "skill" and event.name != "guard":
			var dust := TorusMesh.new()
			dust.inner_radius = 0.94
			dust.outer_radius = 1.0
			dust.rings = 24
			dust.ring_segments = 4
			var effect := UnitView.add_mesh(self, dust, UnitView.material(Color("c8ad76")), Vector3(event.pos.x, 0.12, event.pos.y))
			effects.append({"node": effect, "remaining": 0.22})
	sim.events.clear()
	for i in range(effects.size() - 1, -1, -1):
		effects[i].remaining -= delta
		effects[i].node.scale = Vector3.ONE * (1.0 + (0.22 - effects[i].remaining) * 13.0)
		if effects[i].remaining <= 0.0:
			effects[i].node.queue_free()
			effects.remove_at(i)

func _frame_timing() -> Dictionary:
	if frame_samples_ms.is_empty():
		return {}
	var ordered := frame_samples_ms.duplicate()
	ordered.sort()
	var total := 0.0
	for duration in ordered:
		total += duration
	return {"display": DisplayServer.get_name(), "device": RenderingServer.get_video_adapter_name(),
		"sample_count": ordered.size(), "wall_mean_ms": total / ordered.size(),
		"wall_p50_ms": ordered[int(ordered.size() * 0.5)],
		"wall_p95_ms": ordered[mini(int(ordered.size() * 0.95), ordered.size() - 1)]}
