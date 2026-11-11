extends Node3D

const Simulation := preload("res://scripts/battle_sim.gd")
const UnitView := preload("res://scripts/unit_view.gd")
const InputActions := preload("res://scripts/input_actions.gd")
const Strategy := preload("res://scripts/strategy_view.gd")
const Hud := preload("res://scripts/battle_hud.gd")
const Adapter := preload("res://scripts/battle_adapter.gd")
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
	strategy = Strategy.new()
	strategy.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(strategy)
	strategy.hide()
	strategy.close_requested.connect(_toggle_strategy)
	strategy.assault_requested.connect(_start_campaign_battle)
	strategy.campaign_reset.connect(_on_campaign_reset)
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
	if campaign_adapter != null and not sim.ended:
		return
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
	if campaign_adapter == null:
		return
	campaign_adapter = null
	campaign_settlement = {}
	sim = training_sim
	paused_before_strategy = training_paused
	paused = true
	strategy.set_battle_context(false, false)
	_rebuild_unit_views()

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
	if event.is_action_pressed("toggle_strategy") and not event.is_echo():
		_toggle_strategy()
		get_viewport().set_input_as_handled()

func _toggle_strategy() -> void:
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
	if strategy.visible:
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
	if strategy.visible:
		return
	if not sim.ended:
		paused = not paused

func _request_action(action: String) -> void:
	if paused or sim.ended:
		return
	if action.begins_with("order_"):
		sim.issue_order(action.trim_prefix("order_"))
	else:
		sim.use_action(action)

func _physics_process(delta: float) -> void:
	if strategy.visible:
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
