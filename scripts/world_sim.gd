class_name WorldSimulation
extends RefCounted
## Authoritative seconds clock with hourly economics. Presentation uses player_view().

const VERSION := 2
const Battle := preload("res://scripts/battle_sim.gd")
const BATTLE_LIMIT := 20
const MAX_ADVANCE := 8760
const ROUTES := {
	"road": {"from": "pingling", "to": "anping", "hours": 6},
	"mountain": {"from": "pingling", "to": "anping", "hours": 18},
	"river": {"from": "pingling", "to": "hequ", "hours": 3},
	"grain_road": {"from": "hequ", "to": "anping", "hours": 5},
}
var _state: Dictionary = {}
var _battle_sessions: Dictionary = {}
var _campaign_generation := 0

func _init(seed_value: int = 184) -> void:
	reset(seed_value)

func reset(seed_value: int = 184) -> void:
	_campaign_generation += 1
	_battle_sessions.clear()
	_state = {
		"version": VERSION, "seed": seed_value, "hour": 0, "time_seconds": 0.0,
		"campaign_generation": _campaign_generation, "campaign_ended": false,
		"commander": {"alive": true, "hp": 360.0, "max_hp": 360.0, "army": "relief"},
		"battle_tickets": {}, "battle_locks": {}, "next_battle": 1,
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
		if not known.has(subject) or report.observed_at_seconds >= known[subject].observed_at_seconds:
			known[subject] = report.duplicate(true)
	var location: String = _state.armies.relief.location
	var local_city: Dictionary = {}
	if _state.cities.has(location):
		local_city = _state.cities[location].duplicate(true)
		local_city["id"] = location
	return {"hour": _state.hour, "time_seconds": _state.time_seconds, "campaign_ended": _state.campaign_ended, "commander": _state.commander.duplicate(true), "active_battle": _state.battle_locks.get("relief", ""), "army": _state.armies.relief.duplicate(true), "local_city": local_city, "routes": ROUTES.duplicate(true), "reports": _state.reports.duplicate(true), "known": known}

func march(route_id: String) -> bool:
	if _state.campaign_ended or _state.battle_locks.has("relief") or not ROUTES.has(route_id):
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
	var arrival_seconds: float = _state.time_seconds + route.hours * 3600.0
	army.march = {"route": route_id, "destination": destination, "arrives_at": ceili(arrival_seconds / 3600.0), "arrives_at_seconds": arrival_seconds}
	army.location = ""
	_event("march_started", {"route": route_id, "arrives_at": army.march.arrives_at, "arrives_at_seconds": arrival_seconds})
	return true

func transfer(from_id: String, to_id: String, resource: String, amount: int) -> bool:
	## City/army inventory transfer only when co-located and allied. No remote teleporting.
	if _state.campaign_ended or _state.battle_locks.has(from_id) or _state.battle_locks.has(to_id):
		return false
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
	## Legacy deterministic aggregate scenario; interactive UI uses BattleAdapter instead.
	if _state.campaign_ended or not _state.battle_locks.is_empty():
		return false
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
	if _state.campaign_ended or not _state.cities.has(city_id) or delay_hours < 0 or delay_hours > MAX_ADVANCE:
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
	return advance_seconds(float(hours) * 3600.0)

func advance_seconds(seconds: float) -> bool:
	## Autonomous simulation API, not permission for a dead protagonist to wait.
	## The world may continue after death; presentation blocks all campaign commands.
	## Strategic time cannot also advance while a local battle owns the clock.
	if not is_finite(seconds) or seconds < 0.0 or seconds > MAX_ADVANCE * 3600.0 or not _state.battle_locks.is_empty():
		return false
	_advance_clock_to(_state.time_seconds + seconds)
	return true

func _advance_clock_to(target_seconds: float) -> void:
	while _state.time_seconds < target_seconds:
		var hour_boundary: float = (_state.hour + 1) * 3600.0
		var next_time := minf(target_seconds, hour_boundary)
		for army in _state.armies.values():
			if not army.march.is_empty():
				next_time = minf(next_time, float(army.march.arrives_at_seconds))
		for report in _state.pending_reports:
			next_time = minf(next_time, float(report.arrives_at_seconds))
		_state.time_seconds = next_time
		if next_time == hour_boundary:
			_state.hour += 1
			_produce()
			_supply_enemy()
			_feed()
			_arrivals()
			_resolve_siege()
			_deliver_reports()
		else:
			_arrivals()
			_deliver_reports()

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
			_lose_troops(army, 1, "starvation")

func _consume(entity: Dictionary, amount: int) -> int:
	var eaten := mini(amount, int(entity.food))
	entity.food -= eaten
	_state.ledger.food_consumed += eaten
	return eaten

func _arrivals() -> void:
	for army in _state.armies.values():
		if not army.march.is_empty() and army.march.arrives_at_seconds <= _state.time_seconds:
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
	var soldiers := int(entity.soldiers) - _reserved_for(entity, "soldiers")
	var weapons := int(entity.weapons) - _reserved_for(entity, "weapons")
	return mini(soldiers, weapons) + maxi(0, soldiers - weapons) / 2

func _lose_troops(entity: Dictionary, count: int, cause: String = "combat") -> void:
	var lost := mini(count, int(entity.soldiers) - _reserved_for(entity, "soldiers"))
	var weapons := mini(lost, int(entity.weapons) - _reserved_for(entity, "weapons"))
	entity.soldiers -= lost
	entity.weapons -= weapons
	_state.ledger.dead += lost
	_state.ledger.weapons_destroyed += weapons
	# Aggregate losses take ordinary soldiers first. The last actual relief person
	# is the commander; their removal cannot leave an immortal phantom character.
	if is_same(entity, _state.armies.relief) and entity.soldiers == 0 and _state.commander.alive:
		_state.commander.hp = 0.0
		_state.commander.alive = false
		_state.campaign_ended = true
		_event("campaign_ended", {"cause": cause})

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
		army.march = {"route": "grain_road", "destination": "hequ", "arrives_at": _state.hour + 5, "arrives_at_seconds": _state.time_seconds + 5 * 3600.0}
	_event("siege_ended", {"outcome": outcome})
	_queue_report("anping", "安平军情信使", _state.hour, _state.hour + 12, {"owner": _state.cities.anping.owner, "under_siege": false, "outcome": outcome})

func _queue_report(subject: String, source: String, observed_at: int, arrives_at: int, contents: Dictionary) -> void:
	var observed_seconds: float = _state.time_seconds if observed_at == _state.hour else observed_at * 3600.0
	var arrival_seconds: float = _state.time_seconds + (arrives_at - _state.hour) * 3600.0
	_state.pending_reports.append({"id": _state.next_report, "subject": subject, "source": source,
		"observed_at": observed_at, "arrives_at": ceili(arrival_seconds / 3600.0), "reported_at": -1,
		"observed_at_seconds": observed_seconds, "arrives_at_seconds": arrival_seconds, "reported_at_seconds": -1.0,
		"confidence": 1.0, "contents": contents.duplicate(true)})
	_state.next_report += 1

func _deliver_reports() -> void:
	for index in range(_state.pending_reports.size() - 1, -1, -1):
		var report: Dictionary = _state.pending_reports[index]
		if report.arrives_at_seconds <= _state.time_seconds:
			report.reported_at = _state.hour
			report.reported_at_seconds = _state.time_seconds
			_state.reports.append(report)
			_state.pending_reports.remove_at(index)
	_state.reports.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.id < b.id)

func _event(kind: String, details: Dictionary) -> void:
	_state.events.append({"hour": _state.hour, "time_seconds": _state.time_seconds, "kind": kind, "details": details.duplicate(true)})

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
	if not is_finite(float(_state.time_seconds)) or _state.hour != floori(_state.time_seconds / 3600.0):
		errors.append("clock mismatch")
	for force_id in _state.battle_locks:
		var ticket_id: String = _state.battle_locks[force_id]
		if not _state.battle_tickets.has(ticket_id) or _state.battle_tickets[ticket_id].status not in ["reserved", "running"]:
			errors.append("invalid battle lock")
			continue
		var entity := _entity(force_id)
		if entity.soldiers < _reserved_for(entity, "soldiers") or entity.weapons < _reserved_for(entity, "weapons"):
			errors.append("reservation exceeds inventory")
	if _state.commander.alive and _state.armies.relief.soldiers < 1:
		errors.append("living commander missing from army")
	if _state.campaign_ended != (not _state.commander.alive) or _state.commander.alive != (_state.commander.hp > 0.0):
		errors.append("commander life state")
	return errors


func _reserved_for(entity: Dictionary, resource: String) -> int:
	for force_id in _state.battle_locks:
		if not is_same(entity, _entity(force_id)):
			continue
		var ticket: Dictionary = _state.battle_tickets[_state.battle_locks[force_id]]
		var team: int = ticket.participating_force_ids.find(force_id)
		var roster: Array = ticket.reserved_roster_snapshot[team]
		if resource == "soldiers":
			return roster.size()
		var equipped := 0
		for soldier in roster:
			equipped += 1 if soldier.weapon != "" else 0
		return equipped
	return 0

func create_battle_ticket(location: String = "hequ") -> Dictionary:
	## Only the local Hequ depot encounter is implemented. Reserves stay in their force.
	if _state.campaign_ended:
		return _reject("campaign_ended")
	if location != "hequ":
		return _reject("unsupported_location")
	var army: Dictionary = _state.armies.relief
	var depot: Dictionary = _state.cities.hequ
	if army.location != location or not army.march.is_empty():
		return _reject("not_local")
	if not _state.battle_locks.is_empty():
		return _reject("participants_locked")
	if army.soldiers <= 0 or depot.soldiers <= 0 or depot.owner == army.owner:
		return _reject("no_hostile_force")
	var battle_id := "%d:%d" % [_state.campaign_generation, _state.next_battle]
	var rosters: Array = []
	for force_id in ["relief", "hequ"]:
		var force := _entity(force_id)
		var count := mini(BATTLE_LIMIT, int(force.soldiers))
		# Representative allocation avoids silently selecting only an armed elite.
		var armed := floori(float(mini(int(force.soldiers), int(force.weapons))) * count / force.soldiers)
		var roster: Array[Dictionary] = []
		for slot in range(count):
			var hero: bool = force_id == "relief" and slot == 0
			roster.append({"id": "commander" if hero else "%s:%s:%d" % [battle_id, force_id, slot],
				"force_id": force_id, "hero": hero, "weapon": "spear" if slot < armed else "",
				"hp": _state.commander.hp if hero else 100.0})
		rosters.append(roster)
	var ticket := {"battle_id": battle_id, "time": _state.time_seconds, "location": location,
		"participating_force_ids": ["relief", "hequ"], "reserved_roster_snapshot": rosters,
		"terrain": "depot", "tactical_seed": int(_state.seed) + int(_state.next_battle) * 7919,
		"status": "reserved", "elapsed_world_time": 0.0}
	_state.battle_tickets[battle_id] = ticket
	_state.battle_locks = {"relief": battle_id, "hequ": battle_id}
	_state.next_battle += 1
	_event("battle_reserved", {"battle_id": battle_id, "location": location, "counts": [rosters[0].size(), rosters[1].size()]})
	return {"ok": true, "ticket": ticket.duplicate(true)}

func battle_ticket(battle_id: String) -> Dictionary:
	return _state.battle_tickets.get(battle_id, {}).duplicate(true)

func cancel_battle_ticket(battle_id: String) -> bool:
	## No rollback of running fights: withdrawal must use the physical retreat exit.
	if not _state.battle_tickets.has(battle_id) or _state.battle_tickets[battle_id].status != "reserved":
		return false
	_state.battle_tickets[battle_id].status = "cancelled"
	_unlock_battle(battle_id)
	_event("battle_cancelled", {"battle_id": battle_id})
	return true

func start_battle(battle_id: String) -> BattleSimulation:
	if not _state.battle_tickets.has(battle_id):
		return null
	var ticket: Dictionary = _state.battle_tickets[battle_id]
	if ticket.status == "running":
		return _battle_sessions.get(battle_id)
	if ticket.status != "reserved":
		return null
	var simulation := Battle.new()
	simulation.reset_from_ticket(ticket)
	_battle_sessions[battle_id] = simulation
	ticket.status = "running"
	_event("battle_started", {"battle_id": battle_id})
	return simulation

func sync_battle_time(battle_id: String) -> bool:
	if not _battle_sessions.has(battle_id) or _state.battle_tickets[battle_id].status != "running":
		return false
	var simulation: BattleSimulation = _battle_sessions[battle_id]
	var ticket: Dictionary = _state.battle_tickets[battle_id]
	if not is_finite(simulation.elapsed) or simulation.elapsed < ticket.elapsed_world_time or simulation.elapsed > MAX_ADVANCE * 3600.0:
		return false
	_advance_clock_to(ticket.time + simulation.elapsed)
	ticket.elapsed_world_time = simulation.elapsed
	return true

func validate_battle_outcome(outcome: Variant) -> Dictionary:
	## Inspection is read-only. Caller-written dictionaries are never authoritative.
	if not outcome is Dictionary or not outcome.get("battle_id") is String:
		return _reject("malformed_outcome")
	var battle_id: String = outcome.battle_id
	if not _state.battle_tickets.has(battle_id):
		return _reject("unknown_battle")
	var ticket: Dictionary = _state.battle_tickets[battle_id]
	if ticket.status == "committed":
		if outcome == ticket.outcome:
			return {"ok": true, "already_committed": true}
		return _reject("conflicting_committed_outcome")
	if ticket.status != "running" or not _battle_sessions.has(battle_id):
		return _reject("battle_not_running")
	var simulation: BattleSimulation = _battle_sessions[battle_id]
	if not simulation.ended:
		return _reject("battle_not_ended")
	if not is_finite(simulation.elapsed) or simulation.elapsed < ticket.elapsed_world_time or simulation.elapsed > MAX_ADVANCE * 3600.0:
		return _reject("invalid_elapsed_time")
	if outcome != simulation.outcome():
		return _reject("outcome_not_authoritative")
	if simulation.units.size() != ticket.reserved_roster_snapshot[0].size() + ticket.reserved_roster_snapshot[1].size():
		return _reject("roster_changed")
	var seen: Array[String] = []
	for team in range(2):
		for reserved in ticket.reserved_roster_snapshot[team]:
			var matched := false
			for unit in simulation.units:
				if unit.get("roster_id") == reserved.id:
					if unit.roster_id in seen or unit.team != team or unit.weapon != reserved.weapon or unit.hero != reserved.hero or unit.force_id != reserved.force_id or not is_finite(float(unit.hp)) or unit.hp < 0.0 or unit.hp > reserved.hp:
						return _reject("invalid_roster_state")
					seen.append(unit.roster_id)
					matched = true
			if not matched:
				return _reject("missing_roster_member")
	if outcome.result == "retreat":
		if simulation.order != "retreat" or simulation.player().pos.x >= -27.0:
			return _reject("retreat_not_extracted")
		for unit in simulation.units:
			if unit.team == 0 and not unit.hero and unit.hp > 0.0 and unit.pos.x > -25.5:
				return _reject("retreat_not_extracted")
	for force_id in ticket.participating_force_ids:
		if _state.battle_locks.get(force_id) != battle_id or _location(force_id) != ticket.location:
			return _reject("reservation_changed")
	if not audit().is_empty():
		return _reject("world_audit_failed")
	return {"ok": true, "already_committed": false}

func commit_battle_outcome(outcome: Variant) -> Dictionary:
	var validation := validate_battle_outcome(outcome)
	if not validation.ok:
		return validation
	var battle_id: String = outcome.battle_id
	if validation.already_committed:
		var repeated: Dictionary = _state.battle_tickets[battle_id].receipt.duplicate(true)
		repeated.already_committed = true
		return repeated
	var before := _state.duplicate(true)
	if not sync_battle_time(battle_id):
		return _reject("clock_sync_failed")
	var ticket: Dictionary = _state.battle_tickets[battle_id]
	for force in outcome.forces:
		var entity := _entity(force.force_id)
		entity.soldiers -= force.dead_ids.size()
		entity.weapons -= force.destroyed_equipment
		_state.ledger.dead += force.dead_ids.size()
		_state.ledger.weapons_destroyed += force.destroyed_equipment
	_state.cities.hequ.weapons -= outcome.spoils.weapons
	_state.armies.relief.weapons += outcome.spoils.weapons
	var captured: bool = outcome.result == "victory" and _state.cities.hequ.soldiers == 0
	if captured:
		_capture("hequ", _state.armies.relief.owner)
	_unlock_battle(battle_id)
	_state.commander.hp = outcome.player_hp
	_state.commander.alive = outcome.player_alive
	ticket.status = "committed"
	ticket.outcome = outcome.duplicate(true)
	ticket.receipt = {"ok": true, "already_committed": false, "battle_id": battle_id,
		"result": outcome.result, "depot_captured": captured, "campaign_ended": not outcome.player_alive,
		"elapsed_world_time": outcome.elapsed_world_time, "spoils": outcome.spoils.duplicate(true)}
	_event("battle_committed", {"battle_id": battle_id, "result": outcome.result, "forces": outcome.forces, "spoils": outcome.spoils})
	# A local observation is legitimate; remote siege truth remains delayed.
	observe_city("hequ")
	if not outcome.player_alive:
		_state.campaign_ended = true
		_event("campaign_ended", {"cause": "commander_dead", "battle_id": battle_id})
	var errors := audit()
	if not errors.is_empty():
		_state = before
		return {"ok": false, "reason": "settlement_audit_failed", "errors": errors}
	_battle_sessions.erase(battle_id)
	return ticket.receipt.duplicate(true)

func _unlock_battle(battle_id: String) -> void:
	for force_id in _state.battle_locks.keys():
		if _state.battle_locks[force_id] == battle_id:
			_state.battle_locks.erase(force_id)

func _reject(reason: String) -> Dictionary:
	return {"ok": false, "reason": reason}
