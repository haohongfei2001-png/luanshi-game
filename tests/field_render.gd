extends SceneTree
## Real X11 window and uncapped wall-clock samples. Movie readbacks run in a separate process.
const Field := preload("res://scripts/field/controller.gd")
const Battle := preload("res://scripts/field/battle.gd")
const Ground := preload("res://scripts/field/ground.gd")
var failures: Array[String]=[]
var field: Field
var film := false
var totals := []

func _initialize() -> void:
	_run.call_deferred()

func check(ok: bool,why: String) -> void:
	if not ok:
		failures.append(why)
		push_error(why)

func _key(code: Key,pressed: bool) -> void:
	var e := InputEventKey.new()
	e.physical_keycode=code
	e.keycode=code
	e.pressed=pressed
	Input.parse_input_event(e)
	Input.flush_buffered_events()

func _run() -> void:
	film="--field-film" in OS.get_cmdline_user_args()
	if DisplayServer.get_name()=="headless":
		push_error("Rendered field verification needs a display")
		quit(1)
		return
	var shell=load("res://scenes/game.tscn").instantiate()
	root.add_child(shell)
	field=shell.field
	await process_frame
	check(field!=null and field.camera.current,"Normal executable entrance opens the battlefield")
	if not field:
		quit(1)
		return
	if film:
		await _movie()
	else:
		RenderingServer.viewport_set_measure_render_time(root.get_viewport_rid(),true)
		for count: int in Battle.SCALES:
			await _measure(count)
			if not failures.is_empty(): break
		if failures.is_empty(): await _paired_detail()
		if failures.is_empty():
			var held:=field.battle
			shell.open_campaign()
			await process_frame
			check(shell.campaign.sim.units.size()==41,"Preserved training and strategy mode")
			shell.open_field()
			await process_frame
			check(shell.field.battle==held,"Switching modes retained the live field")
	var marker := "FIELD_FILM_" if film else "FIELD_RENDER_"
	print(marker+("PASS" if failures.is_empty() else "FAIL")+" "+JSON.stringify(failures))
	shell.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)

func _begin(count: int) -> void:
	if field.battle.started or field.battle.side_size!=count: field.new_muster(count)
	await process_frame
	await process_frame
	_key(KEY_ENTER,true)
	await process_frame
	_key(KEY_ENTER,false)
	check(field.battle.started,"Real Enter deployed %d v %d" % [count,count])
	field.camera.size=28
	field.pan_to(Vector2(0,0))

func _measure(count: int) -> void:
	await _begin(count)
	if not field.battle.started: return
	var b:=field.battle
	var pos:=b.hero.pos
	var key_at:=Time.get_ticks_usec()
	_key(KEY_D,true)
	var latency: float=-1.0
	var time_limit:=Time.get_ticks_msec()+30000
	while b.hits[0]+b.hits[1]<4 and b.result=="" and Time.get_ticks_msec()<time_limit:
		await process_frame
		if latency<0 and b.hero.pos!=pos:
			latency=(Time.get_ticks_usec()-key_at)/1000.0
		if b.hero.pos.distance_to(pos)>1.25: _key(KEY_D,false)
	_key(KEY_D,false)
	check(latency>=0,"WASD movement reached authoritative soldier ticks")
	check(b.hits[0]+b.hits[1]>=4,"Waited for actual contact before wall sampling")
	if not failures.is_empty(): return
	var clips: Array[float]=[]
	var cpu: Array[float]=[]
	var gpu: Array[float]=[]
	var draws: Array[float]=[]
	var peak_poses:=0
	var begin:=Time.get_ticks_usec()
	var previous:=begin
	var first_tick:=b.tick
	var sim_begin:=field.sim_us
	var view_begin:=field.view_us
	var before_hits: int=b.hits[0]+b.hits[1]
	var rid:=root.get_viewport_rid()
	var shifted:=false
	while b.result=="" and Time.get_ticks_msec()<time_limit and (Time.get_ticks_usec()-begin<2800000 or clips.size()<20):
		await RenderingServer.frame_post_draw
		var now:=Time.get_ticks_usec()
		clips.append((now-previous)/1000.0)
		previous=now
		if not shifted and now-begin>1150000:
			shifted=true
			field.pan_to(Vector2(1,-20 if count>=250 else 2))
		peak_poses=maxi(peak_poses,field.view.visible_fighting)
		var cpu_ms:=RenderingServer.viewport_get_measured_render_time_cpu(rid)
		var gpu_ms:=RenderingServer.viewport_get_measured_render_time_gpu(rid)
		if cpu_ms>0: cpu.append(cpu_ms)
		if gpu_ms>0: gpu.append(gpu_ms)
		draws.append(RenderingServer.viewport_get_render_info(rid,RenderingServer.VIEWPORT_RENDER_INFO_TYPE_VISIBLE,RenderingServer.VIEWPORT_RENDER_INFO_DRAW_CALLS_IN_FRAME))
	check(clips.size()>=10 and peak_poses>0 and b.hits[0]+b.hits[1]>before_hits,"Sampled moving, damaging combat frames")
	var span: float=(previous-begin)/1000.0
	clips.sort(); cpu.sort(); gpu.sort(); draws.sort()
	var record:=b.report()
	record.merge({"display":DisplayServer.get_name(),"renderer":RenderingServer.get_current_rendering_method(),"device":RenderingServer.get_video_adapter_name(),
		"viewport_px":[root.size.x,root.size.y],"render_scale":root.scaling_3d_scale,"shadows":true,"seed":Battle.SEED,"frame_samples":clips.size(),
		"wall_seconds":span/1000.0,"fps":clips.size()*1000.0/maxf(span,0.01),"mean_ms":span/maxi(1,clips.size()),"p95_ms":_pct(clips,0.95),"p99_ms":_pct(clips,0.99),
		"sim_ms_per_tick":float(field.sim_us-sim_begin)/maxi(1,b.tick-first_tick)/1000.0,"view_script_ms_per_frame":float(field.view_us-view_begin)/maxi(1,clips.size())/1000.0,
		"render_cpu_p95_ms":_pct(cpu,0.95),"render_gpu_p95_ms":_pct(gpu,0.95),"draw_calls_p95":_pct(draws,0.95),
		"static_memory_bytes":OS.get_static_memory_usage(),"input_observed_ms":latency,"peak_visible_combat_poses":peak_poses,"last_visible_soldiers":field.view.visible_soldiers,"last_high_detail_soldiers":field.view.high_detail_soldiers,"hits_during_sample":b.hits[0]+b.hits[1]-before_hits})
	totals.append(record)
	print("FIELD_FRAME_SAMPLE "+JSON.stringify(record))
	var pic:=root.get_texture().get_image()
	check(pic.save_png("res://artifacts/field-%d.png"%count)==OK,"Save rendered frame")
	var file:=FileAccess.open("res://artifacts/field-frame-times.json",FileAccess.WRITE)
	var raw: Dictionary={"sample":record,"sorted_frame_ms":clips}
	var raw_file:=FileAccess.open("res://artifacts/field-frame-times-%d.json"%count,FileAccess.WRITE)
	raw_file.store_string(JSON.stringify(raw))
	file.store_string(JSON.stringify(totals,"  "))

func _pct(a: Array[float],p: float) -> Variant:
	if a.is_empty(): return null
	return a[clampi(ceili(a.size()*p)-1,0,a.size()-1)]

func _movie() -> void:
	await _begin(512)
	if not field.battle.started: return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://artifacts/field-film"))
	var i:=0
	for frame in 360:
		if frame==12: _key(KEY_D,true)
		if frame==39: _key(KEY_D,false)
		if frame==30:
			_key(KEY_F,true)
			_key(KEY_F,false)
		if frame==45:
			_key(KEY_1,true)
			_key(KEY_1,false)
		if frame==65:
			_key(KEY_Q,true)
			_key(KEY_Q,false)
		if frame<100:
			field.camera.size=lerpf(38,23,frame/100.0)
			field.pan_to(Vector2(lerpf(-3,2,frame/100.0),lerpf(-8,-20,frame/100.0)))
		elif frame<185:
			field.camera.size=lerpf(23,7.0,(frame-100)/85.0)
			field.pan_to(Vector2(2,lerpf(-20,-18,(frame-100)/85.0)))
		elif frame<240:
			field.camera.size=lerpf(7.0,64,(frame-185)/55.0)
			field.pan_to(Vector2(lerpf(2,13,(frame-185)/55.0),lerpf(-18,0,(frame-185)/55.0)))
		elif frame<300:
			field.camera.size=lerpf(64,35,(frame-240)/60.0)
			field.pan_to(Vector2(lerpf(13,52,(frame-240)/60.0),lerpf(0,-3,(frame-240)/60.0)))
		else:
			field.camera.size=lerpf(35,24,(frame-300)/60.0)
			field.pan_to(Vector2(lerpf(52,53,(frame-300)/60.0),lerpf(-3,-13,(frame-300)/60.0)))
		await RenderingServer.frame_post_draw
		if frame%2==0:
			var pic:=root.get_texture().get_image()
			pic.resize(768,480,Image.INTERPOLATE_BILINEAR)
			check(pic.save_jpg("res://artifacts/field-film/frame-%03d.jpg"%i,0.88)==OK,"Movie frame write")
			if frame==326: check(pic.save_jpg("res://artifacts/field-gate.jpg",0.94)==OK,"Gatehouse and wall garrison still")
			if frame==174: check(pic.save_jpg("res://artifacts/field-close.jpg",0.94)==OK,"Close combat still")
			i+=1
	check(i==180 and field.battle.hits[0]>0 and field.battle.hits[1]>0,"Recorded active battle across camera movement")
	print("FIELD_FILM_FACTS "+JSON.stringify(field.battle.report()))

func _paired_detail() -> void:
	# Compare the same live identities, poses, camera, viewport and simulation tick
	# twice. Only the crowd mesh and its shadow submission change. This isolates
	# renderer cost; the real-time four-scale pass above measures player frame time.
	field.set_physics_process(false)
	field.follow=false
	field.camera.size=28
	field.pan_to(Vector2(1,-18))
	var samples: Array=[[],[]]
	var triangles := [0,0]
	var visible := -1
	for frame in 12:
		field.battle.step()
		for half in 2:
			var ref: int=(frame+half)%2
			field.view.reference_detail=bool(ref)
			await RenderingServer.frame_post_draw
			var before:=Time.get_ticks_usec()
			await RenderingServer.frame_post_draw
			if frame>1:
				samples[ref].append((Time.get_ticks_usec()-before)/1000.0)
			triangles[ref]=RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME)
			if half==0: visible=field.view.visible_soldiers
			else: check(visible==field.view.visible_soldiers,"LOD keeps identical visible identities on paired frames")
	for series in samples: series.sort()
	var pair: Dictionary={"poses":10,"visible_soldiers_last":visible,"per_side":field.battle.side_size,
		"optimized_median_render_ms":samples[0][5],"full_detail_median_render_ms":samples[1][5],
		"optimized_primitives":triangles[0],"full_detail_primitives":triangles[1]}
	print("FIELD_PAIRED_LOD "+JSON.stringify(pair))
	var file:=FileAccess.open("res://artifacts/field-lod-paired.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(pair,"  "))
	field.view.reference_detail=false
	field.set_physics_process(true)
