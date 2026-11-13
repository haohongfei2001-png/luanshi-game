extends "res://tests/field_contact_window.gd"
## Move only the camera in the shipping battle. Record logical-to-native projection per frame.
const OUTPUT_DIR := "res://artifacts/face-review"

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
	root.warp_mouse(Vector2(810,416))
	await process_frame
	var b:=field.battle
	if not b.started or b.ordinary_counts!=PackedInt32Array([512,512]): quit(2);return
	for t in range(32): _step_neutral()
	var archer:=b.roster[94]
	if b.tick!=32 or archer.kit!=5 or archer.target!=582: quit(3);return
	await _picture("bow-draw",archer,4.,-.81)
	await _picture("bow",archer,5.,-.55)
	await _picture("bow-normal",archer,22.,-.55)
	await _picture("player",b.hero,5.,.21)
	await _picture("player-normal",b.hero,22.,.21)
	var officer: Battle.Unit
	var best:=-1.
	for u in b.roster:
		if not u.officer or u.team!=1 or not b.active(u): continue
		var nearest:=100.0
		for v in b.roster:
			if v.id!=u.id: nearest=minf(nearest,u.pos.distance_squared_to(v.pos))
		if nearest>best:
			best=nearest
			officer=u
	if officer==null: quit(4);return
	await _picture("officer",officer,5.,-.32)
	await _picture("officer-normal",officer,22.,-.32)
	for t in range(4): _step_neutral()
	await _picture("loose",archer,5.,-.53)
	success=success and archer.ammo==18
	var record:=FileAccess.open(OUTPUT_DIR+"/poses.json",FileAccess.WRITE)
	record.store_string(JSON.stringify(shots,"  "))
	record.close()
	print("FACE_SHELL ",success," bow=",archer.id," officer=",officer.id," hero=",b.hero.id)
	scene.queue_free()
	await process_frame
	quit(0 if success else 1)
