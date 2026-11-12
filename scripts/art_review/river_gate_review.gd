extends Node3D
## A separate, data-driven art review. It never loads battle or campaign state.
## Standard glTF assets are imported directly, including on a clean checkout.

const ROOT := "res://assets/river_gate/art_v1/"
const VIEWS := ["army", "portrait", "equipment", "map", "crowd"]
const VIEW_TITLES := ["TWO ARMIES", "CHARACTER STUDY", "EQUIPMENT & ENVIRONMENT", "RIVER GATE", "1024 STATIC FIGURES"]
const FACTIONS := ["frontier", "garrison"]
const CLIPS := ["idle", "walk", "attack"]
const ROLE_ORDER := ["recruit", "swordsman", "daoman", "staffman", "spearman", "glaiveman", "shieldman", "archer", "crossbowman", "guard", "cavalry", "engineer", "captain", "vanguard", "challenger", "elite_officer", "commander"]

var records: Array[Dictionary] = []
var prop_records: Array[Dictionary] = []
var model_cache: Dictionary = {}
var used_paths: Array[String] = []
var players: Array[AnimationPlayer] = []
var failures: Array[String] = []
var content: Node3D
var camera: Camera3D
var hud: CanvasLayer
var detail_label: Label
var view_label: Label
var tab_buttons: Array[Button] = []
var current_view := 0
var current_lod := 0
var role_index := 4
var clip_index := 0
var focus := Vector3.ZERO
var yaw := 0.28
var pitch := 0.36
var camera_size := 28.0
var output_path := ""
var capture_frames := 45
var frame_count := 0
var static_count := 0
var building := false
var captured := false

func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--art-shot="):
			current_view = VIEWS.find(arg.get_slice("=", 1))
		elif arg.begins_with("--art-output="):
			output_path = arg.trim_prefix("--art-output=")
		elif arg.begins_with("--art-frames="):
			capture_frames = maxi(2, int(arg.get_slice("=", 1)))
		elif arg.begins_with("--art-role="):
			role_index = ROLE_ORDER.find(arg.get_slice("=", 1))
		elif arg.begins_with("--art-lod="):
			current_lod = clampi(int(arg.get_slice("=", 1)), 0, 2)
	if current_view < 0 or role_index < 0:
		_fail("Unknown art view or role; see tools/art_review/README.md")
		get_tree().quit(2)
		return
	if not output_path.is_empty() and not output_path.is_absolute_path():
		_fail("--art-output must be an absolute PNG path")
		get_tree().quit(2)
		return
	records = _catalogue(ROOT + "characters/catalogue.json", false)
	for kind in ["equipment", "environment"]:
		prop_records.append_array(_catalogue(ROOT + kind + "/catalogue.json", false))
	_setup_stage()
	_setup_hud()
	await _show_view(current_view)
	if not failures.is_empty() and not output_path.is_empty():
		get_tree().quit(2)

func _catalogue(path: String, required: bool) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if not FileAccess.file_exists(path):
		if required:
			_fail("Missing catalogue: " + path)
		return result
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not data is Dictionary or not data.get("assets", []) is Array:
		_fail("Invalid catalogue: " + path)
		return result
	for entry in data.get("assets", []):
		if entry is Dictionary:
			result.append(entry)
	return result

func _fail(message: String) -> void:
	failures.append(message)
	push_error("ART_REVIEW: " + message)

func _path(entry: Dictionary) -> String:
	var path := String(entry.get("file", ""))
	if not path.begins_with("res://"):
		path = "res://" + path
	return path

func _instance(path: String, at: Vector3) -> Node3D:
	if not FileAccess.file_exists(path):
		_fail("Missing asset: " + path)
		return null
	if not model_cache.has(path):
		var document := GLTFDocument.new()
		var state := GLTFState.new()
		var error := document.append_from_file(path, state)
		if error != OK:
			_fail("glTF import failed (%s): %s" % [error, path])
			return null
		var generated := document.generate_scene(state)
		if generated == null:
			_fail("glTF generated no scene: " + path)
			return null
		var packed := PackedScene.new()
		var pack_error := packed.pack(generated)
		generated.free()
		if pack_error != OK:
			_fail("Could not cache glTF scene: " + path)
			return null
		model_cache[path] = packed
	var node := (model_cache[path] as PackedScene).instantiate() as Node3D
	if node == null:
		_fail("glTF has no Node3D root: " + path)
		return null
	content.add_child(node)
	node.position = at
	if not used_paths.has(path):
		used_paths.append(path)
	return node

func _character(faction: String, role: String, lod: int, at: Vector3) -> Node3D:
	for entry in records:
		if entry.get("faction") == faction and entry.get("role") == role and int(entry.get("lod", -1)) == lod:
			var node := _instance(_path(entry), at)
			if node:
				for child in node.find_children("*", "AnimationPlayer", true, false):
					var player := child as AnimationPlayer
					players.append(player)
					_play_clip(player)
			return node
	_fail("Missing character: %s / %s / LOD%s" % [faction, role, lod])
	return null

func _play_clip(player: AnimationPlayer) -> void:
	var selected := String(CLIPS[clip_index])
	for animation in player.get_animation_list():
		if String(animation).get_file() == selected or String(animation).ends_with(selected):
			player.get_animation(animation).loop_mode = Animation.LOOP_LINEAR
			player.play(animation)
			player.seek(0.22, true)
			return
	_fail("Missing animation '%s' in %s" % [selected, player.get_path()])

func _setup_stage() -> void:
	var world := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("b2b8b6")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("c9d3df")
	environment.ambient_light_energy = 0.55
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	world.environment = environment
	add_child(world)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-47, -32, 0)
	sun.light_color = Color("fff0d9")
	sun.light_energy = 1.7
	sun.shadow_enabled = true
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
	sun.directional_shadow_max_distance = 340.0
	add_child(sun)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-25, 145, 0)
	fill.light_color = Color("aebfca")
	fill.light_energy = 0.4
	add_child(fill)
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.far = 1400.0
	camera.near = 0.02
	add_child(camera)
	camera.make_current()
	get_viewport().msaa_3d = Viewport.MSAA_2X

func _ground(size: Vector2, tint: Color) -> void:
	var mesh := PlaneMesh.new()
	mesh.size = size
	var mat := StandardMaterial3D.new()
	mat.albedo_color = tint
	mat.roughness = 0.94
	mesh.material = mat
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.position.y = -0.018
	content.add_child(instance)

func _show_view(index: int) -> void:
	building = true
	current_view = index
	players.clear()
	used_paths.clear()
	failures.clear()
	static_count = 0
	frame_count = 0
	if is_instance_valid(content):
		content.free()
	content = Node3D.new()
	content.name = "ReviewContents"
	add_child(content)
	match current_view:
		0:
			_ground(Vector2(75, 50), Color("7b7b69"))
			for faction_index in 2:
				for i in ROLE_ORDER.size():
					var column := i % 9
					var row := i / 9
					var at := Vector3((column - 4) * 2.4, 0, row * 3.3 + faction_index * 8.0 - 5.5)
					_character(FACTIONS[faction_index], ROLE_ORDER[i], 1, at)
			focus = Vector3(0, 0.7, 0.4)
			camera_size = 29
			yaw = 0.11
			pitch = 0.58
		1:
			_ground(Vector2(25, 25), Color("777b70"))
			for i in 2:
				_character(FACTIONS[i], ROLE_ORDER[role_index], current_lod, Vector3(-0.8 + 1.6 * i, 0, 0))
			focus = Vector3(0, 0.97, 0)
			camera_size = 3.9
			yaw = 0.20
			pitch = 0.14
		2:
			if prop_records.is_empty():
				_fail("No equipment/environment catalogues; generate environment.py first")
			_ground(Vector2(170, 145), Color("7b7b69"))
			for i in prop_records.size():
				var entry: Dictionary = prop_records[i]
				var at := Vector3((i % 6 - 2.5) * 18, 0, (i / 6 - 2.0) * 18)
				_instance(_path(entry), at)
				_world_label(String(entry.get("id", "asset")).replace("_", " "), at + Vector3(0, 0.12, 6.2), 0.035)
			focus = Vector3(0, 1, 0)
			camera_size = 121
			yaw = 0.18
			pitch = 0.84
		3:
			_instance(ROOT + "maps/river_gate_map.glb", Vector3.ZERO)
			focus = Vector3(-5, 0, 0)
			camera_size = 260
			yaw = -0.32
			pitch = 0.83
		4:
			_ground(Vector2(100, 90), Color("7b7b69"))
			await _static_crowd()
			focus = Vector3(0, 0.5, 0)
			camera_size = 73
			yaw = 0.16
			pitch = 0.70
	_update_camera()
	_update_hud()
	building = false
	if failures.is_empty():
		print("ART_REVIEW_READY view=%s files=%s" % [VIEWS[current_view], used_paths.size()])

func _static_crowd() -> void:
	for team in 2:
		var sample := _character(FACTIONS[team], "spearman", 2, Vector3.ZERO)
		if sample == null:
			continue
		for player in players:
			player.pause()
		await get_tree().process_frame
		await get_tree().process_frame
		for child in sample.find_children("*", "MeshInstance3D", true, false):
			var source := child as MeshInstance3D
			if source.mesh == null:
				continue
			var mesh: Mesh = source.mesh
			if source.skin != null:
				mesh = source.bake_mesh_from_current_skeleton_pose()
				for surface in mesh.get_surface_count():
					(mesh as ArrayMesh).surface_set_material(surface, source.get_active_material(surface))
			var batch := MultiMesh.new()
			batch.transform_format = MultiMesh.TRANSFORM_3D
			batch.mesh = mesh
			batch.instance_count = 512
			for i in 512:
				var position := Vector3((i % 32 - 15.5) * 1.3, 0, (i / 32) * 1.5 + team * 30 - 27)
				batch.set_instance_transform(i, Transform3D(Basis.IDENTITY, position) * source.global_transform)
			var display := MultiMeshInstance3D.new()
			display.multimesh = batch
			content.add_child(display)
		static_count += 512
		sample.queue_free()
	players.clear()

func _world_label(text: String, at: Vector3, pixel_size: float) -> void:
	var label := Label3D.new()
	label.text = text
	label.font_size = 24
	label.pixel_size = pixel_size
	label.modulate = Color("ebe9db")
	label.outline_modulate = Color("333b35")
	label.outline_size = 5
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position = at
	content.add_child(label)

func _setup_hud() -> void:
	hud = CanvasLayer.new()
	add_child(hud)
	var top := PanelContainer.new()
	top.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	top.offset_bottom = 110
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.055, 0.075, 0.07, 0.93)
	style.content_margin_left = 28
	style.content_margin_top = 14
	style.content_margin_right = 28
	style.content_margin_bottom = 10
	top.add_theme_stylebox_override("panel", style)
	hud.add_child(top)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 4)
	top.add_child(column)
	var title := Label.new()
	title.text = "RIVER GATE  /  ASSET REVIEW"
	title.add_theme_font_size_override("font_size", 21)
	title.add_theme_color_override("font_color", Color("ece5cf"))
	column.add_child(title)
	var subtitle := Label.new()
	subtitle.text = "Independent Godot preview  ·  late-Tang inspired art  ·  not battle gameplay"
	subtitle.add_theme_font_size_override("font_size", 13)
	subtitle.modulate = Color("aab9b0")
	column.add_child(subtitle)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	column.add_child(row)
	for i in VIEWS.size():
		var button := Button.new()
		button.text = "%s  %s" % [i + 1, VIEW_TITLES[i]]
		button.add_theme_font_size_override("font_size", 12)
		button.pressed.connect(_change_view.bind(i))
		row.add_child(button)
		tab_buttons.append(button)
	var bottom := PanelContainer.new()
	bottom.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	bottom.offset_top = -82
	bottom.add_theme_stylebox_override("panel", style.duplicate())
	hud.add_child(bottom)
	var lines := VBoxContainer.new()
	bottom.add_child(lines)
	view_label = Label.new()
	view_label.add_theme_font_size_override("font_size", 16)
	view_label.modulate = Color("ece5cf")
	lines.add_child(view_label)
	detail_label = Label.new()
	detail_label.add_theme_font_size_override("font_size", 12)
	detail_label.modulate = Color("becac1")
	lines.add_child(detail_label)
	var controls := Label.new()
	controls.text = "1–5 Views   |   Space Animation   |   L LOD   |   Arrows Role   |   WASD Pan   |   Right-drag Orbit   |   Wheel Zoom   |   H HUD"
	controls.add_theme_font_size_override("font_size", 11)
	controls.modulate = Color("9aaca2")
	lines.add_child(controls)

func _update_hud() -> void:
	for i in tab_buttons.size():
		tab_buttons[i].modulate = Color("e4ce92") if i == current_view else Color.WHITE
	view_label.text = VIEW_TITLES[current_view]
	match current_view:
		0:
			detail_label.text = "West attacking army / blue cloth     •     River-gate garrison / red-brown cloth     •     17 roles per side / LOD1"
		1:
			detail_label.text = "%s  •  LOD%s  •  %s  •  same adult scale, separately inspectable armies" % [String(ROLE_ORDER[role_index]).replace("_", " "), current_lod, CLIPS[clip_index]]
		2:
			detail_label.text = "%s original prop files  •  metres, actual geometry  •  extension engines are art assets without live battle mechanics" % prop_records.size()
		3:
			detail_label.text = "236 × 128 m  •  river x = −32  •  three bridges  •  west camp / gate / courtyard  •  visual model, no navigation claim"
		4:
			detail_label.text = "%s figures / 512 per side  •  one baked idle pose / LOD2 MultiMesh  •  no AI, battle, collision, or performance acceptance" % static_count
	if not failures.is_empty():
		detail_label.text = "INCOMPLETE: " + failures[0]
		detail_label.modulate = Color("ffb09a")

func _change_view(index: int) -> void:
	if not building:
		await _show_view(index)

func _update_camera() -> void:
	var distance := camera_size * 1.8
	camera.position = focus + Vector3(sin(yaw) * cos(pitch), sin(pitch), cos(yaw) * cos(pitch)) * distance
	camera.look_at(focus)
	camera.size = camera_size

func _unhandled_input(event: InputEvent) -> void:
	if building or not output_path.is_empty():
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode >= KEY_1 and event.keycode <= KEY_5:
			await _show_view(int(event.keycode - KEY_1))
		elif event.keycode == KEY_SPACE and current_view != 4:
			clip_index = (clip_index + 1) % CLIPS.size()
			for player in players:
				_play_clip(player)
			_update_hud()
		elif event.keycode == KEY_L:
			current_lod = (current_lod + 1) % 3
			await _show_view(1)
		elif event.keycode in [KEY_LEFT, KEY_RIGHT]:
			role_index = posmod(role_index + (1 if event.keycode == KEY_RIGHT else -1), ROLE_ORDER.size())
			await _show_view(1)
		elif event.keycode == KEY_H:
			hud.visible = not hud.visible
	elif event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		yaw -= event.relative.x * 0.006
		pitch = clampf(pitch + event.relative.y * 0.006, 0.06, 1.45)
		_update_camera()
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			camera_size = maxf(1.6, camera_size * 0.9)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			camera_size = minf(450.0, camera_size * 1.1)
		_update_camera()

func _process(delta: float) -> void:
	if building or not is_instance_valid(camera):
		return
	if output_path.is_empty():
		var direction := Vector3.ZERO
		if Input.is_physical_key_pressed(KEY_W): direction.z -= 1
		if Input.is_physical_key_pressed(KEY_S): direction.z += 1
		if Input.is_physical_key_pressed(KEY_A): direction.x -= 1
		if Input.is_physical_key_pressed(KEY_D): direction.x += 1
		if direction.length_squared() > 0:
			focus += direction.rotated(Vector3.UP, yaw) * delta * camera_size * 0.35
			_update_camera()
	else:
		frame_count += 1
		if frame_count >= capture_frames and not captured:
			captured = true
			await _capture()

func _capture() -> void:
	if not failures.is_empty() or used_paths.is_empty():
		_fail("Refusing to write a completion screenshot for an incomplete view")
		get_tree().quit(2)
		return
	if DisplayServer.get_name() == "headless":
		_fail("Headless mode cannot capture rendered evidence; use capture_review.sh")
		get_tree().quit(2)
		return
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	DirAccess.make_dir_recursive_absolute(output_path.get_base_dir())
	var result := image.save_png(output_path)
	if result != OK:
		_fail("PNG save failed: %s" % result)
		get_tree().quit(2)
		return
	var assets: Array[Dictionary] = []
	for path in used_paths:
		assets.append({"file": path.trim_prefix("res://"), "sha256": FileAccess.get_sha256(path)})
	var report := {
		"status": "PREVIEW_RENDERED", "evidence_kind": "independent_godot_asset_preview",
		"battle_integrated": false, "m5_performance_verified": false,
		"view": VIEWS[current_view], "engine": Engine.get_version_info(),
		"adapter": RenderingServer.get_video_adapter_name(), "vendor": RenderingServer.get_video_adapter_vendor(),
		"renderer": RenderingServer.get_current_rendering_method(), "display_server": DisplayServer.get_name(),
		"resolution": [image.get_width(), image.get_height()], "rendered_frames": frame_count,
		"camera": {"projection": "orthographic", "size": camera.size, "position": [camera.position.x, camera.position.y, camera.position.z], "target": [focus.x, focus.y, focus.z]},
		"role": ROLE_ORDER[role_index] if current_view == 1 else null,
		"lod": current_lod if current_view == 1 else (2 if current_view == 4 else 1),
		"animation": "baked_idle_static" if current_view == 4 else CLIPS[clip_index],
		"static_figure_count": static_count, "asset_files": assets,
		"png_sha256": FileAccess.get_sha256(output_path),
		"utc_time": Time.get_datetime_string_from_system(true) + "Z"
	}
	var report_file := FileAccess.open(output_path.get_basename() + ".json", FileAccess.WRITE)
	if report_file == null:
		_fail("Could not save screenshot provenance JSON")
		get_tree().quit(2)
		return
	report_file.store_string(JSON.stringify(report, "\t") + "\n")
	print("ART_REVIEW_CAPTURED ", output_path)
	get_tree().quit()
