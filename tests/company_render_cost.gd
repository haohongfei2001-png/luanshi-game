extends SceneTree
## Render-only comparison. Both revisions consume the same four sets of actual live poses,
## each replayed with the same camera. Wall timing includes presentation and frame submit,
## excludes the scheduled simulation step and screenshot/file I/O.
const Field:=preload("res://scripts/field/controller.gd")
const Battle:=preload("res://scripts/field/battle.gd")
var field: Field
func _initialize() -> void: _run.call_deferred()
func _pct(v: Array[float],p: float) -> float:
	v.sort()
	return v[clampi(ceili(p*v.size())-1,0,v.size()-1)] if not v.is_empty() else -1.0
func _run() -> void:
	var scene=load("res://scenes/game.tscn").instantiate()
	root.add_child(scene)
	field=scene.field
	field.set_process(false)
	field.set_physics_process(false)
	field.hud.plan_requested.emit(1)
	field.hud.go.pressed.emit()
	var b:=field.battle
	if DisplayServer.get_name()=="headless" or not b.started or b.side_size!=512: quit(1);return
	RenderingServer.viewport_set_measure_render_time(root.get_viewport_rid(),true)
	var rid:=root.get_viewport_rid()
	for sample in [[80,Vector2(1,-18),26.0,"line"],[130,Vector2(-1,-20),12.0,"melee"],[525,Vector2(43,0),27.0,"gate"],[590,Vector2(37,3),50.0,"pan"]]:
		while b.tick<sample[0] and not field.paused and b.result=="": field._physics_process(Battle.DT)
		if b.tick!=sample[0]: quit(1);return
		var wall: Array[float]=[]
		var cpu: Array[float]=[]
		var gpu: Array[float]=[]
		var tris:=0
		var draws:=0
		for frame in 40:
			if frame%3==0: field._physics_process(Battle.DT)
			var at: Vector2=sample[1]
			if sample[3]=="pan": at.x+=float(frame)*.59
			var begin:=Time.get_ticks_usec()
			field.camera.size=sample[2]
			field.pan_to(at)
			field._process(1.0/60.0)
			await RenderingServer.frame_post_draw
			if frame<8: continue
			wall.append((Time.get_ticks_usec()-begin)/1000.0)
			var c:=RenderingServer.viewport_get_measured_render_time_cpu(rid)
			var g:=RenderingServer.viewport_get_measured_render_time_gpu(rid)
			if c>0: cpu.append(c)
			if g>0: gpu.append(g)
			tris=RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME)
			draws=RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)
		print("COMPANY_RENDER_COST "+JSON.stringify({"case":sample[3],"tick":b.tick,"seed":Battle.SEED,"per_side":b.side_size,"hits":b.hits,"dead":b.losses,
			"camera_size":field.camera.size,"visible":field.view.visible_soldiers,"triangles":tris,"draws":draws,"samples":wall.size(),"p50_ms":_pct(wall,.5),"p95_ms":_pct(wall,.95),"p99_ms":_pct(wall,.99),
			"render_cpu95_ms":_pct(cpu,.95),"render_gpu95_ms":_pct(gpu,.95),"renderer":RenderingServer.get_video_adapter_name(),"memory_bytes":OS.get_static_memory_usage()}))
	scene.queue_free()
	await process_frame
	quit()
