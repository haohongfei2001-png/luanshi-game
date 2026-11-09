extends SceneTree
const Battle := preload("res://scripts/battle_sim.gd")
const World := preload("res://scripts/world_sim.gd")
var checks := 0
var failures: Array[String] = []

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)
		push_error(label)

func fresh() -> BattleSimulation:
	var b := Battle.new()
	b.reset()
	return b

func advance(b: BattleSimulation, frames: int = 60) -> void:
	for i in range(frames): b.step(Battle.FIXED_DELTA)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	if "--write-restart" in OS.get_cmdline_user_args() or "--read-restart" in OS.get_cmdline_user_args():
		_restart_probe()
		return
	var b := fresh()
	b.units[0].pos = b.player().pos + Vector2(2, 0)
	b.units[1].pos = Vector2(5, 15)
	check(b.issue_order("attack"), "local flag accepted")
	check(b.units[0].received_order == "follow" and b.units[1].received_order == "follow", "issuing intent does not instantly alter AI")
	check(b.signal_status().delivered == 0 and b.signal_status().pending > 0, "HUD begins pending not active")
	b.units[1].pos = b.player().pos + Vector2(0, 3)
	advance(b)
	check(b.units[0].received_order == "attack", "visible soldier receives finite signal")
	check(b.units[1].received_order == "follow", "entering radius later cannot acquire old flag")
	check(b.units[20].received_order == "attack" and b.units[20].received_order_sequence == 0, "enemy never receives ally signal")
	check(b.units.size() == 41, "signal creates no soldiers")
	b = fresh()
	b.player().pos = Vector2(0, 15)
	b.units[0].pos = Vector2(0, 14)
	b.units[1].pos = Vector2(-21, 0)
	b.issue_order("attack")
	check(b.last_signal.origin == Vector2(0, 15) and 0 in b.last_signal.recipients and 1 not in b.last_signal.recipients, "flag originates at actual current hero location")
	b = fresh()
	b.issue_order("attack")
	b.units[0].hp = 0.0
	b.units[1].pos = Vector2(20, 15)
	advance(b)
	check(b.units[0].received_order == "follow", "dead recipient does not receive")
	check(b.units[1].received_order == "follow", "recipient outside visibility at receipt misses flag")
	b.player().hp = 0.0
	check(not b.issue_order("retreat"), "dead issuer cannot signal even before result tick")
	b = fresh()
	b.issue_order("attack")
	b.issue_order("retreat")
	check(b.pending_signals.size() <= 20, "repeated signals bounded to real recipients")
	advance(b)
	check(b.units[0].received_order == "retreat" and b.units[0].received_order_sequence == 2, "newer recipient signal supersedes older")
	check(b.signal_status().delivered == b.signal_status().recipients, "HUD delivery totals reflect latest receipt")
	b.issue_order("retreat")
	advance(b)
	check(b.units[0].received_order_sequence == 3, "same instruction can be deliberately signaled again")
	b.reset()
	check(b.pending_signals.is_empty() and b.signal_sequence == 0 and b.last_signal.is_empty() and b.units[0].received_order == "follow", "restart clears signal history")
	b = fresh()
	for i in range(90):
		b.issue_order("retreat")
		b.step(Battle.FIXED_DELTA)
	check(b.units[0].received_order == "retreat", "holding same flag never starves finite recognition")
	var one := fresh()
	var two := fresh()
	for sim in [one, two]:
		sim.issue_order("attack")
		advance(sim, 100)
		sim.issue_order("follow")
		advance(sim, 100)
	check(one.export_campaign_state() == two.export_campaign_state(), "seeded signal and AI execution deterministic")
	_test_save()
	_test_authority()
	_test_forged_receipts()
	print("LOCAL_SIGNALS_TESTS " + JSON.stringify({"checks": checks, "failures": failures}))
	quit(0 if failures.is_empty() else 1)

func _test_save() -> void:
	var world := World.new()
	world.march("river")
	world.advance(3)
	var ticket: Dictionary = world.create_battle_ticket().ticket
	var original := world.start_battle(ticket.battle_id)
	original.issue_order("attack")
	advance(original, 5)
	var snapshot := original.export_campaign_state()
	var loaded := Battle.new()
	check(loaded.restore_campaign_state(snapshot, ticket).ok, "in-flight signal snapshot restores")
	check(loaded.export_campaign_state() == snapshot, "pending recipients, timings, counters exact")
	for i in range(100):
		original.step(Battle.FIXED_DELTA)
		loaded.step(Battle.FIXED_DELTA)
	check(original.export_campaign_state() == loaded.export_campaign_state(), "resumed signal arrives once with identical simulation")
	var bad := snapshot.duplicate(true)
	bad.pending_signals[0].recipient = loaded.player().id
	var before := loaded.export_campaign_state()
	check(not loaded.restore_campaign_state(bad, ticket).ok and before == loaded.export_campaign_state(), "invalid hero recipient rejected atomically")
	bad = snapshot.duplicate(true)
	bad.pending_signals[0].due = 1000.0
	check(not loaded.restore_campaign_state(bad, ticket).ok, "unbounded signal delay rejected")
	var legacy := snapshot.duplicate(true)
	for key in ["signal_model", "signal_sequence", "pending_signals", "last_signal"]: legacy.erase(key)
	for unit in legacy.units:
		unit.erase("received_order")
		unit.erase("received_order_sequence")
	check(not loaded.restore_campaign_state(legacy, ticket).ok, "new saves cannot silently omit signal state")
	var old_ticket := ticket.duplicate(true)
	old_ticket["signal_model"] = "legacy_global_v0"
	check(loaded.restore_campaign_state(Battle.migrate_legacy_session(legacy), old_ticket).ok and loaded.units[0].received_order == legacy.order and loaded.pending_signals.is_empty(), "legacy battle seeds actually held global order without invented signals")

	check(loaded.issue_order("retreat") and loaded.units[0].received_order == "retreat" and loaded.pending_signals.is_empty(), "migrated legacy active fight retains immediate historical orders")
	loaded.reset()
	check(loaded.signal_model == "local_v1", "new fight leaves legacy compatibility model")

func _test_authority() -> void:
	var b := fresh()
	b._ticket = {"command_authority": "withdrawal_only"}
	check(not b.issue_order("attack") and not b.issue_order("follow"), "recruit cannot command squad")
	check(b.issue_order("retreat") and not b.pending_signals.is_empty(), "recruit may emit pre-agreed local retreat signal")
	check(b.units[0].received_order == "follow", "pre-agreed retreat still requires finite receipt time")
	b.player().pos = Vector2(-29, 0)
	b._check_result()
	check(not b.ended, "recruit cannot end battle while allies remain outside extraction")
	advance(b)
	check(b.units[0].received_order == "retreat", "nearby allies receive pre-agreed withdrawal")
	for unit in b.units:
		if unit.team == 0: unit.pos = Vector2(-29, 0)
	b._check_result()
	check(b.ended and b.result == "The company withdrew", "withdrawal requires all survivors physically extracted")

func _restart_probe() -> void:
	var codec := preload("res://scripts/campaign_value_codec.gd").new()
	var path := "user://local_signal_restart.json"
	if "--write-restart" in OS.get_cmdline_user_args():
		var world := World.new()
		world.march("river")
		world.advance(3)
		var ticket: Dictionary = world.create_battle_ticket().ticket
		var battle := world.start_battle(ticket.battle_id)
		battle.issue_order("retreat")
		advance(battle, 5)
		var state := battle.export_campaign_state()
		advance(battle, 100)
		var encoded := codec.encode({"ticket": ticket, "state": state, "expected": battle.export_campaign_state()})
		check(encoded.ok, "encode restart fixture")
		FileAccess.open(path, FileAccess.WRITE).store_string(JSON.stringify(encoded.value))
	else:
		var decoded := codec.decode(JSON.parse_string(FileAccess.get_file_as_string(path)))
		check(decoded.ok, "decode prior process fixture")
		var battle := Battle.new()
		check(battle.restore_campaign_state(decoded.value.state, decoded.value.ticket).ok, "restore signals in fresh process")
		advance(battle, 100)
		check(battle.export_campaign_state() == decoded.value.expected, "fresh process delivery exactly matches uninterrupted process")
	print("LOCAL_SIGNAL_RESTART " + JSON.stringify({"checks": checks, "failures": failures}))
	quit(0 if failures.is_empty() else 1)

func _test_forged_receipts() -> void:
	var world := World.new()
	world.start_youth("volunteer", "homeland")
	world.youth_action("first_march")
	var ticket: Dictionary = world.create_battle_ticket().ticket
	var battle := world.start_battle(ticket.battle_id)
	var saved := battle.export_campaign_state()
	saved.units[0].received_order = "follow"
	var target := Battle.new()
	check(not target.restore_campaign_state(saved, ticket).ok, "zero-sequence recruit cannot forge unauthorized follow order")
	battle.issue_order("retreat")
	_test_signal_field_types(battle, ticket)
	saved = battle.export_campaign_state()
	var recipient: int = saved.pending_signals[0].recipient
	saved.units[recipient].received_order = "retreat"
	saved.units[recipient].received_order_sequence = saved.signal_sequence
	saved.last_signal.delivered.append(recipient)
	saved.pending_signals = saved.pending_signals.filter(func(message: Dictionary) -> bool: return message.recipient != recipient)
	check(not target.restore_campaign_state(saved, ticket).ok, "forged receipt before recognition delay rejected")
	saved.elapsed = 0.16
	check(not target.restore_campaign_state(saved, ticket).ok, "receipt after recognition but before recorded propagation deadline rejected")
	saved = battle.export_campaign_state()
	saved.units[recipient].received_order = "retreat"
	saved.units[recipient].received_order_sequence = saved.signal_sequence
	check(not target.restore_campaign_state(saved, ticket).ok, "latest unit receipt must exist in delivery evidence")

func _test_signal_field_types(battle: BattleSimulation, ticket: Dictionary) -> void:
	var original := battle.export_campaign_state()
	var target := Battle.new()
	for value in [null, true, 1.25, "bad", [], {}, Vector2.ZERO]:
		for key in ["sequence", "name", "due_times"]:
			if typeof(value) == typeof(original.last_signal[key]): continue
			var saved := original.duplicate(true)
			saved.last_signal[key] = value
			check(not target.restore_campaign_state(saved, ticket).ok, "malformed latest signal field safely rejected " + key)
		if not value is float:
			var saved := original.duplicate(true)
			saved.last_signal.due_times[0] = value
			check(not target.restore_campaign_state(saved, ticket).ok, "malformed nested propagation deadline safely rejected")
