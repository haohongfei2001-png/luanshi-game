class_name CampaignPersistenceSmoke
extends RefCounted
## Runtime-safe persistence acceptance entry for exported builds (no test imports).
## App hook calls run(), prints a phase-specific marker, then exits nonzero on error.
const World := preload("res://scripts/world_sim.gd")
const Store := preload("res://scripts/campaign_store.gd")
var _errors: Array[String] = []

static func run(phase: String, isolated_id: String = "export_v1") -> Dictionary:
	return CampaignPersistenceSmoke.new()._run(phase, isolated_id)

func _run(phase: String, isolated_id: String) -> Dictionary:
	if phase not in ["prepare", "resume"]:
		return {"ok": false, "errors": ["unsupported phase"]}
	var store := Store.new("runtime_smoke_" + isolated_id)
	var world := World.new(998877)
	if phase == "prepare":
		world.observe_city("pingling", 20)
		world.march("river")
		world.advance_seconds(10800.125)
		var reserved := world.create_battle_ticket()
		if not reserved.ok:
			return {"ok": false, "errors": ["reservation failed"]}
		var id: String = reserved.ticket.battle_id
		var battle := world.start_battle(id)
		battle.issue_order("attack")
		_play(world, id, 330)
		_expect(store.save_slot(world, "running").ok, "midbattle save failed")
		_play(world, id, 10800)
		_expect(battle.ended, "uninterrupted battle did not end")
		_expect(store.save_slot(world, "pending").ok, "pending save failed")
		_expect(store.commit_and_save(world, battle.outcome(), "committed").ok, "durable settlement failed")
		_expect(store.save_checkpoint(world, "expected").ok, "oracle save failed")
	else:
		var expected := World.new()
		if not store.load_checkpoint(expected, "expected").ok or not store.load_slot(world, "running").ok:
			return {"ok": false, "phase": phase, "errors": ["previous-process saves missing or invalid"]}
		var id: String = world.player_view().active_battle
		if id.is_empty():
			return {"ok": false, "phase": phase, "errors": ["active battle missing"]}
		_play(world, id, 10800)
		_expect(world.commit_battle_outcome(world.start_battle(id).outcome()).ok, "resumed settlement failed")
		_expect(world.export_campaign_state() == expected.export_campaign_state(), "fresh-process RNG/world mismatch")
		if not store.load_slot(world, "pending").ok:
			return {"ok": false, "phase": phase, "errors": ["pending save invalid"]}
		id = world.player_view().active_battle
		var outcome := world.start_battle(id).outcome()
		_expect(store.commit_and_save(world, outcome, "recovered").ok, "pending recovery failed")
		_expect(world.export_campaign_state() == expected.export_campaign_state(), "pending recovery mismatch")
		if not store.load_slot(world, "committed").ok:
			return {"ok": false, "phase": phase, "errors": ["committed save invalid"]}
		var before := world.export_campaign_state()
		var duplicate := store.commit_and_save(world, outcome, "committed")
		_expect(duplicate.ok and duplicate.get("receipt", {}).get("already_committed", false), "receipt retry failed")
		_expect(world.export_campaign_state() == before and before == expected.export_campaign_state(), "duplicate resource settlement")
	return {"ok": _errors.is_empty(), "phase": phase, "errors": _errors,
		"campaign": "runtime_smoke_" + isolated_id, "world_time": world.snapshot().time_seconds,
		"events": world.snapshot().events.size(), "schema_version": Store.SAVE_VERSION}

func _play(world: WorldSimulation, id: String, frames: int) -> void:
	var battle := world.start_battle(id)
	for frame in range(frames):
		battle.step(BattleSimulation.FIXED_DELTA)
		if not world.sync_battle_time(id):
			_errors.append("clock synchronization failed")
			return
		if battle.ended:
			return

func _expect(condition: bool, error: String) -> void:
	if not condition:
		_errors.append(error)
