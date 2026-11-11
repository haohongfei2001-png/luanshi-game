class_name CampaignSchema
extends RefCounted
## Explicit save-v1 shapes. Unknown fields require a new supported schema, not
## silent discard. Domain cross-checks run only after these typed shapes pass.

const MAX_TIME := 31557600000.0 # 1,000 years: bounded clock arithmetic.
const MAX_STOCK := 1000000000000000000
const MAX_PEOPLE := 1000000000
const MAX_ID := 1000000000
const MAX_HISTORY := 250000

static func keys(value: Variant, fields: Array) -> bool:
	if not value is Dictionary or value.size() != fields.size():
		return false
	for field in fields:
		if not value.has(field):
			return false
	return true

static func types(value: Dictionary, fields: Dictionary) -> bool:
	for field in fields:
		if typeof(value.get(field)) != fields[field]:
			return false
	return true

static func integer(value: Variant, lower: int = 0, upper: int = MAX_STOCK) -> bool:
	return value is int and value >= lower and value <= upper

static func number(value: Variant, lower: float = 0.0, upper: float = MAX_TIME) -> bool:
	return value is float and is_finite(value) and value >= lower and value <= upper

static func text(value: Variant, maximum: int = 256) -> bool:
	return value is String and value.length() <= maximum

static func dictionary(value: Variant, maximum: int = MAX_HISTORY) -> bool:
	return value is Dictionary and value.size() <= maximum

static func array(value: Variant, maximum: int = MAX_HISTORY) -> bool:
	return value is Array and value.size() <= maximum

static func condition(value: Variant) -> bool:
	if not keys(value, ["fatigue", "morale", "hunger", "stage", "last_needed", "last_eaten", "last_activity", "activity_flags"]):
		return false
	for field in ["fatigue", "morale", "hunger", "last_needed", "last_eaten"]:
		if not integer(value[field], 0, MAX_PEOPLE):
			return false
	if not text(value.stage) or not text(value.last_activity) or not dictionary(value.activity_flags, 5):
		return false
	for field in value.activity_flags:
		if not text(field) or not value.activity_flags[field] is bool:
			return false
	return true

static func world(value: Variant, expected_version: int) -> bool:
	if not keys(value, ["version", "seed", "hour", "time_seconds", "campaign_generation", "campaign_ended", "commander", "battle_tickets", "battle_locks", "next_battle", "factions", "cities", "armies", "siege", "ledger", "pending_reports", "reports", "events", "next_report", "convoys", "next_convoy", "initial_totals", "initial_force_roster"]):
		return false
	if not types(value, {"version": TYPE_INT, "seed": TYPE_INT, "hour": TYPE_INT, "time_seconds": TYPE_FLOAT, "campaign_generation": TYPE_INT, "campaign_ended": TYPE_BOOL, "commander": TYPE_DICTIONARY, "factions": TYPE_DICTIONARY, "cities": TYPE_DICTIONARY, "armies": TYPE_DICTIONARY, "siege": TYPE_DICTIONARY, "ledger": TYPE_DICTIONARY, "initial_totals": TYPE_DICTIONARY, "initial_force_roster": TYPE_DICTIONARY, "battle_tickets": TYPE_DICTIONARY, "battle_locks": TYPE_DICTIONARY, "pending_reports": TYPE_ARRAY, "reports": TYPE_ARRAY, "events": TYPE_ARRAY, "convoys": TYPE_ARRAY}):
		return false
	if not types(value.commander, {"army": TYPE_STRING, "alive": TYPE_BOOL, "hp": TYPE_FLOAT, "max_hp": TYPE_FLOAT}) or not types(value.siege, {"city": TYPE_STRING, "army": TYPE_STRING, "active": TYPE_BOOL, "outcome": TYPE_STRING}):
		return false
	if not integer(value.version, expected_version, expected_version) or not value.seed is int or not integer(value.hour, 0, int(MAX_TIME / 3600)) or not number(value.time_seconds) or not integer(value.campaign_generation, 1, MAX_ID) or not value.campaign_ended is bool:
		return false
	for counter in ["next_battle", "next_report", "next_convoy"]:
		if not integer(value[counter], 1, MAX_ID):
			return false
	if not keys(value.commander, ["alive", "hp", "max_hp", "army"]) or not value.commander.alive is bool or not number(value.commander.hp, 0, 360) or not number(value.commander.max_hp, 360, 360) or value.commander.army != "relief":
		return false
	if not keys(value.factions, ["sheng", "bei"]):
		return false
	for faction in value.factions.values():
		if not keys(faction, ["name"]) or not text(faction.name):
			return false
	if not keys(value.cities, ["anping", "pingling", "hequ"]) or not keys(value.armies, ["relief", "besiegers"]):
		return false
	for city in value.cities.values():
		if not _city(city):
			return false
	for army in value.armies.values():
		if not _army(army):
			return false
	if not keys(value.siege, ["city", "army", "active", "outcome"]) or value.siege.city != "anping" or value.siege.army != "besiegers" or not value.siege.active is bool or value.siege.outcome not in ["ongoing", "captured", "relieved", "supply_retreat"]:
		return false
	if not keys(value.initial_totals, ["food", "weapons", "soldiers", "civilian_population"]):
		return false
	if not keys(value.initial_force_roster, ["anping", "pingling", "hequ", "relief", "besiegers"]):
		return false
	var initial_people := 0
	for count in value.initial_force_roster.values():
		if not integer(count, 0, MAX_PEOPLE): return false
		initial_people += count
	for total in value.initial_totals.values():
		if not integer(total):
			return false
	if initial_people != value.initial_totals.soldiers:
		return false
	if not keys(value.ledger, ["food_produced", "food_consumed", "food_consumed_civilian", "food_consumed_military", "food_shortfall_civilian", "food_shortfall_military", "weapons_produced", "weapons_destroyed", "dead", "starvation_dead", "prisoners"]):
		return false
	for total in value.ledger.values():
		if not integer(total):
			return false
	if not array(value.pending_reports) or not array(value.reports) or not array(value.convoys) or not array(value.events):
		return false
	for report in value.pending_reports + value.reports:
		if not _report(report):
			return false
	for convoy in value.convoys:
		if not _convoy(convoy):
			return false
	for event in value.events:
		if not keys(event, ["hour", "time_seconds", "kind", "details"]) or not integer(event.hour, 0, int(MAX_TIME / 3600)) or not number(event.time_seconds) or not text(event.kind) or not dictionary(event.details, 64):
			return false
	if not dictionary(value.battle_tickets) or not dictionary(value.battle_locks, 2):
		return false
	for id in value.battle_tickets:
		if not text(id) or not ticket(value.battle_tickets[id]):
			return false
	for force in value.battle_locks:
		if force not in ["relief", "hequ"] or not text(value.battle_locks[force]):
			return false
	return true

static func _inventory(value: Dictionary) -> bool:
	if not types(value, {"owner": TYPE_STRING, "condition": TYPE_DICTIONARY}) or value.owner not in ["sheng", "bei"] or not condition(value.condition):
		return false
	return integer(value.food) and integer(value.weapons) and integer(value.soldiers, 0, MAX_PEOPLE)

static func _city(value: Variant) -> bool:
	if not keys(value, ["population", "workable_population", "arable_land", "workshop_capacity", "stability", "name", "owner", "soldiers", "weapons", "food", "fort", "production_rates", "production_progress", "civilian_food_progress", "condition"]):
		return false
	if not _inventory(value) or not text(value.name) or not integer(value.fort, 0, MAX_PEOPLE):
		return false
	for field in ["population", "workable_population", "arable_land", "workshop_capacity", "stability", "civilian_food_progress"]:
		if not integer(value[field], 0, MAX_PEOPLE):
			return false
	if not keys(value.production_rates, ["food_per_farmer_month", "weapons_per_crafter_month"]) or not keys(value.production_progress, ["food", "weapons"]):
		return false
	for amount in value.production_rates.values() + value.production_progress.values():
		if not integer(amount, 0, MAX_PEOPLE):
			return false
	return true

static func _army(value: Variant) -> bool:
	if not keys(value, ["owner", "location", "soldiers", "weapons", "food", "march", "starving_hours", "condition"]):
		return false
	if not types(value, {"location": TYPE_STRING, "march": TYPE_DICTIONARY}) or not _inventory(value) or value.location not in ["", "anping", "pingling", "hequ"] or not integer(value.starving_hours, 0, MAX_PEOPLE) or not dictionary(value.march, 4):
		return false
	if value.march.is_empty():
		return value.location != ""
	if not types(value.march, {"route": TYPE_STRING, "destination": TYPE_STRING}):
		return false
	return value.location == "" and keys(value.march, ["route", "destination", "arrives_at", "arrives_at_seconds"]) and value.march.route in ["road", "mountain", "river", "grain_road"] and value.march.destination in ["anping", "pingling", "hequ"] and integer(value.march.arrives_at, 0, int(MAX_TIME / 3600)) and number(value.march.arrives_at_seconds)

static func _report(value: Variant) -> bool:
	if not keys(value, ["id", "subject", "source", "observed_at", "arrives_at", "reported_at", "observed_at_seconds", "arrives_at_seconds", "reported_at_seconds", "confidence", "contents"]):
		return false
	if not types(value, {"subject": TYPE_STRING, "source": TYPE_STRING}):
		return false
	if not integer(value.id, 1, MAX_ID) or value.subject not in ["anping", "pingling", "hequ"] or not text(value.source) or not number(value.confidence, 0, 1) or not dictionary(value.contents, 8):
		return false
	for field in ["observed_at", "arrives_at", "reported_at"]:
		if not integer(value[field], -72, int(MAX_TIME / 3600)):
			return false
	for field in ["observed_at_seconds", "arrives_at_seconds", "reported_at_seconds"]:
		if not number(value[field], -72 * 3600.0):
			return false
	for field in value.contents:
		match field:
			"owner":
				if not value.contents[field] is String or value.contents[field] not in ["sheng", "bei"]: return false
			"under_siege":
				if not value.contents[field] is bool: return false
			"soldiers", "food", "fort":
				if not integer(value.contents[field]): return false
			"outcome":
				if not value.contents[field] is String or value.contents[field] not in ["ongoing", "captured", "relieved", "supply_retreat"]: return false
			_:
				return false
	return true

static func _convoy(value: Variant) -> bool:
	return keys(value, ["id", "owner", "origin", "destination", "departed_at", "arrives_at", "food", "returning"]) and types(value, {"owner": TYPE_STRING, "origin": TYPE_STRING, "destination": TYPE_STRING, "returning": TYPE_BOOL}) and integer(value.id, 1, MAX_ID) and value.owner in ["sheng", "bei"] and value.origin == "hequ" and value.destination in ["anping", "hequ"] and integer(value.departed_at, 0, int(MAX_TIME / 3600)) and integer(value.arrives_at, 0, int(MAX_TIME / 3600)) and integer(value.food, 1, MAX_PEOPLE) and value.returning is bool

static func ticket(value: Variant) -> bool:
	if not value is Dictionary or not types(value, {"status": TYPE_STRING, "location": TYPE_STRING, "terrain": TYPE_STRING, "participating_force_ids": TYPE_ARRAY}):
		return false
	var fields := ["battle_id", "time", "location", "participating_force_ids", "reserved_roster_snapshot", "terrain", "tactical_seed", "status", "elapsed_world_time"]
	if value.get("status") == "committed":
		fields.append_array(["outcome", "receipt"])
	if not keys(value, fields) or not text(value.battle_id) or not number(value.time) or value.location != "hequ" or value.participating_force_ids != ["relief", "hequ"] or value.terrain != "depot" or not value.tactical_seed is int or value.status not in ["reserved", "running", "committed", "cancelled"] or not number(value.elapsed_world_time, 0, 8760 * 3600.0):
		return false
	if not array(value.reserved_roster_snapshot, 2) or value.reserved_roster_snapshot.size() != 2:
		return false
	for team in range(2):
		var roster: Variant = value.reserved_roster_snapshot[team]
		if not array(roster, 20) or roster.is_empty():
			return false
		for slot in range(roster.size()):
			var entry: Variant = roster[slot]
			if not keys(entry, ["id", "force_id", "hero", "weapon", "hp", "condition", "condition_modifiers"]):
				return false
			if not types(entry, {"id": TYPE_STRING, "force_id": TYPE_STRING, "hero": TYPE_BOOL, "weapon": TYPE_STRING}) or not text(entry.id) or entry.force_id != value.participating_force_ids[team] or entry.hero != (team == 0 and slot == 0) or not entry.hero is bool or entry.weapon not in ["", "spear"] or not number(entry.hp, 0.00001, 360.0 if entry.hero else 100.0) or not condition(entry.condition):
				return false
			if not keys(entry.condition_modifiers, ["damage_percent", "speed_percent"]):
				return false
			for amount in entry.condition_modifiers.values():
				if not integer(amount, 1, 100): return false
	if value.status == "committed":
		return outcome(value.outcome) and receipt(value.receipt)
	return true

static func outcome(value: Variant) -> bool:
	if not value is Dictionary or not types(value, {"battle_id": TYPE_STRING, "result": TYPE_STRING, "player_alive": TYPE_BOOL, "retreat_positions": TYPE_DICTIONARY}):
		return false
	if not keys(value, ["battle_id", "result", "forces", "elapsed_world_time", "player_alive", "player_hp", "spoils", "retreat_positions"]) or not text(value.battle_id) or value.result not in ["victory", "retreat", "commander_dead"] or not array(value.forces, 2) or value.forces.size() != 2 or not number(value.elapsed_world_time, 0, 8760 * 3600.0) or not value.player_alive is bool or not number(value.player_hp, 0, 360) or not keys(value.spoils, ["weapons"]) or not integer(value.spoils.weapons, 0, 20) or not dictionary(value.retreat_positions, 1):
		return false
	for force in value.forces:
		if not keys(force, ["force_id", "surviving_ids", "dead_ids", "wounded", "missing", "captured", "recovered_equipment", "destroyed_equipment"]) or force.force_id not in ["relief", "hequ"] or not integer(force.recovered_equipment, 0, 20) or not integer(force.destroyed_equipment, 0, 20):
			return false
		for field in ["surviving_ids", "dead_ids", "wounded", "missing", "captured"]:
			if not array(force[field], 20): return false
			for id in force[field]:
				if not text(id): return false
	return true

static func receipt(value: Variant) -> bool:
	return keys(value, ["ok", "already_committed", "battle_id", "result", "depot_captured", "campaign_ended", "elapsed_world_time", "spoils"]) and types(value, {"ok": TYPE_BOOL, "already_committed": TYPE_BOOL, "battle_id": TYPE_STRING, "result": TYPE_STRING, "depot_captured": TYPE_BOOL, "campaign_ended": TYPE_BOOL}) and value.ok is bool and value.already_committed is bool and text(value.battle_id) and value.result in ["victory", "retreat", "commander_dead"] and value.depot_captured is bool and value.campaign_ended is bool and number(value.elapsed_world_time, 0, 8760 * 3600.0) and keys(value.spoils, ["weapons"]) and integer(value.spoils.weapons, 0, 20)
