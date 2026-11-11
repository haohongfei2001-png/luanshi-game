class_name PetitionPersistenceSmoke
extends RefCounted
const W := preload("res://scripts/world_sim.gd")
const Store := preload("res://scripts/campaign_store.gd")
const Setup := preload("res://scripts/appraisal_persistence_smoke.gd")
var checks := 0
var failures: Array[String] = []
func check(ok: bool, label: String) -> bool:
	checks += 1
	if not ok: failures.append(label)
	return ok
static func run(phase: String, id: String) -> Dictionary:
	return PetitionPersistenceSmoke.new().execute(phase, id)
func execute(phase: String, id: String) -> Dictionary:
	var store := Store.new("petition_" + id)
	for choice in ["keep_evidence", "endure", "protect_comrade"]:
		var w := W.new()
		if phase == "prepare":
			var setup := Setup.new()
			w = setup.build(choice, "", "survival" if choice == "endure" else "homeland")
			check(setup.failures.is_empty(), "actual battle and camp " + choice)
			if not check(store.save_slot(w, "before_" + choice).ok, "save before decision"): break
		elif phase == "resume":
			if not check(store.load_slot(w, "before_" + choice).ok, "load before decision"): break
		else:
			check(false, "unknown phase")
			break
		var before := w.snapshot()
		if not check(w.youth_action("comrade_petition").ok, "actual petition"): break
		var record: Dictionary = w.youth_view().petition
		check((record.restored == 0) == (choice == "endure"), "expected named decisions " + choice)
		check(w.snapshot().youth.recorded_merit == before.youth.recorded_merit + record.restored, "actual recorded consequence")
		check(w.snapshot().youth.earned_merit == before.youth.earned_merit, "earned merit unchanged")
		var settled := w.export_campaign_state()
		check(not w.youth_action("comrade_petition").ok and settled == w.export_campaign_state(), "no repeat farming")
		if not check(w.youth_action("refuse_order").ok, "original endpoint retained"): break
		if phase == "prepare": check(store.save_slot(w, "expected_" + choice).ok, "save persistent decisions")
		else:
			var expected := W.new()
			check(store.load_slot(expected, "expected_" + choice).ok, "load expected history")
			check(w.export_campaign_state() == expected.export_campaign_state(), "exact causal restart")
	return {"ok": failures.is_empty(), "checks": checks, "failures": failures, "phase": phase}
