extends SceneTree
const Battle := preload("res://scripts/field/battle.gd")
const Arms := preload("res://scripts/field/arms.gd")
const Ground := preload("res://scripts/field/ground.gd")
var failures: Array[String] = []

func check(value: bool, message: String) -> void:
	if not value:
		failures.append(message)
		push_error(message)

func _initialize() -> void:
	for n: int in Battle.SCALES:
		var b := Battle.new()
		b.setup(n)
		check(b.roster.size() == 2*n+b.companies.size()+1, "Separate ordinary soldiers, officers and player")
		check(b.command(0,Battle.Mission.PRESS,Battle.Channel.FLAG), "Muster order")
		b.start()
		check(b.command(0,Battle.Mission.PRESS,Battle.Channel.HORN),"Issue horn")
		var samples: Array[int] = []
		for t in 360:
			if b.result != "":
				break
			var begin := Time.get_ticks_usec()
			b.step()
			samples.append(Time.get_ticks_usec()-begin)
		var touched := [0,0]
		var lanes := {}
		var fallen := [0,0]
		for u in b.roster:
			if u.hero or u.officer:
				continue
			check(b.roster[u.id] == u, "Stable roster ID")
			if u.hp < u.max_hp:
				touched[u.team] += 1
				lanes[floori(u.station.y/10.0)] = true
			if u.hp <= 0:
				fallen[u.team] += 1
		check(touched[0] > 0 and touched[1] > 0 and fallen[0]+fallen[1] > 0,"Both forces took actual damage at %d" % n)
		check(b.hits[0] > 0 and b.hits[1] > 0 and b.arrow_count > 0, "Melee and missiles active")
		check(fallen == b.losses and b.losses == b.equipment,"Bodies and dropped weapons reconcile")
		check(b.messages_arrived == 1, "Delayed order reached officer")
		check(n < 250 or lanes.size() >= 4, "Real contacts on several fronts without a camera")
		var r := b.report()
		samples.sort()
		r["sim_p95_ms"] = samples[ceili(samples.size()*0.95)-1]/1000.0
		r["damaged_soldiers"] = touched
		r["engaged_lanes"] = lanes.size()
		print("FIELD_SCALE " + JSON.stringify(r))
	_test_orders_and_ground()
	_test_grid()
	_test_resume()
	_test_player_kits()
	print("FIELD_SIM_" + ("PASS" if failures.is_empty() else "FAIL") + " " + JSON.stringify(failures))
	quit(0 if failures.is_empty() else 1)

func _test_orders_and_ground() -> void:
	var b := Battle.new()
	b.setup(20)
	var officer := b.roster[b.companies[0].officer_id]
	b.hero.pos = Vector2(-105,52)
	b.start()
	check(not b.command(0,Battle.Mission.HOLD,Battle.Channel.FLAG), "Distant flag cannot deliver")
	b.hero.pos = Vector2(-1,8)
	officer.pos = Vector2(10,8)
	b.roster[20].pos = b.hero.pos
	b._rebuild_grid()
	check(b.command(0,Battle.Mission.WITHDRAW,Battle.Channel.COURIER),"Dispatch courier")
	b.step()
	check(b.messages_lost == 1 and b.companies[0].mission == Battle.Mission.PRESS, "Intercepted order left mission intact")
	check(Ground.blocked(Ground.GATE,false) and not Ground.blocked(Ground.GATE,true),"Gate opens only after a breach")
	check(not Ground.clear_shot(Vector2(44,10),Vector2(55,10),true),"Wall stops shots beside breached gate")
	check(Ground.blocked(Vector2(Ground.RIVER_X,13),true) and not Ground.blocked(Vector2(Ground.RIVER_X,0),true),"Bridge is a physical crossing")

func _test_grid() -> void:
	var b := Battle.new()
	b.setup(512)
	var expected: Array[int] = []
	var start := Time.get_ticks_usec()
	for u in b.roster:
		var reach := 29.0 if u.kit in [Arms.Kit.BOW,Arms.Kit.CROSSBOW] else 6.8
		var best := -1
		var dsq := reach*reach
		for v in b.roster:
			if v.team == u.team: continue
			var d := u.pos.distance_squared_to(v.pos)
			if d < dsq and Ground.clear_shot(u.pos,v.pos,false):
				best = v.id
				dsq = d
		expected.append(best)
	var exhaustive := Time.get_ticks_usec()-start
	start = Time.get_ticks_usec()
	for u in b.roster:
		b._assessment(u)
		check(u.target == expected[u.id],"Local and exhaustive target disagree at %d" % u.id)
	print("FIELD_TARGET_LOOKUP " + JSON.stringify({"units":b.roster.size(),"all_pairs_us":exhaustive,"grid_with_separation_us":Time.get_ticks_usec()-start}))

func _test_resume() -> void:
	const Save := preload("res://scripts/field/save.gd")
	var b := Battle.new()
	b.setup(100)
	b.start()
	b.command(1,Battle.Mission.FLANK,Battle.Channel.COURIER)
	for i in 32: b.step()
	var saved := Save.snapshot(b)
	var restored := Save.restore(saved)
	check(restored!=null,"Restore an engaged field with flights and officer orders")
	if restored==null: return
	for i in 52:
		b.step()
		restored.step()
	check(Save.snapshot(b)==Save.snapshot(restored),"Resumed contacts, losses, mounts, pending orders and RNG agree")
	saved.losses[0]+=1
	check(Save.restore(saved)==null,"Reject mismatched casualty ledger")

func _test_player_kits() -> void:
	for kit in Arms.NAMES.size():
		var b := Battle.new()
		b.setup(20,Battle.SEED,kit)
		b.start()
		var hero:=b.hero
		hero.pos=Vector2(18,50)
		var target:=b.roster[20]
		target.pos=hero.pos+Vector2(1.25,0)
		b._rebuild_grid()
		b.input_state(Vector2.ZERO,Vector2.RIGHT)
		var hp:=target.hp
		check(b.action(0) and not b.action(0),"Windup locks repeated basic input")
		check(target.hp==hp and hero.state==Battle.State.WINDUP,"Contact waits for each weapon windup")
		for i in 30:
			b._state_step(hero)
			b._projectiles()
		check(target.hp<hp,"Actual weapon contact "+Arms.NAMES[kit])
		var projectile_kit:=kit in [Arms.Kit.BOW,Arms.Kit.CROSSBOW]
		check((b.arrow_count>0)==projectile_kit,"Ranged kit produces a traveling projectile")
	var mounted:=Battle.new()
	mounted.setup(20)
	check(mounted.mount(1) and mounted.vehicle==1,"Mount real horse near muster")
	check(mounted.mount(1) and mounted.vehicle==0 and mounted.mount(2) and mounted.vehicle==2,"Dismount and board the separate cart")
