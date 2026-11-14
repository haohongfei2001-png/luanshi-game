extends SceneTree
const Actor := preload("res://scripts/experimental/intact_character_actor.gd")
const Battle := preload("res://scripts/field/battle.gd")
const Save := preload("res://scripts/field/save.gd")
var assertions := 0
var failures := 0
func check(value: bool) -> void:
	assertions += 1
	if not value:
		failures += 1
		push_error("Intact-character adapter assertion %d failed" % assertions)
func _initialize() -> void:
	_run.call_deferred()
func _signature(actor: Node3D) -> PackedByteArray:
	var data := []
	for mesh: MeshInstance3D in actor.model.find_children("*", "MeshInstance3D", true, false):
		for i in mesh.mesh.get_surface_count():
			data.append(mesh.mesh.surface_get_arrays(i))
		if mesh.skin:
			for i in mesh.skin.get_bind_count():
				data.append([mesh.skin.get_bind_name(i), mesh.skin.get_bind_bone(i), mesh.skin.get_bind_pose(i)])
	return var_to_bytes(data)
func _run() -> void:
	var actor := Actor.new()
	root.add_child(actor)
	actor.configure()
	check(actor.skeleton.get_bone_count() == 65)
	check(actor.hand_sockets.size() == 2)
	var source := _signature(actor)
	var rest := []
	for i in actor.skeleton.get_bone_count():
		rest.append([actor.skeleton.get_bone_name(i), actor.skeleton.get_bone_parent(i), actor.skeleton.get_bone_rest(i)])
	var observed_states := {}
	var unsupported := {}
	var scales := []
	for count: int in Battle.SCALES:
		var battle := Battle.new()
		battle.setup(count, Battle.SEED, Battle.Arms.Kit.SPEAR, true, true, -1, true)
		battle.start()
		var distance := PackedFloat64Array()
		distance.resize(battle.roster.size())
		for t in (600 if count == 20 else 240):
			battle.step()
			for u in battle.roster:
				distance[u.id] += u.before.distance_to(u.pos)
			var before := var_to_bytes(Save.snapshot(battle))
			# At most one actual unit of each state per tick; never force units
			# into a desired outcome, freeze damage, or remove offscreen troops.
			var tick_states := {}
			for u in battle.roster:
				var key: int = u.state + (16 if u.mounted else 0)
				if tick_states.has(key): continue
				tick_states[key] = true
				var receipt := actor.observe(battle, u, 0.5, distance[u.id])
				observed_states[u.state] = true
				if not receipt.unsupported.is_empty(): unsupported[receipt.unsupported] = true
				check(receipt.id == u.id and receipt.tick == battle.tick)
				check(receipt.bones == 65 and not receipt.shipping_enabled)
				check(actor.position.is_finite() and actor.basis.is_finite())
				var p: Vector2 = u.before.lerp(u.pos, 0.5)
				check(Vector2(actor.position.x, actor.position.z).distance_to(p) < 0.00001)
				if u.facing_before == Vector2.ZERO or u.facing_before == u.facing:
					check(Vector2(actor.basis.z.x, actor.basis.z.z).distance_to(u.facing) < 0.00001)
			check(before == var_to_bytes(Save.snapshot(battle)))
		# This proves read-only presentation on an active real battle. It is not
		# the four-scale player/performance gate: passive 20v20 bridge deployment
		# produces one-sided hits even at 600 ticks. Preserve that result instead
		# of staging an enemy, inventing contact, or claiming two-sided coverage.
		check(battle.hits[0] + battle.hits[1] > 0)
		scales.append({"per_side": count, "ticks": battle.tick, "hits": battle.hits.duplicate(), "losses": battle.losses.duplicate(), "roster": battle.roster.size(), "two_sided_contact_observed": battle.hits[0] > 0 and battle.hits[1] > 0})
	check(_signature(actor) == source)
	for i in actor.skeleton.get_bone_count():
		check(rest[i] == [actor.skeleton.get_bone_name(i), actor.skeleton.get_bone_parent(i), actor.skeleton.get_bone_rest(i)])
	check(observed_states.has(Battle.State.DEAD))
	check(unsupported.has("authored_weapon_contact_curve_missing"))
	check(unsupported.has("native_riding_and_vehicle_clip_missing"))
	var report := {"assertions": assertions, "failures": failures, "actual_battle_scales": scales,
		"observed_states": observed_states.keys(), "unsupported": unsupported.keys(),
		"native_bones": 65, "native_geometry_weights_skin_rest_unchanged": true,
		"battle_snapshot_before_after_equal": true, "source_rest_min_y": actor.source_min_y,
		"visual": "NOT_RUN", "foot_contact": "NOT_ACCEPTED", "weapons": "NOT_ATTACHED", "shipping_enabled": false}
	DirAccess.make_dir_recursive_absolute("res://artifacts/intact-character-adapter")
	var file := FileAccess.open("res://artifacts/intact-character-adapter/state.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "  ")); file.close()
	print("INTACT_CHARACTER_STATE_", "PASS " if failures == 0 else "FAIL ", JSON.stringify(report))
	actor.queue_free()
	await process_frame
	quit(0 if failures == 0 else 1)
