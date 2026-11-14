extends SceneTree
## The ordinary shell and field rules, including an old v4 snapshot with no moat.
const Battle:=preload("res://scripts/field/battle.gd")
const Ground:=preload("res://scripts/field/ground.gd")
const Store:=preload("res://scripts/field/save.gd")
const World:=preload("res://scripts/field/campaign.gd")
var passed:=true

func expect(ok:bool,reason:String) -> void:
	if not ok:
		passed=false
		push_error(reason)

func _initialize() -> void:
	var b:=Battle.new()
	b.setup(512,Battle.SEED,Battle.Arms.Kit.SPEAR,true,true,512,true)
	expect(b.ordinary_counts==PackedInt32Array([512,512]) and b.command_counts==PackedInt32Array([16,16]),"Company ledger")
	var origin:=b.hero.pos
	var west:=Vector2(Ground.MOAT_X-4.5,6.5)
	expect(Ground.travel(west,Vector2.RIGHT,false,true)==west,"Water on the bank is impassable")
	expect(Ground.travel(Vector2(Ground.MOAT_X-4.5,0),Vector2.RIGHT,false,true).x>Ground.MOAT_X-4.0,"Boots can cross the deck")
	expect(Ground.travel(west,Vector2.RIGHT,false).x>west.x,"Original field is unaffected")
	for u in b.roster:
		expect(not Ground.moat_blocks(u.pos),"Soldier musters in the water "+str(u.id))
	var muster:=Battle.new()
	muster.setup(100,Battle.SEED,Battle.Arms.Kit.SPEAR,true,true,100,true)
	for shape in Battle.FORMATIONS.size():
		for slot in muster.companies_per_side:
			expect(muster.deploy_company(0,slot,shape,1),"Rearrange the bridge muster")
			for u in muster.roster:
				expect(not Ground.moat_blocks(u.pos),"A redeployed file starts below the water "+str(u.id))
	var world:=World.new()
	expect(world.bind(b) and world.reserve(),"Crossing has its own real reserved military ledger")
	var was_west:={}
	for u in b.roster:
		if u.team==0 and not u.hero and not u.officer and u.pos.x<Ground.MOAT_X-3.: was_west[u.id]=true
	var crossed:={}
	b.start()
	for i in 400:
		if not b.result.is_empty(): break
		# A directed walk uses the same authoritative simulation as the controller.
		b.input_state(Vector2.RIGHT if b.hero.pos.x<Ground.MOAT_X+4.1 else Vector2.ZERO,Vector2.RIGHT)
		if b.tick in [70,84,99,116,139,151]: b.press_action(0)
		b.step()
		for u in b.roster:
			if was_west.has(u.id) and u.pos.x>Ground.MOAT_X+4. and absf(u.pos.y)<5.: crossed[u.id]=true
		if b.tick==140:
			var restored:=Store.restore(Store.snapshot(b))
			expect(restored!=null and restored.bridgehead and restored.hero.pos.is_equal_approx(b.hero.pos),"Mid-crossing save restored the same encounter")
			if restored!=null:
				expect(restored.companies[0].home==b.companies[0].home and restored.roster[0].station==b.roster[0].station,"Formation stations round-trip")
	expect(b.hero.pos.x>Ground.MOAT_X+3.5 and origin.x<Ground.MOAT_X-4., "The operator crosses from west to east")
	expect(crossed.size()>12 and b.hits[0]+b.hits[1]>10 and b.blocked_hits>0,"Companies physically cross, fight and block")
	expect(world.sync() and world.audit().is_empty() and world.audit_quivers(),"Ledger after combat")
	var old:=Battle.new()
	old.setup(20)
	var save:=Store.snapshot(old)
	save.erase("bridgehead")
	var old_restored:=Store.restore(save)
	expect(old_restored!=null and not old_restored.bridgehead and old_restored.hero.pos==old.hero.pos,"Unmodified previous v4")
	print("BRIDGEHEAD_SIM ",JSON.stringify({"pass":passed,"tick":b.tick,"crossed":crossed.size(),"hits":b.hits,"blocks":b.blocked_hits,"deaths":b.losses,"hero":[b.hero.pos.x,b.hero.pos.y],"result":b.result}))
	quit(0 if passed else 1)
