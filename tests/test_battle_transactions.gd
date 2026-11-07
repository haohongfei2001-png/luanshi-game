extends SceneTree

const World := preload("res://scripts/world_sim.gd")
const Adapter := preload("res://scripts/battle_adapter.gd")
const UnitView := preload("res://scripts/unit_view.gd")
var assertions := 0
var failures: Array[String] = []

class FailingSettlementWorld extends WorldSimulation:
	var audit_calls := 0
	var inject_failure := true

	func audit() -> Array[String]:
		var errors := super.audit()
		audit_calls += 1
		if inject_failure and audit_calls == 2:
			errors.append("test injected post-settlement audit failure")
		return errors


func _initialize() -> void:
	call_deferred("_run")

func check(condition: bool, message: String) -> void:
	assertions += 1
	if not condition:
		failures.append(message)
		push_error("FAIL: " + message)

func local_world() -> WorldSimulation:
	var world := World.new(184)
	world.march("river")
	world.advance(3)
	return world

func begin(world: WorldSimulation) -> BattleAdapter:
	var adapter := Adapter.new(world)
	check(adapter.begin_local_depot().ok, "local depot battle starts")
	return adapter

func finish_victory(sim: BattleSimulation) -> void:
	# Isolated settlement fixture; end-to-end combat is tested separately below.
	for unit in sim.units:
		if unit.team == 1:
			sim._hurt(unit, 1000.0, false)
	sim._check_result()

func assert_rejected(world: WorldSimulation, outcome: Variant, label: String) -> void:
	var before := world.snapshot()
	check(not world.validate_battle_outcome(outcome).ok, label + " validation rejected")
	check(world.snapshot() == before, label + " inspection never mutates")
	check(not world.commit_battle_outcome(outcome).ok, label + " commit rejected")
	check(world.snapshot() == before, label + " commit never mutates")

func _run() -> void:
	var world := World.new(184)
	var before := world.snapshot()
	check(not world.create_battle_ticket().ok, "cannot attack distant depot")
	check(not world.create_battle_ticket("anping").ok, "unsupported encounters explicitly rejected")
	check(world.snapshot() == before, "rejected remote requests leave state unchanged")
	world.march("river")
	world.advance(2)
	before = world.snapshot()
	check(not world.create_battle_ticket().ok, "cannot attack while marching")
	check(world.snapshot() == before and world.player_view().army.location == "", "two hours cannot teleport army")
	world.advance(1)
	var total_before := world.totals()
	var reservation := world.create_battle_ticket()
	check(reservation.ok, "three-hour arrival permits local reservation")
	check(world.totals() == total_before, "reservation creates no soldiers or equipment")
	var ticket: Dictionary = reservation.ticket
	check(ticket.status == "reserved" and ticket.location == "hequ", "inspectable local reserved ticket")
	check(ticket.reserved_roster_snapshot[0].size() == 20 and ticket.reserved_roster_snapshot[1].size() == 15, "actual 20 vs 15 allocation includes commander")
	check(world.snapshot().armies.relief.soldiers == 60, "forty reserves stay in army and are not cloned")
	var weapons := 0
	for soldier in ticket.reserved_roster_snapshot[0]:
		weapons += 1 if soldier.weapon != "" else 0
	check(weapons == 10, "60 soldiers / 30 weapons becomes 10 armed of 20, not an elite full-armament sample")
	check(world.audit().is_empty(), "reservation audit passes")
	reservation.ticket.reserved_roster_snapshot[0][0].weapon = "forged"
	check(world.battle_ticket(ticket.battle_id).reserved_roster_snapshot[0][0].weapon == "spear", "returned ticket cannot mutate authority")
	before = world.snapshot()
	check(not world.create_battle_ticket().ok, "second ticket cannot double-assign participants")
	check(not world.march("grain_road"), "locked force cannot march away")
	check(not world.transfer("relief", "hequ", "weapons", 1), "locked inventory cannot transfer")
	check(not world.advance(1) and not world.advance_seconds(0.25), "strategy clock cannot double-advance local encounter")
	check(not world.seize_depot(), "legacy aggregate scenario cannot bypass running reservation")
	check(world.snapshot() == before, "rejected actions are transactionally read-only")
	check(world.cancel_battle_ticket(ticket.battle_id), "unstarted reservation can be cancelled")
	check(world.snapshot().battle_locks.is_empty() and world.totals() == total_before, "cancellation unlocks without losses")
	check(world.start_battle(ticket.battle_id) == null, "cancelled ticket cannot run")
	check(not world.cancel_battle_ticket(ticket.battle_id), "cancel is not repeated")
	var adapter := begin(world)
	var sim := adapter.simulation
	ticket = adapter.ticket
	check(world.start_battle(ticket.battle_id) == sim, "repeated start resumes same simulation rather than resetting")
	check(not world.cancel_battle_ticket(ticket.battle_id), "running fight cannot be cancelled to erase losses")
	check(sim.units.size() == 35 and sim.player().hero, "world-backed battlefield creates only the reserved actual people")
	check(sim.alive_count(0, true) == 20 and sim.alive_count(0) == 19, "commander occupies one slot in relief roster")
	var unarmed_count := 0
	for unit in sim.units:
		if unit.team == 0 and unit.weapon == "":
			unarmed_count += 1
			check(unit.damage == 4.0 and unit.range == 0.85, "unarmed soldier has no spear reach or damage")
			var visual := UnitView.new()
			visual.configure(unit)
			check(visual.weapon.get_child_count() == 0, "unarmed visual contains no default spear")
			visual.free()
	check(unarmed_count == 10, "ten visibly unarmed participants")
	assert_rejected(world, {}, "empty outcome")
	assert_rejected(world, null, "null outcome")
	assert_rejected(world, {"battle_id": []}, "wrong ID type")
	assert_rejected(world, {"battle_id": "forged"}, "unknown ticket")
	assert_rejected(world, {"battle_id": ticket.battle_id}, "unfinished battle")
	sim.step(0.25)
	check(adapter.sync_world(), "fractional battle elapsed reaches world")
	check(world.snapshot().time_seconds == 10800.25 and world.snapshot().hour == 3, "battle fractions are not rounded into hours")
	before = world.snapshot()
	check(adapter.sync_world() and world.snapshot() == before, "repeated synchronization consumes elapsed only once")
	# Two armed + one unarmed losses; one is a regular, not the commander.
	sim._hurt(sim.units[1], 1000.0, false)
	sim._hurt(sim.units[2], 1000.0, false)
	sim._hurt(sim.units[15], 1000.0, false)
	finish_victory(sim)
	var outcome := sim.outcome()
	check(outcome.forces[0].dead_ids.size() == 3 and outcome.forces[0].recovered_equipment == 2, "dead and recovered equipment reflect actual armed roster")
	check(outcome.spoils.weapons == 15 and outcome.forces[1].dead_ids.size() == 15, "spoils come only from dead equipped defenders")
	for field in ["elapsed_world_time", "player_hp", "result", "spoils", "forces", "retreat_positions"]:
		var forged := outcome.duplicate(true)
		forged[field] = "forged"
		assert_rejected(world, forged, "forged " + field)
	var extra := outcome.duplicate(true)
	extra["bonus_food"] = 900
	assert_rejected(world, extra, "extra fields")
	var old_weapon: String = sim.units[15].weapon
	sim.units[15].weapon = "spear"
	assert_rejected(world, sim.outcome(), "altered simulation equipment")
	sim.units[15].weapon = old_weapon
	check(world.validate_battle_outcome(outcome).ok, "matching inspectable terminal outcome is accepted")
	var inventory := world.totals()
	var receipt := adapter.settle()
	check(receipt.ok and receipt.depot_captured and not receipt.campaign_ended, "victory settles actual depot ownership")
	var state := world.snapshot()
	check(state.armies.relief.soldiers == 57 and state.cities.hequ.soldiers == 0, "only participating deaths removed; forty reserves remain")
	check(state.armies.relief.weapons == 45 and state.cities.hequ.weapons == 0, "15 real weapons move from defenders to relief and friendly weapons recovered")
	check(world.totals().weapons == inventory.weapons, "victory recovery and spoils conserve total equipment")
	check(state.armies.relief.location == "hequ" and state.cities.hequ.owner == "sheng", "winning does not teleport soldiers or food")
	check(state.battle_locks.is_empty() and state.battle_tickets[ticket.battle_id].status == "committed", "successful commit unlocks world")
	check(world.audit().is_empty(), "victory conservation audit")
	check(world.player_view().known.hequ.contents.owner == "sheng", "local observation reflects real victory")
	check(world.player_view().known.anping.observed_at == -72, "battle does not reveal remote siege truth")
	before = world.snapshot()
	var repeated := adapter.settle()
	check(repeated.ok and repeated.already_committed, "valid twice commit succeeds idempotently")
	check(world.snapshot() == before, "idempotence includes events, clock, equipment, and deaths")
	extra = outcome.duplicate(true)
	extra.spoils.weapons += 1
	assert_rejected(world, extra, "conflicting second commit")
	check(world.transfer("hequ", "relief", "food", 1), "settled force can use local depot inventory")
	check(world.march("grain_road") and world.player_view().army.location == "", "settled force can resume real march")
	world.advance(4)
	check(world.player_view().army.location == "", "four hours cannot teleport five-hour grain road")
	world.advance(1)
	check(world.player_view().army.location == "anping", "normal march arrives after settlement")
	check(world.audit().is_empty(), "post-battle world remains conserved")

	_test_retreat_and_death()
	_test_clock_and_locked_attrition()
	_test_unarmed_and_partial()
	_test_determinism_and_stale_ids()
	_test_fractional_routes_reports_and_world_death()
	_test_atomic_rollback()
	print("Battle transaction tests: %d assertions, %d failures" % [assertions, failures.size()])
	print("TRANSACTION_TEST_SUMMARY " + JSON.stringify({"assertions": assertions, "failures": failures.size(), "messages": failures}))
	quit(0 if failures.is_empty() else 1)

func _test_retreat_and_death() -> void:
	var world := local_world()
	var adapter := begin(world)
	var sim := adapter.simulation
	sim._hurt(sim.units[1], 1000, false)
	sim._hurt(sim.units[20], 1000, false)
	sim._hurt(sim.player(), 30, false)
	sim.issue_order("retreat")
	sim.ended = true
	assert_rejected(world, sim.outcome(), "retreat before extraction")
	sim.ended = false
	sim.set_player_input(Vector2.LEFT, Vector2.LEFT)
	for frame in range(1800):
		sim.step(BattleSimulation.FIXED_DELTA)
		adapter.sync_world()
		if sim.ended:
			break
	check(sim.ended and sim.result == "The company withdrew", "retreat completes through physical extraction, no instant quit outcome")
	var outcome := sim.outcome()
	var receipt := adapter.settle()
	check(receipt.ok and receipt.result == "retreat" and not receipt.depot_captured, "retreat does not claim depot")
	var state := world.snapshot()
	check(state.cities.hequ.owner == "bei" and state.cities.hequ.soldiers == 14, "retreat preserves remaining enemy troops")
	check(state.armies.relief.soldiers == 59 and state.armies.relief.weapons == 29, "retreat costs actual dead soldier and unrecovered equipment")
	check(state.cities.hequ.weapons == 14 and outcome.spoils.weapons == 0, "retreat cannot loot enemy weapons")
	check(state.armies.relief.location == "hequ" and state.armies.relief.march.is_empty(), "battlefield retreat is not strategic teleport")
	check(state.ledger.weapons_destroyed == 2 and world.audit().is_empty(), "unrecoverable weapons ledgered once")
	check(not state.campaign_ended and state.battle_locks.is_empty(), "living commander retains campaign after retreat")
	var next := begin(world)
	check(next.simulation.player().hp == state.commander.hp and state.commander.hp == 330.0, "commander injury persists into next actual battle")
	check(next.simulation.units.size() == 34, "next actual roster does not resurrect lost enemy")
	next.simulation._hurt(next.simulation.player(), 1000, false)
	next.simulation.step(BattleSimulation.FIXED_DELTA)
	check(not world.player_view().campaign_ended, "protagonist death does not end campaign before settlement")
	check(next.settle().ok, "death settlement succeeds")
	state = world.snapshot()
	check(state.campaign_ended and not state.commander.alive and state.commander.hp == 0.0, "death ends this protagonist's campaign")
	check(state.armies.relief.soldiers == 58 and state.battle_locks.is_empty(), "commander is a real lost person; locks released before ending")
	check(state.events[-1].kind == "campaign_ended" and state.events[-2].kind == "battle_committed", "world impact is committed before terminal campaign event")
	before_death_actions(world)
	check(world.audit().is_empty(), "death audit passes")

func before_death_actions(world: WorldSimulation) -> void:
	var before := world.snapshot()
	check(not world.march("river") and not world.observe_city("hequ"), "dead protagonist cannot move or scout")
	check(not world.create_battle_ticket().ok and not world.seize_depot(), "dead protagonist cannot lead new combat")
	check(not world.transfer("relief", "hequ", "food", 1), "dead protagonist cannot manage inventory")
	check(world.snapshot() == before, "commands after death cannot mutate campaign")

func _test_clock_and_locked_attrition() -> void:
	var world := local_world()
	world.advance_seconds(3599.75)
	var adapter := begin(world)
	var sim := adapter.simulation
	sim.step(0.25)
	adapter.sync_world()
	check(world.snapshot().hour == 4 and world.snapshot().time_seconds == 14400.0, "quarter-second battle crosses exact hourly boundary once")
	check(world.snapshot().armies.relief.food == 96, "hourly upkeep feeds all sixty, including twenty locked participants")
	check(world.snapshot().cities.anping.fort < 53, "offscreen siege progresses while in local combat")
	var before := world.snapshot()
	check(adapter.sync_world() and world.snapshot() == before, "boundary cannot be processed twice")
	# Time stress fixture: hold both sides still with no damage while battle hours elapse.
	for unit in sim.units:
		unit.speed = 0.0
		unit.damage = 0.0
	for hour in range(26):
		sim.step(3600.0)
		check(adapter.sync_world(), "running battle synchronizes long elapsed time")
		check(world.audit().is_empty(), "locked force remains conserved at long battle hour %d" % hour)
	var state := world.snapshot()
	check(state.hour == 30 and state.time_seconds == 108000.0, "battle time advances strategic clock without rounding or extra seconds")
	check(state.siege.outcome == "captured", "offscreen Anping falls even while depot battle continues")
	check(state.armies.relief.soldiers < 60 and state.armies.relief.soldiers >= 20, "starvation affects only unreserved remainder")
	check(sim.alive_count(0, true) == 20 and sim.alive_count(1) == 15, "offscreen attrition cannot double-kill locked combatants")
	check(state.armies.relief.weapons >= 10, "offscreen losses cannot destroy reserved equipment")
	finish_victory(sim)
	check(adapter.settle().ok and world.audit().is_empty(), "battle can settle after world independently evolves")

func _test_unarmed_and_partial() -> void:
	var world := World.new(184)
	world.transfer("relief", "pingling", "weapons", 30)
	world.march("river")
	world.advance(3)
	var adapter := begin(world)
	var sim := adapter.simulation
	for unit in sim.units:
		if unit.team == 0:
			check(unit.weapon == "", "empty force arsenal cannot produce a default weapon")
	check(not sim.use_action("sweep") and not sim.use_action("lunge"), "unarmed commander cannot use spear skills")
	check(sim.cooldowns.sweep == 0.0 and sim.cooldowns.lunge == 0.0, "rejected weapon skills do not spend cooldowns")
	check(sim.use_action("attack") and sim.use_action("guard"), "unarmed commander retains punch and guard")
	# Aggregate fixture relocates existing troops, not recruitment or spawning.
	world = local_world()
	world._state.armies.besiegers.soldiers -= 10
	world._state.cities.hequ.soldiers += 10
	check(world.audit().is_empty(), "larger depot fixture preserves global manpower")
	adapter = begin(world)
	sim = adapter.simulation
	check(sim.alive_count(1) == 20, "large garrison only allocates twenty nearby participants")
	check(adapter.ticket.reserved_roster_snapshot[1].filter(func(s: Dictionary) -> bool: return s.weapon != "").size() == 12, "enemy partial allocation uses same proportional scarcity rule")
	finish_victory(sim)
	var receipt := adapter.settle()
	check(receipt.ok and not receipt.depot_captured, "local victory cannot invent defeat of unseen reserves")
	check(world.snapshot().cities.hequ.soldiers == 5 and world.snapshot().cities.hequ.owner == "bei", "five actual defender reserves keep depot hostile")
	check(world.snapshot().cities.hequ.weapons == 3 and world.snapshot().armies.relief.weapons == 42, "only twelve participating enemy weapons become spoils")
	check(world.audit().is_empty(), "partial encounter conserves both forces")
	check(world.create_battle_ticket().ok, "remaining actual defenders require a new encounter")

func _test_determinism_and_stale_ids() -> void:
	var a := run_actual_battle()
	var b := run_actual_battle()
	check(a == b, "same world seed, battle seed and actions yield identical transaction and world")
	check(a.campaign_ended, "real soldier AI reaches a terminal battle and settlement without fabricated outcome")
	var world := local_world()
	var adapter := begin(world)
	finish_victory(adapter.simulation)
	var old_outcome := adapter.simulation.outcome()
	world.reset(184)
	world.march("river")
	world.advance(3)
	var fresh := begin(world)
	check(fresh.ticket.battle_id != old_outcome.battle_id, "new campaign cannot reuse stale transaction identity")
	assert_rejected(world, old_outcome, "old campaign outcome")

func run_actual_battle() -> Dictionary:
	var world := local_world()
	var adapter := begin(world)
	var sim := adapter.simulation
	sim.issue_order("attack")
	for frame in range(10800):
		sim.step(BattleSimulation.FIXED_DELTA)
		adapter.sync_world()
		if sim.ended:
			break
	check(sim.ended, "world-sourced forces reach an ending within 180 seconds")
	check(adapter.settle().ok, "real combat's exact outcome commits")
	check(world.audit().is_empty(), "real combat post-settlement audit passes")
	return world.snapshot()


func _test_fractional_routes_reports_and_world_death() -> void:
	var world := World.new()
	world.advance_seconds(3599.0)
	check(world.observe_city("pingling", 1), "subhour local observation queues delayed report")
	world.advance_seconds(1.0)
	check(not world.player_view().known.has("pingling"), "one-second boundary does not shorten one-hour report delay")
	world.advance_seconds(3598.0)
	check(not world.player_view().known.has("pingling"), "report still absent one second before actual due time")
	world.advance_seconds(1.0)
	var report: Dictionary = world.player_view().known.pingling
	check(report.observed_at_seconds == 3599.0 and report.reported_at_seconds == 7199.0, "delayed report preserves exact observation and receipt seconds")
	world = World.new()
	world.advance_seconds(3599.0)
	world.march("river")
	world.advance_seconds(7201.0)
	check(world.player_view().army.location == "", "three-hour march after fractional wait cannot arrive in7201seconds")
	world.advance_seconds(3598.0)
	check(world.player_view().army.location == "", "march remains en route one second before exact duration")
	world.advance_seconds(1.0)
	check(world.player_view().army.location == "hequ" and world.snapshot().time_seconds == 14399.0, "march arrives after exactly10800seconds")
	check(world.snapshot().events[-1].kind == "arrival" and world.snapshot().events[-1].time_seconds == 14399.0, "arrival event stamped at real subhour deadline")
	check(world.audit().is_empty(), "fractional route remains conserved")
	world = World.new()
	world.advance_seconds(10)
	world.observe_city("pingling", 1)
	world.advance_seconds(10)
	world.observe_city("pingling")
	world.advance_seconds(3590)
	check(world.player_view().known.pingling.observed_at_seconds == 20.0, "later receipt cannot replace fresher observation from same hour")
	world = World.new()
	world.advance(100)
	var state := world.snapshot()
	check(state.armies.relief.soldiers == 0 and not state.commander.alive and state.campaign_ended, "last-person aggregate starvation cannot leave immortal commander")
	check(state.events.filter(func(e: Dictionary) -> bool: return e.kind == "campaign_ended" and e.details.cause == "starvation").size() == 1, "world mortality records explainable cause once")
	check(world.audit().is_empty(), "commander population invariant is audited")
	before_death_actions(world)
	check(world.advance(1) and world.snapshot().hour == 101, "autonomous world clock can continue after protagonist ends; player commands remain blocked")
	world = World.new()
	world.transfer("relief", "pingling", "weapons", 29)
	world.march("river")
	world.advance(3)
	var adapter := begin(world)
	check(adapter.simulation.player().weapon == "", "one weapon among sixty does not magically equip representative deployment")
	check(world.snapshot().armies.relief.weapons == 1, "unallocated scarce weapon remains in world reserve")

func _test_atomic_rollback() -> void:
	var world := FailingSettlementWorld.new()
	world.march("river")
	world.advance(3)
	var adapter := begin(world)
	adapter.simulation.step(0.5)
	finish_victory(adapter.simulation)
	var before := world.snapshot()
	var rejected := adapter.settle()
	check(not rejected.ok and rejected.reason == "settlement_audit_failed", "post-apply audit failure rejects complete settlement")
	check(world.snapshot() == before, "failed post-apply audit rolls back resources, ownership, reports, clock and events")
	check(world.battle_ticket(adapter.ticket.battle_id).status == "running" and not world.snapshot().battle_locks.is_empty(), "rollback retains live reservation for safe retry")
	world.inject_failure = false
	check(adapter.settle().ok and world.audit().is_empty(), "validated same operation can retry safely after rollback")
	check(adapter.settle().already_committed, "retry still preserves once-only settlement")
