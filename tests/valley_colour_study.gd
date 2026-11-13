extends "res://tests/river_art_capture.gd"

func _run() -> void:
	if DisplayServer.get_name()=="headless":
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))
	var scene=load("res://scenes/game.tscn").instantiate()
	root.add_child(scene)
	field=scene.field
	field.set_physics_process(false)
	field.set_process(false)
	field.hud.plan_requested.emit(1)
	field.hud.go.pressed.emit()
	root.warp_mouse(Vector2(810,416))
	await process_frame
	_advance(8)
	await _snap("saddle","horse",8.0,1.09)
	_advance(65)
	await _snap("troops","line",22.0,-.576)
	await _snap("rider","cavalry",9.5,-.93)
	await _snap("ford","bridge",29.0,-.54)
	await _snap("grove","margin",23.0,-.64)
	_advance(490)
	await _snap("gate","gate",32.0,-.89)
	var out:=FileAccess.open(directory+"/frames.json",FileAccess.WRITE)
	out.store_string(JSON.stringify(shots,"  "))
	success=success and field.battle.ordinary_counts==PackedInt32Array([512,512])
	print("VALLEY_"+("PASS" if success else "FAIL"))
	scene.queue_free()
	await process_frame
	quit(0 if success else 1)

func _target(kind: String) -> Vector2:
	if kind=="cavalry":
		for u in field.battle.roster:
			if u.mounted and not u.officer and field.battle.active(u):
				return u.pos
	return super._target(kind)
