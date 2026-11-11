class_name AppraisalPersistenceSmoke
extends RefCounted
## Export-safe stock/knowledge/merit restart proof through real public actions.
const W := preload("res://scripts/world_sim.gd")
const Store := preload("res://scripts/campaign_store.gd")
const Playback := preload("res://scripts/youth_persistence_smoke.gd")
var checks := 0
var failures: Array[String] = []
func check(ok: bool, label: String) -> bool:
	checks += 1
	if not ok: failures.append(label)
	return ok
func act(w: WorldSimulation, action: String) -> bool:
	return check(w.youth_action(action).ok, "action " + action)
func build(choice: String, reply: String = "", motivation: String = "homeland") -> WorldSimulation:
	var w := W.new(184)
	if not check(w.start_youth("forced", motivation).ok, "enlist"): return w
	if reply != "" and not act(w, "arrange_courier"): return w
	if not act(w, "first_march"): return w
	if reply != "":
		if not act(w, "wait_courier") or not act(w, "courier_" + reply): return w
	var reserved := w.create_battle_ticket()
	if not check(reserved.ok, "real battle ticket"): return w
	w.start_battle(reserved.ticket.battle_id)
	var driver := Playback.new()
	if not check(driver._play(w, "fight"), "public controls battle playback"): return w
	if not check(driver._settle(w), "real battle settlement"): return w
	for action in ["return_to_camp", choice, "accept_appointment"]:
		if not act(w, action): return w
	return w
static func run(phase: String, id: String) -> Dictionary:
	return AppraisalPersistenceSmoke.new().execute(phase, id)
func execute(phase: String, id: String) -> Dictionary:
	var store := Store.new("appraisal_" + id)
	for scenario in [["appeal", "", "support"], ["keep_evidence", "", "bargain"], ["appeal", "refuse", "denied"]]:
		var label: String = scenario[2]
		var w := W.new()
		if phase == "prepare":
			w = build(scenario[0], scenario[1])
			if not act(w, "camp_appraisal"): break
			if not check(w.youth_view().appraisal.outcome == label, "expected offer"): break
			if not check(store.save_slot(w, "quote_" + label).ok, "save pending offer"): break
		elif phase == "resume":
			if not check(store.load_slot(w, "quote_" + label).ok, "load prior process offer"): break
		else:
			check(false, "unknown phase")
			break
		if label != "denied":
			var before := w.snapshot()
			if not act(w, "appraisal_accept"): break
			var after := w.snapshot()
			var food: int = w.youth_view().appraisal.food
			check(after.armies.relief.food == before.armies.relief.food + food and after.cities.pingling.food == before.cities.pingling.food - food, "stock exactly transferred")
			check(after.youth.earned_merit == before.youth.earned_merit, "actual merit unchanged")
			check(after.youth.recorded_merit == before.youth.recorded_merit - (1 if label == "bargain" else 0), "credit exact")
			var accepted := w.export_campaign_state()
			check(not w.youth_action("appraisal_accept").ok and w.export_campaign_state() == accepted, "repeat accept atomic")
		if not act(w, "refuse_order"): break
		check(w.snapshot().youth.endpoint.reason == "order_refused", "legitimate original endpoint")
		if phase == "prepare": check(store.save_slot(w, "expected_" + label).ok, "save endpoint")
		else:
			var expected := W.new()
			check(store.load_slot(expected, "expected_" + label).ok, "load prior endpoint")
			check(w.export_campaign_state() == expected.export_campaign_state(), "exact state events RNG resources knowledge after restart")
	return {"ok": failures.is_empty(), "checks": checks, "failures": failures, "phase": phase}
