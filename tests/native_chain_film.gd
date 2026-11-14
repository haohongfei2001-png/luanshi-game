extends "res://tests/bridgehead_window.gd"
## Twenty-four consecutive real battle ticks, with unmodified actor placement.
const FILM_OUT:="res://artifacts/native-chain-film"

func _set_view(center:Vector2,size:float,yaw:float) -> void:
	field.camera_center=center
	field.camera.size=size
	field.camera_yaw=yaw
	field._camera()
	field.carry=Battle.DT*.82
	field._draw_field()
	field.hud.update_model(field.battle,field.paused)

func _open_match() -> Node:
	var scene=load("res://scenes/game.tscn").instantiate()
	root.add_child(scene)
	field=scene.field
	for i in 5: await process_frame
	if not await _select_bridge(): return null
	_click(field.hud.go.get_global_rect().get_center())
	field.set_process(false)
	field.set_physics_process(false)
	return scene

func _run() -> void:
	for folder:String in [OUT,FILM_OUT,FILM_OUT+"/normal",FILM_OUT+"/side"]:
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	# This exact naturally occurring dao episode was identified by the existing
	# scout. Freeze the actor and ticks for all visual comparisons.
	var selected:={"start":100,"windup":106,"hit":112,"resume":121,"actor":617}
	var scene=await _open_match()
	if scene==null: quit(3);return
	var b:=field.battle
	while b.tick<int(selected.start):
		b.input_state(Vector2.ZERO,b.hero.facing)
		b.step()
	var rows:Array=[]
	for frame:int in 24:
		if frame>0:
			b.input_state(Vector2.ZERO,b.hero.facing)
			b.step()
		var subject:Battle.Unit=b.roster[int(selected.actor)]
		var shots:Array=[["normal",Ground.BRIDGE_VIEW,22.,deg_to_rad(-33.)],["side",subject.pos,6.3,0.]]
		for shot:Array in shots:
			_set_view(shot[1],shot[2],shot[3])
			await RenderingServer.frame_post_draw
			var captured:=root.get_texture().get_image()
			if captured.get_width()!=2560 or captured.get_height()!=1600: quit(4);return
			if captured.save_jpg(FILM_OUT+"/%s/frame-%03d.jpg"%[shot[0],frame],.88)!=OK: quit(5);return
		if b.tick==112:
			_set_view(Ground.BRIDGE_VIEW,22.,deg_to_rad(-33.)+PI)
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_jpg(FILM_OUT+"/reverse-112.jpg",.78)
		rows.append({"tick":b.tick,"actor":subject.id,"kit":subject.kit,"team":subject.team,"mounted":subject.mounted,
			"xz":[subject.pos.x,subject.pos.y],"facing":[subject.facing.x,subject.facing.y],
			"state":subject.state,"timer":subject.timer,"duration":subject.duration,
			"move_slot":subject.move_slot,"target":subject.target,"impacts":subject.impacts,"received":subject.received,
			"travel":subject.pos.distance_to(subject.before),"hp":subject.hp,"contact_tick":subject.contact_tick,
			"contact_blocked":subject.contact_blocked,"hits":Array(b.hits).duplicate(),
			"losses":Array(b.losses).duplicate(),"ordinary":Array(b.ordinary_counts).duplicate(),
			"camera_close":[subject.pos.x,subject.pos.y,6.3,0.]})
	var f:=FileAccess.open(FILM_OUT+"/sequence.json",FileAccess.WRITE)
	f.store_string(JSON.stringify({"selected":selected,"frames":24,"fps":20,"duration":1.2,"size":[2560,1600],
		"scale":root.scaling_3d_scale,"normal_camera":[Ground.BRIDGE_VIEW.x,Ground.BRIDGE_VIEW.y,22.,deg_to_rad(-33.)],
		"seed":Battle.SEED,"kind":"consecutive original-speed real game steps, no realtime FPS claim","index":rows},"  "))
	f.close()
	print("NATIVE_CHAIN_MOTION ",JSON.stringify(rows[0])," terminal=",JSON.stringify(rows[-1]))
	scene.queue_free()
	await process_frame
	quit()
