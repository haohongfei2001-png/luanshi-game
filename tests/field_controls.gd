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
	var roster:=field.battle.roster
	field.hud.quality.item_selected.emit(2)
	_check(is_equal_approx(root.scaling_3d_scale,0.70) and not field.map.sun.shadow_enabled and is_same(roster,field.battle.roster),"Graphics preset changes render scale and shadows on the same fighters")
	field.hud.quality.item_selected.emit(0)
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
	await _vehicle_inputs()
	field.new_muster(20)
	await _portrait()
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
	# Stage a shield infantryman from the same roster who can engage locally.
	# A bodyguard deliberately returns to his commander instead of holding a duel.
	var enemy: Battle.Unit
	for unit in b.roster:
		if unit.team==1 and unit.kit==Arms.Kit.SHIELD and not unit.officer and b.corps.title_of(b,unit)=="":
			enemy=unit
			break
	_check(enemy!=null,"A shield infantryman is available from the defended formation")
	if enemy==null: return
	b.hero.pos=Vector2(14,-46); b.hero.before=b.hero.pos
	enemy.pos=b.hero.pos+Vector2(3.8 if kit in [Arms.Kit.BOW,Arms.Kit.CROSSBOW] else 1.36,0)
	enemy.before=enemy.pos
	b._rebuild_grid()
	field.camera.size=8.4
	field.pan_to(b.hero.pos.lerp(enemy.pos,0.5))
	if kit==Arms.Kit.SWORD: _check_orbit_aim(enemy)
	var basic_connected:=false
	var skill_attempted:=false
	var skill_committed:=false
	var committed: Array[int]=[]
	var defensive_effect:=false
	var defense_pos:=Vector2.ZERO
	var mouse_down:=false
	var max_ground_error:=0.0
	var cursor_error:=0.0
	var live_cursor_error:=0.0
	for n in 170:
		var foot:=Ground.unit_point(enemy.pos)
		var floor_screen:=field.camera.unproject_position(foot)
		max_ground_error=maxf(max_ground_error,field._screen_ground(floor_screen).distance_to(enemy.pos))
		var aim:=field.camera.unproject_position(foot+Vector3.UP*0.95)
		var err:=field._aim_point(aim,true).distance_to(enemy.pos)
		cursor_error=maxf(cursor_error,err)
		if b.active(enemy): live_cursor_error=maxf(live_cursor_error,err)
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
		if skill_committed and b.hero.state==Battle.State.MARCH and committed.size()<2:
			var slot:=2+committed.size()
			var key:=KEY_E if slot==2 else KEY_SPACE
			defense_pos=b.hero.pos
			_key(key,true)
			_key(key,false)
			if b.hero.state==Battle.State.WINDUP and b.hero.move_slot==slot: committed.append(slot)
		if committed.has(3):
			defensive_effect=defensive_effect or b.hero.state==Battle.State.GUARD or b.hero.pos.distance_squared_to(defense_pos)>0.8
		await RenderingServer.frame_post_draw
		if n%4==0:
			var pic:=root.get_texture().get_image()
			pic.resize(640,400,Image.INTERPOLATE_BILINEAR)
			_check(pic.save_jpg("res://artifacts/kit-film/frame-%03d.jpg"%frame_number,0.86)==OK,"Write action frame")
			frame_number+=1
	if mouse_down: _mouse(MOUSE_BUTTON_LEFT,root.get_mouse_position(),false)
	_check(max_ground_error<0.04,"Ray intersects the actual sloping ground")
	_check(basic_connected and skill_committed,"Mouse hit and Q windup for "+Arms.NAMES[kit])
	_check(committed==[2,3] and defensive_effect,"E and Space produce committed movement or guard for "+Arms.NAMES[kit])
	var row:={"e_and_space":committed,"defense_seen":defensive_effect,"weapon":Arms.NAMES[kit],"hits":b.hero.impacts,"target_hp":enemy.hp,"hero_hp":b.hero.hp,"quiver":b.hero.ammo,"skill_input":skill_committed,"max_ground_error":max_ground_error,"max_body_pick_error":cursor_error,"max_live_body_pick_error":live_cursor_error}
	evidence.append(row)
	print("FIELD_WEAPON_INPUT "+JSON.stringify(row))

func _check_orbit_aim(enemy: Battle.Unit) -> void:
	var saved_yaw:=field.camera_yaw
	var chest:=Ground.unit_point(enemy.pos)+Vector3.UP*0.96
	for yaw: float in [0.0,PI*0.5,PI,PI*1.5]:
		field.camera_yaw=yaw
		field._camera()
		var across:=field.camera.global_transform.basis.x.normalized()
		var edge:=field.camera.unproject_position(chest+across*0.27)
		var outside:=field.camera.unproject_position(chest+across*0.44)
		_check(field._aim_point(edge,true).distance_to(enemy.pos)<0.01,"A visible shoulder is selectable at yaw "+str(yaw))
		_check(field._aim_point(outside,true).distance_to(field._screen_ground(outside))<0.01,"Bare ground beside the shoulder remains aimable at yaw "+str(yaw))
	field.camera_yaw=saved_yaw
	field._camera()

func _portrait() -> void:
	var entering_yaw:=field.camera_yaw
	field.camera_yaw=0.0 # Fixed light and angle across portrait revisions.
	var u:=field.battle.roster[0]
	field.camera.size=5.8
	field.pan_to(u.pos)
	var mouse:=Vector2(620,380)
	root.warp_mouse(mouse)
	_mouse(MOUSE_BUTTON_MIDDLE,mouse,true)
	var turn:=InputEventMouseMotion.new()
	turn.position=mouse+Vector2(-132,0); turn.relative=Vector2(-132,0); turn.button_mask=MOUSE_BUTTON_MASK_MIDDLE
	Input.parse_input_event(turn); Input.flush_buffered_events()
	_mouse(MOUSE_BUTTON_MIDDLE,turn.position,false)
	_check(field.camera_yaw>1.0,"Middle drag orbits the same living soldier")
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var full:=root.get_texture().get_image()
	var feet:=Ground.unit_point(u.pos)
	# Sample the exposed lower cheek of the actual posed soldier. The previous
	# fixed screen point landed on the top of this helmet after the loaded stance.
	var batch=field.view.groups[field.view._key(u)]
	var body:Transform3D=batch.mesh.get_instance_transform(0)
	var pose:Color=batch.mesh.get_instance_custom_data(0)
	var material:=batch.node.material_override as ShaderMaterial
	var bank:Texture2D=material.get_shader_parameter("motion_bank")
	var face_local:=_idle_head_point(bank.get_image(),u.kit,pose.b,Vector3(0.035,1.548,0.124))
	var face:=field.camera.unproject_position(body*face_local)
	var face_pixels:=_warm_pixels(full,Vector2i(face),5)
	var hand_pixels:=0
	for sign_z: float in [-1,1]:
		var hand:=field.camera.unproject_position(feet+Vector3(0.36,1.018,sign_z*0.34))
		hand_pixels=maxi(hand_pixels,_warm_pixels(full,Vector2i(hand),6))
	var rect:=Rect2i(Vector2i(face)-Vector2i(78,52),Vector2i(156,206)).intersection(Rect2i(Vector2i.ZERO,full.get_size()))
	var portrait:=full.get_region(rect)
	_check(portrait.save_jpg("res://artifacts/soldier-portrait.jpg",0.97)==OK,"Store the actual face and hands at maximum play zoom")
	print("FIELD_PORTRAIT_JPEG "+Marshalls.raw_to_base64(FileAccess.get_file_as_bytes("res://artifacts/soldier-portrait.jpg")))
	_check(face_pixels>=7 and hand_pixels>=3,"Modeled skin remains visible on the face and at least one hand")
	print("FIELD_PORTRAIT "+JSON.stringify({"face_skin_pixels":face_pixels,"hand_skin_pixels":hand_pixels,"crop_px":[rect.size.x,rect.size.y],"zoom":field.camera.size}))
	field.camera_yaw=entering_yaw

func _idle_head_point(atlas: Image,kit: int,phase: float,bind_point: Vector3) -> Vector3:
	# The first unit uses its kit's standard idle, with the head on joint 2.
	# Decode the same two adjacent baked RGBA16 keys as the rendered mesh.
	var key:=clampf(phase,0.,1.)*32.
	var first:=floori(key)
	var column:=2*33+first
	var row:=(kit*31+1)*4
	var parts:Array[Color]=[]
	for i in 4:
		var a:=atlas.get_pixel(column,row+i)
		var b:=atlas.get_pixel(2*33+mini(first+1,32),row+i)
		parts.append(a.lerp(b,key-first))
	var q:Color=(parts[0]*256.+parts[1])*(2./257.)-Color(1,1,1,1)
	var t:Color=(parts[2]*256.+parts[3])*(6./257.)-Color(3,3,3,3)
	return Quaternion(q.r,q.g,q.b,q.a).normalized()*bind_point+Vector3(t.r,t.g,t.b)

func _warm_pixels(pic: Image,center: Vector2i,radius: int) -> int:
	var found:=0
	var area:=Rect2i(center-Vector2i.ONE*radius,Vector2i.ONE*(radius*2+1)).intersection(Rect2i(Vector2i.ZERO,pic.get_size()))
	for x in range(area.position.x,area.end.x):
		for y in range(area.position.y,area.end.y):
			var c:=pic.get_pixel(x,y)
			if c.r>0.24 and c.r>c.g*1.05 and c.g>c.b*1.05: found+=1
	return found

func _vehicle_inputs() -> void:
	var vehicle_records: Array=[]
	for id in [1,2]:
		field.new_muster(20)
		var b:=field.battle
		field.hud.weapon.select(Arms.Kit.SPEAR)
		field.hud.weapon.item_selected.emit(Arms.Kit.SPEAR)
		var button: Key=KEY_F if id==1 else KEY_V
		_key(button,true); _key(button,false)
		_key(KEY_ENTER,true); _key(KEY_ENTER,false)
		field.camera.size=9.2
		var start:=b.hero.pos
		_key(KEY_S,true)
		_key(KEY_SHIFT,true)
		for i in 38: await process_frame
		var speed:=b.riding_speed
		var turned:=b.riding_heading.y
		_key(KEY_SHIFT,false); _key(KEY_S,false)
		_key(KEY_Q,true); _key(KEY_Q,false)
		var used:=b.hero_cds[1]>0
		for i in 22: await process_frame
		await RenderingServer.frame_post_draw
		var name_of_vehicle: String="horse" if id==1 else "cart"
		_check(root.get_texture().get_image().save_jpg("res://artifacts/journey-vehicle-"+name_of_vehicle+".jpg",0.91)==OK,"Capture actual ridden vehicle")
		var distance:=b.hero.pos.distance_to(start)
		_key(button,true); _key(button,false)
		_check(speed>2 and turned>0.6 and distance>1.0 and used and b.vehicle==0,"Ride, steer, fight and dismount "+name_of_vehicle)
		vehicle_records.append({"vehicle":name_of_vehicle,"speed":speed,"turn_z":turned,"distance":distance,"skill":used,"dismounted":b.vehicle==0})
	print("FIELD_VEHICLE_INPUTS "+JSON.stringify(vehicle_records))
