extends SceneTree
## Run twice by tools/test.sh: the second Godot process has no old objects/RNG.
const World := preload("res://scripts/world_sim.gd")
const Store := preload("res://scripts/campaign_store.gd")
var assertions := 0
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func check(condition: bool, label: String) -> void:
	assertions += 1
	if not condition:
		failures.append(label)
		push_error(label)

func _play(world: WorldSimulation, id: String, frames: int) -> void:
	var battle := world.start_battle(id)
	for frame in range(frames):
		battle.step(BattleSimulation.FIXED_DELTA)
		check(world.sync_battle_time(id), "battle clock resumes")
		if battle.ended:
			break

func _run() -> void:
	var arguments := OS.get_cmdline_user_args()
	if arguments.size() not in [2, 3] or arguments[0] not in ["prepare", "resume"]:
		push_error("Expected prepare|resume plus isolated campaign identifier")
		quit(1)
		return
	var store := Store.new(arguments[1])
	var profile_id: String = arguments[2] if arguments.size() == 3 else "early_v1"
	var world := World.new(998877, profile_id)
	var id := ""
	if arguments[0] == "prepare":
		world.observe_city("pingling", 20)
		world.march("river")
		world.advance_seconds(10800.125)
		id = world.create_battle_ticket().ticket.battle_id
		var battle := world.start_battle(id)
		battle.issue_order("attack")
		_play(world, id, 330)
		for action in ["attack", "sweep", "lunge", "guard"]: check(battle.use_action(action), "activate saved " + action)
		check(store.save_slot(world, "running").ok, "write running session")
		_play(world, id, 10800)
		check(battle.ended, "uninterrupted battle ends")
		check(store.save_slot(world, "pending").ok, "write finished pending session")
		var committed := store.commit_and_save(world, battle.outcome(), "committed")
		check(committed.ok, "write once-only receipt")
		check(store.save_checkpoint(world, "expected").ok, "persist uninterrupted oracle")
	else:
		var expected := World.new()
		check(store.load_checkpoint(expected, "expected").ok, "read oracle from previous process")
		check(store.load_slot(world, "running").ok, "read running session from previous process")
		check(world.snapshot().commander.hero_profile.id == profile_id, "fresh process retains selected profile")
		id = world.player_view().active_battle
		if id.is_empty():
			check(false, "running ticket missing")
		else:
			_play(world, id, 10800)
			var outcome := world.start_battle(id).outcome()
			check(world.commit_battle_outcome(outcome).ok, "resumed actual battle settles")
			check(world.export_campaign_state() == expected.export_campaign_state(), "process restart equals uninterrupted oracle exactly")
		check(store.load_slot(world, "pending").ok, "read terminal precommit session")
		id = world.player_view().active_battle
		var pending_outcome := world.start_battle(id).outcome()
		check(store.commit_and_save(world, pending_outcome, "recovered").ok, "retry after simulated pre-rename crash settles once")
		check(world.export_campaign_state() == expected.export_campaign_state(), "precommit recovery exact")
		check(store.load_slot(world, "committed").ok, "read committed receipt from previous process")
		var before := world.export_campaign_state()
		var duplicate := store.commit_and_save(world, pending_outcome, "committed")
		check(duplicate.ok and duplicate.receipt.already_committed, "retry after simulated post-rename crash returns receipt")
		check(world.export_campaign_state() == before and before == expected.export_campaign_state(), "postcommit retry cannot duplicate resources")
	print("Save restart %s: %d assertions, %d failures" % [arguments[0], assertions, failures.size()])
	print("SAVE_RESTART_SUMMARY " + JSON.stringify({"profile": profile_id, "phase": arguments[0], "assertions": assertions, "failures": failures.size(), "messages": failures}))
	quit(0 if failures.is_empty() else 1)
