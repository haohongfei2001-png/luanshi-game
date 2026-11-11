extends RefCounted
## Runs through the exported main scene and shared command/weapon entry points.
const Save := preload("res://scripts/field/save.gd")
const Arms := preload("res://scripts/field/arms.gd")
const Battle := preload("res://scripts/field/battle.gd")
const Field := preload("res://scripts/field/controller.gd")

static func run(tree: SceneTree,scene: Field) -> void:
	await tree.process_frame
	scene.hud.weapon.select(Arms.Kit.BOW)
	scene.hud.weapon.item_selected.emit(Arms.Kit.BOW)
	scene.hud.go.pressed.emit()
	var b:=scene.battle
	b.command(0,Battle.Mission.PRESS,Battle.Channel.HORN)
	var limit := Time.get_ticks_msec()+45000
	while b.tick<100 and b.result=="" and Time.get_ticks_msec()<limit:
		await tree.physics_frame
		if b.tick==35: scene.pan_to(Vector2(0,-20))
		if b.tick==70: scene.pan_to(Vector2(0,20))
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
			await RenderingServer.frame_post_draw
			var img:=tree.root.get_texture().get_image()
			var colors:={}
			for x in range(16,img.get_width(),16):
				for y in range(12,img.get_height(),16):
					colors[img.get_pixel(x,y).to_rgba32()]=true
			ok=ok and colors.size()>50 and img.save_png(image_path)==OK
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
	var panned:=false
	while b.result=="" and Time.get_ticks_usec()-start<12000000 and (frames.size()<120 or Time.get_ticks_usec()-start<3500000):
		await RenderingServer.frame_post_draw
		var now:=Time.get_ticks_usec()
		frames.append((now-previous)/1000.0)
		previous=now
		if not panned and now-start>=1250000:
			panned=true
			scene.pan_to(Vector2(2,-18))
		var cpu:=RenderingServer.viewport_get_measured_render_time_cpu(rid)
		var gpu:=RenderingServer.viewport_get_measured_render_time_gpu(rid)
		if cpu>0: rcpu.append(cpu)
		if gpu>0: rgpu.append(gpu)
	var sorted:=frames.duplicate()
	sorted.sort(); rcpu.sort(); rgpu.sort()
	if sorted.is_empty(): return false
	var duration: float=(previous-start)/1000000.0
	var record:={"platform":OS.get_name(),"processor":OS.get_processor_name(),"adapter":RenderingServer.get_video_adapter_name(),
		"display":DisplayServer.get_name(),"renderer":RenderingServer.get_current_rendering_method(),"viewport":[tree.root.size.x,tree.root.size.y],
		"scale":tree.root.scaling_3d_scale,"shadows":true,"per_side":b.side_size,"frames":frames.size(),"seconds":duration,"fps":frames.size()/duration,
		"p95_ms":sorted[ceili(sorted.size()*0.95)-1],"p99_ms":sorted[ceili(sorted.size()*0.99)-1],
		"render_cpu_p95_ms":rcpu[ceili(rcpu.size()*0.95)-1] if not rcpu.is_empty() else null,
		"render_gpu_p95_ms":rgpu[ceili(rgpu.size()*0.95)-1] if not rgpu.is_empty() else null,
		"hits_in_window":b.hits[0]+b.hits[1]-before_hits,"static_bytes":OS.get_static_memory_usage(),"panned":panned}
	print("FIELD_HOST_WINDOW "+JSON.stringify(record))
	record.raw_wall_ms=frames
	var file:=FileAccess.open(path.get_basename()+"-frames.json",FileAccess.WRITE)
	if not file: return false
	file.store_string(JSON.stringify(record))
	return frames.size()>=10 and record.hits_in_window>0 and panned
