extends SceneTree
const W := preload("res://scripts/world_sim.gd")
const A := preload("res://scripts/camp_appraisal.gd")
const Driver := preload("res://tests/youth_combat_driver.gd")
var checks := 0
var failures: Array[String] = []
func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label); push_error(label)
func act(w: WorldSimulation, id: String) -> void:
	check(w.youth_action(id).ok, "action " + id)
func build(choice: String, reply: String = "") -> WorldSimulation:
	var w := W.new(184)
	check(w.start_youth("forced", "homeland").ok, "enlist")
	if reply != "": act(w, "arrange_courier")
	act(w, "first_march")
	if reply != "":
		act(w, "wait_courier")
		act(w, "courier_" + reply)
	var ticket: Dictionary = w.create_battle_ticket()
	check(ticket.ok, "battle reserved")
	var out := Driver.play(w.start_battle(ticket.ticket.battle_id))
	check(out.player_alive and out.result == "victory", "actual first victory")
	check(w.commit_battle_outcome(out).ok, "actual outcome committed")
	act(w, "return_to_camp")
	act(w, choice)
	act(w, "accept_appointment")
	check(w.youth_view().stage == "dangerous_orders", "at camp with real commission")
	return w
func roundtrip(w: WorldSimulation, label: String) -> void:
	var other := W.new(99)
	check(other.restore_campaign_state(w.export_campaign_state()).ok, label + " load")
	check(other.export_campaign_state() == w.export_campaign_state(), label + " exact state")
func reject(s: Dictionary, label: String) -> void:
	var other := W.new(99)
	var before := other.export_campaign_state()
	check(not other.restore_campaign_state(s).ok, label + " rejects")
	check(before == other.export_campaign_state(), label + " atomic")
func run() -> void:
	for scenario in [["appeal", "", "support"], ["keep_evidence", "", "bargain"], ["keep_evidence", "comply", "support"], ["appeal", "refuse", "denied"]]:
		var w := build(scenario[0], scenario[1])
		var before := w.snapshot()
		act(w, "camp_appraisal")
		var quoted: Dictionary = w.youth_view().appraisal
		check(quoted.outcome == scenario[2], "causal offer " + str(scenario))
		check(w.snapshot().time_seconds == before.time_seconds + 3600.0, "appraisal real elapsed hour")
		check(quoted.battles == before.youth.characters.officer_qiao.known_battles, "only reported known battles")
		check(quoted.receipts == A.returned(before.couriers), "only physically returned receipts")
		check(w.snapshot().youth.evidence == before.youth.evidence, "private evidence not disclosed")
		roundtrip(w, "quoted " + scenario[2])
		var quoted_state := w.export_campaign_state()
		check(not w.youth_action("camp_appraisal").ok and w.export_campaign_state() == quoted_state, "request once atomic")
		for key in quoted:
			var forged := quoted_state.duplicate(true)
			for e in forged.world.events:
				if e.kind == "youth_transition" and e.details.action == "camp_appraisal": e.details.data[key] = null
			for e in forged.world.youth.timeline:
				if e.action == "camp_appraisal": e.details[key] = null
			reject(forged, "corrupt quote " + key)
		if quoted.outcome == "denied":
			check(not w.youth_action("appraisal_accept").ok, "denial no grant")
			act(w, "refuse_order")
			continue
		var declined := W.new()
		check(declined.restore_campaign_state(quoted_state).ok, "clone declined choice")
		var credit: Dictionary = declined.snapshot().youth
		var army: Dictionary = declined.snapshot().armies.relief
		act(declined, "appraisal_decline")
		check(declined.snapshot().youth.recorded_merit == credit.recorded_merit and declined.snapshot().youth.standing == credit.standing and declined.snapshot().armies.relief == army, "decline preserves merit standing supplies")
		roundtrip(declined, "declined")
		act(declined, "refuse_order")
		check(declined.snapshot().youth.endpoint.reason == "order_refused", "old refusal path retained")
		before = w.snapshot()
		act(w, "appraisal_accept")
		var after := w.snapshot()
		check(after.time_seconds == before.time_seconds, "accept menu zero time")
		check(after.armies.relief.food == before.armies.relief.food + quoted.food and after.cities.pingling.food == before.cities.pingling.food - quoted.food, "exact real stock transfer")
		check(after.youth.earned_merit == before.youth.earned_merit and after.youth.recorded_merit + after.youth.appropriated_merit == before.youth.recorded_merit + before.youth.appropriated_merit, "actual and credited merit conservation")
		check(after.youth.recorded_merit == before.youth.recorded_merit - (1 if quoted.outcome == "bargain" else 0), "bargain real merit consequence")
		check(after.youth.characters.officer_qiao.reported_merit == before.youth.characters.officer_qiao.reported_merit + (1 if quoted.outcome == "bargain" else 0), "officer credit matches")
		check(after.youth.standing == before.youth.standing + 1, "real standing")
		var settled := w.export_campaign_state()
		check(not w.youth_action("appraisal_accept").ok and not w.youth_action("appraisal_decline").ok and settled == w.export_campaign_state(), "no double grant or changed decision")
		roundtrip(w, "settled")
		var forged := settled.duplicate(true)
		forged.world.events.append(forged.world.events[-1].duplicate(true))
		reject(forged, "replayed acceptance")
		act(w, "dangerous_march")
		check(not w.youth_action("appraisal_accept").ok, "no remote stale acceptance")
		roundtrip(w, "old march path")
	# Unit boundary: unread, lost or returning courier records never enter the decision.
	var w := build("keep_evidence")
	var y: Dictionary = w.snapshot().youth
	for status in ["queued", "outbound", "awaiting_reply", "returning", "lost"]:
		check(A.returned([{"id": 1, "status": status, "reply": "refuse"}]).is_empty(), "hidden receipt filtered: " + status)
		check(A.evaluate(y, A.returned([{"id": 1, "status": status, "reply": "refuse"}]), 100).outcome == "bargain", "hidden fate no NPC influence: " + status)
	check(A.evaluate(y, [{"id": 1, "reply": "no_response"}], 100).outcome == "bargain", "silence not refusal")
	check(A.evaluate(y, [], 3).reason == "insufficient_stock", "bounded stock denial")
	check(A.evaluate(y, [], 4).outcome == "bargain", "exact minimum stock")
	var old := w.export_campaign_state()
	check(old.world.version == 8 and old.world.origin == "new_world7", "unchanged world identity")
	roundtrip(w, "untouched prior trajectory")
	# Evidence forgery rejected even when quote and timeline are edited together.
	var evidence_world := build("keep_evidence", "comply")
	act(evidence_world, "camp_appraisal")
	var evidence_state := evidence_world.export_campaign_state()
	for field in ["receipts", "battles"]:
		var replacements: Array = [[{"id": 1.0, "reply": "comply"}], [{"id": 1, "reply": true}], [{"id": 2, "reply": "comply"}], [{"id": 1, "reply": "refuse"}]] if field == "receipts" else [["invented:99"], [1]]
		for value in replacements:
			var forged := evidence_state.duplicate(true)
			for e in forged.world.events:
				if e.kind == "youth_transition" and e.details.action == "camp_appraisal": e.details.data[field] = value
			for e in forged.world.youth.timeline:
				if e.action == "camp_appraisal": e.details[field] = value
			reject(forged, "forged " + field + str(value))
	for event in [{"kind": "march_started", "details": {}}, {"kind": "city_captured", "details": {"city": "pingling", "owner": "bei"}}]:
		var forged := evidence_state.duplicate(true)
		var inserted: Dictionary = event.duplicate(true)
		inserted["time_seconds"] = forged.world.time_seconds
		inserted["hour"] = forged.world.hour
		forged.world.events.insert(forged.world.events.size() - 1, inserted)
		check(not preload("res://scripts/youth_career.gd").validate(forged.world), "independent appraisal replay rejects " + event.kind)
		reject(forged, "off-camp/owner forgery " + event.kind)
	var private_y: Dictionary = y.duplicate(true)
	private_y.evidence = [{"kind": "private_roster_copy", "battle_id": "hidden", "witness": "private", "disclosed_to": []}]
	check(A.evaluate(y, [], 100) == A.evaluate(private_y, [], 100), "undisclosed private proof does not influence NPC")
	for replacement in [{"outcome": "denied", "reason": "insufficient_stock", "food": 0}, {"outcome": "bargain", "reason": "credit_for_rations", "food": 4}]:
		var forged := evidence_state.duplicate(true)
		for e in forged.world.events:
			if e.kind == "youth_transition" and e.details.action == "camp_appraisal":
				for field in replacement: e.details.data[field] = replacement[field]
		for e in forged.world.youth.timeline:
			if e.action == "camp_appraisal":
				for field in replacement: e.details[field] = replacement[field]
		reject(forged, "coordinated false quote/stock outcome " + replacement.outcome)
	# Second physical dispatch remains legal after either quote/decision, with no repeated stock reward.
	for decision in ["", "appraisal_accept", "appraisal_decline"]:
		var dispatch_world := W.new()
		check(dispatch_world.restore_campaign_state(evidence_state).ok, "dispatch branch from actual first receipt")
		if decision != "": act(dispatch_world, decision)
		act(dispatch_world, "arrange_courier")
		check(dispatch_world.snapshot().couriers.size() == 2 and dispatch_world.snapshot().couriers[1].stage == "dangerous_orders", "second courier after appraisal " + decision)
		roundtrip(dispatch_world, "second dispatch " + decision)
	# Real hourly starvation interrupts appraisal before knowledge/stock/standing effects.
	var dying := build("keep_evidence")
	act(dying, "arrange_courier")
	for hour in range(80):
		if dying.snapshot().armies.relief.soldiers == 1: break
		act(dying, "wait_courier")
	check(dying.snapshot().armies.relief.soldiers == 1 and dying.snapshot().commander.alive, "real starvation leaves commander last")
	var pre_death := dying.snapshot()
	act(dying, "camp_appraisal")
	check(dying.snapshot().campaign_ended and not dying.snapshot().commander.alive, "death during appraisal hour")
	check(A.offer(dying.snapshot().youth).is_empty() and dying.snapshot().youth.standing == pre_death.youth.standing and dying.snapshot().youth.reward_food == pre_death.youth.reward_food, "interrupted appraisal no knowledge standing or reward")
	check(dying.snapshot().time_seconds > pre_death.time_seconds, "elapsed time retained on death")
	roundtrip(dying, "death during appraisal")
	var dead := dying.export_campaign_state()
	check(not dying.youth_action("appraisal_accept").ok and dying.export_campaign_state() == dead, "dead cannot accept")
	# Defensive stale-view boundary only, not a valid playable/save fixture.
	var stale := build("keep_evidence")
	act(stale, "camp_appraisal")
	stale._state.cities.pingling.food = 0
	var unavailable := stale.export_campaign_state()
	check(not stale.youth_action("appraisal_accept").ok and stale.export_campaign_state() == unavailable, "current stock rechecked before stale acceptance")
	stale._state.armies.relief.location = "hequ"
	unavailable = stale.export_campaign_state()
	check(not stale.youth_action("appraisal_accept").ok and not stale.youth_action("appraisal_decline").ok and stale.export_campaign_state() == unavailable, "current location rechecked without writes")
	# Scalar type equality must not allow integer/float substitutes in new event contracts.
	var typed := w.export_campaign_state()
	act(w, "camp_appraisal")
	typed = w.export_campaign_state()
	for replacement in [1.0, true, "1", 2]:
		var forged := typed.duplicate(true)
		for e in forged.world.events:
			if e.kind == "youth_transition" and e.details.action == "camp_appraisal": e.details.data.revision = replacement
		for e in forged.world.youth.timeline:
			if e.action == "camp_appraisal": e.details.revision = replacement
		reject(forged, "invalid contract revision " + str(replacement))
	# Frozen bytes made by unmodified 78c7853, not by this new reader.
	var decoded := preload("res://scripts/campaign_store.gd").new().decode_campaign(FileAccess.get_file_as_bytes("res://tests/fixtures/world8-camp-before-appraisal.save.json"))
	check(decoded.ok, "genuine World8 fixture decodes")
	var legacy := W.new(99)
	check(legacy.restore_campaign_state(decoded.state).ok, "genuine World8 restores")
	check(legacy.export_campaign_state() == decoded.state, "old world exact field/value/identity equality without migration")
	act(legacy, "camp_appraisal")
	check(legacy.youth_view().appraisal.outcome == "support", "old physically returned receipt usable without invented history")
	roundtrip(legacy, "legacy extended by optional new action")
	print("CAMP_APPRAISAL_SUMMARY " + JSON.stringify({"checks": checks, "failures": failures}))
	quit(0 if failures.is_empty() else 1)
