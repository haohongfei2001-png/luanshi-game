extends SceneTree
## Optional independent property review: 36 seeded scenarios plus capture continuity.
## Mutations of _state below are privileged fixture setup, not gameplay actions.
const Sim = preload("res://scripts/world_sim.gd")
var failures = 0
var assertions = 0
func check(ok: bool, message: String) -> void:
	assertions += 1
	if not ok:
		failures += 1
		push_error(message)
func _initialize() -> void:
	var rng = RandomNumberGenerator.new()
	rng.seed = 120947
	for i in range(36):
		var world = Sim.new(184)
		var city = world._state.cities.pingling
		city.population = rng.randi_range(0, 100)
		city.workable_population = rng.randi_range(0, city.population)
		city.arable_land = rng.randi_range(0, 100)
		city.workshop_capacity = rng.randi_range(0, 100)
		city.stability = rng.randi_range(0, 100)
		city.production_rates.food_per_farmer_month = rng.randi_range(0, 500)
		city.production_rates.weapons_per_crafter_month = rng.randi_range(0, 80)
		city.food = 1000000
		world._state.initial_totals = world.totals()
		var hours = rng.randi_range(1, 2160)
		var farmers = mini(city.workable_population, city.arable_land)
		var crafters = mini(city.workable_population - farmers, city.workshop_capacity)
		var expected = {"food": [farmers,city.production_rates.food_per_farmer_month], "weapons": [crafters,city.production_rates.weapons_per_crafter_month]}
		check(world.advance(hours), "random case %d accepted" % i)
		var actual = {"food":0,"weapons":0}
		for event in world._state.events:
			if event.kind == "production" and event.details.city == "pingling":
				for resource in actual:
					actual[resource] += event.details.amounts[resource]
					check(event.details.progress_after[resource] == (event.details.progress_before[resource] + event.details.labor[resource + "_per_month_numerator"]) % 72000, "event remainder equation")
		for resource in actual:
			var numerator = expected[resource][0] * expected[resource][1] * city.stability * hours
			@warning_ignore("integer_division")
			var units = numerator / 72000
			check(actual[resource] == units, "random case %d %s inventory" % [i, resource])
			check(city.production_progress[resource] == numerator % 72000, "random case %d %s progress" % [i, resource])
		check(world.audit().is_empty(), "random case audit %d" % i)
	var captured = Sim.new(184)
	captured.march("river")
	captured.advance_seconds(3.5 * 3600.0)
	var before = captured.snapshot().cities.hequ
	check(captured.seize_depot(), "capture at partial hour")
	var after = captured.snapshot().cities.hequ
	for field in ["population", "workable_population", "arable_land", "workshop_capacity", "stability", "food", "weapons", "production_rates", "production_progress", "civilian_food_progress"]:
		check(before[field] == after[field], "capture preserves " + field)
	captured.advance_seconds(20.5 * 3600.0)
	check(captured._state.cities.hequ.production_progress.weapons == 0, "captured workshops complete one daily weapon, no reset or duplicate accrual")
	check(captured._state.cities.hequ.weapons == before.weapons + 1, "captured stock receives actual completed weapon")
	check(captured.audit().is_empty(), "capture economics conserve")
	print("INDEPENDENT_ECO_REVIEW ", assertions, " assertions / ", failures, " failures")
	quit(0 if failures == 0 else 1)
