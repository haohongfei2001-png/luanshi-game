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
	_test_move_windows_and_parapet()
	_test_wall_retreat()
	_test_cavalry()
	_test_world_settlement()
	_test_full_siege()
	_test_deployment_and_camp()
	_test_chariot_origin()
	_test_quivers_and_acknowledgments()
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

func _test_wall_retreat() -> void:
	# The first archer on each wall walk used to walk straight into its high edge.
	for breached: bool in [false, true]:
		var b := Battle.new()
		b.setup(250)
		if breached: b.gate_hp = 0
		var sides := {}
		for archer in b.roster:
			if not archer.wall_post or sides.has(signf(archer.pos.y)): continue
			var side := signf(archer.pos.y)
			sides[side] = true
			b._set_state(archer, Battle.State.ROUT, 0)
			archer.separation = Vector2(2.2, side * 1.1)
			var steps := 0
			var descended := false
			var crossed_postern := false
			var continuous := true
			for i in 850:
				steps += 1
				var previous := archer.pos
				b._state_step(archer)
				continuous = continuous and absf(Ground.parapet(previous)-Ground.parapet(archer.pos)) < 0.56
				if Ground.parapet(archer.pos) == 0 and archer.pos.x < Ground.WALL_X + 5:
					descended = true
				if previous.x < Ground.BACK_X and archer.pos.x >= Ground.BACK_X:
					crossed_postern = absf(archer.pos.y) < Ground.POSTERN_HALF
				if archer.state == Battle.State.ESCAPED: break
			print("FIELD_PARAPET_RETREAT ",JSON.stringify({"side":side,"front_breached":breached,"steps":steps,"ramp":descended,"continuous":continuous,"postern":crossed_postern,"escaped":archer.state==Battle.State.ESCAPED}))
			check(descended and continuous and crossed_postern and archer.state == Battle.State.ESCAPED,
				"Defending archer descends its ramp and exits the rear postern, side %d, front breach %s" % [int(side),str(breached)])
		check(sides.size() == 2 and b.escaped[1] == 2 and b.losses[1] == 0,"Both routed soldiers were accounted alive exactly once")
	check(not Ground.blocked(Vector2(Ground.BACK_X,0),false) and Ground.blocked(Vector2(Ground.BACK_X,3),false),"Rear postern is narrow and independent of the front gate")
	check(Ground.clear_shot(Vector2(84,0),Vector2(95,0),false) and not Ground.clear_shot(Vector2(84,3),Vector2(95,3),true),
		"Missiles and walking use the same rear opening")
	for side: float in [-1.0, 1.0]:
		for pair: Array in [[Vector2(4.0,side*9),Vector2(100.0,side*32),false],
				[Vector2(69.0,side*11),Vector2(-98.0,side*32),true],
				[Vector2(69.0,side*11),Vector2(-98.0,side*32),false]]:
			var at: Vector2 = pair[0]
			var goal: Vector2 = pair[1]
			for step in 1600:
				if at.distance_to(goal) < 1.0: break
				var via := Ground.retreat_waypoint(at, goal, pair[2])
				at = Ground.travel(at,at.direction_to(via)*minf(0.2,at.distance_to(via)),pair[2])
			check(at.distance_to(goal)<1.0,"Courtyard and sortie retreat follow open passages to the army exit")

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
	check(w.audit_quivers() and first.has("ammunition") and snapshot.field_ammo_spent[0]+snapshot.field_ammo_spent[1]==b.arrow_count,"World counts every expended arrow and bolt")
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
	check(world.cities.hequ.owner=="sheng" and world.armies.hequ_remnant.soldiers==siege.side_size+siege.companies_per_side and siege_world.audit().is_empty() and siege_world.audit_quivers() and world.armies.hequ_remnant.field_ammo[0]>0,"Living garrison leaves on an actual road with its equipment")

func _test_quivers_and_acknowledgments() -> void:
	const Save := preload("res://scripts/field/save.gd")
	var b:=Battle.new()
	b.setup(20,Battle.SEED,Arms.Kit.BOW,true,false)
	b.start()
	var archer:=b.hero
	b.input_state(Vector2.ZERO,Vector2.RIGHT)
	var initial:=archer.ammo
	for volley in ceili(initial/3.0):
		var before:=archer.ammo
		b._begin(archer,1,Vector2.RIGHT)
		check(archer.ammo==before,"A cancelled draw costs no missile")
		b._release(archer,b._committed_move(archer))
	check(archer.ammo==0 and b.arrow_count==initial and b.shots.size()==initial,"Only issued arrows fly, including a short last volley")
	archer.state=Battle.State.MARCH
	check(not b.action(1) and b.action(0) and archer.stock_strike,"Empty ranged kit uses a real short strike")
	b._release(archer,b._committed_move(archer))
	check(b.arrow_count==initial,"Stock blow creates no projectile")
	var data:=Save.snapshot(b)
	check(Save.restore(data)!=null,"Empty quiver and stock animation round trip")
	var bad:=data.duplicate(true)
	bad.units[archer.id][Save.UNIT.find(&"ammo")]=1
	check(Save.restore(bad)==null,"Reject unaccounted ammunition")
	var old:=data.duplicate(true)
	old.version=1
	old.erase("legacy_missiles")
	old.battle.pop_back()
	for row in old.units: row.resize(Save.UNIT.find(&"ammo"))
	var preserved:=Save.restore(old)
	check(preserved!=null and preserved.legacy_missiles and preserved.arrow_count==initial,"Unmetered historical field retains its original rules")
	if preserved: check(Save.restore(Save.snapshot(preserved)).legacy_missiles,"Saving again preserves historical behavior")

	var signal_battle:=Battle.new()
	signal_battle.setup(100)
	signal_battle.start()
	var officer:=signal_battle.roster[signal_battle.companies[0].officer_id]
	signal_battle.hero.pos=Vector2(-75,0)
	officer.pos=Vector2(-57,0)
	check(not signal_battle.command(0,Battle.Mission.HOLD,Battle.Channel.VOICE),"Spoken order stays in earshot")
	officer.pos=Vector2(-69,0)
	check(signal_battle.command(0,Battle.Mission.HOLD,Battle.Channel.VOICE),"Nearby officer hears a spoken order")
	for i in 15: signal_battle._dispatches()
	check(signal_battle.companies[0].mission==Battle.Mission.HOLD,"Voice delivery applies the actual mission")
	officer.pos=Vector2(-49,0)
	signal_battle._rebuild_grid()
	check(signal_battle.command(0,Battle.Mission.FLANK,Battle.Channel.COURIER),"Send a distant rider")
	var saw_return:=false
	for i in 240:
		signal_battle._dispatches()
		if not signal_battle.orders.is_empty() and signal_battle.orders[0].leg==1 and not saw_return:
			saw_return=true
			check(signal_battle.notice.contains("已发"),"Distant command does not reveal instant acknowledgment")
	check(saw_return and signal_battle.orders.is_empty() and signal_battle.notice.contains("回报"),"Physical return reaches the player")
	var company:=signal_battle.companies[0]
	company.standing=3
	officer.pos=signal_battle.hero.pos+Vector2(4,0)
	signal_battle.command(0,Battle.Mission.PRESS,Battle.Channel.VOICE)
	for i in 15: signal_battle._dispatches()
	check(signal_battle.messages_refused==1 and company.mission==Battle.Mission.FLANK,"Depleted company can decline an attack and report it")
	company.standing=company.initial
	officer.pos=Vector2(-49,0)
	signal_battle.roster[100].pos=Vector2(-57,0)
	signal_battle._rebuild_grid()
	signal_battle.command(0,Battle.Mission.WITHDRAW,Battle.Channel.COURIER)
	for i in 65: signal_battle._dispatches()
	check(signal_battle.messages_lost==1 and signal_battle.notice.contains("已发"),"Unseen interception is not reported at once")
	for i in 280: signal_battle._dispatches()
	check(signal_battle.notice.contains("超时") and company.mission==Battle.Mission.FLANK,"Late notice exposes the missing reply without hidden enemy positions")

func _test_full_siege() -> void:
	const FieldWorld:=preload("res://scripts/field/campaign.gd")
	var b:=Battle.new()
	b.setup(512)
	var w:=FieldWorld.new()
	check(w.bind(b),"Bind full siege to historical world")
	for i in b.companies_per_side:
		var mission:=Battle.Mission.PRESS
		if i in [2,7]: mission=Battle.Mission.ESCORT
		elif i in [0,4]: mission=Battle.Mission.FLANK
		check(b.command(i,mission,Battle.Channel.FLAG),"Issue muster task to standing officer")
	check(w.reserve(),"Reserve the full deployment")
	b.start()
	var gate_contact := -1
	var breach := -1
	var farthest_ram := b.ram.x
	for i in 3600:
		b.step()
		if b.gate_hp<260 and gate_contact<0: gate_contact=b.tick
		if b.gate_hp<=0 and breach<0: breach=b.tick
		farthest_ram=maxf(farthest_ram,b.ram.x)
		if b.result!="": break
	check(w.sync() and w.audit_quivers(),"Three-minute siege retains issued combat supplies")
	if b.result!="": check(not w.settle().is_empty(),"Natural force outcome settles once")
	var row:=b.report()
	row.merge({"first_gate_damage_tick":gate_contact,"gate_breach_tick":breach,"farthest_ram_x":farthest_ram,
		"ordinary_surviving":[b.side_size-b.losses[0],b.side_size-b.losses[1]],"world_receipt":not w.receipt.is_empty()})
	print("FIELD_NATURAL_SIEGE "+JSON.stringify(row))

func _test_move_windows_and_parapet() -> void:
	var moves_checked:=0
	for kit in Arms.NAMES.size():
		for slot in 4:
			var b:=Battle.new()
			b.setup(20,Battle.SEED,kit)
			b.start()
			b.hero.pos=Vector2(20,45)
			var start:=b.hero.pos
			var move: Arms.Move=b.moves[kit][slot]
			var target:=b.roster[20]
			target.pos=start+Vector2(maxf(1.05,move.step+1.05),0)
			b._rebuild_grid()
			b.input_state(Vector2.ZERO,target.pos-start)
			check(b.action(slot) and target.hp==target.max_hp,"Windup precedes contact for %d-%d"%[kit,slot])
			var held:=false
			for i in 58:
				b._state_step(b.hero)
				held=held or b.hero.state==Battle.State.GUARD
				b._projectiles()
			if move.shape in [Arms.Shape.PARRY,Arms.Shape.BRACE]:
				check(held and target.hp==target.max_hp,"Actual defensive interval")
			elif move.shape==Arms.Shape.EVADE:
				check(b.hero.pos.x<start.x-0.9 and target.hp==target.max_hp,"Evasion changes the real position")
			else:
				check(target.hp<target.max_hp and b.hero.impacts>0,"Damaging window connects for %d-%d"%[kit,slot])
			if slot>0: check(b.hero_cds[slot]>0 and not b.action(slot),"Skill cooldown is independent from animation recovery")
			moves_checked+=1
	print("FIELD_MOVE_WINDOWS "+str(moves_checked))

	var b:=Battle.new()
	b.setup(20,Battle.SEED,Arms.Kit.CROSSBOW)
	b.start()
	b.hero.pos=Vector2(Ground.WALL_X-5,15)
	var low:=b.roster[20]
	var high:=b.roster[21]
	low.pos=Vector2(Ground.WALL_X+6.0,15)
	high.pos=Vector2(Ground.WALL_X+3.1,15)
	b._rebuild_grid()
	b.input_state(Vector2.ZERO,high.pos-b.hero.pos)
	check(b.action(1),"Manually aim at a real parapet position")
	for i in 35:
		b._state_step(b.hero)
		b._projectiles()
	check(high.hp<high.max_hp and low.hp==low.max_hp,"Elevated shot connects with wall defender without hitting a screened ground unit")

func _test_cavalry() -> void:
	for braced in [false,true]:
		var b:=Battle.new()
		b.setup(100)
		b.start()
		var horseman: Battle.Unit
		var defender: Battle.Unit
		for u in b.roster:
			if horseman==null and u.team==0 and u.mounted: horseman=u
			if defender==null and u.team==1 and u.kit==Arms.Kit.SPEAR: defender=u
		horseman.pos=Vector2(4,48)
		horseman.fatigue=0.0
		defender.pos=Vector2(15,48)
		defender.facing=Vector2.LEFT
		if braced: b._set_state(defender,Battle.State.GUARD,4.0)
		b.companies[horseman.squad].aim=defender.pos
		horseman.target=defender.id
		var fastest:=0.0
		for i in 80:
			b._rebuild_grid()
			b._state_step(horseman)
			fastest=maxf(fastest,horseman.charge_speed)
			if horseman.received>0 or defender.received>0: break
		check(fastest>=4.5,"A running horse gathers actual momentum")
		if braced:
			check(horseman.received>0 and horseman.mount_hp<48 and defender.hp==defender.max_hp,"A facing spear stops the charge and injures its mount")
		else:
			check(defender.received>0 and defender.max_hp-defender.hp>25 and horseman.received==0,"Unopposed cavalry lands a stronger moving strike")

func _test_deployment_and_camp() -> void:
	const Store:=preload("res://scripts/field/save.gd")
	const World:=preload("res://scripts/field/campaign.gd")
	var b:=Battle.new()
	b.setup(512)
	var enemy_before:=b.roster[b.side_size].pos
	var gear:=PackedInt32Array()
	for u in b.roster:
		gear.append(u.kit)
		if u.team==0: check(not Ground.blocked(u.pos,false),"Own muster is on dry traversable ground")
	var original:=b.companies[0].home
	var north:=b.companies[4].home
	check(b.deploy_company(0,4,2,2) and b.companies[0].home==north and b.companies[4].home==original,"Swap two actual company sites")
	check(b.roster[24].station.x==north.x and b.roster[0].station.x<north.x and b.roster[b.side_size].pos==enemy_before,"Existing archers take the front of the narrow column")
	for u in b.roster: check(u.kit==gear[u.id],"Muster cannot mint or reissue gear")
	var saved:=Store.snapshot(b)
	var read:=Store.restore(saved)
	check(read!=null and read.roster[24].station==b.roster[24].station and read.muster_manifest()==b.muster_manifest(),"Muster slot swap and assignments persist")
	var invalid:=saved.duplicate(true)
	invalid.muster[0][0]=invalid.muster[1][0]
	check(Store.restore(invalid)==null,"Reject overlapping deployment slots")
	b.start()
	check(not b.deploy_company(0,0,0,0),"Cannot reposition forces through the muster after deployment")
	# A deliberate short press during the last recovery frames uses the direction
	# at press time and cannot interrupt the existing strike.
	b.hero.state=Battle.State.RECOVER
	b.hero.timer=0.09
	b.hero.duration=0.34
	b.aim=Vector2.UP
	check(not b.press_action(1) and b.buffer_ticks==4,"Recovery queues a short skill press")
	b.aim=Vector2.DOWN
	var saved_input:=Store.restore(Store.snapshot(b))
	for i in 3:
		b.step()
		if saved_input: saved_input.step()
	check(b.hero.state==Battle.State.WINDUP and b.hero.locked==Vector2.UP and b.buffered_slot==-1 and saved_input!=null and saved_input.hero.locked==b.hero.locked,"Buffered strike preserves aim through a save")
	b.hero.state=Battle.State.MARCH
	b.sprinting=true
	b.input_state(Vector2.LEFT,Vector2.LEFT)
	var before:=b.hero.pos
	b.step()
	check(b.hero.pos.distance_to(before)>0.25 and b.breath<1.0,"Actual foot sprint spends breath")
	# Controlled settlement fixture: one secured dropped blade, one under guard.
	var v:=Battle.new()
	v.setup(20)
	var w:=World.new()
	check(w.bind(v) and w.reserve(),"Open a real world ticket for the salvage fixture")
	v.start()
	for u in v.roster:
		u.pos=Vector2(-10,0) if u.team==0 else Vector2(20,0)
		u.before=u.pos
	var safe:=v.roster[v.side_size]
	var guarded:=v.roster[v.side_size+1]
	safe.pos=Vector2(-9,0)
	v._hurt(v.hero,safe,10000,v.hero.pos)
	v._hurt(v.hero,guarded,10000,v.hero.pos)
	v.result="守军溃退"
	var receipt:=w.settle()
	check(receipt.get("reclaimed",-1)==1 and w.loose_weapons==1 and w.audit().is_empty(),"Only one accessible weapon enters friendly inventory")
	check(not w.camp_order("river") and w.enter_camp() and not w.camp_order("ration"),"No strategic act before continuing; hostile city cannot supply player")
	check(w.camp_order("river") and not w.camp_order("river"),"Army physically marches and cannot dispatch itself twice")
	for i in 3: check(w.wait_at_camp(),"World advances from the settled clock")
	check(w.player_view().army.location=="pingling" and w.camp_order("ration"),"The surviving army arrives before drawing local supplies")
	var saved_camp:=Store.restore(Store.snapshot(v))
	var rebound:=World.new()
	check(saved_camp!=null and rebound.bind(saved_camp) and rebound.snapshot()==w.snapshot() and rebound.receipt==receipt and rebound.audit().is_empty(),"Saving camp restores exactly one settlement and every timed march/transfer")
	var former:=Battle.new()
	former.setup(20,Battle.SEED,Arms.Kit.SPEAR,false,false)
	former.start()
	for i in 20: former.step()
	var legacy:=Store.snapshot(former)
	legacy.version=2
	legacy.erase("dry_muster")
	var old:=Store.restore(legacy)
	check(old!=null and not old.dry_muster and old.camp_actions.is_empty(),"Previous field save remains readable without a new campaign")

func _test_chariot_origin() -> void:
	const Store:=preload("res://scripts/field/save.gd")
	var b:=Battle.new()
	b.setup(20,Battle.SEED,Arms.Kit.BOW)
	var nose: Vector2=b.vehicle_pos[2]
	check(b.mount(2) and b.hero.pos.is_equal_approx(nose-Vector2.RIGHT*1.83),"Charioteer physically boards the visible platform")
	check(not b.mount(1) and b.vehicle==2,"Mount key cannot silently dismount a charioteer")
	b.start()
	b.input_state(Vector2.ZERO,Vector2.UP)
	check(b.action(0),"Loose one real arrow from the cart")
	var fired:=false
	for i in 30:
		b.step()
		for s in b.shots:
			if s.source==b.hero.id and not fired:
				fired=s.previous.distance_to(b.hero.pos+Vector2.UP*0.45)<0.02 and s.launch_height>Ground.deck_height(b.hero.pos)+0.85
	check(fired,"Arrow originates above the seat, not the draft horse")
	b.input_state(Vector2.DOWN,Vector2.LEFT)
	for i in 32: b.step()
	var parked: Vector2=b.vehicle_pos[2]
	var heading:=b.riding_heading
	check(b.mount(2) and b.vehicle==0 and b.hero.pos.distance_to(parked)>0.8 and b.parked_heading[2].is_equal_approx(heading),"Dismount onto a bank-side foot position without rotating the empty cart")
	var restored:=Store.restore(Store.snapshot(b))
	check(restored!=null and restored.vehicle_pos==b.vehicle_pos and restored.parked_heading==b.parked_heading,"Parking direction survives a save")
