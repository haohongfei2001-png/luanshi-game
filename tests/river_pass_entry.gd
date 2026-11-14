extends SceneTree
func _initialize() -> void:_run.call_deferred()
func _run() -> void:
	var scene=load("res://scenes/game.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	var field=scene.field
	field.hud.plan_requested.emit(5)
	field.set_process(false);field.set_physics_process(false)
	field.hud.go.pressed.emit()
	assert(field.battle.started and field.battle.bridgehead)
	assert(field.map.composition_audit().layout=="river-pass-master-v1")
	for tick in 135:field._physics_process(.05)
	field.camera.size=22.
	field._process(.05)
	assert(field.map.gate!=null and field.map.ram_beam!=null)
	print("RIVER_PASS_ENTRY_PASS ",JSON.stringify({"layout":field.map.composition_audit(),"tick":field.battle.tick,"ordinary":Array(field.battle.ordinary_counts),"hits":field.battle.hits,"camera_size":field.camera.size,"graphics":"NOT_RUN"}))
	scene.queue_free();await process_frame;await process_frame
	# Allow the audio mixer to acknowledge stopped playback before process exit.
	await create_timer(.15).timeout
	quit(0)
