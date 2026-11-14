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
	replay.requested_side=b.ordinary_counts[0]
	for step in (900 if replay.real_time else 3600):
		replay._drive()
		field._physics_process(Battle.DT)
		field._process(Battle.DT)
		if b.tick%50==0:
			print("CONTROL_STEP ",b.tick," hero=",b.hero.pos," hp=",b.hero.hp," impacts=",b.hero.impacts," state=",b.hero.state," input=",JSON.stringify(replay.notes.back()) if not replay.notes.is_empty() else "")
		if b.result!="":break
		await process_frame
	var ok:bool=b.hero.impacts>0 and b.tick>=600 and b.hits[0]+b.hits[1]>0 and b.result!=""
	if replay.real_time:
		ok=b.hero.hp>0 and b.hits[0]+b.hits[1]>0 and (b.tick>=900 or b.result!="")
	print("WHOLE_INPUT_CALIBRATION ",ok," tick=",b.tick," impacts=",b.hero.impacts," hp=",b.hero.hp," result=",b.result)
	replay.free()
	scene.queue_free()
	await process_frame
	quit(0 if ok else 1)
