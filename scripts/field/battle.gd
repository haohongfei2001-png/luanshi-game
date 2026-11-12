extends RefCounted
## Fixed-step field combat. IDs index a permanent roster including fallen soldiers.
## The camera and rendering layer never participate in a decision or damage roll.
const Arms := preload("res://scripts/field/arms.gd")
const Ground := preload("res://scripts/field/ground.gd")
const OfficerCorps := preload("res://scripts/field/officer_corps.gd")
const Objectives := preload("res://scripts/field/field_objectives.gd")
const CrowdGrid := preload("res://scripts/field/crowd_grid.gd")
const Traffic := preload("res://scripts/field/formation_traffic.gd")
const Profiles := preload("res://scripts/hero_combat_profiles.gd")
const DT := 0.05
const CELL := 6.0
const COLS := 42
const ROWS := 24
const SCALES := [20, 100, 250, 512]
const SEED := 61112
enum State { MARCH, WINDUP, RECOVER, GUARD, STAGGER, ROUT, ESCAPED, DEAD }
enum Mission { PRESS, HOLD, FLANK, ESCORT, INTERCEPT, RESERVE, WITHDRAW }
enum Channel { FLAG, HORN, COURIER, VOICE }
const MISSIONS := ["推进城门", "守住阵地", "侧翼推进", "护送冲车", "截击", "预备队", "撤离"]
const CHANNELS := ["令旗", "号角", "传令兵", "口令"]

class Unit:
	var id := 0
	var team := 0
	var squad := 0
	var kit := 0
	var officer := false
	var hero := false
	var engineer := false
	var ram_station := -1
	var density_cell := 0
	var wall_post := false
	var mounted := false
	var mount_hp := 0.0
	var pos := Vector2.ZERO
	var before := Vector2.ZERO
	var facing := Vector2.RIGHT
	var locked := Vector2.RIGHT
	var separation := Vector2.ZERO
	var station := Vector2.ZERO
	var target := -1
	var state := State.MARCH
	var timer := 0.0
	var duration := 0.0
	var move_slot := 0
	var ammo := 0
	var stock_strike := false
	var charge_speed:=0.0
	var charging_strike:=false
	var hp := 62.0
	var max_hp := 62.0
	var armor := 0.0
	var morale := 1.0
	var fatigue := 0.0
	var flash := 0.0
	var stride := 0.0
	# Transient presentation state. Checkpoints retain their original gait and
	# authoritative movement values; the renderer reconstructs this cycle on load.
	var visual_stride := -1.0
	var visual_run := false
	var facing_before := Vector2.ZERO
	var used_second := false
	var impacts := 0
	var received := 0
	var lost_tick := -1

class Company:
	var team := 0
	var slot := 0
	var shape := 0
	var front := 0
	var officer_id := -1
	var home := Vector2.ZERO
	var aim := Vector2.ZERO
	var mission := Mission.PRESS
	var initial := 0
	var standing := 0
	var serial := 0
	var delivered := 0
	var regrouping := false

class Shot:
	var team := 0
	var source := 0
	var pos := Vector2.ZERO
	var previous := Vector2.ZERO
	var direction := Vector2.RIGHT
	var speed := 0.0
	var remaining := 0.0
	var distance := 0.0
	var power := 0.0
	var pierce := 1
	var last_hit := -1
	var arrow := false
	var over_front := false
	var launch_height := 0.0

class Dispatch:
	var squad := 0
	var serial := 0
	var mission := 0
	var channel := 0
	var pos := Vector2.ZERO
	var age := 0.0
	var delay := 0.0
	var leg := 0 # 0 outward, 1 returning with the officer’s reply, 2 missing
	var due := 0.0
	var refused := false

const FORMATIONS := ["横阵","疏列","纵队"]
const VANGUARDS := ["原有次序","盾枪在前","弓弩在前","骑兵在前"]
var muster_slots: Array[Vector2] = []
var dry_muster:=true
var corps := OfficerCorps.new()
var objectives := Objectives.new()
var traffic_enabled := true
var soft_crowd := true
var keep_gate_file := true
var density := CrowdGrid.new()
var camp_actions: Array=[]
var aftermath_hours := 0
var at_camp := false
var sprinting := false
var breath := 1.0
var winded := false
var buffered_slot := -1
var buffer_ticks := 0
var buffer_aim := Vector2.RIGHT
var buffer_wall := false

var moves := Arms.library()
var stock_blow := Arms.Move.new(Arms.Shape.BASH,1.25,0.72,0.27,0.56,8.0,1)
# Field saves made before quivers existed retain the combat rules they were saved with.
var legacy_missiles := false
var roster: Array[Unit] = []
var companies: Array[Company] = []
var shots: Array[Shot] = []
var orders: Array[Dispatch] = []
var hero: Unit
var rng := RandomNumberGenerator.new()
var side_size := 0 # Player-side count used by the four historical benchmark callers.
var ordinary_counts := PackedInt32Array([0,0])
var command_counts := PackedInt32Array([0,0])
var world_patrol := false
var companies_per_side := 0
var tick := 0
var started := false
var result := ""
var equipment := [0, 0]
var losses := [0, 0]
var escaped := [0, 0]
var hits := [0, 0]
var attacks := 0
var blocked_hits := 0
var arrow_count := 0
var messages_arrived := 0
var messages_lost := 0
var messages_refused := 0
var notice := ""
var gate_hp := 260.0
var ram_hp := 150.0
var ram := Vector2(-9, 1)
var ram_timer := 0.0
var ram_crew := PackedInt32Array([-1,-1,-1,-1])
var reliefs := 0
var capture := 0.0
var hero_move := Vector2.ZERO
var aim := Vector2.RIGHT
var aim_at_wall_post:=false
var locked_at_wall_post:=false
var hero_cds := PackedFloat32Array([0.0,0.0,0.0,0.0])
# Foot, horse and chariot are separate physical assets. The rider can lose either vehicle.
var vehicle := 0
var seat_origin:=true
var parked_heading: Array[Vector2]=[Vector2.RIGHT,Vector2.RIGHT,Vector2.RIGHT]
var vehicle_pos := [Vector2.ZERO, Vector2.ZERO, Vector2.ZERO]
var vehicle_hp := [0.0, 75.0, 115.0]
var riding_speed := 0.0
var riding_heading := Vector2.RIGHT
var grid := PackedInt32Array()
var links := PackedInt32Array()
# Same IDs and order as grid, restricted to one side for target and weapon queries.
var team_grid := PackedInt32Array()
var team_links := PackedInt32Array()
var hostile_min_x:=PackedFloat64Array([INF,INF])
var hostile_max_x:=PackedFloat64Array([-INF,-INF])

func setup(n: int, seed_value: int = SEED, weapon: int = Arms.Kit.SPEAR, on_banks: bool=true,ranked_officers: bool=true,defenders: int=-1) -> void:
	if defenders==-1: defenders=n
	assert(n>0 and defenders>0 and roster.is_empty())
	ordinary_counts=PackedInt32Array([n,defenders])
	command_counts=PackedInt32Array([ceili(n/32.0),ceili(defenders/32.0)])
	side_size = n
	traffic_enabled=ranked_officers
	soft_crowd=ranked_officers
	keep_gate_file=ranked_officers
	objectives.enabled=ranked_officers
	dry_muster=on_banks
	rng.seed = seed_value
	companies_per_side = command_counts[0]
	for team in 2:
		var company_count:=command_counts[team]
		var bands:=mini(5,company_count)
		var sign_x := 1.0 if team == 0 else -1.0
		for c in company_count:
			var company := Company.new()
			company.team = team
			var lane := (float(c % bands) - (bands - 1) * 0.5) * 13.6
			company.home = Vector2(-sign_x * (5.0 + floorf(float(c) / bands) * 7.2), lane)
			# Sortie companies meet the attacker on the outer field. The garrison still
			# physically occupies the walled court when the outer line collapses.
			var garrison := team == 1 and company_count >= 4 and c >= ceili(company_count*0.58)
			if garrison:
				var post := c-ceili(company_count*0.58)
				company.home = Vector2(55.5 + floorf(post/3.0)*8.4, (post%3-1)*12.0)
			company.mission = Mission.PRESS if team == 0 else Mission.HOLD
			if team==0 and dry_muster and company.home.x< -23:
				company.home.x=Ground.RIVER_X-7.3-maxf(0.0,floorf(float(c)/bands)-3.0)*7.2
			company.slot=c
			if team==0: muster_slots.append(company.home)
			company.aim = company.home
			companies.append(company)
			for j in mini(32, ordinary_counts[team] - c * 32):
				var pos := company.home + Vector2(-sign_x * floorf(j / 8.0) * 1.78, (j % 8 - 3.5) * 1.58)
				var u := _add(team, companies.size()-1, pos)
				var file := j % 8
				if j >= 24:
					u.kit = Arms.Kit.BOW if file % 2 == 0 else Arms.Kit.CROSSBOW
				elif j >= 16 and file >= 6:
					u.kit = Arms.Kit.DAO
					u.mounted = true
					u.mount_hp = 48.0
				elif j < 8:
					u.kit = Arms.Kit.SHIELD if file % 3 == 0 else Arms.Kit.SPEAR
				else:
					u.kit = [Arms.Kit.SWORD, Arms.Kit.DAO, Arms.Kit.STAFF, Arms.Kit.GLAIVE][file % 4]
				if garrison and c-ceili(company_count*0.58)<2 and j>=24:
					var sign_z := -1 if c==ceili(company_count*0.58) else 1
					u.pos=Vector2(Ground.WALL_X+2.05+(j%2)*1.1,sign_z*(14.0+floorf((j-24)/2.0)*1.7))
					u.before=u.pos
					u.station=u.pos
					u.wall_post=true
				# A small detachment travels with the ram. Its crew are counted soldiers.
				u.engineer = team == 0 and c == bands / 2 and j >= 12 and j < 16
				if u.engineer:
					u.ram_station=u.id%4
					ram_crew[u.ram_station]=u.id
				if ordinary_counts[team] <= 20 and j >= 16:
					u.kit = Arms.Kit.BOW if file % 2 == 0 else Arms.Kit.CROSSBOW
				u.ammo=Arms.issue(u.kit)
				u.armor = 0.22 if u.kit == Arms.Kit.SHIELD else (0.12 if u.kit == Arms.Kit.GLAIVE else 0.05)
				company.initial += 1
				company.standing += 1
	for i in companies.size():
		var c := companies[i]
		var u := _add(c.team, i, c.home + Vector2(-7.6 if c.team == 0 else 7.6, 1.2))
		u.officer = true
		u.kit = Arms.Kit.GLAIVE
		u.max_hp = 88
		u.hp = u.max_hp
		u.armor = 0.15
		c.officer_id = u.id
	hero = _add(0, 0, Vector2(-10, -3))
	hero.hero = true
	equip_hero(weapon)
	hero.max_hp = Profiles.get_profile(Profiles.EARLY).max_hp
	hero.hp = hero.max_hp
	vehicle_pos[1] = hero.pos + Vector2(-1.8, 0)
	vehicle_pos[2] = hero.pos + Vector2(-2.8, 2.2)
	grid.resize(COLS * ROWS)
	links.resize(roster.size())
	team_grid.resize(2*COLS*ROWS)
	team_links.resize(roster.size())
	corps.setup(self,ranked_officers)
	_rebuild_grid()

func _rank(u: Unit,front: int) -> int:
	match front:
		1: return 0 if u.kit in [Arms.Kit.SHIELD,Arms.Kit.SPEAR] else 1
		2: return 0 if u.kit in [Arms.Kit.BOW,Arms.Kit.CROSSBOW] else 1
		3: return 0 if u.mounted else 1
	return 0

func _place_company(index: int) -> void:
	var c:=companies[index]
	c.home=muster_slots[c.slot]
	c.aim=c.home
	var line: Array[Unit]=[]
	for u in roster:
		if u.team==0 and u.squad==index and not u.officer and not u.hero: line.append(u)
	if c.front!=0:
		line.sort_custom(func(a: Unit,b: Unit):
			var ra:=_rank(a,c.front)
			var rb:=_rank(b,c.front)
			return a.id<b.id if ra==rb else ra<rb)
	var width:=4 if c.shape==2 else 8
	# Fit every shape inside its own deployment cell, including the rear file.
	var spacing:=1.76 if c.shape==1 else (1.14 if c.shape==2 else 1.58)
	var depth:=0.91 if c.shape==2 else 1.78
	for j in line.size():
		var u:=line[j]
		u.station=c.home+Vector2(-floorf(float(j)/width)*depth,(float(j%width)-(width-1)*0.5)*spacing)
		u.pos=u.station
		u.before=u.pos
	var officer:=roster[c.officer_id]
	officer.station=c.home+Vector2(-7.6,1.2)
	officer.pos=officer.station
	officer.before=officer.pos

func deploy_company(index: int,slot: int,shape: int,front: int) -> bool:
	if started or index<0 or index>=companies_per_side or slot<0 or slot>=companies_per_side or shape<0 or shape>=FORMATIONS.size() or front<0 or front>=VANGUARDS.size(): return false
	var chosen:=companies[index]
	for i in companies_per_side:
		if i!=index and companies[i].slot==slot:
			companies[i].slot=chosen.slot
			_place_company(i)
			break
	chosen.slot=slot
	chosen.shape=shape
	chosen.front=front
	_place_company(index)
	_rebuild_grid()
	return true

func muster_manifest() -> Array:
	var out: Array=[]
	for i in companies_per_side:
		var c:=companies[i]
		out.append([c.slot,c.shape,c.front])
	return out

func restore_muster(rows: Variant) -> bool:
	if not rows is Array or rows.size()!=companies_per_side: return false
	var seen: Dictionary={}
	for row in rows:
		if not row is Array or row.size()!=3: return false
		for v in row:
			if not v is int: return false
		if row[0]<0 or row[0]>=companies_per_side or seen.has(row[0]) or row[1]<0 or row[1]>=FORMATIONS.size() or row[2]<0 or row[2]>=VANGUARDS.size(): return false
		seen[row[0]]=true
	for i in companies_per_side:
		var c:=companies[i]
		c.slot=rows[i][0]
		c.shape=rows[i][1]
		c.front=rows[i][2]
		_place_company(i)
	_rebuild_grid()
	return true

func equip_hero(kit: int) -> void:
	if started or kit<0 or kit>=Arms.NAMES.size(): return
	hero.kit=kit
	hero.ammo=Arms.issue(kit)

func _basic(u: Unit) -> Arms.Move:
	if not legacy_missiles and u.ammo==0 and u.kit in [Arms.Kit.BOW,Arms.Kit.CROSSBOW]: return stock_blow
	return moves[u.kit][0]

func _committed_move(u: Unit) -> Arms.Move:
	return stock_blow if u.stock_strike else moves[u.kit][u.move_slot]

func _add(team: int, squad: int, pos: Vector2) -> Unit:
	var u := Unit.new()
	u.id = roster.size()
	u.team = team
	u.squad = squad
	u.pos = pos
	u.before = pos
	u.station = pos
	u.facing = Vector2.RIGHT if team == 0 else Vector2.LEFT
	u.locked = u.facing
	u.morale = rng.randf_range(0.73, 1.0)
	u.stride = rng.randf()
	u.fatigue = rng.randf_range(0.0, 0.35)
	roster.append(u)
	return u

func active(u: Unit) -> bool:
	return u.hp > 0 and u.state != State.ESCAPED

func _cell(p: Vector2) -> Vector2i:
	return Vector2i(clampi(floori((p.x + 124) / CELL), 0, COLS-1), clampi(floori((p.y + 70) / CELL), 0, ROWS-1))

func _rebuild_grid() -> void:
	var west0:=INF
	var west1:=INF
	var east0:=-INF
	var east1:=-INF
	grid.fill(-1)
	team_grid.fill(-1)
	if soft_crowd: density.clear()
	for i in range(roster.size()-1, -1, -1):
		var u := roster[i]
		if active(u):
			if u.team==0:
				west0=minf(west0,u.pos.x)
				east0=maxf(east0,u.pos.x)
			else:
				west1=minf(west1,u.pos.x)
				east1=maxf(east1,u.pos.x)
			var cell := _cell(u.pos)
			var ix := cell.y * COLS + cell.x
			links[i] = grid[ix]
			grid[ix] = i
			var side_ix:=ix+u.team*COLS*ROWS
			team_links[i]=team_grid[side_ix]
			team_grid[side_ix]=i
			if soft_crowd:
				var weight:=2.6 if u.hero and vehicle==2 else (1.65 if u.mounted or (u.hero and vehicle==1) else 1.0)
				u.density_cell=density.register(u.pos,weight,u.pos.x>Ground.WALL_X and Ground.parapet(u.pos)>1.2)
	# Each side looks up its opponent's width, computed from the unclamped positions.
	hostile_min_x[0]=west1
	hostile_max_x[0]=east1
	hostile_min_x[1]=west0
	hostile_max_x[1]=east0

func _assessment(u: Unit) -> void:
	var best := -1
	var reach := 29.0 if (u.ammo>0 or legacy_missiles) and u.kit in [Arms.Kit.BOW, Arms.Kit.CROSSBOW] else 6.8
	var best_sq := reach*reach
	var correction := Vector2.ZERO
	var pos:=u.pos
	# Only immediate neighbours can contribute to contact pressure. Other cells
	# can skip allies entirely; the remaining enemy order and ID ties are unchanged.
	var cell := _cell(pos)
	var close_lo:=_cell(pos-Vector2.ONE)
	var close_hi:=_cell(pos+Vector2.ONE)
	var enemy_offset:=(1-u.team)*COLS*ROWS
	var open := gate_hp <= 0
	var elevated := u.wall_post and Ground.parapet(u.pos)>2.75
	var rings:=ceili(reach/CELL)
	# Files beyond the opponent's frontage cannot yield a weapon target. Adjacent
	# mixed cells still contribute the identical contact forces in ID order.
	if pos.x+reach<hostile_min_x[u.team] or pos.x-reach>hostile_max_x[u.team]:
		rings=1
	for ring in range(rings+1):
		for y in range(maxi(0,cell.y-ring),mini(ROWS-1,cell.y+ring)+1):
			for x in range(maxi(0,cell.x-ring),mini(COLS-1,cell.x+ring)+1):
				if ring>0 and absi(x-cell.x)!=ring and absi(y-cell.y)!=ring: continue
				var id_cell:=y*COLS+x
				var close_cell:=x>=close_lo.x and x<=close_hi.x and y>=close_lo.y and y<=close_hi.y
				var i:=grid[id_cell] if close_cell else team_grid[id_cell+enemy_offset]
				if i<0: continue
				if not close_cell and x>0 and x<COLS-1 and y>0 and y<ROWS-1:
					var left:=x*CELL-124.0
					var near_x:=clampf(pos.x,left,left+CELL)-pos.x
					var top:=y*CELL-70.0
					var near_z:=clampf(pos.y,top,top+CELL)-pos.y
					if near_x*near_x+near_z*near_z>best_sq: continue
				while i!=-1:
					var other := roster[i]
					var d := other.pos-pos
					var sq := d.length_squared()
					if close_cell and i!=u.id and sq<0.96 and sq>0.00001:
						correction-=d*(0.98/sqrt(sq)-1.0)
					if other.team!=u.team and (sq<best_sq or (sq==best_sq and i<best)) and Ground.clear_shot(pos,other.pos,open,elevated or (reach>10 and other.wall_post and Ground.parapet(other.pos)>2.75)):
						best=i
						best_sq=sq
					i=links[i] if close_cell else team_links[i]
		# Lower bound from the unit to any cell not visited yet.
		var dx := minf(u.pos.x+124-(cell.x-ring)*CELL,(cell.x+ring+1)*CELL-124-u.pos.x)
		var dz := minf(u.pos.y+70-(cell.y-ring)*CELL,(cell.y+ring+1)*CELL-70-u.pos.y)
		var edge := minf(dx,dz)
		if edge>0.99 and best_sq<edge*edge: break
	u.target=best
	u.separation=correction.limit_length(1.0)*3.6

func start() -> void:
	if not started:
		started = true
		notice = "军令已发"

func command(squad: int, mission: int, channel: int) -> bool:
	if squad < 0 or squad >= companies_per_side or mission < 0 or mission >= MISSIONS.size() or channel < 0 or channel >= CHANNELS.size() or result != "":
		return false
	var c := companies[squad]
	var officer: Unit = corps.recipient(self,c)
	if not corps.can_command(self,c) and (not started or _observed(officer.pos)):
		notice = "本队军官已失去指挥能力"
		return false
	if not started:
		c.mission = mission
		notice = "已部署 · %02d队 %s" % [squad+1, MISSIONS[mission]]
		return true
	var distance := hero.pos.distance_to(officer.pos)
	if channel == Channel.VOICE and (distance>12.0 or not Ground.clear_shot(hero.pos,officer.pos,gate_hp<=0)):
		notice="军官听不清口令"
		return false
	if channel == Channel.FLAG and (distance > 34 or not Ground.clear_shot(hero.pos, officer.pos, gate_hp <= 0)):
		notice = "军官看不到令旗"
		return false
	if channel == Channel.HORN and distance > 54:
		notice = "军官在号角范围外"
		return false
	var order := Dispatch.new()
	c.serial += 1
	order.serial = c.serial
	order.squad = squad
	order.mission = mission
	order.channel = channel
	order.pos = hero.pos
	order.delay = 0.12+distance/36.0 if channel==Channel.VOICE else 0.24+distance/(50.0 if channel==Channel.HORN else 30.0)
	order.due=maxf(6.0,4.0+distance*2.0/5.0)
	orders.append(order)
	notice = "%s已发 · %02d队" % [CHANNELS[channel], squad+1]
	return true

func _observed(pos: Vector2) -> bool:
	return hero.pos.distance_squared_to(pos)<=144.0 and Ground.clear_shot(hero.pos,pos,gate_hp<=0)

func _deliver(order: Dispatch,c: Company) -> void:
	if order.serial<=c.delivered: return
	c.delivered=order.serial
	order.refused=c.standing*4<=c.initial and order.mission in [Mission.PRESS,Mission.FLANK]
	if order.refused:
		messages_refused+=1
	else:
		c.mission=order.mission
		messages_arrived+=1

func _report_order(order: Dispatch) -> void:
	if order.refused: notice="%02d队回报 · 损失过重，无法推进" % (order.squad+1)
	else: notice="%02d队回报 · %s" % [order.squad+1,MISSIONS[order.mission]]

func _dispatches() -> void:
	for at in range(orders.size()-1,-1,-1):
		var order:=orders[at]
		var c:=companies[order.squad]
		var officer: Unit=corps.recipient(self,c)
		order.age+=DT
		if order.channel!=Channel.COURIER:
			if order.age<order.delay: continue
			if corps.can_command(self,c):
				_deliver(order,c)
				if _observed(officer.pos): _report_order(order)
			else:
				messages_lost+=1
				notice="%02d队未回应" % (order.squad+1)
			orders.remove_at(at)
			continue
		if order.leg==2:
			if order.age<order.due: continue
			notice="%02d队超时未回报" % (order.squad+1)
			orders.remove_at(at)
			continue
		var destination:=hero.pos if order.leg==1 else officer.pos
		var direction:=order.pos.direction_to(Ground.waypoint(order.pos,destination))
		order.pos=Ground.travel(order.pos,direction*7.0*DT,gate_hp<=0)
		if (order.leg==0 and not corps.can_command(self,c)) or not _near(order.pos,1.55,1).is_empty() or order.age>90.0:
			if order.leg==0: messages_lost+=1
			if _observed(order.pos):
				notice="%02d队传令中断" % (order.squad+1)
				orders.remove_at(at)
			else: order.leg=2
			continue
		if order.pos.distance_squared_to(destination)>4: continue
		if order.leg==1:
			_report_order(order)
			orders.remove_at(at)
		else:
			_deliver(order,c)
			order.leg=1

func _objective(c: Company) -> Vector2:
	if not corps.can_command(self,c):
		return c.home
	if c.regrouping:
		return Vector2(43.5,clampf(c.home.y,-16,16)) if c.team==1 else Vector2(-36,Ground.crossing(c.home.y))
	match c.mission:
		Mission.WITHDRAW: return Vector2(-92 if c.team == 0 else 96, c.home.y)
		Mission.ESCORT:
			if objectives.enabled and objectives.task==Objectives.Task.COURT and gate_hp<=0:
				return Ground.COURT+Vector2(-0.8,2.2 if c.slot%2==0 else -2.2)
			return ram
		Mission.FLANK: return Vector2(38, signf(c.home.y + 0.5) * 29) if gate_hp > 0 else Ground.COURT
		Mission.HOLD: return c.home
		Mission.RESERVE: return c.home + Vector2(-9 if c.team == 0 else 9, 0)
		Mission.INTERCEPT: return Vector2(5, c.home.y)
	return Ground.COURT if gate_hp <= 0 else Vector2(Ground.WALL_X - 2, 0)

func mount(id: int) -> bool:
	if result != "" or id < 0 or id > 2 or hero.state in [State.WINDUP, State.STAGGER]:
		return false
	if vehicle != 0:
		if seat_origin:
			if id!=0 and id!=vehicle:
				notice="请先下乘，再登上另一辆车马"
				return false
			parked_heading[vehicle]=riding_heading
			vehicle_pos[vehicle]=hero.pos+(riding_heading*1.83 if vehicle==2 else Vector2.ZERO)
			var side:=riding_heading.orthogonal()*1.05
			var landing:=Ground.travel(hero.pos,side,gate_hp<=0)
			if landing.distance_to(hero.pos)<0.5: landing=Ground.travel(hero.pos,-side,gate_hp<=0)
			hero.pos=landing
			hero.before=landing
		else: vehicle_pos[vehicle] = hero.pos
		vehicle = 0
		riding_speed = 0
		notice = "已下乘"
		return true
	if id == 0 or vehicle_hp[id] <= 0 or hero.pos.distance_to(vehicle_pos[id]) > 4.5:
		notice = "需靠近可用的坐骑或战车"
		return false
	var seat: Vector2=vehicle_pos[id]-(parked_heading[id]*1.83 if seat_origin and id==2 else Vector2.ZERO)
	if seat_origin:
		if Ground.blocked(seat,gate_hp<=0) or not Ground.clear_shot(hero.pos,seat,gate_hp<=0):
			notice="车马在阻隔另一侧"
			return false
		hero.pos=seat
		hero.before=seat
	vehicle = id
	riding_heading = parked_heading[id] if seat_origin else hero.facing
	notice = "已上马" if id == 1 else "已登车"
	return true

func input_state(walk: Vector2, facing: Vector2) -> void:
	hero_move = walk.limit_length()
	if facing.length_squared() > 0.0001:
		aim = facing.normalized()
		aim_at_wall_post=Ground.parapet(hero.pos+facing)>2.75

# Keep the last deliberate press near release. Holding attack never overwrites a skill.
func press_action(slot: int) -> bool:
	if not started or result!="" or slot<0 or slot>3: return false
	if action(slot):
		buffered_slot=-1
		buffer_ticks=0
		return true
	if hero.state in [State.WINDUP,State.RECOVER,State.GUARD,State.STAGGER] and hero_cds[slot]<=0.20 and (slot!=0 or buffered_slot<=0):
		buffered_slot=slot
		buffer_aim=aim
		buffer_wall=aim_at_wall_post
		buffer_ticks=4
	return false

func action(slot: int) -> bool:
	if slot < 0 or slot > 3 or not started or result != "" or hero_cds[slot] > 0 or hero.state != State.MARCH:
		return false
	if slot in [1,2] and not legacy_missiles and hero.ammo==0 and hero.kit in [Arms.Kit.BOW,Arms.Kit.CROSSBOW]:
		notice="弹囊已空，可用普攻近身推击"
		return false
	_begin(hero, slot, aim)
	hero_cds[slot] = 0.12 if slot == 0 else [0.0,3.6,4.5,4.2][slot]
	return true

func _begin(u: Unit, slot: int, direction: Vector2) -> void:
	var move: Arms.Move = _basic(u) if slot==0 else moves[u.kit][slot]
	u.stock_strike=move==stock_blow
	u.charging_strike=u.mounted and u.charge_speed>=4.5 and u.facing.dot(direction)>0.78
	if u.charging_strike: u.charge_speed=0.0
	if u.hero: locked_at_wall_post=aim_at_wall_post
	u.move_slot = slot
	u.locked = direction if direction.length_squared() > 0.1 else u.facing
	u.facing = u.locked
	u.used_second = false
	_set_state(u, State.WINDUP, move.wind)
	attacks += 1

func _set_state(u: Unit, state: int, length: float) -> void:
	u.state = state
	u.timer = length
	u.duration = length

func _near(at: Vector2, radius: float, team: int) -> Array[int]:
	var found: Array[int] = []
	var lo := _cell(at - Vector2.ONE * radius)
	var hi := _cell(at + Vector2.ONE * radius)
	var offset:=team*COLS*ROWS
	var radius_sq:=radius*radius
	for y in range(lo.y, hi.y+1):
		for x in range(lo.x, hi.x+1):
			var i := team_grid[y*COLS+x+offset]
			while i != -1:
				var u := roster[i]
				if active(u) and at.distance_squared_to(u.pos) <= radius_sq:
					found.append(i)
				i = team_links[i]
	return found

func _release(u: Unit, move: Arms.Move,apply_stride: bool=true) -> void:
	if apply_stride and move.step != 0 and not (u.hero and seat_origin and vehicle!=0):
		_move(u, u.locked * move.step)
	if move.shape in [Arms.Shape.PARRY, Arms.Shape.BRACE]:
		_set_state(u, State.GUARD, move.recovery)
		return
	if move.shape in [Arms.Shape.ARROW, Arms.Shape.BOLT, Arms.Shape.FAN, Arms.Shape.PIERCE]:
		var requested := 3 if move.shape == Arms.Shape.FAN else 1
		var count := requested if legacy_missiles else mini(requested,u.ammo)
		if not legacy_missiles: u.ammo-=count
		for j in count:
			var shot := Shot.new()
			shot.team = u.team
			shot.source = u.id
			shot.pos = u.pos + u.locked * 0.45
			shot.previous = shot.pos
			shot.direction = u.locked.rotated((float(j)-(count-1)*0.5)*0.12)
			shot.launch_height=Ground.deck_height(u.pos)
			if seat_origin and (u.mounted or (u.hero and vehicle!=0)): shot.launch_height+=0.91 if u.hero and vehicle==2 else 0.81
			shot.over_front=Ground.parapet(u.pos)>2.75 or (u.hero and locked_at_wall_post) or (u.target>=0 and roster[u.target].wall_post and Ground.parapet(roster[u.target].pos)>2.75)
			shot.arrow = move.shape in [Arms.Shape.ARROW, Arms.Shape.FAN]
			shot.speed = 24.0 if shot.arrow else 37.0
			shot.remaining = move.reach
			shot.power = move.power
			shot.pierce = 2 if move.shape == Arms.Shape.PIERCE else 1
			shots.append(shot)
			arrow_count += 1
	elif move.shape != Arms.Shape.EVADE:
		_melee(u, move)
	if u.state == State.WINDUP:
		_set_state(u, State.RECOVER, move.recovery)

func _melee(u: Unit, move: Arms.Move) -> void:
	var candidates := _near(u.pos, move.reach + 0.35, 1-u.team)
	# Nearest-first, with stable ID ties for equal distances across cell boundaries.
	candidates.sort_custom(func(a: int, b: int) -> bool:
		var da := u.pos.distance_squared_to(roster[a].pos)
		var db := u.pos.distance_squared_to(roster[b].pos)
		return a < b if da == db else da < db)
	var count := 0
	for id in candidates:
		var v := roster[id]
		var offset := v.pos - u.pos
		var along := u.locked.dot(offset)
		if move.shape == Arms.Shape.LINE or (move.shape == Arms.Shape.DOUBLE and u.kit == Arms.Kit.SPEAR):
			if along < 0 or along > move.reach or absf(u.locked.cross(offset)) > move.width + 0.22:
				continue
		elif along < offset.length() * cos(move.width):
			continue
		if Ground.clear_shot(u.pos, v.pos, gate_hp <= 0):
			var charging:=u.mounted and u.charging_strike
			u.charging_strike=false
			if charging and v.kit==Arms.Kit.SPEAR and v.state in [State.GUARD,State.WINDUP] and v.facing.dot(v.pos.direction_to(u.pos))>0.4:
				_hurt(v,u,23.0,v.pos)
				if active(u): _set_state(u,State.STAGGER,0.46)
				break
			_hurt(u,v,move.power*(1.48 if charging else 1.0),u.pos)
			if active(v) and move.shape == Arms.Shape.BASH:
				_move(v, u.locked * 0.88)
				_set_state(v, State.STAGGER, 0.30)
			count += 1
			if count >= move.limit:
				break
	var struck_gate := false
	if u.team == 0 and gate_hp > 0:
		if traffic_enabled:
			struck_gate = Traffic.hits_gate(u.pos, u.locked, move.reach, move.width, move.shape == Arms.Shape.LINE or (move.shape == Arms.Shape.DOUBLE and u.kit == Arms.Kit.SPEAR))
		else:
			struck_gate = u.pos.distance_to(Ground.GATE) <= move.reach + 1.0 and u.locked.x > 0.4
	if struck_gate:
		gate_hp = maxf(0, gate_hp - move.power * (0.20 if u.engineer else 0.075))
	if u.team == 1 and ram_hp > 0 and u.pos.distance_to(ram) < move.reach + 0.5 and u.locked.dot(u.pos.direction_to(ram)) > 0.45:
		ram_hp = maxf(0, ram_hp - move.power * 0.16)

func _hurt(source: Unit, target: Unit, power: float, from: Vector2) -> void:
	if not active(target):
		return
	var damage := power * rng.randf_range(0.89,1.09) * (1.0-target.armor)
	var frontal := target.facing.dot(target.pos.direction_to(from)) > 0.18
	if target.state == State.GUARD and frontal:
		damage *= 0.22 if target.kit == Arms.Kit.SHIELD else 0.46
		blocked_hits += 1
		if target.move_slot == 3 and moves[target.kit][3].shape == Arms.Shape.PARRY and active(source) and source.pos.distance_to(target.pos) < 3.4 and target.timer > target.duration * 0.5:
			_set_state(source, State.STAGGER, 0.27)
	if target.hero and vehicle != 0:
		vehicle_hp[vehicle] = maxf(0.0, vehicle_hp[vehicle] - damage * 0.45)
		if vehicle_hp[vehicle] <= 0:
			vehicle_pos[vehicle] = target.pos
			vehicle = 0
			riding_speed = 0
	elif target.mounted:
		target.mount_hp = maxf(0, target.mount_hp - damage * 0.55)
		target.mounted = target.mount_hp > 0
	target.hp = maxf(0, target.hp - damage)
	target.flash = 0.22
	target.morale = maxf(0, target.morale - damage * 0.005)
	target.received += 1
	source.impacts += 1
	hits[source.team] += 1
	if target.hp <= 0:
		_set_state(target, State.DEAD, 0.70)
		target.lost_tick = tick
		if not target.officer and not target.hero:
			losses[target.team] += 1
			equipment[target.team] += 1
			companies[target.squad].standing -= 1
	elif not target.hero and not target.officer and target.state != State.ROUT:
		var c := companies[target.squad]
		var cohesion := float(c.standing) / c.initial
		if target.morale + cohesion * 0.30 < 0.71 or (not corps.can_command(self,c) and target.hp < target.max_hp * 0.50):
			_set_state(target, State.ROUT, 0)
		elif damage > target.max_hp * 0.28 and target.state != State.GUARD:
			_set_state(target, State.STAGGER, 0.17)
	if source.officer or target.officer:
		corps.after_hit(self,source,target)

func _projectiles() -> void:
	for at in range(shots.size()-1,-1,-1):
		var s := shots[at]
		var step := minf(s.remaining, s.speed * DT)
		var next := s.pos + s.direction * step
		var struck := _near((s.pos+next)*0.5, step*0.5+0.60, 1-s.team)
		struck.sort_custom(func(a: int,b: int) -> bool: return s.direction.dot(roster[a].pos) < s.direction.dot(roster[b].pos))
		for id in struck:
			if id == s.last_hit:
				continue
			var v := roster[id]
			var closest := Geometry2D.get_closest_point_to_segment(v.pos, s.pos, next)
			if closest.distance_squared_to(v.pos)>0.36: continue
			var raised_target:=Ground.parapet(v.pos)>2.75
			var launch:=s.pos-s.direction*s.distance
			if s.over_front and s.launch_height<2.75 and not raised_target and not Ground.clear_shot(launch,v.pos,gate_hp<=0):
				continue
			if Ground.clear_shot(s.pos,closest,gate_hp<=0,s.over_front):
				_hurt(roster[s.source], v, s.power, s.pos)
				s.pierce -= 1
				s.last_hit = id
				if s.pierce == 0:
					break
		s.remaining -= step
		s.distance += step
		s.previous = s.pos
		s.pos = next
		if s.pierce == 0 or s.remaining <= 0.0001 or not Ground.clear_shot(s.previous, next, gate_hp <= 0, s.over_front):
			shots.remove_at(at)

func _move(u: Unit, offset: Vector2) -> void:
	if traffic_enabled and ram_hp>0: offset=Traffic.ram_motion(u.pos,offset,ram,u.id)
	u.pos = Ground.travel(u.pos, offset, gate_hp <= 0)

func _player_walk() -> void:
	var walk := hero_move
	var start_pos:=hero.pos
	var start_heading:=riding_heading
	var speed := 4.2
	var run:=sprinting and not winded and vehicle==0 and walk.length_squared()>0.01 and hero.state==State.MARCH
	if run:
		speed=6.65
		breath=maxf(0,breath-DT*0.21)
		winded=breath<=0.01
	else:
		breath=minf(1,breath+DT*0.14)
		if breath>=0.30: winded=false
	if vehicle != 0:
		var top: float=(10.5 if vehicle==1 else 8.2) if sprinting and seat_origin else (8.7 if vehicle==1 else 7.0)
		var target_speed := top*walk.length()
		riding_speed = move_toward(riding_speed, target_speed, DT * (5.5 if vehicle == 1 else 3.5))
		if walk.length_squared() > 0.01:
			var turn: float=(2.8 if vehicle==1 else 1.4)*lerpf(1.0,0.74,riding_speed/top) if seat_origin else (2.8 if vehicle==1 else 1.4)
			riding_heading = Vector2.from_angle(rotate_toward(riding_heading.angle(),walk.angle(),DT*turn))
		walk = riding_heading
		speed = riding_speed
	if hero.state in [State.WINDUP, State.GUARD]:
		speed *= 0.45
	if hero.state != State.STAGGER:
		_move(hero, walk * speed * DT * Ground.pace(hero.pos,vehicle != 0))
	if vehicle != 0:
		if vehicle==2 and seat_origin and (Ground.blocked(hero.pos+riding_heading*1.83,gate_hp<=0) or not Ground.clear_shot(hero.pos,hero.pos+riding_heading*1.83,gate_hp<=0)):
			hero.pos=start_pos
			riding_heading=start_heading
		vehicle_pos[vehicle] = hero.pos+(riding_heading*1.83 if vehicle==2 and seat_origin else Vector2.ZERO)
		if seat_origin and speed>2 and hero.pos.distance_squared_to(start_pos)<0.0004: riding_speed=minf(riding_speed,0.5)
		if riding_speed > 5.5 and tick % 9 == 0:
			var front: Vector2 = vehicle_pos[vehicle] + riding_heading * 1.1
			for id in _near(front, 1.2, 1):
				var v := roster[id]
				if v.kit == Arms.Kit.SPEAR and v.state in [State.GUARD,State.WINDUP] and v.facing.dot(-riding_heading) > 0.3:
					_hurt(v, hero, 21, v.pos)
					riding_speed = 0.5
					break
				_hurt(hero, v, 19 if vehicle == 1 else 28, hero.pos)
				riding_speed *= 0.76
				break
	if hero.state == State.MARCH:
		hero.facing = aim

func _soldier(u: Unit) -> void:
	if corps.act(self,u): return
	var c := companies[u.squad]
	var fleeing := u.state == State.ROUT
	var withdrawing := fleeing or c.mission == Mission.WITHDRAW
	if fleeing:
		# Routed soldiers no longer run target assessment. Release the old contact offset.
		u.separation = u.separation.move_toward(Vector2.ZERO, DT * 8.0)
	var goal := c.aim + (u.station - c.home) * 0.70
	var gate_face := Traffic.gate_face(u.pos) if traffic_enabled else Ground.GATE
	var at_post := u.wall_post and c.mission==Mission.HOLD and not c.regrouping
	if at_post: goal=u.station
	var on_ram:=u.ram_station>=0 if traffic_enabled else u.engineer
	var escort_after_breach:=objectives.enabled and objectives.task==Objectives.Task.ESCORT and gate_hp<=0 and ram.distance_squared_to(Ground.GATE)>9.0
	if on_ram and ram_hp > 0 and (gate_hp > 0 or escort_after_breach):
		goal = ram + Vector2(-0.75, (u.id % 4 - 1.5)*0.75)
	if traffic_enabled and u.team==0 and not withdrawing and not at_post and not c.regrouping and ram_hp>0 and (gate_hp>0 or escort_after_breach):
		if on_ram: goal=Traffic.crew_station(ram,u.ram_station)
		elif c.mission==Mission.ESCORT: goal=Traffic.escort_station(ram,c.slot,u.station-c.home)
		elif c.mission==Mission.PRESS and c.aim.x>=Ground.WALL_X-2.1: goal=Traffic.gate_station(c.slot,companies_per_side,c.home,u.station-c.home)
	if withdrawing:
		goal = Vector2(-98.0 if u.team == 0 else 100.0, signf(u.pos.y)*32)
		if u.pos.distance_to(goal) < 3:
			_set_state(u, State.ESCAPED, 0.0)
			if not u.officer:
				escaped[u.team] += 1
				c.standing -= 1
			return
	else:
		var v: Unit = roster[u.target] if u.target >= 0 else null
		var chase := 34.0
		if c.mission in [Mission.HOLD,Mission.RESERVE]:
			chase = 9.0 if c.mission == Mission.HOLD else 5.0
		var protecting_ram := on_ram and ram_hp>0 and (gate_hp>0 or escort_after_breach) and c.mission!=Mission.WITHDRAW
		var may_engage := v!=null and active(v) and (not protecting_ram or v.pos.distance_to(ram)<4.8)
		if may_engage and u.team==0 and objectives.garrison_retiring and (v.state==State.ROUT or companies[v.squad].mission==Mission.WITHDRAW):
			may_engage=u.pos.distance_squared_to(v.pos)<6.25
		if may_engage and (v.pos.distance_to(c.aim) <= chase or u.pos.distance_to(v.pos) < 8 or (c.mission == Mission.PRESS and not c.regrouping) or at_post):
			var distance := u.pos.distance_to(v.pos)
			var move := _basic(u)
			goal = u.station if at_post else v.pos
			if distance <= move.reach and u.fatigue <= 0:
				u.facing = u.pos.direction_to(v.pos)
				if distance < 3.4 and u.kit in [Arms.Kit.SHIELD, Arms.Kit.SPEAR] and v.state == State.WINDUP and (tick + u.id) % 4 <= 1:
					_set_state(u, State.GUARD, 0.32)
					u.fatigue = 0.49
				else:
					_begin(u, 0, u.facing)
					u.fatigue = rng.randf_range(0.15,0.39)
				return
			if distance <= move.reach * 0.90:
				goal = u.pos
		elif u.team == 0 and gate_hp > 0 and u.fatigue <= 0 and u.pos.distance_to(gate_face) < (minf(3.9, _basic(u).reach + 0.20) if traffic_enabled else 3.9):
			_begin(u, 0, u.pos.direction_to(gate_face))
			u.fatigue = 0.6
			return
	var next: Vector2
	if withdrawing:
		next=Ground.retreat_waypoint(u.pos,goal,gate_hp<=0)
	elif traffic_enabled and not at_post:
		next=Traffic.waypoint(u.pos,goal,u.station.y-c.home.y,u.id,gate_hp<=0,ram_hp>0 and ram.x>Ground.WALL_X-6.0,keep_gate_file)
	else:
		next=Ground.waypoint(u.pos,goal)
	if traffic_enabled and ram_hp>0 and not at_post:
		next=Traffic.around_ram(u.pos,next,ram,u.id,gate_hp<=0)
	var dist := u.pos.distance_to(next)
	var speed := 5.8 if u.mounted else (4.1 if fleeing else 2.85)
	var vel := u.pos.direction_to(next) * minf(speed * Ground.pace(u.pos,u.mounted),dist / DT)
	var old_heading:=u.facing
	if vel.length_squared() > 0.08:
		u.facing = vel.normalized()
	var old_pos:=u.pos
	_move(u,(vel+u.separation)*DT)
	if u.mounted:
		var actual: float=u.pos.distance_to(old_pos)/DT
		var aligned:=old_heading.dot(u.facing)>0.87 and not fleeing
		u.charge_speed=move_toward(u.charge_speed,actual if aligned else 0.0,DT*(5.0 if aligned else 12.0))

func _state_step(u: Unit) -> void:
	var prior:=u.timer
	u.timer = maxf(0, u.timer-DT)
	match u.state:
		State.WINDUP:
			var move:=_committed_move(u)
			var footwork:=objectives.enabled and u.hero and vehicle==0 and move.step!=0.0
			if footwork:
				var before:=smoothstep(0.12,1.0,1.0-prior/u.duration)
				var now:=smoothstep(0.12,1.0,1.0-u.timer/u.duration)
				_move(u,u.locked*(now-before)*move.step)
			if u.timer <= 0:
				_release(u,move,not footwork)
		State.RECOVER:
			var move := _committed_move(u)
			if move.shape == Arms.Shape.DOUBLE and not u.used_second and u.timer <= move.recovery * 0.55:
				u.used_second = true
				_melee(u, move)
			if u.timer <= 0 and u.state == State.RECOVER:
				u.state = State.MARCH
		State.GUARD, State.STAGGER:
			if u.timer <= 0:
				u.state = State.MARCH
		State.MARCH, State.ROUT:
			if not u.hero:
				_soldier(u)

func _rotate_ram_crew() -> void:
	# A signal can only reach nearby escorts. A replacement walks from his
	# current position and keeps his original identity, weapon, HP and company.
	if not traffic_enabled or ram_hp<=0 or (gate_hp<=0 and objectives.task!=Objectives.Task.ESCORT): return
	var nearby: Array[int]=[]
	for slot in ram_crew.size():
		var old: Unit=roster[ram_crew[slot]] if ram_crew[slot]>=0 else null
		if old!=null and active(old) and old.state!=State.ROUT and companies[old.squad].mission!=Mission.WITHDRAW and old.pos.distance_squared_to(ram)<81.0: continue
		if nearby.is_empty(): nearby=_near(ram,9.0,0)
		var best: Unit=null
		var distance:=INF
		for id in nearby:
			var u:=roster[id]
			if u.ram_station>=0 or u.hero or u.officer or u.mounted or u.state==State.ROUT or u.kit in [Arms.Kit.BOW,Arms.Kit.CROSSBOW]: continue
			if companies[u.squad].mission!=Mission.ESCORT or not corps.title_of(self,u).is_empty(): continue
			var d:=u.pos.distance_squared_to(Traffic.crew_station(ram,slot))
			if d<distance or (is_equal_approx(d,distance) and best!=null and id<best.id):
				distance=d
				best=u
		if best:
			if old!=null: old.ram_station=-1
			best.ram_station=slot
			ram_crew[slot]=best.id
			reliefs+=1

func _siege() -> void:
	if ram_hp > 0 and tick % 4 == 0 and (gate_hp>0 or (objectives.enabled and objectives.task==Objectives.Task.ESCORT)):
		var crew := 0
		for id in _near(ram,4.8,0):
			if (roster[id].ram_station>=0 if traffic_enabled else roster[id].engineer) and roster[id].state != State.ROUT:
				crew += 1
		if crew >= 2:
			if ram.distance_to(Ground.GATE) < 3.3:
				ram_timer -= DT*4
				if ram_timer <= 0 and gate_hp>0:
					objectives.strokes+=1
					gate_hp = maxf(0,gate_hp - 14.0 - crew*1.5)
					ram_timer = 1.7
			else:
				ram = Ground.travel(ram,ram.direction_to(Ground.GATE)*DT*4*1.5,false)
	if tick % 5 == 0:
		var friendly := _court_holders(0)
		var enemy := _court_holders(1)
		if gate_hp <= 0 and friendly > enemy:
			capture += DT*5
		else:
			capture = maxf(0,capture-DT*3)

func _court_holders(team: int) -> int:
	var contacts:=_near(Ground.COURT,7.0,team)
	if not objectives.enabled: return contacts.size()
	var standing:=0
	for id in contacts:
		var u:=roster[id]
		if u.state!=State.ROUT and not corps.is_wounded(id): standing+=1
	return standing

func step() -> void:
	if not started or result != "":
		return
	tick += 1
	for i in hero_cds.size():
		hero_cds[i] = maxf(0, hero_cds[i]-DT)
	if buffer_ticks>0:
		if hero.state==State.MARCH:
			var current:=aim
			var wall:=aim_at_wall_post
			aim=buffer_aim
			aim_at_wall_post=buffer_wall
			if action(buffered_slot): buffer_ticks=1
			aim=current
			aim_at_wall_post=wall
		buffer_ticks-=1
		if buffer_ticks==0: buffered_slot=-1
	_rebuild_grid()
	corps.advance(self)
	if tick%20==0: _rotate_ram_crew()
	_dispatches()
	if tick == 1 or tick % 8 == 0:
		for c in companies:
			c.regrouping = corps.can_command(self,c) and c.standing*2 < c.initial and c.standing>0 and c.mission in [Mission.PRESS,Mission.HOLD]
			if objectives.garrison_retiring and c.team==0 and c.mission in [Mission.PRESS,Mission.FLANK]: c.regrouping=false
			c.aim = corps.guide_company(self,c,_objective(c))
	for u in roster:
		u.before = u.pos
		u.facing_before = u.facing
		if active(u) and not u.hero and u.state == State.MARCH:
			var interval := 8 if u.kit in [Arms.Kit.BOW, Arms.Kit.CROSSBOW] else 5
			if (tick+u.id)%interval==0 or (u.target>=0 and not active(roster[u.target])):
				_assessment(u)
	# Alternate initiative for contacts that share a tick.
	for i in roster.size():
		var u := roster[i if tick % 2 == 0 else roster.size()-1-i]
		if u.mounted and u.state!=State.MARCH: u.charge_speed=move_toward(u.charge_speed,0.0,DT*7.0)
		u.flash = maxf(0,u.flash-DT)
		u.fatigue = maxf(0,u.fatigue-DT)
		if not active(u):
			u.timer = maxf(0,u.timer-DT)
			continue
		if u.hero:
			_player_walk()
		_state_step(u)
		if soft_crowd and not u.hero and not u.wall_post and (tick+u.id)%4==0 and density.mass[u.density_cell]>=7.0 and active(u):
			var relief:=density.ease(u.pos,u.density_cell,u.id)
			# One short, terrain-checked adjustment at 5 Hz. This leaves attacks,
			# formation slots and the player's ability to stand close intact.
			if relief!=Vector2.ZERO: _move(u,relief*0.24)
		var travel:=u.pos.distance_to(u.before)
		if u.visual_stride<0: u.visual_stride=u.stride
		u.visual_run=travel>DT*(3.0 if u.visual_run else 3.55)
		u.visual_stride=fposmod(u.visual_stride+travel*(.42 if u.visual_run else .68),1.)
		u.stride = fposmod(u.stride + travel * 0.68, 1.0)
	_projectiles()
	_siege()
	if objectives.enabled:
		result=objectives.resolve(self)
		return
	_resolve_historical()

# Version 1–3 checkpoints replay their original adjudication from their saved tick.
func _resolve_historical() -> void:
	if hero.hp <= 0:
		result = "主将阵亡"
	elif capture >= 6.0:
		result = "夺取城内阵地"
	elif hero.pos.x < -85 and companies[hero.squad].mission == Mission.WITHDRAW and escaped[0] > 0:
		result = "成功撤离"
	elif losses[1]+escaped[1] >= ceili(side_size*0.72):
		result = "守军已失去战斗能力"
	elif losses[0]+escaped[0] >= ceili(side_size*0.72):
		result = "攻势瓦解"
	elif tick%20==0 and losses[1]+escaped[1]+routed(1)>=ceili(side_size*0.72) and routed(1)+escaped[1]>=ceili(side_size*0.20):
		result = "守军溃退"
	elif tick*DT >= 1500:
		result = "守城成功"

func routed(team: int) -> int:
	var count := 0
	for u in roster:
		if u.team==team and not u.officer and not u.hero and u.state==State.ROUT: count+=1
	return count

func report() -> Dictionary:
	return {"seed":rng.seed,"soldiers_per_side":side_size if ordinary_counts[0]==ordinary_counts[1] else null,"ordinary_rosters":[ordinary_counts[0],ordinary_counts[1]],"officers":companies.size(),
		"tick":tick,"result":result,"hits":hits.duplicate(),"attacks":attacks,
		"blocked_hits":blocked_hits,"projectiles":arrow_count,"dead":losses.duplicate(),
		"escaped":escaped.duplicate(),"routing":[routed(0),routed(1)],"dropped_weapons":equipment.duplicate(),
		"gate_hp":gate_hp,"ram_hp":ram_hp,"capture_sec":capture,"mission":Objectives.TITLES[objectives.task],"ram_strokes":objectives.strokes,"crew_replacements":reliefs,"decision":objectives.decision,"officer_corps":corps.summary(self),
		"orders_delivered":messages_arrived,"orders_lost":messages_lost,"orders_refused":messages_refused,"hero_hp":hero.hp}
