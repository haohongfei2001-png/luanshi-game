class_name CourierOrders
extends RefCounted
## A bounded physical exchange, not another guaranteed report queue.
## All time is WorldSim seconds. Lost supplies remain an inaccessible road cache.
const TRAVEL := 10800.0
const DEPART_DELAY := 3600.0
const REPLY_WINDOW := 7200.0
const RATIONS := 10
const LIMIT := 2
const ACTIVE := ["queued", "outbound", "awaiting_reply", "returning"]
const FIELDS := ["id", "stage", "issuer", "recipient", "authority", "payload", "route", "issued_at", "depart_at", "due_at", "meal_at", "food", "status", "delivered_at", "reply", "reply_at", "camp_received_at", "known", "known_at"]

static func initial(id: int, stage: String, at: float) -> Dictionary:
	return {"id": id, "stage": stage, "issuer": "officer_qiao", "recipient": "relief", "authority": "camp_superior", "payload": "return_and_report", "route": "river", "issued_at": at, "depart_at": at + DEPART_DELAY, "due_at": at + DEPART_DELAY, "meal_at": at + 3600.0, "food": RATIONS, "status": "queued", "delivered_at": -1.0, "reply": "", "reply_at": -1.0, "camp_received_at": -1.0, "known": "arranged", "known_at": at}

static func shape(value: Variant) -> bool:
	if not value is Array or value.size() > LIMIT: return false
	for c in value:
		if not _keys(c, FIELDS): return false
		if not c.id is int or c.id < 1 or c.id > LIMIT or not c.food is int or c.food < 0 or c.food > RATIONS: return false
		for f in ["stage", "issuer", "recipient", "authority", "payload", "route", "status", "reply", "known"]:
			if not c[f] is String: return false
		for f in ["issued_at", "depart_at", "due_at", "meal_at", "delivered_at", "reply_at", "camp_received_at", "known_at"]:
			if not c[f] is float or not is_finite(c[f]) or c[f] < -1.0 or c[f] > 31557600000.0: return false
		if c.stage not in ["first_orders", "dangerous_orders"] or c.issuer != "officer_qiao" or c.recipient != "relief" or c.authority != "camp_superior" or c.payload != "return_and_report" or c.route != "river": return false
		if c.status not in ACTIVE + ["returned", "lost"] or c.reply not in ["", "comply", "refuse", "not_found", "no_response"] or c.known not in ["arranged", "delivered", "reply_sent", "camp_confirmed"]: return false
	return true

static func next_boundary(state: Dictionary, target: float) -> float:
	for c in state.couriers:
		if c.status in ACTIVE:
			target = minf(target, minf(c.due_at, c.meal_at))
	return target

static func available(state: Dictionary) -> bool:
	if state.mode != "youth" or state.campaign_ended or not state.battle_locks.is_empty() or state.youth.stage not in ["first_orders", "dangerous_orders"]: return false
	if state.armies.relief.location != "pingling" or state.cities.pingling.owner != "sheng" or state.cities.pingling.soldiers < 1 or state.cities.pingling.food < RATIONS: return false
	if state.couriers.size() >= LIMIT: return false
	for c in state.couriers:
		if c.stage == state.youth.stage or c.status in ACTIVE: return false
	return true

static func dispatch(state: Dictionary) -> bool:
	if not available(state): return false
	var c := initial(state.couriers.size() + 1, state.youth.stage, state.time_seconds)
	state.cities.pingling.soldiers -= 1
	state.cities.pingling.food -= RATIONS
	state.couriers.append(c)
	_event(state, "dispatch", c, c.stage)
	return true

static func tick(state: Dictionary) -> void:
	var now: float = state.time_seconds
	for c in state.couriers:
		if c.status not in ACTIVE: continue
		# Pay for each complete hour actually carried, before movement at the same instant.
		if c.meal_at <= now:
			if c.food == 0:
				_lose(state, c, "starvation")
				continue
			c.food -= 1
			c.meal_at += 3600.0
			state.ledger.food_consumed += 1
			state.ledger.food_consumed_military += 1
			_event(state, "meal", c)
		if c.due_at > now: continue
		match c.status:
			"queued":
				c.status = "outbound"
				c.due_at = now + TRAVEL
				_event(state, "depart", c)
			"outbound":
				# Enemy control matters only at the physical endpoint, not along the whole river.
				if _hostile_contact(state):
					_lose(state, c, "hequ_perimeter")
				elif _recipient_here(state):
					c.status = "awaiting_reply"
					c.delivered_at = now
					c.due_at = now + REPLY_WINDOW
					c.known = "delivered"
					c.known_at = now
					_event(state, "deliver", c)
				else:
					_return(state, c, "not_found")
			"awaiting_reply": _return(state, c, "no_response")
			"returning":
				if state.cities.pingling.owner != "sheng":
					_lose(state, c, "camp_captured")
				else:
					state.cities.pingling.soldiers += 1
					state.cities.pingling.food += c.food
					c.food = 0
					c.status = "returned"
					c.camp_received_at = now
					_event(state, "return", c)
	observe(state)

static func _recipient_here(state: Dictionary) -> bool:
	return state.armies.relief.location == "hequ" and state.armies.relief.soldiers > 0 and state.commander.alive

static func _hostile_contact(state: Dictionary) -> bool:
	# A co-located living patrol screens its own rendezvous outside the walls.
	return state.cities.hequ.owner != "sheng" and state.cities.hequ.soldiers > 0 and not _recipient_here(state)

static func reply(state: Dictionary, response: String) -> bool:
	if state.campaign_ended or not state.battle_locks.is_empty() or response not in ["comply", "refuse"] or not _recipient_here(state): return false
	for c in state.couriers:
		if c.status == "awaiting_reply":
			_return(state, c, response)
			return true
	return false

static func _return(state: Dictionary, c: Dictionary, response: String) -> void:
	c.status = "returning"
	c.reply = response
	c.reply_at = state.time_seconds
	c.due_at = state.time_seconds + TRAVEL
	if response in ["comply", "refuse"]:
		c.known = "reply_sent"
		c.known_at = state.time_seconds
	_event(state, "reply", c, response)

static func _lose(state: Dictionary, c: Dictionary, cause: String) -> void:
	c.status = "lost"
	state.ledger.dead += 1
	if cause == "starvation": state.ledger.starvation_dead += 1
	_event(state, "lost", c, cause)

static func observe(state: Dictionary) -> void:
	if state.armies.relief.location != "pingling" or not state.commander.alive: return
	for c in state.couriers:
		if c.status == "returned" and c.known != "camp_confirmed":
			c.known = "camp_confirmed"
			c.known_at = state.time_seconds
			_event(state, "observe", c)

static func view(state: Dictionary) -> Array:
	var result: Array = []
	for c in state.couriers:
		var expected: float = c.issued_at + DEPART_DELAY + TRAVEL
		var overdue: bool = state.time_seconds > (c.reply_at + TRAVEL if c.known == "reply_sent" else expected + REPLY_WINDOW) and c.known != "camp_confirmed"
		# Only copies of facts personally arranged/received/sent/confirmed are exposed.
		result.append({"id": c.id, "issuer": "乔队正", "recipient": "外出巡队", "payload": "回营呈报", "issued_at": c.issued_at, "expected_at": expected, "known": c.known, "known_at": c.known_at, "overdue": overdue, "reply": c.reply if c.known in ["reply_sent", "camp_confirmed"] else "", "can_reply": c.known == "delivered" and c.status == "awaiting_reply" and _recipient_here(state) and state.battle_locks.is_empty() and not state.campaign_ended})
	return result

static func _event(state: Dictionary, action: String, c: Dictionary, value: String = "") -> void:
	state.events.append({"hour": state.hour, "time_seconds": state.time_seconds, "kind": "courier", "details": {"action": action, "id": c.id, "value": value}})

static func _keys(value: Variant, fields: Array) -> bool:
	if not value is Dictionary or value.size() != fields.size(): return false
	for f in fields:
		if not value.has(f): return false
	return true

static func validate(state: Dictionary) -> bool:
	## Replay transport independently. No saved authority, fate or receipt is trusted.
	var replay: Array = []
	var stage := ""
	var location := "pingling"
	var hequ_owner := "bei"
	var camp_owner := "sheng"
	var enemy_people := 15
	var alive := true
	var last_wait := -1.0
	for e in state.events:
		var d: Dictionary = e.details
		match e.kind:
			"youth_transition":
				match d.action:
					"start": stage = "first_orders"
					"first_march": stage = "first_battle"
					"dangerous_march": stage = "dangerous_battle"
					"accept_appointment", "camp_appraisal", "appraisal_accept", "appraisal_decline": stage = "dangerous_orders"
					_: stage = "other"
			"march_started": location = ""
			"arrival":
				if d.owner == "sheng": location = d.location
			"city_captured":
				if d.city == "hequ":
					hequ_owner = d.owner
					enemy_people -= d.prisoners
				if d.city == "pingling": camp_owner = d.owner
			"troops_lost":
				if d.entity == "hequ": enemy_people -= d.dead
			"battle_committed":
				for f in d.forces:
					if f.force_id == "hequ": enemy_people -= f.dead_ids.size()
			"campaign_ended": alive = false
			"courier_wait":
				if not _keys(d, ["started_at"]) or not d.started_at is float or d.started_at < 0.0 or d.started_at < last_wait or e.time_seconds - d.started_at > 3600.000001 or e.time_seconds <= d.started_at or replay.is_empty(): return false
				last_wait = e.time_seconds
			"courier":
				if not _keys(d, ["action", "id", "value"]) or not d.action is String or not d.value is String or not d.id is int or d.id < 1: return false
				var now: float = e.time_seconds
				if d.action == "dispatch":
					if d.id != replay.size() + 1 or replay.size() >= LIMIT or stage not in ["first_orders", "dangerous_orders"] or d.value != stage or location != "pingling" or camp_owner != "sheng" or not alive: return false
					for old in replay:
						if old.stage == stage or old.status in ACTIVE: return false
					replay.append(initial(d.id, stage, now))
					continue
				if d.id > replay.size(): return false
				var c: Dictionary = replay[d.id - 1]
				# Every complete carried hour is paid before a simultaneous movement or fate.
				if c.status in ACTIVE and d.action != "meal" and not (d.action == "lost" and d.value == "starvation") and c.meal_at <= now: return false
				match d.action:
					"meal":
						if c.status not in ACTIVE or now != c.meal_at or c.food <= 0 or d.value != "": return false
						c.food -= 1
						c.meal_at += 3600.0
					"depart":
						if c.status != "queued" or now != c.due_at or d.value != "": return false
						c.status = "outbound"
						c.due_at = now + TRAVEL
					"deliver":
						if c.status != "outbound" or now != c.due_at or location != "hequ" or not alive or d.value != "": return false
						c.status = "awaiting_reply"
						c.delivered_at = now
						c.due_at = now + REPLY_WINDOW
						c.known = "delivered"
						c.known_at = now
					"reply":
						if d.value in ["comply", "refuse"]:
							if c.status != "awaiting_reply" or location != "hequ" or not alive or now < c.delivered_at or now >= c.due_at: return false
							c.known = "reply_sent"
							c.known_at = now
						elif d.value == "no_response":
							if c.status != "awaiting_reply" or now != c.due_at: return false
						elif d.value == "not_found":
							if c.status != "outbound" or now != c.due_at or (location == "hequ" and alive) or (hequ_owner != "sheng" and enemy_people > 0): return false
						else: return false
						c.status = "returning"
						c.reply = d.value
						c.reply_at = now
						c.due_at = now + TRAVEL
					"return":
						if c.status != "returning" or now != c.due_at or camp_owner != "sheng" or d.value != "": return false
						c.status = "returned"
						c.food = 0
						c.camp_received_at = now
					"lost":
						if d.value == "starvation":
							if c.status not in ACTIVE or c.food != 0 or now != c.meal_at: return false
						elif d.value == "hequ_perimeter":
							if c.status != "outbound" or now != c.due_at or hequ_owner == "sheng" or enemy_people <= 0 or (location == "hequ" and alive): return false
						elif d.value == "camp_captured":
							if c.status != "returning" or now != c.due_at or camp_owner == "sheng": return false
						else: return false
						c.status = "lost"
					"observe":
						if c.status != "returned" or c.known == "camp_confirmed" or location != "pingling" or not alive or d.value != "": return false
						c.known = "camp_confirmed"
						c.known_at = now
					_: return false
	if replay != state.couriers: return false
	for c in replay:
		if c.status in ACTIVE and (c.due_at <= state.time_seconds or c.meal_at <= state.time_seconds): return false
	return true
