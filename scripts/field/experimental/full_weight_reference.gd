extends RefCounted
## Slow diagnostic oracle, not a production renderer. Uses every supplied source
## influence. Native Skin's imported eight slots are not a complete-weight oracle.
static func deform(source:ArrayMesh, full_source:Array, transforms:Array) -> Dictionary:
	if source==null or source.get_blend_shape_count()>0 or transforms.is_empty():
		return {"error":"missing source or unbaked expression shapes"}
	if full_source.size()!=source.get_surface_count():return {"error":"source surface mismatch"}
	for transform:Transform3D in transforms:
		if not transform.is_finite():return {"error":"nonfinite bind matrix"}
	var mesh:=ArrayMesh.new();var count_total:=0;var tail_vertices:=0;var lod_count:=0
	for surface in source.get_surface_count():
		var arrays:=source.surface_get_arrays(surface)
		var original:PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
		var normals:PackedVector3Array=arrays[Mesh.ARRAY_NORMAL] if arrays[Mesh.ARRAY_NORMAL]!=null else PackedVector3Array()
		var tangents:PackedFloat32Array=arrays[Mesh.ARRAY_TANGENT] if arrays[Mesh.ARRAY_TANGENT]!=null else PackedFloat32Array()
		var weights:PackedFloat32Array=full_source[surface].weights
		var joints:PackedInt32Array=full_source[surface].joints
		var count:=original.size()
		if count<1 or weights.size()!=joints.size() or weights.size()%count!=0:return {"error":"weight cardinality mismatch"}
		var slots:int=weights.size()/count
		if slots<1 or slots>16:return {"error":"sixteen source influence limit exceeded; not truncated"}
		if normals.size() not in [0,count] or tangents.size() not in [0,count*4]:return {"error":"native direction cardinality mismatch"}
		var vertices:=PackedVector3Array();vertices.resize(count)
		var posed_normals:=PackedVector3Array();posed_normals.resize(normals.size())
		var posed_tangents:=tangents.duplicate()
		for vertex in count:
			var p:=Vector3.ZERO;var n:=Vector3.ZERO;var t:=Vector3.ZERO;var sum:=0.;var positive:=0
			var source_tangent:=Vector3.ZERO
			if not tangents.is_empty():source_tangent=Vector3(tangents[vertex*4],tangents[vertex*4+1],tangents[vertex*4+2])
			for slot in slots:
				var offset:=vertex*slots+slot;var weight:=weights[offset];var joint:=joints[offset]
				if not is_finite(weight) or weight<0 or joint<0 or joint>=transforms.size():return {"error":"invalid complete source weight or bind"}
				if weight==0:continue
				positive+=1;sum+=weight
				var bind:Transform3D=transforms[joint]
				p+=(bind*original[vertex])*weight
				if not normals.is_empty():n+=(bind.basis*normals[vertex])*weight
				if not tangents.is_empty():t+=(bind.basis*source_tangent)*weight
			if absf(sum-1.)>.0002:return {"error":"source weights not unit sum; not renormalized"}
			if not p.is_finite() or (not normals.is_empty() and n.length_squared()<1e-12) or (not tangents.is_empty() and t.length_squared()<1e-12):return {"error":"nonfinite vertex or degenerate blended direction"}
			vertices[vertex]=p
			if not normals.is_empty():posed_normals[vertex]=n.normalized()
			if not tangents.is_empty():
				t=t.normalized()
				posed_tangents[vertex*4]=t.x;posed_tangents[vertex*4+1]=t.y;posed_tangents[vertex*4+2]=t.z
			if positive>8:tail_vertices+=1
		arrays[Mesh.ARRAY_VERTEX]=vertices
		if not normals.is_empty():arrays[Mesh.ARRAY_NORMAL]=posed_normals
		if not tangents.is_empty():arrays[Mesh.ARRAY_TANGENT]=posed_tangents
		arrays[Mesh.ARRAY_BONES]=null;arrays[Mesh.ARRAY_WEIGHTS]=null
		var flags:=0
		for shift in [Mesh.ARRAY_FORMAT_CUSTOM0_SHIFT,Mesh.ARRAY_FORMAT_CUSTOM1_SHIFT,Mesh.ARRAY_FORMAT_CUSTOM2_SHIFT,Mesh.ARRAY_FORMAT_CUSTOM3_SHIFT]:
			flags|=source.surface_get_format(surface)&(Mesh.ARRAY_FORMAT_CUSTOM_MASK<<shift)
		var raw:=RenderingServer.mesh_get_surface(source.get_rid(),surface)
		var stride:=RenderingServer.mesh_surface_get_format_index_stride(raw.format,count)
		var lods:Dictionary={}
		for lod:Dictionary in raw.get("lods",[]):
			var bytes:PackedByteArray=lod.index_data
			if stride not in [2,4] or bytes.size()%stride!=0:return {"error":"unsupported native LOD encoding"}
			var indices:=PackedInt32Array()
			for offset in range(0,bytes.size(),stride):indices.append(bytes.decode_u16(offset) if stride==2 else bytes.decode_u32(offset))
			lods[lod.edge_length]=indices;lod_count+=1
		mesh.add_surface_from_arrays(source.surface_get_primitive_type(surface),arrays,[],lods,flags)
		if mesh.get_surface_count()!=surface+1:return {"error":"reference surface rejected by engine"}
		mesh.surface_set_name(surface,source.surface_get_name(surface))
		mesh.surface_set_material(surface,source.surface_get_material(surface))
		count_total+=count
	return {"mesh":mesh,"vertices":count_total,"more_than_eight":tail_vertices,"source_lods":lod_count,"source_weights_truncated":false,"source_weights_renormalized":false,"shadow_mesh_optimization_preserved":false}
