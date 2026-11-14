extends "res://tests/river_art_capture.gd"
const DIR:="res://artifacts/field-fall"
var subject:=-1
func _target(kind: String) -> Vector2:
	if kind=="falling": return field.battle.roster[subject].pos
	return super._target(kind)

func _run() -> void:
	if DisplayServer.get_name()=="headless": quit(1);return
	directory=DIR
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(DIR))
	var scene=load("res://scenes/game.tscn").instantiate()
	root.add_child(scene)
	field=scene.field
	field.set_physics_process(false)
	field.set_process(false)
	var b:=field.battle
	field.hud.plan_requested.emit(1)
	field.hud.go.pressed.emit()
	root.warp_mouse(Vector2(810,416))
	await process_frame
	if not b.started or b.ordinary_counts!=PackedInt32Array([512,512]): quit(2);return
	if "--fall-film" in OS.get_cmdline_user_args():
		var start:=0
		var states:=[]
		for frame in range(120):
			_advance(b.tick+1)
			if subject<0:
				for u in b.roster:
					if not u.hero and not u.officer and not u.mounted and u.state==Battle.State.DEAD and u.lost_tick==b.tick:
						subject=u.id
						start=b.tick
						break
			var at:=b.ram if subject<0 else b.roster[subject].pos
			_view(at,22.,-.54)
			await RenderingServer.frame_post_draw
			if subject>=0:
				var u:=b.roster[subject]
				var phase:=b.tick-start
				if phase in [0,4,7,11,15,22]:
					var name:="fall-%02d"%phase
					success=root.get_texture().get_image().save_png(DIR+"/"+name+".png")==OK and success
					states.append({"name":name,"tick":b.tick,"unit":u.id,"kit":u.kit,"timer":u.timer,"hp":u.hp,
						"pos":[u.pos.x,u.pos.y],"lens":field.camera.size,"ordinary":Array(b.ordinary_counts),
						"hits":[b.hits[0],b.hits[1]],"losses":[b.losses[0],b.losses[1]]})
				if phase>=23: break
		success=success and subject>=0 and states.size()==6
		var rec:=FileAccess.open(DIR+"/fall.json",FileAccess.WRITE)
		rec.store_string(JSON.stringify(states,"  "))
		rec.close()
	else:
		_advance(48)
		await _snap("army","hero",22.,-.576)
		await _snap("pasture","line",22.,-.576)
		await _snap("bank","bank",22.,-.576)
		_advance(490)
		await _snap("approach","ram",24.,-.54)
		var target:=Vector2(-INF,-INF)
		var best:=INF
		var kit_count:=PackedInt32Array()
		kit_count.resize(9)
		for u in b.roster:
			if u.hero or u.officer or u.mounted or u.state!=Battle.State.DEAD or u.timer>.0001: continue
			kit_count[u.kit]+=1
			var gap:float=u.pos.distance_squared_to(b.ram-Vector2(7,4))
			if gap<best:
				subject=u.id
				target=u.pos
				best=gap
		if subject<0: quit(3);return
		await _snap("rest","falling",6.,-.54)
		var rec:=FileAccess.open(DIR+"/case.json",FileAccess.WRITE)
		rec.store_string(JSON.stringify({"subject":subject,"pos":[target.x,target.y],"kit":b.roster[subject].kit,"all_settled_kits":Array(kit_count),
			"timer":b.roster[subject].timer,"hp":b.roster[subject].hp,"views":shots},"  "))
		rec.close()
	print("GROUND_FALL ",success," actor=",subject)
	scene.queue_free()
	await process_frame
	quit(0 if success else 1)
