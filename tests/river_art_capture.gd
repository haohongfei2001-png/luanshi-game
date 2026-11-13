extends SceneTree
## Run this same recorder on the previous playable checkout and the new shipping scene.
## It moves the player's camera only. All units, deliveries, blows and casualties
## advance through the 20 Hz controller; exported frames replay at normal speed.
const Field := preload("res://scripts/field/controller.gd")
const Battle := preload("res://scripts/field/battle.gd")
const Ground := preload("res://scripts/field/ground.gd")
var field: Field
var success:=true
var directory:="res://artifacts/river-art"
var shots: Array=[]

func _initialize() -> void:
	_run.call_deferred()

func _advance(tick: int) -> void:
	while field.battle.tick<tick and field.battle.result=="" and not field.paused:
		field._physics_process(Battle.DT)
	if field.battle.tick!=tick:
		push_error("Live battlefield stopped before tick %d" % tick)
		success=false

func _target(kind: String) -> Vector2:
	var b:=field.battle
	if kind.begins_with("archer-"):
		for u in b.roster:
			if u.kit!=5 or u.team!=0 or u.mounted: continue
			if kind=="archer-carry" and u.state==Battle.State.MARCH: return u.pos
			var p:=1.-u.timer/maxf(u.duration,.001)
			if kind=="archer-draw" and u.state==Battle.State.WINDUP and p>.48 and p<.90: return u.pos
			if kind=="archer-loose" and u.state==Battle.State.RECOVER and p<.35: return u.pos
		return Vector2.INF
	if kind=="hero": return b.hero.pos
	if kind=="horse": return b.vehicle_pos[1]
	if kind=="cart": return b.vehicle_pos[2]
	if kind=="gate": return Ground.GATE
	if kind=="camp": return Vector2(-66,-19)
	if kind=="bridge": return Vector2(Ground.RIVER_X,Ground.crossing(0.0))
	if kind=="bank": return Vector2(-35.8,-8.4)
	if kind=="margin": return Vector2(-23.8,13.8)
	if kind=="ram": return b.ram
	if kind=="officer":
		for u in b.roster:
			if u.officer and u.team==1 and b.active(u): return u.pos
	if kind=="archer":
		for u in b.roster:
			if u.kit==5 and u.state in [Battle.State.RECOVER,Battle.State.WINDUP]: return u.pos
	if kind=="line":
		for u in b.roster:
			if u.team==0 and not u.officer and u.state in [Battle.State.WINDUP,Battle.State.RECOVER] and u.target>=0:
				return (u.pos+b.roster[u.target].pos)*.5
	return Vector2(1,-16)

func _view(point: Vector2,zoom: float,yaw: float) -> void:
	field.camera_yaw=yaw
	field.camera.size=zoom
	field.pan_to(point)
	field._process(Battle.DT)

func _snap(label: String,kind: String,zoom: float,yaw: float) -> void:
	var b:=field.battle
	var point:=_target(kind)
	_view(point,zoom,yaw)
	await RenderingServer.frame_post_draw
	var pic:=root.get_texture().get_image()
	success=pic.save_png(directory+"/"+label+".png")==OK and success
	# Keep the older lightweight review view available beside the original pixels.
	success=pic.save_jpg(directory+"/"+label+".jpg",.95)==OK and success
	var item:={"label":label,"kind":kind,"tick":b.tick,"center":[point.x,point.y],"yaw":yaw,"zoom":zoom,
		"hero_state":int(b.hero.state),"hero_kit":b.hero.kit,"hero_slot":b.hero.move_slot,
		"seed":Battle.SEED,"ordinary":Array(b.ordinary_counts),"officers":Array(b.command_counts),
		"contact":[b.hits[0],b.hits[1]],"losses":[b.losses[0],b.losses[1]],"gate_hp":b.gate_hp,
		"visible":field.view.visible_soldiers,"fighting":field.view.visible_fighting,"close":field.view.high_detail_soldiers,
		"ranks":field.view.rank_soldiers,"window":[pic.get_width(),pic.get_height()],
		"internal_scale":root.scaling_3d_scale,"msaa_3d":root.msaa_3d,"screen_space_aa":root.screen_space_aa,
		"shadows":field.map.sun.shadow_enabled}
	# Compare physically on-screen identities between versions. The old rotated
	# world AABB also submitted many soldiers wholly outside the camera corners.
	var on_screen:=PackedInt32Array()
	var canvas:=root.get_visible_rect()
	for u in b.roster:
		if u.hero or u.officer or u.state==Battle.State.ESCAPED: continue
		var foot:=Ground.unit_point(u.before.lerp(u.pos,clampf(field.carry/Battle.DT,0,1)))
		if u.mounted: foot.y+=.8
		var projected:=field.camera.unproject_position(foot+Vector3.UP*.9)
		if canvas.has_point(projected): on_screen.append(u.id)
	item["in_frame_count"]=on_screen.size()
	item["in_frame_ids_sha256"]=Marshalls.raw_to_base64(on_screen.to_byte_array()).sha256_text()
	success=success and field.view.visible_soldiers>=on_screen.size()
	shots.append(item)
	print("RIVER_ART_FRAME "+JSON.stringify(item))

func _run() -> void:
	if DisplayServer.get_name()=="headless": quit(1); return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory+"/film"))
	var scene=load("res://scenes/game.tscn").instantiate()
	root.add_child(scene)
	field=scene.field
	field.set_physics_process(false)
	field.set_process(false)
	var b:=field.battle
	field.hud.plan_requested.emit(1)
	field.hud.go.pressed.emit()
	root.warp_mouse(Vector2(810,416))
	await process_frame
	if not b.started or b.ordinary_counts!=PackedInt32Array([512,512]): quit(1); return
	_advance(8)
	await _snap("carry","archer-carry",6.7,1.35)
	await _snap("carry-side","archer-carry",6.7,-1.12)
	await _snap("hero","hero",6.4,1.27)
	await _snap("saddle","horse",7.8,1.09)
	await _snap("cart","cart",10.0,-.65)
	await _snap("ford","bridge",31.0,-.54)
	await _snap("bank","bank",17.0,-.54)
	await _snap("margin","margin",23.0,-.64)
	await _snap("camp","camp",30.0,-.54)
	# A normal-scale input sample, using the same button path as play.
	_view(b.hero.pos,22.0,-.576)
	field._submit_attack(0)
	_advance(11)
	success=success and b.hero.state in [Battle.State.WINDUP,Battle.State.RECOVER]
	await _snap("player-action","hero",22.0,-.576)
	var found={}
	for sample_tick in range(12,66):
		_advance(sample_tick)
		for action: String in ["draw","loose"]:
			if found.has(action): continue
			var point:=_target("archer-"+action)
			if not point.is_finite(): continue
			await _snap(action,"archer-"+action,6.8,1.35)
			await _snap(action+"-side","archer-"+action,6.8,-1.12)
			found[action]=true
	_advance(65)
	if found.size()!=2:
		push_error("No actual bow draw/release found in battle")
		success=false
	await _snap("officer","officer",7.8,-1.42)
	await _snap("bowline","archer",8.6,1.12)
	await _snap("ranks","line",51.0,-.576)
	await _snap("contact","line",13.0,-.576)
	await _snap("formation","line",26.0,-.576)
	var start:=_target("line")
	var initial_hits: int=b.hits[0]+b.hits[1]
	for i in 80:
		_advance(66+i*2)
		var point:=start.lerp(_target("line"),.22*smoothstep(0,79,i))
		_view(point,lerpf(13.0,22.0,smoothstep(0,79,i)),-.576)
		await RenderingServer.frame_post_draw
		var shot:=root.get_texture().get_image()
		success=shot.save_jpg("%s/film/frame-%03d.jpg"%[directory,i],.88)==OK and success
	_advance(490)
	await _snap("siege","ram",19.0,-.65)
	await _snap("gate","gate",34.0,-.89)
	var f:=FileAccess.open(directory+"/frames.json",FileAccess.WRITE)
	f.store_string(JSON.stringify(shots,"  "))
	success=success and b.hits[0]+b.hits[1]>initial_hits and b.tick==490 and b.side_size==512
	print("RIVER_ART_"+("PASS" if success else "FAIL")+" ticks="+str(b.tick)+" seed="+str(Battle.SEED))
	scene.queue_free()
	await process_frame
	quit(0 if success else 1)
