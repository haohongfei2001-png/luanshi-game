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

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	if DisplayServer.get_name() == "headless":
		quit(1)
		return
	for enabled: bool in [false, true]:
		var mode := "with-lanes" if enabled else "original"
		var directory := "res://artifacts/formation-traffic/" + mode
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))
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
	print("FIELD_TRAFFIC_CAMERA_" + ("PASS" if ok else "FAIL"))
	quit(0 if ok else 1)
