extends "res://tests/bridgehead_window.gd"
## Camera-only examination of one unchanged naturally occurring 512 v 512 spear thrust.
const FILM_OUT:="res://artifacts/native-pike-film"

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

func _instance(subject:Battle.Unit) -> Dictionary:
	var tier:int=field.view.lod_by_id[subject.id]
	var batch=field.view.groups[field.view._key(subject)+30*tier]
	var wanted:=subject.before.lerp(subject.pos,.82)
	var nearest:=-1
	var distance:=INF
	for i:int in batch.used:
		var origin:Vector3=batch.mesh.get_instance_transform(i).origin
		var d2:=Vector2(origin.x,origin.z).distance_squared_to(wanted)
		if d2<distance:
			distance=d2
			nearest=i
	if nearest<0 or distance>.0001: return {}
	var transform:Transform3D=batch.mesh.get_instance_transform(nearest)
	var data:Color=batch.mesh.get_instance_custom_data(nearest)
	var columns:Array=[]
	for column:Vector3 in [transform.basis.x,transform.basis.y,transform.basis.z,transform.origin]:
		columns.append([column.x,column.y,column.z])
	return {"tier":tier,"custom":[data.r,data.g,data.b,data.a],"transform":columns,"matching_origin_error_squared":distance}


func _run() -> void:
	for folder:String in [OUT,FILM_OUT,FILM_OUT+"/frames"]:
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	var scene=await _open_match()
	if scene==null: quit(3);return
	var b:=field.battle
	while b.tick<10:
		b.input_state(Vector2.ZERO,b.hero.facing)
		b.step()
	var rows:Array=[]
	var center:=Vector2(37.76799774,-10.93197441)
	var yaw:=-PI*.25
	for frame:int in 23:
		if frame>0:
			b.input_state(Vector2.ZERO,b.hero.facing)
			b.step()
		var subject:Battle.Unit=b.roster[548]
		_set_view(center,6.3,yaw)
		await RenderingServer.frame_post_draw
		var captured:=root.get_texture().get_image()
		if captured.get_width()!=2560 or captured.get_height()!=1600: quit(4);return
		captured.save_jpg(FILM_OUT+"/frames/frame-%03d.jpg"%frame,.88)
		var instance:=_instance(subject)
		if instance.is_empty(): quit(7);return
		rows.append({"tick":b.tick,"actor":548,"kit":subject.kit,"team":subject.team,"state":subject.state,
			"timer":subject.timer,"duration":subject.duration,"move_slot":subject.move_slot,
			"position":[subject.pos.x,subject.pos.y],"hp":subject.hp,"impacts":subject.impacts,
			"hits":Array(b.hits).duplicate(),"losses":Array(b.losses).duplicate(),
			"ordinary":Array(b.ordinary_counts).duplicate(),"facing":[subject.facing.x,subject.facing.y],
			"camera":[center.x,center.y,6.3,yaw],"instance":instance})
		if b.tick in [16,21,31]:
			_set_view(center,22.,yaw)
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_jpg(FILM_OUT+"/normal-%03d.jpg"%b.tick,.78)
		if b.tick==21:
			_set_view(center,22.,yaw+PI)
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_jpg(FILM_OUT+"/reverse-%03d.jpg"%b.tick,.78)
	FileAccess.open(FILM_OUT+"/sequence.json",FileAccess.WRITE).store_string(JSON.stringify({
		"seed":Battle.SEED,"frames":23,"fps":20,"seconds":1.15,"size":[2560,1600],"scale":root.scaling_3d_scale,
		"selection":{"actor":548,"start":10,"windup":16,"hit":21,"resume":31,"yaw":yaw},"index":rows},"  "))
	print("NATIVE_PIKE_FILM ",JSON.stringify(rows[0])," last=",JSON.stringify(rows[-1]))
	scene.queue_free()
	await process_frame
	quit()
