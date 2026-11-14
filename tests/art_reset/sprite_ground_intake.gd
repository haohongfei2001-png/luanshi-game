extends SceneTree
## Imported terrain support parity, not graphical acceptance.
const Ground:=preload("res://scripts/field/ground.gd")
func _initialize() -> void: run.call_deferred()
func run() -> void:
	var args:=OS.get_cmdline_user_args();assert(args.size()==1)
	var doc:=GLTFDocument.new();var state:=GLTFState.new()
	assert(doc.append_from_file(args[0],state)==OK)
	var scene:=doc.generate_scene(state);assert(scene);root.add_child(scene)
	var vertices:=0;var worst:=0.0;var triangles:=0;var meshes:=0
	for node:MeshInstance3D in scene.find_children("*","MeshInstance3D",true,false):
		meshes+=1
		for surface:int in node.mesh.get_surface_count():
			var arrays:=node.mesh.surface_get_arrays(surface)
			triangles+=int(arrays[Mesh.ARRAY_INDEX].size()/3)
			for vertex:Vector3 in arrays[Mesh.ARRAY_VERTEX]:
				var p:=node.global_transform*vertex;vertices+=1
				assert(p.x>=29.599 and p.x<=46.601 and abs(p.z)<=24.001)
				var xz:=Vector2(p.x,p.z)
				var expected:=Ground.height(xz,true)-Ground.MOAT_BED_DEPTH*Ground.moat_depth(xz)
				worst=maxf(worst,absf(p.y-expected))
	assert(meshes==1 and vertices>=5070 and triangles>9000)
	assert(worst<.015,"Imported vertex deviates from shared gameplay ground")
	print("SPRITE_GROUND_INTAKE ",JSON.stringify({"vertices":vertices,"triangles":triangles,"max_vertex_height_error_m":worst,"interior_triangle_support":"NOT_MEASURED","graphics":"NOT_RUN"}))
	scene.free();quit()
