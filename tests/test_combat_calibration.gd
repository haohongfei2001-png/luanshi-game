extends SceneTree

const Calibration := preload("res://tests/combat_calibration.gd")
const Profiles := preload("res://scripts/hero_combat_profiles.gd")
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
	# Mechanical boundary tests use real BattleSim actions/AI, not injected damage.
	var battle := Calibration.fixture(Profiles.EARLY, 5, 184)
	var snapshot := var_to_bytes([battle.units, battle.rng.state, battle.hero_profile])
	check(not battle.reset(5, "invalid"), "invalid profile is rejected")
	check(snapshot == var_to_bytes([battle.units, battle.rng.state, battle.hero_profile]), "invalid selection leaves current battle unchanged")
	for profile_id in [Profiles.EARLY, Profiles.LATE, Profiles.LEGACY]:
		var small := Calibration.fixture(profile_id, 1, 184)
		var large := Calibration.fixture(profile_id, 30, 184)
		for key in ["hp", "max_hp", "speed", "damage", "range", "condition_damage_scale", "condition_speed_scale"]:
			check(small.player()[key] == large.player()[key], "no enemy-count bonus: " + profile_id + "/" + key)
		check(small.hero_profile == large.hero_profile, "all skill parameters independent of enemy count")
		var soldier: Dictionary = small.units[0]
		check(soldier.hp == 100.0 and soldier.damage == 13.0 and soldier.range == 1.65 and soldier.speed == 3.0, "ordinary soldier is not weakened by hero profile")
		for action in ["attack", "sweep", "lunge"]:
			battle = Calibration.fixture(profile_id, 5, 184)
			for i in range(5):
				battle.units[i].pos = Vector2(1.0 + i * 0.1, 0)
			battle.set_player_input(Vector2.ZERO, Vector2.RIGHT)
			check(battle.use_action(action), "action accepted: " + profile_id + "/" + action)
			var cap: int = battle.hero_profile[action + "_targets"]
			var hit_count := 0
			for unit in battle.units:
				if not unit.hero and unit.hp < 100.0:
					hit_count += 1
			check(hit_count == (mini(cap, 5) if cap > 0 else 5), "action respects profile hit cap")
			check(not battle.use_action(action), "cooldown forbids immediate repeated action")
			check(battle.units[0].hp < 100.0, "nearest eligible enemy is hit first")
		battle = Calibration.fixture(profile_id, 1, 184)
		battle.units[0].pos = Vector2(-1.5, 0)
		battle.set_player_input(Vector2.ZERO, Vector2.RIGHT)
		battle.use_action("attack")
		check(battle.units[0].hp == 100.0, "basic strike respects facing")

	var early_two_wins := 0
	var late_five_wins := 0
	for seed_number in Calibration.SEEDS:
		for count in [1, 2, 5]:
			var early := Calibration.run(Profiles.EARLY, count, seed_number, "retreat_skills")
			var late := Calibration.run(Profiles.LATE, count, seed_number, "retreat_skills")
			check(early == Calibration.run(Profiles.EARLY, count, seed_number, "retreat_skills"), "early full trace repeats")
			check(late == Calibration.run(Profiles.LATE, count, seed_number, "retreat_skills"), "late full trace repeats")
			check(early.distance_moved > 0 and early.accepted_actions.attack > 0, "early policy uses movement and actual attacks")
			check(early.accepted_actions.sweep > 0 and early.accepted_actions.lunge > 0, "early policy uses actual skills")
			if count == 1:
				check(early.outcome == "victory", "early one-enemy operation space")
			elif count == 2:
				early_two_wins += 1 if early.outcome == "victory" else 0
			elif count == 5:
				check(early.outcome == "dead", "early cannot charge through five under this policy")
				late_five_wins += 1 if late.outcome == "victory" else 0
				check(late.kills > early.kills, "late offense matters without more HP")
		for profile_id in Profiles.gameplay_ids():
			var ten := Calibration.focused_contact(profile_id, 10, seed_number, false)
			var guarded_ten := Calibration.focused_contact(profile_id, 10, seed_number, true)
			var thirty := Calibration.focused_contact(profile_id, 30, seed_number, true)
			check(ten.scheduled_attacks == 10 and ten.ended and ten.player_hp == 0.0, "ten actual ordinary attacks are lethal")
			check(guarded_ten.scheduled_attacks == 10 and guarded_ten.player_hp > 0.0 and guarded_ten.player_hp < 40.0, "guard costs real HP under focused hits")
			for count in [10, 30]:
				var surround := Calibration.organized_surround(profile_id, count, seed_number)
				check(surround.ended and surround.player_hp == 0.0, "separated ordinary soldiers close in and kill stationary guarded hero")
			check(thirty.scheduled_attacks == 30 and thirty.ended and thirty.player_hp == 0.0, "thirty queued attacks remain lethal during guard")
	check(early_two_wins == Calibration.SEEDS.size(), "early two-enemy wins are reproducible for this input policy")
	check(late_five_wins == Calibration.SEEDS.size(), "late five-enemy wins are reproducible for this input policy")
	print("COMBAT_CALIBRATION_TESTS " + JSON.stringify({"checks": checks, "failures": failures}))
	quit(0 if failures.is_empty() else 1)
