class_name HometownMessages
extends RefCounted
## One replaceable Pingling resident, a subset of existing civilians, never added manpower.
## Life is a deterministic projection of local observations and the unified clock.
## Only physically carried or personally observed snapshots enter the player's view.
const REVISION := 1
const VISIT_STAGES := ["appointment", "dangerous_orders", "replenishment"]
const PERSON := "pingling_neighbor_v1"

static func record(state: Dictionary) -> Dictionary:
	var result := {"courier_id": 0, "requested_at": -1.0, "letter": {}, "received_at": -1.0, "via": "", "visit": {}}
	for e in state.events:
		match e.kind:
			"hometown_attach":
				result.courier_id = e.details.courier_id
				result.requested_at = e.time_seconds
			"hometown_letter": result.letter = e.details.message.duplicate(true)
			"hometown_received":
				result.received_at = e.time_seconds
				result.via = e.details.via
			"hometown_visit": result.visit = e.details.duplicate(true)
	return result

static func active(state: Dictionary) -> bool:
	return state.mode == "youth" and not state.campaign_ended and state.youth.stage != "endpoint"

static func can_attach(state: Dictionary) -> bool:
	if not active(state) or not state.battle_locks.is_empty() or state.armies.relief.location != "pingling" or state.cities.pingling.owner != "sheng" or record(state).courier_id != 0: return false
	for c in state.couriers:
		if c.status == "queued": return true
	return false

static func can_visit(state: Dictionary) -> bool:
	return active(state) and state.battle_locks.is_empty() and state.youth.stage in VISIT_STAGES and state.armies.relief.location == "pingling" and state.armies.relief.march.is_empty() and state.cities.pingling.owner == "sheng" and record(state).visit.is_empty()

static func attach(state: Dictionary) -> bool:
	if not can_attach(state): return false
	for c in state.couriers:
		if c.status == "queued":
			_event(state, "hometown_attach", {"revision": REVISION, "courier_id": c.id})
			return true
	return false

static func _context() -> Dictionary:
	return {"owner": "sheng", "shortfall": false, "ended_at": -1.0}

static func _observe_event(ctx: Dictionary, e: Dictionary, tickets: Dictionary) -> void:
	if ctx.ended_at >= 0.0: return
	if e.kind == "city_captured" and e.details.city == "pingling": ctx.owner = e.details.owner
	if e.kind == "consumption" and e.details.entity == "pingling" and e.details.consumer == "civilian": ctx.shortfall = e.details.shortfall > 0
	if e.kind == "youth_transition" and e.details.action == "battle":
		var ticket: Dictionary = tickets.get(e.details.data.get("battle_id"), {})
		if ticket.get("purpose") == "first_battle" and ticket.get("status") == "committed":
			if ticket.outcome.result != "victory" and ticket.outcome.forces[1].dead_ids.is_empty(): ctx.ended_at = e.time_seconds
	if e.kind == "campaign_ended" or (e.kind == "youth_transition" and e.details.action in ["refuse_order", "finish_without_replacements", "replenish", "unavailable"]): ctx.ended_at = e.time_seconds

static func _fact(ctx: Dictionary, at: float) -> Dictionary:
	# Shift hours are a provisional compressed scenario schedule, not a full life simulator.
	var hour := posmod(floori(at / 3600.0), 24)
	var activity := "workshop"
	var basis := "work_shift"
	if ctx.owner != "sheng":
		activity = "sheltering"; basis = "local_takeover"
	elif ctx.shortfall:
		activity = "ration_queue"; basis = "civilian_shortfall"
	elif hour >= 4 and hour < 8 or hour >= 16:
		activity = "caregiving"; basis = "family_duty"
	return {"person_id": PERSON, "location": "pingling", "observed_at": at, "activity": activity, "basis": basis, "can_meet": activity == "workshop"}

static func truth(state: Dictionary) -> Dictionary:
	## Privileged model/test projection. Never send this directly to the UI.
	var ctx := _context()
	for e in state.events: _observe_event(ctx, e, state.battle_tickets)
	return _fact(ctx, state.time_seconds if ctx.ended_at < 0.0 else ctx.ended_at)

static func tick(state: Dictionary) -> void:
	if not active(state): return
	var r := record(state)
	if r.courier_id == 0: return
	var c: Dictionary = state.couriers[r.courier_id - 1]
	if r.letter.is_empty() and c.status == "outbound" and c.depart_at == state.time_seconds:
		_event(state, "hometown_letter", {"revision": REVISION, "courier_id": c.id, "message": truth(state)})
		r = record(state)
	if not r.letter.is_empty() and r.received_at < 0.0:
		if c.known == "delivered" and c.delivered_at == state.time_seconds:
			_event(state, "hometown_received", {"revision": REVISION, "courier_id": c.id, "via": "handed_over"})
		elif c.known == "camp_confirmed" and c.known_at == state.time_seconds:
			_event(state, "hometown_received", {"revision": REVISION, "courier_id": c.id, "via": "camp_return"})

static func finish_visit(state: Dictionary, started: float) -> void:
	var observation := {}
	var outcome := "interrupted"
	if active(state) and state.armies.relief.location == "pingling" and state.armies.relief.march.is_empty() and state.cities.pingling.owner == "sheng":
		observation = truth(state)
		outcome = "met" if observation.can_meet else "left_notice"
	_event(state, "hometown_visit", {"revision": REVISION, "started_at": started, "outcome": outcome, "observation": observation})

static func view(state: Dictionary) -> Dictionary:
	var r := record(state)
	var result := {"requested": r.courier_id != 0, "requested_at": r.requested_at, "received_at": r.received_at, "message": {}, "overdue": false, "visit": r.visit}
	if r.received_at >= 0.0: result.message = r.letter.duplicate(true)
	# A missed expectation reveals neither the actual letter nor the carrier's fate.
	var at: float = truth(state).observed_at
	result.overdue = r.courier_id != 0 and r.received_at < 0.0 and at > r.requested_at + 21600.0
	return result

static func _event(state: Dictionary, kind: String, data: Dictionary) -> void:
	state.events.append({"hour": state.hour, "time_seconds": state.time_seconds, "kind": kind, "details": data})

static func _keys(d: Variant, fields: Array) -> bool:
	if not d is Dictionary or d.size() != fields.size(): return false
	for f in fields:
		if not d.has(f): return false
	return true

static func fact_shape(d: Variant) -> bool:
	return _keys(d, ["person_id", "location", "observed_at", "activity", "basis", "can_meet"]) and d.person_id is String and d.location is String and d.observed_at is float and is_finite(d.observed_at) and d.observed_at >= 0.0 and d.activity is String and d.basis is String and d.can_meet is bool

static func event_shape(kind: String, d: Variant) -> bool:
	if not d is Dictionary or not d.get("revision") is int or d.revision != REVISION: return false
	if kind == "hometown_visit":
		return _keys(d, ["revision", "started_at", "outcome", "observation"]) and d.started_at is float and is_finite(d.started_at) and d.started_at >= 0.0 and d.outcome is String and d.observation is Dictionary and (d.observation.is_empty() or fact_shape(d.observation))
	var fields := ["revision", "courier_id"]
	if kind == "hometown_letter": fields.append("message")
	elif kind == "hometown_received": fields.append("via")
	elif kind != "hometown_attach": return false
	if not _keys(d, fields) or not d.courier_id is int or d.courier_id < 1 or d.courier_id > 2: return false
	return (kind != "hometown_letter" or fact_shape(d.message)) and (kind != "hometown_received" or d.via is String)

static func validate(state: Dictionary) -> bool:
	# Replay local observations and transport hooks; missing automatic snapshots/receipts
	# fail as well as invented ones. The carrier's underlying travel has its own audit.
	var ctx := _context()
	var attached := 0
	var letter := false
	var received := false
	var visited := false
	var location := "pingling"
	var stage := ""
	var queued := {}
	var pending: Array = []
	var last_at := 0.0
	var visit_start_stage := ""
	for e in state.events:
		var d: Dictionary = e.details
		if not pending.is_empty() and e.time_seconds != pending[0].at: return false
		if e.kind == "march_started": location = ""
		elif e.kind == "arrival" and d.owner == "sheng": location = d.location
		elif e.kind == "youth_transition":
			match d.action:
				"start": stage = "first_orders"
				"first_march": stage = "first_battle"
				"dangerous_march": stage = "dangerous_battle"
				"battle": stage = "first_return" if stage == "first_battle" else "dangerous_return"
				"return_to_camp": stage = "injustice" if stage == "first_return" else "replenishment"
				"choice": stage = "appointment"
				"accept_appointment": stage = "dangerous_orders"
			last_at = e.time_seconds
			visit_start_stage = stage
		elif e.kind in ["courier_wait", "wound_rest_completed"]: last_at = e.time_seconds
		elif e.kind == "courier":
			if d.action == "dispatch": queued[d.id] = true
			if d.action == "depart": queued[d.id] = false
			if d.id == attached and ctx.ended_at < 0.0:
				if d.action == "depart": pending.append({"kind": "hometown_letter", "at": e.time_seconds, "details": {"revision": REVISION, "courier_id": attached, "message": _fact(ctx, e.time_seconds)}})
				if d.action in ["deliver", "observe"] and not received:
					pending.append({"kind": "hometown_received", "at": e.time_seconds, "details": {"revision": REVISION, "courier_id": attached, "via": "handed_over" if d.action == "deliver" else "camp_return"}})
		if e.kind.begins_with("hometown_"):
			if state.mode != "youth" or not event_shape(e.kind, d): return false
			match e.kind:
				"hometown_attach":
					if ctx.ended_at >= 0.0 or attached != 0 or location != "pingling" or ctx.owner != "sheng" or not queued.get(d.courier_id, false) or stage not in ["first_orders", "dangerous_orders"]: return false
					attached = d.courier_id
				"hometown_letter", "hometown_received":
					if pending.is_empty() or pending[0] != {"kind": e.kind, "at": e.time_seconds, "details": d}: return false
					pending.pop_front()
					if e.kind == "hometown_letter":
						if letter: return false
						letter = true
					else:
						if not letter or received: return false
						received = true
				"hometown_visit":
					if visited or d.started_at != last_at or visit_start_stage not in VISIT_STAGES: return false
					var elapsed: float = e.time_seconds - d.started_at
					if elapsed <= 0.0 or elapsed > 3600.000001 or (ctx.ended_at < 0.0 and not is_equal_approx(elapsed, 3600.0)): return false
					if ctx.ended_at >= 0.0 and (e.time_seconds != ctx.ended_at or d.started_at >= ctx.ended_at): return false
					if ctx.ended_at >= 0.0 or location != "pingling" or ctx.owner != "sheng":
						if d.observation != {} or d.outcome != "interrupted": return false
					else:
						var fact := _fact(ctx, e.time_seconds)
						if d.observation != fact or d.outcome != ("met" if fact.can_meet else "left_notice"): return false
					visited = true
					last_at = e.time_seconds
		_observe_event(ctx, e, state.battle_tickets)
	return pending.is_empty()

static func describe(v: Dictionary) -> String:
	var text := "乡里旧识 / 平陵民户中的作坊帮工（普通临时人物）\n旧识有自己的作坊与家中职责，不随你入伍，别离期间也会改变安排。"
	if v.requested:
		text += "\n已托现有传令兵顺路捎信。"
		if v.message.is_empty(): text += " 尚未亲收，近况未知。" + (" 已过预计时辰，可能延误或失联，不能确认原因。" if v.overdue else "")
		else:
			text += "\n亲收乡信：第 %.2f 时写下，第 %.2f 时收到。仅为当时所知。\n%s" % [v.message.observed_at / 3600.0, v.received_at / 3600.0, words(v.message)]
	if not v.visit.is_empty():
		if v.visit.outcome == "interrupted": text += "\n探望中断，没有获得新的近况。"
		else: text += "\n回乡探望：" + ("当面相见。" if v.visit.outcome == "met" else "旧识未能抽身，只见到留下的口信。") + words(v.visit.observation)
	return text

static func words(fact: Dictionary) -> String:
	match fact.activity:
		"workshop": return "我仍在平陵作坊帮工，趁交工可以说几句话。手上的活不能丢，也不打算跟军队离乡。"
		"caregiving": return "眼下要回家照料亲人，不能陪你长谈。别为等我误了军中的事。"
		"ration_queue": return "本地这一回民粮没有配足，我得先为家人等粮，暂时顾不上相见。"
		"sheltering": return "城中已经换旗，我先护着家人避开街面，暂不约见。"
	return "近况未知。"
