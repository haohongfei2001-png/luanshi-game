extends RefCounted
## Pure read-only contract. Never starts/releases attacks or writes Unit fields.
## No idle, hit, guard, death, mount, skill or other-weapon clips exist here.
const Battle = preload("res://scripts/field/battle.gd")
const Arms = preload("res://scripts/field/arms.gd")
const WALK_SECONDS := 1.3333333333333333

static func sample(unit, vehicle: int, walk_phase: float, thrust_peak: float = -1.0) -> Dictionary:
	var result := {"supported":false,"reason":"unsupported_state","clip":"","phase":0.0}
	if vehicle != 0 or unit.mounted:
		result.reason = "mounted_without_clip"
	elif unit.flash > 0.0:
		result.reason = "hit_reaction_without_clip"
	elif unit.kit != Arms.Kit.SPEAR:
		result.reason = "weapon_without_clip"
	elif unit.state == Battle.State.MARCH:
		if unit.pos.distance_squared_to(unit.before) <= 0.00000001:
			result.reason = "idle_without_clip"
		elif (unit.pos-unit.before).normalized().dot(unit.facing.normalized()) < 0.98:
			result.reason = "strafe_or_backward_without_clip"
		elif unit.facing_before.length_squared() > 0.0 and unit.facing_before.normalized().dot(unit.facing.normalized()) < 0.98:
			result.reason = "turn_without_clip"
		elif unit.visual_run:
			result.reason = "run_without_clip"
		else:
			result = {"supported":true,"reason":"walk_only","clip":"walk","phase":fposmod(walk_phase,1.0)}
	elif unit.state in [Battle.State.WINDUP,Battle.State.RECOVER]:
		if unit.move_slot != 0 or unit.stock_strike or unit.charging_strike:
			result.reason = "skill_or_alternate_strike_without_clip"
		elif not is_finite(thrust_peak) or thrust_peak <= 0.0 or thrust_peak >= 1.0:
			result.reason = "thrust_peak_evidence_missing"
		elif unit.duration <= 0.0:
			result.reason = "invalid_state_duration"
		else:
			var progress := clampf(1.0-unit.timer/unit.duration,0.0,1.0)
			# Author extension peak coincides with authoritative release, not a new hit.
			var phase := progress*thrust_peak if unit.state == Battle.State.WINDUP else lerpf(thrust_peak,1.0,progress)
			result = {"supported":true,"reason":"ordinary_single_thrust_only","clip":"thrust","phase":phase}
	return result
