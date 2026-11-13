extends "res://tests/field_contact_window.gd"

const TAKE := "res://artifacts/grips-bow"
var rows: Array=[]

func _view_actor(label: String,u: Battle.Unit,size: float,turn: float,film: bool=false) -> void:
	var pos:=u.before.lerp(u.pos,.85)
	field.carry=.85*Battle.DT
	var bearing:=atan2(u.facing.x,u.facing.y)+turn
	_view(pos,size,bearing)
	await RenderingServer.frame_post_draw
	var shot:=root.get_texture().get_image()
	if film:
		success=shot.save_jpg(TAKE+"/film/"+label+".jpg",.91)==OK and success
	else:
		success=shot.save_png(TAKE+"/"+label+".png")==OK and success
	var b:=field.battle
	var scale_px:=Vector2(shot.get_size())/root.get_visible_rect().size
	var feet:=field.camera.unproject_position(Ground.unit_point(pos))*scale_px
	var head:=field.camera.unproject_position(Ground.unit_point(pos)+Vector3.UP*1.60)*scale_px
	var tracks:=PackedInt32Array()
	for other in b.roster:
		if other.hero or other.officer: continue
		var foot:=Ground.unit_point(other.before.lerp(other.pos,.85))+Vector3.UP*(.9+(.8 if other.mounted else 0.))
		if root.get_visible_rect().has_point(field.camera.unproject_position(foot)): tracks.append(other.id)
	var row:={"frame":label,"tick":b.tick,"seed":Battle.SEED,"ordinary":Array(b.ordinary_counts),"camera":[size,bearing,pos.x,pos.y],
		"state":u.state,"target":u.target,"timer":u.timer,"duration":u.duration,"kit":u.kit,"id":u.id,"slot":u.move_slot,"ammo":u.ammo,
		"shots":b.arrow_count,"hits":Array(b.hits),"post":[head.x,head.y,feet.x,feet.y],"pixels":[shot.get_width(),shot.get_height()],
		"in_view":Marshalls.raw_to_base64(tracks.to_byte_array()).sha256_text(),"scale":root.scaling_3d_scale,"lod":int(field.view.lod_by_id[u.id])}
	rows.append(row)

func _run() -> void:
	if DisplayServer.get_name()=="headless": quit(1);return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(TAKE+"/film"))
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
	var archer: Battle.Unit
	var started:=-1
	var ammo:=-1
	var released:=-1
	var plate:=false
	for tick in range(1,160):
		_step_neutral()
		if b.tick!=tick: success=false;break
		if archer==null and tick>=23:
			var best:=-1.
			for u in b.roster:
				if u.kit!=5 or u.hero or u.officer or u.mounted or u.wall_post or u.team!=0 or u.ammo<1: continue
				if u.state!=Battle.State.WINDUP or u.timer<u.duration-.061 or u.move_slot!=0: continue
				var nearest:=99.
				for v in b.roster:
					if v.id!=u.id: nearest=minf(nearest,u.pos.distance_squared_to(v.pos))
				if nearest>best:
					best=nearest
					archer=u
			if archer!=null:
				started=tick
				ammo=archer.ammo
				await _view_actor("set",archer,7.8,1.91)
		if archer==null: continue
		var frame:=tick-started
		await _view_actor("%03d"%frame,archer,15.,1.91,true)
		if not plate and archer.state==Battle.State.WINDUP and archer.timer<=archer.duration*.35:
			plate=true
			await _view_actor("draw",archer,7.8,1.91)
			await _view_actor("draw-front",archer,7.8,-.81)
			await _view_actor("fingers",archer,4.0,-.81)
			await _view_actor("fingers-side",archer,4.0,1.91)
			for other in b.roster:
				if other.team!=1 or other.kit!=3 or other.hero or other.officer or other.mounted or not b.active(other): continue
				await _view_actor("enemy-haft",other,6.2,-.87)
				break
			await _view_actor("draw-normal",archer,22.,1.91)
			await _view_actor("draw-back",archer,9.1,2.91)
			await _view_actor("ranks",archer,42.,1.91)
		if released==-1 and archer.state==Battle.State.RECOVER and archer.ammo==ammo-1:
			var owned:=false
			for shot in b.shots:
				if shot.source==archer.id: owned=true
			if owned:
				released=tick
				await _view_actor("loose",archer,7.8,1.91)
		if released>=0 and tick==released+10: break
	success=success and archer!=null and plate and released>started and b.ordinary_counts==PackedInt32Array([512,512])
	var f:=FileAccess.open(TAKE+"/states.json",FileAccess.WRITE)
	f.store_string(JSON.stringify(rows,"  "))
	print("ARCHER_WINDOW ",success," actor ",archer.id if archer!=null else -1," draw ",started," release ",released," frames ",rows.size())
	scene.queue_free()
	await process_frame
	quit(0 if success else 1)
