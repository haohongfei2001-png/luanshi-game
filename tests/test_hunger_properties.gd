extends SceneTree
const W = preload("res://scripts/world_sim.gd")
const A = preload("res://scripts/battle_adapter.gd")
var checks := 0
var failures: Array[String] = []
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)
		push_error(label)
func setup(count: int = 60) -> WorldSimulation:
	var w := W.new()
	w._state.siege.active = false
	w._state.armies.besiegers.location = "hequ"
	w._state.armies.besiegers.food = 1000000
	w._state.cities.pingling.food = 1000000000000
	w._state.armies.relief.soldiers = count
	w._state.armies.relief.weapons = mini(count,30)
	w._state.armies.relief.food = 0
	w._state.initial_totals = w.totals()
	return w
func ceil_ratio(a: int,b: int) -> int:
	@warning_ignore("integer_division")
	return (a+b-1)/b
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 790004
	# A separate condition oracle, driven by physical transfers only after setup.
	for population in [1,9,10,11,59,60,61,1001,1000000000]:
		var w := setup(population)
		var parts := setup(population)
		var hunger := 0
		var fatigue := 0
		var morale := 100
		var people: int = population
		var dead := 0
		for hour in range(25):
			if people == 0: break
			var needed := ceil_ratio(people,10)
			var eaten := rng.randi_range(0,needed)
			for sim in [w,parts]:
				if eaten > 0:
					check(sim.transfer("pingling","relief","food",eaten),"transfer %s/%s" % [population,hour])
			var missing := needed-eaten
			if missing > 0:
				hunger = mini(6000,hunger + ceil_ratio(missing*1000,needed))
				fatigue = mini(100,fatigue + ceil_ratio(missing*12,needed))
				morale = maxi(0,morale - ceil_ratio(missing*10,needed))
				if hunger >= 3000:
					people -= 1
					dead += 1
			else:
				hunger = maxi(0,hunger-1000)
				fatigue = maxi(0,fatigue-6)
				morale = mini(100,morale+4)
			check(w.advance(1),"oracle hour accepted")
			for chunk in [1,5,57,901,999,1637]:
				check(parts.advance_seconds(chunk),"chunk accepted")
			var c: Dictionary = w._state.armies.relief.condition
			check(c.hunger == hunger and c.fatigue == fatigue and c.morale == morale,"independent ration oracle population=%d hour=%d actual=%s expected=%s" % [population,hour,[c.hunger,c.fatigue,c.morale],[hunger,fatigue,morale]])
			check(w._state.armies.relief.soldiers == people and w._state.ledger.starvation_dead == dead,"independent delayed casualty oracle")
			check(w.snapshot() == parts.snapshot(),"arbitrary subhour segmentation reproducible")
			check(w.audit().is_empty(),"oracle conservation")
	# Mixed battle/alert/rest hours and cancellation without elapsed time.
	var w := W.new()
	w.march("river")
	w.advance_seconds(12600.0)
	w._state.armies.relief.condition.fatigue = 60
	w._state.armies.relief.condition.morale = 50
	var adapter := A.new(w)
	check(adapter.begin_local_depot().ok,"mixed battle begins")
	adapter.simulation.elapsed = 3600.0
	for unit in adapter.simulation.units:
		if unit.team == 1: adapter.simulation._hurt(unit,1000.0,false)
	adapter.simulation._check_result()
	check(adapter.settle().ok,"mixed battle ends")
	check(w._state.armies.relief.condition.fatigue == 63,"battle boundary exertion applied once")
	check(w.advance_seconds(1800.0),"post-battle half rest advances")
	check(w._state.armies.relief.condition.fatigue == 66 and w._state.armies.relief.condition.morale == 50,"half-hour rest cannot erase prior half-hour battle")
	check(w.advance(1),"full rest following mixed hour")
	check(w._state.armies.relief.condition.fatigue == 60 and w._state.armies.relief.condition.morale == 54,"next full hour recovers")
	check(w.audit().is_empty(),"mixed battle conservation")
	# Condition validation should reject every required key omission and wrong compound types.
	for id in ["relief","hequ"]:
		var fields: Array = W.new()._entity(id).condition.keys()
		for field in fields:
			w = W.new()
			w._entity(id).condition.erase(field)
			var before := w.snapshot()
			check(not w.advance_seconds(1) and var_to_bytes(before) == var_to_bytes(w.snapshot()),"missing condition %s/%s rejects atomically" % [id,field])
		for field in ["fatigue","morale","hunger","last_needed","last_eaten","stage","last_activity","activity_flags"]:
			for bad in [[],{},Vector2.ZERO,NAN,INF,-INF]:
				if field == "activity_flags" and bad is Dictionary: continue
				w = W.new()
				w._entity(id).condition[field] = bad
				var before := w.snapshot()
				check(not w.advance_seconds(1) and var_to_bytes(before) == var_to_bytes(w.snapshot()),"invalid condition compound %s/%s/%s rejects atomically" % [id,field,str(bad)])
	# Detached audit evidence and event immutability.
	w = setup()
	w.advance(1)
	var evidence: Dictionary = w.snapshot()
	var condition_events: Array = evidence.events.filter(func(e: Dictionary) -> bool: return e.kind == "military_condition" and e.details.entity == "relief")
	check(condition_events.size() == 1,"one condition record per entity per hour")
	w.advance(3)
	var actual: Array = w.snapshot().events.filter(func(e: Dictionary) -> bool: return e.kind == "military_condition" and e.details.entity == "relief")
	check(actual[0] == condition_events[0],"original warning remains immutable over later starvation")
	condition_events[0].details.after.hunger = -9
	check(w._state.armies.relief.condition.hunger == 4000,"public snapshot mutation does not change authority")
	print("INDEPENDENT_HUNGER_AUDIT %d checks / %d failures" % [checks,failures.size()])
	print(JSON.stringify(failures))
	quit(0 if failures.is_empty() else 1)
