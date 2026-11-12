extends SceneTree
## Run the same real GUI recorder on both active river-gate revisions.
## It moves the player's camera only. All units, deliveries, blows and casualties
## advance through the 20 Hz controller; exported frames replay at normal speed.
const Field := preload("res://scripts/field/controller.gd")
const Battle := preload("res://scripts/field/battle.gd")
const Ground := preload("res://scripts/field/ground.gd")
var field: Field
var ground_started:=0
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
	if kind=="bank": return Vector2(-35.8,-8.4)
	if kind=="margin": return Vector2(-23.8,13.8)
	if kind=="bridge": return Vector2(Ground.RIVER_X,Ground.crossing(0.0))
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

func _ground_readback(pic: Image,center: Vector2) -> Dictionary:
	var width:=pic.get_width()
	var height:=pic.get_height()
	var silhouettes: Array[Rect2]=[]
	var height_px:=height/field.camera.size
	var b:=field.battle
	for u in b.roster:
		if u.state==Battle.State.ESCAPED: continue
		var foot:=Ground.unit_point(u.before.lerp(u.pos,clampf(field.carry/Battle.DT,0.0,1.0)))
		var a:=field.camera.unproject_position(foot)
		var c:=field.camera.unproject_position(foot+Vector3.UP*(2.85 if u.mounted else 1.94))
		if a.x< -height_px or a.x>width+height_px or a.y< -height_px or a.y>height+height_px: continue
		var box:=Rect2(a,Vector2.ZERO).expand(c).grow(.71*height_px)
		silhouettes.append(box)
	var samples: Array[float]=[]
	var detail: Array[float]=[]
	var footprint:=minf(25.0,field.camera.size*1.1)
	for i in 41:
		for j in 41:
			var p:=center+Vector2((i-20)*footprint/20.0,(j-20)*footprint/20.0)
			if p.x< -50.0 or p.x>42.0 or absf(p.x-Ground.RIVER_X)<7.3: continue
			if p.distance_squared_to(b.ram)<10.4: continue
			var screen:=field.camera.unproject_position(Ground.unit_point(p))
			if screen.x<20 or screen.x>width-120 or screen.y<90 or screen.y>height-100: continue
			var covered:=false
			for box in silhouettes:
				if box.has_point(screen):
					covered=true
					break
			if covered: continue
			var pixel:=pic.get_pixel(roundi(screen.x),roundi(screen.y))
			var y:float=(.2126*pixel.r+.7152*pixel.g+.0722*pixel.b)*255
			samples.append(y)
			var differences:=0.0
			for d:Vector2i in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
				var v:=pic.get_pixel(roundi(screen.x)+d.x,roundi(screen.y)+d.y)
				differences+=absf(y-(.2126*v.r+.7152*v.g+.0722*v.b)*255)
			detail.append(differences*.25)
	samples.sort()
	detail.sort()
	if samples.is_empty(): return {"count":0}
	return {"count":samples.size(),"one_pixel_Y50":snappedf(detail[floori((detail.size()-1)*.50)],.01),
		"one_pixel_Y90":snappedf(detail[floori((detail.size()-1)*.90)],.01),"Y10":snappedf(samples[floori((samples.size()-1)*.10)],.1),
		"Y50":snappedf(samples[floori((samples.size()-1)*.50)],.1),"Y90":snappedf(samples[floori((samples.size()-1)*.90)],.1)}

func _snap(label: String,kind: String,zoom: float,yaw: float) -> void:
	var b:=field.battle
	var point:=_target(kind)
	_view(point,zoom,yaw)
	await RenderingServer.frame_post_draw
	var pic:=root.get_texture().get_image()
	success=pic.save_jpg(directory+"/"+label+".jpg",.95)==OK and success
	var preview:=pic.duplicate() as Image
	preview.resize(896,560,Image.INTERPOLATE_LANCZOS)
	success=preview.save_jpg(directory+"/"+label+"-view.jpg",0.82)==OK and success
	var item:={"label":label,"kind":kind,"tick":b.tick,"center":[point.x,point.y],"yaw":yaw,"zoom":zoom,
		"seed":Battle.SEED,"ordinary":Array(b.ordinary_counts),"officers":Array(b.command_counts),
		"contact":[b.hits[0],b.hits[1]],"losses":[b.losses[0],b.losses[1]],"gate_hp":b.gate_hp,
		"visible":field.view.visible_soldiers,"fighting":field.view.visible_fighting,"close":field.view.high_detail_soldiers,
		"ranks":field.view.rank_soldiers,"window":[pic.get_width(),pic.get_height()],
		"internal_scale":root.scaling_3d_scale,"shadows":field.map.sun.shadow_enabled}
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
	# The orthographic playable ford never exposes the plain world background.
	var flat:=0
	var tested:=0
	for yy in range(110,pic.get_height()-115,11):
		for xx in range(20,pic.get_width()-25,11):
			var reference:=pic.get_pixel(xx,yy)
			var neighbors: Array[Color]=[pic.get_pixel(xx+8,yy),pic.get_pixel(xx,yy+8),pic.get_pixel(xx+8,yy+8)]
			var identical:=true
			for value:Color in neighbors:
				if absf(value.r-reference.r)+absf(value.g-reference.g)+absf(value.b-reference.b)>.008:
					identical=false
			if identical: flat+=1
			tested+=1
	item["flat_pixel_neighborhood_fraction"]=float(flat)/float(tested)
	if label in ["hero","contact","formation","ford"]: item["ground_readback"]=_ground_readback(pic,point)
	item["draw_calls"]=int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	item["primitives"]=int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME))
	item["in_frame_count"]=on_screen.size()
	item["in_frame_ids_sha256"]=Marshalls.raw_to_base64(on_screen.to_byte_array()).sha256_text()
	success=success and field.view.visible_soldiers>=on_screen.size()
	shots.append(item)
	print("RIVER_ART_FRAME "+JSON.stringify(item))

func _cost(label: String,focus: String,zoom: float,yaw: float) -> void:
	_view(_target(focus),zoom,yaw)
	await RenderingServer.frame_post_draw
	var intervals: Array[float]=[]
	for i in 64:
		var start:=Time.get_ticks_usec()
		_advance(field.battle.tick+1)
		field._process(Battle.DT)
		await RenderingServer.frame_post_draw
		if i>=8: intervals.append((Time.get_ticks_usec()-start)*.001)
	var by_time:=intervals.duplicate()
	by_time.sort()
	# Real hosted software-renderer wall intervals; no screenshot readback samples.
	print("WILLOW_COST "+JSON.stringify({"label":label,"window":[1280,800],"draw_frames":intervals,
		"p50_ms":by_time[28],"p95_ms":by_time[53],"p99_ms":by_time[55],"tick":field.battle.tick,
		"hits":Array(field.battle.hits),"ordinary":Array(field.battle.ordinary_counts)}))

func _run() -> void:
	if DisplayServer.get_name()=="headless": quit(1); return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory+"/film"))
	ground_started=Time.get_ticks_msec()
	var scene=load("res://scenes/game.tscn").instantiate()
	root.add_child(scene)
	field=scene.field
	print("MAP_READY_MS ",Time.get_ticks_msec()-ground_started)
	field.set_physics_process(false)
	field.set_process(false)
	var b:=field.battle
	field.hud.plan_requested.emit(1)
	field.hud.go.pressed.emit()
	root.warp_mouse(Vector2(810,416))
	await process_frame
	if not b.started or b.ordinary_counts!=PackedInt32Array([512,512]): quit(1); return
	_advance(8)
	await _snap("hero","hero",6.4,1.27)
	await _snap("saddle","horse",7.8,1.09)
	await _snap("cart","cart",10.0,-.65)
	await _snap("ford","bridge",31.0,-.54)
	await _snap("camp","camp",30.0,-.54)
	_advance(65)
	await _snap("officer","officer",7.8,-1.42)
	await _snap("bowline","archer",8.6,1.12)
	await _snap("ranks","line",51.0,-.576)
	await _snap("contact","line",13.0,-.576)
	await _snap("formation","line",26.0,-.576)
	if "--stills-only" in OS.get_cmdline_user_args():
		var stills:=FileAccess.open(directory+"/frames.json",FileAccess.WRITE)
		stills.store_string(JSON.stringify(shots,"  "))
		stills.close()
		print("SOIL_STILLS_PASS ",b.tick)
		scene.queue_free()
		await process_frame
		quit(0 if success else 1)
		return
	await _cost("contact","line",13.0,-.576)
	await _cost("ford","bridge",31.0,-.54)
	var f:=FileAccess.open(directory+"/frames.json",FileAccess.WRITE)
	f.store_string(JSON.stringify(shots,"  "))
	success=success and b.tick==193 and b.side_size==512 and b.hits[0]+b.hits[1]>0
	print("RIVER_ART_"+("PASS" if success else "FAIL")+" ticks="+str(b.tick)+" seed="+str(Battle.SEED))
	scene.queue_free()
	await process_frame
	quit(0 if success else 1)
