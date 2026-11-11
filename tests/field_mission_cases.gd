extends SceneTree
const Battle:=preload("res://scripts/field/battle.gd")
const Save:=preload("res://scripts/field/save.gd")
const World:=preload("res://scripts/field/campaign.gd")
const Ground:=preload("res://scripts/field/ground.gd")
var errors: Array[String]=[]

func check(ok: bool,message: String) -> void:
	if not ok:
		errors.append(message)
		push_error(message)

func _initialize() -> void:
	_crowd()
	_different_armies()
	_escort()
	_works_after_breach()
	print("FIELD_MISSIONS_"+("PASS " if errors.is_empty() else "FAIL ")+JSON.stringify(errors))
	quit(0 if errors.is_empty() else 1)

func _crowd() -> void:
	# An intentionally pathological save-like starting arrangement off the walls.
	var field:=Battle.new()
	field.setup(100)
	var origin:=Vector2(16,49)
	for i in 80:
		field.roster[i].pos=origin
		field.roster[i].before=origin
	field._rebuild_grid()
	var count:=0
	for t in 72:
		field._rebuild_grid()
		for i in 80:
			if (t+i)%4!=0: continue
			var u:=field.roster[i]
			var relief:=field.density.ease(u.pos,u.density_cell,i)
			field._move(u,relief*0.24)
	var span:=Rect2(origin,Vector2.ZERO)
	var buckets: Dictionary={}
	for i in 80:
		var p:=field.roster[i].pos
		if p.distance_squared_to(origin)<0.01: count+=1
		var k:=Vector2i((p*2).floor())
		buckets[k]=int(buckets.get(k,0))+1
		span=span.expand(p)
	var peak: int=buckets.values().max()
	check(count<=3 and peak<20 and minf(span.size.x,span.size.y)>2.0,"Coincident infantry spreads in width and depth")
	var cell:=field.density.register(Vector2(-67,43),1.0,false)
	field.density.register(Vector2(-67,43),1.0,false)
	check(field.density.ease(Vector2(-67,43),cell,4)==Vector2.ZERO,"Two close fighters retain contact")
	print("FIELD_CROWD "+JSON.stringify({"original":80,"remaining_at_origin":count,"span_m":[span.size.x,span.size.y],"peak_half_metre_cell":peak}))

func _different_armies() -> void:
	var b:=Battle.new()
	b.setup(641,Battle.SEED,Battle.Arms.Kit.SPEAR,true,true,389)
	var w:=World.new()
	check(b.roster.size()==641+389+21+13+1 and w.bind(b) and w.reserve(),"1030 ordinary identities, unequal armies and real inventories")
	b.start()
	for i in 95: b.step()
	var restored:=Save.restore(Save.snapshot(b))
	check(restored!=null and b.hits[0]>0 and b.hits[1]>0,"Unequal forces exchange real damage and save")
	if restored:
		for i in 20:
			b.step()
			restored.step()
		check(Save.snapshot(restored)==Save.snapshot(b),"Asymmetric companies, officers and damage resume exactly")
	var info:=b.report()
	print("FIELD_ASYMMETRIC "+JSON.stringify({"counts":info.ordinary_rosters,"roster":b.roster.size(),"hits":b.hits,"companies":[b.command_counts[0],b.command_counts[1]]}))

func _escort() -> void:
	var b:=Battle.new()
	b.setup(512)
	b.objectives.task=Battle.Objectives.Task.ESCORT
	for i in b.companies_per_side:
		var mission:=Battle.Mission.PRESS
		if i%4 in [1,2] or i in [2,7]: mission=Battle.Mission.ESCORT
		elif i in [0,4]: mission=Battle.Mission.FLANK
		b.command(i,mission,Battle.Channel.FLAG)
	var world:=World.new()
	check(world.bind(b) and world.reserve(),"Escort takes real weapons and forces")
	b.start()
	for i in 3600:
		b.step()
		if b.result!="": break
	var receipt:=world.settle()
	check(b.result=="护送冲车成功" and not receipt.is_empty() and not receipt.captured_gate,"Win the convoy objective without taking ownership of the city")
	check(b.ram.distance_squared_to(Ground.GATE)<24 and (b.objectives.strokes>=3 or b.gate_hp<=0),"Crew got a real vehicle to the gate")
	check(b.losses[1]<b.ordinary_counts[1] and world.audit().is_empty(),"Survivors and equipment remain on the real ledger")
	print("FIELD_ESCORT "+JSON.stringify(b.report()))

func _works_after_breach() -> void:
	var b:=Battle.new()
	b.setup(100)
	b.objectives.task=Battle.Objectives.Task.ESCORT
	b.gate_hp=0
	b.ram=Ground.GATE-Vector2(5.1,0)
	for u in b.roster:
		if u.engineer: u.pos=b.ram+Vector2(-1.4,1.5 if u.id%2==0 else -1.5)
	b._rebuild_grid()
	for i in 48:
		b.tick=i+1
		b._siege()
	check(b.ram.distance_squared_to(Ground.GATE)<4.8*4.8 and b.objectives.strokes==0,"A breached door allows delivery without imaginary blows")
