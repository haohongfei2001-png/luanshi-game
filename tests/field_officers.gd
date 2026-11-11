extends SceneTree
## Run with godot --headless --path . --script res://tests/field_officers.gd.
## Fixtures arrange existing actors; all movement, contact, signals and extraction use field steps.
const Battle := preload("res://scripts/field/battle.gd")
const Corps := preload("res://scripts/field/officer_corps.gd")
const Arms := preload("res://scripts/field/arms.gd")
const Save := preload("res://scripts/field/save.gd")

var failures: Array[String] = []

func check(ok: bool, label: String) -> void:
	if not ok:
		failures.append(label)
		push_error(label)

func _initialize() -> void:
	_manifest()
	_two_fronts()
	_duel()
	_succession()
	_rescue()
	_capture_and_death()
	_old_field()
	print("FIELD_OFFICERS_", "PASS" if failures.is_empty() else "FAIL", " ", JSON.stringify(failures))
	quit(0 if failures.is_empty() else 1)

func _manifest() -> void:
	var b := Battle.new()
	b.setup(512)
	var ordinary := [0, 0]
	var officers := [0, 0]
	var ranks := [{}, {}]
	var assigned := {}
	for u in b.roster:
		if u.hero:
			continue
		if u.officer:
			officers[u.team] += 1
			var command = b.corps.companies[u.squad]
			ranks[u.team][command.rank] = u.id
			check(b.corps.recipient(b, b.companies[u.squad]) == u, "Real founding command holder")
			for id in command.guards + command.deputies:
				var soldier := b.roster[id]
				check(not assigned.has(id) and soldier.squad == u.squad and not soldier.officer and not soldier.hero and not soldier.engineer, "Ordinary billets have unique in-company identities")
				assigned[id] = true
		else:
			ordinary[u.team] += 1
	check(ordinary == [512, 512] and officers == [16, 16] and b.roster.size() == 1057, "Separate soldiers, officers and player")
	for team in 2:
		check(ranks[team].size() == 5, "Both forces field five officer ranks")
		for rank in [Corps.Rank.COMMANDER, Corps.Rank.VANGUARD, Corps.Rank.CHALLENGER, Corps.Rank.ELITE]:
			var unit := b.roster[int(ranks[team][rank])]
			check(unit.kit == Corps.KITS[rank] and b.corps.title_of(b, unit) == Corps.TITLES[rank], "Officer kit and title match the deployed role")
	print("FIELD_OFFICER_MANIFEST ", JSON.stringify({"ordinary": ordinary, "officers": officers, "existing_billets": assigned.size()}))

func _place(u, point: Vector2) -> void:
	u.pos = point
	u.before = point

func _field(weapon: int = Arms.Kit.SPEAR) -> Battle:
	var b := Battle.new()
	b.setup(20, Battle.SEED, weapon)
	# Leave other actors in their own garrison, preserving their troops and equipment.
	for i in b.companies.size():
		var c := b.companies[i]
		c.mission = Battle.Mission.HOLD
		c.aim = c.home
	for u in b.roster:
		var base := Vector2(-80, 49) if u.team == 0 else Vector2(105, 49)
		_place(u, base + Vector2(u.id % 5, u.id % 3))
	b._rebuild_grid()
	return b

func _two_fronts() -> void:
	var b := _field()
	var targets := []
	for team in 2:
		var officer := b.roster[b.companies[team].officer_id]
		var other_archer := b.roster[(1 - team) * b.side_size + 16]
		var p := Vector2(-9, -20) if team == 0 else Vector2(15, 20)
		var forward := Vector2.RIGHT if team == 0 else Vector2.LEFT
		_place(officer, p)
		_place(other_archer, p + forward * 2.3)
		targets.append(other_archer)
	b.start()
	for i in 230:
		b.step()
	var report: Dictionary = b.corps.summary(b)
	for team in 2:
		check(report.skills[team] > 0 and report.kills[team] > 0 and targets[team].hp == 0.0, "Independent officer weapon skills produce attributed casualties on front %d" % team)
	check(b.hero.impacts == 0 and b.hero.received == 0 and b.result == "", "Both fronts resolve without hero contact or a forced victory")
	print("FIELD_OFFICER_CONTACT ", JSON.stringify({"ticks": b.tick, "skills": report.skills, "kills": report.kills, "dead": b.losses}))

func _exchange(response: int) -> float:
	var b := _field(Arms.Kit.SHIELD)
	var officer := b.roster[b.companies[1].officer_id]
	_place(b.hero, Vector2.ZERO)
	_place(officer, Vector2(2.4, 0))
	b.start()
	var walk := Vector2.LEFT if response == 2 else Vector2.ZERO
	b.input_state(walk, Vector2.RIGHT)
	if response == 1:
		check(b.press_action(3), "Player readies the shield through the ordinary skill input")
	b._begin(officer, 0, Vector2.LEFT)
	var origin := officer.pos
	var hp := b.hero.hp
	for i in 10:
		b.step()
	check(b.tick == 10 and origin.distance_to(officer.pos) < 0.1, "The committed cut holds its origin and direction")
	return hp - b.hero.hp

func _duel() -> void:
	var exposed := _exchange(0)
	var guarded := _exchange(1)
	var withdrew := _exchange(2)
	check(exposed > guarded and guarded > 0.0 and withdrew == 0.0, "The same visible officer strike can hit, be blocked, or miss a retreating player")
	print("FIELD_OFFICER_DUEL ", JSON.stringify({"exposed": exposed, "blocked": guarded, "out_of_reach": withdrew}))

func _wound(b: Battle, u, source) -> void:
	b._rebuild_grid()
	b._hurt(source, u, 100.0, source.pos)
	check(u.hp > 0.0 and b.corps.is_wounded(u.id) and not b.corps.can_command(b, b.companies[u.squad]), "Physical injury interrupts command while the officer is alive")

func _succession() -> void:
	var b := _field()
	var ids := []
	for team in 2:
		var c := b.companies[team]
		var r = b.corps.companies[team]
		var officer := b.roster[c.officer_id]
		var post := Vector2(-8, 0) if team == 0 else Vector2(10, 20)
		_place(officer, post)
		for j in r.deputies.size():
			_place(b.roster[r.deputies[j]], post + Vector2(j + 1, -1))
		ids.append(c.officer_id)
	_place(b.hero, Vector2(-10, 0))
	b._rebuild_grid()
	b.start()
	for team in 2:
		var officer := b.roster[ids[team]]
		var hostile := b.roster[(1 - team) * b.side_size + 5]
		b._hurt(hostile, officer, 300.0, officer.pos + Vector2.RIGHT)
		check(not b.corps.can_command(b, b.companies[team]), "There is a command vacancy on actual death")
	check(not b.command(0, Battle.Mission.RESERVE, Battle.Channel.VOICE), "Witnesses cannot address a fresh vacancy")
	var copy := Save.restore(Save.snapshot(b))
	check(copy != null, "Pending succession round-trips")
	for i in Corps.COMMAND_DELAY + 6:
		b.step()
		if copy != null:
			copy.step()
	if copy != null:
		check(Save.snapshot(copy) == Save.snapshot(b), "Both renewed commands are deterministic across resume")
	for team in 2:
		var deputy = b.corps.recipient(b, b.companies[team])
		check(b.corps.can_command(b, b.companies[team]) and not deputy.officer and deputy.team == team and b.corps.title_of(b, deputy) == "代领队正", "An existing ordinary delegate takes each surviving command")
		check(b.companies[team].officer_id == ids[team] and b.roster[ids[team]].hp == 0.0, "Founding officer identity and death are permanent")
	check(b.losses == [0, 0] and b.result == "", "Two dead commanders leave the ordinary troops and military outcome intact")
	check(b.command(0, Battle.Mission.RESERVE, Battle.Channel.VOICE), "A nearby deputy can hear a new order")
	for i in 20:
		b.step()
	check(b.companies[0].mission == Battle.Mission.RESERVE and b.messages_arrived == 1, "A new order reaches the delegate after its real delay")
	var bad := Save.snapshot(b)
	bad.officer_corps.companies[0][Corps.SERIAL.find(&"leader")] = b.companies[1].officer_id
	check(Save.restore(bad) == null, "Reject foreign command identity")
	print("FIELD_OFFICER_SUCCESSION ", JSON.stringify(b.corps.summary(b)))

func _rescue() -> void:
	var b := _field()
	var r = b.corps.companies[0]
	var u := b.roster[r.primary]
	var guard := b.roster[r.guards[0]]
	var hostile := b.roster[b.side_size + 12]
	var post := Vector2(-89, 32)
	_place(u, post)
	_place(guard, post + Vector2(0, 1))
	_place(hostile, post + Vector2(1, 0))
	b.start()
	_wound(b, u, hostile)
	_place(hostile, b.companies[1].home)
	var escorted := false
	var continuous := true
	var maximum_step := 0.0
	for i in 160:
		var previous := u.pos
		b.step()
		var moved := previous.distance_to(u.pos)
		maximum_step = maxf(maximum_step, moved)
		continuous = continuous and moved <= 0.19
		escorted = escorted or b.corps.support_partner(b, u) == guard.id
		if u.state == Battle.State.ESCAPED:
			break
	var result: Dictionary = b.corps.summary(b)
	check(continuous and escorted and result.rescued[0] == [u.id] and result.captives[0].is_empty(), "A nearby named guard escorts the injured officer to safety by continuous movement")
	check(u.hp > 0.0 and not b.active(u) and b.escaped[0] == 0 and b.losses[0] == 0, "Extracting a living officer does not invent ordinary survivors or casualties")
	check(Save.restore(Save.snapshot(b)) != null, "Escorted survivor status persists")
	print("FIELD_OFFICER_RESCUE ", JSON.stringify({"guard": guard.id, "rescued": result.rescued, "ticks": b.tick, "largest_step": maximum_step}))

func _capture_and_death() -> void:
	var b := _field()
	var u := b.roster[b.companies[0].officer_id]
	var hostile := b.roster[b.side_size + 17]
	_place(u, Vector2.ZERO)
	_place(hostile, Vector2(-0.55, 0))
	b.start()
	_wound(b, u, hostile)
	# The lone opponent is in a real crossbow reload recovery and cannot attack
	# before the capture interval. Distant guards cannot rescue through proximity.
	b._set_state(hostile, Battle.State.RECOVER, b.moves[hostile.kit][0].recovery)
	for i in 7:
		b.step()
	var resumed := Save.restore(Save.snapshot(b))
	check(resumed != null, "Contested custody duration persists")
	for i in Corps.CAPTURE_STEPS + 2:
		b.step()
		if resumed != null:
			resumed.step()
	if resumed != null:
		check(Save.snapshot(resumed) == Save.snapshot(b), "A restored contested casualty has the same holder and outcome")
	check(b.corps.is_captive(u.id) and u.hp > 0 and not b.active(u) and b.corps.companies[0].captor == hostile.id, "The unopposed opponent takes a living prisoner after actual contact")
	check(b.losses == [0, 0] and b.escaped == [0, 0], "Officer capture reconciles outside ordinary losses")

	var fatal := _field()
	var wounded := fatal.roster[fatal.companies[0].officer_id]
	var opponent := fatal.roster[fatal.side_size]
	_place(opponent, wounded.pos + Vector2.RIGHT)
	fatal.start()
	_wound(fatal, wounded, opponent)
	fatal._hurt(opponent, wounded, 300.0, opponent.pos)
	var hits := opponent.impacts
	fatal._hurt(opponent, wounded, 300.0, opponent.pos)
	fatal.step()
	check(wounded.state == Battle.State.DEAD and opponent.impacts == hits and not fatal.corps.is_captive(wounded.id), "A second fatal strike kills a wounded officer once")
	print("FIELD_OFFICER_CUSTODY ", JSON.stringify({"prisoner": u.id, "holder": b.corps.companies[0].captor, "fatal": fatal.corps.summary(fatal).fallen}))

func _old_field() -> void:
	var historical := Battle.new()
	historical.setup(20, Battle.SEED, Arms.Kit.SPEAR, true, false)
	historical.start()
	for i in 6:
		historical.step()
	var old := Save.snapshot(historical)
	old.version = 3
	old.erase("officer_corps")
	var restored := Save.restore(old)
	check(restored != null, "Read a field snapshot predating ranked officers")
	if restored == null:
		return
	var officer := restored.roster[restored.companies[0].officer_id]
	check(not restored.corps.enabled and officer.kit == Arms.Kit.GLAIVE and officer.max_hp == 88, "Historical field retains its original armament and health")
	for i in 10:
		historical.step()
		restored.step()
	check(Save.snapshot(historical) == Save.snapshot(restored), "Historical resumptions retain their exact simulation path")
