class_name CombatGrowth
extends RefCounted
## One earned offensive step, derived from settled shared experience and paid
## continuous practice. No XP currency, personal-kill claim, HP increase or heal.
const REVISION := 1
const REQUIRED_HOURS := 2
const P := preload("res://scripts/hero_combat_profiles.gd")
const S := preload("res://scripts/campaign_schema.gd")

static func initial_profile(state: Dictionary) -> Dictionary:
	# All reservations, including cancellations, preserve the profile at that instant.
	for e in state.events:
		if e.kind == "battle_reserved":
			return state.battle_tickets[e.details.battle_id].hero_profile
	return state.commander.hero_profile

static func qualified(ticket: Dictionary) -> bool:
	if ticket.status != "committed" or not ticket.outcome.player_alive or ticket.elapsed_world_time <= 0.0: return false
	if ticket.outcome.player_hp < ticket.reserved_roster_snapshot[0][0].hp: return true
	for force in ticket.outcome.forces:
		if not force.dead_ids.is_empty(): return true
	return false

static func source_battle(state: Dictionary) -> String:
	for e in state.events:
		if e.kind == "battle_committed" and qualified(state.battle_tickets[e.details.battle_id]): return e.details.battle_id
	return ""

static func completed_hours(state: Dictionary) -> int:
	var hours := 0
	for e in state.events:
		if e.kind == "combat_training_completed" and e.details.reason == "trained": hours += 1
	return hours

static func reason(world: RefCounted, hours: int = 1) -> String:
	var s: Dictionary = world._state
	if hours < 1 or hours > REQUIRED_HOURS: return "invalid_duration"
	if s.campaign_ended or not s.commander.alive: return "campaign_ended"
	if s.mode == "youth" and s.youth.stage in ["endpoint", "ended"]: return "slice_ended"
	if not s.battle_locks.is_empty(): return "active_battle"
	if not s.armies.relief.march.is_empty(): return "marching"
	if world._condition_activity("relief") != "rest": return "unsafe_location"
	if s.siege.active and s.armies.relief.location == s.siege.city: return "besieged_location"
	if s.commander.hero_profile.id == P.PRACTICED: return "already_practiced"
	if s.commander.hero_profile.id != P.EARLY: return "unsupported_profile"
	if source_battle(s).is_empty(): return "no_shared_experience"
	var planned := mini(hours, REQUIRED_HOURS - completed_hours(s))
	if s.armies.relief.food < planned * world._military_food_need(s.armies.relief.soldiers): return "insufficient_rations"
	return ""

static func view(world: RefCounted) -> Dictionary:
	var s: Dictionary = world._state
	return {"profile_id": s.commander.hero_profile.id, "hours_completed": completed_hours(s),
		"hours_required": REQUIRED_HOURS, "source_battle": source_battle(s),
		"hp": s.commander.hp, "max_hp": s.commander.max_hp,
		"reason": reason(world), "two_hour_reason": reason(world, REQUIRED_HOURS),
		"ration_per_hour": world._military_food_need(s.armies.relief.soldiers)}

static func event_shape(kind: String, d: Dictionary) -> bool:
	if not S.integer(d.get("revision"), REVISION, REVISION): return false
	if kind == "combat_training_started":
		return S.keys(d, ["revision", "source_battle", "location", "hp", "rations"]) and S.text(d.source_battle) and d.location is String and d.location in ["pingling", "hequ", "anping"] and S.number(d.hp, 0.00001, 100.0) and S.integer(d.rations, 1, S.MAX_PEOPLE)
	if kind == "combat_training_completed":
		return S.keys(d, ["revision", "source_battle", "started_at", "reason", "hours_completed", "hero_profile"]) and S.text(d.source_battle) and S.number(d.started_at) and d.reason is String and d.reason in ["trained", "hungry", "interrupted"] and S.integer(d.hours_completed, 0, REQUIRED_HOURS) and P.valid_reference(d.hero_profile)
	return false

static func validate(state: Dictionary) -> bool:
	# Called only after closed event/outcome shapes and the account audit pass.
	var profile := initial_profile(state)
	if profile.id not in P.starting_ids(): return false
	var hours := 0
	var source := ""
	var started: Dictionary = {}
	var dead := false
	for e in state.events:
		var d: Dictionary = e.details
		match e.kind:
			"battle_reserved":
				if state.battle_tickets[d.battle_id].hero_profile != profile: return false
			"battle_committed":
				if source.is_empty() and qualified(state.battle_tickets[d.battle_id]): source = d.battle_id
			"campaign_ended": dead = true
			"combat_training_started":
				if dead or not started.is_empty() or profile.id != P.EARLY or source.is_empty() or d.source_battle != source: return false
				started = {"at": e.time_seconds, "source": source}
			"combat_training_completed":
				if started.is_empty() or d.started_at != started.at or d.source_battle != source: return false
				if e.time_seconds <= started.at or e.time_seconds > started.at + 3600.0: return false
				if d.reason != "interrupted" and (dead or e.time_seconds != started.at + 3600.0): return false
				if d.reason == "trained": hours += 1
				if hours == REQUIRED_HOURS: profile = P.profile_reference(P.PRACTICED)
				if hours > REQUIRED_HOURS or d.hours_completed != hours or d.hero_profile != profile: return false
				started.clear()
	return started.is_empty() and state.commander.hero_profile == profile

static func describe(v: Dictionary) -> String:
	var text := "战后练习 / %d / %d 小时。" % [v.hours_completed, v.hours_required]
	if v.source_battle.is_empty(): text += "尚无合格的共同实战经历。"
	else: text += "经历来源：战斗 %s。" % v.source_battle
	text += "\n生还且本人受伤或任一参战方发生真实伤亡，才可学习；共同伤亡不是主角个人斩杀。安全驻地每次练习一至两小时，每小时照常消耗本队 %d 份军粮；世界、军情与信使继续。" % v.ration_per_hour
	text += "\n累计两个完整且吃饱的练习小时，只获得一阶进攻成长：普攻 18→21、横扫 26→30、突刺 34→38、普攻间隔 0.72→0.66秒。生命上限仍100，无回血，防御不变。不是后期训练档，也不是完整成长树。"
	if not v.reason.is_empty(): text += "\n" + reason_text(v.reason)
	return text

static func reason_text(value: String) -> String:
	return {"campaign_ended": "本局已结束，不能训练或复活。", "slice_ended": "本段已结局，可读旧档继续。", "active_battle": "先结算当前战斗。", "marching": "行军中不能练习。", "unsafe_location": "须在无敌军威胁的友方驻地练习。", "besieged_location": "围城中不能安全练习。", "already_practiced": "本阶段的一阶进攻成长已完成，不能重复刷取。", "unsupported_profile": "此训练只对真实早期生涯开放，不更改后期或旧测试档。", "no_shared_experience": "须先完成一次有实际受伤或伤亡、且本人存活的战斗。", "insufficient_rations": "携带军粮不足，不能预约这段练习。", "invalid_duration": "每次练习须为一至两小时。"}.get(value, value)
