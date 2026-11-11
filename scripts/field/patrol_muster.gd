extends RefCounted
## The river patrol leaves the original relief army at Pingling and uses its recorded
## march deadline. Replaying the opening on a fresh world also reproduces its convoys and rations.
const ROUTE := "river"
const GATE_CITY := "hequ"
const COMPANY_SIZE := 32

static func arrive(world, seed_value: int) -> bool:
	if not world.reset(seed_value) or not world.march(ROUTE):
		return false
	var departure: Dictionary = world.player_view()
	var march: Dictionary = departure.army.march
	if march.get("route") != ROUTE or march.get("destination") != GATE_CITY:
		return false
	var elapsed := float(march.arrives_at_seconds) - float(departure.time_seconds)
	if elapsed <= 0.0 or not world.advance_seconds(elapsed):
		return false
	var arrival: Dictionary = world.player_view()
	return arrival.army.location == GATE_CITY and arrival.army.march.is_empty() and arrival.time_seconds == march.arrives_at_seconds

static func ordinary_for(people: int, weapons: int, hero: bool = false) -> int:
	var hero_people := 1 if hero else 0
	var hero_weapons := 2 if hero else 0
	if people <= hero_people or weapons <= hero_weapons:
		return 0
	var billets := mini(people - hero_people, weapons - hero_weapons)
	# Each complete set of 33 billets contains 32 ordinary soldiers and one officer.
	# A partial company also needs its own officer. Integer arithmetic preserves large rosters.
	var set_size := COMPANY_SIZE + 1
	@warning_ignore("integer_division")
	var full_sets := billets / set_size
	return full_sets * COMPANY_SIZE + maxi(0, billets % set_size - 1)
