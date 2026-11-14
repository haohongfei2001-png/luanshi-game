extends Node
## Record the normal main scene. Only normal menu/buttons, mapped movement,
## mouse aim and attack keys are sent. The camera and world are read only.
const Field:=preload("res://scripts/field/controller.gd")
const Battle:=preload("res://scripts/field/battle.gd")
const Ground:=preload("res://scripts/field/ground.gd")
var out:=OS.get_environment("RIVER_CAPTURE_OUT")
var real_time:="--real-time-profile" in OS.get_cmdline_user_args()
var wall_started:=0
var requested_side:=512
var camera_tour:="--camera-tour" in OS.get_cmdline_user_args()
var complete_battle:="--complete-battle" in OS.get_cmdline_user_args()
var last_tour_tick:=-1000
var post_battle_frames:=0
var rendered_size:=Vector2i.ZERO
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
var progress_file:FileAccess

var root:Window
func _ready() -> void:
	root=get_tree().root
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--field-size="):requested_side=argument.trim_prefix("--field-size=").to_int()
	assert(requested_side in Battle.SCALES)
	if out.is_empty():out=ProjectSettings.globalize_path("user://whole-battle-review")
	if "--native-qhd" in OS.get_cmdline_user_args():
		root.content_scale_size=Vector2i(2560,1440)
		root.content_scale_mode=Window.CONTENT_SCALE_MODE_VIEWPORT
		root.content_scale_aspect=Window.CONTENT_SCALE_ASPECT_KEEP
	_run.call_deferred()

func _key(k:Key, pressed:bool) -> void:
	var e:=InputEventKey.new()
	e.keycode=k
	e.physical_keycode=k
	e.pressed=pressed
	Input.parse_input_event(e)
	Input.flush_buffered_events()

func _point(at:Vector2) -> void:
	if DisplayServer.get_name()!="headless":root.warp_mouse(at)
	var motion:=InputEventMouseMotion.new()
	motion.position=at
	motion.global_position=at
	if DisplayServer.get_name()=="headless":
		# A headless root reads Input's emulated global mouse coordinate.
		motion.position=root.get_screen_transform()*at
		motion.global_position=motion.position
		Input.parse_input_event(motion)
		Input.flush_buffered_events()
	else:
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
	await get_tree().process_frame
	var popup:=menu.get_popup()
	if not popup.visible: return false
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_jpg(out+"/muster.jpg",.92)
	# PopupMenu handles window input before Viewport.push_input().
	# Send actual arrow keys through the root so its embedded-window route runs.
	for attempt in menu.item_count+1:
		if popup.get_focused_item()==5:break
		for down:bool in [true,false]:
			var event:=InputEventKey.new()
			event.keycode=KEY_DOWN
			event.physical_keycode=KEY_DOWN
			event.pressed=down
			root.push_input(event,true)
			await get_tree().process_frame
	print("BRIDGE_MENU_FOCUS ",popup.get_focused_item()," embedded=",popup.is_embedded())
	if popup.get_focused_item()!=5:return false
	for down:bool in [true,false]:
		var event:=InputEventKey.new()
		event.keycode=KEY_ENTER
		event.physical_keycode=KEY_ENTER
		event.pressed=down
		root.push_input(event,true)
		await get_tree().process_frame
	for i in 3:await get_tree().process_frame
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
	var goal:=Vector2(38.0,-2.8)
	if target!=null:
		goal=target.pos+target.pos.direction_to(b.hero.pos)*2.15
	if b.hero.hp<64. or b.hero.impacts>=3:goal=Vector2(26.8,-1.)
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
				notes.append({"tick":t,"key":OS.get_keycode_string(key),"aimed_at":target.id,"range":sqrt(d2),"target":[target.pos.x,target.pos.y],"hero":[b.hero.pos.x,b.hero.pos.y],"cursor":[screen.x,screen.y],"mouse":str(root.get_mouse_position()),"direction":[b.hero.locked.x,b.hero.locked.y]})
	elif walk!=Vector2.ZERO:
		_point(field.camera.unproject_position(Ground.unit_point(b.hero.pos+Vector2(3.,0.),true)+Vector3.UP*.65))
	if t==90:
		_key(KEY_1,true)
		_key(KEY_1,false)

func _tour(tick:int) -> void:
	if tick<160 or tick-last_tour_tick<40:return
	last_tour_tick=tick
	var stops:=[Ground.BRIDGE_VIEW,Vector2(42.,-14.),Ground.COURT,Ground.GROVE,Vector2(-37.,0.),Ground.CAMP]
	var stop:Vector2=stops[((tick-160)/40)%stops.size()]
	var inset:=field.hud.inset
	_click(inset.get_global_rect().position+inset._point(stop))
	notes.append({"tick":tick,"minimap_click":[stop.x,stop.y]})

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
		"hits":b.hits.duplicate(),"arrows_fired":b.arrow_count,"ram_strokes":b.objectives.strokes,"blocks":b.blocked_hits,"losses":b.losses.duplicate(),"gate_hp":b.gate_hp,
		"visible_ordinary":in_frame,"visible_shields":shields,"guarding":guards,"feet_in_deep_water":feet_inside,
		"crossed":crossed.size(),"soldier_shield_contacts":contacts.size(),"center":[field.camera_center.x,field.camera_center.y],"zoom":field.camera.size,"yaw":field.camera_yaw,
		"pitch":field.camera_pitch,"deck_screen":[bridge.x,bridge.y],"arch_screen":[arch.x,arch.y],
		"both_landmarks":canvas.has_point(bridge) and canvas.has_point(arch),"orders_delivered":b.messages_arrived,"result":b.result}

func _run() -> void:
	if DisplayServer.get_name()=="headless": get_tree().quit(1);return
	DirAccess.make_dir_recursive_absolute(out)
	progress_file=FileAccess.open(out+"/progress.jsonl",FileAccess.WRITE)
	var scene=get_parent()
	field=scene.field
	for i in 5: await get_tree().process_frame
	if OS.get_name()=="macOS":
		print("BRIDGE_FOCUS_READY ",JSON.stringify({"pid":OS.get_process_id(),"focused":root.has_focus()}))
		for attempt in 240:
			if root.has_focus():break
			await get_tree().process_frame
		if not root.has_focus():
			push_error("The hosted review window did not acquire focus")
			get_tree().quit(1)
			return
	if not await _select_bridge():
		push_error("The bridgehead plan could not be selected in its regular popup")
		get_tree().quit(1);return
	await RenderingServer.frame_post_draw
	var native:=root.get_texture().get_image()
	rendered_size=native.get_size()
	native.save_jpg(out+"/prepared-native.jpg",.95)
	if "--native-qhd" in OS.get_cmdline_user_args() and rendered_size!=Vector2i(2560,1440):
		push_error("Native render attachment must be QHD, got "+str(rendered_size))
		get_tree().quit(1)
		return
	if not is_equal_approx(root.scaling_3d_scale,1.):
		push_error("The review requires full internal render resolution")
		get_tree().quit(1)
		return
	print("BRIDGE_NATIVE_ATTACHMENT ",rendered_size," window=",DisplayServer.window_get_size()," internal=",root.scaling_3d_scale)
	if "--menu-only" in OS.get_cmdline_user_args():
		if "--light-study" in OS.get_cmdline_user_args():
			var before:=field.map.sun.rotation_degrees
			field.map.sun.rotation_degrees=Vector3(-48.,-31.,0.)
			await RenderingServer.frame_post_draw
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_jpg(out+"/previous-daylight-native.jpg",.95)
			field.map.sun.rotation_degrees=before
			var saved_center:=field.camera_center
			var saved_zoom:=field.camera.size
			var saved_follow:=field.follow
			for shot in [
					{"name":"whole-map-native","center":Vector2(9.,0.),"zoom":115.},
					{"name":"near-company-native","center":Vector2(35.,-1.),"zoom":12.},
					{"name":"grove-native","center":Vector2(38.,-10.),"zoom":18.}]:
				field.camera.size=shot.zoom
				field.pan_to(shot.center)
				field._process(Battle.DT)
				await RenderingServer.frame_post_draw
				await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_jpg(out+"/"+shot.name+".jpg",.95)
			field.camera.size=saved_zoom
			field.pan_to(saved_center)
			field.follow=saved_follow
		print("BRIDGE_MENU_INPUT_PASS")
		get_tree().quit(0)
		return
	var b:=field.battle
	for u in b.roster:
		if not u.hero and not u.officer and u.team==0 and u.pos.x<Ground.MOAT_X-3.: initial_west[u.id]=true
	_click(field.hud.go.get_global_rect().get_center())
	if not b.started:
		push_error("Deploy button failed")
		get_tree().quit(1);return
	first_game_frame=Engine.get_frames_drawn()
	var preview:="--bridge-stills" in OS.get_cmdline_user_args()
	var frames:=0
	wall_started=Time.get_ticks_usec()
	while frames<(100000 if real_time else (4320 if complete_battle else 960)) and b.result=="" and not field.paused:
		frames+=1
		if real_time and Time.get_ticks_usec()-wall_started>45000000:break
		if b.tick!=last_tick:
			last_tick=b.tick
			_drive()
			if camera_tour:_tour(b.tick)
			if not real_time or b.tick%25==0:
				var m:=_facts()
				snapshots.append(m)
				if b.tick%25==0:
					print("BRIDGE_TICK ",JSON.stringify(m))
					progress_file.store_line(JSON.stringify({"facts":m,"last_input":notes.back() if not notes.is_empty() else {}}))
					progress_file.flush()
			if not real_time and (b.tick in [15,50,75,105,145,185,245,355,460] or (b.hero.impacts>0 and not clicked)):
				if b.hero.impacts>0: clicked=true
				await RenderingServer.frame_post_draw
				var frame:=root.get_texture().get_image()
				screenshot_ok=frame.save_jpg(out+"/view-%04d.jpg"%b.tick,.94)==OK and screenshot_ok
				if "--native-plates" in OS.get_cmdline_user_args() and b.tick in [50,145]:
					screenshot_ok=frame.save_png(out+"/view-%04d.png"%b.tick)==OK and screenshot_ok
		await get_tree().process_frame
		if preview and b.tick>=150: break
	for key:Key in [KEY_W,KEY_S,KEY_A,KEY_D]: _key(key,false)
	if complete_battle and b.result!="":
		for index in 72:
			post_battle_frames+=1
			await get_tree().process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_jpg(out+"/battle-result-native.jpg",.95)
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
		"native_render_px":[rendered_size.x,rendered_size.y],"physical_window_px":[DisplayServer.window_get_size().x,DisplayServer.window_get_size().y],"post_battle_frames":post_battle_frames,"complete_battle_requested":complete_battle,"camera_tour":camera_tour,"wall_seconds":float(Time.get_ticks_usec()-wall_started)/1000000.,"real_time_profile":real_time,"game_source":OS.get_environment("RIVER_SOURCE_SHA"),"frames_of_play":frames,"sampled_ticks":snapshots.size(),"first_player_strike":first_blow,
		"held_both":clear_count,"feet_in_deep_water":entered_water,"different_lens":off_lens,
		"shield_contacts":contacts.values(),"rank_spear_contacts":troop_contacts,"resolution":[root.size.x,root.size.y],"internal":root.scaling_3d_scale,
		"camera_start":[Ground.BRIDGE_VIEW.x,Ground.BRIDGE_VIEW.y],"software":RenderingServer.get_video_adapter_name(),
		"last":fact,"frames":snapshots,"inputs":notes,"first_game_frame":first_game_frame,"physics_fps":Engine.physics_ticks_per_second,"world_audit":field.theater.audit().is_empty()}
	if field.frame_log:field.frame_log.interrupt("review_completed",field)
	var file:=FileAccess.open(out+"/input-and-camera.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(terminal,"  "))
	file.close()
	var ok:bool=screenshot_ok and b.ordinary_counts==PackedInt32Array([requested_side,requested_side]) and not entered_water and not off_lens and (camera_tour or clear_count>=snapshots.size()*.98) and (initial_west.is_empty() or crossed.size()>0) and fact.hits[0]+fact.hits[1]>0
	if not preview and not real_time: ok=ok and frames>=240 and first_blow>0 and contacts.size()>0
	if complete_battle:ok=ok and b.result!=""
	print("BRIDGE_WINDOW ",ok," ",JSON.stringify(fact)," first_player_strike=",first_blow," contacts=",contacts.size()," frames=",frames)
	get_tree().quit(0 if ok else 1)
