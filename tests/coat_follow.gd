extends "res://tests/field_motion_review.gd"
## Photograph a real hit at the normal play zoom. A target is never repositioned,
## frozen, wounded by the recorder, or substituted for a real soldier.
var folder:="res://artifacts/personal-contact"
var photos: Array[Dictionary]=[]
var lens:=22.0
var film_count:=0

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--coat-lens="): lens=float(arg.get_slice("=",1))
	folder="res://artifacts/coat-%d"%int(lens)
	if lens==22.0:
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder+"/film"))
		RenderingServer.frame_post_draw.connect(_movie)
	_run.call_deferred()

func _movie() -> void:
	if not is_instance_valid(field) or not is_instance_valid(field.camera): return
	var b:=field.battle
	if b==null or not b.started or b.tick<2: return
	var frame:=root.get_texture().get_image()
	frame.resize(960,600,Image.INTERPOLATE_LANCZOS)
	frame.save_jpg(folder+"/film/%03d.jpg"%film_count,.91)
	film_count+=1

func _photo(label: String,marked_tick: int,foe_id: int,previous_hp: float) -> void:
	await RenderingServer.frame_post_draw
	var b:=field.battle
	var pic:=root.get_texture().get_image()
	_check(pic.save_png(folder+"/"+label+".png")==OK,"Could not write a native window")
	var foe:=b.roster[foe_id]
	var row:={"label":label,"marked_tick":marked_tick,"drawn_tick":b.tick,"seed":Battle.SEED,"ordinary":Array(b.ordinary_counts),"screen":[pic.get_width(),pic.get_height()],"internal_scale":root.scaling_3d_scale,"lens":field.camera.size,"yaw":field.camera_yaw,"hero_id":b.hero.id,"hero_position":[b.hero.pos.x,b.hero.pos.y],"foe_id":foe_id,"foe_position":[foe.pos.x,foe.pos.y],"distance":b.hero.pos.distance_to(foe.pos),"previous_foe_hp":previous_hp,"foe_hp":foe.hp,"hero_hits":b.hero.impacts,"hero_state":b.hero.state,"hero_slot":b.hero.move_slot,"received":b.hero.received,"follow":field.follow}
	var boot:=field.camera.unproject_position(Ground.unit_point(b.hero.pos))
	var crown:=field.camera.unproject_position(Ground.unit_point(b.hero.pos)+Vector3.UP*1.68)
	row["on_screen"]=[boot.x,boot.y,crown.x,crown.y]
	photos.append(row)
	print("RC7_PLAY_INPUT "+JSON.stringify(row))

func _run() -> void:
	if DisplayServer.get_name()=="headless": quit(1); return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	var shell=load("res://scenes/game.tscn").instantiate()
	root.add_child(shell)
	field=shell.field
	await _frames(4)
	await _click(field.hud.go)
	var b:=field.battle
	_check(b.started and b.ordinary_counts==PackedInt32Array([512,512]),"Expected the shipping muster")
	field.camera.size=lens
	# Use the ordinary follow camera; only keyboard, pointer and skill input move
	# the player. There is no artificial duel or empty space around the subject.
	var first_pos:=b.hero.pos
	var prior_hits:=b.hero.impacts
	var last_press:=-30
	var target_id:=-1
	var hp_before:=0.0
	var wound:=false
	var windup:=false
	var press_count:=0
	for frame in 510:
		if b.result!="" or b.hero.hp<=0: break
		var closest:=INF
		var target:Battle.Unit=null
		for u in b.roster:
			if u.team!=1 or not b.active(u): continue
			var sq:=b.hero.pos.distance_squared_to(u.pos)
			if sq<closest: closest=sq;target=u
		if target==null: break
		var dir:=b.hero.pos.direction_to(target.pos)
		_walk(dir if closest>2.95 else Vector2.ZERO,closest>20.0)
		var screen:=field.camera.unproject_position(Ground.unit_point(target.pos)+Vector3.UP*.88)
		screen=screen.clamp(Vector2(14,67),root.get_visible_rect().size-Vector2(16,103))
		_point(screen)
		if closest<7.6 and b.hero.state==Battle.State.MARCH and b.tick-last_press>=4:
			target_id=target.id
			hp_before=target.hp
			if press_count%3==1: _tap(KEY_Q)
			else: _at(screen)
			press_count+=1
			last_press=b.tick
		if not windup and target_id>=0 and b.hero.state==Battle.State.WINDUP:
			windup=true
			await _photo("personal-windup",b.tick,target_id,hp_before)
		if not wound and b.hero.impacts>prior_hits and target_id>=0:
			wound=true
			await _photo("personal-contact",b.tick,target_id,hp_before)
			break
		await process_frame
	_walk(Vector2.ZERO,false)
	_check(windup and wound and b.hero.pos.distance_to(first_pos)>1.0,"A travelling player landed a real hit in company")
	var out:=FileAccess.open(folder+"/input.json",FileAccess.WRITE)
	out.store_string(JSON.stringify(photos,"  "))
	print("RC7_PERSONAL_"+("PASS" if errors.is_empty() else "FAIL")+" "+str(b.hero.impacts))
	shell.queue_free()
	await process_frame
	quit(0 if errors.is_empty() else 1)
