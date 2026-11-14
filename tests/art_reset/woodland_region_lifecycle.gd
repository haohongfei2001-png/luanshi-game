extends SceneTree
func _initialize() -> void: run.call_deferred()
func run() -> void:
	var args:=OS.get_cmdline_user_args();assert(args.size()==1)
	var packed:=load(args[0]) as PackedScene;assert(packed)
	var meshes:=0;var resources:={}
	for cycle in 3:
		var instance:=packed.instantiate();root.add_child(instance)
		assert(instance.get_meta("composition")=="sprite-native-woodland-region-01")
		meshes=0;resources.clear()
		for mesh:MeshInstance3D in instance.find_children("*","MeshInstance3D",true,false):
			meshes+=1;resources[mesh.mesh.get_instance_id()]=true
		assert(meshes==10 and resources.size()==2,"Native geometry is not shared by family")
		instance.free()
	print("WOODLAND_LIFECYCLE_PASS opens=3 mesh_instances=10 shared_meshes=2 graphics=NOT_RUN")
	quit()
