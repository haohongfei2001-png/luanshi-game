extends SceneTree
## Run prepare then resume in separate Godot processes with the same campaign ID.
const W := preload("res://scripts/world_sim.gd")
const Store := preload("res://scripts/campaign_store.gd")
var checks := 0
var failures: Array[String] = []
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label); push_error(label)
func _initialize() -> void: call_deferred("run")
func act(w: WorldSimulation, action: String) -> void:
	var result := w.youth_action(action)
	check(result.ok, action + " " + str(result))
func new_life() -> WorldSimulation:
	var w := W.new()
	check(w.start_youth("volunteer", "homeland").ok, "start")
	act(w, "arrange_courier")
	return w
func advance_case(w: WorldSimulation, phase: String) -> void:
	if phase == "outbound": act(w, "wait_courier"); act(w, "courier_comply")
	for i in range(3): act(w, "wait_courier")
func run() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() != 2 or args[0] not in ["prepare", "resume"]:
		push_error("Usage: -- prepare|resume courier_restart"); quit(2); return
	var store := Store.new(args[1])
	for phase in ["outbound", "returning", "lost"]:
		var w := W.new()
		if args[0] == "prepare":
			w = new_life()
			if phase == "lost":
				for i in range(4): act(w, "wait_courier")
			else:
				act(w, "first_march")
				if phase == "returning": act(w, "wait_courier"); act(w, "courier_refuse")
			check(w.snapshot().couriers[0].status == phase, "actual causal boundary " + phase)
			check(store.save_slot(w, phase).ok, "save " + phase)
			advance_case(w, phase)
			check(store.save_slot(w, phase + "_expected").ok, "save expected " + phase)
		else:
			var result := store.load_slot(w, phase)
			check(result.ok, "fresh process load " + phase + " " + str(result))
			if not result.ok: continue
			check(w.snapshot().couriers[0].status == phase, "restored physical phase " + phase)
			advance_case(w, phase)
			var expected := W.new()
			check(store.load_slot(expected, phase + "_expected").ok, "read expected " + phase)
			check(w.export_campaign_state() == expected.export_campaign_state(), "restart exact whole graph " + phase)
			check(w.audit().is_empty(), "restart conservation " + phase)
	print("COURIER_RESTART_" + args[0].to_upper() + " " + JSON.stringify({"checks": checks, "failures": failures}))
	quit(0 if failures.is_empty() else 1)
