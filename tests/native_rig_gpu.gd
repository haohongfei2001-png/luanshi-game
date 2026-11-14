extends SceneTree
## GPU parity fixture, NOT an artwork preview. Two real isolated viewports use
## identical input geometry/poses/camera: native Skin vs full-weight palette.
const Palette = preload("res://scripts/field/experimental/native_rig_palette.gd")
const SHADER = preload("res://scripts/field/experimental/native_rig_palette.gdshader")
var reports: Array = []
var failed := false

func _initialize() -> void:
	call_deferred("run")

func source_mesh() -> ArrayMesh:
	var s := SphereMesh.new()
	s.radius=.65
	s.height=1.4
	s.radial_segments=24
	s.rings=16
	var arrays := s.get_mesh_arrays()
	var bones := PackedInt32Array()
	var weights := PackedFloat32Array()
	for v: Vector3 in arrays[Mesh.ARRAY_VERTEX]:
		bones.append_array(PackedInt32Array([0,17,255,299,2,7,141,291]))
		var upper := clampf((v.y+.7)/1.4,0.0,1.0)
		weights.append_array(PackedFloat32Array([.25,.125,.125,.125,.125,.125,.0625*upper,.0625+.0625*(1.0-upper)]))
	arrays[Mesh.ARRAY_BONES]=bones
	arrays[Mesh.ARRAY_WEIGHTS]=weights
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays,[],{},Mesh.ARRAY_FLAG_USE_8_BONE_WEIGHTS)
	return mesh

func view() -> SubViewport:
	var viewport := SubViewport.new()
	viewport.size=Vector2i(512,512)
	viewport.own_world_3d=true
	viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	viewport.msaa_3d=Viewport.MSAA_4X
	root.add_child(viewport)
	var environment := WorldEnvironment.new()
	environment.environment=Environment.new()
	environment.environment.background_mode=Environment.BG_COLOR
	environment.environment.background_color=Color(.035,.045,.055)
	environment.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color=Color.WHITE
	environment.environment.ambient_light_energy=.45
	viewport.add_child(environment)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees=Vector3(-35,-25,0)
	viewport.add_child(sun)
	var camera := Camera3D.new()
	camera.projection=Camera3D.PROJECTION_ORTHOGONAL
	camera.size=3.0
	camera.position=Vector3(0,0,4)
	camera.current=true
	viewport.add_child(camera)
	return viewport

func run() -> void:
	var folder := "res://artifacts/native-rig-gpu"
	DirAccess.make_dir_recursive_absolute(folder)
	var native_view := view()
	var palette_view := view()
	var skeleton := Skeleton3D.new()
	native_view.add_child(skeleton)
	for i in 300:
		skeleton.add_bone("author_"+str(i))
		if i>0: skeleton.set_bone_parent(i,0)
		skeleton.set_bone_rest(i,Transform3D(Basis.IDENTITY,Vector3(i*.001,0,0)))
	skeleton.reset_bone_poses()
	var skin := Skin.new()
	for bind in 300:
		var bone := 299-bind
		skin.add_named_bind(skeleton.get_bone_name(bone),skeleton.get_bone_global_rest(bone).affine_inverse())
	var native := MeshInstance3D.new()
	native.mesh=source_mesh()
	native.skin=skin
	native.skeleton=NodePath("..")
	var material := StandardMaterial3D.new()
	material.albedo_color=Color(.33,.55,.72)
	material.specular_mode=BaseMaterial3D.SPECULAR_DISABLED
	material.diffuse_mode=BaseMaterial3D.DIFFUSE_LAMBERT
	material.roughness=.85
	native.material_override=material
	skeleton.add_child(native)
	var packed := Palette.pack_mesh(native.mesh,skin.get_bind_count())
	if packed.has("error"):
		push_error(str(packed))
		quit(1)
		return
	var instance := MultiMeshInstance3D.new()
	instance.multimesh=MultiMesh.new()
	instance.multimesh.transform_format=MultiMesh.TRANSFORM_3D
	instance.multimesh.use_custom_data=true
	instance.multimesh.mesh=packed.mesh
	instance.multimesh.instance_count=1
	instance.multimesh.set_instance_transform(0,Transform3D.IDENTITY)
	instance.multimesh.set_instance_custom_data(0,Color(0,0,0,0))
	instance.multimesh.custom_aabb=AABB(Vector3(-2,-2,-2),Vector3(4,4,4))
	var custom := ShaderMaterial.new()
	custom.shader=SHADER
	custom.set_shader_parameter("albedo",material.albedo_color)
	instance.material_override=custom
	palette_view.add_child(instance)
	for stage in ["rest","rotated","scaled","eight_weight_tail"]:
		skeleton.reset_bone_poses()
		if stage!="rest":
			skeleton.set_bone_pose_rotation(299,Quaternion(Vector3.FORWARD,.42))
			skeleton.set_bone_pose_rotation(282,Quaternion(Vector3.UP,-.27))
			skeleton.set_bone_pose_position(0,Vector3(.1,-.08,0))
		if stage=="scaled":
			skeleton.set_bone_pose_scale(299,Vector3(1.15,.85,1.05))
		if stage=="eight_weight_tail":
			skeleton.set_bone_pose_rotation(8,Quaternion(Vector3.RIGHT,.8))
			skeleton.set_bone_pose_position(158,Vector3(-.35,.1,0))
		var capture := Palette.capture(skeleton,skin)
		var bank := Palette.encode([capture.transforms])
		custom.set_shader_parameter("palette",ImageTexture.create_from_image(bank.image))
		for frame in 4: await process_frame
		await RenderingServer.frame_post_draw
		var a := native_view.get_texture().get_image()
		var b := palette_view.get_texture().get_image()
		a.save_png(folder+"/"+stage+"-native.png")
		b.save_png(folder+"/"+stage+"-palette.png")
		var total_error := 0.0
		var max_error := 0.0
		var visible := 0
		var mismatched := 0
		var background := a.get_pixel(0,0)
		for y in a.get_height():
			for x in a.get_width():
				var p := a.get_pixel(x,y)
				var q := b.get_pixel(x,y)
				var error := maxf(absf(p.r-q.r),maxf(absf(p.g-q.g),absf(p.b-q.b)))
				total_error+=error
				max_error=maxf(max_error,error)
				if p!=background or q!=background: visible+=1
				if error>2.0/255.0: mismatched+=1
		var row := {"stage":stage,"mae":total_error/(512*512),"max":max_error,"visible":visible,"pixels_over_2_levels":mismatched,"native_size":[512,512],"internal":1.0}
		row["pass"]=visible>20000 and total_error/(512*512)<.001 and mismatched<visible*.02
		if not row["pass"]: failed=true
		reports.append(row)
		print("NATIVE_RIG_GPU "+JSON.stringify(row))
	var f := FileAccess.open(folder+"/parity.json",FileAccess.WRITE)
	f.store_string(JSON.stringify({"reports":reports,"renderer":RenderingServer.get_video_adapter_name(),"source":OS.get_environment("GITHUB_SHA"),"art_pass":false,"game_enabled":false},"  "))
	f.close()
	quit(1 if failed else 0)
