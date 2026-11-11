extends Node3D
const Battle := preload("res://scripts/field/battle.gd")
const Ground := preload("res://scripts/field/ground.gd")
const Figures := preload("res://scripts/field/presentation.gd")
const Landscape := preload("res://scripts/field/landscape.gd")
const Hud := preload("res://scripts/field/hud.gd")
const Sound := preload("res://scripts/field/sound.gd")
const Store := preload("res://scripts/field/save.gd")
const FieldWorld := preload("res://scripts/field/campaign.gd")
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
var follow := true
var paused := false
var pan := false
var carry := 0.0
var ui_clock := 0.0
var sim_us := 0
var view_us := 0
var max_step_us := 0
var selections := 512
var last_sound_tick := -20
var last_shot_tick := -20
var frame_log: RefCounted
var detail_preset:=0
const QUALITY_FILE:="user://river-gate-graphics.cfg"

func _ready() -> void:
	Actions.install()
	add_child(map)
	add_child(camera)
	camera.projection=Camera3D.PROJECTION_ORTHOGONAL
	camera.size=26.0
	camera.far=360
	camera.current=true
	add_child(hud)
	add_child(audio)
	hud.deploy.connect(deploy)
	hud.pause.connect(toggle_pause)
	hud.terrain_chosen.connect(pan_to)
	hud.quality_changed.connect(func(index: int): set_quality(index,true))
	hud.campaign.connect(func(): campaign_requested.emit())
	hud.retry.connect(func(): new_muster(selections))
	hud.weapon_changed.connect(func(i: int):
		battle.equip_hero(i))
	hud.order_requested.connect(_order)
	hud.save_requested.connect(_save)
	hud.load_requested.connect(_load)
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--field-size="):
			var count := arg.trim_prefix("--field-size=").to_int()
			if count in Battle.SCALES: selections=count
	var cfg:=ConfigFile.new()
	if cfg.load(QUALITY_FILE)==OK: detail_preset=clampi(int(cfg.get_value("display","preset",0)),0,2)
	new_muster(selections)
	if "--field-profile" in OS.get_cmdline_user_args():
		frame_log = preload("res://scripts/field/frame_log.gd").new()
		frame_log.open(get_viewport())

func new_muster(count: int) -> void:
	var fresh := Battle.new()
	fresh.setup(count)
	_adopt(fresh)
	paused=false
	hud.order_panel.show()

func _adopt(fresh: Battle) -> void:
	if view:
		remove_child(view)
		view.free()
	battle=fresh
	theater=FieldWorld.new()
	if not theater.bind(fresh):
		push_error("Field roster does not match opening inventory")
		return
	selections=battle.side_size
	view=Figures.new()
	add_child(view)
	view.configure(battle)
	set_quality(detail_preset)
	camera_center=battle.hero.pos
	follow=true
	carry=0
	hud.bind(battle)
	_camera()
	_draw_field()

func set_quality(which: int,remember: bool=false) -> void:
	if which<0 or which>2: return
	if frame_log and which!=detail_preset: frame_log.interrupt("changed_graphics",self)
	detail_preset=which
	var vp:=get_viewport()
	vp.scaling_3d_mode=Viewport.SCALING_3D_MODE_BILINEAR
	vp.scaling_3d_scale=[1.0,0.85,0.70][which]
	map.sun.shadow_enabled=which!=2
	map.sun.directional_shadow_max_distance=75.0 if which==0 else 48.0
	view.contact_for_all=not map.sun.shadow_enabled
	hud.quality.select(which)
	if remember:
		var cfg:=ConfigFile.new()
		cfg.set_value("display","preset",which)
		cfg.save(QUALITY_FILE)

func deploy() -> void:
	if battle.result!="" or battle.started: return
	if not theater.reserve():
		battle.notice="军籍与库存不符，无法出阵"
		return
	battle.start()
	hud.order_panel.hide()
	audio.cue("horn",-10)
	hud.update_model(battle,paused)

func toggle_pause() -> void:
	if battle.started and battle.result=="":
		paused=not paused
		hud.update_model(battle,paused)

func _order(company: int,mission: int,channel: int) -> void:
	if battle.command(company,mission,channel):
		if battle.started and channel==Battle.Channel.HORN: audio.cue("horn",-10)
	hud.update_model(battle,paused)

func _save() -> void:
	battle.notice = "战场进度已保存" if Store.save(battle)==OK else "保存失败，原存档仍可使用"
	hud.update_model(battle,paused)

func _load() -> void:
	var saved := Store.load_quick()
	if saved:
		_adopt(saved)
		paused=saved.started and saved.result==""
		hud.order_panel.visible=not saved.started
		battle.notice="已恢复战场"
	else:
		battle.notice="未找到可用的战场存档"
	hud.update_model(battle,paused)

func _camera() -> void:
	var p := Ground.unit_point(camera_center)
	camera_pitch=lerpf(deg_to_rad(31.0),deg_to_rad(51.0),smoothstep(7.0,23.0,camera.size))
	camera.position=p+Vector3(0,sin(camera_pitch),cos(camera_pitch))*77.5
	camera.look_at(p)
	camera.current=true

func pan_to(p: Vector2) -> void:
	follow=false
	camera_center=p.clamp(-Ground.LIMIT,Ground.LIMIT)
	_camera()

func _screen_ground(point: Vector2) -> Vector2:
	var origin := camera.project_ray_origin(point)
	var dir := camera.project_ray_normal(point)
	var t := -origin.y/dir.y
	var p := Vector2(origin.x+dir.x*t,origin.z+dir.z*t)
	for i in 2:
		t=(Ground.deck_height(p)-origin.y)/dir.y
		p=Vector2(origin.x+dir.x*t,origin.z+dir.z*t)
	return p

func _unhandled_input(e: InputEvent) -> void:
	if not battle or e.is_echo(): return
	if e is InputEventMouseButton:
		match e.button_index:
			MOUSE_BUTTON_RIGHT, MOUSE_BUTTON_MIDDLE:
				pan=e.pressed
			MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN:
				if e.pressed:
					camera.size=clampf(camera.size*(0.83 if e.button_index==MOUSE_BUTTON_WHEEL_UP else 1.20),5.8,115)
	elif e is InputEventMouseMotion and pan:
		if e.button_mask & (MOUSE_BUTTON_MASK_RIGHT | MOUSE_BUTTON_MASK_MIDDLE):
			pan_to(camera_center+_screen_ground(e.position-e.relative)-_screen_ground(e.position))
		else:
			pan=false
	if e.is_action_pressed("field_deploy"): deploy()
	elif e.is_action_pressed("pause_battle"): toggle_pause()
	elif e.is_action_pressed("field_center"): follow=true
	elif e.is_action_pressed("field_orders"): hud.order_panel.visible=not hud.order_panel.visible
	elif e.is_action_pressed("toggle_help"): hud.toggle_help=not hud.toggle_help
	elif e.is_action_pressed("campaign_quicksave"): _save()
	elif e.is_action_pressed("campaign_quickload"): _load()
	elif e.is_action_pressed("field_mount") and not paused: battle.mount(1)
	elif e.is_action_pressed("field_chariot") and not paused: battle.mount(2)
	elif e.is_action_pressed("order_attack"): _order(hud.unit.selected,Battle.Mission.PRESS,hud.channel.selected)
	elif e.is_action_pressed("order_follow"): _order(hud.unit.selected,Battle.Mission.HOLD,hud.channel.selected)
	elif e.is_action_pressed("order_retreat"): _order(hud.unit.selected,Battle.Mission.WITHDRAW,hud.channel.selected)
	elif not paused and battle.started:
		for i in 3:
			if e.is_action_pressed(["sweep","lunge","guard"][i]):
				battle.input_state(Actions.movement(),_screen_ground(get_viewport().get_mouse_position())-battle.hero.pos)
				battle.action(i+1)

func _physics_process(delta: float) -> void:
	if not battle or paused or not battle.started or battle.result!="": return
	carry+=delta
	while carry+0.000001>=Battle.DT:
		carry=maxf(0,carry-Battle.DT)
		var pointer := get_viewport().get_mouse_position()
		battle.input_state(Actions.movement(),_screen_ground(pointer)-battle.hero.pos)
		if Input.is_action_pressed("attack") and (Input.is_physical_key_pressed(KEY_J) or get_viewport().gui_get_hovered_control()==null):
			battle.action(0)
		var arrows_before := battle.arrow_count
		var gate_before := battle.gate_hp
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
		if battle.gate_hp<gate_before and camera_center.distance_to(Ground.GATE)<32:
			audio.cue("wood",-12)
		if battle.arrow_count>arrows_before and battle.tick-last_shot_tick>=8:
			for shot in battle.shots:
				if shot.distance<2.0 and camera_center.distance_squared_to(shot.pos)<100:
					audio.cue("shot",-21)
					last_shot_tick=battle.tick
					break
		if battle.tick-last_sound_tick>=5:
			for id in battle._near(camera_center,minf(camera.size*0.40,12),1):
				if battle.roster[id].flash>=0.20:
					audio.cue("clash",-20.0)
					last_sound_tick=battle.tick
					break

func _draw_field() -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	var half_extent := Vector2(camera.size*viewport_size.x/maxf(viewport_size.y,1)*0.5+4,0.5*camera.size/sin(camera_pitch)+6)
	var t := Time.get_ticks_usec()
	view.sync_view(camera_center,half_extent,clampf(carry/Battle.DT,0,1),camera.size)
	map.update_battle(battle)
	hud.inset.locate(camera_center,battle.hero.pos,battle.hero.facing,half_extent-Vector2(4,6))
	view_us+=Time.get_ticks_usec()-t

func _process(delta: float) -> void:
	if not battle: return
	if follow: camera_center=camera_center.lerp(battle.hero.pos,1.0-exp(-delta*7.5))
	_camera()
	_draw_field()
	if frame_log: frame_log.sample(self)
	ui_clock+=delta
	if ui_clock>=0.13:
		ui_clock=0
		hud.update_model(battle,paused)
		hud.show_world(theater.own_supply(),theater.loose_weapons,not theater.receipt.is_empty())

func _notification(what: int) -> void:
	if what==NOTIFICATION_APPLICATION_FOCUS_OUT and battle and battle.started: paused=true

func _exit_tree() -> void:
	if frame_log: frame_log.interrupt("left_battlefield",self)
