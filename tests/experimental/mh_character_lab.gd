extends SceneTree
## Native8 diagnostic preview only. Source9 weights need full-influence adapter for faithful rendering.
var actor: Node3D
var player: AnimationPlayer
var skeleton: Skeleton3D
var elapsed := 0.0
var last_clip := ""
var rendered := 0
var test_mode := false
var captured := false
var sequence := [
	[0.0, "Idle"], [2.0, "Walk"], [5.0, "Jog_Fwd"],
	[8.0, "Sprint"], [10.0, "Walk"], [12.0, "Idle"],
	[14.0, "Sword_Idle"], [16.0, "Sword_Attack"], [18.0, "Hit_Chest"],
	[19.0, "Hit_Head"], [20.0, "Death01"]]
func _initialize() -> void: call_deferred("setup")
func setup() -> void:
	test_mode = OS.has_environment("MH_TEST")
	var stage := Node3D.new();root.add_child(stage)
	var model_path := "res://assets/mh_lab/mh_natural_animated_full.glb"
	var packed := load(model_path) as PackedScene
	if packed == null:
		push_error("MH animated GLB not imported; run seed import first")
		quit(1)
		return
	actor = packed.instantiate();stage.add_child(actor)
	player = actor.find_children("*", "AnimationPlayer", true, false)[0]
	skeleton = actor.find_children("*", "Skeleton3D", true, false)[0]
	for clip in player.get_animation_list():
		if clip in ["Idle", "Walk", "Jog_Fwd", "Sprint", "Sword_Idle"]: player.get_animation(clip).loop_mode = Animation.LOOP_LINEAR
	player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	var env := WorldEnvironment.new();var e := Environment.new();env.environment=e
	e.background_mode=Environment.BG_COLOR;e.background_color=Color(.14,.17,.2)
	e.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;e.ambient_light_color=Color(.8,.85,.9);e.ambient_light_energy=.65
	stage.add_child(env)
	var sun := DirectionalLight3D.new();sun.rotation_degrees=Vector3(-40,-25,0);sun.light_energy=1.2;stage.add_child(sun)
	var floor_mesh := MeshInstance3D.new();var plane:=PlaneMesh.new();plane.size=Vector2(30,30);floor_mesh.mesh=plane
	var mat:=StandardMaterial3D.new();mat.albedo_color=Color(.25,.28,.3);mat.roughness=1.;floor_mesh.material_override=mat;stage.add_child(floor_mesh)
	var cam:=Camera3D.new();stage.add_child(cam);cam.projection=Camera3D.PROJECTION_ORTHOGONAL
	cam.size=float(OS.get_environment("MH_VIEW_SIZE")) if OS.has_environment("MH_VIEW_SIZE") else 3.4
	cam.position=Vector3(3,2.1,4);cam.look_at(Vector3(0,1,0));cam.current=true
	if test_mode:
		var report:Dictionary={"bones":skeleton.get_bone_count(),"clips":[],"visual_pass":false,"battle":false,"native8_preview_is_not_full9_skinning":true}
		assert(skeleton.get_bone_count()==163)
		for clip in player.get_animation_list():
			if clip=="RESET":continue
			player.play(clip);player.advance(0.0)
			var start:=skeleton.get_bone_pose_rotation(skeleton.find_bone("upperarm01.L"))
			player.advance(player.get_animation(clip).length*.45)
			var angle:=start.angle_to(skeleton.get_bone_pose_rotation(skeleton.find_bone("upperarm01.L")))
			assert(is_finite(angle));report.clips.append({"clip":clip,"upperarm_delta_rad":angle,"length":player.get_animation(clip).length})
		assert(report.clips.size()==9)
		DirAccess.make_dir_recursive_absolute("res://artifacts/mh-natural")
		var f:=FileAccess.open("res://artifacts/mh-natural/import.json",FileAccess.WRITE);f.store_string(JSON.stringify(report,"  "));f.close()
		print("MH_NATIVE_IMPORT ",JSON.stringify(report));quit();return
func _process(delta:float) -> bool:
	if player==null or test_mode:return false
	elapsed+=delta
	var clip:String=sequence[0][1]
	for entry in sequence:
		if elapsed>=entry[0]:clip=entry[1]
	if clip!=last_clip:player.play(clip,.15);last_clip=clip
	player.advance(delta)
	# Presentation-only turn during walk->idle. No invented authored turn clip.
	actor.rotation.y = smoothstep(10.0,13.0,elapsed)*PI*.5
	rendered+=1
	if not captured and elapsed>=4.0 and OS.has_environment("MH_CAPTURE"):
		captured=true
		call_deferred("capture_frame")
	if elapsed>=23.0:
		print("MH_LAB_DONE ",JSON.stringify({"seconds":elapsed,"frames":rendered,"viewport":root.size,"internal_scale":root.scaling_3d_scale,"visual_pass":false,"battle":false,"native8_preview_is_not_full9_skinning":true}));quit()
	return false

func capture_frame() -> void:
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://artifacts/mh-natural")
	root.get_texture().get_image().save_png("res://artifacts/mh-natural/native.png")
