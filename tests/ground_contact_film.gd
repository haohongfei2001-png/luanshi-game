extends "res://tests/bridgehead_window.gd"
## A known casualty from the unchanged seed61112 roster, followed through the full fall.
const REST_OUT:="res://artifacts/grounded-equipment-film"

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

func _rest_record(b:Battle,u:Battle.Unit,view:String) -> Dictionary:
	var at:=field.camera.unproject_position(Ground.unit_point(u.pos,b.bridgehead))
	var pixels:=Vector2(root.get_texture().get_size())/root.get_visible_rect().size
	return {"tick":b.tick,"actor":u.id,"kit":u.kit,"team":u.team,"view":view,"mounted":u.mounted,
		"state":u.state,"hp":u.hp,"timer":u.timer,"duration":u.duration,"lost_tick":u.lost_tick,
		"xz":[u.pos.x,u.pos.y],"floor_pixel":[at.x*pixels.x,at.y*pixels.y],"facing":[u.facing.x,u.facing.y],"impacts":u.impacts,"received":u.received,
		"hits":Array(b.hits).duplicate(),"losses":Array(b.losses).duplicate(),
		"ordinary":Array(b.ordinary_counts).duplicate(),"scale":root.scaling_3d_scale}

func _save_rest_frame(name:String,center:Vector2,size:float,yaw:float) -> void:
	_set_view(center,size,yaw)
	await RenderingServer.frame_post_draw
	var picture:=root.get_texture().get_image()
	if picture.get_width()!=2560 or picture.get_height()!=1600: quit(10);return
	if picture.save_jpg(REST_OUT+"/"+name+".jpg",.88 if name.begins_with("normal/") else .78)!=OK: quit(11);return

func _run() -> void:
	for folder:String in [OUT,REST_OUT,REST_OUT+"/normal"]:
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	var scene=await _open_match()
	if scene==null: quit(1);return
	var b:=field.battle
	while b.tick<44:
		b.input_state(Vector2.ZERO,b.hero.facing)
		b.step()
	var subject:Battle.Unit=b.roster[80]
	if subject.kit!=0 or subject.hp<=0. or subject.hero or subject.officer: quit(2);return
	var rows:Array=[]
	var mounted_rows:Array=[]
	for frame:int in 32:
		if frame>0:
			b.input_state(Vector2.ZERO,b.hero.facing)
			b.step()
		await _save_rest_frame("normal/frame-%03d"%frame,Ground.BRIDGE_VIEW,22.,deg_to_rad(-33.))
		rows.append(_rest_record(b,subject,"normal"))
		if b.tick in [44,48,52,56,62,75]:
			await _save_rest_frame("side-%03d"%b.tick,subject.pos,6.3,0.)
	await _save_rest_frame("back-075",subject.pos,6.3,PI)
	if subject.hp>0. or subject.lost_tick!=48 or subject.timer>.0001: quit(3);return
	var mounted_id:=-1
	while b.tick<160:
		b.input_state(Vector2.ZERO,b.hero.facing)
		b.step()
		if b.tick<112: continue
		var nearest:=INF
		for u:Battle.Unit in b.roster:
			if not u.mounted or u.hp<=0. or u.kit!=1 or u.state not in [Battle.State.WINDUP,Battle.State.RECOVER]: continue
			var distance:=u.pos.distance_squared_to(Ground.BRIDGE_VIEW)
			if distance<nearest:
				nearest=distance
				mounted_id=u.id
		if mounted_id>=0: break
	if mounted_id<0: quit(4);return
	var rider:Battle.Unit=b.roster[mounted_id]
	await _save_rest_frame("seated-attack-side",rider.pos,6.3,0.)
	await _save_rest_frame("seated-attack-line",Ground.BRIDGE_VIEW,22.,deg_to_rad(-33.))
	mounted_rows.append(_rest_record(b,rider,"seated"))
	var mounted_officers:=0
	for u:Battle.Unit in b.roster:
		if u.mounted and u.officer: mounted_officers+=1
	var f:=FileAccess.open(REST_OUT+"/sequence.json",FileAccess.WRITE)
	f.store_string(JSON.stringify({"frames":32,"fps":20,"duration":1.6,"size":[2560,1600],"seed":Battle.SEED,
		"normal_camera":[Ground.BRIDGE_VIEW.x,Ground.BRIDGE_VIEW.y,22.,deg_to_rad(-33.)],
		"index":rows,"mounted":mounted_rows,"mounted_officers_in_this_roster":mounted_officers,
		"kind":"real consecutive game steps at original speed; no realtime FPS measurement"},"  "))
	f.close()
	print("GROUNDED_EQUIPMENT_MOTION ",JSON.stringify(rows[0])," terminal=",JSON.stringify(rows[-1]),
		" seated=",JSON.stringify(mounted_rows))
	scene.queue_free()
	await process_frame
	quit()
