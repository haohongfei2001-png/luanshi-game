extends SceneTree
func _initialize() -> void: run.call_deferred()
func run() -> void:
	var args:=OS.get_cmdline_user_args();assert(args.size()==1)
	var max_orthogonality:=0.;var vertices_checked:=0
	for cycle in 3:
		var packed:=load(args[0]) as PackedScene;assert(packed)
		var scene:=packed.instantiate();root.add_child(scene)
		var shared:ShaderMaterial
		for node:MeshInstance3D in scene.find_children("Survey_*","MeshInstance3D",true,false):
			var material:=node.material_override as ShaderMaterial;assert(material)
			if shared==null:shared=material
			assert(shared==material,"42 tiles should share one material")
			assert(material.get_shader_parameter("earth_enabled")==true)
			assert(float(material.get_shader_parameter("earth_width_m"))==2.)
			for key in ["earth_albedo","earth_normal","earth_roughness"]:
				var texture:=material.get_shader_parameter(key) as Texture2D;assert(texture)
				var image:=texture.get_image();assert(image.get_size()==Vector2i(2048,2048))
				assert(image.has_mipmaps() and image.get_mipmap_count()==11)
			var arrays:=node.mesh.surface_get_arrays(0)
			var normals:PackedVector3Array=arrays[Mesh.ARRAY_NORMAL]
			var tangents:PackedFloat32Array=arrays[Mesh.ARRAY_TANGENT]
			assert(tangents.size()==normals.size()*4)
			for i in normals.size():
				var tangent:=Vector3(tangents[4*i],tangents[4*i+1],tangents[4*i+2])
				assert(tangent.is_finite() and absf(tangent.length()-1.)<.001)
				max_orthogonality=maxf(max_orthogonality,absf(tangent.dot(normals[i])))
				vertices_checked+=1
		scene.free();shared=null;packed=null
		await process_frame
	assert(max_orthogonality<.001)
	print("EARTH_MATERIAL_ROUNDTRIP_PASS cycles=3 vertices=",vertices_checked," max_normal_tangent_dot=",max_orthogonality," graphics=NOT_RUN")
	quit()
