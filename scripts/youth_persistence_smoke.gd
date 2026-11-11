class_name YouthPersistenceSmoke
extends RefCounted
## Export-safe acceptance: actual battles and the same complete life across processes.
## This opt-in diagnostic uses ordinary actions, never injected HP, deaths or results.
const World := preload("res://scripts/world_sim.gd")
const Store := preload("res://scripts/campaign_store.gd")
var _errors: Array[String] = []
var _checks := 0

static func run(phase: String, isolated_id: String) -> Dictionary:
	return YouthPersistenceSmoke.new()._run(phase, isolated_id)

func _run(phase: String, isolated_id: String) -> Dictionary:
	if phase not in ["prepare", "resume"]:
		return {"ok": false, "errors": ["unsupported phase"]}
	var font := preload("res://scripts/youth_ui.gd").chinese_font()
	for character in "乱世战场军令长枪弓弩守城骑乘":
		_expect(font.has_char(character.unicode_at(0)), "Missing packaged font glyph " + character)
	_expect(not font.allow_system_fallback, "Font depends on the host OS")
	_expect(FileAccess.get_file_as_string("res://assets/fonts/OFL.txt").contains("SIL OPEN FONT LICENSE Version 1.1"), "Missing font redistribution notice")
	var store := Store.new("youth_runtime_" + isolated_id)
	var world := World.new(184)
	if phase == "prepare":
		if not _expect(world.start_youth("forced", "homeland").ok, "enlistment failed"): return _report(phase, world)
		if not _expect(store.save_checkpoint(world, "enlistment").ok, "enlistment checkpoint failed"): return _report(phase, world)
		if not _act(world, "first_march"): return _report(phase, world)
		var reserved := world.create_battle_ticket()
		if not _expect(reserved.ok, "first battle reservation failed"): return _report(phase, world)
		var battle := world.start_battle(reserved.ticket.battle_id)
		_expect(not battle.issue_order("attack"), "recruit gained unearned command")
		battle.use_action("guard")
		battle.set_player_input(Vector2(0.2, -0.1), Vector2.RIGHT)
		battle.step(0.03125)
		if not _expect(store.save_slot(world, "active").ok, "active fractional battle save failed"): return _report(phase, world)
		var pending := World.new()
		if not _expect(pending.restore_campaign_state(world.export_campaign_state()).ok, "pending branch clone failed"): return _report(phase, world)
		if not _play(pending, "fight"): return _report(phase, world)
		if not _expect(store.save_slot(pending, "pending").ok, "uncommitted battle save failed"): return _report(phase, world)
		if not _finish(world): return _report(phase, world)
		_expect(store.save_slot(world, "expected").ok, "endpoint oracle save failed")
	else:
		if not _expect(store.load_slot(world, "active").ok, "previous-process active save missing or invalid"): return _report(phase, world)
		if not _finish(world): return _report(phase, world)
		var expected := World.new()
		if not _expect(store.load_slot(expected, "expected").ok, "previous-process endpoint missing or invalid"): return _report(phase, world)
		_expect(world.export_campaign_state() == expected.export_campaign_state(), "restarted life differs in world, RNG, roster, merit, evidence or relationships")
		var pending := World.new()
		if not _expect(store.load_slot(pending, "pending").ok, "pending save could not load"): return _report(phase, world)
		var id: String = pending.player_view().active_battle
		if not _expect(not id.is_empty(), "pending battle ID missing"): return _report(phase, world)
		var battle := pending.start_battle(id)
		if not _expect(battle.ended, "pending battle did not retain terminal state"): return _report(phase, world)
		var outcome := battle.outcome()
		var receipt := store.commit_and_save(pending, outcome, "settled")
		_expect(receipt.ok and not receipt.get("receipt", {}).get("already_committed", true), "pending receipt not applied exactly once")
		var before := pending.export_campaign_state()
		var repeated := store.commit_and_save(pending, outcome, "settled")
		_expect(repeated.ok and repeated.get("receipt", {}).get("already_committed", false), "receipt retry missing")
		_expect(pending.export_campaign_state() == before, "receipt retry duplicated casualties or rewards")
		var checkpoint := World.new()
		_expect(store.load_checkpoint(checkpoint, "enlistment").ok and checkpoint.youth_view().stage == "first_orders" and checkpoint.snapshot().youth.roster.size() == 5, "full-life checkpoint did not restore original roster")
	return _report(phase, world)

func _finish(world: WorldSimulation) -> bool:
	if not _play(world, "fight") or not _settle(world): return false
	_expect(world.youth_view().earned_merit > 0, "real first fight earned no merit")
	for action in ["return_to_camp", "keep_evidence", "accept_appointment", "dangerous_march"]:
		if not _act(world, action): return false
	var reserved := world.create_battle_ticket()
	if not _expect(reserved.ok, "dangerous battle reservation failed"): return false
	if not _play(world, "delayed_retreat") or not _settle(world): return false
	var receipt: Dictionary = world.battle_ticket(reserved.ticket.battle_id).outcome
	_expect(receipt.result == "retreat" and receipt.forces[0].dead_ids.size() > 0, "dangerous mission must produce real casualties and physical retreat")
	for action in ["return_to_camp", "replenish"]:
		if not _act(world, action): return false
	var view := world.youth_view()
	_expect(view.stage == "endpoint" and view.evidence.size() == 1 and world.snapshot().commander.alive, "surviving endpoint or evidence missing")
	_expect(world.audit().is_empty(), "endpoint world conservation failed")
	return _errors.is_empty()

func _act(world: WorldSimulation, action: String) -> bool:
	return _expect(world.youth_action(action).ok, "youth action failed: " + action)

func _settle(world: WorldSimulation) -> bool:
	var id: String = world.player_view().active_battle
	if not _expect(not id.is_empty(), "settlement has no active battle"): return false
	return _expect(world.commit_battle_outcome(world.start_battle(id).outcome()).ok, "battle settlement failed")

func _play(world: WorldSimulation, policy: String) -> bool:
	var id: String = world.player_view().active_battle
	if not _expect(not id.is_empty(), "playback has no active battle"): return false
	var battle := world.start_battle(id)
	if world.battle_ticket(id).command_authority == "squad": battle.issue_order("attack")
	for frame in range(18000):
		if battle.ended: break
		var hero := battle.player()
		var target: Vector2 = hero.pos + Vector2.RIGHT
		var distance := INF
		for unit in battle.units:
			if unit.team == 1 and unit.hp > 0.0:
				var candidate: float = hero.pos.distance_to(unit.pos)
				if candidate < distance:
					distance = candidate
					target = unit.pos
		var direction: Vector2 = target - hero.pos
		if policy == "delayed_retreat":
			if battle.elapsed > 13.0:
				battle.issue_order("retreat")
				battle.set_player_input(Vector2.LEFT, Vector2.RIGHT)
			else:
				battle.set_player_input(Vector2.ZERO, direction)
		else:
			battle.set_player_input(direction if distance > 1.5 else Vector2.ZERO, direction)
			for action in ["guard", "attack", "sweep"]: battle.use_action(action)
		battle.step(BattleSimulation.FIXED_DELTA)
		if not world.sync_battle_time(id):
			return _expect(false, "battle/world clock synchronization failed")
	return _expect(battle.ended and battle.player().hp > 0.0, "bounded real-control battle did not reach a surviving end")

func _expect(condition: bool, error: String) -> bool:
	_checks += 1
	if not condition: _errors.append(error)
	return condition

func _report(phase: String, world: WorldSimulation) -> Dictionary:
	return {"ok": _errors.is_empty(), "phase": phase, "checks": _checks, "errors": _errors,
		"world_version": world.snapshot().version, "world_time": world.snapshot().time_seconds,
		"hero_hp": world.snapshot().commander.hp, "stage": world.youth_view().stage,
		"events": world.snapshot().events.size(), "envelope_version": Store.SAVE_VERSION}
