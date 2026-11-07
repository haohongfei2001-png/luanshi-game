extends SceneTree
const World := preload("res://scripts/world_sim.gd")
const Store := preload("res://scripts/campaign_store.gd")
var assertions := 0
var failures: Array[String] = []
func _initialize() -> void:
	call_deferred("_run")
func check(ok: bool, label: String) -> void:
	assertions += 1
	if not ok:
		failures.append(label)
		push_error(label)
func _run() -> void:
	var world := World.new(184)
	for day in range(90):
		check(world.advance(24), "existing 90-day economy day advances")
	var store := Store.new("test_history_" + Crypto.new().generate_random_bytes(8).hex_encode())
	var before := world.export_campaign_state()
	var started := Time.get_ticks_msec()
	var saved := store.save_slot(world, "ninety_days")
	var save_ms := Time.get_ticks_msec() - started
	check(saved.ok, "full unmodified 90-day world saves " + str(saved))
	var loaded := World.new()
	started = Time.get_ticks_msec()
	var result := store.load_slot(loaded, "ninety_days")
	var load_ms := Time.get_ticks_msec() - started
	check(result.ok, "full 90-day world loads " + str(result))
	check(loaded.export_campaign_state() == before, "all 90-day events, integer ledgers and causal state preserved")
	var reconstructed := {"food_produced": 0, "weapons_produced": 0, "food_consumed": 0}
	for event in loaded.snapshot().events:
		if event.kind == "production":
			reconstructed.food_produced += event.details.amounts.food
			reconstructed.weapons_produced += event.details.amounts.weapons
		elif event.kind == "consumption":
			reconstructed.food_consumed += event.details.eaten
	for field in reconstructed:
		check(reconstructed[field] == before.world.ledger[field], "untruncated history reconstructs " + field)
	check(world.advance(24) and loaded.advance(24), "both histories continue next day")
	check(world.export_campaign_state() == loaded.export_campaign_state(), "91st day equals uninterrupted world")
	var file := FileAccess.open("user://campaigns/" + store._campaign + "/slots/ninety_days.save.json", FileAccess.READ)
	var bytes := file.get_length()
	var envelope: Dictionary = JSON.parse_string(file.get_as_text())
	file.close()
	print("SAVE_HISTORY_METRICS " + JSON.stringify({"days": 90, "events": before.world.events.size(), "disk_bytes": bytes, "uncompressed_bytes": envelope.uncompressed_bytes, "save_ms": save_ms, "load_ms": load_ms}))
	print("Save history tests: %d assertions, %d failures" % [assertions, failures.size()])
	quit(0 if failures.is_empty() else 1)
