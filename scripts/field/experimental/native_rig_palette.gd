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
	# Three RGBA float texels per bind: complete affine rows.
	# Linear float matrices keep authored scale/shear, unlike quaternion-only rigs.
	if binds * 3 > max_texture_size or frames.size() > max_texture_size:
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

	return {"image":Image.create_from_data(binds*3,frames.size(),false,Image.FORMAT_RGBAF,data.to_byte_array()),
		"binds":binds,"frames":frames.size(),"bytes":data.size()*4}

static func unpack(image: Image, bind: int, frame: int) -> Transform3D:
	var a := image.get_pixel(bind*3,frame)
	var b := image.get_pixel(bind*3+1,frame)
	var c := image.get_pixel(bind*3+2,frame)
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
	var lod_count := 0
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
		# Keep the imported mesh's existing LOD index buffers. The vertices and
		# UVs are unchanged; discarding these buffers silently makes a native
		# character substantially more expensive at the actual 22 m camera.
		var raw := RenderingServer.mesh_get_surface(source.get_rid(),surface)
		var stride := RenderingServer.mesh_surface_get_format_index_stride(raw.format,count)
		var lods := {}
		for lod: Dictionary in raw.get("lods",[]):
			var bytes: PackedByteArray = lod.index_data
			if stride not in [2,4] or bytes.size()%stride != 0:
				return {"error":"unsupported source LOD index encoding","surface":surface}
			var indices := PackedInt32Array()
			for offset in range(0,bytes.size(),stride):
				indices.append(bytes.decode_u16(offset) if stride==2 else bytes.decode_u32(offset))
			lods[lod.edge_length]=indices
			lod_count+=1
		result.add_surface_from_arrays(source.surface_get_primitive_type(surface),a,[],lods,flags)
		if result.get_surface_count() != surface+1:
			return {"error":"engine rejected packed surface", "surface":surface}
		result.surface_set_material(surface,source.surface_get_material(surface))
		result.surface_set_name(surface,source.surface_get_name(surface))
		vertices+=count
	return {"mesh":result,"vertices":vertices,"max_influences":max_influences,"binds":bind_count,"source_lods":lod_count}

## A separate static weight texture avoids consuming an author's extra UV/custom
## channels. Explicit extra source weights may exceed Godot Skin's eight-slot
## importer limit. Callers MUST supply the exact rendered-vertex mapping; this
## adapter never guesses it from nearest positions or truncates tail influences.
static func pack_textured_mesh(source: ArrayMesh, bind_count: int, full_source: Array = []) -> Dictionary:
	if source==null or bind_count<1 or source.get_blend_shape_count()>0:
		return {"error":"missing mesh/binds or unbaked expression rig"}
	if not full_source.is_empty() and full_source.size()!=source.get_surface_count():
		return {"error":"explicit full-weight surface count mismatch"}
	var mesh:=ArrayMesh.new()
	var tables:=[]
	var lod_count:=0
	for surface in source.get_surface_count():
		var arrays:=source.surface_get_arrays(surface)
		var count:int=arrays[Mesh.ARRAY_VERTEX].size()
		var joints:PackedInt32Array=arrays[Mesh.ARRAY_BONES] if arrays[Mesh.ARRAY_BONES]!=null else PackedInt32Array()
		var weights:PackedFloat32Array=arrays[Mesh.ARRAY_WEIGHTS] if arrays[Mesh.ARRAY_WEIGHTS]!=null else PackedFloat32Array()
		if not full_source.is_empty():
			joints=full_source[surface].joints
			weights=full_source[surface].weights
		if count<1 or joints.size()!=weights.size() or joints.size()%count!=0:
			return {"error":"exact per-vertex source weights required"}
		var slots:int=joints.size()/count
		if slots<1 or slots>16:
			return {"error":"explicit sixteen-influence limit exceeded; source not truncated"}
		var groups:int=ceili(slots/4.0)
		var texels:int=count*groups*2
		var width:=mini(2048,texels)
		var height:=ceili(float(texels)/width)
		if height>8192:return {"error":"static weight texture exceeds size limit"}
		var pixels:=PackedFloat32Array();pixels.resize(width*height*4)
		for vertex in count:
			var sum:=0.0
			for slot in slots:
				var index:=vertex*slots+slot
				var weight:=weights[index]
				if not is_finite(weight) or weight<0.0 or joints[index]<0 or joints[index]>=bind_count:
					return {"error":"invalid unmodified source weight or bind"}
				sum+=weight
				var offset:int=(vertex*groups*2+int(slot/4)*2)*4+slot%4
				pixels[offset]=float(joints[index]);pixels[offset+4]=weight
			if absf(sum-1.0)>0.0002:return {"error":"unnormalized complete source weights","sum":sum}
		var image:=Image.create_from_data(width,height,false,Image.FORMAT_RGBAF,pixels.to_byte_array())
		tables.append({"image":image,"influences":slots,"groups":groups,"vertices":count,"full_source_supplied":not full_source.is_empty()})
		arrays[Mesh.ARRAY_BONES]=null;arrays[Mesh.ARRAY_WEIGHTS]=null
		var flags:=0
		for shift in [Mesh.ARRAY_FORMAT_CUSTOM0_SHIFT,Mesh.ARRAY_FORMAT_CUSTOM1_SHIFT,Mesh.ARRAY_FORMAT_CUSTOM2_SHIFT,Mesh.ARRAY_FORMAT_CUSTOM3_SHIFT]:
			flags|=source.surface_get_format(surface)&(Mesh.ARRAY_FORMAT_CUSTOM_MASK<<shift)
		var raw:=RenderingServer.mesh_get_surface(source.get_rid(),surface)
		var stride:=RenderingServer.mesh_surface_get_format_index_stride(raw.format,count)
		var lods:Dictionary={}
		for lod:Dictionary in raw.get("lods",[]):
			var bytes:PackedByteArray=lod.index_data
			if stride not in [2,4] or bytes.size()%stride!=0:return {"error":"unsupported source LOD encoding"}
			var indices:=PackedInt32Array()
			for offset in range(0,bytes.size(),stride):indices.append(bytes.decode_u16(offset) if stride==2 else bytes.decode_u32(offset))
			lods[lod.edge_length]=indices;lod_count+=1
		mesh.add_surface_from_arrays(source.surface_get_primitive_type(surface),arrays,[],lods,flags)
		mesh.surface_set_material(surface,source.surface_get_material(surface))
		mesh.surface_set_name(surface,source.surface_get_name(surface))
	return {"mesh":mesh,"tables":tables,"source_lods":lod_count,"shadow_mesh_optimization_preserved":false}

static func unpack_weight(table:Dictionary, vertex:int, slot:int) -> Vector2:
	var index:int=vertex*table.groups*2+int(slot/4)*2
	var joints:Color=table.image.get_pixel(index%table.image.get_width(),index/table.image.get_width())
	var weight_index:=index+1
	var weights:Color=table.image.get_pixel(weight_index%table.image.get_width(),weight_index/table.image.get_width())
	return Vector2(joints[slot%4],weights[slot%4])
