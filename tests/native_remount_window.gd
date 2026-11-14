extends "res://tests/bridgehead_window.gd"
## Actual cavalry in the fixed bridge battle, with the same geometry and full roster.
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
	var out:="res://artifacts/remount-window"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var scene=load("res://scenes/game.tscn").instantiate()
	root.add_child(scene)
	field=scene.field
	for i in 5: await process_frame
	if not await _select_bridge():
		push_error("The native remount study could not select the real bridge muster")
		quit(1);return
	_click(field.hud.go.get_global_rect().get_center())
	field.set_process(false)
	field.set_physics_process(false)
	var b:=field.battle
	var records:Array=[]
	for mark in [85,135]:
		while b.tick<mark:
			b.input_state(Vector2.ZERO,b.hero.facing)
			b.step()
		var subject:Battle.Unit
		var nearest:=INF
		for u in b.roster:
			if u.hero or u.officer or not u.mounted or u.mount_hp<=0. or not b.active(u): continue
			var d:=u.pos.distance_squared_to(Ground.BRIDGE_VIEW)
			if d<nearest:
				subject=u
				nearest=d
		if subject==null: quit(2);return
		var yaw:=deg_to_rad(-33.)
		var angles:Array=[["line",Ground.BRIDGE_VIEW,22.,yaw]]
		if mark==135:
			angles.append(["reverse",Ground.BRIDGE_VIEW,22.,yaw+PI])
			var forward:=atan2(subject.facing.x,subject.facing.y)
			angles.append(["horse",subject.pos,5.3,forward+.95])
			angles.append(["horse-reverse",subject.pos,5.3,forward+.95+PI])
		for shot:Array in angles:
			_set_view(shot[1],shot[2],shot[3])
			await RenderingServer.frame_post_draw
			var image:=root.get_texture().get_image()
			if image.get_width()!=2560 or image.get_height()!=1600: quit(3);return
			if image.save_jpg(out+"/%s-%03d.jpg"%[shot[0],mark],.945)!=OK: quit(4);return
			records.append({"tick":b.tick,"view":shot[0],"camera":[shot[2],shot[3],shot[1].x,shot[1].y],"actor":subject.id,"xz":[subject.pos.x,subject.pos.y],"stride":subject.stride,"stance":subject.state,"hp":subject.hp,"mount_hp":subject.mount_hp,"hits":Array(b.hits).duplicate(),"losses":Array(b.losses).duplicate(),"ordinary":Array(b.ordinary_counts),"pixels":[image.get_width(),image.get_height()],"scale":root.scaling_3d_scale})
	var file:=FileAccess.open(out+"/field.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(records,"  "))
	file.close()
	print("NATIVE_REMOUNT_WINDOW ",JSON.stringify(records[-1]))
	scene.queue_free()
	await process_frame
	quit()
