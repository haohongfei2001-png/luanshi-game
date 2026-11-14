extends RefCounted
## All planar coordinates are (x,z). Geometry and simulated movement share these landmarks.
const LIMIT := Vector2(118, 64)
const RIVER_X := -32.0
const CROSSINGS := [-35.0, 0.0, 35.0]
const WALL_X := 48.0
const BACK_X := 89.0
const WALL_Z := 23.0
const GATE_HALF := 4.0
const POSTERN_HALF := 1.65
# The outer moat follows the fort rather than the open-field river.
const MOAT_X := 24.0
const MOAT_BANK := 5.85
const MOAT_WATER := 4.10
const MOAT_DECK := 3.70
const MOAT_END := 25.5
const RIVER_BED_DEPTH := 3.8
const MOAT_BED_DEPTH := 3.4
const BATTLE_WATER_LEVEL := -1.48
# Authored outcrop centres are shared by the visible banks and their footprint.
const BANK_OUTCROPS: Array[Vector3] = [
	Vector3(1.,-6.2,2.7),Vector3(-1.,-8.8,3.4),Vector3(1.,-10.5,3.6),
	Vector3(-1.,-14.,4.0),Vector3(1.,-16.,3.4),Vector3(-1.,-21.,3.5),Vector3(1.,-22.5,3.0),
	Vector3(1.,6.5,3.0),Vector3(-1.,7.8,3.6),Vector3(1.,11.,3.8),
	Vector3(-1.,13.5,3.8),Vector3(1.,16.3,3.4),Vector3(-1.,19.,3.6),Vector3(1.,22.,3.0)]
const RIVER_OUTCROPS: Array[Vector3] = [
	Vector3(1.,-55.,4.3),Vector3(-1.,-46.,4.2),Vector3(-1.,-29.,3.1),
	Vector3(1.,28.,3.4),Vector3(-1.,43.,4.0),Vector3(1.,52.,3.6),Vector3(-1.,61.,4.4)]
const BRIDGE_VIEW := Vector2(34.2,1.0)
const GATE := Vector2(WALL_X, 0)
const COURT := Vector2(66, 0)
const CAMP := Vector2(-83, 0)
const GROVE := Vector2(-2, 37)
const RIDGE := Vector2(9, -36)
const RIDGE_RADII := Vector2(34, 16)
const EAST_HILL := Vector2(77, 43)
const EAST_RADII := Vector2(30, 13)

static func height(p: Vector2,bridgehead:bool=false) -> float:
	if not bridgehead:
		# Existing open-field saves retain their original terrain and routes.
		var legacy_slope := (p-RIDGE)/RIDGE_RADII
		var legacy_hill := maxf(0.0,1.0-legacy_slope.length_squared())
		var legacy_east := (p-EAST_HILL)/EAST_RADII
		var legacy_bank := clampf((absf(p.x-RIVER_X)-3.9)/2.4,0.0,1.0)
		return 3.9*legacy_hill*legacy_hill+1.8*pow(maxf(0.0,1.0-legacy_east.length_squared()),2)-(1.0-legacy_bank)*.92
	var slope := (p - RIDGE) / RIDGE_RADII
	var hill := maxf(0.0, 1.0 - slope.length_squared())
	var east := (p - EAST_HILL) / EAST_RADII
	var bank := smoothstep(3.9,6.8,absf(p.x-river_center(p.y))-river_shore_variation(p.y))
	var western_ridge:=(p-Vector2(-86.,-48.))/Vector2(46.,17.)
	var northern_ridge:=(p-Vector2(-4.,58.))/Vector2(29.,11.)
	var eastern_ridge:=(p-Vector2(112.,-45.))/Vector2(25.,17.)
	var relief:=4.8*pow(maxf(0.,1.-western_ridge.length_squared()),2)+3.6*pow(maxf(0.,1.-northern_ridge.length_squared()),2)+5.4*pow(maxf(0.,1.-eastern_ridge.length_squared()),2)
	relief*=smoothstep(6.3,14.,absf(p.x-RIVER_X))
	return 3.9 * hill * hill + 1.8 * pow(maxf(0.0, 1.0 - east.length_squared()), 2) + relief + bridgehead_relief(p) - (1.0 - bank) * RIVER_BED_DEPTH

static func bridgehead_relief(p:Vector2) -> float:
	# Shared, actual actor/terrain height. Keep the original bridge abutments,
	# gate sill and wall foundations fixed; shape the land between them.
	var approach:=smoothstep(29.8,33.2,p.x)*(1.-smoothstep(42.5,46.,p.x))
	var road:=.58*approach*(1.-smoothstep(3.2,6.6,absf(p.y)))
	var north:=(p-Vector2(35.,-11.8))/Vector2(10.3,8.8)
	var south:=(p-Vector2(36.8,14.2))/Vector2(10.5,10.0)
	var shoulders:=2.15*pow(maxf(0.,1.-north.length_squared()),2)
	shoulders+=1.72*pow(maxf(0.,1.-south.length_squared()),2)
	shoulders*=smoothstep(29.8,35.,p.x)*(1.-smoothstep(40.,46.,p.x))
	# Broad valley benches break the formerly empty plain. Their feet feather
	# into the existing road and river clearances, not isolated cone mounds.
	var west:=(p-Vector2(-4.,-23.))/Vector2(24.,18.)
	var lower:=(p-Vector2(-9.,24.))/Vector2(19.,17.)
	var benches:=2.6*pow(maxf(0.,1.-west.length_squared()),2)
	benches+=1.9*pow(maxf(0.,1.-lower.length_squared()),2)
	var northern:=(p-Vector2(41.,-45.))/Vector2(31.,19.)
	benches+=5.2*pow(maxf(0.,1.-northern.length_squared()),2)
	return road+shoulders+benches

static func river_center(z: float) -> float:
	var approach:=smoothstep(4.2,12.,absf(z-crossing(z)))
	return RIVER_X+approach*(1.10*sin(z*.083)+.45*sin(z*.173+.7))

static func river_shore_variation(z: float) -> float:
	return smoothstep(4.2,9.,absf(z-crossing(z)))*(.44*sin(z*.63)+.22*sin(z*1.27+.8))

static func crossing(z: float) -> float:
	var best := 0.0
	for v: float in CROSSINGS:
		if absf(z - v) < absf(z - best):
			best = v
	return best

static func parapet(p: Vector2) -> float:
	var z := absf(p.y)
	if p.x < WALL_X+1.4 or p.x > WALL_X+4.6 or z < 5.5 or z > WALL_Z-1.2: return 0.0
	return clampf((z-5.5)*0.43,0.0,3.25)

static func moat_depth(p: Vector2) -> float:
	var edge:=smoothstep(MOAT_DECK+1.,MOAT_DECK+4.,absf(p.y))*(.48*sin(p.y*.71)+.25*sin(p.y*1.33))
	return (1.0-smoothstep(2.7,MOAT_BANK+edge*.5,absf(p.x-MOAT_X))) * (1.0-smoothstep(MOAT_END-2.2,MOAT_END+1.5,absf(p.y)))

static func moat_blocks(p: Vector2) -> bool:
	if absf(p.y)<=MOAT_DECK: return false
	return moat_depth(p)>.43 or bank_outcrop_blocks(p,MOAT_X,true)

static func bank_outcrop_blocks(p:Vector2,channel:float,moat:bool) -> bool:
	if absf(p.x-channel)>8.: return false
	for station:Vector3 in BANK_OUTCROPS:
		var x:=channel if moat else river_center(station.y)
		var centre:=Vector2(x+station.x*(3.9 if moat else 4.8),station.y)
		if p.distance_squared_to(centre)<pow(station.z*.53,2): return true
	if not moat:
		for station:Vector3 in RIVER_OUTCROPS:
			var centre:=Vector2(river_center(station.y)+station.x*4.8,station.y)
			if p.distance_squared_to(centre)<pow(station.z*.53,2): return true
	return false

# At the bridgehead a change from a column to a line can put the outside
# files into the moat. Keep their frontage and dress them back onto their bank.
static func muster_ground(station: Vector2,company_x: float) -> Vector2:
	if moat_blocks(station):
		station.x=MOAT_X+signf(company_x-MOAT_X)*(MOAT_BANK+.44)
	return station

static func restore_bank_position(p:Vector2,bridgehead:bool) -> Vector2:
	# Revision-one saves may place a living actor inside the new bank outcrops.
	# Reproject only those positions, keeping their side of the crossing.
	var restored:=p
	if bridgehead and moat_blocks(p):
		restored.x=MOAT_X+(-1. if p.x<MOAT_X else 1.)*(MOAT_BANK+.6)
	elif bridgehead and absf(p.y-crossing(p.y))>3.8 and absf(p.x-RIVER_X)<9. and blocked(p,true,true):
		var centre:=river_center(p.y)
		restored.x=centre+(-1. if p.x<centre else 1.)*8.5
	return restored

static func deck_height(p: Vector2, bridgehead: bool=false) -> float:
	if bridgehead and absf(p.x-MOAT_X)<5.95 and absf(p.y)<=MOAT_DECK+.18: return .13
	var ledge := parapet(p)
	if ledge>0: return ledge
	if absf(p.x - RIVER_X) < 6.6 and absf(p.y - crossing(p.y)) < 3.95:
		return 0.13
	return height(p,bridgehead)-(MOAT_BED_DEPTH*moat_depth(p) if bridgehead else 0.0)

static func unit_point(p: Vector2, bridgehead: bool=false) -> Vector3:
	return Vector3(p.x, deck_height(p,bridgehead), p.y)

static func pace(p: Vector2, mounted: bool, bridgehead: bool=false) -> float:
	if bridgehead and absf(p.x-MOAT_X)<5.9 and absf(p.y)<=MOAT_DECK: return .83
	if p.distance_squared_to(GROVE) < 13.0 * 13.0:
		return 0.54 if mounted else 0.82
	if absf(p.x - RIVER_X) < 6.6:
		return 0.72
	# The central approach lies between the extents of both hills. All land here is level.
	if p.y >= RIDGE.y + RIDGE_RADII.y and p.y <= EAST_HILL.y - EAST_RADII.y:
		return 1.0
	return 0.87 if height(p,bridgehead) > 1.2 else 1.0

static func blocked(p: Vector2, open: bool, bridgehead: bool=false) -> bool:
	if bridgehead and moat_blocks(p): return true
	var river_blocked:=absf(p.x-RIVER_X)<4.8
	if bridgehead:
		river_blocked=absf(p.x-river_center(p.y))<5.65+river_shore_variation(p.y) or bank_outcrop_blocks(p,RIVER_X,false)
	if river_blocked and absf(p.y-crossing(p.y))>3.8:return true
	if absf(p.x - WALL_X) < 1.4 and absf(p.y) <= WALL_Z + 1.0:
		return not (open and absf(p.y) < GATE_HALF - 0.3)
	if absf(p.x - BACK_X) < 1.2 and absf(p.y) <= WALL_Z + 1.0:
		return absf(p.y) >= POSTERN_HALF
	return p.x >= WALL_X and p.x <= BACK_X and absf(absf(p.y) - WALL_Z) < 1.2

static func can_step(p: Vector2, q: Vector2, open: bool, bridgehead: bool=false) -> bool:
	if blocked(q,open,bridgehead): return false
	if maxf(p.x,q.x)<WALL_X or minf(p.x,q.x)>WALL_X+5.0: return true
	return absf(parapet(q)-parapet(p))<0.56

static func travel(p: Vector2, offset: Vector2, open: bool, bridgehead: bool=false) -> Vector2:
	var dest := (p + offset).clamp(-LIMIT, LIMIT)
	if can_step(p,dest,open,bridgehead):
		return dest
	var slide := Vector2(dest.x, p.y)
	if can_step(p,slide,open,bridgehead):
		return slide
	slide = Vector2(p.x, dest.y)
	return slide if can_step(p,slide,open,bridgehead) else p

static func needs_moat_crossing(p: Vector2, goal: Vector2) -> bool:
	if absf(p.y)>MOAT_END+1.5 and signf(goal.y)==signf(p.y) and absf(goal.y)>MOAT_END+1.5: return false
	var direction:=signf(goal.x-p.x)
	return direction!=0.0 and (p.x-MOAT_X)*direction<MOAT_WATER+.4 and (goal.x-MOAT_X)*direction>MOAT_WATER+.4

static func moat_waypoint(p: Vector2,goal: Vector2,file: float=0.) -> Vector2:
	var direction:=signf(goal.x-p.x)
	if (p.x-MOAT_X)*direction < -MOAT_WATER and absf(p.y-file)>1.05:
		return Vector2(MOAT_X-direction*(MOAT_BANK+.60),file)
	return Vector2(MOAT_X+direction*(MOAT_BANK+.8),file)

static func waypoint(p: Vector2, goal: Vector2, bridgehead: bool=false) -> Vector2:
	if bridgehead and needs_moat_crossing(p,goal): return moat_waypoint(p,goal)
	if (p.x < RIVER_X - 5.0 and goal.x > RIVER_X - 5.0) or (p.x > RIVER_X + 5.0 and goal.x < RIVER_X + 5.0):
		var z := crossing(p.y)
		if absf(p.y - z) > 2.7:
			return Vector2(RIVER_X + signf(p.x - RIVER_X) * 7.0, z)
		return Vector2(RIVER_X - signf(p.x - RIVER_X) * 7.1, z)
	if p.x < WALL_X and goal.x >= WALL_X and absf(p.y) > GATE_HALF - 1.2:
		return Vector2(WALL_X - 4.0, 0)
	return goal

## Withdrawal uses actual gate openings and the toe of the sloped wall walk.
## The two side lanes run outside the corner towers.
static func retreat_waypoint(p: Vector2, goal: Vector2, front_open: bool, bridgehead: bool=false) -> Vector2:
	if parapet(p) > 0.0:
		return Vector2(WALL_X + 3.0, signf(p.y) * 4.7)
	var eastbound := goal.x > BACK_X
	var side := -1.0 if goal.y < 0.0 else 1.0
	var outside_z := side * (WALL_Z + 5.0)
	var in_fort := p.x > WALL_X - 1.4 and p.x < BACK_X + 1.2 and absf(p.y) < WALL_Z - 1.15
	if in_fort:
		if eastbound or not front_open:
			if absf(p.y) > POSTERN_HALF * 0.65:
				return Vector2(BACK_X - 3.0, 0)
			return Vector2(BACK_X + 3.0, 0)
		if absf(p.y) > GATE_HALF - 1.0:
			return Vector2(WALL_X + 3.0, 0)
		return Vector2(WALL_X - 3.0, 0)
	if eastbound and p.x >= RIVER_X - 5.0 and p.x <= BACK_X + 1.2:
		if p.x < WALL_X - 1.4 and absf(p.y) < WALL_Z + 3.1:
			return Vector2(WALL_X - 4.3, outside_z)
		return Vector2(BACK_X + 3.0, outside_z)
	if not eastbound and p.x > WALL_X - 2.0:
		if p.x >= BACK_X + 1.2 and absf(p.y) < WALL_Z + 3.1:
			return Vector2(BACK_X + 4.3, outside_z)
		return Vector2(WALL_X - 4.3, outside_z)
	return waypoint(p, goal, bridgehead)

static func clear_shot(a: Vector2, b: Vector2, open: bool, over_front: bool=false) -> bool:
	# Segment vs the actual wall strips; includes diagonal approaches and parapets.
	if maxf(a.x,b.x) < WALL_X - 1.4:
		return true
	for x: float in [WALL_X, BACK_X]:
		if (a.x < x) != (b.x < x):
			var z := lerpf(a.y, b.y, (x - a.x) / (b.x - a.x))
			if absf(z) < WALL_Z + 0.8:
				if x == BACK_X and absf(z) >= POSTERN_HALF: return false
				if x == WALL_X and not over_front and (not open or absf(z) >= GATE_HALF): return false
	for z: float in [-WALL_Z, WALL_Z]:
		if (a.y < z) != (b.y < z):
			var x := lerpf(a.x, b.x, (z - a.y) / (b.y - a.y))
			if x > WALL_X and x < BACK_X:
				return false
	return true
