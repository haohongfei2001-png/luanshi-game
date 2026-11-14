extends "res://tests/bridgehead_window.gd"
## Same bridge muster and neutral-player combat, common seed, running armature and dress pieces.
func _set_view(center:Vector2,size:float,yaw:float) -> void:
	field.camera_center=center
	field.camera.size=size
	field.camera_yaw=yaw
	field._camera()
	var hw:=size*.5*float(root.size.x)/maxf(1.,root.size.y)
	var hd:=size*.5/maxf(sin(field.camera_pitch),.28)
	var co:=absf(cos(yaw))
	var si:=absf(sin(yaw))
	field.view.sync_view(center,Vector2(co*hw+si*hd+4,si*hw+co*hd+6),.82,size)

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var scene=load("res://scenes/game.tscn").instantiate()
	root.add_child(scene)
	field=scene.field
	for i in 5: await process_frame
	if not await _select_bridge(): quit(1);return
	_click(field.hud.go.get_global_rect().get_center())
	var b:=field.battle
	var focus:=Ground.BRIDGE_VIEW
	var size:=22.
	var yaw:=deg_to_rad(-33.)
	field.set_process(false)
	field.set_physics_process(false)
	var checks:Array=[]
	for mark in [55,105,135,185]:
		while b.tick<mark:
			# Soldiers and officers advance their normal battle actions with a neutral player.
			b.input_state(Vector2.ZERO,b.hero.facing)
			b.step()
		var subjects:={}
		var ranks:={}
		for u in b.roster:
			if u.hero or u.officer or u.mounted or not b.active(u) or u.kit not in [3,5,7]: continue
			var label:=str(u.kit)
			var center:=Vector2(34.8,1.2)
			var target:=Vector2(31.,-9.) if b.tick==135 else center
			var d:=u.pos.distance_squared_to(target)
			if (not ranks.has(label) or d<ranks[label]) and u.pos.x>27.:
				ranks[label]=d
				subjects[label]=u
		var list:Array=[["line",focus,size,yaw]]
		if mark==135:
			list.append(["reverse",focus,size,yaw+PI])
			for kit in ["3","5","7"]:
				if not subjects.has(kit): continue
				var u:Battle.Unit=subjects[kit]
				var forward:=atan2(u.facing.x,u.facing.y)
				var angle:=forward+.36
				if sin(angle)>.70: angle=forward-.73
				list.append(["kit"+kit,u.pos+.35*u.facing,5.3,angle])
		for shot:Array in list:
			_set_view(shot[1],shot[2],shot[3])
			await RenderingServer.frame_post_draw
			var frame:=root.get_texture().get_image()
			var ok:=frame.save_jpg(OUT+"/%s-%03d.jpg"%[shot[0],mark],.945)==OK
			var who:={}
			for k:String in subjects: who[k]=subjects[k].id
			checks.append({"tick":mark,"view":shot[0],"pixels":[frame.get_width(),frame.get_height()],"normal":[shot[2],shot[3],shot[1].x,shot[1].y],"ordinary":Array(b.ordinary_counts),"hits":Array(b.hits).duplicate(),"losses":Array(b.losses).duplicate(),"subjects":who,"saved":ok,"units":field.view.visible_soldiers})
			if not ok or frame.get_width()!=2560 or frame.get_height()!=1600: quit(2);return
	var f:=FileAccess.open(OUT+"/field.json",FileAccess.WRITE)
	f.store_string(JSON.stringify(checks,"  "))
	f.close()
	print("ROBE_GAME_WINDOW ",checks.size()," ",JSON.stringify(checks[-1]))
	scene.queue_free()
	await process_frame
	quit()
