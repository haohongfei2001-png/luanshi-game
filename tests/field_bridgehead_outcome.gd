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
	var breach_tick:=-1
	while b.result.is_empty() and b.tick<6000:
		b.input_state(Vector2.RIGHT if b.hero.pos.x<Ground.MOAT_X+4.2 else Vector2.ZERO,Vector2.RIGHT)
		if b.tick==90: b.command(0,Battle.Mission.PRESS,Battle.Channel.FLAG)
		b.step()
		if crossing_tick<0 and b.hero.pos.x>Ground.MOAT_X+4.: crossing_tick=b.tick
		if breach_tick<0 and b.gate_hp<=0: breach_tick=b.tick
		if b.tick%20==0 and not campaign.sync():
			push_error("campaign clock")
			quit(1);return
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
	var result:={"tick":b.tick,"end":b.result,"gate":b.gate_hp,"hero_health":b.hero.hp,"losses":b.losses,"hits":b.hits,"blocks":b.blocked_hits,"hero_crossed":crossing_tick,"breached":breach_tick,"camp":camp,"wait_one_hour":waited,"march":march,"saved_result":legacy_ok,"ledger":not ledger.is_empty(),"audits":audit,"captured_city":ledger.get("captured_gate",false),"spoils":ledger.get("spoils",{})}
	print("BRIDGE_FULL_RUN ",JSON.stringify(result))
	var ok:=b.result=="守城成功" and breach_tick>0 and not ledger.is_empty() and not ledger.get("captured_gate",true) and audit and legacy_ok and camp and waited and march
	quit(0 if ok else 1)
