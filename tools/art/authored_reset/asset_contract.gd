extends RefCounted
## Production asset admission. Never substitutes a primitive or a rejected asset.
static func inspect(node:Node3D) -> Dictionary:
	var meshes:=0;var surfaces:=0;var triangles:=0;var uv_surfaces:=0;var lod_surfaces:=0
	var bounds:=AABB();var first:=true
	var candidates:Array[Node]=node.find_children("*","MeshInstance3D",true,false)
	if node is MeshInstance3D:candidates.append(node)
	for candidate:Node in candidates:
		var mesh_node:=candidate as MeshInstance3D
		if not mesh_node.mesh:continue
		var transform:=Transform3D.IDENTITY if mesh_node==node else mesh_node.transform
		var parent:=mesh_node.get_parent()
		while mesh_node!=node and parent and parent!=node:
			if parent is Node3D:transform=(parent as Node3D).transform*transform
			parent=parent.get_parent()
		var box:=transform*mesh_node.mesh.get_aabb()
		bounds=box if first else bounds.merge(box);first=false;meshes+=1
		for s:int in mesh_node.mesh.get_surface_count():
			surfaces+=1
			var arrays:=mesh_node.mesh.surface_get_arrays(s)
			var indices:PackedInt32Array=arrays[Mesh.ARRAY_INDEX]
			var vertices:PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
			triangles+=int((indices.size() if not indices.is_empty() else vertices.size())/3)
			if arrays[Mesh.ARRAY_TEX_UV]!=null and arrays[Mesh.ARRAY_TEX_UV].size()==vertices.size():uv_surfaces+=1
			if mesh_node.mesh is ArrayMesh:
				var info:Dictionary=RenderingServer.mesh_get_surface(mesh_node.mesh.get_rid(),s)
				if not info.get("lods",[]).is_empty():lod_surfaces+=1
	return {"mesh_nodes":meshes,"surfaces":surfaces,"base_triangles":triangles,"uv_surfaces":uv_surfaces,"lod_surfaces":lod_surfaces,"bounds":bounds}

static func load_verified(entry:Dictionary) -> Dictionary:
	for field:String in ["source","sha256","license_evidence","metres_per_unit","triangle_budget","surface_budget"]:
		if not entry.has(field):return {"ok":false,"reason":"MISSING_"+field}
	var path:String=entry.source
	if "river_pass/nature" in path or "river_gate/world/architecture" in path:
		return {"ok":false,"reason":"REJECTED_FOUNDATION_REQUIRES_NEW_REVIEW"}
	if not FileAccess.file_exists(path):return {"ok":false,"reason":"SOURCE_NOT_AVAILABLE"}
	if FileAccess.get_sha256(path)!=entry.sha256:return {"ok":false,"reason":"SOURCE_HASH_MISMATCH"}
	if not FileAccess.file_exists(entry.license_evidence):return {"ok":false,"reason":"LICENSE_EVIDENCE_MISSING"}
	if float(entry.metres_per_unit)<=0:return {"ok":false,"reason":"INVALID_UNIT_SCALE"}
	var packed:=load(path) as PackedScene
	if not packed:return {"ok":false,"reason":"NOT_PACKED_SCENE"}
	var instance:=packed.instantiate()
	if not instance is Node3D:
		instance.free();return {"ok":false,"reason":"NOT_3D"}
	var node:=instance as Node3D
	var audit:=inspect(node)
	if audit.base_triangles>int(entry.triangle_budget) or audit.surfaces>int(entry.surface_budget):
		node.free();return {"ok":false,"reason":"BUDGET_EXCEEDED","audit":audit}
	# Parent transform only: no mesh rebuilding, normal rewriting, UV baking,
	# material flattening or forced LOD. Source editable structure is retained.
	var wrapper:=Node3D.new();wrapper.name="VerifiedAsset";wrapper.add_child(node)
	node.scale*=float(entry.metres_per_unit)
	wrapper.set_meta("source_sha256",entry.sha256)
	return {"ok":true,"node":wrapper,"audit":audit,"visual_acceptance":"NOT_REVIEWED"}
