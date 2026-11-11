extends SceneTree

const Profiles := preload("res://scripts/hero_combat_profiles.gd")
var checks := 0
var failures: Array[String] = []

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error(message)

func _initialize() -> void:
	var early := Profiles.get_profile(Profiles.EARLY)
	var late := Profiles.get_profile(Profiles.LATE)
	var legacy := Profiles.get_profile(Profiles.LEGACY)
	check(Profiles.get_profile("unknown").is_empty(), "unknown profile has no silent legacy fallback")
	check(Profiles.gameplay_ids() == [Profiles.EARLY, Profiles.LATE], "legacy excluded from gameplay selection")
	check(legacy.test_only and legacy.max_hp == 360.0, "360 HP explicitly kept as legacy test fixture")
	check(early.max_hp == late.max_hp, "growth comparison holds HP equal")
	for key in ["speed", "guard_cooldown", "guard_duration", "guard_incoming_factor"]:
		check(early[key] == late[key], "late does not gain defense or move speed: " + key)
	for profile_id in Profiles.gameplay_ids():
		var profile := Profiles.get_profile(profile_id)
		check(not profile.test_only, "gameplay profile identified")
		check(profile.max_hp > 0.0 and profile.max_hp <= Profiles.GAMEPLAY_HP_CAP, "finite gameplay HP cap")
		check(profile.guard_incoming_factor >= 0.5 and profile.guard_incoming_factor <= 1.0, "guard cannot erase focused damage")
		check(profile.guard_duration < profile.guard_cooldown, "guard cannot be permanent")
		check(profile.attack_targets == 1, "ordinary basic strike is a single target")
		check(profile.sweep_targets > 0 and profile.lunge_targets > 0, "gameplay skills have explicit finite hit caps")
		for key in profile:
			if profile[key] is float:
				check(is_finite(profile[key]), "finite field: " + key)
		profile.max_hp = 99999.0
		check(Profiles.get_profile(profile_id).max_hp == 100.0, "caller cannot mutate canonical profile")
	check(late.damage > early.damage and late.attack_cooldown < early.attack_cooldown, "late basic offense increases")
	check(late.sweep_damage > early.sweep_damage and late.sweep_targets > early.sweep_targets, "late sweep efficiency increases")
	check(late.lunge_damage > early.lunge_damage and late.lunge_targets > early.lunge_targets, "late lunge efficiency increases")
	print("HERO_PROFILE_TESTS " + JSON.stringify({"checks": checks, "failures": failures}))
	quit(0 if failures.is_empty() else 1)
