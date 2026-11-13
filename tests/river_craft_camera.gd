extends "res://tests/field_carry_camera.gd"
## Keep the live battle inputs, unit state and camera identical across two revisions.
func _run() -> void:
	if DisplayServer.get_name()=="headless": quit(1); return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))
	var shell=load("res://scenes/game.tscn").instantiate()
	root.add_child(shell)
	field=shell.field
	field.set_process(false)
	field.set_physics_process(false)
	field.hud.plan_requested.emit(1)
	field.hud.go.pressed.emit()
	await process_frame
	_advance(8)
	await _snap("captain","hero",8.6,1.27)
	await _snap("horse","horse",12.5,1.09)
	await _snap("river","bank",22.0,-.54)
	_advance(65)
	await _snap("foot","line",12.5,-.576)
	await _snap("field","line",22.0,-.576)
	await _snap("ranks","line",42.0,-.576)
	var center:=_target("line")
	for frame in 30:
		_advance(66+floori(frame*2.0/3.0))
		_view(center,22.0,-.576)
		await RenderingServer.frame_post_draw
		success=root.get_texture().get_image().save_jpg("%s/play-%03d.jpg"%[directory,frame],.92)==OK and success
	_advance(490)
	await _snap("gate","gate",32.0,-.89)
	FileAccess.open(directory+"/frames.json",FileAccess.WRITE).store_string(JSON.stringify(shots))
	print("RIVER_CRAFT_CAMERA ",field.battle.tick," hits ",field.battle.hits)
	shell.queue_free()
	await process_frame
	quit(0 if success else 1)
