extends SceneTree
## Record the normal main scene. Only normal menu/buttons, mapped movement,
## mouse aim and attack keys are sent. The camera and world are read only.
const Field:=preload("res://scripts/field/controller.gd")
const Battle:=preload("res://scripts/field/battle.gd")
const Ground:=preload("res://scripts/field/ground.gd")
const OUT:="res://artifacts/bridge-window"
var field: Field
var snapshots:Array=[]
var notes:Array=[]
var crossed:={}
var contacts:={}
var initial_west:={}
var last_tick:=-1
var first_game_frame:=0
var clicked:=false
var noted_contacts:={}
var troop_contacts:Array=[]
var screenshot_ok:=true

func _initialize() -> void:
	_run.call_deferred()

func _key(k:Key, pressed:bool) -> void:
	var e:=InputEventKey.new()
	e.keycode=k
	e.physical_keycode=k
	e.pressed=pressed
	Input.parse_input_event(e)
	Input.flush_buffered_events()

func _point(at:Vector2) -> void:
	root.warp_mouse(at)
	var motion:=InputEventMouseMotion.new()
	motion.position=at
	motion.global_position=at
	root.push_input(motion,true)

func _click(here:Vector2) -> void:
	_point(here)
	for down:bool in [true,false]:
		var e:=InputEventMouseButton.new()
		e.button_index=MOUSE_BUTTON_LEFT
		e.pressed=down
		e.position=here
		e.global_position=here
		root.push_input(e,true)

func _select_bridge() -> bool:
	var menu:=field.hud.plan
	_click(menu.get_global_rect().get_center())
	await process_frame
	var popup:=menu.get_popup()
	if not popup.visible: return false
	# The popup is embedded in the game's viewport; its coordinates use the
	# canvas design size. Project the row to real X11 window pixels before
	# moving the OS pointer, also on a 1600 x 1000 or Retina-sized window.
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_jpg(OUT+"/muster.jpg",.92)
	var target:=Vector2(popup.position)+Vector2(popup.size.x*.45,popup.size.y*.90)
	var pixel:=root.get_final_transform()*target
	var top_id:=DisplayServer.window_get_native_handle(DisplayServer.WINDOW_HANDLE,0)
	print("BRIDGE_MENU ",popup.position," ",popup.size," logical=",target," pixel=",pixel)
	if OS.execute("xdotool",PackedStringArray(["mousemove","--window",str(top_id),str(roundi(pixel.x)),str(roundi(pixel.y)),"click","1"]))!=0: return false
	for i in 6: await process_frame
	print("BRIDGE_MENU_SELECTED ",menu.selected," encounter=",field.battle.bridgehead," popup=",popup.visible)
	return menu.selected==5 and field.battle.bridgehead and not field.battle.started

func _drive() -> void:
	var b:=field.battle
	var t:=b.tick
	var target:Battle.Unit=null
	var d2:=42.
	for id in b._near(b.hero.pos,6.5,1):
		var other:=b.roster[id]
		if other.state==Battle.State.ROUT: continue
		var dist:=b.hero.pos.distance_squared_to(other.pos)
		if dist<d2 and Ground.clear_shot(b.hero.pos,other.pos,b.gate_hp<=0):
			target=other
			d2=dist
	var goal:=Vector2(34.0,-2.8)
	if b.hero.impacts>0: goal=Vector2(28.65,-2.8)
	if b.hero.hp<62.: goal=Vector2(26.8,-1.)
	# A human can follow the cart ruts with eight directions and retire
	# behind the other advancing soldiers. Send the same four mapped keys.
	var walk:=Vector2.ZERO
	if t>28 and b.hero.pos.distance_to(goal)>.28:
		var local:=b.hero.pos.direction_to(goal).rotated(field.camera_yaw)
		walk=Vector2.from_angle(roundf(local.angle()/(PI/4.))*PI/4.)
	_key(KEY_W,walk.y<-.25)
	_key(KEY_S,walk.y>.25)
	_key(KEY_A,walk.x<-.25)
	_key(KEY_D,walk.x>.25)
	if target!=null:
		var screen:=field.camera.unproject_position(Ground.unit_point(target.pos,true)+Vector3.UP*.86)
		_point(screen)
		if b.hero.state==Battle.State.MARCH:
			var key:Key=KEY_NONE
			if b.hero.hp<69. and b.hero_cds[3]<=0.: key=KEY_SPACE
			elif d2<9.75: key=KEY_Q if b.hero_cds[1]<=0. else KEY_J
			elif d2<22. and b.hero_cds[2]<=0. and b.hero.impacts==0: key=KEY_E
			if key!=KEY_NONE:
				_key(key,true)
				_key(key,false)
				notes.append({"tick":t,"key":OS.get_keycode_string(key),"aimed_at":target.id,"range":sqrt(d2),"cursor":[screen.x,screen.y],"direction":[b.hero.locked.x,b.hero.locked.y]})
	elif walk!=Vector2.ZERO:
		_point(field.camera.unproject_position(Ground.unit_point(b.hero.pos+Vector2(3.,0.),true)+Vector3.UP*.65))
	if t==90:
		_key(KEY_1,true)
		_key(KEY_1,false)

func _facts() -> Dictionary:
	var b:=field.battle
	var in_frame:=0
	var shields:=0
	var guards:=0
	var feet_inside:=0
	var canvas:=root.get_visible_rect()
	for u in b.roster:
		if u.team==0 and initial_west.has(u.id) and u.pos.x>Ground.MOAT_X+4. and absf(u.pos.y)<5.:
			crossed[u.id]=true
		if u.officer or u.hero or u.state==Battle.State.ESCAPED: continue
		if not canvas.has_point(field.camera.unproject_position(Ground.unit_point(u.pos,true)+Vector3.UP*.95)): continue
		in_frame+=1
		if Ground.moat_blocks(u.pos): feet_inside+=1
		if u.contact_tick==b.tick and u.contact_source>=0 and troop_contacts.size()<12:
			var source:=b.roster[u.contact_source]
			if source.kit==Battle.Arms.Kit.SPEAR and not source.hero and not source.officer and not noted_contacts.has(u.id):
				noted_contacts[u.id]=true
				troop_contacts.append({"tick":b.tick,"target":u.id,"spearman":source.id,"blocked":u.contact_blocked})
		if u.kit==7 and b.active(u):
			shields+=1
			if u.state==Battle.State.GUARD: guards+=1
			if u.contact_blocked and u.contact_tick==b.tick:
				contacts[str(u.id)+"@"+str(b.tick)]={"tick":b.tick,"defender":u.id,"source":u.contact_source}
	var bridge:=field.camera.unproject_position(Vector3(Ground.MOAT_X,.13,0))
	var arch:=field.camera.unproject_position(Vector3(Ground.WALL_X,3.7,0))
	return {"tick":b.tick,"hero":[b.hero.pos.x,b.hero.pos.y],"hp":b.hero.hp,"hero_impacts":b.hero.impacts,
		"hits":b.hits.duplicate(),"blocks":b.blocked_hits,"losses":b.losses.duplicate(),"gate_hp":b.gate_hp,
		"visible_ordinary":in_frame,"visible_shields":shields,"guarding":guards,"feet_in_deep_water":feet_inside,
		"crossed":crossed.size(),"soldier_shield_contacts":contacts.size(),"center":[field.camera_center.x,field.camera_center.y],"zoom":field.camera.size,"yaw":field.camera_yaw,
		"pitch":field.camera_pitch,"deck_screen":[bridge.x,bridge.y],"arch_screen":[arch.x,arch.y],
		"both_landmarks":canvas.has_point(bridge) and canvas.has_point(arch),"orders_delivered":b.messages_arrived,"result":b.result}

func _run() -> void:
	if DisplayServer.get_name()=="headless": quit(1);return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var scene=load("res://scenes/game.tscn").instantiate()
	root.add_child(scene)
	field=scene.field
	for i in 5: await process_frame
	if not await _select_bridge():
		push_error("The bridgehead plan could not be selected in its regular popup")
		quit(1);return
	var b:=field.battle
	for u in b.roster:
		if not u.hero and not u.officer and u.team==0 and u.pos.x<Ground.MOAT_X-3.: initial_west[u.id]=true
	_click(field.hud.go.get_global_rect().get_center())
	if not b.started:
		push_error("Deploy button failed")
		quit(1);return
	first_game_frame=Engine.get_frames_drawn()
	var preview:="--bridge-stills" in OS.get_cmdline_user_args()
	var frames:=0
	while frames<785 and b.result=="" and not field.paused:
		frames+=1
		if b.tick!=last_tick:
			last_tick=b.tick
			_drive()
			var m:=_facts()
			snapshots.append(m)
			if b.tick%25==0: print("BRIDGE_TICK ",JSON.stringify(m))
			if b.tick in [15,50,75,105,145,185,245,355,460] or (b.hero.impacts>0 and not clicked):
				if b.hero.impacts>0: clicked=true
				await RenderingServer.frame_post_draw
				var frame:=root.get_texture().get_image()
				screenshot_ok=frame.save_jpg(OUT+"/view-%04d.jpg"%b.tick,.94)==OK and screenshot_ok
		await process_frame
		if preview and b.tick>=150: break
	for key:Key in [KEY_W,KEY_S,KEY_A,KEY_D]: _key(key,false)
	var fact:=_facts()
	var clear_count:=0
	var entered_water:=false
	var off_lens:=false
	var first_blow:=-1
	for row:Dictionary in snapshots:
		if row.both_landmarks: clear_count+=1
		if row.feet_in_deep_water>0: entered_water=true
		if not is_equal_approx(row.zoom,22.) or absf(row.yaw-deg_to_rad(-33.))>.0001: off_lens=true
		if first_blow<0 and row.hero_impacts>0: first_blow=row.tick
	var terminal:={"ordinary":Array(b.ordinary_counts),"officers":Array(b.command_counts),"seed":Battle.SEED,
		"frames_of_play":frames,"sampled_ticks":snapshots.size(),"first_player_strike":first_blow,
		"held_both":clear_count,"feet_in_deep_water":entered_water,"different_lens":off_lens,
		"shield_contacts":contacts.values(),"rank_spear_contacts":troop_contacts,"resolution":[root.size.x,root.size.y],"internal":root.scaling_3d_scale,
		"camera_start":[Ground.BRIDGE_VIEW.x,Ground.BRIDGE_VIEW.y],"software":RenderingServer.get_video_adapter_name(),
		"last":fact,"frames":snapshots,"inputs":notes,"first_game_frame":first_game_frame,"physics_fps":Engine.physics_ticks_per_second,"world_audit":field.theater.audit().is_empty()}
	var file:=FileAccess.open(OUT+"/input-and-camera.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(terminal,"  "))
	file.close()
	var ok:bool=screenshot_ok and b.ordinary_counts==PackedInt32Array([512,512]) and not entered_water and not off_lens and clear_count>=snapshots.size()*.98 and crossed.size()>0 and fact.hits[0]+fact.hits[1]>0
	if not preview: ok=ok and frames>=240 and first_blow>0 and contacts.size()>0
	print("BRIDGE_WINDOW ",ok," ",JSON.stringify(fact)," first_player_strike=",first_blow," contacts=",contacts.size()," frames=",frames)
	scene.queue_free()
	await process_frame
	quit(0 if ok else 1)
