extends "res://scripts/world_sim.gd"
## The river gate is a new military opening at Hequ in the existing three-city world.
## Old careers retain their actual forces. Only a new opening receives this manifest.
const Field := preload("res://scripts/field/battle.gd")
const Arms := preload("res://scripts/field/arms.gd")
const ENCOUNTER := "river_gate:1"
const FORCES := ["relief","hequ"]
const START_SECONDS := 3595.0
var field: Field
var loose_weapons := 0
var receipt: Dictionary = {}
var reserved_weapons := [0,0]

func bind(model: Field) -> bool:
	if field!=null or model.side_size not in Field.SCALES: return false
	reset(model.rng.seed)
	field=model
	_state.origin="river_gate"
	_state.mode="field"
	var companies := ceili(float(field.side_size)/32.0)
	for team in 2:
		var force:=_entity(FORCES[team])
		var people:=field.side_size+companies+(1 if team==0 else 0)
		force.soldiers=people
		# One spare sidearm at the camp makes the dual-sword muster possible.
		force.weapons=people+(1 if team==0 else 0)
		force.food=people*3
		_state.initial_force_roster[FORCES[team]]=people
	_state.armies.relief.location="hequ"
	_state.initial_totals=totals()
	if not advance_seconds(START_SECONDS): return false
	if field.started:
		if not reserve(): return false
		if not sync(): return false
		if field.result!="" and settle().is_empty(): return false
	return audit().is_empty()

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
	for u in field.roster:
		rosters[u.team].append({"id":u.id,"weapon":Arms.NAMES[u.kit],"officer":u.officer,"hero":u.hero})
		weapons[u.team]+=_pieces(u.kit)
	for team in 2:
		var force:=_entity(FORCES[team])
		if rosters[team].size()!=force.soldiers or weapons[team]>force.weapons: return false
	reserved_weapons=weapons
	_state.battle_tickets[ENCOUNTER]={"battle_id":ENCOUNTER,"location":"hequ","participating_force_ids":FORCES.duplicate(),
		"reserved_roster_snapshot":rosters,"time":_state.time_seconds,"status":"running"}
	_state.battle_locks={"relief":ENCOUNTER,"hequ":ENCOUNTER}
	_event("battle_started",{"battle_id":ENCOUNTER,"counts":[rosters[0].size(),rosters[1].size()]})
	return audit().is_empty()

func sync() -> bool:
	if not field.started: return true
	if not receipt.is_empty(): return true
	if _state.battle_locks.get("relief")!=ENCOUNTER: return false
	var target: float=START_SECONDS+field.tick*Field.DT
	if target<_state.time_seconds: return false
	_advance_clock_to(target)
	return true

static func _pieces(kit: int) -> int:
	return 2 if kit==Arms.Kit.DUAL else 1

func settle() -> Dictionary:
	if not receipt.is_empty(): return receipt.duplicate(true)
	if field.result=="" or not sync() or not audit().is_empty(): return {}
	var dead := [[],[]]
	var living := [[],[]]
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
				surviving_gear[team]+=pieces
				if u.state==Field.State.ESCAPED: fled[team].append(u.id)
				if team==0 and (u.hero or u.state==Field.State.ESCAPED):
					withdrawing_people+=1
					withdrawing_gear+=pieces
	var before:=_state.duplicate(true)
	var old_loose:=loose_weapons
	for team in 2:
		var force:=_entity(FORCES[team])
		force.soldiers-=dead[team].size()
		force.weapons-=dropped[team]
		_state.ledger.dead+=dead[team].size()
		loose_weapons+=dropped[team]
	_unlock_battle(ENCOUNTER)
	var captured:=field.result=="夺取城内阵地"
	if captured:
		# Holding the court dislodges the garrison. Living opponents stay on the
		# map as a field force on an actual route, keeping their assigned weapons.
		var city: Dictionary=_state.cities.hequ
		var count: int=living[1].size()
		if count>0:
			var remnant:=_army("bei","hequ",count,surviving_gear[1],0)
			_state.armies["hequ_remnant"]=remnant
			city.soldiers-=count
			city.weapons-=surviving_gear[1]
			_march_home(remnant,"grain_road","anping")
		_capture("hequ",_state.armies.relief.owner)
	elif field.result=="成功撤离":
		var relief: Dictionary=_state.armies.relief
		var left: int=relief.soldiers-withdrawing_people
		if left>0:
			var left_gear: int=surviving_gear[0]-withdrawing_gear
			_state.armies["hequ_rearguard"]=_army("sheng","hequ",left,left_gear,0)
			relief.soldiers-=left
			relief.weapons-=left_gear
		_march_home(relief,"river","pingling")
	_state.commander.hp=field.hero.hp
	_state.commander.alive=field.hero.hp>0
	_state.campaign_ended=not _state.commander.alive
	ticket.status="committed"
	var issued := {"battle_id":ENCOUNTER,"outcome":field.result,"ending_seconds":_state.time_seconds,
		"dead_ids":dead,"living_ids":living,"escaped_ids":fled,"dropped_by_kit":loose_by_kit,
		"loose_weapons":loose_weapons,"captured_gate":captured,"commander_alive":_state.commander.alive}
	ticket.receipt=issued.duplicate(true)
	_event("field_settled",{"battle_id":ENCOUNTER,"outcome":field.result,"dead":[dead[0].size(),dead[1].size()]})
	if not audit().is_empty():
		_state=before
		loose_weapons=old_loose
		return {}
	receipt=issued
	return receipt.duplicate(true)

func _march_home(force: Dictionary,route: String,destination: String) -> void:
	var arrival: float=_state.time_seconds+float(ROUTES[route].hours)*3600.0
	force.location=""
	force.march={"route":route,"destination":destination,"arrives_at":ceili(arrival/3600.0),"arrives_at_seconds":arrival}

func own_supply() -> int:
	return _state.armies.relief.food
