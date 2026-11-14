extends SceneTree
func _initialize() -> void: run.call_deferred()
func run() -> void:
	if DisplayServer.get_name()=="headless":
		print("GRASS_GPU_LAYOUT_NOT_RUN dummy/headless server cannot validate GPU instance transforms")
		quit(77);return
	var args:=OS.get_cmdline_user_args();assert(args.size()==1)
	var packed:=load(args[0]) as PackedScene;var scene:=packed.instantiate();root.add_child(scene)
	await process_frame;await RenderingServer.frame_post_draw
	var node:=scene.get_node("NativeLowGrassShoulders") as MultiMeshInstance3D
	var poses:Array[Transform3D]=node.get("authored_transforms")
	assert(node.multimesh.instance_count==poses.size())
	var max_error:=0.
	for i in poses.size():
		var actual:=node.multimesh.get_instance_transform(i)
		max_error=maxf(max_error,actual.origin.distance_to(poses[i].origin))
		assert(actual.basis.is_equal_approx(poses[i].basis))
	assert(max_error<.0001)
	print("GRASS_GPU_INSTANCE_LAYOUT_PASS instances=",poses.size()," max_origin_error=",max_error," art=NOT_ACCEPTED")
	scene.free();quit()
