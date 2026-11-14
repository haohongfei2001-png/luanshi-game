extends SceneTree
## Exact ID/position/UV bridge only. Native Godot's8 weights are not full-source rendering.
func _initialize() -> void:call_deferred("run")
func run() -> void:
	var model_path := OS.get_environment("MH_STATIC_PATH")
	if model_path.is_empty(): model_path = "res://assets/mh_lab/mh_natural_fullweights.glb"
	var sidecar_path := OS.get_environment("MH_SIDECAR_PATH")
	if sidecar_path.is_empty(): sidecar_path = "res://assets/mh_lab/full-influences.json"
	var packed := load(model_path) as PackedScene
	if packed == null:
		push_error("MH source GLB not imported; run seed import first")
		quit(1)
		return
	var actor:Node3D=packed.instantiate();root.add_child(actor)
	var skeleton:Skeleton3D=actor.find_children("*","Skeleton3D",true,false)[0]
	var sidecar:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(sidecar_path))
	var by_name:Dictionary={}
	for part:Dictionary in sidecar.parts:by_name[part.node]=part
	var report:Dictionary={"model_path":model_path,"sidecar_path":sidecar_path,"bones":skeleton.get_bone_count(),"parts":[],"source_full_weights_preserved":true,"native8_is_full_weight_renderer":false,"visual_pass":false}
	assert(skeleton.get_bone_count()==163)
	for instance:MeshInstance3D in actor.find_children("*","MeshInstance3D",true,false):
		assert(by_name.has(instance.name),str(instance.name))
		var part:Dictionary=by_name[instance.name]
		var expected_uv:Dictionary={}
		var loop_index:=0
		var allowed_triangles:Dictionary={}
		var expected_triangles:=0
		for polygon:Array in part.polygons:
			expected_triangles+=polygon.size()-2
			for a:int in polygon.size():
				for b:int in range(a+1,polygon.size()):
					for c:int in range(b+1,polygon.size()):allowed_triangles[triangle_key([int(polygon[a]),int(polygon[b]),int(polygon[c])])]=true
			for id:int in polygon:
				if not expected_uv.has(id):expected_uv[id]=[]
				var uv:Array=part.loop_uv[loop_index];expected_uv[id].append(Vector2(uv[0],1.0-uv[1]));loop_index+=1
		var vertices_checked:=0;var high_influence_vertices:=0
		var triangles_checked:=0;var max_position_error:=0.0;var max_uv_error:=0.0
		for surface:int in instance.mesh.get_surface_count():
			var arrays:=instance.mesh.surface_get_arrays(surface)
			var positions:PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
			var ids:PackedVector2Array=arrays[Mesh.ARRAY_TEX_UV2]
			var uvs:PackedVector2Array=arrays[Mesh.ARRAY_TEX_UV]
			assert(ids.size()==positions.size())
			for i:int in positions.size():
				var low:=roundi(ids[i].x);var high:=roundi(ids[i].y)
				assert(low>=0 and low<=255 and high>=0 and high<=255,str(ids[i]))
				var id:=low+256*high;assert(id<part.vertices.size())
				var source:Dictionary=part.vertices[id];assert(int(source.id)==id)
				var p:Array=source.position;var expected:=Vector3(p[0],p[2],-p[1])
				max_position_error=maxf(max_position_error,positions[i].distance_to(expected))
				assert(positions[i].distance_to(expected)<.00002,"position mismatch "+str(instance.name)+":"+str(id))
				var matches:=false;var uv_error:=INF
				for uv:Vector2 in expected_uv[id]:
					uv_error=minf(uv_error,uv.distance_to(uvs[i]))
					if uv.distance_to(uvs[i])<.001:matches=true
				max_uv_error=maxf(max_uv_error,uv_error)
				assert(matches,"UV mismatch "+str(instance.name)+":"+str(id))
				if source.weights.size()>8:high_influence_vertices+=1
				vertices_checked+=1
			var indices:PackedInt32Array=arrays[Mesh.ARRAY_INDEX]
			for index:int in range(0,indices.size(),3):
				var triangle:Array=[]
				for corner:int in 3:
					var uv_id:=ids[indices[index+corner]];triangle.append(roundi(uv_id.x)+256*roundi(uv_id.y))
				assert(allowed_triangles.has(triangle_key(triangle)),"index topology mismatch")
				triangles_checked+=1
		assert(triangles_checked==expected_triangles,"triangle count changed")
		report.parts.append({"node":instance.name,"render_vertices_checked":vertices_checked,"render_vertices_with_source_more_than8":high_influence_vertices,"triangles_checked":triangles_checked,"max_position_error_m":max_position_error,"max_uv_error":max_uv_error})
	DirAccess.make_dir_recursive_absolute("res://artifacts/mh-natural")
	var file:=FileAccess.open("res://artifacts/mh-natural/source-id-test.json",FileAccess.WRITE);file.store_string(JSON.stringify(report,"  "));file.close()
	print("MH163_SOURCE_IDS ",JSON.stringify(report));quit()

func triangle_key(triangle:Array) -> String:
	triangle.sort();return str(triangle[0])+","+str(triangle[1])+","+str(triangle[2])
