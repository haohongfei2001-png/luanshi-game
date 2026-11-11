extends RefCounted
## An objective belongs to this engagement. Territorial ownership changes only
## when troops actually hold the court. All strength is drawn from its roster.
const Ground := preload("res://scripts/field/ground.gd")
const Arms := preload("res://scripts/field/arms.gd")
enum Task { COURT, ESCORT }
const TITLES := ["夺取河关","护送冲车"]
const ESCORT_STROKES := 3
var enabled := true
var task := Task.COURT
var strokes := 0
var broken := [0,0]
var quiet := 0
var last_hits := 0
var last_gate := 260.0
var last_ram := Vector2(-9,1)
var decision := ""
var garrison_retiring := false

func brief() -> String:
	if task==Task.ESCORT:
		return "护送有役兵的冲车至城门，掩护撞门三次。"
	return "护送冲车破门，在守军争夺下占住内庭六秒。"

func strength(b) -> Dictionary:
	var power := [0.0,0.0]
	var ready := [0,0]
	var shaken := [0,0]
	var command := [0,0]
	var approach := [0,0]
	var court := [0,0]
	var quivers := [0,0]
	var moving := 0
	for c in b.companies:
		if c.standing>0 and b.corps.can_command(b,c):
			command[c.team]+=1
	for u in b.roster:
		if u.hero or u.officer or not b.active(u): continue
		var side: int=u.team
		if u.state==b.State.ROUT:
			shaken[side]+=1
			continue
		ready[side]+=1
		if u.pos.distance_squared_to(u.before)>0.0016: moving+=1
		var gear := 1.0
		if u.kit in [Arms.Kit.BOW,Arms.Kit.CROSSBOW]:
			quivers[side]+=u.ammo
			if u.ammo==0 and not b.legacy_missiles: gear=0.62
		if u.mounted: gear+=0.20
		power[side]+=(0.34+0.66*u.hp/u.max_hp)*(0.35+0.65*u.morale)*gear
		if u.pos.distance_squared_to(Ground.GATE)<19.0*19.0: approach[side]+=1
		if u.pos.distance_squared_to(Ground.COURT)<15.0*15.0: court[side]+=1
	for side in 2:
		power[side]*=0.68+0.32*command[side]/float(b.command_counts[side])
	return {"effective":power,"ready":ready,"routing":shaken,"command":command,"approach":approach,"court":court,"ammunition":quivers,"moving":moving}

func resolve(b) -> String:
	if b.hero.hp<=0:
		decision="主将阵亡，余军按在场军籍结算，河关仍由原守军控制。"
		return "主将阵亡"
	if b.hero.pos.x< -85 and b.companies[b.hero.squad].mission==b.Mission.WITHDRAW and b.escaped[0]>0:
		decision="主将与撤出人员到达西营，仍在关前的部队留作后卫。"
		return "成功撤离"
	if b.capture>=6.0:
		decision="城门已开，内庭由我军持续占据；守军余部沿粮道撤出。"
		return "夺取城内阵地"
	if task==Task.ESCORT:
		if strokes>=ESCORT_STROKES:
			decision="役兵将冲车送到门下并完成三次撞击，护送任务完成。"
			return "护送冲车成功"
		if b.ram_hp<=0:
			decision="冲车在抵达或完成撞门前损毁，护送任务终止。"
			return "护送失利"
		if b.gate_hp<=0 and b.ram.distance_squared_to(Ground.GATE)<4.8*4.8:
			decision="城门先由先锋攻开，役兵护送冲车抵达门洞。"
			return "护送冲车成功"
	if b.tick%20!=0: return ""
	var s:=strength(b)
	for side in 2:
		var other:=1-side
		var friendly: float=s.effective[side]
		var enemy: float=s.effective[other]
		# A held gate and a formed garrison can absorb a defeat on the outer field.
		var fortified: bool=side==1 and b.gate_hp>0 and s.court[1]>=maxi(2,ceili(b.ordinary_counts[1]*0.035))
		var contested: bool=s.approach[other]+s.court[other]>=maxi(2,ceili(b.ordinary_counts[other]*0.025))
		var collapse: bool=enemy>maxf(1,friendly*1.72) and (friendly<b.ordinary_counts[side]*0.23 or s.routing[side]>s.ready[side]*0.55)
		var pressure: bool=contested or s.ready[side]<=maxi(1,ceili(b.ordinary_counts[side]*0.08)) or s.routing[side]>s.ready[side]
		if collapse and pressure and not fortified:
			broken[side]=mini(8,broken[side]+1)
		else:
			broken[side]=maxi(0,broken[side]-2)
		if broken[side]>=8:
			if side==1 and b.gate_hp<=0 and task==Task.COURT:
				if not garrison_retiring:
					garrison_retiring=true
					# Outer-line collapse triggers a physical withdrawal. The attackers
					# must still take the court before the city changes hands.
					for company in b.companies:
						if company.team==1 and (company.standing*2<company.initial or company.home.x<Ground.WALL_X or not b.corps.can_command(b,company)):
							company.mission=b.Mission.WITHDRAW
				continue
			decision=("守军失去关前阵地" if side==1 else "我军无法维持攻势")+"，存留战力 %d 对 %d，可指挥部队 %d 支。" % [roundi(friendly),roundi(enemy),s.command[side]]
			return "守军溃退" if side==1 else "攻势瓦解"
	var strikes: int=b.hits[0]+b.hits[1]
	var stationary: bool=s.moving<=maxi(2,ceili((s.ready[0]+s.ready[1])*0.035)) and strikes==last_hits and is_equal_approx(last_gate,b.gate_hp) and b.ram.distance_squared_to(last_ram)<0.1 and b.capture<=0
	quiet=quiet+1 if stationary else 0
	last_hits=strikes
	last_gate=b.gate_hp
	last_ram=b.ram
	if b.tick*b.DT>=1500 or quiet>=50:
		if b.gate_hp>0 and s.ready[1]>0:
			decision="守军保住城门，攻方长时间未能继续推进。"
			return "守城成功"
		decision="双方已停止接敌，河关归属维持。"
		return "两军脱离接战"
	return ""

func snapshot() -> Dictionary:
	return {"enabled":enabled,"task":task,"strokes":strokes,"broken":broken.duplicate(),"quiet":quiet,"last_hits":last_hits,"last_gate":last_gate,"last_ram":last_ram,"decision":decision,"garrison_retiring":garrison_retiring}

func restore(v: Variant,tick: int) -> bool:
	if not v is Dictionary or not v.get("enabled") is bool or v.get("task",-1) not in [Task.COURT,Task.ESCORT]: return false
	for key in ["strokes","quiet","last_hits"]:
		if not v.get(key) is int or v[key]<0 or v[key]>100000000: return false
	if not v.get("broken") is Array or v.broken.size()!=2: return false
	for n in v.broken:
		if not n is int or n<0 or n>8: return false
	if not v.get("last_gate") is float or not is_finite(v.last_gate) or v.last_gate<0 or v.last_gate>260: return false
	if not v.get("last_ram") is Vector2 or not v.last_ram.is_finite() or not v.get("decision") is String or v.decision.length()>160: return false
	if v.strokes>tick or v.quiet>tick: return false
	for key in ["enabled","task","strokes","quiet","last_hits","last_gate","last_ram","decision"]: set(key,v[key])
	if not v.get("garrison_retiring",false) is bool: return false
	garrison_retiring=v.get("garrison_retiring",false)
	broken=v.broken.duplicate()
	return true
