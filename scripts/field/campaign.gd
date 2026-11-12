extends "res://scripts/world_sim.gd"
## The river gate is a new military opening at Hequ in the existing three-city world.
## Old careers retain their actual forces. Only a new opening receives this manifest.
const Field := preload("res://scripts/field/battle.gd")
const Arms := preload("res://scripts/field/arms.gd")
const GroundMap := preload("res://scripts/field/ground.gd")
const Patrol := preload("res://scripts/field/patrol_muster.gd")
const ENCOUNTER := "river_gate:1"
const FORCES := ["relief","hequ"]
const START_SECONDS := 3595.0
var field_epoch:=START_SECONDS
var field: Field
var loose_weapons := 0
var receipt: Dictionary = {}
var reserved_weapons := [0,0]

func bind(model: Field) -> bool:
	if field!=null or model.ordinary_counts[0]<=0 or model.ordinary_counts[1]<=0: return false
	if model.world_patrol:
		if not Patrol.arrive(self,model.rng.seed): return false
		field_epoch=_state.time_seconds
	else:
		reset(model.rng.seed)
	field=model
	_state.origin="river_gate"
	_state.mode="field"
	for team in 2:
		var force:=_entity(FORCES[team])
		if field.world_patrol:
			if Patrol.ordinary_for(force.soldiers,force.weapons,team==0)!=field.ordinary_counts[team]: return false
			continue
		var people:=field.ordinary_counts[team]+field.command_counts[team]+(1 if team==0 else 0)
		force.soldiers=people
		# One spare sidearm at the camp makes the dual-sword muster possible.
		force.weapons=people+(1 if team==0 else 0)
		force.food=people*3
		_state.initial_force_roster[FORCES[team]]=people
	if not field.legacy_missiles:
		var opening := [[Arms.ARROWS_PER_QUIVER,Arms.BOLTS_PER_CASE],[0,0]]
		for u in field.roster:
			if u.hero or Arms.issue(u.kit)==0: continue
			opening[u.team][_ammo_kind(u.kit)]+=Arms.issue(u.kit)
		for team in 2:
			_entity(FORCES[team]).field_ammo=opening[team].duplicate()
		_state.field_ammo_initial=[opening[0][0]+opening[1][0],opening[0][1]+opening[1][1]]
		_state.field_ammo_loose=[0,0]
		_state.field_ammo_spent=[0,0]
	if not field.world_patrol:
		_state.armies.relief.location="hequ"
		_state.initial_totals=totals()
		if not advance_seconds(field_epoch): return false
	if field.started:
		if not reserve(): return false
		if not sync(): return false
		if field.result!="" and settle().is_empty(): return false
		if (field.at_camp or field.aftermath_hours>0) and (_state.campaign_ended or receipt.is_empty()): return false
		var cursor:=0
		for hour in field.aftermath_hours+1:
			while cursor<field.camp_actions.size() and field.camp_actions[cursor][0]==hour:
				if not _camp_action(field.camp_actions[cursor][1]): return false
				cursor+=1
			if hour<field.aftermath_hours and not advance(1): return false
		if cursor!=field.camp_actions.size(): return false
	return audit().is_empty() and audit_quivers()

static func _ammo_kind(kit: int) -> int:
	return 1 if kit==Arms.Kit.CROSSBOW else 0

func audit_quivers() -> bool:
	if field.legacy_missiles: return true
	var count := [0,0]
	for pool: Dictionary in [_state.armies,_state.cities]:
		for entity: Dictionary in pool.values():
			var stock: Array=entity.get("field_ammo",[0,0])
			for k in 2:
				if stock[k]<0: return false
				count[k]+=stock[k]
	for k in 2: count[k]+=_state.field_ammo_loose[k]+_state.field_ammo_spent[k]
	if _state.battle_locks.get("relief")==ENCOUNTER:
		var used:=0
		for u in field.roster:
			var issued:=Arms.issue(u.kit)
			if u.ammo<0 or u.ammo>issued: return false
			count[_ammo_kind(u.kit)]+=issued
			used+=issued-u.ammo
		if used!=field.arrow_count: return false
	return count==_state.field_ammo_initial

func totals() -> Dictionary:
	var all:=super.totals()
	all.weapons+=loose_weapons
	return all

func _reserved_for(entity: Dictionary,resource: String) -> int:
	if resource=="weapons" and _state.battle_locks.get("relief")==ENCOUNTER:
		for team in 2:
			if is_same(entity,_entity(FORCES[team])): return reserved_weapons[team]
	return super._reserved_for(entity,resource)

func reserve() -> bool:
	if _state.battle_tickets.has(ENCOUNTER): return _state.battle_tickets[ENCOUNTER].status=="running"
	var rosters := [[],[]]
	var weapons := [0,0]
	var ammunition := [[0,0],[0,0]]
	for u in field.roster:
		ammunition[u.team][_ammo_kind(u.kit)]+=Arms.issue(u.kit)
		rosters[u.team].append({"id":u.id,"weapon":Arms.NAMES[u.kit],"officer":u.officer,"hero":u.hero})
		weapons[u.team]+=_pieces(u.kit)
	for team in 2:
		var force:=_entity(FORCES[team])
		if rosters[team].size()>force.soldiers or weapons[team]>force.weapons: return false
		if not field.world_patrol and rosters[team].size()!=force.soldiers: return false
		if not field.legacy_missiles:
			for k in 2:
				if ammunition[team][k]>force.field_ammo[k]: return false
	reserved_weapons=weapons
	if not field.legacy_missiles:
		for team in 2:
			var force:=_entity(FORCES[team])
			for k in 2: force.field_ammo[k]-=ammunition[team][k]
	_state.battle_tickets[ENCOUNTER]={"battle_id":ENCOUNTER,"location":"hequ","participating_force_ids":FORCES.duplicate(),
		"reserved_roster_snapshot":rosters,"time":_state.time_seconds,"status":"running"}
	_state.battle_locks={"relief":ENCOUNTER,"hequ":ENCOUNTER}
	_event("battle_started",{"battle_id":ENCOUNTER,"counts":[rosters[0].size(),rosters[1].size()]})
	return audit().is_empty() and audit_quivers()

func sync() -> bool:
	if not field.started: return true
	if not receipt.is_empty(): return true
	if _state.battle_locks.get("relief")!=ENCOUNTER: return false
	var target: float=field_epoch+field.tick*Field.DT
	if target<_state.time_seconds: return false
	_advance_clock_to(target)
	return true

static func _pieces(kit: int) -> int:
	return 2 if kit==Arms.Kit.DUAL else 1

func settle() -> Dictionary:
	if not receipt.is_empty(): return receipt.duplicate(true)
	if field.result=="" or not sync() or not audit().is_empty() or not audit_quivers(): return {}
	var dead := [[],[]]
	var living := [[],[]]
	var captives := [[],[]]
	var taken_weapons := [0,0]
	var fled := [[],[]]
	var dropped := [0,0]
	var loose_by_kit := [{},{}]
	var withdrawing_people:=0
	var withdrawing_gear:=0
	var surviving_gear:=[0,0]
	var ticket: Dictionary=_state.battle_tickets[ENCOUNTER]
	for team in 2:
		for entry in ticket.reserved_roster_snapshot[team]:
			var u:=field.roster[int(entry.id)]
			if u.team!=team or entry.weapon!=Arms.NAMES[u.kit] or entry.hero!=u.hero or entry.officer!=u.officer: return {}
			var pieces:=_pieces(u.kit)
			if u.hp<=0:
				dead[team].append(u.id)
				dropped[team]+=pieces
				loose_by_kit[team][entry.weapon]=int(loose_by_kit[team].get(entry.weapon,0))+pieces
			else:
				living[team].append(u.id)
				if u.officer and field.corps.is_captive(u.id):
					captives[team].append(u.id)
					taken_weapons[team]+=pieces
					continue
				surviving_gear[team]+=pieces
				if u.state==Field.State.ESCAPED: fled[team].append(u.id)
				if team==0 and (u.hero or u.state==Field.State.ESCAPED):
					withdrawing_people+=1
					withdrawing_gear+=pieces
	# Withdrawal below starts a march. Remember what the player could actually
	# witness at the gate before moving their army to the campaign route.
	var witnessed_here: bool=field.hero.hp>0 and _state.armies.relief.location=="hequ"
	var before:=_state.duplicate(true)
	var old_loose:=loose_weapons
	for team in 2:
		var force:=_entity(FORCES[team])
		force.soldiers-=dead[team].size()+captives[team].size()
		force.weapons+=taken_weapons[1-team]-taken_weapons[team]-dropped[team]
		_state.ledger.prisoners+=captives[team].size()
		_state.ledger.dead+=dead[team].size()
		loose_weapons+=dropped[team]
	_unlock_battle(ENCOUNTER)
	var captured:=field.result=="夺取城内阵地"
	var spoils: Dictionary={}
	var reclaimed:=0
	if field.result in ["夺取城内阵地","守军溃退","守军已失去战斗能力"]:
		# Collect only the weapon of a fallen enemy in secured, accessible ground.
		field._rebuild_grid()
		for id in dead[1]:
			var body:=field.roster[int(id)]
			if not _secured(body.pos): continue
			var name_of_kit: String=Arms.NAMES[body.kit]
			var pieces:=_pieces(body.kit)
			spoils[name_of_kit]=int(spoils.get(name_of_kit,0))+pieces
			reclaimed+=pieces
		loose_weapons-=reclaimed
		_entity("relief").weapons+=reclaimed
	if captured:
		# Holding the court dislodges the garrison. Living opponents stay on the
		# map as a field force on an actual route, keeping their assigned weapons.
		var city: Dictionary=_state.cities.hequ
		var count: int=living[1].size()-captives[1].size()
		if count>0:
			var remnant:=_army("bei","hequ",count,surviving_gear[1],0)
			_state.armies["hequ_remnant"]=remnant
			city.soldiers-=count
			city.weapons-=surviving_gear[1]
			_march_home(remnant,"grain_road","anping")
		_capture("hequ",_state.armies.relief.owner)
	elif field.result=="成功撤离":
		var relief: Dictionary=_state.armies.relief
		var left: int=living[0].size()-captives[0].size()-withdrawing_people
		if left>0:
			var left_gear: int=surviving_gear[0]-withdrawing_gear
			_state.armies["hequ_rearguard"]=_army("sheng","hequ",left,left_gear,0)
			relief.soldiers-=left
			relief.weapons-=left_gear
		_march_home(relief,"river","pingling")
	var arrow_ledger: Dictionary={}
	if not field.legacy_missiles:
		arrow_ledger=_settle_quivers(captured)
	_state.commander.hp=field.hero.hp
	_state.commander.alive=field.hero.hp>0
	_state.campaign_ended=not _state.commander.alive
	ticket.status="committed"
	var issued := {"battle_id":ENCOUNTER,"outcome":field.result,"ending_seconds":_state.time_seconds,
		"dead_ids":dead,"living_ids":living,"escaped_ids":fled,"dropped_by_kit":loose_by_kit,
		"loose_weapons":loose_weapons,"spoils":spoils,"reclaimed":reclaimed,"captured_gate":captured,"commander_alive":_state.commander.alive}
	if field.objectives.enabled:
		issued.strategy={"task":field.objectives.task,"reason":field.objectives.decision,"strength":field.objectives.strength(field)}
		issued.officers=field.corps.summary(field)
		issued.captured_officers=captives
	if not field.legacy_missiles: issued.ammunition=arrow_ledger
	ticket.receipt=issued.duplicate(true)
	_event("field_settled",{"battle_id":ENCOUNTER,"outcome":field.result,"dead":[dead[0].size(),dead[1].size()]})
	if witnessed_here:
		var city: Dictionary=_state.cities.hequ
		var observed: Dictionary={"battle_id":ENCOUNTER,"outcome":field.result,"owner":city.owner}
		if city.owner==_state.armies.relief.owner:
			observed.merge({"soldiers":city.soldiers,"food":city.food,"fort":city.fort})
		_queue_report("hequ","亲历斥候",_state.hour,_state.hour,observed)
		_deliver_reports()
	if not audit().is_empty() or not audit_quivers():
		_state=before
		loose_weapons=old_loose
		return {}
	receipt=issued
	return receipt.duplicate(true)

# Attribute every unspent arrow and bolt to its surviving carrier or its place
# on the field. In-flight rounds are already expended on release.
func _settle_quivers(captured: bool) -> Dictionary:
	var fired := [[0,0],[0,0]]
	var dropped := [[0,0],[0,0]]
	var carried := [[0,0],[0,0]]
	for u in field.roster:
		var issued:=Arms.issue(u.kit)
		if issued==0: continue
		var k:=_ammo_kind(u.kit)
		_state.field_ammo_spent[k]+=issued-u.ammo
		fired[u.team][k]+=issued-u.ammo
		if u.hp<=0:
			_state.field_ammo_loose[k]+=u.ammo
			dropped[u.team][k]+=u.ammo
			continue
		var dest:String=FORCES[u.team]
		if u.officer and field.corps.is_captive(u.id): dest=FORCES[1-u.team]
		elif captured and u.team==1: dest="hequ_remnant"
		elif field.result=="成功撤离" and u.team==0 and not u.hero and u.state!=Field.State.ESCAPED:
			dest="hequ_rearguard"
		var force:=_entity(dest)
		if not force.has("field_ammo"): force.field_ammo=[0,0]
		force.field_ammo[k]+=u.ammo
		carried[u.team][k]+=u.ammo
	return {"types":["arrow","bolt"],"expended":fired,"dropped":dropped,"returned":carried}

func _march_home(force: Dictionary,route: String,destination: String) -> void:
	var arrival: float=_state.time_seconds+float(ROUTES[route].hours)*3600.0
	force.location=""
	force.march={"route":route,"destination":destination,"arrives_at":ceili(arrival/3600.0),"arrives_at_seconds":arrival}

func own_supply() -> int:
	return _state.armies.relief.food

func _secured(at: Vector2) -> bool:
	var open:=field.gate_hp<=0
	for i in field._near(at,5.5,1):
		var guard:=field.roster[i]
		if guard.state!=Field.State.ROUT and GroundMap.clear_shot(at,guard.pos,open): return false
	for i in field._near(at,7.5,0):
		var carrier:=field.roster[i]
		if carrier.state!=Field.State.ROUT and GroundMap.clear_shot(at,carrier.pos,open): return true
	return false

func enter_camp() -> bool:
	if receipt.is_empty() or _state.campaign_ended: return false
	field.at_camp=true
	return true

func wait_at_camp() -> bool:
	if not field.at_camp or field.aftermath_hours>=168 or _state.campaign_ended or not advance(1): return false
	field.aftermath_hours+=1
	return true

func _camp_action(command: String) -> bool:
	if command=="ration":
		var army: Dictionary=_state.armies.relief
		var local: Dictionary=_state.cities.get(army.location,{})
		if local.is_empty(): return false
		var batch:=mini(army.soldiers,local.food)
		return batch>0 and transfer(army.location,"relief","food",batch)
	return march(command)

func camp_order(command: String) -> bool:
	if not field.at_camp or field.camp_actions.size()>=300 or _state.campaign_ended or not _camp_action(command): return false
	field.camp_actions.append([field.aftermath_hours,command])
	return true
