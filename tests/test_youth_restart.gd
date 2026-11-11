extends SceneTree
const W := preload("res://scripts/world_sim.gd")
const Store := preload("res://scripts/campaign_store.gd")
const Driver := preload("res://tests/youth_combat_driver.gd")
var checks := 0
var failures: Array[String] = []
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label); push_error(label)
func finish(w: WorldSimulation) -> void:
	var b := w.start_battle("1:1")
	check(w.commit_battle_outcome(Driver.play(b)).ok, "first outcome commits")
	for action in ["return_to_camp", "protect_comrade", "accept_appointment", "dangerous_march"]: check(w.youth_action(action).ok, action)
	var id: String = w.create_battle_ticket().ticket.battle_id
	check(w.commit_battle_outcome(Driver.play(w.start_battle(id), "delayed_retreat")).ok, "second outcome commits")
	check(w.youth_action("return_to_camp").ok and w.youth_action("replenish").ok, "real replenishment endpoint")
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var args := OS.get_cmdline_user_args()
	var store := Store.new(args[1])
	var w := W.new()
	if args[0] == "prepare":
		check(w.start_youth("forced", "homeland").ok, "start")
		check(store.save_checkpoint(w, "enlistment").ok, "full life checkpoint")
		w.youth_action("first_march")
		var id: String = w.create_battle_ticket().ticket.battle_id
		var b := w.start_battle(id)
		b.use_action("guard"); b.set_player_input(Vector2(0.2, -0.1), Vector2.RIGHT); b.step(0.03125)
		check(store.save_slot(w, "active").ok, "live fractional combat saved")
		var pending := W.new()
		check(pending.restore_campaign_state(w.export_campaign_state()).ok, "clone for pending boundary")
		Driver.play(pending.start_battle(id))
		check(store.save_slot(pending, "pending").ok, "finished uncommitted saved")
		finish(w)
		check(store.save_slot(w, "expected_final").ok, "expected complete trajectory saved")
	else:
		check(store.load_slot(w, "active").ok, "fresh process restores active")
		finish(w)
		var expected := W.new()
		check(store.load_slot(expected, "expected_final").ok, "fresh process restores endpoint")
		check(w.export_campaign_state() == expected.export_campaign_state(), "all world, identity, inventory, merit, relationship and timeline exact after restart")
		var pending := W.new()
		check(store.load_slot(pending, "pending").ok and pending.start_battle("1:1").ended, "pending receipt boundary restored")
		var r := pending.commit_battle_outcome(pending.start_battle("1:1").outcome())
		check(r.ok and not r.already_committed and pending.youth_view().stage == "first_return", "pending settlement applied once")
		var original := pending.snapshot()
		var repeated := pending.commit_battle_outcome(pending.battle_ticket("1:1").outcome)
		check(repeated.ok and repeated.already_committed and pending.snapshot() == original, "pending receipt not duplicated")
		check(store.load_checkpoint(w, "enlistment").ok and w.youth_view().stage == "first_orders" and w.snapshot().youth.roster.size() == 5, "whole-life rollback restores old living roster rather than resurrecting in current life")
	print("YOUTH_RESTART_" + args[0].to_upper() + " " + JSON.stringify({"checks": checks, "failures": failures}))
	quit(0 if failures.is_empty() else 1)
