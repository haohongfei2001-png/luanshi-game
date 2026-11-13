extends "res://tests/river_art_capture.gd"
## Same live formation, no actors moved or held for the camera.
func _run() -> void:
	if DisplayServer.get_name()=="headless": quit(1); return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))
	var scene=load("res://scenes/game.tscn").instantiate()
	root.add_child(scene)
	field=scene.field
	field.set_process(false)
	field.set_physics_process(false)
	field.hud.plan_requested.emit(1)
	field.hud.go.pressed.emit()
	await process_frame
	# Follow an actual local line of contact through a short exchange at three distances.
	_advance(65)
	await _snap("close","line",12.5,-.576)
	await _snap("field","line",22.0,-.576)
	await _snap("ranks","line",42.0,-.576)
	var line_centre:=_target("line")
	for frame in 30:
		_advance(66+floori(frame*2.0/3.0))
		_view(line_centre,22.0,-.576)
		await RenderingServer.frame_post_draw
		var pic:=root.get_texture().get_image()
		success=pic.save_jpg("%s/play-%03d.jpg"%[directory,frame],.91)==OK and success
	FileAccess.open(directory+"/frames.json",FileAccess.WRITE).store_string(JSON.stringify(shots))
	print("FIELD_CARRIES_VIEW ",field.battle.tick," hits ",field.battle.hits)
	scene.queue_free()
	await process_frame
	quit(0 if success else 1)
