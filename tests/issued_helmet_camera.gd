extends "res://tests/field_contact_window.gd"

var samples: Array=[]
var spear_id: int=-1
const TAKE := "res://artifacts/helmets"

func _actor_view(label: String, u: Battle.Unit, zoom: float, bearing: float) -> void:
	var b:=field.battle
	field.carry=.65*Battle.DT
	var pos:=u.before.lerp(u.pos,.65)
	var yaw:=atan2(u.facing.x,u.facing.y)+bearing
	_view(pos,zoom,yaw)
	await RenderingServer.frame_post_draw
	var shot:=root.get_texture().get_image()
	success=(shot.save_png(TAKE+"/"+label+".png")==OK and success)
	var factor:=Vector2(shot.get_size())/root.get_visible_rect().size
	var ground:=Ground.unit_point(pos)
	var stature:=.966+.0085*((u.id*7+u.squad*5)%9)
	var head:=field.camera.unproject_position(ground+Vector3.UP*1.65*stature)*factor
	var feet:=field.camera.unproject_position(ground)*factor
	var seen:=PackedInt32Array()
	for other in b.roster:
		if other.hero or other.officer: continue
		var base:=Ground.unit_point(other.before.lerp(other.pos,.65))+Vector3.UP*(1.58+(.8 if other.mounted else .0))
		if root.get_visible_rect().has_point(field.camera.unproject_position(base)):
			seen.append(other.id)
	var row:={"label":label,"kit":u.kit,"actor":u.id,"team":u.team,"state":u.state,"tick":b.tick,
		"hp":u.hp,"target":u.target,"blocked_hits":b.blocked_hits,"touch":u.contact_tick,
		"hits":Array(b.hits),"pos":[u.pos.x,u.pos.y],"facing":[u.facing.x,u.facing.y],"camera":[zoom,yaw],
		"ordinary":Array(b.ordinary_counts),"seed":Battle.SEED,"actors":Marshalls.raw_to_base64(seen.to_byte_array()).sha256_text(),
		"head":[head.x,head.y],"feet":[feet.x,feet.y],"seen":seen.size(),"size":[shot.get_width(),shot.get_height()],
		"lod":int(field.view.lod_by_id[u.id]),"internal_scale":root.scaling_3d_scale}
	samples.append(row)
	print("HELMET_WINDOW "+JSON.stringify(row))

func _run() -> void:
	if DisplayServer.get_name()=="headless": quit(1); return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(TAKE))
	var shell=load("res://scenes/game.tscn").instantiate()
	root.add_child(shell)
	field=shell.field
	field.set_physics_process(false)
	field.set_process(false)
	var b:=field.battle
	field.hud.plan_requested.emit(1)
	field.hud.go.pressed.emit()
	root.warp_mouse(Vector2(810,416))
	await process_frame
	if not b.started or b.ordinary_counts!=PackedInt32Array([512,512]):
		quit(1); return
	for tick in range(1,83):
		_step_neutral()
		if b.tick!=tick: success=false; break
		if tick==8:
			# An actual infantryman in the field. Select with the same rule on both trees.
			var spare:=-INF
			for u in b.roster:
				if u.team!=0 or u.officer or u.hero or u.mounted or u.wall_post or u.kit!=3 or not b.active(u): continue
				if u.pos.distance_squared_to(u.before)<.0002: continue
				var near:=INF
				for v in b.roster:
					if v.id!=u.id: near=minf(near,u.pos.distance_squared_to(v.pos))
				if near>spare:
					spare=near
					spear_id=u.id
			if spear_id<0: success=false; break
			var pike:=b.roster[spear_id]
			await _actor_view("spear-front",pike,7.8,.85)
			await _actor_view("spear-back",pike,7.8,2.40)
			await _actor_view("spear-22m",pike,22.,1.12)
			await _actor_view("spear-42m",pike,42.,1.12)
		if tick==79:
			var shield:=b.roster[70]
			success=success and shield.kit==7 and shield.contact_tick==79 and shield.contact_blocked
			await _actor_view("shield-front",shield,7.8,.74)
			await _actor_view("shield-back",shield,7.8,2.42)
			await _actor_view("shield-22m",shield,22.,1.28)
			await _actor_view("shield-42m",shield,42.,1.28)
		if tick==82:
			await _actor_view("shield-after",b.roster[70],7.8,1.51)
	var f:=FileAccess.open(TAKE+"/receipts.json",FileAccess.WRITE)
	f.store_string(JSON.stringify(samples,"  "))
	success=success and samples.size()==9
	print("HELMET_TEST_"+("PASS" if success else "FAIL")+" spear="+str(spear_id)+" guard=70")
	shell.queue_free()
	await process_frame
	quit(0 if success else 1)
