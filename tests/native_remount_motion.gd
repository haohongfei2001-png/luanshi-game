extends "res://tests/native_remount_window.gd"
## Consecutive actual 20 Hz steps, sampled once per game tick at each true camera.
func _run() -> void:
	var out:="res://artifacts/remount-motion"
	for folder:String in [out,out+"/normal",out+"/close",OUT]:
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	var scene=load("res://scenes/game.tscn").instantiate()
	root.add_child(scene)
	field=scene.field
	for i in 5: await process_frame
	if not await _select_bridge(): quit(1);return
	_click(field.hud.go.get_global_rect().get_center())
	field.set_process(false)
	field.set_physics_process(false)
	var b:=field.battle
	if not b.started: quit(2);return
	while b.tick<85:
		b.input_state(Vector2.ZERO,b.hero.facing)
		b.step()
	var subject:Battle.Unit=b.roster[22]
	if subject.hero or subject.officer or not subject.mounted or subject.mount_hp<=0.: quit(3);return
	var yaw:=atan2(subject.facing.x,subject.facing.y)+.95
	var index:Array=[]
	for frame in 32:
		if frame>0:
			b.input_state(Vector2.ZERO,b.hero.facing)
			b.step()
		var shots:Array=[["normal",Ground.BRIDGE_VIEW,22.,deg_to_rad(-33.)],["close",subject.pos,6.3,yaw]]
		for shot:Array in shots:
			_set_view(shot[1],shot[2],shot[3])
			await RenderingServer.frame_post_draw
			var captured:=root.get_texture().get_image()
			if captured.get_width()!=2560 or captured.get_height()!=1600: quit(4);return
			if captured.save_png(out+"/%s/frame-%03d.png"%[shot[0],frame])!=OK: quit(5);return
		index.append({"tick":b.tick,"actor":subject.id,"xz":[subject.pos.x,subject.pos.y],"facing":[subject.facing.x,subject.facing.y],"state":subject.state,"stride":subject.stride,"travel":subject.pos.distance_to(subject.before),"hp":subject.hp,"mount_hp":subject.mount_hp,"hits":Array(b.hits).duplicate(),"losses":Array(b.losses).duplicate(),"ordinary":Array(b.ordinary_counts)})
	var f:=FileAccess.open(out+"/sequence.json",FileAccess.WRITE)
	f.store_string(JSON.stringify({"frames":32,"fps":20,"duration":1.6,"size":[2560,1600],"scale":root.scaling_3d_scale,"normal_zoom":22.,"close_zoom":6.3,"kind":"consecutive original-speed actual game steps, no realtime performance claim","index":index},"  "))
	f.close()
	print("NATIVE_REMOUNT_MOTION ",JSON.stringify(index[-1]))
	scene.queue_free()
	await process_frame
	quit()
