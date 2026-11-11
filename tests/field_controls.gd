extends SceneTree
## Each clip puts one real opposing soldier within reach for a repeatable weapon
## comparison. The separate 512-vs-512 movie uses the unmodified battle deployment.
const Battle := preload("res://scripts/field/battle.gd")
const Field := preload("res://scripts/field/controller.gd")
const Arms := preload("res://scripts/field/arms.gd")
const Ground := preload("res://scripts/field/ground.gd")
var field: Field
var issues: Array[String]=[]
var evidence := []
var frame_number:=0

func _initialize() -> void:
	_run.call_deferred()

func _key(code: Key,pressed: bool) -> void:
	var event:=InputEventKey.new()
	event.physical_keycode=code
	event.keycode=code
	event.pressed=pressed
	Input.parse_input_event(event)
	Input.flush_buffered_events()

func _mouse(button: MouseButton,at: Vector2,down: bool) -> void:
	var event:=InputEventMouseButton.new()
	event.button_index=button
	event.position=at
	event.pressed=down
	Input.parse_input_event(event)
	Input.flush_buffered_events()

func _check(value: bool,line: String) -> void:
	if not value:
		issues.append(line)
		push_error(line)

func _run() -> void:
	if DisplayServer.get_name()=="headless": quit(1); return
	var shell=load("res://scenes/game.tscn").instantiate()
	root.add_child(shell)
	field=shell.field
	await process_frame
	_key(KEY_F,true); _key(KEY_F,false)
	_check(field.battle.vehicle==1,"Mount key boards the horse")
	_key(KEY_F,true); _key(KEY_F,false)
	_key(KEY_V,true); _key(KEY_V,false)
	_check(field.battle.vehicle==2,"Cart key boards the separate vehicle")
	_key(KEY_V,true); _key(KEY_V,false)
	var pos:=field.hud.inset.get_global_rect().get_center()+Vector2(40,0)
	root.warp_mouse(pos)
	_mouse(MOUSE_BUTTON_LEFT,pos,true); _mouse(MOUSE_BUTTON_LEFT,pos,false)
	_check(not field.follow and field.camera_center.x>25,"Map click locates walled side of field")
	var center:=field.camera_center
	pos=Vector2(680,400)
	root.warp_mouse(pos)
	_mouse(MOUSE_BUTTON_RIGHT,pos,true)
	var drag:=InputEventMouseMotion.new()
	drag.position=pos+Vector2(75,16); drag.relative=Vector2(75,16); drag.button_mask=MOUSE_BUTTON_MASK_RIGHT
	Input.parse_input_event(drag); Input.flush_buffered_events()
	_mouse(MOUSE_BUTTON_RIGHT,drag.position,false)
	_check(field.camera_center.distance_to(center)>0.2,"Right-drag pans terrain")
	var zoom:=field.camera.size
	_mouse(MOUSE_BUTTON_WHEEL_UP,pos,true); _mouse(MOUSE_BUTTON_WHEEL_UP,pos,false)
	_check(field.camera.size<zoom,"Wheel changes viewing distance")
	_key(KEY_C,true); _key(KEY_C,false)
	_check(field.follow,"C restores player camera")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://artifacts/kit-film"))
	for kit in Arms.NAMES.size(): await _weapon(kit)
	var out:=FileAccess.open("res://artifacts/field-controls.json",FileAccess.WRITE)
	out.store_string(JSON.stringify(evidence,"  "))
	print("FIELD_CONTROLS_"+("PASS" if issues.is_empty() else "FAIL")+" "+JSON.stringify(issues))
	shell.queue_free()
	await process_frame
	quit(0 if issues.is_empty() else 1)

func _weapon(kit: int) -> void:
	field.new_muster(20)
	field.hud.weapon.select(kit)
	field.hud.weapon.item_selected.emit(kit)
	var b:=field.battle
	_key(KEY_ENTER,true); _key(KEY_ENTER,false)
	_check(b.started and b.hero.kit==kit,"Deploy selected kit "+Arms.NAMES[kit])
	var enemy:=b.roster[b.side_size]
	b.hero.pos=Vector2(14,-46); b.hero.before=b.hero.pos
	enemy.pos=b.hero.pos+Vector2(3.8 if kit in [Arms.Kit.BOW,Arms.Kit.CROSSBOW] else 1.36,0)
	enemy.before=enemy.pos
	b._rebuild_grid()
	field.camera.size=8.4
	field.pan_to(b.hero.pos.lerp(enemy.pos,0.5))
	var basic_connected:=false
	var skill_attempted:=false
	var skill_committed:=false
	var mouse_down:=false
	for n in 84:
		var aim:=field.camera.unproject_position(Ground.unit_point(enemy.pos))
		root.warp_mouse(aim)
		if n==2:
			_mouse(MOUSE_BUTTON_LEFT,aim,true)
			mouse_down=true
		if mouse_down and b.hero.impacts>0:
			basic_connected=true
			_mouse(MOUSE_BUTTON_LEFT,aim,false)
			mouse_down=false
		if basic_connected and b.hero.state==Battle.State.MARCH and not skill_attempted:
			_key(KEY_Q,true); _key(KEY_Q,false)
			skill_attempted=true
			skill_committed=b.hero.move_slot==1 and b.hero.state==Battle.State.WINDUP
		await RenderingServer.frame_post_draw
		if n%3==0:
			var pic:=root.get_texture().get_image()
			pic.resize(640,400,Image.INTERPOLATE_BILINEAR)
			_check(pic.save_jpg("res://artifacts/kit-film/frame-%03d.jpg"%frame_number,0.86)==OK,"Write action frame")
			frame_number+=1
	if mouse_down: _mouse(MOUSE_BUTTON_LEFT,root.get_mouse_position(),false)
	_check(basic_connected and skill_committed,"Mouse hit and Q windup for "+Arms.NAMES[kit])
	var row:={"weapon":Arms.NAMES[kit],"hits":b.hero.impacts,"target_hp":enemy.hp,"hero_hp":b.hero.hp,"quiver":b.hero.ammo,"skill_input":skill_committed}
	evidence.append(row)
	print("FIELD_WEAPON_INPUT "+JSON.stringify(row))
