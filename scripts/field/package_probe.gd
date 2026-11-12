extends RefCounted
## Runs through the exported main scene and shared command/weapon entry points.
const Save := preload("res://scripts/field/save.gd")
const Arms := preload("res://scripts/field/arms.gd")
const Battle := preload("res://scripts/field/battle.gd")
const Field := preload("res://scripts/field/controller.gd")

# The native verifier sends the same deployment signal a player can press after the
# preparation screen appears. It must not deploy while Cocoa is still activating
# a newly opened window: focus loss correctly pauses a running battle.
static func _boot(tree: SceneTree, scene: Field, stage: String) -> void:
	var b := scene.battle
	print("FIELD_BOOT " + JSON.stringify({
		"stage":stage, "engine_ms":Time.get_ticks_msec(), "pid":OS.get_process_id(),
		"physics_frames":Engine.get_physics_frames(), "drawn_frames":Engine.get_frames_drawn(),
		"focus":tree.root.has_focus(), "paused":scene.paused, "started":b.started,
		"tick":b.tick, "hits":b.hits[0]+b.hits[1], "result":b.result,
		"renderer":RenderingServer.get_current_rendering_method(), "data_dir":OS.get_user_data_dir()
	}))

static func _foreground_ready(tree: SceneTree, scene: Field) -> bool:
	_boot(tree,scene,"scene_ready")
	tree.root.focus_entered.connect(_boot.bind(tree,scene,"window_focus_in"))
	tree.root.focus_exited.connect(_boot.bind(tree,scene,"window_focus_out"))
	await RenderingServer.frame_post_draw
	_boot(tree,scene,"first_post_draw")
	var limit := Time.get_ticks_msec()+8000
	var since := -1
	while Time.get_ticks_msec()<limit:
		var now := Time.get_ticks_msec()
		if tree.root.has_focus():
			if since<0: since=now
			if now-since>=300:
				_boot(tree,scene,"foreground_ready")
				return true
		else:
			since=-1
		await tree.process_frame
	_boot(tree,scene,"foreground_timeout")
	return false

static func _check_focus_pause(tree: SceneTree, scene: Field) -> bool:
	# The external macOS test app takes key/active status and gives it back.
	# Only this explicit control exercise presses the verified HUD Resume button.
	_boot(tree,scene,"control_armed")
	var limit := Time.get_ticks_msec()+10000
	while Time.get_ticks_msec()<limit and not scene.paused:
		await tree.process_frame
	if not scene.paused:
		_boot(tree,scene,"pause_timeout")
		return false
	var stopped_at := scene.battle.tick
	_boot(tree,scene,"focus_paused")
	while Time.get_ticks_msec()<limit and not tree.root.has_focus():
		await tree.process_frame
	var allowed_resume := Time.get_ticks_msec()+300
	while Time.get_ticks_msec()<allowed_resume:
		await tree.process_frame
	if not tree.root.has_focus() or not scene.paused or scene.battle.tick!=stopped_at:
		_boot(tree,scene,"pause_not_preserved")
		return false
	_boot(tree,scene,"still_paused_after_foreground")
	scene.hud.change.pressed.emit()
	_boot(tree,scene,"resume_pressed")
	return not scene.paused

static func run(tree: SceneTree,scene: Field) -> void:
	await tree.process_frame
	var native_window := OS.get_name()=="macOS" and DisplayServer.get_name()!="headless"
	if native_window and not await _foreground_ready(tree,scene):
		tree.quit(1)
		return
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--field-quality="):
			var opt:=arg.trim_prefix("--field-quality=")
			if opt in ["0","1","2"]: scene.set_quality(opt.to_int())
	scene.hud.weapon.select(Arms.Kit.BOW)
	scene.hud.weapon.item_selected.emit(Arms.Kit.BOW)
	scene.hud.go.pressed.emit()
	var b:=scene.battle
	if native_window:
		_boot(tree,scene,"deployed")
		if not b.started or scene.paused:
			tree.quit(1)
			return
	b.command(0,Battle.Mission.PRESS,Battle.Channel.HORN)
	var limit := Time.get_ticks_msec()+45000
	var saw_tick := false
	var saw_hit := false
	while b.tick<100 and b.result=="" and Time.get_ticks_msec()<limit:
		await tree.physics_frame
		if native_window:
			if not saw_tick and b.tick>0:
				saw_tick=true
				_boot(tree,scene,"first_tick")
				if "--field-focus-control" in OS.get_cmdline_user_args():
					if not await _check_focus_pause(tree,scene):
						tree.quit(1)
						return
			if not saw_hit and b.hits[0]+b.hits[1]>0:
				saw_hit=true
				_boot(tree,scene,"first_hit")
		if b.tick==35: scene.pan_to(Vector2(0,-20))
		if b.tick==70: scene.pan_to(Vector2(0,20))
	if native_window: _boot(tree,scene,"contact_complete" if b.tick>=100 else "contact_timeout")
	var saved := Save.snapshot(b)
	var loaded := Save.restore(bytes_to_var(var_to_bytes(saved)))
	var ok: bool = b.side_size==512 and b.roster.size()==1057 and b.hits[0]>0 and b.hits[1]>0 and b.arrow_count>0 and b.tick>=100 and b.messages_arrived>0
	ok=ok and scene.view.visible_soldiers>0 and loaded!=null and Save.snapshot(loaded)==saved
	var image_path:=""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--field-proof="): image_path=arg.trim_prefix("--field-proof=")
	if image_path!="":
		ok=ok and DisplayServer.get_name()!="headless"
		if DisplayServer.get_name()!="headless":
			var timing: bool=await _window_sample(tree,scene,image_path)
			ok=ok and timing
	var row:=b.report()
	row.merge({"display":DisplayServer.get_name(),"device":RenderingServer.get_video_adapter_name(),"visible":scene.view.visible_soldiers,"resume_equal":loaded!=null and Save.snapshot(loaded)==saved})
	print("FIELD_PACKAGE_"+("PASS" if ok else "FAIL")+" "+JSON.stringify(row))
	tree.quit(0 if ok else 1)

static func _window_sample(tree: SceneTree,scene: Field,path: String) -> bool:
	var rid:=tree.root.get_viewport_rid()
	RenderingServer.viewport_set_measure_render_time(rid,true)
	var rcpu: Array[float]=[]
	var rgpu: Array[float]=[]
	var frames: Array[float]=[]
	var b:=scene.battle
	var before_hits: int=b.hits[0]+b.hits[1]
	await RenderingServer.frame_post_draw
	var start:=Time.get_ticks_usec()
	var previous:=start
	var first_sim_us:=scene.sim_us
	var first_view_us:=scene.view_us
	var panned:=false
	var tour: bool="--field-window-tour" in OS.get_cmdline_user_args()
	var minimum_us:=24000000 if tour else 3500000
	var bins: Array=[]
	var bin_start:=start
	var bin_hits:=before_hits
	var bin_frame:=0
	var stops:=0
	var keyboard_samples:=0
	while b.result=="" and Time.get_ticks_usec()-start<minimum_us+8500000 and (frames.size()<120 or Time.get_ticks_usec()-start<minimum_us):
		await RenderingServer.frame_post_draw
		var now:=Time.get_ticks_usec()
		frames.append((now-previous)/1000.0)
		previous=now
		if scene.frame_log and keyboard_samples<3 and now-start>250000+keyboard_samples*950000 and b.hero.state==Battle.State.MARCH:
			var key: Key=[KEY_J,KEY_Q,KEY_E][keyboard_samples]
			for down: bool in [true,false]:
				var event:=InputEventKey.new()
				event.keycode=key
				event.physical_keycode=key
				event.pressed=down
				Input.parse_input_event(event)
				Input.flush_buffered_events()
			keyboard_samples+=1
		if not panned and now-start>=1250000:
			panned=true
			scene.pan_to(Vector2(2,-18))
		if tour and now-bin_start>=4000000:
			var current_hits: int=b.hits[0]+b.hits[1]
			bins.append({"wall_seconds":(now-bin_start)/1000000.0,"frames":frames.size()-bin_frame,"hits":current_hits-bin_hits,"tick":b.tick,"visible":scene.view.visible_soldiers})
			bin_hits=current_hits
			bin_start=now
			bin_frame=frames.size()
			var stops_at: Array[Vector2]=[Vector2(1,18),Vector2(11,2),Vector2(23,-8),Vector2(42,0),Vector2(48,6)]
			scene.pan_to(stops_at[stops%stops_at.size()])
			stops+=1
		var cpu:=RenderingServer.viewport_get_measured_render_time_cpu(rid)
		var gpu:=RenderingServer.viewport_get_measured_render_time_gpu(rid)
		if cpu>0: rcpu.append(cpu)
		if gpu>0: rgpu.append(gpu)
	var sorted:=frames.duplicate()
	sorted.sort(); rcpu.sort(); rgpu.sort()
	if sorted.is_empty(): return false
	var duration: float=(previous-start)/1000000.0
	var bytes:=OS.get_static_memory_usage()
	var sim_ms:float=(scene.sim_us-first_sim_us)/1000.0
	var view_ms:float=(scene.view_us-first_view_us)/1000.0
	# For a root window ViewportTexture.get_size() also applies the canvas
	# stretch transform. Read the real color attachment after wall timings end.
	var texture:=tree.root.get_texture()
	var logical:=texture.get_size()
	var img:=texture.get_image()
	if img==null or img.is_empty(): return false
	var target:=img.get_size()
	var image_saved:=img.save_png(path)==OK
	var colors:={}
	for x in range(16,target.x,16):
		for y in range(12,target.y,16):
			colors[img.get_pixel(x,y).to_rgba32()]=true
	var native_window:=DisplayServer.window_get_size()
	var screen_index:=DisplayServer.window_get_current_screen()
	var screen:=DisplayServer.screen_get_size(screen_index)
	var canvas_scale:=tree.root.get_final_transform().get_scale()
	var scale:=tree.root.scaling_3d_scale
	var record:={"platform":OS.get_name(),"processor":OS.get_processor_name(),"adapter":RenderingServer.get_video_adapter_name(),
		"display":DisplayServer.get_name(),"renderer":RenderingServer.get_current_rendering_method(),"viewport":[tree.root.size.x,tree.root.size.y],
		"display_window_px":[native_window.x,native_window.y],"screen_px":[screen.x,screen.y],
		"content_design_px":[tree.root.content_scale_size.x,tree.root.content_scale_size.y],"canvas_scale":[canvas_scale.x,canvas_scale.y],
		"reported_viewport_texture_px":[logical.x,logical.y],"sim_cpu_total_ms":sim_ms,"view_script_total_ms":view_ms,
		"sim_cpu_ms_per_frame":sim_ms/frames.size(),"view_script_ms_per_frame":view_ms/frames.size(),
		"render_cpu_samples":rcpu.size(),"render_gpu_samples":rgpu.size(),
		"gpu_timer_status":"measured" if not rgpu.is_empty() else "no_nonzero_device_timestamps",
		"scale":scale,"preset":scene.detail_preset,"render_target_px":[target.x,target.y],"estimated_internal_px":[roundi(target.x*scale),roundi(target.y*scale)],"shadows":scene.map.sun.shadow_enabled,"per_side":b.side_size,"frames":frames.size(),"seconds":duration,"fps":frames.size()/duration,
		"tour":tour,"four_second_windows":bins,"mean_ms":duration*1000.0/frames.size(),"input_to_postdraw_ms":Array(scene.frame_log.input_ms) if scene.frame_log else [],"p50_ms":sorted[ceili(sorted.size()*0.5)-1],"p95_ms":sorted[ceili(sorted.size()*0.95)-1],"p99_ms":sorted[ceili(sorted.size()*0.99)-1],
		"render_cpu_p95_ms":rcpu[ceili(rcpu.size()*0.95)-1] if not rcpu.is_empty() else null,
		"render_gpu_p95_ms":rgpu[ceili(rgpu.size()*0.95)-1] if not rgpu.is_empty() else null,
		"hits_in_window":b.hits[0]+b.hits[1]-before_hits,"static_bytes":bytes if bytes>0 else null,"panned":panned}
	print("FIELD_HOST_WINDOW "+JSON.stringify(record))
	record.raw_wall_ms=frames
	var file:=FileAccess.open(path.get_basename()+"-frames.json",FileAccess.WRITE)
	if not file: return false
	file.store_string(JSON.stringify(record))
	return image_saved and colors.size()>50 and frames.size()>=10 and record.hits_in_window>0 and panned and (not tour or (duration>=16.0 and bins.size()>=4))
