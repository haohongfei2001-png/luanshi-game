extends SceneTree

const World := preload("res://scripts/world_sim.gd")
const Store := preload("res://scripts/campaign_store.gd")
const Codec := preload("res://scripts/campaign_value_codec.gd")
const Adapter := preload("res://scripts/battle_adapter.gd")
var assertions := 0
var failures: Array[String] = []
var store: CampaignStore
var test_id := ""

func _initialize() -> void:
	call_deferred("_run")

func check(condition: bool, label: String) -> void:
	assertions += 1
	if not condition:
		failures.append(label)
		push_error(label)

func local_world() -> WorldSimulation:
	var world := World.new(184)
	world.advance_seconds(0.125)
	world.observe_city("pingling", 8)
	world.march("river")
	world.advance(3)
	return world

func finish(sim: BattleSimulation) -> void:
	for unit in sim.units:
		if unit.team == 1:
			sim._hurt(unit, 1000.0, false)
	sim._check_result()

func roundtrip(world: WorldSimulation, slot: String) -> WorldSimulation:
	var original := world.export_campaign_state()
	var written := store.save_slot(world, slot)
	check(written.ok, slot + " saves: " + str(written))
	var loaded := World.new(999)
	var result := store.load_slot(loaded, slot)
	check(result.ok, slot + " loads: " + str(result))
	check(loaded.export_campaign_state() == original, slot + " exact whole state")
	check(loaded.audit().is_empty(), slot + " audit")
	return loaded

func _run() -> void:
	test_id = "test_saves_" + Crypto.new().generate_random_bytes(8).hex_encode()
	store = Store.new(test_id)
	_test_codec()
	_test_strategy()
	_test_sessions()
	_test_resume()
	_test_invalid()
	_test_durable_settlement()
	_test_death_checkpoint()
	_test_review_regressions()
	_test_wrong_types()
	print("Campaign save tests: %d assertions, %d failures" % [assertions, failures.size()])
	print("SAVE_TEST_SUMMARY " + JSON.stringify({"assertions": assertions, "failures": failures.size(), "messages": failures, "isolated_directory": test_id}))
	quit(0 if failures.is_empty() else 1)

func _test_codec() -> void:
	var value := {"int": 9007199254740993, "max": 9223372036854775807, "min": -9223372036854775807 - 1, "float": 0.12345678901234567, "vector": Vector2(0.1234567, -20.1213), "nested": [{"flag": true}, null, "中文"]}
	var codec := Codec.new()
	var encoded := codec.encode(value)
	var json: Variant = JSON.parse_string(JSON.stringify(encoded.value))
	check(encoded.ok and codec.decode(json).value == value, "codec preserves int64/float/vector bits through JSON")
	for invalid in [["i", "9223372036854775808"], ["i", "01"], ["f", "000000000000f07f"], ["d", [["same", true], ["same", false]]], ["object", "script"], ["i", 100.0]]:
		check(not codec.decode(invalid).ok, "invalid codec value rejected " + str(invalid))
	check(not codec.encode(INF).ok and not codec.encode(RefCounted.new()).ok, "no infinity or objects encoded")
	var example := store.decode_campaign(FileAccess.get_file_as_bytes("res://docs/examples/campaign-save-v1.json"))
	check(example.ok and example.state == World.new(184, "legacy_test_v0").export_campaign_state(), "documented v0.6 sample migrates to explicit legacy with exact initial state")

func _test_strategy() -> void:
	var world := local_world()
	var loaded := roundtrip(world, "strategy")
	check(loaded.snapshot().convoys.size() == 3 and loaded.snapshot().pending_reports.size() == 1, "cargo and delayed intelligence remain in flight")
	check(not loaded.player_view().known.has("pingling"), "load does not reveal pending intelligence")
	check(world.advance_seconds(7 * 3600.0 + 0.3456789012) and loaded.advance_seconds(7 * 3600.0 + 0.3456789012), "both worlds continue")
	check(world.export_campaign_state() == loaded.export_campaign_state(), "uninterrupted and loaded strategic consequences match exactly")
	# Conservation-valid int64 value beyond IEEE-754 exact JSON integer range.
	world._state.cities.pingling.food += 9007199254740993
	world._state.initial_totals.food += 9007199254740993
	loaded = roundtrip(world, "integer_precision")
	check(loaded.snapshot().cities.pingling.food == world.snapshot().cities.pingling.food, "large food stock not rounded")
	check(store.list_saves().saves.has("strategy"), "named slots discoverable")
	check(store.save_slot(World.new(), "strategy").ok, "free slot can be atomically overwritten")
	var fresh := World.new()
	check(store.load_slot(fresh, "strategy").ok and fresh.snapshot().hour == 0, "overwrite loads latest complete state")

func _test_sessions() -> void:
	var world := local_world()
	var reservation := world.create_battle_ticket()
	var id: String = reservation.ticket.battle_id
	var loaded := roundtrip(world, "reserved")
	var simulation := loaded.start_battle(id)
	check(simulation != null and simulation.units.size() == 35, "loaded reserved ticket starts real roster")
	check(loaded.start_battle(id) == simulation, "loaded start exactly once")
	world.cancel_battle_ticket(id)
	loaded = roundtrip(world, "cancelled")
	check(loaded.start_battle(id) == null and loaded.snapshot().battle_locks.is_empty(), "cancelled ticket stays cancelled")
	world = local_world()
	var adapter := Adapter.new(world)
	adapter.begin_local_depot()
	id = adapter.ticket.battle_id
	adapter.simulation.step(0.01666666666666667)
	adapter.simulation.use_action("guard")
	# Save before sync must keep both the lagging world clock and active elapsed.
	loaded = roundtrip(world, "running_unsynced")
	check(loaded.start_battle(id).elapsed > loaded.battle_ticket(id).elapsed_world_time, "unsynced elapsed preserved, not lost or double-applied")
	check(loaded.sync_battle_time(id), "loaded running clock syncs")
	check(loaded.snapshot().time_seconds == loaded.battle_ticket(id).time + adapter.simulation.elapsed, "exact subframe synchronization")
	check(world.restore_campaign_state(loaded.export_campaign_state()).ok, "live authority loads validated session")
	check(not adapter.sync_world() and not adapter.settle().ok, "stale adapter cannot sync or settle replacement session")
	check(adapter.resume(id).ok and adapter.simulation == world.start_battle(id), "presentation can explicitly rebind loaded session")
	finish(adapter.simulation)
	loaded = roundtrip(world, "pending_outcome")
	check(loaded.start_battle(id).ended, "finished pending outcome resumes terminal state")
	var outcome := loaded.start_battle(id).outcome()
	check(loaded.commit_battle_outcome(outcome).ok, "loaded pending outcome commits")
	loaded = roundtrip(loaded, "committed")
	var before := loaded.export_campaign_state()
	var repeated := loaded.commit_battle_outcome(outcome)
	check(repeated.ok and repeated.already_committed and loaded.export_campaign_state() == before, "loaded committed receipt is idempotent")
	var forged := outcome.duplicate(true)
	forged.spoils.weapons += 1
	check(not loaded.commit_battle_outcome(forged).ok and loaded.export_campaign_state() == before, "conflicting loaded settlement cannot mint spoils")
	loaded.reset(184)
	check(not loaded.commit_battle_outcome(outcome).ok, "old generation ticket rejected after loaded reset")

func _test_resume() -> void:
	var world := local_world()
	var id: String = world.create_battle_ticket().ticket.battle_id
	var sim := world.start_battle(id)
	sim.issue_order("attack")
	for frame in range(330):
		sim.step(BattleSimulation.FIXED_DELTA)
		world.sync_battle_time(id)
	var loaded := roundtrip(world, "deterministic_combat")
	var resumed := loaded.start_battle(id)
	for frame in range(1000):
		if frame % 19 == 0:
			sim.use_action("guard")
			resumed.use_action("guard")
		sim.step(BattleSimulation.FIXED_DELTA)
		resumed.step(BattleSimulation.FIXED_DELTA)
		world.sync_battle_time(id)
		loaded.sync_battle_time(id)
		check(sim.export_campaign_state() == resumed.export_campaign_state(), "deterministic resumed frame %d" % frame)
		if sim.ended:
			break
	check(sim.rng.state == resumed.rng.state and sim.outcome() == resumed.outcome(), "combat RNG/outcome preserved")
	check(world.export_campaign_state() == loaded.export_campaign_state(), "battle and strategic state remain identical")

func rejected(saved: Variant, label: String) -> void:
	var live := local_world()
	var id: String = live.create_battle_ticket().ticket.battle_id
	var old_sim := live.start_battle(id)
	var before := live.export_campaign_state()
	var result := live.restore_campaign_state(saved)
	check(not result.ok, label + " rejected")
	check(live.export_campaign_state() == before and live.start_battle(id) == old_sim, label + " no partial mutation or session swap")

func _test_invalid() -> void:
	var initial := local_world().export_campaign_state()
	for field in initial.world:
		var missing := initial.duplicate(true)
		missing.world.erase(field)
		rejected(missing, "missing " + field)
	for field in initial.world:
		var malformed := initial.duplicate(true)
		malformed.world[field] = RefCounted.new()
		rejected(malformed, "wrong type " + field)
	for mutate in [
		func(s): s.world.cities.anping.food += 1,
		func(s): s.world.time_seconds = INF,
		func(s): s.world.version = 99,
		func(s): s.world.hour += 1,
		func(s): s.world.armies.relief.condition.fatigue = 101,
		func(s): s.world.pending_reports[0].arrives_at_seconds = 0.0,
		func(s): s.world.convoys[0].id = s.world.next_convoy,
		func(s): s.world.battle_locks.relief = "missing",
		func(s): s.world.next_report = 1,
		func(s): s.world.commander.alive = false,
		func(s): s.world.cities.anping.owner = "unknown",
		func(s): s.world.events[0].time_seconds = INF,
		func(s): s.world.initial_totals.soldiers = 9223372036854775807,
	]:
		var corrupt := initial.duplicate(true)
		mutate.call(corrupt)
		rejected(corrupt, "causal corruption")
	var world := local_world()
	var id: String = world.create_battle_ticket().ticket.battle_id
	world.start_battle(id)
	var running := world.export_campaign_state()
	for mutate in [
		func(s): s.battle_sessions.clear(),
		func(s): s.world.battle_tickets[id].reserved_roster_snapshot[0][0].id = "forged",
		func(s): s.world.battle_tickets[id].status = "committed",
		func(s): s.battle_sessions[id].units[0].weapon = "invented",
		func(s): s.battle_sessions[id].units[1].id = 0,
		func(s): s.battle_sessions[id].units[0].hp = NAN,
		func(s): s.battle_sessions[id].rng_state = 1.0,
		func(s): s.battle_sessions[id].cooldowns.attack = -1.0,
		func(s): s.battle_sessions[id].ended = true,
		func(s): s.battle_sessions[id].units[0].target = 1000,
		func(s): s.world.battle_locks.erase("hequ"),
	]:
		var corrupt := running.duplicate(true)
		mutate.call(corrupt)
		rejected(corrupt, "session corruption")
	var encoded := store.encode_campaign(world)
	check(encoded.ok, "fixture encoding valid")
	for bytes in [PackedByteArray(), encoded.bytes.slice(0, 100), "{}".to_utf8_buffer(), ("[".repeat(101) + "]".repeat(101)).to_utf8_buffer()]:
		check(not store.decode_campaign(bytes).ok, "bad or truncated file rejected")
	var envelope: Dictionary = JSON.parse_string(encoded.bytes.get_string_from_utf8())
	envelope.schema_version = 999
	check(not store.decode_campaign(JSON.stringify(envelope).to_utf8_buffer()).ok, "unsupported save version explicit rejection")
	envelope.schema_version = 1
	envelope.payload += " "
	check(not store.decode_campaign(JSON.stringify(envelope).to_utf8_buffer()).ok, "checksum corruption rejected")
	for id_bad in ["", "../escape", "a/b", "a\\b", "中文", "a".repeat(49)]:
		check(not store.save_slot(world, id_bad).ok, "path identifier rejected " + id_bad)
	check(not Store.new("../escape").save_slot(world, "safe").ok, "campaign directory traversal rejected")
	var before := world.export_campaign_state()
	check(not store.load_slot(world, "missing").ok and world.export_campaign_state() == before, "missing load preserves active campaign")

func _test_durable_settlement() -> void:
	var world := local_world()
	var id: String = world.create_battle_ticket().ticket.battle_id
	var sim := world.start_battle(id)
	sim.step(0.1234567890123)
	finish(sim)
	var outcome := sim.outcome()
	check(store.save_slot(world, "durable").ok, "precommit save durable")
	var before := world.export_campaign_state()
	check(not Store.new("invalid/path").commit_and_save(world, outcome, "durable").ok, "durable commit storage failure reported")
	check(world.export_campaign_state() == before and world.start_battle(id) == sim, "failed durable commit leaves live pending state unchanged")
	var settled := store.commit_and_save(world, outcome, "durable")
	check(settled.ok and settled.receipt.ok, "durable commit writes receipt and inventory together")
	var restarted := World.new()
	check(store.load_slot(restarted, "durable").ok, "durable committed state reloads")
	before = restarted.export_campaign_state()
	var duplicate := store.commit_and_save(restarted, outcome, "durable")
	check(duplicate.ok and duplicate.receipt.already_committed and restarted.export_campaign_state() == before, "durable retry no additional resources or losses")

func _test_death_checkpoint() -> void:
	var world := local_world()
	var alive := world.export_campaign_state()
	check(store.save_checkpoint(world, "life_node").ok, "life checkpoint stores full world")
	var id: String = world.create_battle_ticket().ticket.battle_id
	var sim := world.start_battle(id)
	sim._hurt(sim.player(), 1000.0, false)
	sim._check_result()
	check(world.commit_battle_outcome(sim.outcome()).ok and world.player_view().campaign_ended, "death ends run after settlement")
	roundtrip(world, "death")
	check(store.load_checkpoint(world, "life_node").ok and world.export_campaign_state() == alive, "free checkpoint reload restores full predeath causal world")
	check(store.list_saves(true).saves == ["life_node"], "checkpoint namespace independent of slots")
	world.reset()
	world.reset()
	var issued_generation: int = world.snapshot().campaign_generation
	check(store.load_checkpoint(world, "life_node").ok, "older checkpoint can be loaded after new campaigns")
	var reopened := roundtrip(world, "generation_highwater")
	reopened.reset()
	check(reopened.snapshot().campaign_generation == issued_generation + 1, "loaded rollback preserves generation high-water for stale ticket rejection")

func raw_envelope(saved: Dictionary) -> PackedByteArray:
	# Deliberately bypass writer validation, as a hand-edited untrusted file would.
	var raw := JSON.stringify(Codec.new().encode(saved).value).to_utf8_buffer()
	var payload := Marshalls.raw_to_base64(raw.compress(FileAccess.COMPRESSION_ZSTD))
	return JSON.stringify({"format": Store.FORMAT, "schema_version": Store.SAVE_VERSION,
		"encoding": Store.ENCODING, "uncompressed_bytes": raw.size(),
		"payload": payload, "sha256": payload.sha256_text()}).to_utf8_buffer()

func _test_review_regressions() -> void:
	var world := World.new()
	var encoded: String = store.encode_campaign(world).bytes.get_string_from_utf8()
	check(not store.decode_campaign((encoded.left(-1) + ",}").to_utf8_buffer()).ok, "JSON trailing comma rejected")
	check(not store.decode_campaign(("{\"schema_version\":99," + encoded.substr(1)).to_utf8_buffer()).ok, "duplicate JSON envelope key rejected")
	var invalid := world.export_campaign_state()
	invalid.world.ledger.food_produced += 10
	invalid.world.ledger.food_consumed += 10
	invalid.world.ledger.food_consumed_military += 10
	check(not store.decode_campaign(raw_envelope(invalid)).ok, "balanced but causeless ledger rejected with valid checksum")
	world = local_world()
	var adapter := Adapter.new(world)
	adapter.begin_local_depot()
	var old_sim := adapter.simulation
	var old_ticket := adapter.ticket.duplicate(true)
	check(not adapter.resume("missing").ok and adapter.simulation == old_sim and adapter.ticket == old_ticket, "failed resume preserves valid adapter binding")
	check(not adapter.settle().ok, "failed resume leaves unfinished settle safe")
	finish(adapter.simulation)
	var id: String = adapter.ticket.battle_id
	check(adapter.settle().ok, "review victory fixture settles")
	check(world.player_view().last_battle_id == id and world.last_committed_battle_id() == id, "owned latest committed lookup")
	for mutate in [
		func(s):
			s.world.cities.hequ.soldiers += 15
			s.world.ledger.dead -= 15,
		func(s): s.world.commander.hp -= 50.0,
		func(s): s.world.battle_tickets[id].receipt.depot_captured = false,
		func(s): s.world.events.pop_back(),
		func(s): s.world.events[0].kind = "unsupported_event",
	]:
		invalid = world.export_campaign_state()
		mutate.call(invalid)
		check(not store.decode_campaign(raw_envelope(invalid)).ok, "checksummed receipt/event contradiction rejected")
		rejected(invalid, "receipt/event contradiction")
	var live := local_world()
	var before := live.export_campaign_state()
	var path := "user://campaigns/" + test_id + "/slots/bad_file.save.json"
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_buffer(raw_envelope(invalid))
	file.close()
	check(not store.load_slot(live, "bad_file").ok and live.export_campaign_state() == before, "corrupt disk load keeps live world intact")
	check(store.save_slot(live, "surviving_slot").ok, "original slot exists before interrupted temp")
	file = FileAccess.open("user://campaigns/" + test_id + "/slots/surviving_slot.save.json.tmp-interrupted", FileAccess.WRITE)
	file.store_string("partial write")
	file.close()
	check(store.load_slot(live, "surviving_slot").ok and live.export_campaign_state() == before, "abandoned temporary cannot replace good slot")
	check(not store.list_saves().saves.has("surviving_slot.save.json.tmp-interrupted"), "temporary file not listed as slot")

func _test_wrong_types() -> void:
	var world := local_world()
	var id: String = world.create_battle_ticket().ticket.battle_id
	world.start_battle(id)
	var envelope: Dictionary = JSON.parse_string(store.encode_campaign(world).bytes.get_string_from_utf8())
	envelope.schema_version = Store.SAVE_VERSION
	envelope.uncompressed_bytes = int(envelope.uncompressed_bytes)
	var replacements := [null, true, false, 0, 1.25, "wrong", [], {}]
	for key in envelope:
		for replacement in replacements:
			var corrupt := envelope.duplicate(true)
			corrupt[key] = replacement
			var rejected_file := store.decode_campaign(JSON.stringify(corrupt).to_utf8_buffer())
			check(rejected_file.has("ok") and not rejected_file.ok, "malformed envelope type safely rejected: " + key + ":" + str(typeof(replacement)))
	var dying := local_world()
	var death_id: String = dying.create_battle_ticket().ticket.battle_id
	var battle := dying.start_battle(death_id)
	battle._hurt(battle.player(), 1000.0, false)
	battle._check_result()
	check(dying.commit_battle_outcome(battle.outcome()).ok, "death ordering fixture commits")
	var backwards := dying.export_campaign_state()
	var terminal: Dictionary = backwards.world.events.pop_back()
	terminal.hour = 0
	terminal.time_seconds = 0.0
	backwards.world.events.push_front(terminal)
	rejected(backwards, "death precedes its cause")
	var paths := [
		["world", "initial_totals", "soldiers"], ["world", "events", -2, "details", "counts"],
		["world", "commander", "army"], ["world", "commander", "max_hp"],
		["world", "siege", "city"], ["world", "siege", "army"],
		["world", "convoys", 0, "origin"], ["world", "convoys", 0, "owner"],
		["world", "battle_tickets", id, "location"], ["world", "battle_tickets", id, "status"],
		["world", "battle_tickets", id, "participating_force_ids"],
		["world", "battle_tickets", id, "reserved_roster_snapshot", 0, 0, "force_id"],
		["world", "battle_tickets", id, "reserved_roster_snapshot", 0, 0, "hero"],
		["world", "reports", 0, "contents", "owner"],
		["world", "armies", "relief", "location"],
		["world", "events", 0, "details", "route"],
		["world", "events", 1, "details", "period_hours"],
		["battle_sessions", id, "order"], ["battle_sessions", id, "ended"],
		["battle_sessions", id, "cooldowns"],
	]
	for path in paths:
		for replacement in replacements:
			# Decode to untyped arrays, exactly as untrusted files enter the loader.
			var corrupt: Dictionary = Codec.new().decode(Codec.new().encode(world.export_campaign_state()).value).value
			var parent: Variant = corrupt
			for index in range(path.size() - 1):
				parent = parent[path[index]]
			if typeof(parent.get(path[-1]) if parent is Dictionary else parent[path[-1]]) == typeof(replacement):
				continue
			parent[path[-1]] = replacement
			var result := World.new().restore_campaign_state(corrupt)
			check(result.has("ok") and not result.ok, "nested wrong type safely rejected: " + str(path))
