extends SceneTree
const Battle:=preload("res://scripts/field/battle.gd")
const Ground:=preload("res://scripts/field/ground.gd")
const World:=preload("res://scripts/field/campaign.gd")
const Store:=preload("res://scripts/field/save.gd")

func _initialize() -> void:
	var b:=Battle.new()
	b.setup(512,Battle.SEED,Battle.Arms.Kit.SPEAR,true,true,512,true)
	var campaign:=World.new()
	if not campaign.bind(b) or not campaign.reserve():
		push_error("normal muster accounting")
		quit(1);return
	b.start()
	var crossing_tick:=-1
	var ram_arrival:=-1
	while b.result.is_empty() and b.tick<6000:
		b.input_state(Vector2.RIGHT if b.hero.pos.x<Ground.MOAT_X+4.2 else Vector2.ZERO,Vector2.RIGHT)
		if b.tick==90: b.command(0,Battle.Mission.PRESS,Battle.Channel.FLAG)
		b.step()
		if crossing_tick<0 and b.hero.pos.x>Ground.MOAT_X+4.: crossing_tick=b.tick
		if ram_arrival<0 and b.ram.distance_squared_to(Ground.GATE)<13.: ram_arrival=b.tick
		if b.tick%20==0 and not campaign.sync():
			push_error("campaign clock")
			quit(1);return
		if b.tick%500==0:
			print("BRIDGE_PROGRESS ",b.tick," gate=",b.gate_hp," ram=",b.ram," crew positions=",b.ram_crew," hits=",b.hits," hp=",b.hero.hp)
	var vv:=b.objectives.strength(b)
	print("BRIDGE_LINES ",JSON.stringify(vv)," capture=",b.capture," withdrawals=",b.escaped," retiring=",b.objectives.garrison_retiring," quiet=",b.objectives.quiet)
	for i in b.companies.size():
		var c:=b.companies[i]
		var num:=0
		var avg:=Vector2.ZERO
		for u in b.roster:
			if u.squad==i and not u.officer and not u.hero and b.active(u) and u.state!=Battle.State.ROUT:
				num+=1; avg+=u.pos
		if num>0: avg/=num
		print("BRIDGE_COMPANY ",i," side=",c.team," ready=",num," formed=",c.standing," regroup=",c.regrouping," mission=",c.mission," home=",c.home," aim=",c.aim," avg=",avg," lead=",b.corps.can_command(b,c))
	var ledger:=campaign.settle()
	var camp:=campaign.enter_camp()
	var waited:=campaign.wait_at_camp() if camp else false
	var march:=false
	if camp:
		var world:=campaign.player_view()
		march=not world.army.march.is_empty()
		if not march:
			for road:String in world.routes:
				if campaign.camp_order(road):
					march=true;break
	var restored:=Store.restore(Store.snapshot(b))
	var legacy_ok:=restored!=null and restored.bridgehead and restored.result==b.result and restored.aftermath_hours==b.aftermath_hours
	var audit:=campaign.audit().is_empty() and campaign.audit_quivers()
	var result:={"tick":b.tick,"end":b.result,"gate":b.gate_hp,"hero_health":b.hero.hp,"losses":b.losses,"hits":b.hits,"blocks":b.blocked_hits,"hero_crossed":crossing_tick,"ram_arrival":ram_arrival,"camp":camp,"wait_one_hour":waited,"march":march,"saved_result":legacy_ok,"ledger":not ledger.is_empty(),"audits":audit,"captured_city":ledger.get("captured_city",false),"spoils":ledger.get("spoils",{})}
	print("BRIDGE_FULL_RUN ",JSON.stringify(result))
	var ok:=not b.result.is_empty() and not ledger.is_empty() and audit and legacy_ok and camp and waited and march
	quit(0 if ok else 1)
