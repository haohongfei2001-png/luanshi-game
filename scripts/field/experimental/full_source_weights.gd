extends RefCounted
## Exact source-ID mapping, not geometric nearest-neighbour reconstruction.
## Source UV0 stays unchanged; a separate, previously unused UV2 stores IDs.
static func recover(instance:MeshInstance3D, sidecar:Dictionary) -> Dictionary:
	if sidecar.get("format")!="mh-full-influences-v2" or instance.skin==null:
		return {"error":"unsupported source schema or missing intact skin"}
	var part:Dictionary={}
	for candidate:Dictionary in sidecar.parts:
		if candidate.node==String(instance.name):
			if not part.is_empty():return {"error":"ambiguous source part name"}
			part=candidate
	if part.is_empty():return {"error":"source part not found","node":String(instance.name)}
	var by_name:Dictionary={}
	for bind in instance.skin.get_bind_count():
		var name:=String(instance.skin.get_bind_name(bind))
		if name.is_empty() or by_name.has(name):return {"error":"ambiguous or unnamed native skin bind"}
		by_name[name]=bind
	var surfaces:=[];var total:=0;var more_than_eight:=0;var maximum:=0
	for surface in instance.mesh.get_surface_count():
		var arrays:=instance.mesh.surface_get_arrays(surface)
		var positions:PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
		if arrays[Mesh.ARRAY_TEX_UV2]==null:return {"error":"missing explicit source ID channel"}
		var ids:PackedVector2Array=arrays[Mesh.ARRAY_TEX_UV2]
		if ids.size()!=positions.size():return {"error":"source ID cardinality mismatch"}
		var sources:=[];var slots:=0
		for index in positions.size():
			var low:=roundi(ids[index].x);var high:=roundi(ids[index].y)
			if low<0 or low>255 or high<0 or high>255 or absf(ids[index].x-low)>.001 or absf(ids[index].y-high)>.001:
				return {"error":"non-exact source ID"}
			var id:=low+256*high
			if id>=part.vertices.size():return {"error":"source ID outside original mesh"}
			var source:Dictionary=part.vertices[id]
			if int(source.id)!=id:return {"error":"sidecar index identity mismatch"}
			var p:Array=source.position
			if positions[index].distance_to(Vector3(p[0],p[2],-p[1]))>.00002:
				return {"error":"source ID maps to different rest position","node":String(instance.name),"id":id}
			slots=maxi(slots,source.weights.size());sources.append(source)
			if source.weights.size()>8:more_than_eight+=1
			maximum=maxi(maximum,source.weights.size());total+=1
		if slots<1 or slots>16:return {"error":"complete source influence count unsupported; not truncated"}
		var joints:=PackedInt32Array();var weights:=PackedFloat32Array()
		joints.resize(sources.size()*slots);weights.resize(sources.size()*slots)
		for vertex in sources.size():
			var seen:Dictionary={};var sum:=0.0
			var source:Dictionary=sources[vertex]
			if not source.has("raw_blender_weights") or source.raw_blender_weights.size()!=source.weights.size():return {"error":"missing full raw transfer provenance"}
			var raw_sum:=0.0
			for pair:Array in source.raw_blender_weights:raw_sum+=float(pair[1])
			if raw_sum<=0.0 or absf(raw_sum-float(source.raw_blender_weight_sum))>0.000001 or absf(raw_sum*float(source.runtime_normalization_factor)-1.0)>0.000001:return {"error":"invalid declared upstream normalization"}
			for slot in sources[vertex].weights.size():
				var influence:Array=sources[vertex].weights[slot]
				var name:String=influence[0];var weight:float=influence[1]
				if not by_name.has(name) or seen.has(name) or not is_finite(weight) or weight<0:
					return {"error":"invalid or unmapped full source influence","bone":name}
				var raw:Array=source.raw_blender_weights[slot]
				if String(raw[0])!=name or absf(float(raw[1])*float(source.runtime_normalization_factor)-weight)>0.000001:return {"error":"runtime weight changed beyond declared normalization"}
				seen[name]=true;sum+=weight
				joints[vertex*slots+slot]=by_name[name];weights[vertex*slots+slot]=weight
			if absf(sum-1.)>.0002:return {"error":"full source sum invalid; not normalized by adapter"}
		surfaces.append({"joints":joints,"weights":weights,"slots":slots})
	return {"surfaces":surfaces,"vertices":total,"more_than_eight":more_than_eight,"max_influences":maximum,"bone_name_mapping":by_name,"renormalized_in_adapter":false,"upstream_runtime_normalization":"explicit sidecar v2 factor; raw transferred groups retained"}
