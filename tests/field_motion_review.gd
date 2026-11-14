extends SceneTree
## A player-operated camera and mapped controls, recorded in Godot's 30 Hz movie mode.
## The driver reads the nearest opponent to aim. All movement, strikes, health and
## camera follow still pass through the shipping controller.
const Field:=preload("res://scripts/field/controller.gd")
const Battle:=preload("res://scripts/field/battle.gd")
const Ground:=preload("res://scripts/field/ground.gd")
var field: Field
var held: Dictionary={}
var errors: Array[String]=[]

func _initialize() -> void:
	_run.call_deferred()

func _check(ok: bool,reason: String) -> bool:
	if not ok:
		errors.append(reason)
		push_error("FIELD_MOTION "+reason)
	return ok

func _frames(n: int) -> void:
	for i in n: await process_frame

func _mouse(code: MouseButton,p: Vector2,down: bool) -> void:
	var e:=InputEventMouseButton.new()
	e.position=p
	e.global_position=p
	e.button_index=code
	e.pressed=down
	root.push_input(e,true)

func _point(p: Vector2) -> void:
	root.warp_mouse(p)
	var motion:=InputEventMouseMotion.new()
	motion.position=p
	motion.global_position=p
	root.push_input(motion,true)

func _at(p: Vector2) -> void:
	_point(p)
	_mouse(MOUSE_BUTTON_LEFT,p,true)
	_mouse(MOUSE_BUTTON_LEFT,p,false)

func _click(c: Control) -> void:
	if not _check(c.is_visible_in_tree() and c.get_global_rect().has_area(),"Visible button "+str(c.name)): return
	_at(c.get_global_rect().get_center())
	await _frames(2)

func _key(k: Key,pressed: bool) -> void:
	var e:=InputEventKey.new()
	e.keycode=k
	e.physical_keycode=k
	e.pressed=pressed
	Input.parse_input_event(e)
	Input.flush_buffered_events()

func _tap(k: Key) -> void:
	_key(k,true)
	_key(k,false)


func _hold(key: Key,down: bool) -> void:
	if bool(held.get(key,false))==down: return
	_key(key,down)
	held[key]=down

func _walk(world: Vector2,run: bool) -> void:
	var dir:=world.rotated(field.camera_yaw)
	_hold(KEY_D,dir.x>.38)
	_hold(KEY_A,dir.x<-.38)
	_hold(KEY_S,dir.y>.38)
	_hold(KEY_W,dir.y<-.38)
	_hold(KEY_SHIFT,run)

func _run() -> void:
	if DisplayServer.get_name()=="headless": quit(1); return
	var shell=load("res://scenes/game.tscn").instantiate()
	root.add_child(shell)
	field=shell.field
	await _frames(4)
	if "--field-line-film" in OS.get_cmdline_user_args():
		await _line_film(shell)
		return
	# Equal starting lens for the two input replays, regardless of the new-game default.
	field.camera.size=26.0
	await _click(field.hud.go)
	var b:=field.battle
	_check(b.started and b.ordinary_counts==PackedInt32Array([512,512]),"Expected a deployed full river battle")
	var center:=root.get_visible_rect().size*.5
	_point(center+Vector2(35,-30))
	for i in 5:
		_mouse(MOUSE_BUTTON_WHEEL_UP,center,true)
		_mouse(MOUSE_BUTTON_WHEEL_UP,center,false)
	await _frames(2)
	var start:=b.hero.pos
	var distance:=0.0
	var previous:=start
	var last_pressed:=-30
	var strikes:=0
	var actions_seen:={}
	var directions:={}
	var started_at:=b.tick
	for frame in 330:
		if frame%30==0: print("FIELD_MOTION_PROGRESS frame=",frame)
		var target: Battle.Unit=null
		var closest:=INF
		for u in b.roster:
			if u.team!=1 or not b.active(u): continue
			var sq:=b.hero.pos.distance_squared_to(u.pos)
			if sq<closest: closest=sq; target=u
		if target==null or b.hero.hp<=0 or b.result!="": break
		var axis:=b.hero.pos.direction_to(target.pos)
		var screen:=field.camera.unproject_position(Ground.unit_point(target.pos)+Vector3.UP)
		var viewport:=root.get_visible_rect().size
		_point(screen.clamp(Vector2(14,67),viewport-Vector2(15,100)))
		var desired:=Vector2.ZERO
		if frame<16: desired=axis.orthogonal()
		elif frame<33: desired=-axis.orthogonal()
		elif closest>3.0: desired=axis
		elif frame%98<12: desired=-axis
		elif frame%98<37: desired=axis.orthogonal()
		_walk(desired,closest>20.0 and frame>=33)
		if desired.length_squared()>.2:
			directions[int(roundi(rad_to_deg(axis.angle_to(desired))/45.0))]=true
		if closest<7.6 and b.hero.state==Battle.State.MARCH and b.tick-last_pressed>=4:
			if strikes%4==1: _tap(KEY_Q)
			elif strikes%4==2: _tap(KEY_E)
			else: _at(screen.clamp(Vector2(14,67),viewport-Vector2(15,100)))
			last_pressed=b.tick
			strikes+=1
		actions_seen[b.hero.state]=true
		distance+=b.hero.pos.distance_to(previous)
		previous=b.hero.pos
		await process_frame
	_walk(Vector2.ZERO,false)
	_check(distance>4 and directions.size()>=3,"Live pointer-facing lateral travel and advance")
	_check(actions_seen.has(Battle.State.WINDUP) and actions_seen.has(Battle.State.RECOVER) and b.hero.impacts>0,"A real close-range strike reached an opponent")
	_check(field.camera.size<14 and field.follow,"Normal player zoom and following")
	print("FIELD_MOTION_RECEIPT "+JSON.stringify({"start_tick":started_at,"end_tick":b.tick,"distance_m":distance,"move_directions":directions.keys(),"hero_hits":b.hero.impacts,"hero_received":b.hero.received,"hero_hp":b.hero.hp,"actions_seen":actions_seen.keys(),"view_size":field.camera.size,"ordinary":Array(b.ordinary_counts),"seed":Battle.SEED,"errors":errors}))
	shell.queue_free()
	await process_frame
	quit(0 if errors.is_empty() else 1)

func _line_film(shell: Node) -> void:
	# Keep one normal-speed take. Equip through the live muster, then follow the
	# fighting line using the shipping pan and zoom controls after the hero's volley.
	field.hud.plan.select(1)
	field.hud.plan.item_selected.emit(1)
	field.hud.weapon.select(5)
	field.hud.weapon.item_selected.emit(5)
	await _click(field.hud.go)
	var b:=field.battle
	var center:=root.get_visible_rect().size*.5
	for n in 3:
		_mouse(MOUSE_BUTTON_WHEEL_UP,center,true)
		_mouse(MOUSE_BUTTON_WHEEL_UP,center,false)
	var start:=b.tick
	var previous:=-20
	var volleys:=0
	var followed:=b.hero.pos
	var rendered:=0
	for frame in 1020:
		if b.result!="": break
		if frame==0:
			_hold(KEY_D,true)
			_hold(KEY_SHIFT,true)
		elif frame==12:
			_hold(KEY_D,false)
			_hold(KEY_SHIFT,false)
		if frame<239:
			var target: Battle.Unit=null
			var closest:=INF
			for id in b._near(b.hero.pos,22,1):
				var u:=b.roster[id]
				var sq:=b.hero.pos.distance_squared_to(u.pos)
				if sq<closest and Ground.clear_shot(b.hero.pos,u.pos,b.gate_hp<=0):
					closest=sq
					target=u
			if target:
				var pixel:=field.camera.unproject_position(Ground.unit_point(target.pos)+Vector3.UP*.88)
				var position:=pixel.clamp(Vector2(13,58),root.get_visible_rect().size-Vector2(18,96))
				_point(position)
				if b.hero.state==Battle.State.MARCH and b.tick-previous>=4:
					if volleys%4==1: _tap(KEY_Q)
					else: _at(position)
					volleys+=1
					previous=b.tick
		else:
			if frame%24==0 and frame<755:
				var best:=INF
				for u in b.roster:
					if u.team!=0 or u.state!=Battle.State.WINDUP or u.target<0: continue
					var midpoint:=u.pos.lerp(b.roster[u.target].pos,.5)
					var distance:=field.camera_center.distance_squared_to(midpoint)
					if distance<best:
						best=distance
						followed=midpoint
			if frame>=755: followed=b.ram
			field.pan_to(field.camera_center.lerp(followed,.041))
			if frame in [630,835]:
				_mouse(MOUSE_BUTTON_WHEEL_DOWN,center,true)
				_mouse(MOUSE_BUTTON_WHEEL_DOWN,center,false)
		rendered+=1
		if rendered%90==0:
			print("FIELD_FILM_ADVANCE ",rendered," ",b.tick)
		await process_frame
	_check(rendered==1020 and b.tick-start>=670,"34 continuous seconds of live battle")
	_check(b.hero.impacts>0 and b.hits[0]+b.hits[1]>100,"Visible fighting followed real input and casualties")
	print("FIELD_LINE_FILM "+JSON.stringify({"frames":rendered,"fps":30,"start_tick":start,"end_tick":b.tick,"hero_hits":b.hero.impacts,"hero_hp":b.hero.hp,"attacks_pressed":volleys,"hits":b.hits,"losses":b.losses,"gate":b.gate_hp,"ordinary":Array(b.ordinary_counts),"errors":errors}))
	shell.queue_free()
	await process_frame
	quit(0 if errors.is_empty() else 1)
