extends SceneTree
## Continuous ten-frame-per-second capture of play from ordinary deployment to
## settlement. No unit, health, gate, time or damage value is set by this recorder.
const Field:=preload("res://scripts/field/controller.gd")
const Battle:=preload("res://scripts/field/battle.gd")
const Ground:=preload("res://scripts/field/ground.gd")
var field: Field

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	if DisplayServer.get_name()=="headless": quit(1); return
	var shell=load("res://scenes/game.tscn").instantiate()
	root.add_child(shell)
	field=shell.field
	await process_frame
	var b:=field.battle
	for i in b.companies_per_side:
		var mission:=Battle.Mission.PRESS
		if i in [2,7]: mission=Battle.Mission.ESCORT
		elif i in [0,4]: mission=Battle.Mission.FLANK
		field.hud.order_requested.emit(i,mission,Battle.Channel.FLAG)
	field.hud.go.pressed.emit()
	var root_dir:="res://artifacts/siege-film"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(root_dir))
	var pictures:=0
	var contact:=-1
	var breach:=-1
	var io_ok:=true
	while b.result=="" and b.tick<2400 and pictures<1250:
		if b.tick<155:
			field.camera.size=48
			field.pan_to(Vector2(0,-6))
		elif b.gate_hp>0:
			var t:=clampf((b.tick-155)/375.0,0,1)
			field.camera.size=lerpf(48,23,t)
			field.pan_to(Vector2(lerpf(b.ram.x,Ground.GATE.x-2.0,t),-1))
		else:
			field.camera.size=lerpf(23,36,clampf((b.tick-breach)/200.0,0,1))
			field.pan_to(Vector2(50,-3))
		await RenderingServer.frame_post_draw
		var screen:=root.get_texture().get_image()
		screen.resize(768,480,Image.INTERPOLATE_BILINEAR)
		io_ok=screen.save_jpg("%s/frame-%04d.jpg"%[root_dir,pictures],0.84)==OK and io_ok
		if contact<0 and b.gate_hp<260: contact=b.tick
		if breach<0 and b.gate_hp==0:
			breach=b.tick
			io_ok=screen.save_jpg("res://artifacts/natural-gate-breach.jpg",0.94)==OK and io_ok
		pictures+=1
	var data:=b.report()
	data.merge({"gate_first_damage_tick":contact,"breach_tick":breach,"frames_captured":pictures,"capture_fps":10,
		"receipt":not field.theater.receipt.is_empty(),"ordinary_survivors":[b.side_size-b.losses[0],b.side_size-b.losses[1]],
		"quivers_balanced":field.theater.audit_quivers()})
	var file:=FileAccess.open("res://artifacts/natural-siege.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(data,"  "))
	var ok:bool=io_ok and b.side_size==512 and contact>0 and breach>contact and b.result!="" and data.receipt and data.quivers_balanced and b.losses[1]<512
	print("FIELD_SIEGE_FILM_"+("PASS " if ok else "FAIL ")+JSON.stringify(data))
	shell.queue_free()
	await process_frame
	quit(0 if ok else 1)
