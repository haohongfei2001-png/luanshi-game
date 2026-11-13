extends "res://tests/field_controls.gd"

func _run() -> void:
	if DisplayServer.get_name()=="headless":
		quit(1)
		return
	var shell=load("res://scenes/game.tscn").instantiate()
	root.add_child(shell)
	field=shell.field
	await process_frame
	field.new_muster(20)
	await _portrait()
	shell.queue_free()
	await process_frame
	quit(0 if issues.is_empty() else 1)
