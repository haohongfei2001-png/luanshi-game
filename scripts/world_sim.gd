class_name WorldSimulation
extends RefCounted
## Authoritative hourly simulation. Presentation must use player_view(), not snapshot().

const VERSION := 1
const MAX_ADVANCE := 8760
const ROUTES := {
	"road": {"from": "pingling", "to": "anping", "hours": 6},
	"mountain": {"from": "pingling", "to": "anping", "hours": 18},
	"river": {"from": "pingling", "to": "hequ", "hours": 3},
	"grain_road": {"from": "hequ", "to": "anping", "hours": 5},
}
var _state: Dictionary = {}

func _init(seed_value: int = 184) -> void:
	reset(seed_value)

func reset(seed_value: int = 184) -> void:
	_state = {
		"version": VERSION, "seed": seed_value, "hour": 0,
		"factions": {"sheng": {"name": "晟军"}, "bei": {"name": "北军"}},
		"cities": {
			"anping": _city("安平", "sheng", 40, 40, 100, 60, 0),
			"pingling": _city("平陵", "sheng", 20, 20, 500, 80, 4),
			"hequ": _city("河曲", "bei", 15, 15, 600, 20, 2),
		},
		"armies": {
			"relief": _army("sheng", "pingling", 60, 30, 120),
			"besiegers": _army("bei", "anping", 80, 70, 48),
		},
		"siege": {"city": "anping", "army": "besiegers", "active": true, "outcome": "ongoing"},
		"ledger": {"food_produced": 0, "food_consumed": 0, "weapons_produced": 0, "weapons_destroyed": 0, "dead": 0, "prisoners": 0},
		"pending_reports": [], "reports": [], "events": [], "next_report": 1,
		"convoys": [], "next_convoy": 1,
	}
	_state["initial_totals"] = totals()
	# This is an old observation, not a live view of the besieged city.
	_queue_report("anping", "安平求援使者", -72, 0, {"owner": "sheng", "under_siege": true})
	_deliver_reports()

func _city(label: String, owner: String, troops: int, weapons: int, food: int, fort: int, production: int) -> Dictionary:
	return {"name": label, "owner": owner, "soldiers": troops, "weapons": weapons, "food": food, "fort": fort, "food_per_hour": production}

func _army(owner: String, location: String, troops: int, weapons: int, food: int) -> Dictionary:
	return {"owner": owner, "location": location, "soldiers": troops, "weapons": weapons, "food": food, "march": {}, "starving_hours": 0}

func snapshot() -> Dictionary:
	## Privileged save/debug truth, never a player-facing information API.
	return _state.duplicate(true)

func player_view() -> Dictionary:
	var known: Dictionary = {}
	for report in _state.reports:
		var subject: String = report.subject
		if not known.has(subject) or report.observed_at >= known[subject].observed_at:
			known[subject] = report.duplicate(true)
	var location: String = _state.armies.relief.location
	var local_city: Dictionary = {}
	if _state.cities.has(location):
		local_city = _state.cities[location].duplicate(true)
		local_city["id"] = location
	return {"hour": _state.hour, "army": _state.armies.relief.duplicate(true), "local_city": local_city, "routes": ROUTES.duplicate(true), "reports": _state.reports.duplicate(true), "known": known}

func march(route_id: String) -> bool:
	if not ROUTES.has(route_id):
		return false
	var army: Dictionary = _state.armies.relief
	var route: Dictionary = ROUTES[route_id]
	if not army.march.is_empty() or army.soldiers <= 0:
		return false
	var destination := ""
	if army.location == route.from:
		destination = route.to
	elif army.location == route.to:
		destination = route.from
	else:
		return false
	army.march = {"route": route_id, "destination": destination, "arrives_at": _state.hour + route.hours}
	army.location = ""
	_event("march_started", {"route": route_id, "arrives_at": army.march.arrives_at})
	return true

func transfer(from_id: String, to_id: String, resource: String, amount: int) -> bool:
	## City/army inventory transfer only when co-located and allied. No remote teleporting.
	if amount <= 0 or resource not in ["food", "weapons"] or from_id == to_id:
		return false
	var source := _entity(from_id)
	var target := _entity(to_id)
	if source.is_empty() or target.is_empty() or source.owner != target.owner:
		return false
	var location := _location(from_id)
	if location == "" or location != _location(to_id) or source[resource] < amount:
		return false
	source[resource] -= amount
	target[resource] += amount
	_event("transfer", {"from": from_id, "to": to_id, "resource": resource, "amount": amount})
	return true

func seize_depot() -> bool:
	## Actual local combat: insufficient forces cannot toggle the supply line.
	var army: Dictionary = _state.armies.relief
	if army.location != "hequ" or not army.march.is_empty():
		return false
	var depot: Dictionary = _state.cities.hequ
	if depot.owner == army.owner or _strength(army) <= _strength(depot):
		return false
	var casualties := maxi(1, ceili(float(_strength(depot)) / 4.0))
	_lose_troops(army, casualties)
	_capture("hequ", army.owner)
	_event("depot_seized", {"casualties": casualties})
	return true

func observe_city(city_id: String, delay_hours: int = 0) -> bool:
	## Observation requires physical presence. Delayed content is frozen at observation time.
	if not _state.cities.has(city_id) or delay_hours < 0 or delay_hours > MAX_ADVANCE:
		return false
	if _state.armies.relief.location != city_id:
		return false
	var city: Dictionary = _state.cities[city_id]
	_queue_report(city_id, "亲历斥候", _state.hour, _state.hour + delay_hours,
		{"owner": city.owner, "soldiers": city.soldiers, "food": city.food, "fort": city.fort, "under_siege": city_id == "anping" and _state.siege.active})
	_deliver_reports()
	return true

func advance(hours: int) -> bool:
	if hours < 0 or hours > MAX_ADVANCE:
		return false
	for _tick in range(hours):
		_state.hour += 1
		_produce()
		_supply_enemy()
		_feed()
		_arrivals()
		_resolve_siege()
		_deliver_reports()
	return true

func _produce() -> void:
	for city in _state.cities.values():
		# Besieged production is interrupted. No unaccounted free supplies.
		if city == _state.cities.anping and _state.siege.active:
			continue
		city.food += city.food_per_hour
		_state.ledger.food_produced += city.food_per_hour
		if _state.hour % 24 == 0:
			city.weapons += 1
			_state.ledger.weapons_produced += 1

func _supply_enemy() -> void:
	var depot: Dictionary = _state.cities.hequ
	var army: Dictionary = _state.armies.besiegers
	# Cargo remains physical while moving, including after an army withdraws.
	for index in range(_state.convoys.size() - 1, -1, -1):
		var convoy: Dictionary = _state.convoys[index]
		if convoy.arrives_at > _state.hour:
			continue
		var destination: Dictionary = _state.cities[convoy.destination]
		if convoy.destination == "anping" and _state.siege.active and army.location == "anping" and army.owner == convoy.owner:
			army.food += convoy.food
		elif destination.owner == convoy.owner or convoy.returning:
			# Returning cargo is captured if its home depot has changed hands.
			destination.food += convoy.food
		else:
			convoy.destination = "hequ"
			convoy.departed_at = _state.hour
			convoy.arrives_at = _state.hour + ROUTES.grain_road.hours
			convoy.returning = true
			_event("convoy_returning", {"id": convoy.id, "food": convoy.food})
			continue
		_event("convoy_delivered", {"id": convoy.id, "destination": convoy.destination, "food": convoy.food})
		_state.convoys.remove_at(index)
	if not _state.siege.active or depot.owner != army.owner:
		return
	var amount := mini(8, int(depot.food))
	if amount == 0:
		return
	depot.food -= amount
	_state.convoys.append({"id": _state.next_convoy, "owner": depot.owner, "origin": "hequ", "destination": "anping", "departed_at": _state.hour, "arrives_at": _state.hour + ROUTES.grain_road.hours, "food": amount, "returning": false})
	_state.next_convoy += 1

func _feed() -> void:
	for city in _state.cities.values():
		_consume(city, ceili(float(city.soldiers) / 10.0))
	for army in _state.armies.values():
		var need := ceili(float(army.soldiers) / 10.0)
		var eaten := _consume(army, need)
		army.starving_hours = army.starving_hours + 1 if eaten < need else 0
		if army.starving_hours >= 3:
			_lose_troops(army, 1)

func _consume(entity: Dictionary, amount: int) -> int:
	var eaten := mini(amount, int(entity.food))
	entity.food -= eaten
	_state.ledger.food_consumed += eaten
	return eaten

func _arrivals() -> void:
	for army in _state.armies.values():
		if not army.march.is_empty() and army.march.arrives_at <= _state.hour:
			army.location = army.march.destination
			army.march = {}
			_event("arrival", {"owner": army.owner, "location": army.location})

func _resolve_siege() -> void:
	if not _state.siege.active:
		return
	var city: Dictionary = _state.cities.anping
	var enemy: Dictionary = _state.armies.besiegers
	var relief: Dictionary = _state.armies.relief
	if enemy.starving_hours >= 1 or enemy.soldiers <= 0:
		_end_siege("supply_retreat")
		return
	var defense := _strength(city)
	var present: bool = relief.location == "anping" and relief.owner == city.owner and relief.soldiers > 0
	if present:
		defense += _strength(relief)
	if defense >= _strength(enemy):
		if present:
			_lose_troops(relief, maxi(1, ceili(float(enemy.soldiers) / 12.0)))
		_lose_troops(enemy, maxi(1, ceili(float(defense) / 10.0)))
		_end_siege("relieved")
		return
	var pressure := maxi(1, ceili(float(_strength(enemy) - defense) / 10.0))
	city.fort = maxi(0, city.fort - pressure)
	if city.food <= 0 or city.fort <= 0 or city.soldiers <= 0:
		_capture("anping", enemy.owner)
		_end_siege("captured")

func _strength(entity: Dictionary) -> int:
	return mini(int(entity.soldiers), int(entity.weapons)) + maxi(0, int(entity.soldiers) - int(entity.weapons)) / 2

func _lose_troops(entity: Dictionary, count: int) -> void:
	var lost := mini(count, int(entity.soldiers))
	var weapons := mini(lost, int(entity.weapons))
	entity.soldiers -= lost
	entity.weapons -= weapons
	_state.ledger.dead += lost
	_state.ledger.weapons_destroyed += weapons

func _capture(city_id: String, owner: String) -> void:
	var city: Dictionary = _state.cities[city_id]
	_state.ledger.prisoners += city.soldiers
	city.soldiers = 0
	city.owner = owner
	_event("city_captured", {"city": city_id, "owner": owner})
	_queue_report(city_id, "逃出城的信使", _state.hour, _state.hour + 12, {"owner": owner, "under_siege": false})

func _end_siege(outcome: String) -> void:
	_state.siege.active = false
	_state.siege.outcome = outcome
	if outcome != "captured":
		# Retreat is real movement, not disappearance or reinforcement spawning.
		var army: Dictionary = _state.armies.besiegers
		army.location = ""
		army.march = {"route": "grain_road", "destination": "hequ", "arrives_at": _state.hour + 5}
	_event("siege_ended", {"outcome": outcome})
	_queue_report("anping", "安平军情信使", _state.hour, _state.hour + 12, {"owner": _state.cities.anping.owner, "under_siege": false, "outcome": outcome})

func _queue_report(subject: String, source: String, observed_at: int, arrives_at: int, contents: Dictionary) -> void:
	_state.pending_reports.append({"id": _state.next_report, "subject": subject, "source": source, "observed_at": observed_at, "arrives_at": arrives_at, "reported_at": -1, "confidence": 1.0, "contents": contents.duplicate(true)})
	_state.next_report += 1

func _deliver_reports() -> void:
	for index in range(_state.pending_reports.size() - 1, -1, -1):
		var report: Dictionary = _state.pending_reports[index]
		if report.arrives_at <= _state.hour:
			report.reported_at = _state.hour
			_state.reports.append(report)
			_state.pending_reports.remove_at(index)
	_state.reports.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.id < b.id)

func _event(kind: String, details: Dictionary) -> void:
	_state.events.append({"hour": _state.hour, "kind": kind, "details": details.duplicate(true)})

func _entity(id: String) -> Dictionary:
	if _state.cities.has(id):
		return _state.cities[id]
	return _state.armies.get(id, {})

func _location(id: String) -> String:
	if _state.cities.has(id):
		return id
	return _state.armies.get(id, {}).get("location", "")

func totals() -> Dictionary:
	var result := {"food": 0, "weapons": 0, "soldiers": 0}
	for entity in _state.cities.values() + _state.armies.values():
		for resource in result:
			result[resource] += entity[resource]
	for convoy in _state.convoys:
		result.food += convoy.food
	return result

func audit() -> Array[String]:
	var errors: Array[String] = []
	var total := totals()
	var initial: Dictionary = _state.initial_totals
	var ledger: Dictionary = _state.ledger
	if total.food != initial.food + ledger.food_produced - ledger.food_consumed:
		errors.append("food conservation")
	if total.weapons != initial.weapons + ledger.weapons_produced - ledger.weapons_destroyed:
		errors.append("weapon conservation")
	if total.soldiers + ledger.dead + ledger.prisoners != initial.soldiers:
		errors.append("soldier conservation")
	for entity in _state.cities.values() + _state.armies.values():
		for resource in ["food", "weapons", "soldiers"]:
			if entity[resource] < 0:
				errors.append("negative " + resource)
	for convoy in _state.convoys:
		if convoy.food <= 0 or convoy.arrives_at <= convoy.departed_at:
			errors.append("invalid convoy")
	return errors
