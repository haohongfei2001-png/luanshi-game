extends RefCounted
## Shared test controls. Never writes HP, positions, RNG, roster or outcome.
var tree: SceneTree
var scene: Node
var actions: Dictionary = {}
var held_keys: Dictionary = {}
var pointer_error_max := 0.0
var moving_frames := 0

func _init(host: SceneTree, battle_scene: Node) -> void:
	tree = host
	scene = battle_scene

func key(code: Key) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.keycode = code
	event.pressed = true
	tree.root.push_input(event, true)
	event.pressed = false
	tree.root.push_input(event, true)

func click(control: Control) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.position = control.get_global_rect().get_center()
	event.pressed = true
	tree.root.push_input(event, true)
	event.pressed = false
	tree.root.push_input(event, true)
	await settle_ui()

func youth_click(id: String) -> void:
	if scene.youth.scroll.is_ancestor_of(scene.youth.buttons[id]):
		scene.youth.scroll.ensure_control_visible(scene.youth.buttons[id])
	await tree.process_frame
	await click(scene.youth.buttons[id])

func settle_ui() -> void:
	for i in range(5):
		await tree.process_frame
	while scene.save_busy or scene.youth_busy:
		await tree.process_frame
	for i in range(3):
		await tree.process_frame

func aim(at: Vector2) -> void:
	var viewport_position: Vector2 = scene.camera.unproject_position(Vector3(at.x, 0, at.y))
	# Real window backends poll the OS cursor. A synthetic motion alone does not
	# move it and can be overwritten by the next X11 poll (the headless backend
	# has no OS cursor). Warp through the viewport, then deliver the same motion.
	if DisplayServer.get_name() != "headless":
		tree.root.warp_mouse(viewport_position)
	var event := InputEventMouseMotion.new()
	event.position = tree.root.get_screen_transform() * viewport_position
	event.global_position = event.position
	Input.parse_input_event(event)
	Input.flush_buffered_events()
	pointer_error_max = maxf(pointer_error_max, tree.root.get_mouse_position().distance_to(viewport_position))

func hold_key(code: Key, pressed: bool) -> void:
	if bool(held_keys.get(code, false)) == pressed:
		return
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)
	held_keys[code] = pressed

func movement(direction: Vector2) -> void:
	# Send real held-key events, not action-strength overrides. Input backends can
	# rebuild action state when they process queued mouse/keyboard events.
	hold_key(KEY_A, direction.x < -0.1)
	hold_key(KEY_D, direction.x > 0.1)
	hold_key(KEY_W, direction.y < -0.1)
	hold_key(KEY_S, direction.y > 0.1)
	Input.flush_buffered_events()

func release_inputs() -> void:
	movement(Vector2.ZERO)
	hold_key(KEY_J, false)
	Input.flush_buffered_events()

func fight(capture_name: String = "") -> Dictionary:
	var sim: BattleSimulation = scene.sim
	var frames := 0
	var captured := false
	while not sim.ended and frames < 7200:
		var nearest := -1
		var distance := INF
		for i in range(sim.units.size()):
			var unit: Dictionary = sim.units[i]
			if unit.team != 1 or unit.hp <= 0:
				continue
			var next_distance: float = sim.player().pos.distance_to(unit.pos)
			if next_distance < distance:
				distance = next_distance
				nearest = i
		if nearest >= 0:
			var offset: Vector2 = sim.units[nearest].pos - sim.player().pos
			aim(sim.units[nearest].pos)
			var move := offset.normalized() if distance > sim.player().range * 0.95 else Vector2.ZERO
			if distance < sim.player().range * 0.92:
				move = -offset.normalized()
			movement(move)
			hold_key(KEY_J, true)
			Input.flush_buffered_events()
			actions.attack = true
			if frames % 6 == 0:
				if distance <= 1.9:
					key(KEY_SPACE)
					actions.guard = true
				if distance <= sim.hero_profile.sweep_range:
					key(KEY_Q)
					actions.sweep = true
				if distance > 0.65 and distance <= sim.hero_profile.lunge_distance:
					key(KEY_E)
					actions.lunge = true
		await tree.physics_frame
		if scene.sim.player_move.length() > 0.0:
			moving_frames += 1
		frames += 1
		if frames == 120 and not capture_name.is_empty():
			captured = await capture(capture_name)
	release_inputs()
	await tree.physics_frame
	await tree.physics_frame
	return {"report": sim.report(), "frames": frames, "captured": captured, "actions": actions.duplicate(), "pointer_error_max": pointer_error_max, "moving_frames": moving_frames}

func skirmish_and_withdraw(capture_name: String = "") -> Dictionary:
	# A risky tactical choice, not a casualty fixture: send the commissioned squad
	# into contact, then withdraw on the first actual loss. The hero stays at the rear.
	key(KEY_1)
	actions.attack_order = true
	movement(Vector2.ZERO)
	for i in range(1800):
		if scene.sim.ended or scene.sim.report().friendly_casualties > 0:
			break
		await tree.physics_frame
	if not capture_name.is_empty():
		await capture(capture_name)
	return await withdraw()

func withdraw(capture_name: String = "") -> Dictionary:
	key(KEY_3)
	actions.withdraw = true
	movement(Vector2.LEFT)
	for i in range(600):
		if scene.sim.ended:
			break
		await tree.physics_frame
		if i == 15 and not capture_name.is_empty():
			await capture(capture_name)
	release_inputs()
	await tree.physics_frame
	await tree.physics_frame
	return scene.sim.report()

func capture(name: String) -> bool:
	await tree.process_frame
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://artifacts")
	return tree.root.get_texture().get_image().save_png("res://artifacts/" + name + ".png") == OK
