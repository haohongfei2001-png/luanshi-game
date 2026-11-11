extends SceneTree
const World := preload("res://scripts/world_sim.gd")
const Store := preload("res://scripts/campaign_store.gd")
const Codec := preload("res://scripts/campaign_value_codec.gd")
const Profiles := preload("res://scripts/hero_combat_profiles.gd")
var checks := 0
var failures: Array[String] = []

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)
		push_error(label)

func legacy_fields(state: Dictionary) -> Dictionary:
	var original := state.duplicate(true)
	original.world.version = 5
	original.world.erase("mode")
	original.world.erase("origin")
	original.world.erase("youth")
	original.world.erase("couriers")
	original.world.commander.erase("hero_profile")
	for ticket in original.world.battle_tickets.values():
		ticket.erase("signal_model")
		ticket.erase("hero_profile")
		ticket.erase("purpose")
		ticket.erase("command_authority")
	for session in original.battle_sessions.values():
		session.erase("hero_profile")
		for f in ["signal_model", "signal_sequence", "pending_signals", "last_signal"]: session.erase(f)
		for unit in session.units:
			unit.erase("received_order"); unit.erase("received_order_sequence")
	return original

func expected(name: String, suffix: String = "state") -> Dictionary:
	return Codec.new().decode(JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/v06/%s.%s.codec.json" % [name, suffix]))).value

func reject(target: WorldSimulation, state: Dictionary, label: String) -> void:
	var before := target.export_campaign_state()
	check(not target.restore_campaign_state(state).ok, label + " rejected")
	check(target.export_campaign_state() == before, label + " atomic")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	check(World.new().snapshot().commander.hero_profile == Profiles.profile_reference(Profiles.EARLY), "new campaigns default early")
	var battle := BattleSimulation.new()
	battle.reset()
	check(battle.hero_profile.id == Profiles.EARLY and battle.player().hp == 100.0, "standalone defaults early")
	for id in Profiles.gameplay_ids() + [Profiles.LEGACY]:
		_test_current(id)
		_test_conditions(id)
	_test_legacy()
	print("PROFILE_SAVE_TESTS " + JSON.stringify({"checks": checks, "failures": failures}))
	quit(0 if failures.is_empty() else 1)

func _test_current(profile_id: String) -> void:
	var world := World.new(184, profile_id)
	var profile := Profiles.get_profile(profile_id)
	world.march("river")
	world.advance(3)
	var id: String = world.create_battle_ticket().ticket.battle_id
	var sim := world.start_battle(id)
	check(sim.hero_profile.id == profile_id and sim.player().max_hp == profile.max_hp, "canonical profile " + profile_id)
	for action in ["attack", "sweep", "lunge", "guard"]: sim.use_action(action)
	sim.set_player_input(Vector2(0.2, -0.1), Vector2(0.8, 0.4))
	sim.step(0.03125)
	var state := world.export_campaign_state()
	var store := Store.new()
	var encoded := store.encode_campaign(world)
	check(encoded.ok, "profile encodes " + profile_id)
	var decoded := store.decode_campaign(encoded.bytes)
	var loaded := World.new()
	check(decoded.ok and loaded.restore_campaign_state(decoded.state).ok, "profile restores " + profile_id)
	check(state == loaded.export_campaign_state(), "full current identity and timers exact " + profile_id)
	var resumed := loaded.start_battle(id)
	check(resumed.player().guard == sim.player().guard and resumed.cooldowns == sim.cooldowns and resumed.rng.state == sim.rng.state, "active guard cooldown RNG exact " + profile_id)
	for frame in range(1800):
		for item in [sim, resumed]:
			item.set_player_input(Vector2.RIGHT if item.player().pos.x < 12.0 else Vector2.ZERO, Vector2.RIGHT)
			item.step(BattleSimulation.FIXED_DELTA)
		world.sync_battle_time(id)
		loaded.sync_battle_time(id)
		check(world.export_campaign_state() == loaded.export_campaign_state(), "whole fight continuation %s/%d" % [profile_id, frame])
		if sim.ended: break
	check(sim.ended, "real terminal outcome " + profile_id)
	check(world.commit_battle_outcome(sim.outcome()).ok and loaded.commit_battle_outcome(resumed.outcome()).ok, "actual outcome settles " + profile_id)
	check(world.export_campaign_state() == loaded.export_campaign_state(), "settled worlds exact " + profile_id)
	check(store.decode_campaign(store.encode_campaign(world).bytes).ok, "settled profile roundtrip " + profile_id)
	var reference: Dictionary = state.world.commander.hero_profile.duplicate()
	for bad in [null, {}, "early_v1", {"id": 3, "revision": 1}, {"id": "missing", "revision": 1}, {"id": profile_id, "revision": 999}, {"id": profile_id, "revision": float(reference.revision)}, {"id": profile_id, "revision": reference.revision, "stats": {}}]:
		for where in ["commander", "ticket", "session"]:
			var corrupt := state.duplicate(true)
			if where == "commander": corrupt.world.commander.hero_profile = bad
			elif where == "ticket": corrupt.world.battle_tickets[id].hero_profile = bad
			else: corrupt.battle_sessions[id].hero_profile = bad
			reject(loaded, corrupt, "invalid %s profile %s" % [where, str(bad)])
	for where in ["commander", "ticket", "session"]:
		var corrupt := state.duplicate(true)
		if where == "commander": corrupt.world.commander.erase("hero_profile")
		elif where == "ticket": corrupt.world.battle_tickets[id].erase("hero_profile")
		else: corrupt.battle_sessions[id].erase("hero_profile")
		reject(loaded, corrupt, "missing current " + where)
	var wrong := state.duplicate(true)
	wrong.battle_sessions[id].hero_profile = Profiles.profile_reference(Profiles.LATE if profile_id != Profiles.LATE else Profiles.EARLY)
	reject(loaded, wrong, "session differs from ticket")
	wrong = state.duplicate(true)
	wrong.world.battle_tickets[id].hero_profile = Profiles.profile_reference(Profiles.LATE if profile_id != Profiles.LATE else Profiles.EARLY)
	reject(loaded, wrong, "ticket differs from life")
	for field in ["hp", "max_hp"]:
		wrong = state.duplicate(true)
		wrong.world.commander[field] = profile.max_hp + 0.01
		reject(loaded, wrong, "oversized commander " + field)
	wrong = state.duplicate(true)
	wrong.world.battle_tickets[id].reserved_roster_snapshot[0][0].hp = profile.max_hp + 0.01
	reject(loaded, wrong, "oversized reserved HP")
	for action in ["attack", "sweep", "lunge", "guard"]:
		wrong = state.duplicate(true)
		wrong.battle_sessions[id].cooldowns[action] = profile[action + "_cooldown"] + 0.01
		reject(loaded, wrong, "oversized cooldown " + action)
	wrong = state.duplicate(true)
	wrong.battle_sessions[id].units[0].guard = profile.guard_duration + 0.01
	reject(loaded, wrong, "oversized guard")
	var before := loaded.export_campaign_state()
	check(not loaded.reset(123, "unknown") and loaded.export_campaign_state() == before, "unknown reset is atomic")

func _test_legacy() -> void:
	var store := Store.new()
	for name in ["running", "pending", "committed", "cancelled", "dead", "life_node"]:
		var path := "res://tests/fixtures/v06/%s.save.json" % name
		var bytes := FileAccess.get_file_as_bytes(path)
		var decoded := store.decode_campaign(bytes)
		check(decoded.ok, "genuine v06 decodes " + name)
		if not decoded.ok: continue
		var world := World.new()
		check(world.restore_campaign_state(decoded.state).ok, "migrated state restores " + name)
		check(legacy_fields(world.export_campaign_state()) == expected(name), "every original field preserved " + name)
		check(world.snapshot().commander.hero_profile == Profiles.profile_reference(Profiles.LEGACY), "legacy identity explicit " + name)
		var id := "1:1"
		match name:
			"running":
				var sim := world.start_battle(id)
				check(sim.player().max_hp == 360.0 and sim.player().guard > 2.5, "legacy HP and longer active guard preserved")
				var trace: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/v06/running.trace.json"))
				for frame in range(int(trace.frame_count)):
					if frame % 19 == 0: sim.use_action("guard")
					if frame % 23 == 0: sim.use_action("attack")
					sim.set_player_input(Vector2(0.25,-0.125), Vector2(1.0,0.35))
					sim.step(BattleSimulation.FIXED_DELTA)
					world.sync_battle_time(id)
					var original := legacy_fields(world.export_campaign_state())
					check(JSON.stringify(Codec.new().encode(original).value).sha256_text() == trace.state_sha256[frame], "legacy old-core exact frame %d" % frame)
					if frame == 119: check(original == expected(name, "continuation"), "legacy first120 exact")
				check(sim.ended and world.commit_battle_outcome(sim.outcome()).ok, "legacy whole-fight settles")
				check(legacy_fields(world.export_campaign_state()) == expected(name, "whole_fight"), "legacy old-core whole-fight settlement exact")
			"pending":
				check(world.commit_battle_outcome(world.start_battle(id).outcome()).ok, "legacy pending commits")
			"committed":
				var receipt := world.commit_battle_outcome(world.battle_ticket(id).outcome)
				check(receipt.ok and receipt.already_committed, "legacy receipt not replayed")
			"cancelled", "life_node":
				check(world.advance_seconds(7 * 3600.0 + 0.3456789012), "legacy world continues")
			"dead":
				check(world.player_view().campaign_ended and world.snapshot().commander.hp == 0.0, "legacy death remains dead")
				check(world.restore_campaign_state(expected("life_node")).ok, "explicit legacy life rollback")
		if name != "running": check(legacy_fields(world.export_campaign_state()) == expected(name, "continuation"), "old-core continuation exact " + name)
		check(FileAccess.get_file_as_bytes(path) == bytes, "loading does not rewrite source " + name)
		var corrupted := expected(name)
		corrupted.world.commander["hero_profile"] = Profiles.profile_reference(Profiles.LEGACY)
		reject(world, corrupted, "v5 cannot carry v6 field " + name)

func _test_conditions(profile_id: String) -> void:
	for unarmed in [false, true]:
		var world := World.new(184, profile_id)
		# Real deprivation/travel produces the condition; no condition/stat injection.
		world.transfer("relief", "pingling", "food", 120)
		if unarmed: world.transfer("relief", "pingling", "weapons", 30)
		world.march("river")
		world.advance(3)
		var ticket: Dictionary = world.create_battle_ticket().ticket
		var battle := world.start_battle(ticket.battle_id)
		var profile := Profiles.get_profile(profile_id)
		var modifier: Dictionary = ticket.reserved_roster_snapshot[0][0].condition_modifiers
		var speed_scale := float(modifier.speed_percent) / 100.0
		var damage_scale := float(modifier.damage_percent) / 100.0
		check(speed_scale < 1.0 and damage_scale < 1.0, "real deprivation produces condition penalty")
		check(is_equal_approx(battle.player().speed, profile.speed * speed_scale), "profile speed scaled once")
		check(is_equal_approx(battle.player().damage, (7.0 if unarmed else profile.damage) * damage_scale), "profile/unarmed damage scaled once")
		check(battle.player().hp == profile.max_hp and battle.player().max_hp == profile.max_hp, "deprivation does not inflate/clamp hero HP")
		var before: Vector2 = battle.player().pos
		check(battle.use_action("lunge") != unarmed, "only weapon allows lunge")
		if not unarmed:
			check(is_equal_approx(battle.player().pos.x - before.x, profile.lunge_distance * speed_scale), "lunge distance scaled once")
		var loaded := World.new()
		check(loaded.restore_campaign_state(world.export_campaign_state()).ok, "deprived profile restores")
		check(loaded.start_battle(ticket.battle_id).export_campaign_state() == battle.export_campaign_state(), "restoration does not reapply condition")
