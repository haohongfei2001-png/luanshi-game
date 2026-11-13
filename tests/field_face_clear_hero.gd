extends "res://tests/field_contact_window.gd"
## Move only the camera in the shipping battle. Record logical-to-native projection per frame.
const OUTPUT_DIR := "res://artifacts/face-lane"

func _picture(label: String,u: Battle.Unit,size: float,turn: float) -> void:
	var p:=u.before.lerp(u.pos,.85)
	var bearing:=atan2(u.facing.x,u.facing.y)+turn
	field.carry=.85*Battle.DT
	_view(p,size,bearing)
	await RenderingServer.frame_post_draw
	var picture:=root.get_texture().get_image()
	success=picture.save_png(OUTPUT_DIR+"/"+label+".png")==OK and success
	var factor:=Vector2(picture.get_size())/root.get_visible_rect().size
	var stride_scale:=1.07 if u.hero or u.officer else (1.0 if u.mounted else .966+.0085*((u.id*7+u.squad*5)%9))
	var top:=Ground.unit_point(p)+Vector3.UP*(1.565*stride_scale+(.73 if u.mounted else 0.))
	var post:=field.camera.unproject_position(top)*factor
	var roster:=PackedInt32Array()
	for other in field.battle.roster:
		if other.hero or other.officer: continue
		var feet:=Ground.unit_point(other.before.lerp(other.pos,.85))
		var center:=feet+Vector3.UP*(.9+(.8 if other.mounted else 0.))
		if root.get_visible_rect().has_point(field.camera.unproject_position(center)): roster.append(other.id)
	var row:={"name":label,"id":u.id,"kit":u.kit,"hero":u.hero,"officer":u.officer,"mounted":u.mounted,
		"ordinary":Array(field.battle.ordinary_counts),"officers":Array(field.battle.command_counts),"seed":Battle.SEED,
		"tick":field.battle.tick,"state":u.state,"target":u.target,"ammo":u.ammo,"hits":Array(field.battle.hits),
		"visible_ids":Marshalls.raw_to_base64(roster.to_byte_array()).sha256_text(),
		"post":[post.x,post.y],"camera":[size,bearing,p.x,p.y],"scale":root.scaling_3d_scale,
		"pixels":[picture.get_width(),picture.get_height()],"shadows":field.map.sun.shadow_enabled,"lod":int(field.view.lod_by_id[u.id])}
	shots.append(row)

func _run() -> void:
	if DisplayServer.get_name()=="headless": quit(1);return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	var scene=load("res://scenes/game.tscn").instantiate()
	root.add_child(scene)
	field=scene.field
	field.set_physics_process(false)
	field.set_process(false)
	field.hud.plan_requested.emit(1)
	field.hud.go.pressed.emit()
	root.warp_mouse(Vector2(855,440))
	await process_frame
	var b:=field.battle
	if not b.started or b.ordinary_counts!=PackedInt32Array([512,512]): quit(2);return
	var origin:=b.hero.pos
	var gap:=-1.
	# Use the normal A/Shift actions to step out of the overlapping polearms.
	Input.action_press("move_left")
	Input.action_press("field_sprint")
	for t in range(90):
		_step_neutral()
		var nearest:=INF
		for other in b.roster:
			if other.id!=b.hero.id and b.active(other):
				nearest=minf(nearest,b.hero.pos.distance_to(other.pos))
		if nearest>2.8 and b.hero.pos.distance_to(origin)>4.0:
			gap=nearest
			break
	Input.action_release("move_left")
	Input.action_release("field_sprint")
	_step_neutral()
	success=success and b.active(b.hero) and b.hero.pos.distance_to(origin)>4.
	await _picture("hero-front",b.hero,5.,.03)
	await _picture("hero-quarter",b.hero,5.,-.68)
	await _picture("hero-normal",b.hero,22.,.03)
	var record:=FileAccess.open(OUTPUT_DIR+"/poses.json",FileAccess.WRITE)
	record.store_string(JSON.stringify({"travel":b.hero.pos.distance_to(origin),"gap":gap,"hp":b.hero.hp,"shots":shots},"  "))
	record.close()
	print("FACE_LANE ",success," gap=",gap," walked=",b.hero.pos.distance_to(origin))
	scene.queue_free()
	await process_frame
	quit(0 if success else 1)
