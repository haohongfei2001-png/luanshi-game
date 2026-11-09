class_name CourierPersistenceSmoke
extends RefCounted
## Export-safe, real-action courier and local-signal restart acceptance.
const World := preload("res://scripts/world_sim.gd")
const Store := preload("res://scripts/campaign_store.gd")
var _errors: Array[String] = []
var _checks := 0

static func run(phase: String, isolated_id: String) -> Dictionary:
	return CourierPersistenceSmoke.new()._run(phase, isolated_id)

func _run(phase: String, isolated_id: String) -> Dictionary:
	var store := Store.new("courier_" + isolated_id)
	var world := World.new(184)
	if phase == "prepare":
		if not _expect(world.start_youth("forced", "homeland").ok, "enlistment failed"): return _report(phase, world)
		var stock: Dictionary = world.snapshot().cities.pingling.duplicate(true)
		if not _act(world, "arrange_courier"): return _report(phase, world)
		_expect(world.snapshot().cities.pingling.soldiers == stock.soldiers - 1 and world.snapshot().cities.pingling.food == stock.food - 10, "dispatch did not debit real stock")
		if not _act(world, "first_march"): return _report(phase, world)
		_expect(world.snapshot().couriers[0].status == "outbound", "outbound save is not in flight")
		_expect(world.player_view().courier_orders[0].known == "arranged", "outbound facts leaked to player")
		if not _save(store, world, "outbound"): return _report(phase, world)
		if not _prepare_signal(store, world): return _report(phase, world)
		for response in ["comply", "refuse"]:
			var branch := World.new()
			if not _expect(store.load_slot(branch, "outbound").ok, "outbound clone load failed"): return _report(phase, world)
			if not _deliver_and_reply(branch, response): return _report(phase, world)
			if not _save(store, branch, "returning_" + response): return _report(phase, world)
			if not _finish_return(branch): return _report(phase, world)
			if not _save(store, branch, "expected_" + response): return _report(phase, world)
	elif phase == "resume":
		for response in ["comply", "refuse"]:
			if not _expect(store.load_slot(world, "outbound").ok, "previous-process outbound save failed"): return _report(phase, world)
			if not _deliver_and_reply(world, response): return _report(phase, world)
			if not _finish_return(world): return _report(phase, world)
			if not _compare(store, world, "expected_" + response): return _report(phase, world)
			if not _expect(store.load_slot(world, "returning_" + response).ok, "previous-process return save failed"): return _report(phase, world)
			_expect(world.snapshot().couriers[0].status == "returning", "return save not in flight")
			if not _finish_return(world): return _report(phase, world)
			if not _compare(store, world, "expected_" + response): return _report(phase, world)
		if not _expect(store.load_slot(world, "signal").ok, "previous-process pending signal load failed"): return _report(phase, world)
		if not _finish_signal(world): return _report(phase, world)
		_compare(store, world, "expected_signal")
	else:
		_expect(false, "unsupported phase")
	return _report(phase, world)

func _deliver_and_reply(world: WorldSimulation, response: String) -> bool:
	if not _act(world, "wait_courier"): return false
	if not _expect(world.snapshot().couriers[0].status == "awaiting_reply" and world.player_view().courier_orders[0].can_reply, "real courier did not deliver"): return false
	if not _act(world, "courier_" + response): return false
	return _expect(world.snapshot().couriers[0].camp_received_at == -1.0 and world.player_view().courier_orders[0].known == "reply_sent", "reply arrived without return travel")

func _finish_return(world: WorldSimulation) -> bool:
	for hour in range(3):
		if not _act(world, "wait_courier"): return false
		if hour < 2: _expect(world.snapshot().couriers[0].status == "returning", "courier arrived before three hours")
	var courier: Dictionary = world.snapshot().couriers[0]
	_expect(courier.status == "returned" and courier.camp_received_at == courier.reply_at + 10800.0, "return receipt timing mismatch")
	var visible: Dictionary = world.player_view().courier_orders[0]
	_expect(visible.known == "reply_sent" and not visible.has("status") and not visible.has("camp_received_at"), "remote camp receipt leaked to player")
	return _expect(world.audit().is_empty(), "courier conservation failed")

func _prepare_signal(store: CampaignStore, source: WorldSimulation) -> bool:
	var world := World.new()
	if not _expect(world.restore_campaign_state(source.export_campaign_state()).ok, "signal branch clone failed"): return false
	var reserved := world.create_battle_ticket()
	if not _expect(reserved.ok, "signal battle reservation failed"): return false
	var battle := world.start_battle(reserved.ticket.battle_id)
	if not _expect(battle.issue_order("retreat"), "recruit local retreat refused"): return false
	battle.step(0.03125)
	if not _expect(world.sync_battle_time(reserved.ticket.battle_id), "signal clock sync failed"): return false
	if not _expect(not battle.pending_signals.is_empty(), "no actual pending local signal"): return false
	if not _save(store, world, "signal"): return false
	if not _finish_signal(world): return false
	return _save(store, world, "expected_signal")

func _finish_signal(world: WorldSimulation) -> bool:
	var id: String = world.player_view().active_battle
	if not _expect(not id.is_empty(), "signal battle missing"): return false
	var battle := world.start_battle(id)
	if not _expect(not battle.pending_signals.is_empty(), "saved local signals missing"): return false
	for frame in range(120):
		battle.step(BattleSimulation.FIXED_DELTA)
		if not _expect(world.sync_battle_time(id), "resumed signal clock failed"): return false
	return _expect(not battle.last_signal.delivered.is_empty(), "local retreat never reached a soldier")

func _act(world: WorldSimulation, action: String) -> bool:
	var result := world.youth_action(action)
	return _expect(result.ok, "action " + action + ": " + JSON.stringify(result))

func _save(store: CampaignStore, world: WorldSimulation, slot: String) -> bool:
	var result := store.save_slot(world, slot)
	return _expect(result.ok, "save " + slot + ": " + JSON.stringify(result))

func _compare(store: CampaignStore, world: WorldSimulation, slot: String) -> bool:
	var expected := World.new()
	if not _expect(store.load_slot(expected, slot).ok, "oracle load failed: " + slot): return false
	return _expect(world.export_campaign_state() == expected.export_campaign_state(), "exact world/battle/RNG/courier/knowledge mismatch: " + slot)

func _expect(condition: bool, error: String) -> bool:
	_checks += 1
	if not condition: _errors.append(error)
	return condition

func _report(phase: String, world: WorldSimulation) -> Dictionary:
	return {"ok": _errors.is_empty(), "phase": phase, "checks": _checks, "errors": _errors,
		"world_version": world.snapshot().version, "world_time": world.snapshot().time_seconds,
		"couriers": world.snapshot().couriers, "player_knowledge": world.player_view().courier_orders}
