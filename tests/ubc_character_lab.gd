extends SceneTree
## Isolated real native Skeleton3D animation lab. Not combat, art or performance PASS.
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
	test_mode = OS.has_environment("UBC_TEST")
	root.content_scale_size=Vector2i.ZERO
	root.content_scale_mode=Window.CONTENT_SCALE_MODE_DISABLED
	var stage := Node3D.new();root.add_child(stage)
	var model_path := "res://assets/ubc_lab/ubc_outfit.glb" if OS.has_environment("UBC_OUTFIT") else "res://assets/ubc_lab/ubc_animated.glb"
	actor = load(model_path).instantiate();stage.add_child(actor)
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
	cam.size=float(OS.get_environment("UBC_VIEW_SIZE")) if OS.has_environment("UBC_VIEW_SIZE") else 3.4
	cam.position=Vector3(3,2.1,4);cam.look_at(Vector3(0,1,0));cam.current=true
	if OS.has_environment("UBC_STILLS"):
		test_mode=true
		_stills.call_deferred(cam)
		return
	if test_mode:
		var report:Dictionary={"bones":skeleton.get_bone_count(),"clips":[],"visual_pass":false,"battle":false}
		assert(skeleton.get_bone_count()==65)
		for clip in player.get_animation_list():
			if clip=="RESET":continue
			player.play(clip);player.advance(0.0)
			var start:=skeleton.get_bone_pose_rotation(skeleton.find_bone("upperarm_l"))
			player.advance(player.get_animation(clip).length*.45)
			var angle:=start.angle_to(skeleton.get_bone_pose_rotation(skeleton.find_bone("upperarm_l")))
			assert(is_finite(angle));report.clips.append({"clip":clip,"upperarm_delta_rad":angle,"length":player.get_animation(clip).length})
		assert(report.clips.size()==9)
		DirAccess.make_dir_recursive_absolute("res://artifacts/ubc-character")
		var f:=FileAccess.open("res://artifacts/ubc-character/import.json",FileAccess.WRITE);f.store_string(JSON.stringify(report,"  "));f.close()
		print("UBC_NATIVE_IMPORT ",JSON.stringify(report));quit();return
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
	if not captured and elapsed>=4.0 and OS.has_environment("UBC_CAPTURE"):
		captured=true
		call_deferred("capture_frame")
	if elapsed>=23.0:
		print("UBC_LAB_DONE ",JSON.stringify({"seconds":elapsed,"frames":rendered,"viewport":root.size,"internal_scale":root.scaling_3d_scale,"visual_pass":false,"battle":false,"source_sha":OS.get_environment("UBC_SOURCE_SHA"),"camera_size":OS.get_environment("UBC_VIEW_SIZE"),"timing":"fixed cadence when MovieMaker requested, not a performance benchmark"}));quit()
	return false

func capture_frame() -> void:
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://artifacts/ubc-character")
	root.get_texture().get_image().save_png("res://artifacts/ubc-character/native.png")

func _stills(cam:Camera3D) -> void:
	if DisplayServer.get_name()=="headless":quit(1);return
	var out:=OS.get_environment("UBC_CAPTURE_OUT")
	DirAccess.make_dir_recursive_absolute(out)
	var rows:=[]
	for distance:float in [3.4,22.0]:
		cam.size=distance
		for clip:String in ["Idle","Walk","Jog_Fwd","Sprint","Sword_Attack","Hit_Chest","Death01"]:
			player.play(clip);player.seek(player.get_animation(clip).length*.45,true);player.advance(0.)
			await RenderingServer.frame_post_draw
			await RenderingServer.frame_post_draw
			var picture:=root.get_texture().get_image()
			if picture.get_size()!=root.size or not is_equal_approx(root.scaling_3d_scale,1.):quit(2);return
			var name:="%s-%s.png"%[str(distance),clip]
			if picture.save_png(out+"/"+name)!=OK:quit(3);return
			rows.append({"file":name,"pixels":[picture.get_width(),picture.get_height()],"internal_scale":root.scaling_3d_scale,"camera_size":distance,"clip":clip,"clip_time":player.get_animation(clip).length*.45,"source_sha":OS.get_environment("UBC_SOURCE_SHA"),"device":RenderingServer.get_video_adapter_name(),"renderer":RenderingServer.get_current_rendering_method(),"bones":skeleton.get_bone_count(),"battle":false,"art_acceptance":"NOT_ACCEPTED_SOURCE_RIG_LAB"})
	var file:=FileAccess.open(out+"/frames.json",FileAccess.WRITE);file.store_string(JSON.stringify(rows,"  "));file.close()
	print("UBC_NATIVE_STILLS_PASS ",rows.size())
	quit()
