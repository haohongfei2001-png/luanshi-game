extends SceneTree
## Two ordinary attempts through the same playable shell. No health, casualty,
## troop position, clock or outcome is forced. These are NOT scale benchmarks.
const Field:=preload("res://scripts/field/controller.gd")
const Battle:=preload("res://scripts/field/battle.gd")
var field: Field
const Ground:=preload("res://scripts/field/ground.gd")
var held: Array[Key]=[]
var results: Array=[]
var failures: Array[String]=[]

func _initialize() -> void:
	_run.call_deferred()

func _key(k: Key,pressed: bool) -> void:
	var e:=InputEventKey.new()
	e.physical_keycode=k
	e.keycode=k
	e.pressed=pressed
	Input.parse_input_event(e)
	Input.flush_buffered_events()

func _tap(k: Key) -> void:
	_key(k,true)
	_key(k,false)

func _steer(direction: Vector2) -> void:
	var screen:=direction.rotated(field.camera_yaw)
	var requested: Array[Key]=[]
	if screen.x< -0.32: requested.append(KEY_A)
	elif screen.x>0.32: requested.append(KEY_D)
	if screen.y< -0.32: requested.append(KEY_W)
	elif screen.y>0.32: requested.append(KEY_S)
	for k in held:
		if k not in requested: _key(k,false)
	for k in requested:
		if k not in held: _key(k,true)
	held=requested

func _check(ok: bool,s: String) -> void:
	if not ok:
		failures.append(s)
		push_error(s)

func _run() -> void:
	if DisplayServer.get_name()=="headless": quit(1); return
	var shell=load("res://scenes/game.tscn").instantiate()
	root.add_child(shell)
	field=shell.field
	await process_frame
	for retreat: bool in [true,false]:
		var b:=field.battle
		_tap(KEY_3 if retreat else KEY_2)
		_tap(KEY_ENTER)
		_check(b.started and b.companies[0].mission==(Battle.Mission.WITHDRAW if retreat else Battle.Mission.HOLD),"Selected mission and deployed through normal bindings")
		_key(KEY_SHIFT,true)
		var frames:=0
		while b.result=="" and b.tick<1800 and frames<1000:
			frames+=1
			var dest:=Vector2(-91,0)
			if not retreat:
				var nearest:=INF
				for u in b.roster:
					if u.team!=1 or not b.active(u): continue
					var d:=u.pos.distance_squared_to(b.hero.pos)
					if d<nearest:
						dest=u.pos
						nearest=d
			var via:=Ground.waypoint(b.hero.pos,dest)
			_steer(b.hero.pos.direction_to(via) if dest.distance_to(b.hero.pos)>0.7 else Vector2.ZERO)
			await process_frame
		_steer(Vector2.ZERO)
		_key(KEY_SHIFT,false)
		for i in 4: await process_frame
		var detail:=b.report()
		detail.merge({"case":"withdrawal" if retreat else "defeat","hero_x":b.hero.pos.x,"survivors_can_continue":field.hud.resume_camp.visible,"receipt":not field.theater.receipt.is_empty()})
		results.append(detail)
		_check(b.result==("成功撤离" if retreat else "主将阵亡"),"Expected actual alternative result, obtained "+b.result+" "+JSON.stringify(detail))
		_check(detail.receipt and field.hud.result_box.visible and field.hud.resume_camp.visible==retreat,"Continuation respects the commander and the settled roster")
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_jpg("res://artifacts/outcome-"+str(detail.case)+".jpg",0.90)
		if retreat:
			if b.result=="": break
			# Retry by pressing the same visible button.
			var p:=field.hud.retry_button.get_global_rect().get_center()
			for down: bool in [true,false]:
				var e:=InputEventMouseButton.new()
				e.position=p
				e.global_position=p
				e.button_index=MOUSE_BUTTON_LEFT
				e.pressed=down
				root.push_input(e,true)
			for i in 3: await process_frame
			_check(field.battle!=b and not field.battle.started,"Retry starts fresh after withdrawal")
	# In camp the world continues to consume real rations after the encounter.
	# Exercise the same terminal state the economy commits when relief loses its last person.
	field.new_muster(20)
	var fresh:=field.battle
	field.deploy()
	fresh.result="守城成功"
	field.theater.sync()
	field.theater.settle()
	field.theater.enter_camp()
	var force: Dictionary=field.theater._state.armies.relief
	field.theater._lose_troops(force,force.soldiers,"shortage")
	field._refresh_hud()
	_check(field.hud.wait_hour.disabled and not field.hud.travel_row.visible and field.hud.condition.text=="主将阵亡","Career end in camp uses the living world's commander")
	field.hud.back_report.emit()
	_check(not field.hud.resume_camp.visible and not field.theater.enter_camp(),"Past encounter HP cannot resurrect the player from its report")
	var file:=FileAccess.open("res://artifacts/field-outcomes.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(results,"  "))
	print("FIELD_ALTERNATE "+JSON.stringify(results))
	print("FIELD_ENDINGS_"+("PASS" if failures.is_empty() else "FAIL")+" "+JSON.stringify(failures))
	shell.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
