class_name WoundCare
extends RefCounted
## Battle HP already persists. This module exposes its actual sources and adds
## paid, whole-hour convalescence, not a second damage debt or permanent disability.
const REVISION := 1
const HP_PER_HOUR := 5.0
const MAX_HOURS := 6
const S := preload("res://scripts/campaign_schema.gd")

static func sources(state: Dictionary) -> Array:
	var result: Array = []
	for e in state.events:
		if e.kind != "battle_committed": continue
		var t: Dictionary = state.battle_tickets[e.details.battle_id]
		var before: float = t.reserved_roster_snapshot[0][0].hp
		var loss: float = before - t.outcome.player_hp
		if loss > 0.0:
			result.append({"battle_id": t.battle_id, "at": e.time_seconds, "hp_before": before,
				"hp_after": t.outcome.player_hp, "loss": loss, "result": t.outcome.result})
	return result

static func planned_hours(world: RefCounted, requested: int) -> int:
	var s: Dictionary = world._state
	var healing := ceili((s.commander.max_hp - s.commander.hp) / HP_PER_HOUR)
	# Full rations first clear existing hunger; the final fed hour can heal.
	var feeding := maxi(0, ceili(float(s.armies.relief.condition.hunger) / 1000.0) - 1)
	return mini(requested, healing + feeding)

static func reason(world: RefCounted, hours: int = 1) -> String:
	var s: Dictionary = world._state
	if hours < 1 or hours > MAX_HOURS: return "invalid_duration"
	if s.campaign_ended or not s.commander.alive: return "campaign_ended"
	if s.mode == "youth" and s.youth.stage in ["endpoint", "ended"]: return "slice_ended"
	if not s.battle_locks.is_empty(): return "active_battle"
	if not s.armies.relief.march.is_empty(): return "marching"
	if world._condition_activity("relief") != "rest": return "unsafe_location"
	if s.siege.active and s.armies.relief.location == s.siege.city: return "besieged_location"
	if s.commander.hp >= s.commander.max_hp: return "unwounded"
	if sources(s).is_empty(): return "no_battle_injury"
	if s.armies.relief.food < planned_hours(world, hours) * world._military_food_need(s.armies.relief.soldiers): return "insufficient_rations"
	return ""

static func view(world: RefCounted) -> Dictionary:
	var s: Dictionary = world._state
	var recovered := 0.0
	var seconds := 0.0
	for e in s.events:
		if e.kind == "wound_rest_completed":
			recovered += e.details.healed
			seconds += e.time_seconds - e.details.started_at
	return {"hp": s.commander.hp, "max_hp": s.commander.max_hp,
		"deficit": s.commander.max_hp - s.commander.hp, "sources": sources(s),
		"recovered": recovered, "rest_hours": seconds / 3600.0, "rest_seconds": seconds, "hp_per_hour": HP_PER_HOUR,
		"ration_per_hour": world._military_food_need(s.armies.relief.soldiers),
		"reason": reason(world), "six_hour_reason": reason(world, MAX_HOURS)}

static func event_shape(kind: String, d: Dictionary) -> bool:
	if not S.integer(d.get("revision"), REVISION, REVISION): return false
	if kind == "wound_rest_started":
		return S.keys(d, ["revision", "location", "hp", "rations"]) and d.location is String and d.location in ["pingling", "hequ", "anping"] and S.number(d.hp, 0.00001, 360.0) and S.integer(d.rations, 1, S.MAX_PEOPLE)
	if kind == "wound_rest_completed":
		return S.keys(d, ["revision", "started_at", "hp_before", "hp_after", "healed", "reason"]) and S.number(d.started_at) and S.number(d.hp_before, 0.00001, 360.0) and S.number(d.hp_after, 0.0, 360.0) and S.number(d.healed, 0.0, HP_PER_HOUR) and d.reason is String and d.reason in ["rested", "hungry", "interrupted"]
	return false

static func describe(v: Dictionary) -> String:
	var text := "战后伤情 / 生命 %.1f / %.1f，尚缺 %.1f。休养累计恢复 %.1f。" % [v.hp, v.max_hp, v.deficit, v.recovered]
	if v.sources.is_empty(): text += "\n尚无已结算的战斗伤害。"
	else:
		for injury in v.sources.slice(maxi(0, v.sources.size() - 4)):
			text += "\n战斗 %s：入场 %.1f → 结算 %.1f，本战受伤 %.1f。" % [injury.battle_id, injury.hp_before, injury.hp_after, injury.loss]
	text += "\n每完整小时最多恢复 5 点，照常消耗本队 %d 份军粮；世界、信使与战争继续。连续休养满一小时才回血；仍饥饿时只休整。旧时段的行军或战斗疲劳照常计算。无额外攻速或移动惩罚，不复活阵亡者。" % v.ration_per_hour
	if v.reason != "": text += "\n" + reason_text(v.reason)
	return text

static func reason_text(value: String) -> String:
	return {"campaign_ended": "本局已结束，不能休养或复活。", "slice_ended": "本段已结局；可读旧档继续。", "active_battle": "先结算当前战斗。", "marching": "行军中不能休养。", "unsafe_location": "须在友方驻地且无敌军威胁。", "besieged_location": "围城中无法安全休养。", "unwounded": "生命完整，无需休养。", "no_battle_injury": "没有可追溯的战斗伤情。", "insufficient_rations": "携带军粮不足，不能预约这段休养。", "invalid_duration": "每次休养须为一至六小时。"}.get(value, value)
