extends SceneTree
const W := preload("res://scripts/world_sim.gd")
const P := preload("res://scripts/comrade_petition.gd")
const Driver := preload("res://tests/youth_combat_driver.gd")
const Store := preload("res://scripts/campaign_store.gd")
var checks := 0
var failures: Array[String] = []
func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label); push_error(label)
func act(w: WorldSimulation, id: String) -> void:
	check(w.youth_action(id).ok, "action " + id)
func build(choice: String, policy: String = "fight", seed_value: int = 184, motivation: String = "homeland") -> WorldSimulation:
	var w := W.new(seed_value)
	check(w.start_youth("forced", motivation).ok, "enlist")
	act(w, "first_march")
	var ticket := w.create_battle_ticket()
	check(ticket.ok, "actual battle ticket")
	var out := Driver.play(w.start_battle(ticket.ticket.battle_id), policy)
	check(out.player_alive, "actual battle survivor " + policy)
	check(w.commit_battle_outcome(out).ok, "actual battle committed")
	for action in ["return_to_camp", choice, "accept_appointment"]: act(w, action)
	return w
func roundtrip(w: WorldSimulation, label: String) -> void:
	var encoded := Store.new().encode_campaign(w)
	check(encoded.ok, label + " encoded")
	if not encoded.ok: return
	var decoded := Store.new().decode_campaign(encoded.bytes)
	check(decoded.ok, label + " decoded")
	if not decoded.ok: return
	var target := W.new(99)
	check(target.restore_campaign_state(decoded.state).ok, label + " restored")
	check(target.export_campaign_state() == w.export_campaign_state(), label + " exact events resources RNG state")
func reject(s: Dictionary, label: String) -> void:
	var target := W.new(99)
	var before := target.export_campaign_state()
	check(not target.restore_campaign_state(s).ok, label + " rejects")
	check(before == target.export_campaign_state(), label + " atomic")
func replace_record(s: Dictionary, data: Dictionary) -> void:
	for e in s.world.events:
		if e.kind == "youth_transition" and e.details.action == "comrade_petition": e.details.data = data.duplicate(true)
	for e in s.world.youth.timeline:
		if e.action == "comrade_petition": e.details = data.duplicate(true)
func run() -> void:
	for choice in ["keep_evidence", "endure", "protect_comrade", "appeal"]:
		var w := build(choice, "fight", 184, "survival" if choice == "endure" else "homeland")
		var before := w.snapshot()
		if not P.available(before.youth):
			check(before.youth.appropriated_merit == 0, "fully restored first appeal cannot reroll")
			continue
		var expected := P.evaluate(before.youth)
		var control := W.new()
		check(control.restore_campaign_state(w.export_campaign_state()).ok, "real elapsed-hour control")
		act(control, "camp_appraisal")
		act(w, "comrade_petition")
		var after := w.snapshot()
		var record := P.record(after.youth)
		check(record == expected, "causal deterministic decisions " + choice)
		check(after.time_seconds == before.time_seconds + 3600.0, "one actual hour")
		check(after.armies == control.snapshot().armies and after.cities == control.snapshot().cities, "petition grants no supplies troops or resources")
		check(after.youth.recorded_merit == before.youth.recorded_merit + record.restored and after.youth.appropriated_merit == before.youth.appropriated_merit - record.restored, "remaining merit conserved")
		check(after.youth.earned_merit == before.youth.earned_merit and after.youth.characters.officer_qiao.reported_merit == before.youth.characters.officer_qiao.reported_merit - record.restored, "actual battle credit unchanged officer claim reduced")
		if choice == "keep_evidence" or choice == "protect_comrade": check(record.restored > 0, "positive own decision " + choice)
		if choice == "endure": check(record.restored == 0, "fear permits genuine refusal")
		for decision in record.decisions:
			var person: Dictionary = before.youth.characters[decision.id]
			check(decision.id in P.PEOPLE and person.alive and record.battle_id in person.known_battles, "only living original direct witnesses")
			check(after.youth.characters[decision.id].trust == person.trust + (1 if decision.sign else 0) and after.youth.characters[decision.id].respect == person.respect + (1 if decision.sign else 0), "signer relationship consequence; refusal unpunished")
			if choice == "keep_evidence" and decision.id == "recruit_lin": check(decision.sign and decision.reason == "kept_our_record", "actual private-copy witness Lin knows retained record")
			if choice == "keep_evidence" and decision.id == "recruit_zhou": check(not decision.sign and decision.reason != "kept_our_record", "Zhou cannot know another witness private copy")
			if choice == "appeal" and decision.id == before.youth.evidence[0].witness: check(not decision.sign and decision.reason == "already_testified", "prior appeal witness never counted twice")
			if decision.id == before.youth.protected_id: check(decision.sign and decision.reason == "protected_me", "protected camp survivor retains agency")
		var stable := w.export_campaign_state()
		check(not w.youth_action("comrade_petition").ok and stable == w.export_campaign_state(), "no repeat roll atomic")
		roundtrip(w, choice)
		# Pure malformed-save boundary tests. Never used as gameplay evidence.
		for key in record:
			var forged := stable.duplicate(true)
			var malformed := record.duplicate(true)
			malformed[key] = null
			replace_record(forged, malformed)
			reject(forged, "null record " + key)
		for value in [1.0, true, "1", 2]:
			var forged := stable.duplicate(true)
			var malformed := record.duplicate(true)
			malformed.revision = value
			replace_record(forged, malformed)
			reject(forged, "typed revision " + str(value))
		if not record.decisions.is_empty():
			for field in ["sign", "reason", "trust", "respect", "grievance", "id"]:
				var forged := stable.duplicate(true)
				var malformed := record.duplicate(true)
				malformed.decisions[0][field] = "invented" if field in ["reason", "id"] else not malformed.decisions[0][field] if field == "sign" else 999
				replace_record(forged, malformed)
				reject(forged, "coordinated false decision " + field)
		for malformed in [record.merged({"extra": true}), record.merged({"restored": float(record.restored)}, true)]:
			var forged := stable.duplicate(true)
			replace_record(forged, malformed)
			reject(forged, "extra field or float merit contract")
		if not record.decisions.is_empty():
			var malformed := record.duplicate(true)
			malformed.decisions[0].trust = float(malformed.decisions[0].trust)
			var forged := stable.duplicate(true)
			replace_record(forged, malformed)
			reject(forged, "float relationship contract")
		var replayed := stable.duplicate(true)
		replayed.world.events.append(replayed.world.events[-1].duplicate(true))
		reject(replayed, "duplicate petition event")
		act(w, "camp_appraisal")
		roundtrip(w, "petition followed by appraisal")
		act(w, "refuse_order")
		check(w.snapshot().youth.endpoint.reason == "order_refused", "original refusal remains playable")
	var quoted := build("keep_evidence")
	act(quoted, "camp_appraisal")
	var stable := quoted.export_campaign_state()
	check(not quoted.youth_action("comrade_petition").ok and stable == quoted.export_campaign_state(), "appraisal closes petition before any bargain")
	act(quoted, "appraisal_accept")
	stable = quoted.export_campaign_state()
	check(not quoted.youth_action("comrade_petition").ok and stable == quoted.export_campaign_state(), "cannot recover voluntarily traded merit")
	# Genuine tactical losses from public controls, independent of starvation fixtures.
	var tactical := build("keep_evidence", "reckless", 185)
	check(not tactical.snapshot().youth.characters.recruit_lin.alive, "real seed185 reckless battle kills Lin")
	var tactical_control := W.new()
	check(tactical_control.restore_campaign_state(tactical.export_campaign_state()).ok, "clone tactical casualty camp")
	act(tactical_control, "camp_appraisal")
	var tactical_expected := P.evaluate(tactical_control.snapshot().youth)
	act(tactical, "comrade_petition")
	var tactical_record := P.record(tactical.snapshot().youth)
	check(tactical_record == tactical_expected, "tactical casualty decisions exact after actual hour")
	for d in tactical_record.decisions:
		check(d.id != "recruit_lin", "dead tactical witness Lin cannot sign")
		if d.id == "recruit_zhou": check(d.sign and d.reason == "kept_our_record", "surviving actual private-copy witness Zhou can sign")
	roundtrip(tactical, "real tactical casualty petition")
	# Actual waiting consumes real food and kills named comrades; no state injection.
	var casualty := build("keep_evidence")
	act(casualty, "arrange_courier")
	for hour in range(80):
		if not casualty.snapshot().youth.characters.recruit_lin.alive: break
		act(casualty, "wait_courier")
	var dead_count := 0
	for id in P.PEOPLE:
		if not casualty.snapshot().youth.characters[id].alive: dead_count += 1
	check(dead_count > 0, "real hourly casualty fixture")
	var casualty_control := W.new()
	check(casualty_control.restore_campaign_state(casualty.export_campaign_state()).ok, "clone actual casualty camp before elapsed hour")
	act(casualty_control, "camp_appraisal")
	var expected_after_hour := P.evaluate(casualty_control.snapshot().youth)
	act(casualty, "comrade_petition")
	check(P.record(casualty.snapshot().youth) == expected_after_hour, "casualty petition uses authoritative post-hour living actor set")
	for d in P.record(casualty.snapshot().youth).decisions: check(casualty.snapshot().youth.characters[d.id].alive, "dead original witness excluded")
	roundtrip(casualty, "actual casualty petition")
	# Unit-only presence/knowledge/grievance boundaries, explicitly not playable saves.
	var sample: Dictionary = build("keep_evidence").snapshot().youth
	# Wu and Tian cannot read the player's private choice. Equal local relations
	# and shared experience yield the same decisions despite different responses.
	var homeland_endure: Dictionary = build("endure").snapshot().youth
	var record_decisions: Array = P.evaluate(sample).decisions
	var endure_decisions: Array = P.evaluate(homeland_endure).decisions
	for id in ["recruit_wu", "recruit_tian"]:
		var kept := {}
		var endured := {}
		for d in record_decisions:
			if d.id == id: kept = d
		for d in endure_decisions:
			if d.id == id: endured = d
		check(not kept.is_empty() and kept == endured, "local decision invariant across private response for " + id)
	var unrelated_hidden := sample.duplicate(true)
	for evidence in unrelated_hidden.evidence:
		if evidence.kind == "private_roster_copy": evidence.battle_id = "other_hidden_battle"
	var original_zhou := {}
	var hidden_zhou := {}
	for d in P.evaluate(sample).decisions:
		if d.id == "recruit_zhou": original_zhou = d
	for d in P.evaluate(unrelated_hidden).decisions:
		if d.id == "recruit_zhou": hidden_zhou = d
	check(not original_zhou.is_empty() and original_zhou == hidden_zhou, "unrelated person's hidden-copy mutation cannot affect Zhou decision")
	for id in P.PEOPLE:
		var absent := sample.duplicate(true)
		absent.roster.erase(id); absent.characters[id].location = "hequ"
		for d in P.evaluate(absent).decisions: check(d.id != id, "absent witness filtered")
		absent = sample.duplicate(true); absent.characters[id].known_battles = []
		for d in P.evaluate(absent).decisions: check(d.id != id, "unwitnessed battle filtered")
		absent = sample.duplicate(true); absent.characters[id].grievance = 99
		for d in P.evaluate(absent).decisions:
			if d.id == id: check(not d.sign and d.reason == "losses_before_credit", "losses can outweigh trust")
	var protected_sample: Dictionary = build("protect_comrade").snapshot().youth
	var protected_id: String = protected_sample.protected_id
	protected_sample.characters[protected_id].grievance = 99
	var protected_refused := false
	for d in P.evaluate(protected_sample).decisions:
		if d.id == protected_id: protected_refused = not d.sign and d.reason == "losses_before_credit"
	check(protected_refused, "protected survivor may decline when losses outweigh gratitude")
	# Real hourly starvation may end a life before any petition consequence.
	var dying := build("keep_evidence")
	act(dying, "arrange_courier")
	for hour in range(80):
		if dying.snapshot().armies.relief.soldiers == 1: break
		act(dying, "wait_courier")
	check(dying.snapshot().armies.relief.soldiers == 1 and dying.snapshot().commander.alive, "real starvation last survivor")
	var before_death := dying.snapshot()
	act(dying, "comrade_petition")
	check(dying.snapshot().campaign_ended and P.record(dying.snapshot().youth).is_empty(), "hourly death prevents testimony")
	check(dying.snapshot().youth.evidence == before_death.youth.evidence and dying.snapshot().youth.recorded_merit == before_death.youth.recorded_merit, "death no evidence or merit award")
	roundtrip(dying, "petition interrupted by death")
	var decoded := Store.new().decode_campaign(FileAccess.get_file_as_bytes("res://tests/fixtures/world8-camp-before-appraisal.save.json"))
	check(decoded.ok, "old frozen fixture decodes")
	var legacy := W.new(99)
	check(legacy.restore_campaign_state(decoded.state).ok and legacy.export_campaign_state() == decoded.state, "old fixture unchanged exactly")
	act(legacy, "comrade_petition")
	roundtrip(legacy, "old fixture optional petition")
	print("COMRADE_PETITION_SUMMARY " + JSON.stringify({"checks": checks, "failures": failures}))
	quit(0 if failures.is_empty() else 1)
