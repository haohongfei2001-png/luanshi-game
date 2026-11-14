extends SceneTree
const Map:=preload("res://scripts/field/river_pass_master.gd")
func _initialize() -> void:_run.call_deferred()
func _run() -> void:
	await process_frame
	var orphan_baseline:=int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))
	var rows:Array=[]
	for cycle in 3:
		var map:=Map.new();map.bridgehead=true;root.add_child(map)
		await process_frame
		assert(map.composition_audit().native_instances==643)
		var loaded:=int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
		map.queue_free();await process_frame;await process_frame
		var orphans:=int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))
		assert(orphans==orphan_baseline,"Native packed scene leaked orphan nodes after close")
		rows.append({"cycle":cycle,"loaded_nodes":loaded,"remaining_nodes":int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)),"orphans":orphans})
	assert(rows[0].remaining_nodes==rows[2].remaining_nodes)
	print("RIVER_PASS_LIFECYCLE_PASS ",JSON.stringify({"orphan_baseline":orphan_baseline,"cycles":rows,"graphics":"NOT_RUN"}))
	quit(0)
