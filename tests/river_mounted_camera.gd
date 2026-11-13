extends SceneTree
## The rider is an actual cavalry actor from the river-gate roster. The camera
## follows its position and facing; the same match and inputs run on both trees.
const Field := preload("res://scripts/field/controller.gd")
const Battle := preload("res://scripts/field/battle.gd")
const Ground := preload("res://scripts/field/ground.gd")
var field: Field
var snapshots: Array = []
var rider_id := -1
var failed := false
var directory := "res://artifacts/river-mounted"
func _initialize() -> void:
	_run.call_deferred()

func _advance(to_tick: int) -> void:
	while field.battle.tick < to_tick and field.battle.result.is_empty():
		field._physics_process(Battle.DT)
	if field.battle.tick != to_tick: failed = true

func _view(point: Vector2, zoom: float, angle: float) -> void:
	field.camera_yaw=angle
	field.camera.size=zoom
	field.pan_to(point)
	field._process(0.)

func _snap(label: String, point: Vector2, zoom: float, angle: float, id: int) -> void:
	_view(point,zoom,angle)
	await RenderingServer.frame_post_draw
	var pic:=root.get_texture().get_image()
	if pic.save_png(directory+"/"+label+".png")!=OK: failed=true
	var b:=field.battle
	var at:=field.camera.unproject_position(Ground.unit_point(point)+Vector3.UP*1.18)
	var heading: Vector2=b.riding_heading if id<0 else b.roster[id].facing
	var muzzle: Vector2=point+heading*1.16
	var nose:=field.camera.unproject_position(Ground.unit_point(muzzle)+Vector3.UP*1.58)
	# canvas_items keeps input and unprojection in design coordinates. The
	# saved image is in actual window pixels, including on a HiDPI target.
	var scale_xy:=Vector2(pic.get_size())/root.get_visible_rect().size
	at*=scale_xy
	nose*=scale_xy
	var rump: Vector2=point-heading*.61
	var chest: Vector2=point+heading*.32
	var at_rump: Vector2=field.camera.unproject_position(Ground.unit_point(rump)+Vector3.UP*1.17)*scale_xy
	var at_shoulder: Vector2=field.camera.unproject_position(Ground.unit_point(chest)+Vector3.UP*1.12)*scale_xy
	snapshots.append({"rump_pixel":[at_rump.x,at_rump.y],"shoulder_pixel":[at_shoulder.x,at_shoulder.y],"label":label,"tick":b.tick,"ordinary":Array(b.ordinary_counts),"actor":id,
		"pos":[point.x,point.y],"facing":[heading.x,heading.y],"center_pixel":[at.x,at.y],
		"muzzle_pixel":[nose.x,nose.y],"zoom":zoom,"yaw":angle,"hits":Array(b.hits),
		"losses":Array(b.losses),"visible":field.view.visible_soldiers,"width":pic.get_width(),
		"height":pic.get_height(),"scale":root.scaling_3d_scale,"seed":Battle.SEED})

func _run() -> void:
	if DisplayServer.get_name()=="headless":
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory+"/film"))
	var scene=load("res://scenes/game.tscn").instantiate()
	root.add_child(scene)
	field=scene.field
	field.set_process(false)
	field.set_physics_process(false)
	var b:=field.battle
	field.hud.plan_requested.emit(1)
	field.hud.go.pressed.emit()
	await process_frame
	if not b.started or b.ordinary_counts!=PackedInt32Array([512,512]):
		quit(1)
		return
	_advance(8)
	# Choose an unobstructed actively moving flank rider once, then preserve ID.
	var best:=-INF
	for u in b.roster:
		if not u.mounted or not b.active(u) or u.pos.distance_squared_to(u.before)<.001: continue
		var closest:=100.
		for other in b.roster:
			if other.id!=u.id: closest=minf(closest,u.pos.distance_squared_to(other.pos))
		var score:=closest
		if score>best:
			best=score
			rider_id=u.id
	if rider_id<0:
		push_error("Missing live flank rider")
		quit(1)
		return
	var rider: Battle.Unit=b.roster[rider_id]
	var yaw:=atan2(rider.facing.x,rider.facing.y)
	await _snap("saddle-standing",b.vehicle_pos[1],6.2,.86,-1)
	await _snap("quiet-side",b.vehicle_pos[1],7.1,1.62,-1)
	await _snap("moving-three-quarter",rider.pos,7.6,yaw+.74,rider.id)
	await _snap("moving-profile",rider.pos,7.6,yaw+1.58,rider.id)
	await _snap("rider-opposite",rider.pos,7.6,yaw-1.53,rider.id)
	await _snap("rider-rear",rider.pos,7.6,yaw+2.56,rider.id)
	await _snap("standing-rear",b.vehicle_pos[1],7.1,-2.25,-1)
	await _snap("formation-22m",rider.pos,22.,yaw+.88,rider.id)
	await _snap("formation-42m",rider.pos,42.,yaw+.88,rider.id)
	var last:=rider.pos
	var distance:=0.
	for frame in 100:
		_advance(9+frame)
		distance+=last.distance_to(rider.pos)
		last=rider.pos
		if frame in [24,57,83]:
			var reverse_angle:=(-1.12 if frame==24 else (-1.75 if frame==57 else -.83))
			var current_yaw:=atan2(rider.facing.x,rider.facing.y)
			await _snap("opposite-%03d"%b.tick,rider.pos,7.6,current_yaw+reverse_angle,rider.id)
		_view(rider.pos,9.0,yaw+1.33)
		await RenderingServer.frame_post_draw
		var pic:=root.get_texture().get_image()
		if pic.save_jpg("%s/film/%03d.jpg"%[directory,frame],.90)!=OK: failed=true
	var f:=FileAccess.open(directory+"/frames.json",FileAccess.WRITE)
	f.store_string(JSON.stringify(snapshots,"  "))
	if distance<1.: failed=true
	print("MOUNT_LIVE_"+("FAIL" if failed else "PASS")+" id="+str(rider.id)+" travelled="+str(distance)+"m shots="+str(snapshots.size())+" frames=100 seed="+str(Battle.SEED))
	scene.queue_free()
	await process_frame
	quit(1 if failed else 0)
