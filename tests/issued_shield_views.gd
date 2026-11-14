extends "res://tests/field_contact_window.gd"
## Replay two genuine infantry blocks with both the active weapon hand and an officer in frame.
func _run() -> void:
	if DisplayServer.get_name()=="headless":
		quit(1)
		return
	directory="res://artifacts/shield-views"
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
	var passed:=field.battle.started
	var records:=[]
	var b:=field.battle
	for step in range(1,190):
		_step_neutral()
		if b.tick!=step:
			quit(1)
			return
		if step not in [79,188]: continue
		var id:=70 if step==79 else 678
		var u:=b.roster[id]
		passed=passed and u.contact_tick==step and u.contact_blocked and u.kit==7 and u.state==Battle.State.GUARD
		var near_officer: Battle.Unit
		var nearest:=INF
		for v in b.roster:
			if v.officer and b.active(v) and v.pos.distance_squared_to(u.pos)<nearest:
				near_officer=v
				nearest=v.pos.distance_squared_to(u.pos)
		if near_officer==null:
			quit(1)
			return
		for yaw in [LOOK,LOOK+PI]:
			for station in ["hand","normal","ranks","officer","profile"]:
				var zoom:=22.0
				var focus: Battle.Unit=u
				var bearing:float=yaw
				match station:
					"profile":
						zoom=3.6
						var towards:=u.facing
						bearing=atan2(towards.x,towards.y)+(.32 if yaw==LOOK else -.73)
					"hand": zoom=5.6
					"ranks": zoom=43.0
					"officer":
						zoom=8.0
						focus=near_officer
				field.carry=.65*Battle.DT
				var at:=focus.before.lerp(focus.pos,.65)
				_view(at,zoom,bearing)
				await RenderingServer.frame_post_draw
				var im:=root.get_texture().get_image()
				var tag:="%d-%s-%s"%[step,station,"front" if yaw==LOOK else "rear"]
				passed=im.save_jpg(directory+"/"+tag+".jpg",.96)==OK and passed
				if station in ["hand","normal","profile"]:
					passed=im.save_png(directory+"/"+tag+".png")==OK and passed
				var anchor:=Ground.unit_point(at)+Vector3.UP*(1.55 if station=="profile" else 1.02)
				var px:=field.camera.unproject_position(anchor)*Vector2(im.get_size())/root.get_visible_rect().size
				records.append({"tag":tag,"tick":step,"id":focus.id,"ordinary":Array(b.ordinary_counts),"roles":Array(b.command_counts),
					"shield":id,"attacker":u.contact_source,"side":u.contact_side,"hp":u.hp,"hit":u.contact_blocked,
					"lens":zoom,"yaw":bearing,"screen":[im.get_width(),im.get_height()],"scale":root.scaling_3d_scale,
					"xy":[px.x,px.y],"hits":Array(b.hits),"losses":Array(b.losses),"visible":field.view.visible_soldiers})
	var f:=FileAccess.open(directory+"/views.json",FileAccess.WRITE)
	f.store_string(JSON.stringify(records,"  "))
	f.close()
	print("ISSUED_SHIELD_WINDOW ",passed," frames=",records.size())
	scene.queue_free()
	await process_frame
	quit(0 if passed and records.size()==20 else 1)
