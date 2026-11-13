extends SceneTree
## Measure construction and present the same 1,024 actors in the saved battlefield.
const Battle:=preload("res://scripts/field/battle.gd")
const Field:=preload("res://scripts/field/controller.gd")

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	if DisplayServer.get_name()=="headless": quit(1); return
	var out:=OS.get_environment("CAPTURE_DIR")
	var boot:=Time.get_ticks_usec()
	var scene: Node=load("res://scenes/game.tscn").instantiate()
	root.add_child(scene)
	var field: Field=scene.field
	field.set_physics_process(false)
	field.set_process(false)
	var ready:=Time.get_ticks_usec()
	await RenderingServer.frame_post_draw
	print("GROVE_BOOT "+JSON.stringify({"scene_ms":(ready-boot)/1000.0,"first_frame_ms":(Time.get_ticks_usec()-boot)/1000.0,"static_bytes":OS.get_static_memory_usage(),"static_max":OS.get_static_memory_peak_usage()}))
	if "--setup-only" not in OS.get_cmdline_user_args():
		field.hud.plan_requested.emit(1)
		field.hud.go.pressed.emit()
		var b:=field.battle
		if not b.started or b.ordinary_counts!=PackedInt32Array([512,512]): quit(1);return
		for item in [[48,Vector2(3,-4),22.0,"combat"],[65,Vector2(-4,-11),10.0,"trees"],[68,Vector2(-31,-6),42.0,"river"],[490,Vector2(41,1),31.0,"gate"]]:
			while b.tick<int(item[0]) and b.result=="": field._physics_process(Battle.DT)
			if b.tick!=int(item[0]): quit(1);return
			field.camera.size=float(item[2])
			field.camera_yaw=-.576
			field.pan_to(item[1])
			field._process(Battle.DT)
			var timing: Array[float]=[]
			for i in 22:
				var start:=Time.get_ticks_usec()
				await RenderingServer.frame_post_draw
				if i>=4: timing.append((Time.get_ticks_usec()-start)/1000.0)
			timing.sort()
			var frame:=root.get_texture().get_image()
			if frame.save_png(out+"/"+str(item[3])+".png")!=OK: quit(1);return
			print("GROVE_VIEW "+JSON.stringify({"view":item[3],"tick":b.tick,"ordinary":Array(b.ordinary_counts),"hits":Array(b.hits),"losses":Array(b.losses),"visible":field.view.visible_soldiers,"calls":RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME),"triangles":RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME),"p50_ms":timing[8],"p95_ms":timing[17],"render_samples":timing,"resolution":[frame.get_width(),frame.get_height()],"scale":root.scaling_3d_scale}))
	scene.queue_free()
	await process_frame
	quit(0)
