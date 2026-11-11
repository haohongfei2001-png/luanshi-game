extends SceneTree
const W := preload("res://scripts/world_sim.gd")
const H := preload("res://scripts/hometown_messages.gd")
const Setup := preload("res://scripts/hometown_persistence_smoke.gd")
const Store := preload("res://scripts/campaign_store.gd")
var checks := 0
var failures: Array[String] = []
var setup := Setup.new()
func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label); push_error(label)
func act(w: WorldSimulation, id: String) -> void:
	var result := w.youth_action(id)
	check(result.ok, "action " + id + (" " + str(result) if not result.ok else ""))
func roundtrip(w: WorldSimulation, label: String) -> void:
	var encoded := Store.new().encode_campaign(w)
	check(encoded.ok, label + " encoded")
	if not encoded.ok: return
	var decoded := Store.new().decode_campaign(encoded.bytes)
	check(decoded.ok, label + " decoded")
	if not decoded.ok: return
	var clone := W.new(42)
	check(clone.restore_campaign_state(decoded.state).ok and clone.export_campaign_state() == w.export_campaign_state(), label + " exact")
func reject(s: Dictionary, label: String) -> void:
	var target := W.new(99)
	var before := target.export_campaign_state()
	check(not target.restore_campaign_state(s).ok, label + " rejects")
	check(target.export_campaign_state() == before, label + " atomic")
func run() -> void:
	var w := setup.build()
	var initial := w.snapshot()
	var without_letter := W.new(184)
	check(without_letter.start_youth("forced", "homeland").ok, "resource baseline")
	check(initial.cities.pingling.soldiers == without_letter.snapshot().cities.pingling.soldiers - 1 and initial.cities.pingling.food == without_letter.snapshot().cities.pingling.food - 10, "one existing soldier ten existing rations, no extra letter cost")
	check(w.totals() == initial.initial_totals, "dispatch conserves existing totals")
	check(H.truth(initial).activity == "workshop", "ordinary existing civilian starts at actual work shift")
	check(w.player_view().hometown.message.is_empty(), "attachment exposes no remote letter")
	var unchanged := w.export_campaign_state()
	check(not w.youth_action("attach_hometown_letter").ok and unchanged == w.export_campaign_state(), "repeated click atomic")
	roundtrip(w, "queued")
	act(w, "first_march")
	check(H.record(w.snapshot()).letter.observed_at == 3600.0, "letter frozen at actual departure")
	check(w.player_view().hometown.message.is_empty(), "letter hidden until physical arrival")
	roundtrip(w, "outbound")
	act(w, "wait_courier")
	var received: Dictionary = w.player_view().hometown.message.duplicate(true)
	check(received.activity == "workshop" and received.observed_at == 3600.0 and w.player_view().hometown.received_at == 14400.0, "old facts delivered after three-hour route")
	check(H.truth(w.snapshot()).activity == "caregiving", "offscreen shift changes before player learns")
	var view: Dictionary = w.player_view().hometown
	check(not view.has("truth") and not view.has("letter") and view.message != H.truth(w.snapshot()), "projection has only received facts")
	check(not w.youth_action("visit_hometown").ok, "remote visit denied")
	act(w, "courier_comply")
	check(setup.fight_return(w), "real battle and return")
	check(not H.can_visit(w.snapshot()), "first resolve the original four injustice choices")
	act(w, "keep_evidence")
	var previsit := w.export_campaign_state()
	var control := W.new()
	check(control.restore_campaign_state(previsit).ok, "visit clock control")
	act(control, "wait_courier")
	act(w, "visit_hometown")
	check(w.snapshot().cities == control.snapshot().cities and w.snapshot().armies == control.snapshot().armies, "visit grants no resources; consumes real hour")
	check(w.player_view().hometown.visit.outcome == "met", "workshop permits actual reunion")
	check(w.player_view().hometown.message == received, "later reunion cannot rewrite old letter")
	unchanged = w.export_campaign_state()
	check(not w.youth_action("visit_hometown").ok and unchanged == w.export_campaign_state(), "no repeated reunion farming")
	roundtrip(w, "reunion")
	act(w, "accept_appointment"); act(w, "comrade_petition")
	act(w, "refuse_order")
	unchanged = w.export_campaign_state()
	check(not w.youth_action("visit_hometown").ok and not w.youth_action("attach_hometown_letter").ok and unchanged == w.export_campaign_state(), "endpoint blocks new hometown actions")
	roundtrip(w, "original endpoint and all old actions")
	var lost := setup.build()
	for i in range(7): act(lost, "wait_courier")
	check(lost.snapshot().couriers[0].status == "lost", "actual enemy garrison intercepts")
	check(lost.player_view().hometown.overdue and lost.player_view().hometown.message.is_empty(), "cannot know secret carrier loss")
	check(not H.describe(lost.player_view().hometown).contains("击杀"), "no omniscient loss text")
	roundtrip(lost, "unknown loss")
	var stale := lost.export_campaign_state()
	for e in stale.world.events:
		if e.kind == "hometown_letter": e.details.message.activity = "caregiving"
	reject(stale, "invented past letter")
	var arrived := W.new()
	check(arrived.restore_campaign_state(previsit).ok, "clone letter history")
	for index in range(unchanged.world.events.size()):
		var original: Dictionary = unchanged.world.events[index]
		if not original.kind.begins_with("hometown_"): continue
		for field in original.details:
			var forged := unchanged.duplicate(true)
			forged.world.events[index].details[field] = null
			reject(forged, "null " + original.kind + "/" + field)
		var duplicate := unchanged.duplicate(true)
		duplicate.world.events.insert(index, original.duplicate(true))
		reject(duplicate, "duplicate " + original.kind)
		var removed := unchanged.duplicate(true)
		removed.world.events.remove_at(index)
		reject(removed, "missing " + original.kind)
		var extra := unchanged.duplicate(true)
		extra.world.events[index].details.extra = true
		reject(extra, "extra " + original.kind)
		for value in [1.0, true, 2]:
			var forged := unchanged.duplicate(true)
			forged.world.events[index].details.revision = value
			reject(forged, "bad revision " + original.kind)
		if original.kind == "hometown_letter":
			for field in original.details.message:
				var forged := unchanged.duplicate(true)
				forged.world.events[index].details.message[field] = null
				reject(forged, "null letter fact " + field)
			for field in ["person_id", "activity", "basis", "location"]:
				var forged := unchanged.duplicate(true)
				forged.world.events[index].details.message[field] = "invented"
				reject(forged, "false fact " + field)
	# Real pre-feature World8 bytes are unchanged, then may opt into a visit.
	var old := Store.new().decode_campaign(FileAccess.get_file_as_bytes("res://tests/fixtures/world8-camp-before-appraisal.save.json"))
	check(old.ok, "genuine old World8 decoded")
	var legacy := W.new()
	check(legacy.restore_campaign_state(old.state).ok, "genuine old World8 restored")
	check(legacy.export_campaign_state() == old.state, "old fields and events preserved exactly")
	act(legacy, "visit_hometown")
	roundtrip(legacy, "old save opts into visit")
	# Exercise refusing to meet because of independent family duty via actual waiting.
	var busy := W.new()
	check(busy.restore_campaign_state(previsit).ok, "busy setup")
	while busy.snapshot().armies.relief.soldiers > 1: act(busy, "wait_courier")
	act(busy, "visit_hometown")
	check(busy.player_view().hometown.visit.outcome == "interrupted" and busy.player_view().hometown.visit.observation.is_empty() and busy.snapshot().campaign_ended, "actual starvation interrupts visit without new knowledge")
	roundtrip(busy, "interrupted visit")
	var postmortem := busy.export_campaign_state()
	for e in postmortem.world.events:
		if e.kind == "hometown_visit": e.time_seconds += 0.5
	postmortem.world.time_seconds += 0.5
	reject(postmortem, "visit knowledge cannot occur after death boundary")
	var family := W.new()
	check(family.restore_campaign_state(previsit).ok, "family duty setup")
	act(family, "accept_appointment")
	act(family, "comrade_petition")
	act(family, "camp_appraisal")
	while family.snapshot().time_seconds < 16.0 * 3600.0: act(family, "wait_courier")
	act(family, "visit_hometown")
	check(family.player_view().hometown.visit.outcome == "left_notice" and family.player_view().hometown.visit.observation.activity == "caregiving", "independent family duty changes meeting outcome")
	# A carrier's camp-return branch is currently unreachable through the bounded youth
	# routes with a living hostile Hequ garrison. This is a unit transport-hook check,
	# not a claimed playable campaign or accepted save.
	var camp := setup.build()
	act(camp, "wait_courier")
	var returned := camp.snapshot()
	returned.time_seconds = 25200.0; returned.hour = 7
	returned.couriers[0].status = "returned"
	returned.couriers[0].known = "camp_confirmed"
	returned.couriers[0].known_at = returned.time_seconds
	H.tick(returned)
	check(H.view(returned).received_at == 25200.0 and H.view(returned).message.observed_at == 3600.0, "unit camp observer receives frozen original")
	var count: int = returned.events.size()
	H.tick(returned)
	check(returned.events.size() == count, "unit repeated camp observer cannot duplicate receipt")
	var absent := camp.snapshot()
	absent.time_seconds = 25200.0; absent.hour = 7
	absent.armies.relief.location = "hequ"
	absent.couriers[0].status = "returned"
	H.tick(absent)
	check(H.view(absent).message.is_empty(), "unit returned carrier alone cannot inform distant player")
	# Pure model boundary checks: resource knowledge comes from actual local ration events,
	# not privileged warehouse contents; no synthetic test is claimed as a played campaign.
	var a := initial.duplicate(true)
	a.cities.pingling.food = 0
	check(H.truth(a).activity == "workshop", "resident cannot read hidden warehouse stocks")
	a.events.append({"kind": "consumption", "time_seconds": 86400.0, "details": {"entity": "pingling", "consumer": "civilian", "shortfall": 1}})
	a.time_seconds = 86400.0
	check(H.truth(a).activity == "ration_queue", "known local civilian shortfall changes priorities")
	a.events.append({"kind": "city_captured", "time_seconds": 90000.0, "details": {"city": "pingling", "owner": "bei"}})
	a.time_seconds = 90000.0
	check(H.truth(a).activity == "sheltering", "local visible takeover changes plans")
	# Identical elapsed world time split at arbitrary fractional boundaries, private clock
	# used solely for a low-level determinism property, not as a legal gameplay route.
	var whole := setup.build(); var split := setup.build()
	whole._advance_clock_to(14400.0)
	for at in [0.125, 3599.5, 3600.0, 7777.25, 14400.0]: split._advance_clock_to(at)
	check(whole.snapshot() == split.snapshot(), "fractional split time identical including letter and hidden interception")
	# The clock proof cannot be disabled by saved metadata, and it works with active
	# battles, fractional synchronization, distinct generations and explicit reports.
	var running := setup.build()
	act(running, "first_march")
	var live_ticket := running.create_battle_ticket()
	check(live_ticket.ok, "reserve with hometown transit")
	roundtrip(running, "reserved ticket with transit")
	var live := running.start_battle(live_ticket.ticket.battle_id)
	live.step(1.0 / 30.0)
	check(running.sync_battle_time(live_ticket.ticket.battle_id), "fractional battle sync")
	roundtrip(running, "active battle fractional clock")
	check(running.observe_city("hequ", 1), "ordinary local observation remains supported")
	roundtrip(running, "active battle with local report")
	for future_hours in [24, 240]:
		var sparse := running.export_campaign_state()
		sparse.world.time_seconds += future_hours * 3600.0
		sparse.world.hour = floori(sparse.world.time_seconds / 3600.0)
		sparse.world.battle_tickets[live_ticket.ticket.battle_id].elapsed_world_time = sparse.world.time_seconds - sparse.world.battle_tickets[live_ticket.ticket.battle_id].time
		var rejection_started := Time.get_ticks_msec()
		reject(sparse, "sparse future " + str(future_hours))
		check(Time.get_ticks_msec() - rejection_started < 5000, "reject sparse future at first missing hour")
	var generation := W.new(184)
	check(generation.reset(184), "second generation")
	check(generation.start_youth("forced", "homeland").ok, "second generation enlist")
	act(generation, "arrange_courier"); act(generation, "attach_hometown_letter")
	act(generation, "first_march")
	check(setup.fight_return(generation), "second generation identities")
	act(generation, "keep_evidence"); act(generation, "visit_hometown")
	roundtrip(generation, "second generation replay")
	# Independent review regression: a legal old world at hour 20 cannot claim
	# a visit by just advancing saved time while deleting every real hourly event.
	var free_hour := W.new()
	check(free_hour.restore_campaign_state(old.state).ok, "free hour fixture")
	for i in range(9): act(free_hour, "wait_courier")
	var forged_hour := free_hour.export_campaign_state()
	var started: float = forged_hour.world.time_seconds
	forged_hour.world.time_seconds += 3600.0
	forged_hour.world.hour = floori(forged_hour.world.time_seconds / 3600.0)
	H.finish_visit(forged_hour.world, started)
	reject(forged_hour, "coordinated whole-hour economic deletion")
	var free_before := free_hour.snapshot()
	act(free_hour, "visit_hometown")
	check(free_hour.snapshot().armies.relief.food == free_before.armies.relief.food - 1, "real counterpart pays hourly food")
	# Independent review regression: self-reported civilian shortages, even with
	# coordinated ledger and observed-fact edits, are not authoritative local knowledge.
	var ration := W.new()
	check(ration.restore_campaign_state(old.state).ok, "ration fixture")
	act(ration, "camp_appraisal"); act(ration, "appraisal_accept")
	while ration.snapshot().hour < 23: act(ration, "wait_courier")
	act(ration, "visit_hometown")
	check(ration.player_view().hometown.visit.outcome == "met", "real adequate civilian ration")
	var ration_saved := ration.export_campaign_state()
	for exact_boundary in [false, true]:
		var forged := ration_saved.duplicate(true)
		var fake_at: float = 86400.0 if exact_boundary else forged.world.time_seconds
		var fake := {"hour": 24, "time_seconds": fake_at, "kind": "consumption", "details": {"entity": "pingling", "consumer": "civilian", "people": 20 if exact_boundary else 1, "requested": 48 if exact_boundary else 1, "eaten": 0, "shortfall": 48 if exact_boundary else 1, "food_delta": 0, "period_hours": 24}}
		var insert_at: int = forged.world.events.size() - 1
		if exact_boundary:
			for i in range(forged.world.events.size()):
				if forged.world.events[i].time_seconds > fake_at: insert_at = i; break
		forged.world.events.insert(insert_at, fake)
		forged.world.ledger.food_shortfall_civilian += fake.details.shortfall
		# Recompute the fraudulent final statement even when a genuine later ration
		# would overwrite the forged one; the fake clock event itself must be rejected.
		for e in forged.world.events:
			if e.kind == "hometown_visit":
				e.details.observation.activity = "ration_queue"; e.details.observation.basis = "civilian_shortfall"; e.details.observation.can_meet = false; e.details.outcome = "left_notice"
		reject(forged, "fabricated local civilian shortage exact_boundary=" + str(exact_boundary))
	var coordinated := ration_saved.duplicate(true)
	for e in coordinated.world.events:
		if e.kind == "consumption" and e.details.entity == "pingling" and e.details.consumer == "civilian" and e.time_seconds == 86400.0:
			var eaten: int = e.details.eaten
			e.details.eaten = 0; e.details.food_delta = 0; e.details.shortfall += eaten
			coordinated.world.cities.pingling.food += eaten
			coordinated.world.ledger.food_consumed -= eaten
			coordinated.world.ledger.food_consumed_civilian -= eaten
			coordinated.world.ledger.food_shortfall_civilian += eaten
		if e.kind == "hometown_visit":
			e.details.observation.activity = "ration_queue"; e.details.observation.basis = "civilian_shortfall"; e.details.observation.can_meet = false; e.details.outcome = "left_notice"
	reject(coordinated, "coordinated exact-day ration stock ledger and observation forgery")
	var bypass := ration_saved.duplicate(true)
	bypass.world.clock_replay_verified = true
	reject(bypass, "payload cannot disable replay")
	# A real zero-merit retreat ends this narrative slice before the carrier arrives.
	# Existing courier waiting remains legal, while hometown truth/knowledge freezes.
	var withdrawn := setup.build()
	act(withdrawn, "first_march")
	var retreat_ticket := withdrawn.create_battle_ticket()
	check(retreat_ticket.ok, "retreat actual battle")
	var retreat_battle := withdrawn.start_battle(retreat_ticket.ticket.battle_id)
	var retreat := preload("res://tests/youth_combat_driver.gd").play(retreat_battle, "retreat")
	check(retreat.player_alive and retreat.forces[1].dead_ids.is_empty(), "real zero-merit retreat")
	check(withdrawn.commit_battle_outcome(retreat).ok, "retreat committed")
	check(withdrawn.snapshot().youth.endpoint.reason == "first_patrol_withdrawn", "early terminal story")
	var ended_truth := H.truth(withdrawn.snapshot())
	var ended_view: Dictionary = withdrawn.player_view().hometown
	for i in range(5): act(withdrawn, "wait_courier")
	check(H.truth(withdrawn.snapshot()) == ended_truth and withdrawn.player_view().hometown == ended_view, "early endpoint freezes facts receipts and overdue without blocking old wait")
	roundtrip(withdrawn, "early retreat endpoint after courier arrival")
	# Genuine hunger ends life; then even a direct legacy clock tick must freeze this module.
	var dying := setup.build()
	for i in range(80):
		if dying.snapshot().campaign_ended: break
		act(dying, "wait_courier")
	check(dying.snapshot().campaign_ended, "real hunger terminal boundary")
	var final_knowledge: Dictionary = dying.player_view().hometown
	var final_truth := H.truth(dying.snapshot())
	dying._advance_clock_to(dying.snapshot().time_seconds + 86400.0)
	check(H.truth(dying.snapshot()) == final_truth and dying.player_view().hometown == final_knowledge, "no hometown future or new knowledge after real death")
	check(setup.failures.is_empty(), "all real helper actions " + str(setup.failures))
	print("HOMETOWN_SUMMARY " + JSON.stringify({"checks": checks, "failures": failures}))
	quit(0 if failures.is_empty() else 1)
