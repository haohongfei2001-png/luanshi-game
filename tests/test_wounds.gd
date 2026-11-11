extends SceneTree
const W := preload("res://scripts/world_sim.gd")
const Care := preload("res://scripts/wound_care.gd")
const Setup := preload("res://scripts/wound_persistence_smoke.gd")
const Driver := preload("res://tests/youth_combat_driver.gd")
const Store := preload("res://scripts/campaign_store.gd")
var checks := 0
var failures: Array[String] = []
func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label); push_error(label)
func clone(w: WorldSimulation) -> WorldSimulation:
	var other := W.new()
	var r := other.restore_campaign_state(w.export_campaign_state())
	check(r.ok, "exact clone " + str(r))
	check(not r.ok or other.export_campaign_state() == w.export_campaign_state(), "no migration of existing fields")
	return other
func reject(s: Dictionary, label: String) -> void:
	var target := W.new(99)
	var before := target.export_campaign_state()
	check(not target.restore_campaign_state(s).ok, label + " rejected")
	check(target.export_campaign_state() == before, label + " atomic")
func denied(w: WorldSimulation, hours: Variant, label: String) -> void:
	var before := w.export_campaign_state()
	check(not w.rest_wounds(hours).ok, label + " denied")
	check(w.export_campaign_state() == before, label + " no mutation")
func run() -> void:
	var setup := Setup.new()
	var w := setup.build()
	check(setup.failures.is_empty(), "actual input setup " + str(setup.failures))
	var injured := w.snapshot()
	var source: Dictionary = w.player_view().wounds.sources[0]
	check(source.loss == 100.0 - injured.commander.hp and source.hp_before == 100.0, "actual first battle source")
	check(injured.commander.hp > 0.0 and injured.commander.hp < 100.0, "injured alive")
	check(not is_zero_approx(fposmod(injured.time_seconds, 3600.0)), "fractional-second start")
	var initial := w.export_campaign_state()
	var second := clone(w)
	check(second.youth_action("keep_evidence").ok and second.youth_action("accept_appointment").ok and second.youth_action("dangerous_march").ok, "second battle preparation")
	var ticket := second.create_battle_ticket()
	check(ticket.ok, "second battle reservation")
	var b := second.start_battle(ticket.ticket.battle_id)
	check(b.player().hp == injured.commander.hp and b.player().max_hp == 100.0, "unrested second battle retains injury and cap")
	denied(second, 1, "active battle")
	var active := clone(second)
	var b2 := active.start_battle(ticket.ticket.battle_id)
	for frame in range(80): b.step(BattleSimulation.FIXED_DELTA); b2.step(BattleSimulation.FIXED_DELTA)
	check(second.sync_battle_time(ticket.ticket.battle_id) and active.sync_battle_time(ticket.ticket.battle_id), "active continuation sync")
	check(second.export_campaign_state() == active.export_campaign_state(), "active continuation exact")
	for invalid in [false, true, 1.0, 0.0, 0, -1, 7, null, "1", [], {}, NAN, INF]: denied(w, invalid, "closed duration " + str(invalid))
	var control := clone(w)
	control._youth_command = true
	check(control.advance(1), "control real hour")
	control._youth_command = false
	var rest := w.rest_wounds(1)
	check(rest.ok and rest.elapsed == 3600.0 and rest.healed == 5.0, "full continuous fractional hour heals")
	check(w.snapshot().cities == control.snapshot().cities and w.snapshot().armies == control.snapshot().armies and w.snapshot().ledger == control.snapshot().ledger and w.snapshot().reports == control.snapshot().reports, "world economics siege conditions and messages identical to real hour")
	check(w.snapshot().armies.relief.condition.last_activity == "march", "old mixed activity flags not erased by care")
	check(w.snapshot().armies.relief.food == injured.armies.relief.food - 1, "ordinary actual ration cost")
	check(w.snapshot().battle_tickets == injured.battle_tickets and w.snapshot().youth == injured.youth, "no rewrite of battle merit people or history")
	check(w.player_view().wounds.sources == initial.world.battle_tickets.values().map(func(t): return {"battle_id": t.battle_id, "at": t.time + t.elapsed_world_time, "hp_before": t.reserved_roster_snapshot[0][0].hp, "hp_after": t.outcome.player_hp, "loss": t.reserved_roster_snapshot[0][0].hp - t.outcome.player_hp, "result": t.outcome.result}), "source survives healing unchanged")
	var after := w.export_campaign_state()
	check(w.commit_battle_outcome(injured.battle_tickets["1:1"].outcome).already_committed, "repeat commit receipt")
	check(w.export_campaign_state() == after, "repeat commit no damage or recovery duplication")
	clone(w)
	var bulk := W.new(); check(bulk.restore_campaign_state(initial).ok, "bulk restore")
	var split := clone(bulk)
	check(bulk.rest_wounds(2).ok and split.rest_wounds(1).ok and split.rest_wounds(1).ok, "split actions")
	check(bulk.export_campaign_state() == split.export_campaign_state(), "two hours equal two one-hour actions exactly")
	# Real new inputs after recovery record only this battle's incremental loss.
	check(split.youth_action("keep_evidence").ok and split.youth_action("accept_appointment").ok and split.youth_action("dangerous_march").ok, "post-rest next mission")
	var r := split.create_battle_ticket(); var fight := split.start_battle(r.ticket.battle_id)
	check(fight.player().hp == injured.commander.hp + 10.0, "second battle begins at recovered current HP")
	check(split.commit_battle_outcome(Driver.play(fight, "reckless")).ok, "second real combat outcome")
	var source2: Dictionary = split.player_view().wounds.sources[-1]
	check(source2.loss == source2.hp_before - source2.hp_after and source2.hp_before == injured.commander.hp + 10.0, "second injury uses actual entry delta")
	check(split.snapshot().campaign_ended, "actual second battle death ends life")
	denied(split, 1, "dead life")
	clone(split)
	# Real pristine/full-health play is never charged or penalized.
	var full := W.new(); denied(full, 1, "unwounded")
	check(full.march("river") and full.advance(3), "uninjured march")
	r = full.create_battle_ticket(); fight = full.start_battle(r.ticket.battle_id)
	check(full.commit_battle_outcome(Driver.play(fight, "fight")).ok and full.snapshot().commander.hp == 100.0, "uninjured actual victory")
	check(full.player_view().wounds.sources.is_empty(), "no invented injuries after clean fight")
	denied(full, 1, "uninjured settled")
	# Technical modes, immutable legacy tier and an actual second hostile engagement.
	for profile in ["early_v1", "late_v1", "legacy_test_v0"]:
		var helper := Setup.new(); var tech := helper.build("technical", profile)
		check(helper.failures.is_empty(), "technical survived " + profile + str(helper.failures))
		if not helper.failures.is_empty(): continue
		check(tech.rest_wounds(1).ok, "technical care " + profile)
		clone(tech)
		var old_hp: float = tech.snapshot().commander.hp
		check(tech.march("river"), "march starts")
		denied(tech, 1, "march care")
		check(tech.advance(3), "march ends hostile")
		denied(tech, 1, "hostile care")
		r = tech.create_battle_ticket()
		check(r.ok and r.ticket.reserved_roster_snapshot[0][0].hp == old_hp, "technical next injury snapshot")
		denied(tech, 1, "reserved care")
		clone(tech)
	# Finite near-full batching preflights only the time actually needed.
	var near := Setup.new().build("technical")
	check(near.rest_wounds(1).ok, "near-full first care")
	var needed := near._military_food_need(near.snapshot().armies.relief.soldiers)
	var two_hour_stock := 2 * needed
	check(near.transfer("relief", "pingling", "food", near.snapshot().armies.relief.food - two_hour_stock), "keep exactly two real ration-hours")
	var near_time: float = near.snapshot().time_seconds
	var near_result := near.rest_wounds(6)
	check(near_result.ok and near_result.elapsed == 7200.0 and near.snapshot().time_seconds == near_time + 7200.0 and near.snapshot().commander.hp == 100.0, "up-to-six stops at cap and charges only two hours")
	check(near.snapshot().armies.relief.food == 0 and near.player_view().wounds.rest_hours == 3.0, "paid only actual hours and truthful duration")
	clone(near)
	var hungry := Setup.new().build("technical")
	check(hungry.transfer("relief", "pingling", "food", hungry.snapshot().armies.relief.food) and hungry.advance(2), "real two-hour ration shortage")
	check(hungry.snapshot().armies.relief.condition.hunger == 2000, "real existing hunger")
	check(hungry.transfer("pingling", "relief", "food", 3 * hungry._military_food_need(hungry.snapshot().armies.relief.soldiers)), "restore actual stock")
	var hungry_hp: float = hungry.snapshot().commander.hp
	check(hungry.rest_wounds(1).ok and hungry.snapshot().commander.hp == hungry_hp, "first full meal clears only half hunger, no heal")
	check(hungry.rest_wounds(1).ok and hungry.snapshot().commander.hp == hungry_hp + 5.0, "next paid hour fully fed and heals")
	clone(hungry)
	# A real legacy World5 active save keeps its 360 HP profile/snapshot, then
	# settles via ordinary inputs and opts into convalescence without healing on load.
	var old_data := Store.new().decode_campaign(FileAccess.get_file_as_bytes("res://tests/fixtures/v06/running.save.json"))
	var legacy := W.new(); check(old_data.ok and legacy.restore_campaign_state(old_data.state).ok, "genuine World5 active load")
	var legacy_id: String = legacy.player_view().active_battle
	var legacy_ticket := legacy.battle_ticket(legacy_id)
	var lb := legacy.start_battle(legacy_id)
	lb.issue_order("attack")
	for frame in range(18000):
		if lb.ended: break
		if lb.player().hp < lb.player().max_hp:
			lb.issue_order("retreat"); lb.set_player_input(Vector2.LEFT, Vector2.RIGHT)
		else: lb.set_player_input(Vector2.RIGHT, Vector2.RIGHT)
		lb.step(BattleSimulation.FIXED_DELTA)
	check(lb.ended and lb.player().hp > 0.0 and lb.player().hp < 360.0 and legacy.commit_battle_outcome(lb.outcome()).ok, "genuine legacy active battle survives actual damage")
	check(legacy.march("river") and legacy.advance(3) and legacy.rest_wounds(1).ok, "genuine legacy new recovery roundtrip")
	check(legacy.snapshot().commander.max_hp == 360.0 and legacy.battle_ticket(legacy_id).reserved_roster_snapshot == legacy_ticket.reserved_roster_snapshot, "legacy reserved health and profile never rewritten")
	clone(legacy)
	# Eligibility guards tested in isolation, never claimed as authentic save histories.
	var blocked := clone(w)
	blocked._state.armies.relief.food = 0
	denied(blocked, 1, "no food")
	blocked = clone(w); blocked._state.cities.pingling.owner = "bei"
	denied(blocked, 1, "occupied home")
	blocked = clone(w); blocked._state.siege.city = "pingling"; blocked._state.siege.active = true
	denied(blocked, 1, "besieged friendly city")
	blocked = clone(w); blocked._state.commander.hp = 99.0
	blocked._rest_wound_hour()
	check(blocked.snapshot().commander.hp == 100.0, "isolated cap primitive never exceeds profile")
	denied(blocked, 1, "healed full")
	blocked = clone(w)
	blocked._state.armies.besiegers.location = ""
	blocked._state.armies.besiegers.march = {"route": "road", "destination": "pingling", "arrives_at": ceili((blocked.snapshot().time_seconds + 720.0) / 3600.0), "arrives_at_seconds": blocked.snapshot().time_seconds + 720.0}
	var before_interrupt: float = blocked.snapshot().commander.hp
	var previous_rest: float = blocked.player_view().wounds.rest_seconds
	blocked._rest_wound_hour()
	check(blocked.snapshot().commander.hp == before_interrupt and blocked.player_view().wounds.rest_seconds == previous_rest + 720.0, "isolated hostile arrival interrupts at actual 0.2h without healing")
	# Genuine pre-feature bytes remain exact. They can later request recovery.
	for fixture in ["world8-camp-before-appraisal.save.json", "v08/world7_youth_running.save.json", "v07/early_v1_running.save.json", "v06/running.save.json"]:
		var path: String = "res://tests/fixtures/" + fixture
		if not FileAccess.file_exists(path): continue
		var decoded := Store.new().decode_campaign(FileAccess.get_file_as_bytes(path))
		check(decoded.ok, "decode old fixture " + fixture)
		if decoded.ok:
			var old := W.new(); check(old.restore_campaign_state(decoded.state).ok, "restore old fixture " + fixture)
			if decoded.state.world.version == 8: check(old.export_campaign_state() == decoded.state, "World8 unchanged")
	# Every new event field has a closed typed shape; audit happens before replay.
	for index in range(after.world.events.size()):
		var e: Dictionary = after.world.events[index]
		if not e.kind.begins_with("wound_rest_"): continue
		for field in e.details:
			for invalid in [null, {}, [], false, "forged"]:
				var forged := after.duplicate(true); forged.world.events[index].details[field] = invalid
				reject(forged, "bad " + e.kind + "/" + field + "/" + str(invalid))
		for revision in [true, 1.0, 0, 2]:
			var forged := after.duplicate(true); forged.world.events[index].details.revision = revision
			reject(forged, "revision " + str(revision))
		var extra := after.duplicate(true); extra.world.events[index].details.extra = true; reject(extra, "extra field")
		var missing := after.duplicate(true); missing.world.events.remove_at(index); reject(missing, "missing event")
		var duplicate := after.duplicate(true); duplicate.world.events.insert(index, e.duplicate(true)); reject(duplicate, "duplicate event")
	# Coordinated rather than trivial stock/healing edits.
	var forged := after.duplicate(true)
	for e in forged.world.events:
		if e.kind == "wound_rest_completed": e.details.hp_after += 1.0; e.details.healed += 1.0
	forged.world.commander.hp += 1.0; reject(forged, "forged healing amount")
	forged = after.duplicate(true); forged.world.armies.relief.food += 1; forged.world.ledger.food_consumed -= 1; forged.world.ledger.food_consumed_military -= 1
	for index in range(forged.world.events.size() - 1, -1, -1):
		var e: Dictionary = forged.world.events[index]
		if e.kind == "consumption" and e.details.entity == "relief":
			e.details.eaten = 0; e.details.food_delta = 0; e.details.shortfall = e.details.requested
			forged.world.ledger.food_shortfall_military += 1
			break
	reject(forged, "coordinated free ration")
	for offset in [0.125, 3600.0, 86400.0, 864000.0]:
		forged = after.duplicate(true); forged.world.time_seconds += offset; forged.world.hour = floori(forged.world.time_seconds / 3600.0)
		reject(forged, "free time " + str(offset))
	forged = after.duplicate(true)
	for e in forged.world.events:
		if e.kind == "wound_rest_completed": e.time_seconds -= 0.001
	reject(forged, "subsecond free rest")
	var encoded := Store.new().encode_campaign(w)
	check(encoded.ok and Store.new().decode_campaign(encoded.bytes).ok, "disk codec after care")
	print(JSON.stringify({"suite": "wounds", "checks": checks, "failures": failures}))
	quit(0 if failures.is_empty() else 1)
