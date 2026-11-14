extends "res://tests/native_chain_film.gd"
## The unchanged fixed-seed opening supplies an early real sword cut with few bodies.
const CLEAR_OUT:="res://artifacts/native-clear-film"

func _view_angle(subject:Battle.Unit) -> float:
	var best:=0.
	var best_score:=INF
	for turn:int in 8:
		var angle:=float(turn)*PI*.25
		field.camera_center=subject.pos
		field.camera.size=6.3
		field.camera_yaw=angle
		field._camera()
		var base:=Ground.unit_point(subject.pos,true)
		var foot:=field.camera.unproject_position(base)
		var chest:=field.camera.unproject_position(base+Vector3.UP)
		var pixels_per_m:=root.get_visible_rect().size.y/6.3
		var score:=0.
		for other:Battle.Unit in field.battle.roster:
			if other.id==subject.id or other.state==Battle.State.ESCAPED: continue
			var p:=Ground.unit_point(other.pos,true)
			if p.distance_squared_to(base)>36.: continue
			if field.camera.global_position.distance_squared_to(p)>=field.camera.global_position.distance_squared_to(base): continue
			var height:=.32 if other.state==Battle.State.DEAD else (2.3 if other.mounted else 1.65)
			var bottom:=field.camera.unproject_position(p)
			var top:=field.camera.unproject_position(p+Vector3.UP*height)
			var half_width:=pixels_per_m*(.7 if other.mounted else .29)
			for probe:Vector2 in [foot,chest]:
				if absf(probe.x-bottom.x)<half_width and probe.y>=top.y-10. and probe.y<=bottom.y+10.:
					score+=3. if probe==foot else 1.
		if score<best_score:
			best_score=score
			best=angle
	return best

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
	for folder:String in [OUT,CLEAR_OUT,CLEAR_OUT+"/frames"]:
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	var scene=await _open_match()
	if scene==null: quit(3);return
	var b:=field.battle
	while b.tick<16:
		b.input_state(Vector2.ZERO,b.hero.facing)
		b.step()
	var selected:Battle.Unit=b.roster[584]
	var yaw:=_view_angle(selected)
	var rows:Array=[]
	for frame:int in 20:
		if frame>0:
			b.input_state(Vector2.ZERO,b.hero.facing)
			b.step()
		var subject:Battle.Unit=b.roster[584]
		_set_view(subject.pos,6.3,yaw)
		await RenderingServer.frame_post_draw
		var captured:=root.get_texture().get_image()
		if captured.get_width()!=2560 or captured.get_height()!=1600: quit(4);return
		captured.save_jpg(CLEAR_OUT+"/frames/frame-%03d.jpg"%frame,.88)
		var instance:=_instance(subject)
		if instance.is_empty(): quit(7);return
		rows.append({"tick":b.tick,"actor":584,"kit":subject.kit,"team":subject.team,"state":subject.state,
			"position":[subject.pos.x,subject.pos.y],"hp":subject.hp,"impacts":subject.impacts,
			"hits":Array(b.hits).duplicate(),"losses":Array(b.losses).duplicate(),
			"ordinary":Array(b.ordinary_counts).duplicate(),"facing":[subject.facing.x,subject.facing.y],
			"camera":[subject.pos.x,subject.pos.y,6.3,yaw],"instance":instance})
		if b.tick in [22,27,34]:
			_set_view(Ground.BRIDGE_VIEW,22.,deg_to_rad(-33.))
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_jpg(CLEAR_OUT+"/normal-%03d.jpg"%b.tick,.78)
	FileAccess.open(CLEAR_OUT+"/sequence.json",FileAccess.WRITE).store_string(JSON.stringify({
		"seed":Battle.SEED,"frames":20,"fps":20,"seconds":1.0,"size":[2560,1600],"scale":root.scaling_3d_scale,
		"selection":{"actor":584,"start":16,"windup":22,"hit":27,"resume":34,"yaw":yaw},"index":rows},"  "))
	print("NATIVE_CLEAR_FILM ",JSON.stringify(rows[0])," last=",JSON.stringify(rows[-1]))
	scene.queue_free()
	await process_frame
	quit()
