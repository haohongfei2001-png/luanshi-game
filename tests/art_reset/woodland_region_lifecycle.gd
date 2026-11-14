extends SceneTree
func _initialize() -> void: run.call_deferred()
func run() -> void:
	var args:=OS.get_cmdline_user_args();assert(args.size()==1)
	var packed:=load(args[0]) as PackedScene;assert(packed)
	var meshes:=0;var resources:={}
	for cycle in 3:
		var instance:=packed.instantiate();root.add_child(instance)
		assert(instance.get_meta("composition")=="sprite-native-woodland-region-02-mipmapped")
		meshes=0;resources.clear()
		for mesh:MeshInstance3D in instance.find_children("*","MeshInstance3D",true,false):
			var material:=mesh.mesh.surface_get_material(0) as StandardMaterial3D
			for texture:Texture2D in [material.albedo_texture,material.normal_texture,material.roughness_texture]:assert(texture.get_image().has_mipmaps(),"Normal-pixel material lacks mipmaps")
			meshes+=1;resources[mesh.mesh.get_instance_id()]=true
		assert(meshes==10 and resources.size()==2,"Native geometry is not shared by family")
		instance.free()
	print("WOODLAND_LIFECYCLE_PASS opens=3 mesh_instances=10 shared_meshes=2 graphics=NOT_RUN")
	quit()
