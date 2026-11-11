extends SceneTree
## Clock-boundary regression, not combat balance/playability evidence. The deliberately
## stretched public tactical step consumes actual world food without injecting state.
const W := preload("res://scripts/world_sim.gd")
const Store := preload("res://scripts/campaign_store.gd")
const Driver := preload("res://tests/youth_combat_driver.gd")
var checks := 0
var failures: Array[String] = []
func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)
		push_error(label)
func roundtrip(w: WorldSimulation, label: String) -> void:
	var encoded := Store.new().encode_campaign(w)
	check(encoded.ok, label + " encodes")
	if not encoded.ok: return
	var decoded := Store.new().decode_campaign(encoded.bytes)
	var target := W.new()
	check(decoded.ok and target.restore_campaign_state(decoded.state).ok, label + " restores")
	check(target.export_campaign_state() == w.export_campaign_state(), label + " exact roundtrip")
func reject(saved: Dictionary, label: String) -> void:
	var target := W.new(99)
	var original := target.export_campaign_state()
	check(not target.restore_campaign_state(saved).ok, label + " rejected")
	check(original == target.export_campaign_state(), label + " atomic")
func depleted_return() -> WorldSimulation:
	var w := W.new()
	check(w.start_youth("forced", "homeland").ok, "forced enlistment")
	check(w.youth_action("first_march").ok, "first march")
	var id: String = w.create_battle_ticket().ticket.battle_id
	var b := w.start_battle(id)
	Driver.play(b, "fight", 180)
	check(not b.ended, "stretch fixture remains in actual combat")
	b.set_player_input(Vector2.ZERO, Vector2.RIGHT)
	b.step(7.0 * 3600.0)
	var out := Driver.play(b)
	check(out.result == "victory" and out.player_alive, "actual combat victory survives prolonged clock fixture")
	check(w.commit_battle_outcome(out).ok, "extended battle settles")
	check(w.player_view().army.food == 0 and w.player_view().army.condition.hunger == 0, "actual seven hours exhaust last ration")
	roundtrip(w, "depleted battle")
	check(w.youth_action("return_to_camp").ok, "return with starvation completes rather than rolling back")
	var state := w.snapshot()
	check(state.armies.relief.soldiers == 4 and state.youth.roster.size() == 4, "actual casualty count agrees with named roster")
	check(not state.youth.characters.recruit_lin.alive and "recruit_lin" not in state.youth.roster, "deterministic ordinary soldier dies first")
	check(state.youth.characters.recruit_zhou.alive and state.commander.alive, "unaffected people remain alive")
	check(state.armies.relief.location == "pingling" and state.youth.stage == "injustice", "real return still reaches camp and next stage")
	check(state.youth.timeline[-2].action == "attrition" and state.youth.timeline[-2].details.dead_ids == ["recruit_lin"], "named starvation record derives from actual loss")
	roundtrip(w, "named return casualty")
	return w
func continue_terminal(w: WorldSimulation) -> void:
	check(w.youth_action("protect_comrade").ok, "loss of final witness interrupts protection without rolling back time")
	var state := w.snapshot()
	check(state.youth.stage == "injustice" and state.youth.roster == ["commander"], "commander alone can still choose another response")
	check(state.youth.choice == "" and state.youth.protected_id == "" and state.youth.evidence.is_empty(), "interrupted protection invents no rescued person or evidence")
	check(state.youth.timeline[-1].action == "interrupted", "failed protection is recorded")
	check(not w.youth_view().choices[3].enabled, "protection becomes unavailable after witness death")
	roundtrip(w, "interrupted protection")
	var forged := w.export_campaign_state()
	forged.world.events.append(forged.world.events[-1].duplicate(true))
	reject(forged, "replayed interruption event")
	forged = w.export_campaign_state()
	forged.world.youth.timeline.append(forged.world.youth.timeline[-1].duplicate(true))
	reject(forged, "replayed interruption timeline")
	check(w.youth_action("endure").ok, "commander starvation becomes legitimate endpoint")
	state = w.snapshot()
	check(state.campaign_ended and not state.commander.alive and state.commander.hp == 0.0, "protagonist death is authoritative")
	check(state.youth.roster.is_empty() and state.youth.endpoint.reason == "commander_dead" and state.youth.endpoint.cause == "starvation", "named roster and death endpoint agree")
	check(state.youth.reward_food == 0 and state.youth.choice == "" and state.armies.relief.food == 0, "dead commander receives no pending action reward")
	check(w.youth_view().choices.is_empty(), "death exposes no further actions")
	var before := w.export_campaign_state()
	check(not w.youth_action("endure").ok and w.export_campaign_state() == before, "repeat action cannot revive or grant resources")
	roundtrip(w, "starvation endpoint")
func run() -> void:
	var args := OS.get_cmdline_user_args()
	var phase := args[0] if not args.is_empty() else "prepare"
	var store := Store.new(args[1] if args.size() > 1 else "youth_attrition_regression")
	var w := W.new()
	if phase == "resume":
		check(store.load_slot(w, "returned").ok, "fresh process restores named casualty")
		continue_terminal(w)
		var expected := W.new()
		check(store.load_slot(expected, "terminal").ok, "fresh process restores starvation endpoint")
		check(w.export_campaign_state() == expected.export_campaign_state(), "restart continuation produces identical state and history")
	else:
		w = depleted_return()
		var returned := w.export_campaign_state()
		check(store.save_slot(w, "returned").ok, "persist return for restart")
		var forged := returned.duplicate(true)
		forged.world.youth.characters.recruit_lin.alive = true
		reject(forged, "resurrected starvation casualty")
		forged = returned.duplicate(true)
		for event in forged.world.youth.timeline:
			if event.action == "attrition": event.details.dead_ids = ["recruit_zhou"]
		reject(forged, "rewritten casualty identity")
		forged = returned.duplicate(true)
		for event in forged.world.youth.timeline:
			if event.action == "attrition": event.details.cause = "combat"
		reject(forged, "forged narrative casualty cause")
		forged = returned.duplicate(true)
		for event in forged.world.events:
			if event.kind == "troops_lost" and event.details.entity == "relief": event.details.cause = "combat"
		for event in forged.world.youth.timeline:
			if event.action == "attrition": event.details.cause = "combat"
		reject(forged, "matching forged source and narrative cause")
		forged = returned.duplicate(true)
		for index in range(forged.world.events.size()):
			var event: Dictionary = forged.world.events[index]
			if event.kind == "troops_lost" and event.details.entity == "relief":
				forged.world.events.insert(index + 1, event.duplicate(true))
				break
		reject(forged, "replayed aggregate casualty")
		forged = returned.duplicate(true)
		for index in range(forged.world.youth.timeline.size()):
			var event: Dictionary = forged.world.youth.timeline[index]
			if event.action == "attrition":
				forged.world.youth.timeline.insert(index + 1, event.duplicate(true))
				break
		reject(forged, "replayed named casualty")
		# Continued successful appointment must use the post-attrition roster,
		# not the dictionary captured before its elapsed preparation time.
		var appointment := W.new()
		check(appointment.restore_campaign_state(returned).ok, "appointment branch restores")
		check(appointment.youth_action("endure").ok and appointment.youth_action("accept_appointment").ok, "surviving commander receives real appointment after casualties")
		check(appointment.snapshot().youth.roster.size() == 6 and not appointment.snapshot().youth.characters.recruit_lin.alive and not appointment.snapshot().youth.characters.recruit_zhou.alive, "replacement identities do not resurrect prior casualties")
		roundtrip(appointment, "appointment after attrition")
		# Death in a longer choice skips its resource transfer and story effect.
		var appeal := W.new()
		check(appeal.restore_campaign_state(returned).ok and appeal.youth_action("appeal").ok, "death during six-hour appeal completes legally")
		check(appeal.snapshot().time_seconds == appeal.snapshot().youth.endpoint.at, "long choice clock stops at actual death boundary")
		check(appeal.snapshot().campaign_ended and appeal.snapshot().youth.reward_food == 0 and appeal.snapshot().youth.evidence.is_empty(), "death before appeal resolution grants nothing")
		roundtrip(appeal, "interrupted appeal death")
		continue_terminal(w)
		check(store.save_slot(w, "terminal").ok, "persist terminal expectation")
	print("YOUTH_ATTRITION_" + phase.to_upper() + " " + JSON.stringify({"checks": checks, "failures": failures}))
	quit(0 if failures.is_empty() else 1)
