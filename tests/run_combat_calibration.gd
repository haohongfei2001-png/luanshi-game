extends SceneTree

const Calibration := preload("res://tests/combat_calibration.gd")
const Profiles := preload("res://scripts/hero_combat_profiles.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var rows: Array[Dictionary] = []
	var focused: Array[Dictionary] = []
	var surrounded: Array[Dictionary] = []
	for profile_id in [Profiles.EARLY, Profiles.LATE, Profiles.LEGACY]:
		for policy in Calibration.POLICIES:
			for count in [1, 2, 5]:
				for seed_number in Calibration.SEEDS:
					rows.append(Calibration.run(profile_id, count, seed_number, policy))
		for count in [10, 30]:
			for guarded in [false, true]:
				for seed_number in Calibration.SEEDS:
					focused.append(Calibration.focused_contact(profile_id, count, seed_number, guarded))
		if profile_id in Profiles.gameplay_ids():
			for count in [10, 30]:
				for seed_number in Calibration.SEEDS:
					surrounded.append(Calibration.organized_surround(profile_id, count, seed_number))
	var summary := Calibration.summarize(rows)
	var payload := {"engine": Engine.get_version_info().string, "profile_revision": Profiles.REVISION,
		"fixed_delta": Calibration.Simulation.FIXED_DELTA, "horizon_seconds": Calibration.HORIZON_SECONDS,
		"action_interval_steps": Calibration.ACTION_INTERVAL_STEPS, "seeds": Calibration.SEEDS, "summary": summary, "runs": rows, "focused_contact": focused, "organized_surround": surrounded}
	DirAccess.make_dir_recursive_absolute("res://artifacts")
	var file := FileAccess.open("res://artifacts/combat-calibration.json", FileAccess.WRITE)
	if file == null:
		push_error("Cannot write calibration results")
		quit(1)
		return
	file.store_string(JSON.stringify(payload, "\t") + "\n")
	for item in summary:
		print("COMBAT_CALIBRATION " + JSON.stringify(item))
	print("CALIBRATION_COMPLETE runs=%d focused_contact=%d organized_surround=%d" % [rows.size(), focused.size(), surrounded.size()])
	quit(0)
