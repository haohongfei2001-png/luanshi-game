extends SceneTree
## Fast input calibration against the complete normal scene, before native capture.
## This verifies controls and battle events. It supplies no visual acceptance.
const Replay:=preload("res://scripts/field/whole_battle_review.gd")
const Battle:=preload("res://scripts/field/battle.gd")
func _initialize() -> void:
	_run.call_deferred()
func _run() -> void:
	root.size=Vector2i(2560,1440)
	var scene=load("res://scenes/game.tscn").instantiate()
	root.add_child(scene)
	var field=scene.field
	field.set_process(false)
	field.set_physics_process(false)
	field.hud.plan_requested.emit(5)
	field.hud.go.pressed.emit()
	var replay:=Replay.new()
	replay.root=root
	replay.field=field
	var b=field.battle
	var max_camera_error:=0.
	var fixed_camera_required:="--fixed-camera-contract" in OS.get_cmdline_user_args()
	replay.requested_side=b.ordinary_counts[0]
	for step in (900 if replay.real_time else 3600):
		replay._drive()
		field._physics_process(Battle.DT)
		field._process(Battle.DT)
		var offset:Vector2=field.camera_center-field.Ground.BRIDGE_VIEW
		max_camera_error=maxf(max_camera_error,maxf(absf(offset.x),absf(offset.y)))
		if b.tick%50==0:
			print("CONTROL_STEP ",b.tick," hero=",b.hero.pos," hp=",b.hero.hp," impacts=",b.hero.impacts," state=",b.hero.state," input=",JSON.stringify(replay.notes.back()) if not replay.notes.is_empty() else "")
		if b.result!="":break
		await process_frame
	var ok:bool=b.hero.impacts>0 and b.tick>=600 and b.hits[0]+b.hits[1]>0 and b.result!=""
	if replay.real_time:
		ok=b.hero.hp>0 and b.hits[0]+b.hits[1]>0 and (b.tick>=900 or b.result!="")
	assert(field.hud.refresh_tick>=0 and field.hud.refresh_tick<=b.tick)
	assert(field.hud.refresh_us>0 and not field.hud.condition.text.is_empty())
	ok=ok and (not fixed_camera_required or max_camera_error<.35)
	print("WHOLE_CAMERA_CONTRACT required=",fixed_camera_required," max_center_error=",max_camera_error)
	print("WHOLE_INPUT_CALIBRATION ",ok," tick=",b.tick," impacts=",b.hero.impacts," hp=",b.hero.hp," result=",b.result)
	for key:Key in [KEY_W,KEY_S,KEY_A,KEY_D]:replay._key(key,false)
	replay.free()
	scene.queue_free()
	await process_frame
	await process_frame
	await create_timer(.15).timeout
	quit(0 if ok else 1)
