class_name CampaignEventAudit
extends RefCounted
const Couriers := preload("res://scripts/courier_orders.gd")
## Reconstruct authoritative ledgers and transaction transitions from causal events.
## A checksum or balanced final totals alone cannot prove these accounts agree.
const S := preload("res://scripts/campaign_schema.gd")
const CITIES := ["anping", "pingling", "hequ"]
const ENTITIES := ["anping", "pingling", "hequ", "relief", "besiegers"]

static func validate(state: Dictionary) -> bool:
	var accounts := {}
	for key in state.ledger:
		accounts[key] = 0
	var courier_food := {}
	var statuses := {}
	var ownership := {}
	var people: Dictionary = state.initial_force_roster.duplicate()
	var commander_hp: float = S.HeroProfiles.from_reference(state.commander.hero_profile).max_hp
	var death_recorded := false
	var previous: Dictionary = {}
	var resting: Dictionary = {}
	for event in state.events:
		var d: Dictionary = event.details
		for name in ["entity", "consumer", "cause", "city", "owner", "battle_id", "location", "activity", "route", "from", "to", "resource", "destination", "outcome", "result"]:
			if d.has(name) and not d[name] is String:
				return false
		for name in ["counts", "forces"]:
			if d.has(name) and not d[name] is Array: return false
		for name in ["spoils", "amounts", "labor", "rates", "progress_before", "progress_after", "before", "after"]:
			if d.has(name) and not d[name] is Dictionary: return false
		if death_recorded and event.kind in ["march_started", "transfer", "depot_seized", "battle_reserved", "battle_started", "battle_committed"]:
			return false
		match event.kind:
			"combat_training_started", "combat_training_completed":
				if not preload("res://scripts/combat_growth.gd").event_shape(event.kind, d): return false
				if event.kind == "combat_training_started" and (death_recorded or d.hp != commander_hp): return false
			"wound_rest_started":
				if not preload("res://scripts/wound_care.gd").event_shape(event.kind, d) or death_recorded or not resting.is_empty() or d.hp != commander_hp: return false
				resting = {"at": event.time_seconds, "hp": commander_hp}
			"wound_rest_completed":
				if not preload("res://scripts/wound_care.gd").event_shape(event.kind, d) or resting.is_empty() or d.started_at != resting.at or d.hp_before != resting.hp: return false
				if event.time_seconds > d.started_at + 3600.0 or event.time_seconds <= d.started_at: return false
				if d.reason == "interrupted":
					if d.healed != 0.0 or d.hp_after != commander_hp: return false
				elif death_recorded or event.time_seconds != d.started_at + 3600.0 or d.hp_after != commander_hp + d.healed or (d.reason != "rested" and d.healed != 0.0): return false
				commander_hp = d.hp_after
				resting.clear()
			"hometown_attach", "hometown_letter", "hometown_received", "hometown_visit":
				if not preload("res://scripts/hometown_messages.gd").event_shape(event.kind, d): return false
			"courier_wait":
				if not S.keys(d, ["started_at"]) or not S.number(d.started_at, 0, event.time_seconds): return false
			"courier":
				if not S.keys(d, ["action", "id", "value"]) or not d.action is String or not d.id is int or not d.value is String: return false
				match d.action:
					"dispatch":
						if death_recorded or people.pingling < 1 or courier_food.has(d.id): return false
						people.pingling -= 1
						courier_food[d.id] = Couriers.RATIONS
					"meal":
						if not courier_food.has(d.id) or courier_food[d.id] < 1: return false
						courier_food[d.id] -= 1
						if not _add(accounts, "food_consumed", 1) or not _add(accounts, "food_consumed_military", 1): return false
					"lost":
						if not _add(accounts, "dead", 1): return false
						if d.value == "starvation" and not _add(accounts, "starvation_dead", 1): return false
					"return": people.pingling += 1
			"youth_inventory":
				if not S.keys(d, ["from", "to", "resource", "amount"]) or d.from not in ["relief", "pingling"] or d.to not in ["relief", "pingling"] or d.from == d.to or d.resource not in ["food", "weapons", "soldiers"] or not S.integer(d.amount, 1, 120) or death_recorded: return false
				if d.resource == "soldiers":
					if people[d.from] < d.amount: return false
					people[d.from] -= d.amount
					people[d.to] += d.amount
			"youth_transition":
				if not S.keys(d, ["action", "data", "moves"]): return false
			"production":
				if not _production(d) or event.hour < 1:
					return false
				for resource in ["food", "weapons"]:
					if not _add(accounts, resource + "_produced", d.amounts[resource]): return false
			"consumption":
				if not _consumption(d) or event.hour < 1 or (d.consumer == "civilian" and event.hour % 24 != 0):
					return false
				if not _add(accounts, "food_consumed", d.eaten) or not _add(accounts, "food_consumed_" + d.consumer, d.eaten) or not _add(accounts, "food_shortfall_" + d.consumer, d.shortfall):
					return false
			"troops_lost":
				if not S.keys(d, ["entity", "dead", "weapons_destroyed", "cause"]) or d.entity not in ENTITIES or d.cause not in ["combat", "starvation"] or not S.integer(d.dead, 1, S.MAX_PEOPLE) or not S.integer(d.weapons_destroyed, 0, d.dead):
					return false
				if d.dead > people[d.entity] or not _add(accounts, "dead", d.dead) or not _add(accounts, "weapons_destroyed", d.weapons_destroyed): return false
				people[d.entity] -= d.dead
			"starvation_attrition":
				if not S.keys(d, ["entity", "dead", "weapons_destroyed", "hunger", "fatigue", "morale", "reserved_people"]) or d.entity not in ENTITIES or not S.integer(d.dead, 1, S.MAX_PEOPLE) or not S.integer(d.weapons_destroyed, 0, d.dead) or not S.integer(d.hunger, 3000, 6000) or not S.integer(d.fatigue, 0, 100) or not S.integer(d.morale, 0, 100) or not S.integer(d.reserved_people, 0, 20):
					return false
				if not _add(accounts, "starvation_dead", d.dead): return false
			"city_captured":
				if not S.keys(d, ["city", "owner", "prisoners"]) or d.city not in CITIES or d.owner not in ["sheng", "bei"] or not S.integer(d.prisoners, 0, S.MAX_PEOPLE): return false
				ownership[d.city] = d.owner
				if d.prisoners > people[d.city]: return false
				people[d.city] -= d.prisoners
				if not _add(accounts, "prisoners", d.prisoners): return false
			"battle_reserved", "battle_started", "battle_cancelled", "battle_committed":
				if not d.get("battle_id") is String or not state.battle_tickets.has(d.battle_id): return false
				var id: String = d.battle_id
				var ticket: Dictionary = state.battle_tickets[id]
				match event.kind:
					"battle_reserved":
						if not S.keys(d, ["battle_id", "location", "counts"]) or d.location != ticket.location or d.counts != [ticket.reserved_roster_snapshot[0].size(), ticket.reserved_roster_snapshot[1].size()] or statuses.has(id) or event.time_seconds != ticket.time: return false
						statuses[id] = "reserved"
					"battle_started", "battle_cancelled":
						if not S.keys(d, ["battle_id"]) or statuses.get(id) != "reserved" or event.time_seconds != ticket.time: return false
						statuses[id] = "running" if event.kind == "battle_started" else "cancelled"
					"battle_committed":
						if not S.keys(d, ["battle_id", "result", "forces", "spoils"]) or statuses.get(id) != "running" or ticket.status != "committed" or event.time_seconds != ticket.time + ticket.elapsed_world_time: return false
						var outcome: Dictionary = ticket.outcome
						if d.result != outcome.result or d.forces != outcome.forces or d.spoils != outcome.spoils: return false
						var captured: bool = previous.get("kind") == "city_captured" and previous.time_seconds == event.time_seconds and previous.details.city == ticket.location
						if ticket.receipt.depot_captured != captured: return false
						for force in outcome.forces:
							if force.dead_ids.size() > people[force.force_id] or not _add(accounts, "dead", force.dead_ids.size()) or not _add(accounts, "weapons_destroyed", force.destroyed_equipment): return false
							people[force.force_id] -= force.dead_ids.size()
						commander_hp = outcome.player_hp
						statuses[id] = "committed"
			"campaign_ended":
				if death_recorded or not S.text(d.get("cause")): return false
				if d.cause == "commander_dead":
					if not S.keys(d, ["cause", "battle_id"]) or statuses.get(d.battle_id) != "committed" or previous.get("kind") != "battle_committed" or previous.details.battle_id != d.battle_id or previous.time_seconds != event.time_seconds or state.battle_tickets[d.battle_id].outcome.player_alive: return false
				elif d.cause not in ["combat", "starvation"] or not S.keys(d, ["cause"]) or previous.get("kind") != "troops_lost" or previous.time_seconds != event.time_seconds or previous.details.entity != "relief" or previous.details.cause != d.cause or people.relief != 0: return false
				commander_hp = 0.0
				death_recorded = true
			"military_condition":
				if not S.keys(d, ["entity", "needed", "eaten", "shortfall", "activity", "rested", "before", "after"]) or d.entity not in ENTITIES or not S.integer(d.needed, 1, S.MAX_PEOPLE) or not S.integer(d.eaten, 0, d.needed) or not S.integer(d.shortfall, 0, d.needed) or d.shortfall != d.needed - d.eaten or d.activity not in ["rest", "alert", "siege", "march", "battle"] or not d.rested is bool or not S.condition(d.before) or not S.condition(d.after): return false
			"march_started":
				if not S.keys(d, ["route", "arrives_at", "arrives_at_seconds"]) or d.route not in ["road", "mountain", "river", "grain_road"] or not S.integer(d.arrives_at, 0, int(S.MAX_TIME / 3600.0)) or not S.number(d.arrives_at_seconds, event.time_seconds) or d.arrives_at != ceili(d.arrives_at_seconds / 3600.0): return false
			"transfer":
				if not S.keys(d, ["from", "to", "resource", "amount"]) or d.from not in ENTITIES or d.to not in ENTITIES or d.from == d.to or d.resource not in ["food", "weapons"] or not S.integer(d.amount, 1): return false
			"depot_seized":
				if not S.keys(d, ["casualties"]) or not S.integer(d.casualties, 1, S.MAX_PEOPLE): return false
			"convoy_returning":
				if not S.keys(d, ["id", "food"]) or not S.integer(d.id, 1, state.next_convoy - 1) or not S.integer(d.food, 1, S.MAX_PEOPLE): return false
			"convoy_delivered":
				if not S.keys(d, ["id", "destination", "food"]) or not S.integer(d.id, 1, state.next_convoy - 1) or d.destination not in CITIES or not S.integer(d.food, 1, S.MAX_PEOPLE): return false
			"arrival":
				if not S.keys(d, ["owner", "location"]) or d.owner not in ["sheng", "bei"] or d.location not in CITIES: return false
			"siege_ended":
				if not S.keys(d, ["outcome"]) or d.outcome not in ["captured", "relieved", "supply_retreat"] or d.outcome != state.siege.outcome: return false
			_:
				return false
		previous = event
	if not resting.is_empty(): return false
	if accounts != state.ledger or statuses.size() != state.battle_tickets.size() or state.campaign_ended != death_recorded:
		return false
	for id in people:
		var entity: Dictionary = state.cities.get(id, state.armies.get(id, {}))
		if entity.soldiers != people[id]: return false
	for id in statuses:
		if statuses[id] != state.battle_tickets[id].status: return false
	for city in ownership:
		if state.cities[city].owner != ownership[city]: return false
	if commander_hp >= 0.0 and state.commander.hp != commander_hp:
		return false
	return true

static func _add(accounts: Dictionary, key: String, amount: int) -> bool:
	if amount < 0 or amount > S.MAX_STOCK or accounts[key] > S.MAX_STOCK - amount:
		return false
	accounts[key] += amount
	return true

static func _consumption(d: Dictionary) -> bool:
	if not S.keys(d, ["entity", "consumer", "people", "requested", "eaten", "shortfall", "food_delta", "period_hours"]) or d.entity not in ENTITIES or d.consumer not in ["civilian", "military"] or not S.integer(d.people, 0, S.MAX_PEOPLE) or not S.integer(d.requested, 1) or not S.integer(d.eaten, 0, d.requested) or not S.integer(d.shortfall, 0, d.requested) or not S.integer(d.food_delta, -S.MAX_STOCK, 0) or not S.integer(d.period_hours, 1, 24):
		return false
	return d.food_delta == -d.eaten and d.requested == d.eaten + d.shortfall and d.period_hours == (24 if d.consumer == "civilian" else 1)

static func _production(d: Dictionary) -> bool:
	if not S.types(d, {"city": TYPE_STRING, "period_hours": TYPE_INT, "denominator": TYPE_INT}) or not S.keys(d, ["city", "amounts", "labor", "population", "workable_population", "arable_land", "workshop_capacity", "rates", "progress_before", "progress_after", "period_hours", "denominator"]) or d.city not in CITIES or not S.keys(d.amounts, ["food", "weapons"]) or not S.keys(d.progress_before, ["food", "weapons"]) or not S.keys(d.progress_after, ["food", "weapons"]) or not S.keys(d.rates, ["food_per_farmer_month", "weapons_per_crafter_month"]) or not S.keys(d.labor, ["farmers", "crafters", "stability", "besieged", "effective_condition", "food_per_month_numerator", "weapons_per_month_numerator", "rate_denominator", "hours_per_month", "civilian_food_per_hour_numerator", "civilian_food_rate_denominator", "hours_per_day"]):
		return false
	for field in ["population", "workable_population", "arable_land", "workshop_capacity"]:
		if not S.integer(d[field], 0, S.MAX_PEOPLE): return false
	for field in ["farmers", "crafters", "stability", "effective_condition", "food_per_month_numerator", "weapons_per_month_numerator", "rate_denominator", "hours_per_month", "civilian_food_per_hour_numerator", "civilian_food_rate_denominator", "hours_per_day"]:
		if not S.integer(d.labor[field]): return false
	if not d.labor.besieged is bool or d.labor.besieged or d.labor.stability > 100 or d.labor.effective_condition != d.labor.stability or d.workable_population > d.population or d.labor.farmers != mini(d.workable_population, d.arable_land) or d.labor.crafters != mini(d.workable_population - d.labor.farmers, d.workshop_capacity) or d.period_hours != 1 or not d.period_hours is int or d.denominator != 72000 or not d.denominator is int or d.labor.rate_denominator != 100 or d.labor.hours_per_month != 720 or d.labor.civilian_food_per_hour_numerator != d.population or d.labor.civilian_food_rate_denominator != 10 or d.labor.hours_per_day != 24:
		return false
	for resource in ["food", "weapons"]:
		var rate: Variant = d.rates["food_per_farmer_month" if resource == "food" else "weapons_per_crafter_month"]
		if not S.integer(rate, 0, 1000000) or not S.integer(d.amounts[resource]) or not S.integer(d.progress_before[resource], 0, 71999) or not S.integer(d.progress_after[resource], 0, 71999): return false
		var labor: int = d.labor.farmers if resource == "food" else d.labor.crafters
		var numerator: int = labor * rate * d.labor.stability
		var work: int = d.progress_before[resource] + numerator
		@warning_ignore("integer_division")
		var amount: int = work / 72000
		if d.labor[resource + "_per_month_numerator"] != numerator or d.amounts[resource] != amount or d.progress_after[resource] != work % 72000: return false
	return d.amounts.food > 0 or d.amounts.weapons > 0
