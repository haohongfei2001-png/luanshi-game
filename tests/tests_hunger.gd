extends SceneTree

const World := preload("res://scripts/world_sim.gd")
const Adapter := preload("res://scripts/battle_adapter.gd")
const Battle := preload("res://scripts/battle_sim.gd")
var assertions := 0
var failures: Array[String] = []

class FailingSettlementWorld extends WorldSimulation:
	var audit_calls := 0
	var inject_failure := true
	func audit() -> Array[String]:
		var errors := super.audit()
		audit_calls += 1
		if inject_failure and audit_calls == 2:
			errors.append("injected post-condition settlement failure")
		return errors

func _initialize() -> void:
	call_deferred("_run")

func check(condition: bool, message: String) -> void:
	assertions += 1
	if not condition:
		failures.append(message)
		push_error("FAIL: " + message)

func _run() -> void:
	_test_staged_warning_and_attrition()
	_test_partial_rations()
	_test_recovery_and_activity()
	_test_faction_and_garrison_symmetry()
	_test_battle_entry()
	_test_reserved_and_rollback()
	_test_invalid_and_caps()
	_test_replay_and_knowledge()
	print("Hunger tests: %d assertions, %d failures" % [assertions, failures.size()])
	print("HUNGER_TEST_SUMMARY " + JSON.stringify({"assertions": assertions, "failures": failures.size(), "messages": failures}))
	quit(0 if failures.is_empty() else 1)

func empty_relief(world: WorldSimulation) -> void:
	check(world.transfer("relief", "pingling", "food", world._state.armies.relief.food), "rations are left in real city stock")

func condition_events(world: WorldSimulation, entity: String, kind: String = "military_condition") -> Array:
	return world._state.events.filter(func(event: Dictionary) -> bool: return event.kind == kind and event.details.entity == entity)

func _test_staged_warning_and_attrition() -> void:
	var world := World.new()
	empty_relief(world)
	var view := world.player_view()
	check(view.army.condition.low_food and view.army.condition.food_hours == 0.0, "pre-march stock warning is observable before any hunger")
	check(view.army.condition.hunger == 0 and view.army.soldiers == 60, "low stock alone does not kill or manufacture hunger")
	check(world.march("mountain"), "undersupplied march may be attempted")
	for hour in range(1, 4):
		check(world.advance(1), "hungry march hour %d advances" % hour)
		view = world.player_view()
		var condition: Dictionary = view.army.condition
		check(condition.hunger == hour * 1000 and condition.fatigue == hour * 14 and condition.morale == 100 - hour * 10, "actual missing meals and march explain condition at %d" % hour)
		check(condition.stage == ["shortage", "weakened", "attrition"][hour - 1], "warning stage %d visible in player view" % hour)
		check(condition.last_needed == 6 and condition.last_eaten == 0 and condition.activity == "march", "own ration and activity evidence visible")
		check(condition.modifiers.damage_percent < 100 and condition.modifiers.speed_percent < 100, "shortage weakens combat before first death")
		check(view.army.soldiers == (60 if hour < 3 else 59), "no instant wipe; two warned boundaries precede first casualty")
		check(world.audit().is_empty(), "staged starvation is conserved")
	var attrition := condition_events(world, "relief", "starvation_attrition")
	check(attrition.size() == 1 and attrition[0].time_seconds == 10800.0 and attrition[0].details.dead == 1, "first death has exact world time and bounded count")
	var events := condition_events(world, "relief")
	check(events[0].details.after.stage == "shortage" and events[1].details.after.stage == "weakened", "prior warnings persist as immutable evidence")
	check(world._state.events.find(events[2]) < world._state.events.find(attrition[0]), "same-hour warning logged before attrition")
	check(world._state.ledger.starvation_dead == 1, "starvation deaths are categorized within conserved dead ledger")
	print("HUNGER_STAGES " + JSON.stringify({"first_warning_hour": 1, "weakened_hour": 2, "first_death_hour": 3, "survivors": view.army.soldiers}))

func _test_partial_rations() -> void:
	var world := World.new()
	empty_relief(world)
	for hour in range(1, 7):
		check(world.transfer("pingling", "relief", "food", 3), "half ration comes from city, not creation")
		check(world.advance(1), "half-ration hour advances")
		var condition: Dictionary = world._state.armies.relief.condition
		check(condition.hunger == hour * 500 and condition.fatigue == hour * 6 and condition.morale == 100 - hour * 5, "half meals have half deprivation impact")
		check(world._state.armies.relief.soldiers == (60 if hour < 6 else 59), "partial deficit delays first death until three full-ration equivalents")
		check(world.audit().is_empty(), "partial ration conservation")
	check(world._state.armies.relief.condition.stage == "attrition", "partial deficits eventually reach the same attrition threshold")
	var tiny := World.new()
	tiny._state.armies.relief.soldiers = World.MAX_ECONOMY_PEOPLE
	tiny._state.armies.relief.food = 99_999_999
	tiny._state.initial_totals = tiny.totals()
	check(tiny.advance(1) and tiny.audit().is_empty(), "maximum supported military count is arithmetically safe")
	check(tiny._state.armies.relief.condition.hunger == 1 and tiny._state.armies.relief.soldiers == World.MAX_ECONOMY_PEOPLE, "tiny deficit is conservatively rounded to one bounded point, not whole-hour starvation")

func strain(world: WorldSimulation, id: String = "relief") -> void:
	world._entity(id).condition.fatigue = 60
	world._entity(id).condition.morale = 50

func _test_recovery_and_activity() -> void:
	var world := World.new()
	empty_relief(world)
	world.advance(4)
	var soldiers: int = world._state.armies.relief.soldiers
	var weapons: int = world._state.armies.relief.weapons
	var before: Dictionary = world._state.armies.relief.condition.duplicate(true)
	check(world.transfer("pingling", "relief", "food", 100), "real supplies can interrupt attrition")
	check(world._state.armies.relief.condition == before, "supply UI does not instantly heal fatigue, morale or hunger")
	check(world.advance(1), "one safe fed recovery hour passes")
	var condition: Dictionary = world._state.armies.relief.condition
	check(condition.stage == "recovering" and condition.hunger == 3000 and condition.fatigue == 42 and condition.morale == 64, "fed rest recovers gradually rather than resets")
	check(world._state.armies.relief.soldiers == soldiers, "full meal stops new deaths immediately even with residual hunger")
	check(world.advance(10), "sufficient fed rest passes on unified clock")
	condition = world._state.armies.relief.condition
	check(condition.hunger == 0 and condition.fatigue == 0 and condition.morale == 100 and condition.stage == "fed", "bounded condition fully recovers after enough real time")
	check(world._state.armies.relief.soldiers == soldiers and world._state.armies.relief.weapons == weapons, "recovery resurrects no people or weapons")
	check(world.audit().is_empty() and world._state.siege.outcome == "captured", "recovery also advances offscreen war and conservation")
	before = condition.duplicate(true)
	for repeat in range(10):
		world.player_view()
		world.observe_city("pingling")
		world.advance(0)
	check(world._state.armies.relief.condition == before and world._state.hour == 15, "menus, observation and zero advances cannot farm recovery")

	var resting := World.new()
	strain(resting)
	resting.advance(1)
	check(resting._state.armies.relief.condition.fatigue == 54 and resting._state.armies.relief.condition.morale == 54, "safe stationary friendly camp allows recovery")
	var marching := World.new()
	strain(marching)
	marching.march("river")
	marching.advance(3)
	check(marching._state.armies.relief.condition.fatigue == 66 and marching._state.armies.relief.condition.morale == 50, "march and exact arrival hour never count as rest")
	marching.advance(1)
	check(marching._state.armies.relief.condition.fatigue == 66 and marching._state.armies.relief.condition.last_activity == "alert", "standing in hostile depot is not safe rest")
	check(marching._state.cities.hequ.condition.last_activity == "alert", "garrison facing local hostile force is not resting either")
	var siege := World.new()
	strain(siege, "besiegers")
	siege.advance(1)
	check(siege._state.armies.besiegers.condition.fatigue == 61 and siege._state.armies.besiegers.condition.morale == 50, "stationary siege army is exerting, not recovering")
	check(siege._state.cities.anping.condition.last_activity == "siege", "besieged garrison has same exertion classification")
	var mixed := World.new()
	mixed._state.cities.hequ.owner = "sheng" # Controlled safe destination, no event shortcut.
	mixed.advance_seconds(3599.0)
	strain(mixed)
	mixed.march("river")
	mixed.advance_seconds(10801.0)
	check(mixed._state.armies.relief.condition.fatigue == 68, "one second at destination cannot award a whole hour of rest")
	check(mixed._state.armies.relief.condition.last_activity == "march", "mixed hour preserves earlier travel in activity evidence")
	mixed.advance(1)
	check(mixed._state.armies.relief.condition.fatigue == 62 and mixed._state.armies.relief.condition.morale == 54, "following full safe hour genuinely recovers")

func _test_faction_and_garrison_symmetry() -> void:
	var world := World.new()
	world._state.siege.active = false
	world._state.cities.pingling.arable_land = 0
	world._state.cities.hequ.arable_land = 0
	world._state.armies.besiegers.location = "hequ"
	for id in ["relief", "besiegers", "pingling", "hequ"]:
		var force := world._entity(id)
		force.soldiers = 20
		force.weapons = 10
		force.food = 0
	world._state.initial_totals = world.totals()
	for hour in range(1, 9):
		check(world.advance(1), "symmetric hunger advances")
		var expected: Dictionary = world._state.armies.relief.condition
		for id in ["besiegers", "pingling", "hequ"]:
			check(world._entity(id).condition == expected, "identical military rules for " + id)
			check(world._entity(id).soldiers == world._state.armies.relief.soldiers, "identical attrition for " + id)
		check(world.audit().is_empty(), "shared faction/garrison ledger conserves")
	var dead_from_events := 0
	for event in world._state.events:
		if event.kind == "starvation_attrition":
			dead_from_events += event.details.dead
	check(world._state.ledger.starvation_dead == 24 and dead_from_events == 24, "four forces lose exactly one per hour after warnings; ledger reconstructed")
	check(world.totals().civilian_population == 50, "military hunger does not add deferred civilian demography")

func local_world() -> WorldSimulation:
	# Existing condition arithmetic is an explicit legacy fixture.
	var world := World.new(184, "legacy_test_v0")
	world.march("river")
	world.advance(3)
	return world

func begin(world: WorldSimulation) -> BattleAdapter:
	var adapter := Adapter.new(world)
	check(adapter.begin_local_depot().ok, "local battle starts from actual force")
	return adapter

func victory(simulation: BattleSimulation) -> void:
	# Transaction fixture only; actual combat smoke remains independently required.
	for unit in simulation.units:
		if unit.team == 1:
			simulation._hurt(unit, 1000.0, false)
	simulation._check_result()

func _test_battle_entry() -> void:
	var healthy := local_world()
	var normal := begin(healthy)
	check(normal.simulation.player().speed == 7.0 and normal.simulation.player().damage == 26.0 and normal.simulation.player().hp == 360.0, "explicit legacy condition fixture unchanged; finite profiles have separate coverage")
	var world := local_world()
	for id in ["relief", "hequ"]:
		strain(world, id)
		world._entity(id).condition.hunger = 2000
	var before := world.totals()
	var adapter := begin(world)
	check(world.totals() == before, "condition snapshot invents no inventory or personnel")
	var modifiers: Dictionary = adapter.ticket.reserved_roster_snapshot[0][0].condition_modifiers
	check(modifiers == adapter.ticket.reserved_roster_snapshot[1][0].condition_modifiers, "equal condition gives equal enemy and ally modifiers")
	check(modifiers.speed_percent == 88 and modifiers.damage_percent == 88, "configured fatigue, morale and hunger produce explainable 12 percent penalty")
	for unit in adapter.simulation.units:
		var speed := 7.0 if unit.hero else 3.0
		var damage := (26.0 if unit.hero else 13.0) if unit.weapon != "" else (7.0 if unit.hero else 4.0)
		check(is_equal_approx(unit.speed, speed * 0.88) and is_equal_approx(unit.damage, damage * 0.88), "entry penalties apply to actual armed/unarmed participant")
		check(unit.hp == (360.0 if unit.hero else 100.0), "condition does not manufacture HP damage or growth")
	adapter.ticket.reserved_roster_snapshot[0][0].condition.fatigue = 0
	check(world.battle_ticket(adapter.ticket.battle_id).reserved_roster_snapshot[0][0].condition.fatigue == 60, "public ticket condition is detached")
	var sim := adapter.simulation
	var enemy: Dictionary = sim.units.filter(func(unit: Dictionary) -> bool: return unit.team == 1)[0]
	sim.player().pos = Vector2.ZERO
	enemy.pos = Vector2(3.5, 0.0)
	sim.set_player_input(Vector2.ZERO, Vector2.RIGHT)
	check(sim.use_action("sweep") and is_equal_approx(enemy.hp, 100.0 - 44.0 * 0.88), "sweep uses the same condition damage penalty as basic attack")
	enemy.hp = 100.0
	enemy.pos = Vector2(4.0, 0.0)
	check(sim.use_action("lunge") and is_equal_approx(enemy.hp, 100.0 - 58.0 * 0.88), "lunge uses condition-scaled damage")
	check(is_equal_approx(sim.player().pos.x, 5.8 * 0.88), "lunge displacement follows movement condition")
	var capped := world._condition_modifiers({"fatigue": 100, "morale": 0, "hunger": 6000})
	check(capped == {"speed_percent": 80, "damage_percent": 75}, "penalties have hard lower limits, not total paralysis")

func _test_reserved_and_rollback() -> void:
	var fed := local_world()
	strain(fed)
	var fed_adapter := begin(fed)
	for unit in fed_adapter.simulation.units:
		unit.speed = 0.0
		unit.damage = 0.0
	fed_adapter.simulation.step(3600.0)
	check(fed_adapter.sync_world(), "fed active battle advances the shared clock")
	check(fed._state.armies.relief.condition.fatigue == 63 and fed._state.armies.relief.condition.morale == 50 and fed._state.armies.relief.condition.hunger == 0, "full meals in active battle do not grant fatigue or morale rest")
	check(not condition_events(fed, "relief")[-1].details.rested, "fed battle ledger explicitly rules out recovery")
	var world := local_world()
	# Put carried food back into a physical inventory before the lock.
	world._state.cities.pingling.food += world._state.armies.relief.food
	world._state.armies.relief.food = 0
	strain(world)
	var adapter := begin(world)
	var sim := adapter.simulation
	for unit in sim.units:
		unit.speed = 0.0
		unit.damage = 0.0
	for hour in range(6):
		sim.step(3600.0)
		check(adapter.sync_world() and world.audit().is_empty(), "long battle uses one clock and validates condition")
		check(world._state.armies.relief.condition.last_activity == "battle", "active battle is never rest")
		check(sim.alive_count(0, true) == 20 and sim.alive_count(1) == 15, "reserved local people not also killed by coarse attrition")
		var before := world.snapshot()
		check(adapter.sync_world() and before == world.snapshot(), "duplicate sync cannot apply hunger twice")
	check(world._state.armies.relief.soldiers == 56 and world._state.ledger.starvation_dead == 4, "only actual free reserves suffer staged hunger loss")
	check(world._state.armies.relief.condition.fatigue == 100 and world._state.armies.relief.condition.morale == 0, "condition saturates safely under sustained battle hunger")
	victory(sim)
	check(adapter.settle().ok and world.audit().is_empty(), "hungry world battle settles with existing conservation")
	var committed := world.snapshot()
	check(adapter.settle().ok and world.snapshot() == committed, "repeated settlement leaves condition and casualty ledger untouched")

	var rollback := FailingSettlementWorld.new()
	rollback.march("river")
	rollback.advance(3)
	rollback._state.cities.pingling.food += rollback._state.armies.relief.food
	rollback._state.armies.relief.food = 0
	adapter = begin(rollback)
	adapter.simulation.elapsed = 10800.0 # Inject elapsed time to cross warning and attrition during commit.
	victory(adapter.simulation)
	var snapshot := rollback.snapshot()
	var rejected := adapter.settle()
	check(not rejected.ok and rejected.reason == "settlement_audit_failed", "injected post-condition failure refuses settlement")
	check(rollback.snapshot() == snapshot, "rollback restores all condition, activity, starvation ledger, events and clock")
	rollback.inject_failure = false
	check(adapter.settle().ok and rollback.audit().is_empty(), "same outcome safely retries after complete rollback")
	check(rollback._state.ledger.starvation_dead == 1 and condition_events(rollback, "relief", "starvation_attrition").size() == 1, "retry does not duplicate hunger casualty or warning timeline")

func _test_invalid_and_caps() -> void:
	var invalid := [
		{"fatigue": -1}, {"fatigue": 101}, {"fatigue": 1.0}, {"fatigue": true},
		{"morale": -1}, {"morale": 101}, {"morale": null},
		{"hunger": -1}, {"hunger": 6001}, {"hunger": "1000"},
		{"last_needed": -1}, {"last_eaten": 1}, {"last_needed": 100000001},
		{"stage": "unknown"}, {"last_activity": "teleport"},
		{"activity_flags": []}, {"activity_flags": {"unknown": true}},
		{"activity_flags": {"rest": 1}}, {"activity_flags": {"rest": false}},
	]
	for change in invalid:
		var world := World.new()
		world._state.armies.relief.condition.merge(change, true)
		var before := world.snapshot()
		check(not world.audit().is_empty(), "bad condition audited: " + str(change))
		check(not world.advance(1) and world.snapshot() == before, "bad condition refuses before any world mutation")
	for bad in [null, [], "condition", 100]:
		var world := World.new()
		world._state.cities.hequ.condition = bad
		var before := world.snapshot()
		check(not world.advance_seconds(0.1) and not world.audit().is_empty() and world.snapshot() == before, "wrong condition container is rejected atomically")
	var missing := World.new()
	missing._state.armies.relief.condition.erase("hunger")
	check(not missing.advance(1), "missing required condition refuses arithmetic")
	for bad in [-1, 1.0, "1", World.MAX_ECONOMY_STOCK + 1]:
		var world := World.new()
		world._state.ledger.starvation_dead = bad
		var before := world.snapshot()
		check(not world.advance(1) and world.snapshot() == before, "bad starvation ledger refuses clock before mutation")
	var wrong_ledger := World.new()
	wrong_ledger._state.ledger.starvation_dead = 1
	check(not wrong_ledger.audit().is_empty() and not wrong_ledger.advance(1), "starvation category cannot exceed total deaths")
	var world := local_world()
	var adapter := begin(world)
	world._state.armies.relief.condition.fatigue = 101
	adapter.simulation.elapsed = 3600.0
	var before := world.snapshot()
	check(not adapter.sync_world() and world.snapshot() == before, "battle clock shares condition schema refusal")
	var cap := World.new()
	cap._state.ledger.starvation_dead = World.MAX_ECONOMY_STOCK
	cap._state.ledger.dead = World.MAX_ECONOMY_STOCK
	before = cap.snapshot()
	check(not cap.advance(1) and cap.snapshot() == before, "starvation ledger numeric headroom rejects before mutation")
	check(cap.advance_seconds(0.5), "fractional clock with no condition update needs no casualty headroom")
	for field in ["dead", "prisoners", "weapons_destroyed"]:
		var capped_ledger := World.new()
		capped_ledger._state.ledger[field] = World.MAX_ECONOMY_STOCK
		var capped_before := capped_ledger.snapshot()
		check(not capped_ledger.advance(1) and capped_ledger.snapshot() == capped_before, "loss-ledger headroom refuses atomically for " + field)
	var bounded := World.new()
	empty_relief(bounded)
	bounded.advance(80)
	check(bounded._state.armies.relief.condition.hunger == 6000 and bounded._state.armies.relief.condition.fatigue == 100 and bounded._state.armies.relief.condition.morale == 0, "sustained hunger values stay bounded")
	check(bounded._state.armies.relief.soldiers == 0 and condition_events(bounded, "relief", "starvation_attrition").size() == 60 and bounded._state.campaign_ended, "last real person dies once; no immortal commander or negative force")
	check(bounded.audit().is_empty(), "long attrition obeys all economic/personnel invariants")

func _test_replay_and_knowledge() -> void:
	var a := World.new()
	var b := World.new()
	var c := World.new()
	for world in [a, b, c]:
		empty_relief(world)
		world.march("mountain")
	a.advance(12)
	for hour in range(12):
		b.advance(1)
		for quarter in range(4):
			c.advance_seconds(900.0)
	check(a.snapshot() == b.snapshot() and b.snapshot() == c.snapshot(), "batched/hourly/fractional clocks reproduce complete condition and event state")
	var view := a.player_view()
	check(not view.has("armies") and not view.has("events") and not view.has("ledger"), "own hunger adds no global condition/attrition intelligence")
	check(view.known.anping.contents == {"owner": "sheng", "under_siege": true}, "remote old report remains unchanged during autonomous hunger")
	view.army.condition.fatigue = 0
	view.army.condition.activity_flags["rest"] = true
	view.army.condition.modifiers.damage_percent = 900
	check(a._state.armies.relief.condition.fatigue == 100 and a._state.armies.relief.condition.activity_flags.is_empty(), "player condition, flags and derived modifiers are detached")
	var local := local_world()
	check(not local.player_view().local_city.has("condition"), "physical city view does not expose new hostile military condition history")
	var first := World.new()
	first.advance(17)
	check(first.player_view().army.condition.low_food and first.player_view().army.condition.food_hours == 3.0, "remaining-food warning exists three fed hours before first deficit")
	check(first.player_view().army.condition.stage == "fed" and first._state.armies.relief.soldiers == 60, "low stores alone are warning, not starvation")
