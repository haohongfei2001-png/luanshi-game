extends SceneTree
const Palette = preload("res://scripts/field/experimental/native_rig_palette.gd")
var checks := 0
var failures: Array[String] = []

func expect(value: bool, message: String) -> void:
	checks+=1
	if not value: failures.append(message)

func triangle(eight: bool) -> ArrayMesh:
	var a := []
	a.resize(Mesh.ARRAY_MAX)
	a[Mesh.ARRAY_VERTEX]=PackedVector3Array([Vector3(0.2,0.3,0.4),Vector3(1.1,0.2,0.3),Vector3(0.1,1.2,0.3)])
	a[Mesh.ARRAY_NORMAL]=PackedVector3Array([Vector3.UP,Vector3.UP,Vector3.UP])
	a[Mesh.ARRAY_TEX_UV]=PackedVector2Array([Vector2.ZERO,Vector2.RIGHT,Vector2.UP])
	a[Mesh.ARRAY_BONES]=PackedInt32Array()
	a[Mesh.ARRAY_WEIGHTS]=PackedFloat32Array()
	var ids := [0,17,255,299,2,7,141,291] if eight else [0,17,255,299]
	var weights := [.25,.125,.125,.125,.125,.125,.0625,.0625] if eight else [.5,.25,.125,.125]
	for vertex in 3:
		a[Mesh.ARRAY_BONES].append_array(PackedInt32Array(ids))
		a[Mesh.ARRAY_WEIGHTS].append_array(PackedFloat32Array(weights))
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,a,[],{},Mesh.ARRAY_FLAG_USE_8_BONE_WEIGHTS if eight else 0)
	mesh.surface_set_name(0,"authored uv and weights")
	mesh.surface_set_material(0,StandardMaterial3D.new())
	return mesh

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var skeleton := Skeleton3D.new()
	root.add_child(skeleton)
	for i in 300:
		skeleton.add_bone("author_joint_"+str(i))
		if i>0: skeleton.set_bone_parent(i,0)
		skeleton.set_bone_rest(i,Transform3D(Basis.IDENTITY,Vector3(i*.001,.1,0)))
	skeleton.reset_bone_poses()
	var skin := Skin.new()
	# Reverse bind order tests the subtle, easily missed Skin != Skeleton index.
	for i in 300:
		var bone := 299-i
		skin.add_named_bind(skeleton.get_bone_name(bone),skeleton.get_bone_global_rest(bone).affine_inverse())
	var rest := Palette.capture(skeleton,skin)
	expect(not rest.has("error"),"capture 300 named inverse binds")
	for pose: Transform3D in rest.transforms:
		expect(pose.is_equal_approx(Transform3D.IDENTITY),"rest bind cancellation")
	skeleton.set_bone_pose_position(0,Vector3(.2,.8,-.1))
	skeleton.set_bone_pose_rotation(299,Quaternion(Vector3.UP,.43))
	skeleton.set_bone_pose_scale(299,Vector3(1.1,.95,1.2))
	var actual := Palette.capture(skeleton,skin)
	expect(not actual.has("error"),"preserve hierarchical translation rotation scale")
	var bank := Palette.encode([rest.transforms,actual.transforms])
	expect(not bank.has("error"),"float palette built")
	expect(bank.binds==300 and bank.image.get_size()==Vector2i(1800,2),"not truncated to 16 or 256 bones")
	expect(bank.bytes==300*6*4*4*2,"precise palette memory")
	for row in 2:
		for bone in 300:
			var reconstructed: Transform3D = Palette.unpack(bank.image,bone,row)
			var original: Transform3D = [rest.transforms,actual.transforms][row][bone]
			expect((reconstructed*Vector3(.7,.2,-.3)).distance_to(original*Vector3(.7,.2,-.3))<.000002,"float matrix reconstruction")
	for eight in [false,true]:
		var source := triangle(eight)
		var packed := Palette.pack_mesh(source,300)
		expect(not packed.has("error"),"4/8 influences pack")
		if packed.has("error"): continue
		var before := source.surface_get_arrays(0)
		var after: Array = packed.mesh.surface_get_arrays(0)
		expect(after[Mesh.ARRAY_VERTEX]==before[Mesh.ARRAY_VERTEX],"vertex anatomy unchanged")
		expect(after[Mesh.ARRAY_TEX_UV]==before[Mesh.ARRAY_TEX_UV],"UV unchanged")
		expect(source.surface_get_material(0)==packed.mesh.surface_get_material(0),"source material retained")
		expect(after[Mesh.ARRAY_BONES]==null or after[Mesh.ARRAY_BONES].is_empty(),"no double engine skinning")
		expect(packed.max_influences==(8 if eight else 4),"all weights retained")
		var joints_a: PackedFloat32Array = after[Mesh.ARRAY_CUSTOM0]
		var weights_a: PackedFloat32Array = after[Mesh.ARRAY_CUSTOM1]
		var joints_b: PackedFloat32Array = after[Mesh.ARRAY_CUSTOM2]
		var weights_b: PackedFloat32Array = after[Mesh.ARRAY_CUSTOM3]
		for vertex in 3:
			var expected := Vector3.ZERO
			var computed := Vector3.ZERO
			for influence in (8 if eight else 4):
				var old_idx: int = vertex*(8 if eight else 4)+influence
				var joint: int = before[Mesh.ARRAY_BONES][old_idx]
				var weight: float = before[Mesh.ARRAY_WEIGHTS][old_idx]
				var offset := vertex*4+influence%4
				var new_joint := int(joints_a[offset] if influence<4 else joints_b[offset])
				var new_weight: float = weights_a[offset] if influence<4 else weights_b[offset]
				expect(joint==new_joint and weight==new_weight,"no weights normalized dropped or reordered")
				expected+=(actual.transforms[joint]*before[Mesh.ARRAY_VERTEX][vertex])*weight
				computed+=(Palette.unpack(bank.image,new_joint,1)*after[Mesh.ARRAY_VERTEX][vertex])*new_weight
				expect(computed.distance_to(expected)<.000002,"full authored weighted pose preserved")
		expect(Palette.pack_mesh(source,16).has("error"),"too few palette bones cannot silently clamp")
	var unknown := Skin.new()
	unknown.add_named_bind("not_present",Transform3D.IDENTITY)
	expect(Palette.capture(skeleton,unknown).has("error"),"missing source joint rejected")
	expect(Palette.encode([]).has("error"),"empty bank rejected")
	expect(Palette.encode([actual.transforms],1024).has("error"),"texture capacity checked")
	var shaped := triangle(false)
	# Explicit empty source with blend shapes still must fail before geometry.
	shaped=ArrayMesh.new()
	shaped.add_blend_shape("FaceExpression")
	expect(Palette.pack_mesh(shaped,300).has("error"),"face expressions not silently discarded")
	print("NATIVE_RIG_PALETTE "+JSON.stringify({"checks":checks,"failures":failures,"bones":300,"max_weights":8,"game_enabled":false,"visual_pass":false,"gpu_parity":"NOT_RUN"}))
	skeleton.queue_free()
	quit(0 if failures.is_empty() else 1)
