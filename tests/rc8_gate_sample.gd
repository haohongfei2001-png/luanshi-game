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
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))
	var scene=load("res://scenes/game.tscn").instantiate()
	root.add_child(scene)
	field=scene.field
	field.set_process(false)
	field.set_physics_process(false)
	field.hud.plan_requested.emit(1)
	field.hud.go.pressed.emit()
	await process_frame
	_advance(490)
	await _snap("gate","gate",34.0,-.89)
	await _snap("fight","ram",19.0,-.65)
	FileAccess.open(directory+"/frames.json",FileAccess.WRITE).store_string(JSON.stringify(shots))
	scene.queue_free()
	await process_frame
	quit(0 if success else 1)
