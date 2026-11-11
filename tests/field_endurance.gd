extends SceneTree
## Replay player-accessible reserve commitments in one real river-gate encounter.
## No reinforcements, stat edits, camera-dependent enemies, or time scaling.
const Field := preload("res://scripts/field/controller.gd")
const Battle := preload("res://scripts/field/battle.gd")
const GOAL_TICKS := 4000
const DIR := "res://artifacts/endurance/"
const PLANS := [
	{"name":"center_column", "interval":13, "vanguard":1, "flanks":false, "order":[2,7,12,1,3,6,8,11,13,0,4,5,9,10,14,15]},
	{"name":"alternating_wings", "interval":14, "vanguard":2, "flanks":true, "order":[0,4,7,2,5,9,10,14,1,3,11,13,6,8,12,15]},
	{"name":"relieve_in_turn", "interval":17, "vanguard":1, "flanks":false, "order":[7,12,11,6,8,13,10,14,15,5,9,2,1,3,0,4]}
]

func _initialize() -> void:
	_run.call_deferred()

func _deployment(b: Battle, plan: Dictionary) -> bool:
	for i in b.companies_per_side:
		if not b.command(i, Battle.Mission.RESERVE, Battle.Channel.FLAG):
			return false
	for i in int(plan.vanguard):
		var mission := Battle.Mission.FLANK if plan.flanks else Battle.Mission.PRESS
		if not b.command(plan.order[i], mission, Battle.Channel.FLAG):
			return false
	return true

func _progress(plan: Dictionary) -> Dictionary:
	return {"next":int(plan.vanguard),"at":int(plan.interval)*20,"issued":0,"unavailable":0}

func _orders(b: Battle, plan: Dictionary, cursor: Dictionary) -> void:
	if cursor.next >= plan.order.size() or b.tick < cursor.at or b.result != "":
		return
	var index := int(cursor.next)
	var mission := Battle.Mission.FLANK if plan.flanks and index%3 == 1 else Battle.Mission.PRESS
	var id := int(plan.order[index])
	if b.command(id, mission, Battle.Channel.HORN) or b.command(id, mission, Battle.Channel.COURIER):
		cursor.issued += 1
	else:
		cursor.unavailable += 1
	cursor.next += 1
	cursor.at += int(plan.interval)*20

func _logbook() -> Dictionary:
	return {"last_hits":0,"hit_ticks":[],"bins":[]}

func _observe(b: Battle, book: Dictionary) -> void:
	var total := int(b.hits[0])+int(b.hits[1])
	if total == book.last_hits: return
	var bin_index := maxi(0,b.tick-1)/100
	while book.bins.size()<=bin_index: book.bins.append(0)
	book.bins[bin_index] += total-int(book.last_hits)
	book.hit_ticks.append(b.tick)
	book.last_hits = total

func _coverage(book: Dictionary, end: int) -> Dictionary:
	var ticks: Array=book.hit_ticks
	var bins: Array=book.bins.duplicate()
	while bins.size()<ceili(end/100.0): bins.append(0)
	var occupied:=0
	for n: int in bins:
		if n>0: occupied+=1
	var previous:=0
	var gap_max:=0
	var streak_two:=0
	var streak_five:=0
	var two_start:=-1
	var five_start:=-1
	for t: int in ticks:
		var gap:=t-previous
		gap_max=maxi(gap_max,gap)
		if two_start<0 or gap>40: two_start=t
		if five_start<0 or gap>100: five_start=t
		streak_two=maxi(streak_two,t-two_start)
		streak_five=maxi(streak_five,t-five_start)
		previous=t
	return {"ticks":end,"sim_seconds":end*Battle.DT,"hit_total":book.last_hits,"hits_per_5_sim_seconds":bins,
		"five_second_bins_with_hits":occupied,"five_second_bins":bins.size(),
		"first_hit_tick":ticks[0] if not ticks.is_empty() else null,"last_hit_tick":previous if not ticks.is_empty() else null,
		"longest_silence_sim_seconds":maxi(gap_max,end-previous)*Battle.DT,
		"longest_contact_2s_sim_seconds":streak_two*Battle.DT,"longest_contact_5s_sim_seconds":streak_five*Battle.DT}

func _trial(plan: Dictionary) -> Dictionary:
	var b:=Battle.new()
	b.setup(512)
	if not _deployment(b,plan):
		push_error("Refused pre-battle assignment")
		return {}
	b.start()
	var cursor:=_progress(plan)
	var book:=_logbook()
	while b.tick<GOAL_TICKS and b.result=="":
		_orders(b,plan,cursor)
		b.input_state(Vector2.LEFT if b.tick<50 else Vector2.ZERO,Vector2.RIGHT)
		b.step()
		_observe(b,book)
	var row:=_coverage(book,b.tick)
	row.merge({"plan":plan.name,"result":b.result,"dead":b.losses,"escaped":b.escaped,
		"hero_hp":b.hero.hp,"ram_hp":b.ram_hp,"order_cursor":cursor,"simulation_only":true})
	return row

func _write_json(path: String, value: Variant) -> void:
	var out:=FileAccess.open(DIR+path,FileAccess.WRITE)
	out.store_string(JSON.stringify(value,"  ")+"\n")

func _stats(values: Array[float]) -> Dictionary:
	if values.is_empty(): return {"frames":0}
	var sorted:=values.duplicate()
	sorted.sort()
	var ms:=0.0
	for v: float in values: ms+=v
	return {"frames":values.size(),"wall_seconds":ms/1000.0,"fps":values.size()*1000.0/ms,
		"p50_ms":sorted[ceili(sorted.size()*0.50)-1],"p95_ms":sorted[ceili(sorted.size()*0.95)-1],"p99_ms":sorted[ceili(sorted.size()*0.99)-1]}

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(DIR))
	if DisplayServer.get_name()=="headless":
		var trials:=[]
		var best: Dictionary={}
		for plan: Dictionary in PLANS:
			var result:=_trial(plan)
			if result.is_empty():
				quit(1)
				return
			trials.append(result)
			print("ENDURANCE_PLAN "+JSON.stringify(result))
			if best.is_empty() or result.five_second_bins_with_hits>best.five_second_bins_with_hits or (result.five_second_bins_with_hits==best.five_second_bins_with_hits and result.longest_contact_5s_sim_seconds>best.longest_contact_5s_sim_seconds):
				best=result
		_write_json("plans.json",trials)
		_write_json("selection.json",best)
		quit(0)
		return
	var selected=JSON.parse_string(FileAccess.get_file_as_string(DIR+"selection.json"))
	if not selected is Dictionary:
		push_error("No recorded deployment selection")
		quit(1)
		return
	for plan: Dictionary in PLANS:
		if selected.plan==plan.name:
			await _window(plan)
			return
	push_error("Recorded deployment unavailable")
	quit(1)

func _window(plan: Dictionary) -> void:
	var shell=load("res://scenes/game.tscn").instantiate()
	root.add_child(shell)
	await process_frame
	var field: Field=shell.field
	var b:=field.battle
	if b.side_size!=512 or not _deployment(b,plan):
		push_error("Endurance test could not deploy the original 512v512 roster")
		quit(1)
		return
	field.set_quality(0)
	field.camera.size=49
	field.pan_to(Vector2.ZERO)
	var cursor:=_progress(plan)
	var book:=_logbook()
	var poses: Array[Vector2]=[Vector2(0,0),Vector2(5,-24),Vector2(15,24),Vector2(42,0),Vector2(15,-14),Vector2(4,20)]
	var rid:=root.get_viewport_rid()
	RenderingServer.viewport_set_measure_render_time(rid,true)
	var frames: Array[float]=[]
	var contact: Array[float]=[]
	var csv:=FileAccess.open(DIR+"frames.csv",FileAccess.WRITE)
	csv.store_line("tick,frame_ms,hit_total,ordinary_visible,combat_poses,camera_x,camera_z,camera_size,simulation_usec_total,view_usec_total,render_cpu_ms,render_gpu_ms")
	Input.action_press("move_left")
	field.deploy()
	var pilot:=func():
		if b.tick>=50 and Input.is_action_pressed("move_left"): Input.action_release("move_left")
		_orders(b,plan,cursor)
	physics_frame.connect(pilot)
	var start:=Time.get_ticks_usec()
	var previous:=start
	var previous_hit:=-1
	var previous_tick:=0
	var early_exit:=""
	var segment:=-1
	while b.tick<GOAL_TICKS and b.result=="":
		await RenderingServer.frame_post_draw
		var now:=Time.get_ticks_usec()
		var elapsed: float=(now-previous)/1000.0
		previous=now
		frames.append(elapsed)
		var seen:int=book.last_hits
		_observe(b,book)
		if book.last_hits>seen: previous_hit=b.tick
		if previous_hit>=0 and b.tick-previous_hit<=40 and b.result=="": contact.append(elapsed)
		csv.store_csv_line(PackedStringArray([str(b.tick),str(elapsed),str(book.last_hits),str(field.view.visible_soldiers),
			str(field.view.visible_fighting),str(field.camera_center.x),str(field.camera_center.y),str(field.camera.size),str(field.sim_us),
			str(field.view_us),str(RenderingServer.viewport_get_measured_render_time_cpu(rid)),str(RenderingServer.viewport_get_measured_render_time_gpu(rid))]))
		var next_segment:=mini(b.tick/400,9)
		if next_segment!=segment:
			segment=next_segment
			var focus:=poses[segment%poses.size()]
			field.camera.size=[49.0,15.0,29.0,55.0,19.0,38.0][segment%6]
			field.pan_to(focus)
			if segment in [0,3,6,9]:
				root.get_texture().get_image().save_jpg(DIR+"field-%03d.jpg"%roundi(b.tick*Battle.DT),0.85)
		if b.tick<previous_tick or field.battle!=b or field.paused or not b.started:
			early_exit="Unexpected replacement, pause, or clock reversal"
			break
		if now-start>430000000:
			early_exit="Wall-clock cap reached"
			break
		previous_tick=b.tick
	physics_frame.disconnect(pilot)
	Input.action_release("move_left")
	csv.flush()
	csv.close()
	var result:=_coverage(book,b.tick)
	result.merge({"plan":plan.name,"single_encounter":true,"initial_ordinary":1024,"officers":b.companies.size(),"ending_ordinary_alive":[512-b.losses[0],512-b.losses[1]],
		"result":b.result,"hero_hp":b.hero.hp,"hit_sides":b.hits,"orders":cursor,"order_acknowledged":b.messages_arrived,
		"lost":b.messages_lost,"refused":b.messages_refused,"camera_cuts":segment+1,"raw_frames":"frames.csv",
		"wall_all":_stats(frames),"wall_recent_contact_2s":_stats(contact),"host":OS.get_processor_name(),"adapter":RenderingServer.get_video_adapter_name(),
		"renderer":RenderingServer.get_current_rendering_method(),"window_px":[root.size.x,root.size.y],"internal_scale":root.scaling_3d_scale,"shadows":field.map.sun.shadow_enabled,
		"open_or_settled_world_valid":field.theater.audit().is_empty() and field.theater.audit_quivers(),"error":early_exit})
	_write_json("window.json",result)
	print("ENDURANCE_WINDOW "+JSON.stringify(result))
	var good: bool=early_exit=="" and bool(result.open_or_settled_world_valid) and frames.size()>100 and book.last_hits>0 and segment>0
	shell.queue_free()
	await process_frame
	quit(0 if good else 1)
