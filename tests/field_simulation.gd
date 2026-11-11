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
	_test_world_settlement()
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
			var high := (u.wall_post and Ground.parapet(u.pos)>2.75) or (reach>10 and v.wall_post and Ground.parapet(v.pos)>2.75)
			if d < dsq and Ground.clear_shot(u.pos,v.pos,false,high):
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

func _test_world_settlement() -> void:
	const FieldWorld := preload("res://scripts/field/campaign.gd")
	var b:=Battle.new()
	b.setup(20)
	var w:=FieldWorld.new()
	check(w.bind(b) and w.reserve(),"World reserves the actual field roster and issued weapons")
	b.start()
	while b.result=="" and b.tick<1200: b.step()
	check(b.result!="" and w.sync(),"Encounter produces a natural result")
	var first:=w.settle()
	check(not first.is_empty() and w.audit().is_empty(),"World settlement conserves soldiers, gear, civilians and food")
	var snapshot:=w.snapshot()
	check(snapshot.hour>=1 and snapshot.convoys.size()>0 and snapshot.ledger.food_consumed>0,"Offscreen supply departed and both sides ate on the same clock")
	check(first==w.settle() and snapshot==w.snapshot(),"Repeated settlement has no second effect")
	var resumed:=FieldWorld.new()
	check(resumed.bind(b) and resumed.snapshot()==snapshot and resumed.receipt==first,"Terminal save rebuilds identical clock, inventory, receipt and delayed reports")
	var siege:=Battle.new()
	siege.setup(100)
	var siege_world:=FieldWorld.new()
	check(siege_world.bind(siege) and siege_world.reserve(),"Second opening has its own military supply")
	# Isolated siege fixture: leave real crews at the door and real defenders
	# outside the court. Only ordinary siege ticks can damage the gate or capture.
	siege.start()
	siege.ram=Vector2(Ground.WALL_X-2.7,0)
	var occupants:=0
	for u in siege.roster:
		if u.engineer: u.pos=siege.ram+Vector2(0,0.30*(u.id%4))
		elif u.team==0 and occupants<6:
			u.pos=Ground.COURT+Vector2(0.4*occupants,0)
			occupants+=1
		elif u.team==1: u.pos=Vector2(27,34)+Vector2(u.id%8,floorf((u.id%32)/8.0))
	siege._rebuild_grid()
	for i in 1200:
		siege.tick+=1
		siege._siege()
		if siege.capture>=6: break
	check(siege.gate_hp==0 and siege.capture>=6 and siege.losses==[0,0],"Physical crew opened gate and held the court with defenders still alive")
	siege.step()
	check(siege.result=="夺取城内阵地" and siege_world.sync() and not siege_world.settle().is_empty(),"Court control produces a non-annihilation settlement")
	var world:=siege_world.snapshot()
	check(world.cities.hequ.owner=="sheng" and world.armies.hequ_remnant.soldiers==siege.side_size+siege.companies_per_side and siege_world.audit().is_empty(),"Living garrison leaves on an actual road with its equipment")
