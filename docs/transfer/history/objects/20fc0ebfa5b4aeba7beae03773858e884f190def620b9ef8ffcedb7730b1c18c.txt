extends RefCounted
## Shared test controls. Never writes HP, positions, RNG, roster or outcome.
var tree: SceneTree
var scene: Node
var actions: Dictionary = {}

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
	var event := InputEventMouseMotion.new()
	event.position = tree.root.get_screen_transform() * scene.camera.unproject_position(Vector3(at.x, 0, at.y))
	event.global_position = event.position
	Input.parse_input_event(event)

func movement(direction: Vector2) -> void:
	for action in ["move_left", "move_right", "move_up", "move_down"]:
		Input.action_release(action)
	if direction.x < 0: Input.action_press("move_left", -direction.x)
	if direction.x > 0: Input.action_press("move_right", direction.x)
	if direction.y < 0: Input.action_press("move_up", -direction.y)
	if direction.y > 0: Input.action_press("move_down", direction.y)

func release_inputs() -> void:
	movement(Vector2.ZERO)
	Input.action_release("attack")

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
			Input.action_press("attack")
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
		frames += 1
		if frames == 120 and not capture_name.is_empty():
			captured = await capture(capture_name)
	release_inputs()
	await tree.physics_frame
	await tree.physics_frame
	return {"report": sim.report(), "frames": frames, "captured": captured, "actions": actions.duplicate()}

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
