extends SceneTree
## Kept on the experiment branch. Two continuous 512v512 views in the normal game.
const Field:=preload("res://scripts/field/controller.gd")
const Battle:=preload("res://scripts/field/battle.gd")
const FieldView:=preload("res://scripts/field/presentation.gd")
const Save:=preload("res://scripts/field/save.gd")
const SHOTS:=[33,93,153]
const WARM:=24
const FRAMES:=162
const STOPS:=[Vector2(1,-18),Vector2(1,18),Vector2(11,2),Vector2(23,-8),Vector2(42,0),Vector2(48,6)]
var field: Field
var out: String
var tag: String
var report: Dictionary={}
var failures: Array[String]=[]

func sha(a: PackedByteArray) -> String:
	var h:=HashingContext.new()
	h.start(HashingContext.HASH_SHA256)
	h.update(a)
	return h.finish().hex_encode()

func make_witness(which: String, frame: int) -> Dictionary:
	var b:=field.battle
	var model:=field.view
	var named:=model.groups.duplicate()
	named[900]=model.contact
	named[901]=model.horse
	named[902]=model.horse_rank
	named[903]=model.cart
	named[904]=model.cart_rank
	named[905]=model.arrows
	named[906]=model.runners
	named[907]=model.standards[0]
	named[908]=model.standards[1]
	var keys:=named.keys()
	keys.sort()
	var batches: Array=[]
	var counts: Array=[]
	for key in keys:
		var g: FieldView.Batch=named[key]
		var n:=g.mesh.visible_instance_count
		if n!=g.used: failures.append("Submitted batch count differs at %s / %s"%[key,frame])
		var uniforms: Array=[]
		for i in n:
			var instance:=g.mesh.get_instance_transform(i)
			uniforms.append(instance)
			if key!=900:
				uniforms.append(g.mesh.get_instance_custom_data(i))
			elif g.mesh.use_custom_data and g.mesh.get_instance_custom_data(i)!=Color(0,0,0,0):
				failures.append("Unexpected animated sole")
		batches.append([key,n,int(g.node.cast_shadow),uniforms])
		counts.append([key,n])
	var shot:=root.get_texture().get_image()
	shot.convert(Image.FORMAT_RGBA8)
	var pixel_file:=FileAccess.open(OS.get_environment("VIEW_PIXELS")+"/%s-%s-%03d.rgba"%[tag,which,frame],FileAccess.WRITE)
	pixel_file.store_buffer(shot.get_data())
	pixel_file.close()
	var p:=out+"/%s-%s-%03d.png"%[tag,which,frame]
	if tag.ends_with("0") and shot.save_png(p)!=OK:failures.append("Could not save framebuffer")
	if shot.get_width()!=1280 or shot.get_height()!=800:failures.append("Unexpected actual render target")
	return {"frame":frame,"tick":b.tick,"pos":str(field.camera_center),"lens":field.camera.size,"hits":b.hits.duplicate(),"losses":b.losses.duplicate(),"shots":b.shots.size(),"commanders":b.companies.size(),"ordinary":[b.ordinary_counts[0],b.ordinary_counts[1]],"render_px":[shot.get_width(),shot.get_height()],"live_batches":counts,"state_sha256":sha(var_to_bytes(Save.snapshot(b))),"instance_sha256":sha(var_to_bytes(batches)),"rgba_sha256":sha(shot.get_data()),"visible_ordinary":model.visible_soldiers,"fighting":model.visible_fighting,"far":model.rank_soldiers,"close":model.high_detail_soldiers,"fallen_visible":model.shown_fallen}

func timing_window(which: String, start_tick: int) -> void:
	var b:=field.battle
	field.carry=0.0
	while b.tick<start_tick and not field.paused and b.result.is_empty():field._physics_process(Battle.DT)
	if b.tick!=start_tick: failures.append("Cannot enter "+which);return
	var rows: Array=[]
	var witnesses: Array=[]
	var ignore_next:=0
	for frame in FRAMES:
		var sim0:=field.sim_us
		var view0:=field.view_us
		var at:=Time.get_ticks_usec()
		field.carry=0.0
		if frame%3==0:field._physics_process(Battle.DT)
		field.carry=Battle.DT*float(frame%3)/3.0
		if which=="close":
			field.camera.size=18.0
			field.pan_to(Vector2(1.0,-15.0))
		else:
			var stop:=int(frame/24)%STOPS.size()
			var previous: Vector2=STOPS[posmod(stop-1,STOPS.size())]
			var point: Vector2=previous.lerp(STOPS[stop],smoothstep(0.0,1.0,float(frame%24)/7.0))
			field.camera.size=30.0
			field.pan_to(point)
		field._process(1.0/60.0)
		await RenderingServer.frame_post_draw
		var wall:=Time.get_ticks_usec()-at
		if frame>=WARM and ignore_next==0:
			rows.append([frame,wall,field.view_us-view0,field.sim_us-sim0,field.view.visible_soldiers])
		if ignore_next>0:ignore_next-=1
		if frame in SHOTS:
			witnesses.append(make_witness(which,frame))
			ignore_next=3
	if b.tick!=start_tick+ceili(FRAMES/3.0):failures.append("Active tick count differs")
	report[which]={"columns":["frame","wall_us","display_script_us","sim_us","visible_ordinary"],"start_tick":start_tick,"rows":rows,"witnesses":witnesses}

func run() -> void:
	tag=OS.get_environment("VIEW_TAG")
	out=OS.get_environment("VIEW_OUT")
	var shell=load("res://scenes/game.tscn").instantiate()
	root.add_child(shell)
	field=shell.field
	field.set_physics_process(false)
	field.set_process(false)
	field.set_quality(0)
	field.hud.plan_requested.emit(1)
	field.hud.go.pressed.emit()
	Input.warp_mouse(Vector2(640,400))
	if DisplayServer.get_name()=="headless" or field.battle.ordinary_counts!=PackedInt32Array([512,512]) or not field.battle.started or not field.map.sun.shadow_enabled or root.scaling_3d_scale!=1.0:
		printerr("Wrong runtime, graphics or muster");quit(1);return
	for _warmup in 6:await RenderingServer.frame_post_draw
	await timing_window("close",115)
	await timing_window("tour",495)
	report["host"]={"tag":tag,"seed":Battle.SEED,"cpu":OS.get_processor_name(),"driver":DisplayServer.get_name(),"adapter":RenderingServer.get_video_adapter_name(),"renderer":RenderingServer.get_current_rendering_method(),"engine":Engine.get_version_info().string,"quality":field.detail_preset,"shadows":field.map.sun.shadow_enabled,"scale":root.scaling_3d_scale,"shader_time":"fixed engine clock, two camera runs in the same order","mem_tracked_bytes":OS.get_static_memory_usage(),"failures":failures}
	var f:=FileAccess.open(out+"/"+tag+".json",FileAccess.WRITE)
	f.store_string(JSON.stringify(report))
	f.close()
	print("VIEW_STREAM ",tag," ",JSON.stringify(report.host))
	quit(0 if failures.is_empty() else 1)

func _initialize() -> void:run.call_deferred()
