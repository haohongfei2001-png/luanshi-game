extends Node3D
const Battle := preload("res://scripts/field/battle.gd")
const Ground := preload("res://scripts/field/ground.gd")
const Figures := preload("res://scripts/field/presentation.gd")
const Landscape := preload("res://scripts/field/river_master_map.gd")
const Hud := preload("res://scripts/field/hud.gd")
const Sound := preload("res://scripts/field/sound.gd")
const Store := preload("res://scripts/field/save.gd")
const FieldWorld := preload("res://scripts/field/campaign.gd")
const Patrol := preload("res://scripts/field/patrol_muster.gd")
const Actions := preload("res://scripts/input_actions.gd")
signal campaign_requested
var battle: Battle
var theater: FieldWorld
var view: Figures
var map := Landscape.new()
var hud := Hud.new()
var audio := Sound.new()
var camera := Camera3D.new()
var camera_center := Vector2.ZERO
var camera_pitch:=deg_to_rad(51.0)
var camera_yaw:=deg_to_rad(-33.0)
var shadow_zoom:=-1.0
const CAMERA_DISTANCE:=77.5
var orbiting:=false
var follow := true
var paused := false
var pan := false
var carry := 0.0
var ui_clock := 0.0
var sim_us := 0
var view_us := 0
var max_step_us := 0
var selections := 512
var opposing_selection := -1
var last_sound_tick := -20
var last_shot_tick := -20
var frame_log: RefCounted
enum Quality { NATIVE_MSAA, BALANCED, PERFORMANCE, NATIVE_SINGLE_SAMPLE }
const QUALITY_SCALES := [1.0, 0.85, 0.70, 1.0]
var detail_preset:=Quality.NATIVE_MSAA
enum DisplayChoice { WINDOW, SCREEN, QHD, UHD }
const DISPLAY_PIXELS:=[Vector2i.ZERO,Vector2i.ZERO,Vector2i(2560,1440),Vector2i(3840,2160)]
var windowed_size:=Vector2i.ZERO
var windowed_position:=Vector2i.ZERO
var last_hero_hit:=-100
var step_distance:=0.0
const QUALITY_FILE:="user://river-gate-graphics.cfg"

func _ready() -> void:
	Actions.install()
	var cfg:=ConfigFile.new()
	if cfg.load(QUALITY_FILE)==OK: detail_preset=clampi(int(cfg.get_value("display","preset",0)),0,QUALITY_SCALES.size()-1)
	# Register the saved viewport format before the first terrain meshes and
	# soldier batches enter the renderer. Their first pipelines then use it.
	_apply_viewport_quality(detail_preset)
	add_child(map)
	add_child(camera)
	camera.projection=Camera3D.PROJECTION_ORTHOGONAL
	camera.size=22.0
	camera.far=360
	camera.current=true
	add_child(hud)
	# Old saves and menu entries keep their original numerical indices.
	hud.quality.set_item_text(Quality.NATIVE_MSAA,"清晰 100% · 4× 抗锯齿")
	hud.quality.add_item("原生 100% · 无抗锯齿")
	add_child(audio)
	if DisplayServer.get_name()!="headless":
		windowed_size=get_window().size
		windowed_position=get_window().position
		hud.display_mode.item_selected.connect(_choose_display)
		get_window().size_changed.connect(_refresh_display)
		hud.display_mode.get_popup().about_to_popup.connect(_refresh_display)
		var mode:=int(cfg.get_value("display","mode",DisplayChoice.WINDOW))
		if mode>DisplayChoice.WINDOW and mode<DISPLAY_PIXELS.size(): _choose_display(mode,false)
		_refresh_display()
	hud.deploy.connect(deploy)
	hud.pause.connect(toggle_pause)
	hud.terrain_chosen.connect(pan_to)
	hud.quality_changed.connect(func(index: int): set_quality(index,true))
	hud.campaign.connect(func(): campaign_requested.emit())
	hud.plan_requested.connect(func(style: int):
		if battle.started: return
		if style==5:
			new_muster(selections,opposing_selection,true,battle.hero.kit)
			return
		if style==4:
			patrol_muster()
			return
		if battle.world_patrol and style==0:
			new_muster(512)
			return
		if battle.bridgehead and style==0:
			new_muster(selections,opposing_selection,false,battle.hero.kit)
			return
		battle.objectives.task=Battle.Objectives.Task.ESCORT if style==3 else Battle.Objectives.Task.COURT
		if style==0:
			hud.update_model(battle,paused)
			return
		for i in battle.companies_per_side:
			var mission:=Battle.Mission.PRESS
			if style in [1,3]:
				if style==3 and i%4 in [1,2]: mission=Battle.Mission.ESCORT
				elif i in [2,7]: mission=Battle.Mission.ESCORT
				elif i in [0,4]: mission=Battle.Mission.FLANK
			else: mission=Battle.Mission.HOLD if i%4==3 else Battle.Mission.WITHDRAW
			battle.command(i,mission,Battle.Channel.FLAG)
		hud.select_company(battle,hud.unit.selected)
		battle.notice="全军任务已分配，可逐队调整"
		hud.update_model(battle,paused))
	hud.muster_apply.connect(func(index: int,slot: int,shape: int,front: int):
		if battle.deploy_company(index,slot,shape,front):
			battle.notice="部署已定 · %02d 队 %s" % [index+1,Battle.FORMATIONS[shape]]
			hud.select_company(battle,index)
			pan_to(battle.companies[index].home))
	hud.unit.item_selected.connect(func(i: int):
		hud.select_company(battle,i)
		if not battle.started: pan_to(battle.companies[i].home))
	hud.camp_requested.connect(func():
		if theater.enter_camp(): _refresh_hud())
	hud.camp_order.connect(func(command: String):
		if theater.camp_order(command): _refresh_hud())
	hud.camp_wait.connect(func():
		if theater.wait_at_camp(): _refresh_hud())
	hud.back_report.connect(func():
		battle.at_camp=false
		_refresh_hud())
	hud.retry.connect(func():
		if battle.world_patrol: patrol_muster()
		else: new_muster(selections,opposing_selection,battle.bridgehead))
	hud.weapon_changed.connect(func(i: int):
		battle.equip_hero(i))
	hud.order_requested.connect(_order)
	hud.save_requested.connect(_save)
	hud.load_requested.connect(_load)
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--field-size="):
			var count := arg.trim_prefix("--field-size=").to_int()
			if count in Battle.SCALES: selections=count
	new_muster(selections)
	if "--field-profile" in OS.get_cmdline_user_args():
		frame_log = preload("res://scripts/field/frame_log.gd").new()
		frame_log.open(get_viewport())

func new_muster(count: int,defenders: int=-1,at_moat: bool=false,weapon: int=Battle.Arms.Kit.SPEAR) -> void:
	var fresh := Battle.new()
	fresh.setup(count,Battle.SEED,weapon,true,true,defenders,at_moat)
	if not _adopt(fresh): return
	paused=false
	hud.order_panel.show()

func patrol_muster() -> void:
	var world:=FieldWorld.new()
	if not Patrol.arrive(world,Battle.SEED): return
	var manifest:=world.snapshot()
	var relief: Dictionary=manifest.armies.relief
	var garrison: Dictionary=manifest.cities.hequ
	var own:=Patrol.ordinary_for(relief.soldiers,relief.weapons,true)
	var opposing:=Patrol.ordinary_for(garrison.soldiers,garrison.weapons)
	if mini(own,opposing)<=0: return
	var fresh:=Battle.new()
	fresh.setup(own,Battle.SEED,Battle.Arms.Kit.SPEAR,true,true,opposing)
	fresh.world_patrol=true
	if not _adopt(fresh): return
	paused=false
	hud.order_panel.show()

func _adopt(fresh: Battle) -> bool:
	var candidate:=FieldWorld.new()
	if not candidate.bind(fresh): return false
	if view:
		remove_child(view)
		view.free()
	if map.bridgehead!=fresh.bridgehead:
		remove_child(map)
		map.free()
		map=Landscape.new()
		map.bridgehead=fresh.bridgehead
		add_child(map)
	battle=fresh
	theater=candidate
	selections=battle.side_size
	opposing_selection=battle.ordinary_counts[1]
	view=Figures.new()
	add_child(view)
	view.configure(battle)
	set_quality(detail_preset)
	camera_center=Ground.BRIDGE_VIEW if battle.bridgehead else battle.hero.pos
	follow=true
	if battle.bridgehead:
		camera.size=22.
		camera_yaw=deg_to_rad(-33.)
	last_hero_hit=-100
	step_distance=0
	carry=0
	hud.bind(battle)
	hud.continue_slot.visible=not battle.started and FileAccess.file_exists(Store.FILE)
	_refresh_hud()
	_camera()
	_draw_field()
	return true

func _apply_viewport_quality(which: int) -> void:
	var vp:=get_viewport()
	var samples:=Viewport.MSAA_4X if which==Quality.NATIVE_MSAA else Viewport.MSAA_DISABLED
	if vp.msaa_3d!=samples: vp.msaa_3d=samples
	if vp.scaling_3d_mode!=Viewport.SCALING_3D_MODE_BILINEAR:
		vp.scaling_3d_mode=Viewport.SCALING_3D_MODE_BILINEAR
	if not is_equal_approx(vp.scaling_3d_scale,QUALITY_SCALES[which]):
		vp.scaling_3d_scale=QUALITY_SCALES[which]

func set_quality(which: int,remember: bool=false) -> void:
	if which<0 or which>=QUALITY_SCALES.size(): return
	if frame_log and which!=detail_preset: frame_log.interrupt("changed_graphics",self)
	detail_preset=which
	_apply_viewport_quality(which)
	map.sun.shadow_enabled=which!=Quality.PERFORMANCE
	shadow_zoom=-1.0
	view.contact_for_all=not map.sun.shadow_enabled
	hud.quality.select(which)
	if DisplayServer.get_name()!="headless": _refresh_display.call_deferred()
	if remember:
		var cfg:=ConfigFile.new()
		cfg.load(QUALITY_FILE)
		cfg.set_value("display","preset",which)
		cfg.save(QUALITY_FILE)

func _refresh_display() -> void:
	var win:=get_window()
	var screen:=DisplayServer.screen_get_size(win.current_screen)
	for i in range(DisplayChoice.QHD,DISPLAY_PIXELS.size()):
		var wanted:Vector2i=DISPLAY_PIXELS[i]
		hud.display_mode.set_item_disabled(i,wanted.x>screen.x or wanted.y>screen.y)
	var pixels:=win.get_texture().get_size()
	if pixels.x>0 and pixels.y>0:
		var rendered:=Vector2i((Vector2(pixels)*win.scaling_3d_scale).round())
		hud.physical_size.text="3D  %d × %d"%[rendered.x,rendered.y]

func _choose_display(index: int,remember: bool=true) -> void:
	if index<0 or index>=DISPLAY_PIXELS.size(): return
	var win:=get_window()
	var screen:=DisplayServer.screen_get_size(win.current_screen)
	var wanted:Vector2i=DISPLAY_PIXELS[index]
	if wanted.x>screen.x or wanted.y>screen.y:
		_refresh_display()
		return
	if win.mode==Window.MODE_WINDOWED and not win.borderless:
		windowed_size=win.size
		windowed_position=win.position
	if index==DisplayChoice.SCREEN:
		# Size the drawable before requesting native fullscreen. A hosted X11
		# display can have no window manager to deliver a configure event.
		win.mode=Window.MODE_WINDOWED
		win.size=screen
		win.mode=Window.MODE_FULLSCREEN
	elif index==DisplayChoice.WINDOW:
		win.mode=Window.MODE_WINDOWED
		win.borderless=false
		if windowed_size.x>0:
			win.size=windowed_size
			win.position=windowed_position
	else:
		win.mode=Window.MODE_WINDOWED
		win.borderless=true
		win.size=wanted
		win.position=DisplayServer.screen_get_position(win.current_screen)+Vector2i(Vector2(screen-wanted)*.5)
	hud.display_mode.select(index)
	if index>=DisplayChoice.QHD and not is_equal_approx(QUALITY_SCALES[detail_preset],1.0):
		if view: set_quality(Quality.NATIVE_MSAA,remember)
		else: detail_preset=Quality.NATIVE_MSAA
	if remember:
		var cfg:=ConfigFile.new()
		cfg.load(QUALITY_FILE)
		cfg.set_value("display","mode",index)
		cfg.save(QUALITY_FILE)
	_refresh_display.call_deferred()

func deploy() -> void:
	if battle.result!="" or battle.started: return
	if not theater.reserve():
		battle.notice="军籍与库存不符，无法出阵"
		return
	battle.start()
	follow=true
	hud.order_panel.hide()
	audio.cue("horn",-10)
	hud.update_model(battle,paused)

func toggle_pause() -> void:
	if battle.started and battle.result=="":
		paused=not paused
		hud.update_model(battle,paused)

func _order(company: int,mission: int,channel: int) -> void:
	if battle.command(company,mission,channel):
		if battle.started:
			hud.order_panel.hide()
			get_viewport().gui_release_focus()
			if channel==Battle.Channel.HORN: audio.cue("horn",-10)
	hud.update_model(battle,paused)

func _save() -> void:
	var ok:=Store.save(battle)==OK
	if ok and not battle.started: hud.continue_slot.show()
	battle.notice = "战场进度已保存" if ok else "保存失败，原存档仍可使用"
	hud.update_model(battle,paused)

func _load() -> void:
	var saved := Store.load_quick()
	if saved and _adopt(saved):
		paused=saved.started and saved.result==""
		hud.order_panel.visible=not saved.started
		battle.notice="已恢复战场"
	else:
		battle.notice="存档与军籍不符，当前战场已保留" if saved else "未找到可用的战场存档"
	_refresh_hud()

func _camera() -> void:
	var p := Ground.unit_point(camera_center,battle.bridgehead)
	camera_pitch=lerpf(deg_to_rad(31.0),deg_to_rad(51.0),smoothstep(7.0,23.0,camera.size))
	camera.position=p+Vector3(sin(camera_yaw)*cos(camera_pitch),sin(camera_pitch),cos(camera_yaw)*cos(camera_pitch))*CAMERA_DISTANCE
	camera.look_at(p)
	if not is_equal_approx(shadow_zoom,camera.size):
		# Orthographic projection keeps its composition as the clipping slab tightens.
		# Include the ground below the camera target and the shadow of the gate roof.
		var ground_depth:=camera.size*.5/tan(camera_pitch)
		camera.near=maxf(.1,CAMERA_DISTANCE-ground_depth-17.0)
		map.sun.directional_shadow_max_distance=CAMERA_DISTANCE+ground_depth*(1.0 if QUALITY_SCALES[detail_preset]==1.0 else .75)+11.0
		map.sun.directional_shadow_fade_start=.93
		shadow_zoom=camera.size
	camera.current=true

func pan_to(p: Vector2) -> void:
	follow=false
	camera_center=p.clamp(-Ground.LIMIT,Ground.LIMIT)
	_camera()

func _screen_ground(point: Vector2) -> Vector2:
	var origin:=camera.project_ray_origin(point)
	var dir:=camera.project_ray_normal(point)
	# Traverse from above the tallest deck to below the river bed, then refine
	# the first surface. Iterating from a flat plane misses uphill narrow attacks.
	var top: float=(5.8-origin.y)/dir.y
	var bottom: float=(-1.3-origin.y)/dir.y
	var previous:=top
	for sample in range(1,13):
		var at:=lerpf(top,bottom,sample/12.0)
		var p:=origin+dir*at
		if p.y<=Ground.deck_height(Vector2(p.x,p.z),battle.bridgehead):
			var lo:=previous
			var hi:=at
			for i in 10:
				var mid: float=(lo+hi)*0.5
				var q:=origin+dir*mid
				if q.y>Ground.deck_height(Vector2(q.x,q.z),battle.bridgehead): lo=mid
				else: hi=mid
			p=origin+dir*((lo+hi)*0.5)
			return Vector2(p.x,p.z)
		previous=at
	var end:=origin+dir*bottom
	return Vector2(end.x,end.z)

func _aim_point(screen: Vector2,target_figures: bool) -> Vector2:
	var floor_point:=_screen_ground(screen)
	if not target_figures: return floor_point
	var best:=floor_point
	var best_score:=INF
	# In the orthographic player camera a shoulder spans the same number of pixels
	# everywhere. Measure across the screen so orbiting preserves that width.
	var base:=Ground.unit_point(floor_point,battle.bridgehead)
	var shoulder:=camera.global_transform.basis.x.normalized()*0.32
	var radius:=maxf(2.0,camera.unproject_position(base+shoulder).distance_to(camera.unproject_position(base)))
	# A cursor resting on a visible torso selects that ground direction at the
	# start of the strike. Melee reach, flight and obstruction remain in Battle.
	for id in battle._near(floor_point,4.8,1):
		var u:=battle.roster[id]
		if battle.hero.pos.distance_squared_to(u.pos)>34.0*34.0: continue
		var foot:=Ground.unit_point(u.pos,battle.bridgehead)
		var head:=foot+Vector3.UP*(2.45 if u.mounted else 1.70)
		var low:=camera.unproject_position(foot)
		var high:=camera.unproject_position(head)
		var d:=screen.distance_to(Geometry2D.get_closest_point_to_segment(screen,low,high))
		if d>radius: continue
		var score:=d/radius+0.001*screen.distance_to(low)
		if score>=best_score: continue
		var elevated:=Ground.parapet(u.pos)>2.75 or Ground.parapet(battle.hero.pos)>2.75
		if not Ground.clear_shot(battle.hero.pos,u.pos,battle.gate_hp<=0,elevated): continue
		best_score=score
		best=u.pos
	return best

func _input(e: InputEvent) -> void:
	if not battle or not is_visible_in_tree() or e.is_echo() or battle.result!="": return
	if e.is_action_pressed("field_orders"):
		for menu in [hud.weapon,hud.plan,hud.unit,hud.mission,hud.channel,hud.quality,hud.shape,hud.front,hud.slot]:
			if menu.get_popup().visible: return
		hud.order_panel.visible=not hud.order_panel.visible
		get_viewport().gui_release_focus()
		get_viewport().set_input_as_handled()

func _unhandled_input(e: InputEvent) -> void:
	if not battle or e.is_echo(): return
	if e is InputEventMouseButton:
		match e.button_index:
			MOUSE_BUTTON_RIGHT:
				pan=e.pressed
			MOUSE_BUTTON_MIDDLE:
				orbiting=e.pressed
			MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN:
				if e.pressed:
					camera.size=clampf(camera.size*(0.83 if e.button_index==MOUSE_BUTTON_WHEEL_UP else 1.20),5.8,115)
	elif e is InputEventMouseMotion and orbiting:
		if e.button_mask & MOUSE_BUTTON_MASK_MIDDLE:
			camera_yaw=wrapf(camera_yaw-e.relative.x*0.009,-PI,PI)
			_camera()
		else: orbiting=false
	elif e is InputEventMouseMotion and pan:
		if e.button_mask & MOUSE_BUTTON_MASK_RIGHT:
			pan_to(camera_center+_screen_ground(e.position-e.relative)-_screen_ground(e.position))
		else:
			pan=false
	if e.is_action_pressed("field_deploy"): deploy()
	elif e.is_action_pressed("pause_battle"): toggle_pause()
	elif e.is_action_pressed("field_center"): follow=true
	elif e.is_action_pressed("toggle_help"): hud.toggle_help=not hud.toggle_help
	elif e.is_action_pressed("campaign_quicksave"): _save()
	elif e.is_action_pressed("campaign_quickload"): _load()
	elif e.is_action_pressed("field_mount") and not paused: battle.mount(1)
	elif e.is_action_pressed("field_chariot") and not paused: battle.mount(2)
	elif e.is_action_pressed("order_attack"): _order(hud.unit.selected,Battle.Mission.PRESS,hud.channel.selected)
	elif e.is_action_pressed("order_follow"): _order(hud.unit.selected,Battle.Mission.HOLD,hud.channel.selected)
	elif e.is_action_pressed("order_retreat"): _order(hud.unit.selected,Battle.Mission.WITHDRAW,hud.channel.selected)
	elif not paused and battle.started and battle.result=="":
		if e.is_action_pressed("attack"):
			battle.input_state(Actions.movement().rotated(-camera_yaw),_aim_point(get_viewport().get_mouse_position(),true)-battle.hero.pos)
			_submit_attack(0)
		for i in 3:
			if e.is_action_pressed(["sweep","lunge","guard"][i]):
				battle.input_state(Actions.movement().rotated(-camera_yaw),_aim_point(get_viewport().get_mouse_position(),true)-battle.hero.pos)
				_submit_attack(i+1)

func _submit_attack(slot: int) -> void:
	var at:=Time.get_ticks_usec()
	if battle.press_action(slot) and frame_log:
		frame_log.accepted(slot,at)

func _physics_process(delta: float) -> void:
	if not battle or paused or not battle.started or battle.result!="": return
	carry+=delta
	while carry+0.000001>=Battle.DT:
		carry=maxf(0,carry-Battle.DT)
		var pointer := get_viewport().get_mouse_position()
		var attacking:=Input.is_action_pressed("attack") and (Input.is_physical_key_pressed(KEY_J) or get_viewport().gui_get_hovered_control()==null)
		battle.input_state(Actions.movement().rotated(-camera_yaw),_aim_point(pointer,attacking)-battle.hero.pos)
		battle.sprinting=Input.is_action_pressed("field_sprint")
		if attacking and battle.buffered_slot<0:
			battle.action(0)
		var arrows_before := battle.arrow_count
		var gate_before := battle.gate_hp
		var personal:=battle.hero.impacts
		var bruises:=battle.hero.received
		var motion_before:=battle.hero.pos
		var pose_before:=battle.hero.state
		var start := Time.get_ticks_usec()
		battle.step()
		if battle.tick%20==0 or battle.result!="":
			if not theater.sync() or (battle.result!="" and theater.settle().is_empty()):
				paused=true
				push_error("Field world clock or settlement audit failed")
				return
		var cost := Time.get_ticks_usec()-start
		sim_us+=cost
		max_step_us=maxi(max_step_us,cost)
		var near_hero:=camera_center.distance_squared_to(battle.hero.pos)<400
		if battle.hero.impacts>personal:
			last_hero_hit=battle.tick
			if near_hero: _cue_at("impact",-8,battle.hero.pos)
		if near_hero and battle.hero.received>bruises:
			_cue_at("shield" if battle.hero.contact_blocked else "wood",-9,battle.hero.pos)
		if near_hero and pose_before==Battle.State.WINDUP and battle.hero.state==Battle.State.RECOVER and battle.hero.kit not in [5,6]:
			_cue_at("swing",-19,battle.hero.pos)
		step_distance+=motion_before.distance_to(battle.hero.pos)
		var step_length:=2.40 if battle.vehicle!=0 else 1.28
		if step_distance>=step_length:
			step_distance=fmod(step_distance,step_length)
			if near_hero: _cue_at("step" if battle.vehicle==0 else "hoof",-21 if battle.vehicle==0 else -15,battle.hero.pos)
		if battle.tick%161==1: audio.cue("wind",-28,0.45)
		if battle.tick in [4,13,24] or (battle.gate_hp==0 and gate_before>0): _cue_at("drum",-14,battle.ram)
		if battle.gate_hp<gate_before and camera_center.distance_to(Ground.GATE)<32:
			_cue_at("wood",-12,Ground.GATE)
		if battle.arrow_count>arrows_before and battle.tick-last_shot_tick>=8:
			for shot in battle.shots:
				if shot.distance<2.0 and camera_center.distance_squared_to(shot.pos)<100:
					_cue_at("shot",-18,shot.pos)
					last_shot_tick=battle.tick
					break
		if battle.tick-last_sound_tick>=5:
			for id in battle._near(camera_center,minf(camera.size*0.40,12),1):
				if battle.roster[id].contact_tick==battle.tick:
					_cue_at("shield" if battle.roster[id].contact_blocked else "clash",-17,battle.roster[id].pos)
					last_sound_tick=battle.tick
					break

func _cue_at(kind: String,level: float,at: Vector2) -> void:
	var offset:=at-camera_center
	var right:=Vector2(camera.basis.x.x,camera.basis.x.z)
	audio.cue(kind,level-minf(12.0,offset.length()*0.22),clampf(offset.dot(right)/maxf(5,camera.size*0.45),-1,1))

func _draw_field() -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	var hw:=camera.size*viewport_size.x/maxf(viewport_size.y,1)*0.5
	var hd:=0.5*camera.size/sin(camera_pitch)
	var co:=absf(cos(camera_yaw))
	var si:=absf(sin(camera_yaw))
	var half_extent:=Vector2(co*hw+si*hd+4,si*hw+co*hd+6)
	var hero:=battle.hero
	hud.marker.visible=battle.result=="" and camera.is_position_in_frustum(Ground.unit_point(hero.pos,battle.bridgehead))
	if hud.marker.visible:
		var hp:=Ground.unit_point(hero.before.lerp(hero.pos,clampf(carry/Battle.DT,0,1)),battle.bridgehead)
		var at:=camera.unproject_position(hp)
		var ahead:=camera.unproject_position(hp+Vector3(hero.facing.x,0,hero.facing.y))
		hud.marker.project(at,ahead-at,camera.unproject_position(hp+camera.basis.x*0.5).distance_to(at),clampf(1.0-(battle.tick-last_hero_hit)*0.21,0,1),clampf(hero.flash/0.22,0,1),battle.bridgehead)
	var t := Time.get_ticks_usec()
	view.sync_view(camera_center,half_extent,clampf(carry/Battle.DT,0,1),camera.size)
	if frame_log: frame_log.pose_submitted(battle)
	map.update_battle(battle)
	map.reveal_sightline(camera_center,battle.hero.pos,camera.position,camera.size,battle.started and battle.result=="",battle.gate_hp<260.0 or battle.ram.x>Ground.WALL_X-12.0)
	hud.inset.locate(camera_center,battle.hero.pos,battle.hero.facing,Vector2(hw,hd),camera_yaw)
	view_us+=Time.get_ticks_usec()-t

func _process(delta: float) -> void:
	if not battle: return
	if follow:
		# The gate watch keeps the crossing and arch in view while the player
		# advances. Follow again when they actually leave the approach.
		var focus:=battle.hero.pos
		if battle.bridgehead:
			var offset:=focus-Ground.BRIDGE_VIEW
			focus=Ground.BRIDGE_VIEW+offset-offset.clamp(Vector2(-17.,-4.8),Vector2(12.,4.8))
		camera_center=camera_center.lerp(focus,1.0-exp(-delta*7.5))
	_camera()
	_draw_field()
	if frame_log: frame_log.sample(self)
	ui_clock+=delta
	if ui_clock>=0.13:
		ui_clock=0
		_refresh_hud()

func _refresh_hud() -> void:
	hud.update_model(battle,paused)
	if not theater.receipt.is_empty(): hud.show_receipt(battle,theater.receipt,theater.player_view())

func _notification(what: int) -> void:
	if what==NOTIFICATION_APPLICATION_FOCUS_OUT and battle and battle.started: paused=true

func _exit_tree() -> void:
	if frame_log: frame_log.interrupt("left_battlefield",self)
