extends SceneTree
func _initialize() -> void:run.call_deferred()
func run() -> void:
	var packed:=load("user://authored-reset-support.scn") as PackedScene
	assert(packed)
	var before:=int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))
	for cycle:int in 3:
		var instance:=packed.instantiate();root.add_child(instance);await process_frame
		assert(instance.get_node("ContinuousSurveySurface").get_child_count()==72)
		assert(instance.get_node("BridgeMoat").position==Vector3(24,.13,0))
		assert(instance.get_node("Gate").position==Vector3(48,0,0))
		instance.queue_free();await process_frame
		assert(root.get_child_count()==0)
	assert(int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))==before)
	print("SUPPORT_LIFECYCLE_PASS 3 opens/closes, zero new orphan nodes; not gameplay")
	quit()
