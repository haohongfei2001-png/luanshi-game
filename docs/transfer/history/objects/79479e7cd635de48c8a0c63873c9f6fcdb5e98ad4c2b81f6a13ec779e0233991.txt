class_name HeroCombatProfiles
extends RefCounted
## Immutable versioned combat snapshots. CombatGrowth owns earned transitions.
## Released IDs must never change meaning; tuning creates a new ID/revision.
## OWNER-03 approves the direction; these exact values are provisional calibration.
## Enemy count is deliberately not an input. Ordinary soldiers remain unchanged.

const REVISION := 1
const EARLY := "early_v1"
const PRACTICED := "practiced_v1"
const LATE := "late_v1"
const LEGACY := "legacy_test_v0"
const GAMEPLAY_HP_CAP := 100.0
const PROFILES := {
	EARLY: {
		"id": EARLY, "revision": REVISION, "test_only": false,
		"max_hp": 100.0, "speed": 3.0, "damage": 18.0, "range": 1.9,
		"attack_cooldown": 0.72, "attack_min_dot": 0.25, "attack_targets": 1,
		"sweep_cooldown": 5.0, "sweep_damage": 26.0, "sweep_range": 2.4,
		"sweep_min_dot": -0.15, "sweep_targets": 2,
		"lunge_cooldown": 7.0, "lunge_damage": 34.0, "lunge_distance": 2.6,
		"lunge_radius": 0.9, "lunge_targets": 2,
		"guard_cooldown": 9.0, "guard_duration": 1.0, "guard_incoming_factor": 0.5,
	},
	PRACTICED: {
		"id": PRACTICED, "revision": REVISION, "test_only": false,
		"max_hp": 100.0, "speed": 3.0, "damage": 21.0, "range": 1.9,
		"attack_cooldown": 0.66, "attack_min_dot": 0.25, "attack_targets": 1,
		"sweep_cooldown": 5.0, "sweep_damage": 30.0, "sweep_range": 2.4,
		"sweep_min_dot": -0.15, "sweep_targets": 2,
		"lunge_cooldown": 7.0, "lunge_damage": 38.0, "lunge_distance": 2.6,
		"lunge_radius": 0.9, "lunge_targets": 2,
		"guard_cooldown": 9.0, "guard_duration": 1.0, "guard_incoming_factor": 0.5,
	},
	LATE: {
		"id": LATE, "revision": REVISION, "test_only": false,
		"max_hp": 100.0, "speed": 3.0, "damage": 42.0, "range": 2.8,
		"attack_cooldown": 0.42, "attack_min_dot": 0.25, "attack_targets": 1,
		"sweep_cooldown": 4.0, "sweep_damage": 78.0, "sweep_range": 3.7,
		"sweep_min_dot": -0.35, "sweep_targets": 5,
		"lunge_cooldown": 5.0, "lunge_damage": 84.0, "lunge_distance": 4.2,
		"lunge_radius": 1.2, "lunge_targets": 4,
		"guard_cooldown": 9.0, "guard_duration": 1.0, "guard_incoming_factor": 0.5,
	},
	LEGACY: {
		"id": LEGACY, "revision": 0, "test_only": true,
		"max_hp": 360.0, "speed": 7.0, "damage": 26.0, "range": 3.1,
		"attack_cooldown": 0.55, "attack_min_dot": 0.25, "attack_targets": 0,
		"sweep_cooldown": 5.0, "sweep_damage": 44.0, "sweep_range": 4.4,
		"sweep_min_dot": -0.35, "sweep_targets": 0,
		"lunge_cooldown": 7.0, "lunge_damage": 58.0, "lunge_distance": 5.8,
		"lunge_radius": 1.8, "lunge_targets": 0,
		"guard_cooldown": 9.0, "guard_duration": 2.6, "guard_incoming_factor": 0.25,
	},
}

static func get_profile(profile_id: String) -> Dictionary:
	## Unknown IDs must fail closed at the integration boundary; never become legacy.
	return PROFILES.get(profile_id, {}).duplicate(true)

static func starting_ids() -> Array[String]:
	return [EARLY, LATE, LEGACY]

# Existing calibration/preview set is stable; earned profiles are tested separately.
static func gameplay_ids() -> Array[String]:
	return [EARLY, LATE]

static func profile_reference(profile_id: String) -> Dictionary:
	var profile := get_profile(profile_id)
	return {} if profile.is_empty() else {"id": profile.id, "revision": profile.revision}

static func valid_reference(value: Variant) -> bool:
	return value is Dictionary and value.size() == 2 and value.get("id") is String and value.get("revision") is int and PROFILES.has(value.id) and value.revision == PROFILES[value.id].revision

static func from_reference(value: Variant) -> Dictionary:
	return get_profile(value.id) if valid_reference(value) else {}
