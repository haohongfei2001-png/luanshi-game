extends "res://tests/river_art_capture.gd"
## Real company members under the deployment and battle controller.
var subject: int = -1
func _target(kind: String) -> Vector2:
	if kind=="subject": return field.battle.roster[subject].pos
	return super._target(kind)

func _run() -> void:
	if DisplayServer.get_name()=="headless": quit(1); return
	directory="res://artifacts/wardrobe"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))
	var game=load("res://scenes/game.tscn").instantiate()
	root.add_child(game)
	field=game.field
	field.set_physics_process(false)
	field.set_process(false)
	field.hud.plan_requested.emit(1)
	field.hud.go.pressed.emit()
	await process_frame
	var b:=field.battle
	if not b.started or b.ordinary_counts!=PackedInt32Array([512,512]): quit(1);return
	_advance(41)
	for kit: int in [3,7,5]:
		var best_score: float=-INF
		subject=-1
		for u in b.roster:
			if u.kit!=kit or u.officer or u.hero or u.mounted or not b.active(u): continue
			if u.team != (1 if kit==7 else 0): continue
			if kit==5 and u.pos.x< -27.0: continue
			var score:float=-u.pos.distance_to(Vector2(2,13) if kit==5 else Vector2(1,-14))*.33
			if u.state in [Battle.State.WINDUP,Battle.State.RECOVER,Battle.State.GUARD]: score+=22
			if score>best_score: best_score=score; subject=u.id
		if subject<0: quit(2);return
		var label: String={3:"spear",7:"shield",5:"bow"}[kit]
		var yaw: float=-1.36 if kit==7 else 1.19
		await _snap(label,"subject",5.8,yaw)
		var row: Dictionary=shots.back()
		var foe=b.roster[subject]
		var screen:=field.camera.unproject_position(Ground.unit_point(foe.pos)+Vector3.UP*.91)
		row["subject_id"]=int(subject)
		row["subject_pixel"]=[screen.x,screen.y]
		row["state"]=int(foe.state)
		row["kit"]=int(foe.kit)
		row["subject_position"]=[foe.pos.x,foe.pos.y]
	await _snap("line","line",13.0,-.576)
	await _snap("wide","line",49.0,-.576)
	var f:=FileAccess.open(directory+"/subjects.json",FileAccess.WRITE)
	f.store_string(JSON.stringify(shots,"  "))
	f.close()
	print("GARMENT_WINDOW ",success)
	game.queue_free()
	await process_frame
	quit(0 if success else 1)
