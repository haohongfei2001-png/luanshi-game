extends SceneTree
## Actual scene lifecycle: explicit late training never changes a fresh campaign,
## and old running/committed/dead saves bind their own legacy identity.
const Store := preload("res://scripts/campaign_store.gd")
var checks := 0
var failures: Array[String] = []
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error(message)
func _initialize() -> void:
	call_deferred("_run")
func _run() -> void:
	var scene: Node = load("res://scenes/battle.tscn").instantiate()
	var store := Store.new("profile_scene_" + Crypto.new().generate_random_bytes(8).hex_encode())
	scene.campaign_store = store
	root.add_child(scene)
	await process_frame
	await process_frame
	var expected_profile := "late_v1" if "--training-profile=late_v1" in OS.get_cmdline_user_args() else "early_v1"
	check(scene.training_sim.hero_profile.id == expected_profile, "training explicit tier")
	check(scene.training_sim.player().max_hp == 100.0, "both training tiers finite")
	check(scene.strategy.world.snapshot().commander.hero_profile.id == "early_v1", "training tier cannot upgrade campaign")
	for name in ["running", "committed", "dead"]:
		var path: String = store._location("slots", name, true).path
		var bytes := FileAccess.get_file_as_bytes("res://tests/fixtures/v06/%s.save.json" % name)
		var file := FileAccess.open(path, FileAccess.WRITE)
		file.store_buffer(bytes)
		file.close()
		scene._open_save_panel()
		check(scene._load_campaign(name).ok, "actual scene loads genuine v06 " + name)
		check(scene.strategy.world.snapshot().commander.hero_profile.id == "legacy_test_v0", "world retains legacy " + name)
		if name == "running":
			check(scene.sim.hero_profile.id == "legacy_test_v0" and scene.sim.player().max_hp == 360.0, "active legacy binds 360HP simulation")
			check(scene.sim.player().guard > 2.5 and scene.sim.cooldowns.attack > 0.5, "actual scene preserves old guard and cooldown")
			check(scene.paused and scene.hud.profile_label() == "V0.6 LEGACY", "old battle paused and accurately labeled")
		else:
			check(scene.campaign_adapter == null and scene.sim == scene.training_sim and scene.strategy.visible, "settled save restores map without replay")
		check(scene.training_sim.hero_profile.id == expected_profile, "load preserves independent training tier")
		check(FileAccess.get_file_as_bytes(path) == bytes, "scene load never rewrites original bytes")
	check(scene.strategy.world.player_view().campaign_ended, "dead legacy save remains dead")
	scene.queue_free()
	await process_frame
	print("PROFILE_SCENE_TESTS " + JSON.stringify({"training_profile": expected_profile, "checks": checks, "failures": failures}))
	quit(0 if failures.is_empty() else 1)
