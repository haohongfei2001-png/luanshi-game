class_name WoundPersistenceSmoke
extends RefCounted
const W := preload("res://scripts/world_sim.gd")
const Store := preload("res://scripts/campaign_store.gd")
var checks := 0
var failures: Array[String] = []
func check(ok: bool, label: String) -> bool:
	checks += 1
	if not ok: failures.append(label)
	return ok
func act(w: WorldSimulation, action: String) -> bool:
	return check(w.youth_action(action).ok, "action " + action)
func build(mode: String = "youth", profile: String = "early_v1") -> WorldSimulation:
	var w := W.new(184, profile)
	if mode == "youth":
		check(w.start_youth("forced", "homeland").ok, "enlist")
		act(w, "first_march")
	else:
		check(w.transfer("pingling", "relief", "food", 60), "technical local resupply")
		check(w.march("river") and w.advance(3), "technical march")
	var r := w.create_battle_ticket()
	if not check(r.ok, "reserve real encounter"): return w
	var b := w.start_battle(r.ticket.battle_id)
	if mode == "youth":
		for frame in range(18000):
			if b.ended: break
			var nearest := Vector2.RIGHT
			var distance := INF
			for u in b.units:
				if u.team == 1 and u.hp > 0.0 and b.player().pos.distance_to(u.pos) < distance:
					distance = b.player().pos.distance_to(u.pos)
					nearest = u.pos - b.player().pos
			b.set_player_input(nearest, nearest)
			b.step(BattleSimulation.FIXED_DELTA)
	else:
		b.issue_order("attack")
		# Walk into genuine enemy reach, then withdraw after the first actual hit.
		# No HP, positions, roster or outcome writes.
		for frame in range(18000):
			if b.ended: break
			if b.player().hp < b.player().max_hp:
				b.issue_order("retreat")
				b.set_player_input(Vector2.LEFT, Vector2.RIGHT)
			else: b.set_player_input(Vector2.RIGHT, Vector2.RIGHT)
			b.step(BattleSimulation.FIXED_DELTA)
	check(b.ended and b.player().hp > 0.0 and b.player().hp < b.player().max_hp, "actual survived injury")
	check(w.commit_battle_outcome(b.outcome()).ok, "commit actual injury")
	if mode == "youth": act(w, "return_to_camp")
	else: check(w.march("river") and w.advance(3), "technical return")
	return w
static func run(phase: String, id: String) -> Dictionary:
	return WoundPersistenceSmoke.new().execute(phase, id)
func execute(phase: String, id: String) -> Dictionary:
	var store := Store.new("wounds_" + id)
	for mode in ["youth", "technical"]:
		var w := W.new()
		if phase == "prepare":
			w = build(mode)
			if not check(store.save_slot(w, mode + "_before").ok, "save injured life"): break
		else:
			if not check(store.load_slot(w, mode + "_before").ok, "load injured life"): break
		var hp: float = w.snapshot().commander.hp
		check(w.rest_wounds(2).ok and w.snapshot().commander.hp == hp + 10.0, "two actual hours recover ten HP")
		if phase == "prepare": check(store.save_slot(w, mode + "_expected").ok, "save recovered endpoint")
		else:
			var expected := W.new()
			check(store.load_slot(expected, mode + "_expected").ok, "load recovered endpoint")
			check(w.export_campaign_state() == expected.export_campaign_state(), "exact separate-process replay")
		# Restart a later battle without rewriting its reservation or resurrecting losses.
		if mode == "youth":
			act(w, "keep_evidence"); act(w, "accept_appointment"); act(w, "dangerous_march")
		else: check(w.march("river") and w.advance(3), "return to hostile depot")
		var r := w.create_battle_ticket()
		if not check(r.ok, "second encounter with wounds"): break
		var b := w.start_battle(r.ticket.battle_id)
		check(b.player().hp == hp + 10.0, "second battle keeps only paid recovery")
		for i in range(33): b.step(BattleSimulation.FIXED_DELTA)
		check(w.sync_battle_time(r.ticket.battle_id), "sync active wounded battle")
		if phase == "prepare": check(store.save_slot(w, mode + "_active").ok, "save active wounded battle")
		else:
			var active := W.new()
			check(store.load_slot(active, mode + "_active").ok, "load active wounded battle")
			check(w.export_campaign_state() == active.export_campaign_state(), "exact ticket and session after recovery")
	return {"ok": failures.is_empty(), "checks": checks, "failures": failures, "phase": phase}
