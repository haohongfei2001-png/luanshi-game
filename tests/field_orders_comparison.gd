extends SceneTree
## Compare legal deployment choices against the unchanged river-gate candidate.
const Battle:=preload("res://scripts/field/battle.gd")
const World:=preload("res://scripts/field/campaign.gd")
const Ground:=preload("res://scripts/field/ground.gd")
var failed:=false

func _initialize() -> void:
	var records:=[]
	for plan: String in ["escort","outer_companies","withdraw"]:
		records.append(_campaign(plan))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://artifacts"))
	var out:=FileAccess.open("res://artifacts/field-orders.json",FileAccess.WRITE)
	out.store_string(JSON.stringify(records,"  "))
	quit(1 if failed else 0)

func _assignment(i: int,plan: String) -> int:
	if plan=="withdraw":
		return Battle.Mission.HOLD if i in [2,7] else Battle.Mission.WITHDRAW
	if plan=="escort":
		if i in [2,6,7,8,11,12]: return Battle.Mission.ESCORT
		if i in [0,4,5,9,10,14]: return Battle.Mission.FLANK
		return Battle.Mission.PRESS
	if i in [1,2,3,6,7,8,11,12,13]: return Battle.Mission.ESCORT
	if i in [0,4,5,9]: return Battle.Mission.RESERVE
	return Battle.Mission.FLANK

func _campaign(plan: String) -> Dictionary:
	var b:=Battle.new()
	b.setup(512)
	var w:=World.new()
	var legal:=w.bind(b)
	for i in b.companies_per_side:
		legal=b.command(i,_assignment(i,plan),Battle.Channel.FLAG) and legal
	legal=b.mount(1) and w.reserve() and legal
	b.start()
	var first_damage:=-1
	var first_breach:=-1
	var impacts:=0
	var reissued:=false
	for i in 2600:
		var goal:=Ground.COURT
		if plan=="withdraw": goal=Vector2(-96,0)
		elif b.gate_hp>0: goal=b.ram+Vector2(-4.2,-2.5)
		var next:=Ground.waypoint(b.hero.pos,goal)
		var walk:=b.hero.pos.direction_to(next) if next.distance_to(b.hero.pos)>1.0 else Vector2.ZERO
		var direction:=walk
		var nearby:=b._near(b.hero.pos,3.0,1)
		var nearest:=-1
		var best:=INF
		for id in nearby:
			var dist:=b.hero.pos.distance_squared_to(b.roster[id].pos)
			if dist<best and Ground.clear_shot(b.hero.pos,b.roster[id].pos,b.gate_hp<=0):
				best=dist
				nearest=id
		if nearest>=0: direction=b.roster[nearest].pos-b.hero.pos
		b.input_state(walk,direction)
		if nearest>=0 and plan!="withdraw": b.action(0)
		if b.gate_hp<=0 and not reissued and plan!="withdraw":
			for j in b.companies_per_side:
				if _assignment(j,plan)==Battle.Mission.ESCORT: b.command(j,Battle.Mission.PRESS,Battle.Channel.COURIER)
			reissued=true
		var old_timer:=b.ram_timer
		b.step()
		if b.ram_timer>old_timer+0.8: impacts+=1
		if first_damage<0 and b.gate_hp<260: first_damage=b.tick
		if first_breach<0 and b.gate_hp<=0: first_breach=b.tick
		if b.result!="": break
	legal=w.sync() and w.audit_quivers() and legal
	if b.result!="": legal=not w.settle().is_empty() and w.audit().is_empty() and w.audit_quivers() and legal
	var row:=b.report()
	row.merge({"scenario":plan,"initial_ordinary":1024,"ram_impacts":impacts,"gate_first_damage":first_damage,"breach":first_breach,
		"hero_damage_events":b.hero.impacts,"surviving_ordinary":[512-b.losses[0],512-b.losses[1]],"world_receipt":not w.receipt.is_empty(),"accounted":legal})
	print("FIELD_ORDER_TRIAL "+JSON.stringify(row))
	if not legal: failed=true
	return row
