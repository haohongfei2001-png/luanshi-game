extends SceneTree
## Geometry/import verification only. This cannot render or accept the art.
func _initialize() -> void:
	var args:=OS.get_cmdline_user_args();assert(args.size()==1,"Pass derived GLB path after --")
	var document:=GLTFDocument.new();var state:=GLTFState.new()
	assert(document.append_from_file(args[0],state)==OK)
	var scene:=document.generate_scene(state);assert(scene)
	root.add_child(scene)
	var triangles:=0;var surfaces:=0;var nodes:=0;var textures:=0;var uv_channels:=0
	for node:MeshInstance3D in scene.find_children("*","MeshInstance3D",true,false):
		nodes+=1
		for surface:int in node.mesh.get_surface_count():
			surfaces+=1;var arrays:=node.mesh.surface_get_arrays(surface)
			triangles+=int(arrays[Mesh.ARRAY_INDEX].size()/3)
			if arrays[Mesh.ARRAY_TEX_UV]!=null:uv_channels+=1
			if arrays[Mesh.ARRAY_TEX_UV2]!=null:uv_channels+=1
			var material:=node.mesh.surface_get_material(surface) as StandardMaterial3D
			if material and material.albedo_texture:textures+=1
	assert(nodes==1 and surfaces==1,"Unbounded per-leaf draw surfaces")
	assert(triangles==90484,"Unexpected source geometry change")
	assert(textures==1 and uv_channels>=1,"Missing baked color material")
	print("SPRITE_GLTF_INTAKE ",JSON.stringify({"triangles":triangles,"surfaces":surfaces,"mesh_nodes":nodes,"textured_surfaces":textures,"uv_channels":uv_channels,"actual_draw_calls":"NOT_MEASURED","graphics":"NOT_RUN"}))
	scene.free();quit()
