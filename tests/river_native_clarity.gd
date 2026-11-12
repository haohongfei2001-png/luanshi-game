extends SceneTree
## Real game framebuffer capture. No preview models, imposed positions or substitute shaders.
const Field := preload("res://scripts/field/controller.gd")
const Battle := preload("res://scripts/field/battle.gd")
const Ground := preload("res://scripts/field/ground.gd")
const Save := preload("res://scripts/field/save.gd")
const FRAMES := 5
var field: Field
var output := ""
var width := 0
var samples := 0
var reference := false
var frames: Array = []
var timings: Dictionary = {}
var errors: Array[String] = []

func _initialize() -> void:
	_run.call_deferred()

func _verify(ok: bool, message: String) -> void:
	if not ok:
		errors.append(message)
		push_error(message)

func _advance_to(end: int) -> void:
	var b := field.battle
	while b.tick < end and b.result == "":
		b.input_state(Vector2.ZERO,Vector2.RIGHT)
		b.step()
	_verify(b.tick == end,"Simulation stopped early")

func _line() -> Vector2:
	var b := field.battle
	for kit in [3,4,-1]:
		for u in b.roster:
			if u.team == 0 and not u.officer and (kit == -1 or kit == u.kit) and u.state in [Battle.State.WINDUP,Battle.State.RECOVER] and u.target >= 0:
				return u.pos.lerp(b.roster[u.target].pos,.5)
	_verify(false,"No engaged line")
	return b.hero.pos

func _compose(point: Vector2, zoom: float, yaw: float, t: int) -> void:
	field.camera_yaw = yaw
	field.camera.size = zoom
	field.pan_to(point+Vector2(.055,.021)*t)
	field.carry = (t%3)*Battle.DT/3.0
	field._process(1.0/60.0)

func _snapshot(label: String, i: int) -> void:
	var b := field.battle
	await RenderingServer.frame_post_draw
	var picture := root.get_texture().get_image()
	var target := "%s/%s-%d" % [output,label,i]
	_verify(picture.get_size() == Vector2i(width,width*5/8),"Actual framebuffer size disagrees with requested size: "+str(picture.get_size()))
	_verify(picture.save_png(target+".png") == OK,"Could not save raw color attachment")
	var ids := PackedInt32Array()
	var kits := PackedInt32Array()
	kits.resize(9)
	var mounted := 0
	var officers := 0
	var viewport_rect := root.get_visible_rect()
	for u in b.roster:
		if not b.active(u): continue
		var p := Ground.unit_point(u.before.lerp(u.pos,clampf(field.carry/Battle.DT,0,1)))
		var center := field.camera.unproject_position(p+Vector3.UP*(1.8 if u.mounted else .95))
		if not viewport_rect.has_point(center): continue
		ids.append(u.id)
		kits[u.kit] += 1
		if u.mounted: mounted += 1
		if u.officer: officers += 1
	frames.append({"scene":label,"frame":i,"tick":b.tick,"center":[field.camera_center.x,field.camera_center.y],
		"yaw":field.camera_yaw,"zoom":field.camera.size,"seed":Battle.SEED,"ordinary":Array(b.ordinary_counts),
		"visible_ids":Marshalls.raw_to_base64(ids.to_byte_array()).sha256_text(),"visible_alive":ids.size(),
		"visible_kits":Array(kits),"visible_mounted":mounted,"visible_officers":officers,"hits":Array(b.hits),
		"losses":Array(b.losses),"shots_in_flight":b.shots.size(),"vehicle":b.vehicle,
		"camera_high_models":field.view.high_detail_soldiers,"camera_rank_models":field.view.rank_soldiers,
		"submitted":field.view.visible_soldiers,"size":[picture.get_width(),picture.get_height()],"scale_3d":root.scaling_3d_scale,
		"msaa":root.msaa_3d,"shadow":field.map.sun.shadow_enabled})
	# Identical draw count across variants. The additional hidden-actor diagnostic
	# yields a reference coverage mask; these extra draws never enter wall timing.
	field.view.hide()
	await RenderingServer.frame_post_draw
	if reference:
		_verify(root.get_texture().get_image().save_png(target+"-background.png")==OK,"Could not save silhouette diagnostic")
	field.view.show()

func _scene(label: String, start: int, zoom: float, yaw: float) -> void:
	_advance_to(start)
	var point := field.battle.hero.pos if label == "mounted" else _line()
	for i in FRAMES:
		if i > 0 and i%3 == 0: _advance_to(field.battle.tick+1)
		_compose(point,zoom,yaw,i)
		await _snapshot(label,i)
	# 12 warm frames; clock real completions, independent of the fixed sim clock.
	var elapsed := PackedInt64Array()
	for i in 42:
		var before := Time.get_ticks_usec()
		if i%3 == 0: _advance_to(field.battle.tick+1)
		_compose(point,zoom,yaw,FRAMES+i)
		if reference: continue
		await RenderingServer.frame_post_draw
		if i >= 12: elapsed.append(Time.get_ticks_usec()-before)
	timings[label] = Array(elapsed)

func _run() -> void:
	if DisplayServer.get_name()=="headless": quit(1); return
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--raw="): output=arg.trim_prefix("--raw=")
		elif arg.begins_with("--width="): width=arg.trim_prefix("--width=").to_int()
		elif arg.begins_with("--samples="): samples=arg.trim_prefix("--samples=").to_int()
		elif arg=="--reference": reference=true
	DirAccess.make_dir_recursive_absolute(output)
	var scene=load("res://scenes/game.tscn").instantiate()
	root.add_child(scene)
	field=scene.field
	field.set_process(false)
	field.set_physics_process(false)
	var device := RenderingServer.get_video_adapter_name()
	var method := RenderingServer.get_current_rendering_method()
	var actual_window := DisplayServer.window_get_size()
	var original := {"msaa":root.msaa_3d,"screen_aa":root.screen_space_aa,"taa":root.use_taa,
		"scale":root.scaling_3d_scale,"preset":field.detail_preset,"shadow":field.map.sun.shadow_enabled,
		"window":[actual_window.x,actual_window.y],"logical":[root.get_visible_rect().size.x,root.get_visible_rect().size.y],
		"hidpi":ProjectSettings.get_setting("display/window/dpi/allow_hidpi",true),"resizable":not root.unresizable}
	_verify(original.preset==0 and is_equal_approx(original.scale,1.0) and original.screen_aa==0 and not original.taa and original.shadow,"Native quality at ordinary launch")
	_verify(method=="mobile" and actual_window.x==width,"Unexpected rendering backend or window")
	root.msaa_3d=Viewport.MSAA_DISABLED if samples==0 else (Viewport.MSAA_2X if samples==2 else Viewport.MSAA_4X)
	field.hud.plan_requested.emit(1)
	field.hud.go.pressed.emit()
	var b:=field.battle
	_verify(b.started and b.ordinary_counts==PackedInt32Array([512,512]),"Expected 1024 deployed ordinary troops")
	_verify(b.mount(1),"Actual player horse unavailable")
	for i in 5: await RenderingServer.frame_post_draw
	await _scene("mounted",8,14.0,1.09)
	await _scene("contact",65,18.0,-.576)
	_verify(b.hits[0]+b.hits[1]>0,"No simulated combat")
	var report:={"engine":Engine.get_version_info().string,"driver":device,"renderer":method,"default":original,
		"width":width,"samples":samples,"reference":reference,"frames":frames,"timing_us":timings,"errors":errors}
	var f:=FileAccess.open(output+"/run.json",FileAccess.WRITE)
	f.store_string(JSON.stringify(report,"  "))
	f.close()
	print("CLAR_SCENE_END ", JSON.stringify({"driver":device,"method":method,"default":original,"width":width,"samples":samples,"frames":frames.size(),"errors":errors}))
	scene.queue_free()
	await process_frame
	quit(0 if errors.is_empty() else 1)
