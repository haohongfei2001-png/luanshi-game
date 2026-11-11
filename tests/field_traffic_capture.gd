extends SceneTree
## Two camera-matched excerpts from the actual game. Each output image represents
## four normal 20 Hz simulation updates through the production controller.
const Field := preload("res://scripts/field/controller.gd")
const Battle := preload("res://scripts/field/battle.gd")
const Ground := preload("res://scripts/field/ground.gd")
const START_TICK := 260
const FRAME_COUNT := 120
const TICKS_PER_FRAME := 4
var ok := true
var profiling := false

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	if DisplayServer.get_name() == "headless":
		quit(1)
		return
	profiling = "--traffic-frame-probe" in OS.get_cmdline_user_args()
	for enabled: bool in [false, true]:
		var mode := "with-lanes" if enabled else "original"
		var directory := "res://artifacts/formation-traffic/" + mode
		if not profiling: DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))
		var shell = load("res://scenes/game.tscn").instantiate()
		root.add_child(shell)
		var field: Field = shell.field
		field.set_physics_process(false)
		field.set_process(false)
		field.battle.traffic_enabled = enabled
		field.hud.plan_requested.emit(1)
		field.hud.go.pressed.emit()
		var b := field.battle
		ok = ok and b.side_size == 512 and b.started
		if profiling:
			await _frame_probe(field, mode)
			shell.queue_free()
			await process_frame
			continue
		for frame in FRAME_COUNT:
			var target_tick := START_TICK + frame * TICKS_PER_FRAME
			while b.tick < target_tick and b.result.is_empty():
				field._physics_process(Battle.DT)
				if field.paused or not b.started:
					push_error("Replay paused before requested frame")
					quit(1)
					return
			if b.tick != target_tick:
				push_error("Battle ended before paired frame")
				quit(1)
				return
			var center_x := -9.0 + float(target_tick) * 0.073
			field.pan_to(Vector2(minf(center_x, Ground.WALL_X + 2.0), 0.0))
			field.camera.size = 26.0
			field._process(Battle.DT * TICKS_PER_FRAME)
			await RenderingServer.frame_post_draw
			var shot := root.get_texture().get_image()
			ok = ok and shot != null and shot.save_jpg("%s/frame-%03d.jpg" % [directory, frame], 0.92) == OK
		print("FIELD_TRAFFIC_CAMERA " + JSON.stringify({"mode": mode, "seed": Battle.SEED,
			"first_tick": START_TICK, "last_tick": b.tick, "frames": FRAME_COUNT, "ticks_per_frame": TICKS_PER_FRAME,
			"source_resolution": [root.size.x, root.size.y], "hits": b.hits, "losses": b.losses, "ram_x": b.ram.x}))
		shell.queue_free()
		await process_frame
	print(("FIELD_TRAFFIC_PROFILE_" if profiling else "FIELD_TRAFFIC_CAMERA_") + ("PASS" if ok else "FAIL"))
	quit(0 if ok else 1)

func _frame_probe(field: Field, mode: String) -> void:
	# Same world ticks and camera path per A/B. Measure real wall time between
	# rendered frames with vsync disabled and without readback or video encoding.
	# The scheduled 20 Hz/60 Hz workload stays identical on a slower renderer.
	var b := field.battle
	while b.tick < 460 and b.result.is_empty() and not field.paused:
		field._physics_process(Battle.DT)
	if b.tick != 460:
		ok = false
		return
	for distance: float in [26.0, 52.0]:
		field.camera.size = distance
		field.pan_to(Vector2(minf(-9.0 + b.tick * 0.073, Ground.WALL_X + 2.0), 0.0))
		for warmup in 8:
			field._process(Battle.DT / 3.0)
			await RenderingServer.frame_post_draw
		var first_tick := b.tick
		var initial_hits: int = b.hits[0] + b.hits[1]
		var ms := PackedFloat64Array()
		var total := 0.0
		for frame in 90:
			var start := Time.get_ticks_usec()
			if frame % 3 == 0: field._physics_process(Battle.DT)
			field.pan_to(Vector2(minf(-9.0 + b.tick * 0.073, Ground.WALL_X + 2.0), 0.0))
			field._process(Battle.DT / 3.0)
			await RenderingServer.frame_post_draw
			var sample := (Time.get_ticks_usec() - start) / 1000.0
			ms.append(sample)
			total += sample
		ms.sort()
		var data := {"mode": mode, "camera_size": distance, "seed": Battle.SEED, "first_tick": first_tick,
			"last_tick": b.tick, "samples": ms.size(), "real_hits": b.hits[0] + b.hits[1] - initial_hits,
			"window": [root.size.x, root.size.y], "internal_scale": root.scaling_3d_scale,
			"renderer": RenderingServer.get_video_adapter_name(), "godot_tracked_bytes": OS.get_static_memory_usage(),
			"mean_ms": total / ms.size(), "p50_ms": ms[44], "p95_ms": ms[85], "p99_ms": ms[89]}
		print("FIELD_TRAFFIC_FRAME " + JSON.stringify(data))
		ok = ok and b.tick - first_tick == 30 and ms.size() == 90 and data.real_hits > 0
