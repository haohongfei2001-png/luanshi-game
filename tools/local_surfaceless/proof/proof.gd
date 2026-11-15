extends Node

var root: Window

var frame_number: int = 0
var requested_size := Vector2i(768, 432)
var elapsed: float = 0.0
var moving_box: MeshInstance3D
var proof_label: Label
var captured: Array[Dictionary] = []
var taking_capture: bool = false
var input_event_count: int = 0
var unhandled_input_event_count: int = 0
var input_proof: Dictionary = {}
var output_dir: String = ProjectSettings.globalize_path("res://")

func _ready() -> void:
	root = get_tree().root
	InputMap.add_action("surfaceless_proof_action")
	root.scaling_3d_scale = 1.0
	root.size = Vector2i(768, 432)
	root.content_scale_size = Vector2i(768, 432)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	var world := Node3D.new()
	add_child(world)
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color(0.025, 0.045, 0.09)
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color(0.65, 0.75, 0.95)
	environment.environment.ambient_light_energy = 0.35
	world.add_child(environment)
	var floor_mesh := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(8.0, 7.0)
	floor_mesh.mesh = plane
	floor_mesh.material_override = material(Color(0.17, 0.23, 0.30), 0.9)
	world.add_child(floor_mesh)
	moving_box = MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(1.1, 1.4, 1.1)
	moving_box.mesh = box
	moving_box.position = Vector3(-1.5, 0.7, 0.0)
	moving_box.material_override = material(Color(0.9, 0.31, 0.08), 0.35)
	world.add_child(moving_box)
	var sphere := MeshInstance3D.new()
	var sphere_mesh := SphereMesh.new()
	sphere_mesh.radius = 0.7
	sphere_mesh.height = 1.4
	sphere.mesh = sphere_mesh
	sphere.position = Vector3(1.65, 0.7, 0.0)
	sphere.material_override = material(Color(0.05, 0.55, 0.85), 0.2)
	world.add_child(sphere)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-52, -34, 0)
	light.light_color = Color(1.0, 0.90, 0.75)
	light.light_energy = 1.8
	light.shadow_enabled = true
	world.add_child(light)
	var camera := Camera3D.new()
	camera.position = Vector3(5.0, 4.5, 8.0)
	world.add_child(camera)
	camera.look_at(Vector3(0, 0.4, 0))
	camera.current = true
	var ui := CanvasLayer.new()
	add_child(ui)
	var panel := ColorRect.new()
	panel.position = Vector2(16, 16)
	panel.size = Vector2(530, 63)
	panel.color = Color(0.01, 0.02, 0.04, 0.9)
	ui.add_child(panel)
	proof_label = Label.new()
	proof_label.position = Vector2(28, 24)
	proof_label.add_theme_font_size_override("font_size", 20)
	proof_label.text = "ACTUAL GODOT SceneTree / GLES3\nEGL surfaceless + Mesa software renderer"
	ui.add_child(proof_label)
	print("PROOF_RENDERER ", RenderingServer.get_video_adapter_name())
	print("PROOF_DRIVER ", DisplayServer.get_name(), " / ", RenderingServer.get_current_rendering_method())
	if DisplayServer.get_name() != "surfaceless" or not RenderingServer.get_video_adapter_name().contains("llvmpipe"):
		push_error("Expected actual surfaceless llvmpipe renderer, not Dummy.")
		get_tree().quit(2)

func material(color: Color, roughness: float) -> StandardMaterial3D:
	var result := StandardMaterial3D.new()
	result.albedo_color = color
	result.roughness = roughness
	return result

func _process(delta: float) -> void:
	frame_number += 1
	if frame_number == 4:
		check_synthetic_input(true)
	if frame_number == 5:
		check_synthetic_input(false)
	elapsed += delta
	moving_box.position.x = -1.7 + float(frame_number) * 0.028
	moving_box.rotation.y = float(frame_number) * 0.015
	if frame_number == 64:
		requested_size = Vector2i(1280, 720)
	if frame_number == 80:
		requested_size = Vector2i(2560, 1440)
	if frame_number == 96:
		requested_size = Vector2i(3840, 2160)
	if frame_number in [64, 80, 96]:
		root.size = requested_size
		root.content_scale_size = requested_size
	if frame_number in [8, 48, 64, 80, 96] and not taking_capture:
		taking_capture = true
		capture.call_deferred(frame_number, moving_box.position.x, elapsed)
	if frame_number > 130:
		push_error("Capture did not complete before watchdog.")
		get_tree().quit(3)

func capture(at_frame: int, at_x: float, at_elapsed: float) -> void:
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	if img == null or img.is_empty():
		push_error("SceneTree viewport readback empty.")
		get_tree().quit(4)
		return
	var path := output_dir.path_join("scenetree_frame_%02d.png" % at_frame)
	var err := img.save_png(path)
	if err != OK:
		push_error("PNG save failed: %d" % err)
		get_tree().quit(5)
		return
	captured.append({"frame":at_frame,"requested_size":[requested_size.x,requested_size.y],"root_size":[root.size.x,root.size.y],"scaling_3d_scale":root.scaling_3d_scale,"scaling_3d_mode":root.scaling_3d_mode,"box_x":at_x,"scene_elapsed_seconds":at_elapsed,"width":img.get_width(),"height":img.get_height(),"png":path.get_file(),"visible_draw_calls":root.get_render_info(Viewport.RENDER_INFO_TYPE_VISIBLE, Viewport.RENDER_INFO_DRAW_CALLS_IN_FRAME),"visible_primitives":root.get_render_info(Viewport.RENDER_INFO_TYPE_VISIBLE, Viewport.RENDER_INFO_PRIMITIVES_IN_FRAME),"canvas_draw_calls":root.get_render_info(Viewport.RENDER_INFO_TYPE_CANVAS, Viewport.RENDER_INFO_DRAW_CALLS_IN_FRAME)})
	print("PROOF_CAPTURE ", JSON.stringify(captured[-1]))
	taking_capture = false
	if captured.size() == 5:
		var result := {"scope":"minimal real Godot SceneTree lit mesh + shadow + UI + motion proof; not Luanshi scene/art/device proof", "display_driver":DisplayServer.get_name(), "rendering_method":RenderingServer.get_current_rendering_method(), "renderer":RenderingServer.get_video_adapter_name(), "vendor":RenderingServer.get_video_adapter_vendor(), "api":RenderingServer.get_video_adapter_api_version(), "engine":Engine.get_version_info(), "debug_feature":OS.has_feature("debug"), "llvmpipe_worker_threads":OS.get_environment("LP_NUM_THREADS"), "DISPLAY_present":OS.has_environment("DISPLAY"), "WAYLAND_DISPLAY_present":OS.has_environment("WAYLAND_DISPLAY"), "captures":captured, "synthetic_input_proof":input_proof, "status":"ACTUAL_SCENETREE_READBACK_COMPLETE_PENDING_PIXEL_QA"}
		FileAccess.open(output_dir.path_join("runtime_report.json"), FileAccess.WRITE).store_string(JSON.stringify(result, "  "))
		get_tree().quit()

func _input(_event: InputEvent) -> void:
	input_event_count += 1

func _unhandled_input(_event: InputEvent) -> void:
	unhandled_input_event_count += 1

func check_synthetic_input(pressed: bool) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = Vector2(123, 234)
	motion.global_position = motion.position
	Input.parse_input_event(motion)
	var key := InputEventKey.new()
	key.keycode = KEY_J
	key.physical_keycode = KEY_J
	key.pressed = pressed
	Input.parse_input_event(key)
	var action := InputEventAction.new()
	action.action = "surfaceless_proof_action"
	action.pressed = pressed
	Input.parse_input_event(action)
	Input.flush_buffered_events()
	var observed_pointer := root.get_mouse_position()
	var key_state := Input.is_physical_key_pressed(KEY_J)
	var action_state := Input.is_action_pressed("surfaceless_proof_action")
	var passed := observed_pointer.distance_to(Vector2(123, 234)) < 0.01 and key_state == pressed and action_state == pressed and input_event_count >= 3 and unhandled_input_event_count >= 1
	input_proof["press" if pressed else "release"] = {"scope":"synthetic Input API events only, not physical OS input or desktop focus", "requested_pointer":[123,234], "observed_pointer":[observed_pointer.x, observed_pointer.y], "requested_pressed":pressed, "physical_key_J_state":key_state, "action_state":action_state, "input_callback_count":input_event_count, "unhandled_callback_count":unhandled_input_event_count, "pass":passed}
	print("PROOF_INPUT ", JSON.stringify(input_proof["press" if pressed else "release"]))
	if not passed:
		push_error("Synthetic input dispatch/state proof failed.")
		get_tree().quit(6)
