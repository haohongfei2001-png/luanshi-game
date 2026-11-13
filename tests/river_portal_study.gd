extends "res://tests/river_art_capture.gd"

func _run() -> void:
	if DisplayServer.get_name()=="headless":
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))
	var game=load("res://scenes/game.tscn").instantiate()
	root.add_child(game)
	field=game.field
	field.set_process(false)
	field.set_physics_process(false)
	field.hud.plan_requested.emit(1)
	field.hud.go.pressed.emit()
	await process_frame
	_advance(490)
	await _snap("survey","gate",34.0,-.89)
	await _snap("approach","ram",22.0,-.65)
	await _snap("threshold","gate",22.0,-.89)
	await _snap("gallery","gate",26.0,2.23)
	_advance(635)
	await _snap("broken","gate",22.0,-.89)
	FileAccess.open(directory+"/frames.json",FileAccess.WRITE).store_string(JSON.stringify(shots))
	game.queue_free()
	await process_frame
	quit(0 if success else 1)
