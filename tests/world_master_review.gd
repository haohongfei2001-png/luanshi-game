extends SceneTree
## Deterministic real-game stills. The complete battle advances between views.
const Battle:=preload("res://scripts/field/battle.gd")
const Ground:=preload("res://scripts/field/ground.gd")
const OUT:="res://docs/evidence/river-whole-rebuild/review"
var field
var records:Array=[]
func _initialize() -> void:
	_run.call_deferred()
func _snap(label:String,point:Vector2,zoom:float) -> void:
	field.camera_yaw=deg_to_rad(-33.)
	field.camera.size=zoom
	field.pan_to(point)
	field._process(Battle.DT)
	await RenderingServer.frame_post_draw
	var pic:=root.get_texture().get_image()
	assert(pic.get_width()==2560 and pic.get_height()==1440)
	pic.save_png(OUT+"/"+label+".png")
	pic.save_jpg(OUT+"/"+label+".jpg",.94)
	pic.resize(1440,810,Image.INTERPOLATE_LANCZOS)
	pic.save_jpg(OUT+"/"+label+"-preview.jpg",.93)
	var b=field.battle
	var row:={"frame":label,"seed":Battle.SEED,"tick":b.tick,"ordinary":Array(b.ordinary_counts),"hits":b.hits.duplicate(),"center":[point.x,point.y],"zoom":zoom,"internal":root.scaling_3d_scale,"world_audit":field.theater.audit(),"renderer":RenderingServer.get_video_adapter_name()}
	records.append(row)
	print("WORLD_MASTER_FRAME ",JSON.stringify(row))
func _run() -> void:
	if DisplayServer.get_name()=="headless":quit(1);return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var scene=load("res://scenes/game.tscn").instantiate()
	root.add_child(scene)
	field=scene.field
	field.hud.plan_requested.emit(5)
	field.set_process(false)
	field.set_physics_process(false)
	field.hud.go.pressed.emit()
	assert(field.battle.started and field.battle.bridgehead)
	assert(field.map._land_height(Vector2(Ground.MOAT_X,12.))<-.38,"The actual moat bed must remain below its visible water")
	assert(field.map._land_height(Vector2(Ground.RIVER_X,12.))<-.37,"The river bed must remain below its visible water")
	for tick in 50:field._physics_process(Battle.DT)
	await _snap("bridgehead-0050",Ground.BRIDGE_VIEW,22.)
	for tick in 85:field._physics_process(Battle.DT)
	await _snap("bridgehead-0135",Ground.BRIDGE_VIEW,22.)
	await _snap("whole-war-0135",Vector2(9.,0.),115.)
	var file:=FileAccess.open(OUT+"/frames.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(records,"  "))
	print("WORLD_MASTER_STILLS ",field.theater.audit().is_empty())
	scene.queue_free()
	await process_frame
	quit(0)
