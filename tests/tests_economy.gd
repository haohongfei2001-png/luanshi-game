extends SceneTree

const Simulation := preload("res://scripts/world_sim.gd")
var assertions := 0
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func check(condition: bool, message: String) -> void:
	assertions += 1
	if not condition:
		failures.append(message)
		push_error("FAIL: " + message)

func fixture(overrides: Dictionary = {}) -> RefCounted:
	# Privileged test setup, not a player-facing command or an unsupported save loader.
	# Existing military forces remain intact; ample starting stores isolate capacity tests.
	var world := Simulation.new(184)
	world._state.cities.pingling.merge(overrides, true)
	world._state.cities.pingling.food = 100000
	world._state.initial_totals = world.totals()
	return world

func production(world: RefCounted, city_id: String) -> Dictionary:
	var result := {"food": 0, "weapons": 0}
	for event in world._state.events:
		if event.kind == "production" and event.details.city == city_id:
			result.food += event.details.amounts.food
			result.weapons += event.details.amounts.weapons
	return result

func consumed(world: RefCounted, entity_id: String, consumer: String) -> Dictionary:
	var result := {"requested": 0, "eaten": 0, "shortfall": 0}
	for event in world._state.events:
		if event.kind == "consumption" and event.details.entity == entity_id and event.details.consumer == consumer:
			for field in result:
				result[field] += event.details[field]
	return result

func _run() -> void:
	_test_capacity()
	_test_siege_and_fractional_work()
	_test_civilian_consumption()
	_test_three_months()
	_test_battle_boundary()
	_test_invalid_state()
	_test_local_view()
	_test_capacity_boundaries()
	print("Economy tests: %d assertions, %d failures" % [assertions, failures.size()])
	print("ECONOMY_TEST_SUMMARY " + JSON.stringify({"assertions": assertions, "failures": failures.size(), "messages": failures}))
	quit(0 if failures.is_empty() else 1)

func _test_capacity() -> void:
	var baseline := Simulation.new()
	check(baseline.totals().civilian_population == 50 and baseline.totals().soldiers == 215, "civilians exclude garrisons and field soldiers")
	check(baseline.snapshot().version == 3, "new economic snapshot schema is explicit; no silent v2 migration")
	check(not baseline.snapshot().cities.pingling.has("food_per_hour"), "fixed city production is removed")
	var cases := [
		{"label": "normal", "inputs": {}, "food": 2880, "weapons": 30},
		{"label": "less population and labor", "inputs": {"population": 5, "workable_population": 5}, "food": 1800, "weapons": 0},
		{"label": "no workable population", "inputs": {"workable_population": 0}, "food": 0, "weapons": 0},
		{"label": "no population", "inputs": {"population": 0, "workable_population": 0}, "food": 0, "weapons": 0},
		{"label": "land scarcity", "inputs": {"arable_land": 4}, "food": 1440, "weapons": 30},
		{"label": "no secured farmland", "inputs": {"arable_land": 0}, "food": 0, "weapons": 30},
		{"label": "workshop scarcity", "inputs": {"workshop_capacity": 1}, "food": 2880, "weapons": 15},
		{"label": "no workshops", "inputs": {"workshop_capacity": 0}, "food": 2880, "weapons": 0},
		{"label": "shared labor cannot work two jobs", "inputs": {"arable_land": 9}, "food": 3240, "weapons": 15},
		{"label": "extra labor without land or workshops", "inputs": {"population": 40, "workable_population": 30}, "food": 2880, "weapons": 30},
		{"label": "half stability", "inputs": {"stability": 50}, "food": 1440, "weapons": 15},
		{"label": "disrupted production", "inputs": {"stability": 0}, "food": 0, "weapons": 0},
		{"label": "data rates", "inputs": {"production_rates": {"food_per_farmer_month": 180, "weapons_per_crafter_month": 30}}, "food": 1440, "weapons": 60},
	]
	for scenario in cases:
		var world := fixture(scenario.inputs)
		check(world.audit().is_empty(), scenario.label + " fixture is coherent")
		check(world.advance(Simulation.MONTH_HOURS), scenario.label + " advances full month")
		var produced := production(world, "pingling")
		check(produced.food == scenario.food and produced.weapons == scenario.weapons, scenario.label + " affects actual stocks and ledger events")
		check(world.audit().is_empty(), scenario.label + " conserves resources")
		var city: Dictionary = world._state.cities.pingling
		check(city.food == 100000 + produced.food - consumed(world, "pingling", "civilian").eaten - consumed(world, "pingling", "military").eaten,
			scenario.label + " city inventory independently reconstructs from local events")

func _test_siege_and_fractional_work() -> void:
	var besieged := fixture()
	besieged._state.cities.anping.arable_land = 8
	besieged._state.cities.anping.food = 100000
	besieged._state.cities.anping.fort = 100000
	besieged._state.cities.hequ.food = 100000
	besieged._state.initial_totals = besieged.totals()
	check(besieged.advance(Simulation.MONTH_HOURS) and besieged._state.siege.active, "well-supplied fixture sustains real siege for a month")
	check(production(besieged, "anping") == {"food": 0, "weapons": 0}, "siege blocks farming and workshops despite workers and land")
	check(besieged._state.cities.anping.production_progress == {"food": 0, "weapons": 0}, "blocked labor creates no deferred harvest")
	check(production(besieged, "pingling").food == 2880 and besieged.audit().is_empty(), "unobserved neighboring economy continues during siege")
	besieged._state.siege.active = false # Controlled lifting of siege, not a victory shortcut.
	check(besieged.advance(24), "work resumes after blockade lifts")
	check(production(besieged, "anping") == {"food": 96, "weapons": 1}, "only actual post-siege work is credited")


	var interrupted := fixture()
	interrupted._state.cities.anping.food = 10000
	interrupted._state.cities.anping.fort = 10000
	interrupted._state.cities.hequ.food = 10000
	interrupted._state.armies.besiegers.food = 10000
	interrupted._state.initial_totals = interrupted.totals()
	interrupted._state.siege.active = false
	interrupted.advance(12)
	check(interrupted._state.cities.anping.production_progress.weapons == 36000, "half-completed weapon exists only as work progress")
	interrupted._state.siege.active = true
	interrupted.advance(24)
	check(interrupted._state.cities.anping.production_progress.weapons == 36000 and production(interrupted, "anping").weapons == 0,
		"blockade preserves existing fractional work but creates no extra work")
	interrupted._state.siege.active = false
	interrupted.advance(12)
	check(production(interrupted, "anping").weapons == 1 and interrupted.audit().is_empty(), "resumed work finishes exactly one item after twenty-four productive hours")

	var timely := Simulation.new()
	timely._state.cities.anping.arable_land = 8
	timely.march("road")
	timely.advance(6)
	check(timely._state.siege.outcome == "relieved" and production(timely, "anping").food == 0, "real relief ends siege only after that hour's interrupted production")
	timely.advance(24)
	check(production(timely, "anping") == {"food": 96, "weapons": 1}, "causal relief restarts previously unavailable production")

	var fractional := fixture({"population": 2, "workable_population": 2, "arable_land": 1, "workshop_capacity": 1,
		"stability": 50, "production_rates": {"food_per_farmer_month": 1, "weapons_per_crafter_month": 1}})
	check(fractional.advance(719), "fractional work advances without rounding each hour to a free item")
	check(production(fractional, "pingling") == {"food": 0, "weapons": 0}, "subunit monthly progress is not spendable inventory")
	check(fractional._state.cities.pingling.production_progress == {"food": 35950, "weapons": 35950}, "integer progress retains small rates exactly")
	fractional.advance(1)
	check(fractional._state.cities.pingling.production_progress.food == 36000, "half item after one month")
	fractional.advance(720)
	check(production(fractional, "pingling") == {"food": 1, "weapons": 1}, "two half-rate months produce exactly one real item each")
	fractional.advance(720)
	check(production(fractional, "pingling").food == 1 and fractional._state.cities.pingling.production_progress.food == 36000, "third month preserves remaining half item")
	check(fractional.audit().is_empty(), "fractional production conserves integer stocks")

func _test_civilian_consumption() -> void:
	var world := fixture({"population": 1, "workable_population": 0})
	world.advance_seconds(24 * 3600.0 - 0.25)
	check(consumed(world, "pingling", "civilian").eaten == 0, "civilian rations wait for actual day boundary")
	world.advance_seconds(0.25)
	check(consumed(world, "pingling", "civilian").eaten == 2 and world._state.cities.pingling.civilian_food_progress == 4, "civilian whole food units consumed with exact person-hour carry")
	world.advance(96)
	check(consumed(world, "pingling", "civilian") == {"requested": 12, "eaten": 12, "shortfall": 0}, "five days for one civilian consumes exactly twelve, not fifteen rounded units")
	check(consumed(world, "pingling", "military").requested == 240, "garrison consumption is distinct from civilian meals")
	check(world._state.cities.pingling.civilian_food_progress == 0 and world.audit().is_empty(), "daily fraction cycle returns to zero")

	var hungry := fixture({"workable_population": 0})
	hungry._state.cities.pingling.food = 1
	hungry._state.initial_totals = hungry.totals()
	hungry.advance(48)
	check(hungry._state.cities.pingling.food == 0 and hungry.audit().is_empty(), "shortage never creates negative food")
	check(consumed(hungry, "pingling", "military").eaten == 1, "only one physical ration can be consumed")
	check(consumed(hungry, "pingling", "civilian") == {"requested": 96, "eaten": 0, "shortfall": 96}, "unmet civilian demand is explicit and is not counted as eaten")
	check(hungry._state.cities.pingling.population == 20, "civilian demography and hunger attrition deliberately deferred")

func _test_three_months() -> void:
	var daily := Simulation.new(184)
	for day in range(90):
		check(daily.advance(24), "day %d advances" % (day + 1))
		check(daily.audit().is_empty(), "day %d food/weapons/people conservation" % (day + 1))
		check(daily.totals().civilian_population == 50, "day %d fixed civilian population" % (day + 1))
	var state := daily.snapshot()
	var event_totals := {"food_produced": 0, "weapons_produced": 0, "food_consumed": 0,
		"food_consumed_civilian": 0, "food_consumed_military": 0, "food_shortfall_civilian": 0, "food_shortfall_military": 0}
	var valid_events := true
	for event in state.events:
		valid_events = valid_events and event.time_seconds == event.hour * 3600.0
		if event.kind == "production":
			var detail: Dictionary = event.details
			var labor: Dictionary = detail.labor
			valid_events = valid_events and state.cities.has(detail.city) and labor.farmers + labor.crafters <= detail.workable_population
			valid_events = valid_events and labor.farmers <= detail.arable_land and labor.crafters <= detail.workshop_capacity and not labor.besieged
			valid_events = valid_events and detail.amounts.food >= 0 and detail.amounts.weapons >= 0
			for resource in ["food", "weapons"]:
				event_totals[resource + "_produced"] += detail.amounts[resource]
		elif event.kind == "consumption":
			var detail: Dictionary = event.details
			valid_events = valid_events and (state.cities.has(detail.entity) or state.armies.has(detail.entity))
			valid_events = valid_events and detail.eaten >= 0 and detail.shortfall >= 0 and detail.requested == detail.eaten + detail.shortfall
			valid_events = valid_events and detail.food_delta == -detail.eaten
			if detail.consumer == "civilian":
				valid_events = valid_events and event.hour % 24 == 0 and detail.period_hours == 24
			else:
				valid_events = valid_events and detail.period_hours == 1
			event_totals.food_consumed += detail.eaten
			event_totals["food_consumed_" + detail.consumer] += detail.eaten
			event_totals["food_shortfall_" + detail.consumer] += detail.shortfall
	check(valid_events, "all ninety-day economy events have truthful time/source/capacity/demand")
	for field in event_totals:
		check(event_totals[field] == state.ledger[field], "event reconstruction matches " + field)
	check(state.ledger.food_produced == 12960 and state.ledger.weapons_produced == 269, "three months match independently calculated monthly rates, including fifteen-hour siege interruption")
	check(production(daily, "pingling") == {"food": 8640, "weapons": 90}, "offscreen Pingling produces exact three-month capacities")
	check(consumed(daily, "pingling", "civilian").eaten == 4320 and consumed(daily, "pingling", "military").eaten == 4320, "civilian and garrison consumption each match three-month person-hours")
	check(state.cities.pingling.food == 500, "sustainable fixture is conserved, not topped up by a script")
	check(daily.totals().food == state.initial_totals.food + event_totals.food_produced - event_totals.food_consumed, "food reconstructed solely from explicit creation/consumption across three months")
	check(state.armies.relief.soldiers == 0 and state.campaign_ended and state.hour == 2160, "autonomous economy continues after actual player army starvation")
	var batch := Simulation.new(184)
	check(batch.advance(2160), "one batched three-month request accepted")
	check(batch.snapshot() == state, "same seed/actions in daily and whole-period chunks produce identical state and event history")
	var replay := Simulation.new(184)
	replay.advance(719)
	replay.advance_seconds(0.5)
	replay.advance_seconds(1441 * 3600.0 - 0.5)
	check(replay.snapshot() == state, "fractional battle-compatible clock chunks do not duplicate economic boundaries")
	print("ECONOMY_90_DAYS " + JSON.stringify({"hour": state.hour, "population": daily.totals().civilian_population,
		"food_produced": state.ledger.food_produced, "weapons_produced": state.ledger.weapons_produced,
		"food_consumed": state.ledger.food_consumed, "final_food": daily.totals().food, "events": state.events.size()}))

func _test_battle_boundary() -> void:
	var world := Simulation.new()
	world._state.armies.relief.food = 10000
	world._state.initial_totals = world.totals()
	world.march("river")
	world.advance_seconds(720 * 3600.0 - 0.25)
	var reserved: Dictionary = world.create_battle_ticket()
	check(reserved.ok, "actual surviving local army can reserve encounter before monthly boundary")
	var battle: RefCounted = world.start_battle(reserved.ticket.battle_id)
	battle.elapsed = 0.25 # Exact elapsed-time seam; no fabricated battle outcome.
	check(world.sync_battle_time(reserved.ticket.battle_id), "local battle advances authoritative monthly/day boundary")
	check(production(world, "pingling") == {"food": 2880, "weapons": 30}, "battle crossing boundary completes one month's actual work")
	check(consumed(world, "pingling", "civilian").eaten == 1440, "battle crossing boundary charges daily civilian food once")
	check(consumed(world, "relief", "military").eaten == 4320, "battle reservation does not hide any of sixty soldiers from upkeep")
	var state := world.snapshot()
	check(world.sync_battle_time(reserved.ticket.battle_id) and world.snapshot() == state, "repeat battle sync cannot repeat production or consumption")
	check(world.audit().is_empty(), "locked world remains conserved after month boundary")

func _test_invalid_state() -> void:
	var invalid := [
		{"population": -1}, {"workable_population": -1}, {"workable_population": 21},
		{"arable_land": -1}, {"workshop_capacity": -1}, {"stability": -1}, {"stability": 101},
		{"food": -1}, {"weapons": -1}, {"population": 20.5},
		{"civilian_food_progress": 10}, {"civilian_food_progress": -1},
		{"production_progress": {"food": -1, "weapons": 0}},
		{"production_progress": {"food": 72000, "weapons": 0}},
		{"production_rates": {"food_per_farmer_month": -1, "weapons_per_crafter_month": 15}},
		{"production_rates": {"food_per_farmer_month": 1.5, "weapons_per_crafter_month": 15}},
		{"production_rates": {}}, {"production_rates": []}, {"production_rates": null},
		{"production_rates": {"food_per_farmer_month": "360", "weapons_per_crafter_month": 15}},
		{"production_rates": {"food_per_farmer_month": 9223372036854775807, "weapons_per_crafter_month": 15}},
		{"production_progress": {"food": 0}}, {"production_progress": []}, {"production_progress": null},
		{"production_progress": {"food": 0, "weapons": "0"}},
		{"population": "20"}, {"population": 9223372036854775807}, {"workable_population": null},
		{"arable_land": {}}, {"stability": "100"}, {"food": "500"},
	]
	for fields in invalid:
		var world := Simulation.new()
		world._state.cities.pingling.merge(fields, true)
		var state := world.snapshot()
		check(not world.audit().is_empty(), "audit rejects invalid economic input " + str(fields))
		check(not world.advance(1) and world.snapshot() == state, "invalid economic input is rejected before mutation, never silently clamped")
	for field in ["population", "workable_population", "arable_land", "workshop_capacity", "stability", "production_rates", "production_progress", "civilian_food_progress", "food", "weapons", "soldiers"]:
		var missing := Simulation.new()
		missing._state.cities.pingling.erase(field)
		var state := missing.snapshot()
		check(not missing.audit().is_empty(), "missing economic field is reported without a script error: " + field)
		check(not missing.advance(1) and missing.snapshot() == state, "missing economic field cannot partially advance: " + field)
	for field in ["food_produced", "weapons_produced", "food_consumed", "food_consumed_civilian", "food_consumed_military", "food_shortfall_civilian", "food_shortfall_military"]:
		var negative_ledger := Simulation.new()
		negative_ledger._state.ledger[field] = -1
		var state := negative_ledger.snapshot()
		check(not negative_ledger.audit().is_empty(), "negative economy ledger rejected: " + field)
		check(not negative_ledger.advance(1) and negative_ledger.snapshot() == state, "negative ledger cannot advance or silently repair")
	var offset_ledger := Simulation.new()
	offset_ledger._state.ledger.food_consumed_civilian = -1
	offset_ledger._state.ledger.food_consumed_military = 1
	check(not offset_ledger.audit().is_empty(), "offsetting negative consumption cannot hide behind a correct aggregate sum")
	var invalid_battle := Simulation.new()
	invalid_battle.march("river")
	invalid_battle.advance(3)
	var ticket: Dictionary = invalid_battle.create_battle_ticket()
	var battle: RefCounted = invalid_battle.start_battle(ticket.ticket.battle_id)
	battle.elapsed = 3600.0
	invalid_battle._state.cities.hequ.production_rates = {}
	var invalid_battle_state := invalid_battle.snapshot()
	check(not invalid_battle.sync_battle_time(ticket.ticket.battle_id) and invalid_battle.snapshot() == invalid_battle_state,
		"malformed economy also blocks battle-owned clock before any mutation")
	var changed_population := Simulation.new()
	changed_population._state.cities.pingling.population += 1
	check("civilian population conservation" in changed_population.audit(), "unledgered people cannot appear")
	var changed_ledger := Simulation.new()
	changed_ledger._state.ledger.food_consumed_civilian += 1
	check("consumption accounting" in changed_ledger.audit(), "civilian and military consumption must sum to global ledger")
	var isolated := Simulation.new()
	var copy: Dictionary = isolated.snapshot()
	copy.cities.pingling.production_rates.food_per_farmer_month = 9999
	var local: Dictionary = isolated.player_view()
	local.local_city.production_progress.food = 9999
	check(isolated.snapshot().cities.pingling.production_rates.food_per_farmer_month == 360 and isolated.snapshot().cities.pingling.production_progress.food == 0, "economic rates and fractional progress are detached from presentation")
	isolated.advance(24)
	isolated.reset()
	check(isolated.snapshot().cities.pingling.production_progress == {"food": 0, "weapons": 0} and isolated.audit().is_empty(), "reset clears all economic progress and recomputes initial population")

func _test_local_view() -> void:
	var world := Simulation.new()
	var view: Dictionary = world.player_view()
	var plan: Dictionary = view.local_city.production_plan
	check(plan.farmers == 8 and plan.crafters == 2 and plan.hours_per_month == 720, "local view exposes current shared labor allocation")
	check(plan.food_per_month_numerator == 288000 and plan.weapons_per_month_numerator == 3000 and plan.rate_denominator == 100,
		"local view exposes exact current monthly capacities from authoritative plan")
	check(plan.civilian_food_per_hour_numerator == 20 and plan.civilian_food_rate_denominator == 10 and plan.hours_per_day == 24,
		"local view exposes civilian ration rate without UI dependence on global configuration")
	check(not view.has("cities") and not view.has("production_plan") and not view.known.anping.contents.has("production_plan"), "remote economy is not leaked into player intelligence")
	plan.farmers = 9999
	check(world.player_view().local_city.production_plan.farmers == 8, "derived local plan is detached")
	world._state.cities.pingling.stability = 50
	check(world.player_view().local_city.production_plan.food_per_month_numerator == 144000, "view and simulation share the same effective production calculation")
	world.march("road")
	check(world.player_view().local_city.is_empty(), "marching player cannot keep a live remote economy panel")
	world.advance(6)
	check(world.player_view().local_city.id == "anping" and not world.player_view().local_city.production_plan.besieged, "arrival reveals local siege change without exposing other cities")

func _test_capacity_boundaries() -> void:
	var capped := Simulation.new()
	capped._state.cities.pingling.food = Simulation.MAX_ECONOMY_STOCK
	capped._state.initial_totals = capped.totals()
	check(capped.audit().is_empty(), "stock exactly at safety cap is a valid state")
	var before := capped.snapshot()
	check(not capped.advance(1) and capped.snapshot() == before, "positive production at capped stock rejects the whole request without mutation")
	check(capped.advance_seconds(0.5) and capped.audit().is_empty(), "fractional time with no economic boundary can still advance at cap")
	before = capped.snapshot()
	check(not capped.transfer("relief", "pingling", "food", 1) and capped.snapshot() == before, "inventory transfer also respects destination capacity atomically")

	var exact := Simulation.new()
	exact._state.cities.pingling.food = Simulation.MAX_ECONOMY_STOCK - 4
	exact._state.initial_totals = exact.totals()
	check(exact.advance(1) and exact.audit().is_empty(), "exact production headroom is sufficient")
	check(exact._state.cities.pingling.food == Simulation.MAX_ECONOMY_STOCK - 2, "headroom guard does not alter real production or consumption")
	before = exact.snapshot()
	check(not exact.advance(1) and exact.snapshot() == before, "preflight refuses insufficient intermediate headroom rather than relying on a later meal")

	var offset := Simulation.new()
	offset._state.ledger.food_produced = Simulation.MAX_ECONOMY_STOCK
	offset._state.ledger.food_consumed = Simulation.MAX_ECONOMY_STOCK
	offset._state.ledger.food_consumed_military = Simulation.MAX_ECONOMY_STOCK
	check(offset.audit().is_empty(), "offset cumulative ledgers at cap preserve conservation")
	before = offset.snapshot()
	check(not offset.advance(1) and offset.snapshot() == before and offset.audit().is_empty(), "cumulative production and consumption headroom is checked before mutation")

	for field in ["food_shortfall_civilian", "food_shortfall_military"]:
		var shortfall := Simulation.new()
		shortfall._state.ledger[field] = Simulation.MAX_ECONOMY_STOCK
		check(shortfall.audit().is_empty(), "cumulative shortfall at cap is valid")
		before = shortfall.snapshot()
		check(not shortfall.advance(24) and shortfall.snapshot() == before, "maximum possible shortfall must fit before a multi-boundary request")

	var weapon_cap := Simulation.new()
	weapon_cap._state.cities.pingling.weapons = Simulation.MAX_ECONOMY_STOCK
	weapon_cap._state.initial_totals = weapon_cap.totals()
	check(weapon_cap.advance(23) and weapon_cap.audit().is_empty(), "fractional crafting progress can accrue while stock is capped")
	before = weapon_cap.snapshot()
	check(not weapon_cap.advance(1) and weapon_cap.snapshot() == before, "completing a crafted weapon requires inventory headroom")

	var cargo_cap := Simulation.new()
	cargo_cap.advance(1)
	cargo_cap._state.armies.besiegers.food = Simulation.MAX_ECONOMY_STOCK
	# Rebase the test inventory while preserving prior actual production/consumption.
	cargo_cap._state.initial_totals.food = cargo_cap.totals().food - cargo_cap._state.ledger.food_produced + cargo_cap._state.ledger.food_consumed
	check(cargo_cap.audit().is_empty(), "capped army with real cargo en route is coherent")
	before = cargo_cap.snapshot()
	check(not cargo_cap.advance(5) and cargo_cap.snapshot() == before, "convoy arrival capacity is included in clock headroom")

	for mode in ["stock", "ledger"]:
		var world := Simulation.new()
		world.march("river")
		world.advance(3)
		var reservation: Dictionary = world.create_battle_ticket()
		var battle: RefCounted = world.start_battle(reservation.ticket.battle_id)
		if mode == "stock":
			var increase: int = Simulation.MAX_ECONOMY_STOCK - int(world._state.cities.pingling.food)
			world._state.cities.pingling.food += increase
			world._state.initial_totals.food += increase
		else:
			var increase: int = Simulation.MAX_ECONOMY_STOCK - int(world._state.ledger.food_consumed)
			world._state.ledger.food_consumed += increase
			world._state.ledger.food_consumed_military += increase
			world._state.ledger.food_produced += increase
		check(world.audit().is_empty(), "battle cap fixture is coherent: " + mode)
		battle.elapsed = 3600.0
		before = world.snapshot()
		check(not world.sync_battle_time(reservation.ticket.battle_id) and world.snapshot() == before,
			"battle-owned clock rejects insufficient headroom without changing time, tickets or resources: " + mode)
		check(world.audit().is_empty(), "rejected battle advance leaves valid state: " + mode)

	var maximum := fixture({"population": Simulation.MAX_ECONOMY_PEOPLE, "workable_population": Simulation.MAX_ECONOMY_PEOPLE,
		"arable_land": Simulation.MAX_ECONOMY_PEOPLE, "production_rates": {"food_per_farmer_month": Simulation.MAX_PRODUCTION_RATE, "weapons_per_crafter_month": Simulation.MAX_PRODUCTION_RATE}})
	# floor(1e9 farmers * 1e6 food/month * 8760 hours / 720 hours/month).
	# The hourly work numerator times 8760 would overflow signed 64-bit if unsplit.
	var maximum_year_food := 12_166_666_666_666_666
	maximum._state.cities.pingling.food = Simulation.MAX_ECONOMY_STOCK - maximum_year_food
	maximum._state.initial_totals = maximum.totals()
	check(maximum.audit().is_empty(), "maximal documented input values form a valid economic state")
	check(maximum._economy_has_headroom(Simulation.MAX_ADVANCE * 3600.0), "maximum-duration headroom calculation avoids intermediate integer overflow")
	maximum._state.cities.pingling.food += 1
	maximum._state.initial_totals.food += 1
	check(not maximum._economy_has_headroom(Simulation.MAX_ADVANCE * 3600.0), "maximum-duration calculation distinguishes exact capacity from one excess unit")
