extends Node3D

const Simulation := preload("res://scripts/battle_sim.gd")
const UnitView := preload("res://scripts/unit_view.gd")
const InputActions := preload("res://scripts/input_actions.gd")
const Hud := preload("res://scripts/battle_hud.gd")
var sim := Simulation.new()
var camera: Camera3D
var hud: Control
var views: Array[Node3D] = []
var paused := false
var scene_smoke := false
var smoke_steps := 0
var smoke_actions: Dictionary = {}
var simulation_usec := 0
var physics_steps := 0
var cursor: MeshInstance3D
var effects: Array[Dictionary] = []

func _ready() -> void:
	InputActions.install()
	scene_smoke = "--smoke-scene" in OS.get_cmdline_user_args()
	_build_battlefield()
	var canvas := CanvasLayer.new()
	add_child(canvas)
	hud = Hud.new()
	hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(hud)
	hud.action_requested.connect(_request_action)
	hud.restart_requested.connect(_restart)
	hud.pause_requested.connect(_toggle_pause)
	_restart()
	print("LUANSHI_READY engine=%s soldiers=%d+%d renderer=%s" % [Engine.get_version_info().string, sim.alive_count(0), sim.alive_count(1), RenderingServer.get_current_rendering_method()])

func _build_battlefield() -> void:
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color("7e9089")
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color("e3dfc9")
	environment.environment.ambient_light_energy = 0.65
	environment.environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	add_child(environment)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-58, -28, 0)
	sun.light_color = Color("ffebc5")
	sun.light_energy = 1.6
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 90
	add_child(sun)
	camera = Camera3D.new()
	camera.position = Vector3(0, 46, 34)
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 70.0
	camera.near = 0.1
	camera.far = 150
	camera.keep_aspect = Camera3D.KEEP_WIDTH
	add_child(camera)
	camera.look_at(Vector3(0, 0, 0))
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
	for view in views:
		view.queue_free()
	views.clear()
	for effect in effects:
		effect.node.queue_free()
	effects.clear()
	sim.reset()
	paused = false
	for unit in sim.units:
		var view := UnitView.new()
		add_child(view)
		view.configure(unit)
		views.append(view)
	_sync_visuals(0.0)

func _unhandled_input(event: InputEvent) -> void:
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
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and not scene_smoke:
		paused = true

func _toggle_pause() -> void:
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
		if scene_smoke:
			_smoke_input()
		var start := Time.get_ticks_usec()
		sim.step(delta)
		simulation_usec += Time.get_ticks_usec() - start
		physics_steps += 1
	_sync_visuals(delta)
	hud.update_state(sim, paused, Engine.get_frames_per_second())
	if scene_smoke:
		smoke_steps += 1
		if smoke_steps >= 3600 or sim.ended:
			print("SCENE_SMOKE_PASS " + JSON.stringify({"steps": smoke_steps, "mean_simulation_ms": float(simulation_usec) / max(physics_steps, 1) / 1000.0, "actions": smoke_actions, "report": sim.report()}))
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
