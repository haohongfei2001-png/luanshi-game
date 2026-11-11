extends SceneTree
## The normal shipping shell. The driver uses the UI and mapped input only;
## it never writes a fighter, timer, result, order, inventory or camera position.
const Field:=preload("res://scripts/field/controller.gd")
const Battle:=preload("res://scripts/field/battle.gd")
const Ground:=preload("res://scripts/field/ground.gd")
const Arms:=preload("res://scripts/field/arms.gd")
var field: Field
var errors: Array[String]=[]
var screens: Array[String]=[]
var menu_activations:=0

func _initialize() -> void:
	_run.call_deferred()

func _check(ok: bool,msg: String) -> bool:
	if not ok:
		errors.append(msg)
		push_error("PLAYTHROUGH "+msg)
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

func _choose(c: OptionButton,index: int) -> void:
	await _click(c)
	var popup:=c.get_popup()
	if not _check(popup.visible,"Opened menu "+str(c.name)): return
	# X11 delivers these keys to the focused Godot popup window. Sending an
	# action only to the main viewport does not exercise a child window.
	for round_index in 3:
		var focus:=popup.get_focused_item()
		if focus==index: break
		var distance: int=1 if focus<0 else (index-focus+c.item_count)%c.item_count
		var keys:=PackedStringArray(["key","--delay","18"])
		for n in distance: keys.append("Down")
		_check(OS.execute("xdotool",keys)==0,"Native menu navigation is available")
		await _frames(3)
	_check(OS.execute("xdotool",PackedStringArray(["key","Return"]))==0,"Native menu confirmation")
	await _frames(3)
	if c.selected!=index:
		# Disclose a semantic fallback. It uses the same public PopupMenu signal
		# to the OptionButton; it does not change the authoritative battle.
		popup.index_pressed.emit(index)
		menu_activations+=1
	popup.hide()
	await _frames(2)
	_check(c.selected==index,"Menu chose requested item "+str(index))

func _snap(label: String) -> void:
	await RenderingServer.frame_post_draw
	var pic:=root.get_texture().get_image()
	_check(pic.save_jpg("res://artifacts/journey-"+label+".jpg",0.90)==OK,"Save viewport "+label)
	pic.resize(640,400,Image.INTERPOLATE_BILINEAR)
	print("JOURNEY_IMAGE journey-"+label+" "+Marshalls.raw_to_base64(pic.save_jpg_to_buffer(0.80)))
	screens.append(label)
	print("JOURNEY_STAGE "+label+" tick="+str(field.battle.tick))

func _run() -> void:
	if DisplayServer.get_name()=="headless": quit(1); return
	var shell=load("res://scenes/game.tscn").instantiate()
	root.add_child(shell)
	field=shell.field
	await _frames(5)
	var b:=field.battle
	var h:=field.hud
	_check(b.side_size==512 and not b.started and h.order_panel.visible,"Normal entrance with a 1024 ordinary roster")
	await _snap("01-muster")
	await _choose(h.weapon,Arms.Kit.BOW)
	await _choose(h.plan,1)
	await _click(h.details)
	await _choose(h.shape,1)
	await _choose(h.front,2)
	await _click(h.apply_position)
	_check(b.companies[0].shape==1 and b.companies[0].front==2 and b.roster[24].pos.x==b.companies[0].home.x,"Existing bow carriers reached the front")
	await _snap("02-deploy")
	_at(h.inset.position+h.inset._point(Ground.GATE))
	await _frames(4)
	_check(not field.follow and field.camera_center.x>39,"Surveyed the gate via the map")
	await _snap("03-gate")
	await _click(h.go)
	_check(b.started and b.hero.kit==Arms.Kit.BOW and field.follow,"Deploy returns to the equipped hero")
	var old:=b.hero.pos
	_key(KEY_SHIFT,true)
	_key(KEY_D,true)
	await _frames(6)
	_key(KEY_D,false)
	_key(KEY_SHIFT,false)
	_check(b.hero.pos.distance_to(old)>0.45 and b.breath<1,"Sprint reached authoritative combat")
	_tap(KEY_TAB)
	await _frames(3)
	await _choose(h.channel,Battle.Channel.HORN)
	await _click(h.issue)
	_check(not h.order_panel.visible,"Successful order clears the field of view")
	await _frames(3)
	var order_tick:=b.tick
	var aimed:=false
	var skill:=false
	var looked:=false
	var last_pose:=0
	var deadline:=0
	while b.result=="" and b.tick<2100 and deadline<1660:
		deadline+=1
		if b.tick<order_tick+115:
			var best: Battle.Unit=null
			var sep:=INF
			for id in b._near(b.hero.pos,22,1):
				var other:=b.roster[id]
				var d:=b.hero.pos.distance_squared_to(other.pos)
				if d<sep and Ground.clear_shot(b.hero.pos,other.pos,b.gate_hp<=0):
					best=other
					sep=d
			if best:
				var target:=field.camera.unproject_position(Ground.unit_point(best.pos)+Vector3.UP*0.88)
				_point(target)
				if b.hero.state==Battle.State.MARCH and b.tick-last_pose>=4:
					if not skill and b.hero.impacts>0:
						_tap(KEY_Q)
						skill=true
					else: _at(target)
					aimed=true
					last_pose=b.tick
			if b.hero.impacts>0 and "04-contact" not in screens: await _snap("04-contact")
		elif not looked:
			looked=true
			_at(h.inset.position+h.inset._point(Ground.GATE-Vector2(6,1)))
		if b.gate_hp<=0 and "05-breach" not in screens: await _snap("05-breach")
		await process_frame
	if "04-contact" not in screens: await _snap("04-contact")
	_check(aimed and b.hero.impacts>0 and skill,"Short pointer input wounded an opponent and Q was used")
	_check(b.messages_arrived>0,"A real order reached its officer")
	_check(b.result!="" and b.hero.hp>0 and not field.theater.receipt.is_empty(),"Natural, settled battle with surviving commander")
	await _frames(12)
	await _snap("06-report")
	var hours:=-1
	var resume_ok:=false
	if not field.theater.receipt.is_empty() and b.hero.hp>0:
		await _click(h.resume_camp)
		_check(b.at_camp and h.wait_hour.visible,"Continue retains the army")
		if h.march_button.visible and not h.march_button.disabled: await _click(h.march_button)
		await _click(h.wait_hour)
		hours=b.aftermath_hours
		var after:=field.theater.player_view()
		_tap(KEY_F5)
		await _frames(2)
		_tap(KEY_F9)
		await _frames(5)
		resume_ok=field.battle.at_camp and field.battle.aftermath_hours==hours and after==field.theater.player_view()
		_check(hours==1 and resume_ok,"Quickload restored survivors, reports, clock and march")
		await _snap("07-camp")
		await _frames(18)
		await _click(h.report_button)
		await _click(h.retry_button)
		_check(field.battle!=b and not field.battle.started and field.battle.side_size==512,"Restart returns to a fresh muster")
	var facts:=b.report()
	facts.merge({"hero_impacts":b.hero.impacts,"hero_ammo":b.hero.ammo,"camp_hours":hours,"camp_resumed":resume_ok,"screens":screens,"popup_semantic_fallbacks":menu_activations,"errors":errors})
	var out:=FileAccess.open("res://artifacts/journey.json",FileAccess.WRITE)
	out.store_string(JSON.stringify(facts,"  "))
	print("JOURNEY_"+("PASS " if errors.is_empty() else "FAIL ")+JSON.stringify(facts))
	shell.queue_free()
	await process_frame
	quit(0 if errors.is_empty() else 1)
