extends RefCounted
## Opt-in bridge for intact imported rigs. Never remaps an author rig to 16 bones
## or discards low-ranked weights. Not connected to the shipping presentation.

static func capture(skeleton: Skeleton3D, skin: Skin) -> Dictionary:
	if skeleton == null or skin == null or skin.get_bind_count() == 0:
		return {"error":"missing skeleton or skin"}
	var transforms: Array[Transform3D] = []
	for bind in skin.get_bind_count():
		var name := skin.get_bind_name(bind)
		var bone := skeleton.find_bone(name) if not name.is_empty() else skin.get_bind_bone(bind)
		if bone < 0 or bone >= skeleton.get_bone_count():
			return {"error":"unresolved bind", "bind":bind, "name":name}
		# Exact Godot 4.6 Skeleton3D skin transform; bind order is NOT bone order.
		var pose := skeleton.get_bone_global_pose(bone) * skin.get_bind_pose(bind)
		if not pose.is_finite() or absf(pose.basis.determinant()) < 0.000001:
			return {"error":"nonfinite or singular skin pose", "bind":bind}
		transforms.append(pose)
	return {"transforms":transforms}

static func encode(frames: Array, max_texture_size: int = 8192) -> Dictionary:
	if frames.is_empty() or frames[0].is_empty():
		return {"error":"empty palette"}
	var binds: int = frames[0].size()
	# Six RGBA float texels per bind: affine rows plus normal-transform rows.
	# Linear float matrices keep authored scale/shear, unlike quaternion-only rigs.
	if binds * 6 > max_texture_size or frames.size() > max_texture_size:
		return {"error":"palette exceeds explicit texture limit"}
	var data := PackedFloat32Array()
	for frame: Array in frames:
		if frame.size() != binds:
			return {"error":"unequal bind counts"}
		for pose: Transform3D in frame:
			if not pose.is_finite() or absf(pose.basis.determinant()) < 0.000001:
				return {"error":"invalid palette pose"}
			for row in 3:
				data.append_array(PackedFloat32Array([pose.basis.x[row],pose.basis.y[row],pose.basis.z[row],pose.origin[row]]))
			# Match engine CPU bake's normal convention. The real GPU A/B must
			# separately establish the shader's result for authored scaled bones.
			var normal_basis := pose.basis.orthonormalized()
			for row in 3:
				data.append_array(PackedFloat32Array([normal_basis.x[row],normal_basis.y[row],normal_basis.z[row],0.0]))
	return {"image":Image.create_from_data(binds*6,frames.size(),false,Image.FORMAT_RGBAF,data.to_byte_array()),
		"binds":binds,"frames":frames.size(),"bytes":data.size()*4}

static func unpack(image: Image, bind: int, frame: int) -> Transform3D:
	var a := image.get_pixel(bind*6,frame)
	var b := image.get_pixel(bind*6+1,frame)
	var c := image.get_pixel(bind*6+2,frame)
	return Transform3D(Basis(Vector3(a.r,b.r,c.r),Vector3(a.g,b.g,c.g),Vector3(a.b,b.b,c.b)),Vector3(a.a,b.a,c.a))

static func pack_mesh(source: ArrayMesh, bind_count: int) -> Dictionary:
	if source == null or bind_count < 1:
		return {"error":"missing mesh or binds"}
	# MultiMesh cannot represent per-instance blend shapes. Require explicit,
	# separately retained neutral-expression bake, never silently drop a face rig.
	if source.get_blend_shape_count() > 0:
		return {"error":"blend shapes require explicit expression bake"}
	var result := ArrayMesh.new()
	var vertices := 0
	var max_influences := 0
	for surface in source.get_surface_count():
		var a := source.surface_get_arrays(surface)
		var count: int = a[Mesh.ARRAY_VERTEX].size()
		var bones: PackedInt32Array = a[Mesh.ARRAY_BONES] if a[Mesh.ARRAY_BONES] != null else PackedInt32Array()
		var weights: PackedFloat32Array = a[Mesh.ARRAY_WEIGHTS] if a[Mesh.ARRAY_WEIGHTS] != null else PackedFloat32Array()
		if count < 1 or bones.size() != weights.size() or bones.size() not in [count*4,count*8]:
			return {"error":"expected complete 4 or 8 influence skin", "surface":surface}
		for channel in [Mesh.ARRAY_CUSTOM0,Mesh.ARRAY_CUSTOM1,Mesh.ARRAY_CUSTOM2,Mesh.ARRAY_CUSTOM3]:
			if a[channel] != null and not a[channel].is_empty():
				return {"error":"custom channel collision", "surface":surface}
		var per_vertex := bones.size()/count
		var channels: Array[PackedFloat32Array] = []
		for channel in 4:
			channels.append(PackedFloat32Array())
		for vertex in count:
			var weight_sum := 0.0
			var nonzero := 0
			for influence in 8:
				var joint := 0
				var weight := 0.0
				if influence < per_vertex:
					joint=bones[vertex*per_vertex+influence]
					weight=weights[vertex*per_vertex+influence]
				if not is_finite(weight) or weight < 0.0 or joint < 0 or joint >= bind_count:
					return {"error":"invalid joint or weight", "vertex":vertex,"surface":surface}
				if weight > 0.0:
					nonzero+=1
				weight_sum+=weight
				var block := 0 if influence < 4 else 2
				channels[block].append(float(joint))
				channels[block+1].append(weight)
			# Godot stores skin weights as UNORM16. Allow its quantization error,
			# but do not renormalize/truncate authored influences in this adapter.
			if absf(weight_sum-1.0)>0.0002:
				return {"error":"unnormalized source weights", "sum":weight_sum,"vertex":vertex}
			max_influences=maxi(max_influences,nonzero)
		for channel in 4:
			a[Mesh.ARRAY_CUSTOM0+channel]=channels[channel]
		a[Mesh.ARRAY_BONES]=null
		a[Mesh.ARRAY_WEIGHTS]=null
		var flags := 0
		for shift in [Mesh.ARRAY_FORMAT_CUSTOM0_SHIFT,Mesh.ARRAY_FORMAT_CUSTOM1_SHIFT,Mesh.ARRAY_FORMAT_CUSTOM2_SHIFT,Mesh.ARRAY_FORMAT_CUSTOM3_SHIFT]:
			flags |= Mesh.ARRAY_CUSTOM_RGBA_FLOAT << shift
		result.add_surface_from_arrays(source.surface_get_primitive_type(surface),a,[],{},flags)
		if result.get_surface_count() != surface+1:
			return {"error":"engine rejected packed surface", "surface":surface}
		result.surface_set_material(surface,source.surface_get_material(surface))
		result.surface_set_name(surface,source.surface_get_name(surface))
		vertices+=count
	return {"mesh":result,"vertices":vertices,"max_influences":max_influences,"binds":bind_count}
