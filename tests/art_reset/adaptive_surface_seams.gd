extends SceneTree
const Ground:=preload("res://scripts/field/ground.gd")
func _initialize() -> void: run.call_deferred()
func edge_key(a:Vector3,b:Vector3) -> String:
	var ka:="%.6f,%.6f"%[a.x,a.z];var kb:="%.6f,%.6f"%[b.x,b.z]
	return ka+"/"+kb if ka<kb else kb+"/"+ka
func run() -> void:
	assert(Ground.authored_landform_enabled)
	var args:=OS.get_cmdline_user_args();assert(args.size()==1)
	var packed:=load(args[0]) as PackedScene;assert(packed)
	var scene:=packed.instantiate();root.add_child(scene)
	var boundary:Dictionary={};var triangles:=0;var tiles:=0
	for node:MeshInstance3D in scene.find_children("Survey_*","MeshInstance3D",true,false):
		tiles+=1
		var arrays:=node.mesh.surface_get_arrays(0);var v:PackedVector3Array=arrays[Mesh.ARRAY_VERTEX];var ids:PackedInt32Array=arrays[Mesh.ARRAY_INDEX]
		var box:=node.mesh.get_aabb();var edges:Dictionary={};var ends:Dictionary={}
		for i in range(0,ids.size(),3):
			triangles+=1
			for k in 3:
				var a:=v[ids[i+k]];var b:=v[ids[i+(k+1)%3]];var key:=edge_key(a,b)
				edges[key]=int(edges.get(key,0))+1;ends[key]=[a,b]
		for key:String in edges:
			assert(edges[key] in [1,2],"Nonmanifold mesh")
			if edges[key]==1:
				var a:Vector3=ends[key][0];var b:Vector3=ends[key][1]
				var is_border:bool=(a.x==b.x and (a.x==box.position.x or a.x==box.end.x)) or (a.z==b.z and (a.z==box.position.z or a.z==box.end.z))
				assert(is_border,"Internal hanging edge or crack: "+key)
				boundary[key]=int(boundary.get(key,0))+1
				if boundary[key]==1:boundary[key+"_ends"]=[a,b]
	var outer:=0
	for key:String in boundary:
		if key.ends_with("_ends"):continue
		if boundary[key]==1:
			var a:Vector3=boundary[key+"_ends"][0];var b:Vector3=boundary[key+"_ends"][1]
			assert((a.x==b.x and a.x in [-144.,160.]) or (a.z==b.z and a.z in [-112.,112.]),"Tile seam unmatched: "+key)
			outer+=1
		else:assert(boundary[key]==2)
	print("ADAPTIVE_SEAMS_PASS ",JSON.stringify({"tiles":tiles,"triangles":triangles,"outer_edges":outer,"internal_and_tile_edges":"paired, no hanging segments","graphics":"NOT_RUN"}))
	scene.free();quit()
