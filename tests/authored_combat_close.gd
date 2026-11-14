extends "res://tests/authored_combat_window.gd"
const CLOSE_OUT:="res://artifacts/authored-combat-close"

func _set_view(center:Vector2,size:float,yaw:float) -> void:
	field.camera_center=center
	field.camera.size=size
	field.camera_yaw=yaw
	field._camera()
	field.carry=Battle.DT*.82
	field._draw_field()
	field.hud.update_model(field.battle,field.paused)

func _run() -> void:
	for folder:String in [OUT,CLOSE_OUT]:
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	var scene=await _open_match()
	if scene==null: quit(1);return
	var b:=field.battle
	var rows:Array=[]
	for tick:int in [17,23,25,28,31,35,37,48]:
		while b.tick<tick:
			b.input_state(Vector2.ZERO,b.hero.facing)
			b.step()
		var subject:Battle.Unit=b.roster[80]
		var shots:Array=[["side",subject.pos,6.3,0.]]
		if tick in [25,28]: shots.append(["line",Ground.BRIDGE_VIEW,22.,deg_to_rad(-33.)])
		if tick==28: shots.append(["reverse",Ground.BRIDGE_VIEW,22.,deg_to_rad(-33.)+PI])
		for shot:Array in shots:
			_set_view(shot[1],shot[2],shot[3])
			await RenderingServer.frame_post_draw
			var captured:=root.get_texture().get_image()
			if captured.get_width()!=2560 or captured.get_height()!=1600: quit(2);return
			if captured.save_jpg(CLOSE_OUT+"/%s-%03d.jpg"%[shot[0],tick],.78)!=OK: quit(3);return
			rows.append({"actor":80,"tick":tick,"view":shot[0],"camera":[shot[1].x,shot[1].y,shot[2],shot[3]],
				"position":[subject.pos.x,subject.pos.y],"state":subject.state,"timer":subject.timer,"duration":subject.duration,
				"impacts":subject.impacts,"hp":subject.hp,"hits":Array(b.hits),"losses":Array(b.losses),
				"ordinary":Array(b.ordinary_counts),"scale":root.scaling_3d_scale,"size":[2560,1600]})
	var f:=FileAccess.open(CLOSE_OUT+"/sequence.json",FileAccess.WRITE)
	f.store_string(JSON.stringify(rows,"  "))
	f.close()
	print("AUTHORED_CLOSE ",JSON.stringify(rows[-1]))
	scene.queue_free()
	await process_frame
	quit()
