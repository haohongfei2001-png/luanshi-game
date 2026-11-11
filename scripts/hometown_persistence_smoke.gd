class_name HometownPersistenceSmoke
extends RefCounted
const W := preload("res://scripts/world_sim.gd")
const H := preload("res://scripts/hometown_messages.gd")
const Store := preload("res://scripts/campaign_store.gd")
const Playback := preload("res://scripts/youth_persistence_smoke.gd")
var checks := 0
var failures: Array[String] = []
func check(ok: bool, label: String) -> bool:
	checks += 1
	if not ok: failures.append(label)
	return ok
func act(w: WorldSimulation, action: String) -> bool:
	var result := w.youth_action(action)
	return check(result.ok, "action " + action + (" " + str(result) if not result.ok else ""))
func build() -> WorldSimulation:
	var w := W.new(184)
	check(w.start_youth("forced", "homeland").ok, "enlist")
	act(w, "arrange_courier")
	act(w, "attach_hometown_letter")
	return w
func fight_return(w: WorldSimulation) -> bool:
	var ticket := w.create_battle_ticket()
	if not check(ticket.ok, "real first battle"): return false
	w.start_battle(ticket.ticket.battle_id)
	var playback := Playback.new()
	if not check(playback._play(w, "fight"), "public battle controls"): return false
	if not check(playback._settle(w), "real outcome"): return false
	return act(w, "return_to_camp")
static func run(phase: String, id: String) -> Dictionary:
	return HometownPersistenceSmoke.new().execute(phase, id)
func execute(phase: String, id: String) -> Dictionary:
	var store := Store.new("hometown_" + id)
	for scenario in ["arrive", "lost"]:
		var w := W.new()
		if phase == "prepare":
			w = build()
			if scenario == "arrive": act(w, "first_march")
			else: act(w, "wait_courier")
			check(w.player_view().hometown.message.is_empty(), "in transit remains unknown")
			if not check(store.save_slot(w, "pending_" + scenario).ok, "save physical transit"): break
		elif phase == "resume":
			if not check(store.load_slot(w, "pending_" + scenario).ok, "reload physical transit"): break
		else:
			check(false, "unknown phase")
			break
		if scenario == "arrive":
			act(w, "wait_courier")
			check(w.player_view().hometown.message.get("activity") == "workshop", "receive original letter")
			check(H.truth(w.snapshot()).activity == "caregiving", "offscreen person already changed")
			act(w, "courier_comply")
			if not fight_return(w): break
			act(w, "keep_evidence")
			act(w, "visit_hometown")
			check(w.player_view().hometown.visit.outcome == "met", "actual return and meeting")
		else:
			for i in range(6): act(w, "wait_courier")
			check(w.snapshot().couriers[0].status == "lost", "actual hostile endpoint intercepts carrier")
			check(w.player_view().hometown.message.is_empty() and w.player_view().hometown.overdue, "lost letter stays unknown")
		var settled := w.export_campaign_state()
		check(not w.youth_action("attach_hometown_letter").ok and settled == w.export_campaign_state(), "no duplicate attachment")
		if phase == "prepare": check(store.save_slot(w, "expected_" + scenario).ok, "save expected knowledge")
		else:
			var expected := W.new()
			check(store.load_slot(expected, "expected_" + scenario).ok, "load expected knowledge")
			check(w.export_campaign_state() == expected.export_campaign_state(), "exact restart events time resources and knowledge")
	return {"ok": failures.is_empty(), "checks": checks, "failures": failures, "phase": phase}
