extends SceneTree
const W := preload("res://scripts/world_sim.gd")
const Store := preload("res://scripts/campaign_store.gd")
const Driver := preload("res://tests/youth_combat_driver.gd")
var checks := 0
var failures: Array[String] = []
var proofs: Array = []
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)
		push_error(label)
func _initialize() -> void: call_deferred("run")
func act(w: WorldSimulation, action: String) -> bool:
	var r := w.youth_action(action)
	check(r.ok, action + ": " + str(r))
	return r.ok
func roundtrip(w: WorldSimulation, label: String) -> void:
	var store := Store.new()
	var encoded := store.encode_campaign(w)
	check(encoded.ok, label + " encodes " + str(encoded.get("reason", "")))
	if not encoded.ok: return
	var decoded := store.decode_campaign(encoded.bytes)
	var loaded := W.new(999)
	check(decoded.ok and loaded.restore_campaign_state(decoded.state).ok, label + " restores")
	check(loaded.export_campaign_state() == w.export_campaign_state(), label + " exact graph")
func fight(w: WorldSimulation, policy: String, phase: String) -> Dictionary:
	var before := w.snapshot()
	var reservation := w.create_battle_ticket()
	check(reservation.ok, phase + " reserves real troops")
	if not reservation.ok: return {}
	var id: String = reservation.ticket.battle_id
	var b := w.start_battle(id)
	if phase == "first":
		check(not b.issue_order("attack") and not b.issue_order("follow"), "recruit lacks command authority")
		check(b.order == "attack", "superior gives actual initial patrol order")
	else: check(b.issue_order("attack"), "appointed squad can receive commands")
	roundtrip(w, phase + " running")
	var out := Driver.play(b, policy)
	check(b.ended and not out.is_empty(), phase + " real terminal controls " + policy)
	if out.is_empty(): return {}
	var receipt := w.commit_battle_outcome(out)
	check(receipt.ok, phase + " real settlement " + str(receipt))
	if not receipt.ok: return {}
	var after := w.snapshot()
	check(after.ledger.dead - before.ledger.dead == out.forces[0].dead_ids.size() + out.forces[1].dead_ids.size(), phase + " exact casualties")
	check(after.armies.relief.soldiers == before.armies.relief.soldiers - out.forces[0].dead_ids.size(), phase + " roster casualty debit")
	check(after.cities.hequ.soldiers == before.cities.hequ.soldiers - out.forces[1].dead_ids.size(), phase + " undeployed defenders remain")
	check(after.armies.relief.weapons == before.armies.relief.weapons - out.forces[0].destroyed_equipment + out.spoils.weapons, phase + " equipment causal")
	check(after.cities.hequ.owner == "bei" and not receipt.depot_captured, phase + " patrol victory does not capture entire depot")
	for id2 in out.forces[0].dead_ids:
		if id2 != "commander": check(not after.youth.characters[id2].alive and id2 not in after.youth.roster, "actual dead identity removed " + id2)
	for id2 in out.forces[0].surviving_ids:
		if id2 != "commander": check(after.youth.characters[id2].alive and after.youth.characters[id2].known_battles.has(id), "surviving identity knows its battle " + id2)
	check(after.youth.characters.officer_qiao.known_battles.size() < after.youth.battle_ids.size(), "distant superior not omniscient")
	var repeat := w.commit_battle_outcome(out)
	check(repeat.ok and repeat.already_committed and after == w.snapshot(), phase + " settlement is once only")
	check(w.audit().is_empty(), phase + " resource audit")
	roundtrip(w, phase + " committed")
	proofs.append({"seed": before.seed, "phase": phase, "policy": policy, "result": out.result, "player_hp": out.player_hp, "ally_dead": out.forces[0].dead_ids, "enemy_dead": out.forces[1].dead_ids.size(), "elapsed": out.elapsed_world_time})
	return out
func new_life(seed: int = 184, enlistment: String = "volunteer", motive: String = "homeland") -> WorldSimulation:
	var w := W.new(seed)
	var initial := w.totals()
	check(w.start_youth(enlistment, motive).ok, "enlistment accepted")
	check(w.snapshot().mode == "youth" and is_equal_approx(w.youth_view().age_years, 15.0), "new genuine age fifteen")
	check(w.totals() == initial, "enlistment redistributes no resources spawned")
	check(w.snapshot().armies.relief.soldiers == 5 and w.snapshot().cities.pingling.soldiers == 75, "host holds fifty-five existing soldiers")
	check(not w.march("river") and not w.transfer("pingling", "relief", "food", 1) and not w.seize_depot() and not w.advance(1), "recruit cannot bypass lawful action authority")
	check(not w.start_youth(enlistment, motive).ok, "enlistment once only")
	roundtrip(w, "enlistment")
	return w
func run() -> void:
	var technical := W.new()
	check(not technical.youth_view().enabled and technical.snapshot().youth.is_empty(), "technical scenario has no retroactive child identity")
	var forced := new_life(184, "forced", "survival")
	var voluntary := new_life(184, "volunteer", "merit")
	check(forced.snapshot().armies.relief.food != voluntary.snapshot().armies.relief.food and forced.youth_view().standing != voluntary.youth_view().standing, "enlistment and motive have real supply and standing effects")
	var branches: Array = []
	for choice in ["endure", "appeal", "keep_evidence", "protect_comrade"]:
		var w := new_life(184)
		check(act(w, "first_march") and w.snapshot().time_seconds == 10800.0, "first march real three hours")
		var out := fight(w, "fight", "first")
		if out.is_empty() or not out.player_alive: continue
		check(w.youth_view().earned_merit == out.forces[1].dead_ids.size() + 1, "merit from actual first outcome")
		check(w.youth_view().relationships.officer_qiao.reported_merit == 0, "distant officer has not yet appropriated unreceived report")
		act(w, "return_to_camp")
		check(w.youth_view().recorded_merit < w.youth_view().earned_merit and w.youth_view().appropriated_merit > 0, "actual recorded merit appropriated")
		check(w.youth_view().relationships.officer_qiao.reported_merit == w.youth_view().appropriated_merit and w.youth_view().incident_details.actor_id == "officer_qiao", "explicit superior receives stolen credit")
		var before := w.snapshot()
		act(w, choice)
		var after := w.snapshot()
		check(is_equal_approx(after.time_seconds - before.time_seconds, W.Youth.CHOICE_HOURS[choice] * 3600.0), choice + " actual elapsed")
		check(after.armies.relief.food == before.armies.relief.food - W.Youth.CHOICE_HOURS[choice] + W.Youth.REWARDS[choice], choice + " real ration consumption and reward")
		check(after.youth.reward_food == W.Youth.REWARDS[choice], choice + " reward distinct")
		check(not w.youth_action(choice).ok and w.snapshot() == after, choice + " cannot repeat reward")
		branches.append([after.youth.standing, after.youth.recorded_merit, after.youth.reward_food, after.youth.evidence, after.youth.characters.recruit_lin.trust])
		if choice == "protect_comrade": check(after.youth.protected_id == "recruit_lin" and after.cities.pingling.soldiers == before.cities.pingling.soldiers + 1 and "recruit_lin" not in after.youth.roster, "protected survivor actually transferred to camp")
		roundtrip(w, choice)
		before = w.snapshot()
		act(w, "accept_appointment")
		after = w.snapshot()
		var cap: int = 4 if choice == "protect_comrade" else 6
		check(after.armies.relief.soldiers == cap and before.cities.pingling.soldiers - after.cities.pingling.soldiers == cap - before.armies.relief.soldiers, "real authority and source manpower")
		check(after.youth.appointment.issuer == "officer_qiao" and after.youth.rank == "temporary_squad_leader", "appointment from actual superior")
		check(not w.youth_action("accept_appointment").ok, "cannot duplicate appointment")
		act(w, "dangerous_march")
		var second := fight(w, "delayed_retreat" if choice == "protect_comrade" else "tactical", "dangerous")
		if second.is_empty(): continue
		check(second.result == ("retreat" if choice == "protect_comrade" else "victory"), "actual calibrated mission control result " + choice)
		if second.player_alive:
			act(w, "return_to_camp")
			before = w.snapshot()
			act(w, "replenish")
			after = w.snapshot()
			check(after.armies.relief.soldiers == cap and before.cities.pingling.soldiers - after.cities.pingling.soldiers == cap - before.armies.relief.soldiers, "replenishment from exact remaining pool")
			for id in second.forces[0].dead_ids:
				check(not after.youth.characters[id].alive and id not in after.youth.roster, "replacement does not resurrect " + id)
		check(w.youth_view().stage == "endpoint", "finite short-slice endpoint")
		check(not w.youth_action("replenish").ok and not w.create_battle_ticket().ok, "endpoint cannot farm grants or combat")
		roundtrip(w, "endpoint " + choice)
	for i in range(branches.size()):
		for j in range(i): check(branches[i] != branches[j], "all injustice branches distinct")
	for policy in ["retreat", "reckless"]:
		var w := new_life(185, "forced", "survival")
		act(w, "first_march")
		var out := fight(w, policy, "first")
		if not out.is_empty():
			check(w.youth_view().stage == ("endpoint" if out.result != "victory" else "first_return"), "first real result drives phase " + policy)
			check((out.result == "commander_dead") == w.player_view().campaign_ended, "only actual death ends entire life")
			if out.result == "victory":
				act(w, "return_to_camp")
				check(w.youth_view().incident == "disputed_order", "odd seed gives contested-order report variant with real larger first patrol")
	var doomed := new_life(184)
	act(doomed, "first_march")
	fight(doomed, "fight", "first")
	act(doomed, "return_to_camp"); act(doomed, "endure"); act(doomed, "accept_appointment")
	var life_node := doomed.export_campaign_state()
	act(doomed, "dangerous_march")
	var fatal := fight(doomed, "reckless", "dangerous")
	check(not fatal.is_empty() and fatal.result == "commander_dead" and doomed.player_view().campaign_ended, "real reckless mission death ends life")
	check(doomed.restore_campaign_state(life_node).ok and doomed.youth_view().stage == "dangerous_orders" and not doomed.player_view().campaign_ended, "explicit checkpoint rollback restores actual pre-death world")
	act(doomed, "refuse_order")
	check(doomed.snapshot().armies.relief.soldiers == 1 and doomed.youth_view().rank == "relieved_of_command" and doomed.youth_view().endpoint.reason == "order_refused", "refusal transfers troops and withdraws office")
	roundtrip(doomed, "refusal")
	absence_validation_fixture()
	print("YOUTH_COMBAT_PROOFS " + JSON.stringify(proofs))
	print("YOUTH_CAREER_TESTS " + JSON.stringify({"checks": checks, "failures": failures}))
	quit(0 if failures.is_empty() else 1)

func absence_validation_fixture() -> void:
	# VALIDATION FIXTURE ONLY: injected terminal unit states exercise no-witness
	# branching and dead-identity guards. These are not included in combat proofs.
	var w := new_life(184)
	act(w, "first_march")
	var id: String = w.create_battle_ticket().ticket.battle_id
	var b := w.start_battle(id)
	for u in b.units:
		if not u.hero: b._hurt(u, 1000.0, false)
	b._check_result()
	check(w.commit_battle_outcome(b.outcome()).ok, "validation fixture settles exact assigned dead IDs")
	act(w, "return_to_camp")
	var before := w.snapshot()
	check(not w.youth_action("protect_comrade").ok and w.snapshot() == before, "no dead comrade can be protected or resurrected")
	act(w, "appeal")
	check(w.youth_view().evidence[0].kind == "contested_roster" and w.youth_view().evidence[0].witness == "", "absence uses records not an invented witness")
	check(w.youth_view().recorded_merit == 2, "absence appeal weaker than live witness appeal")
	act(w, "accept_appointment")
	for id2 in W.Youth.PEOPLE:
		check(not w.youth_view().relationships[id2].alive and id2 not in w.snapshot().youth.roster, "dead original stays dead on appointment")
	roundtrip(w, "no-witness validation fixture")
