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
const BRIDGE_VIEW := Vector2(34.2,1.0)
const GATE := Vector2(WALL_X, 0)
const COURT := Vector2(66, 0)
const CAMP := Vector2(-83, 0)
const GROVE := Vector2(-2, 37)
const RIDGE := Vector2(9, -36)
const RIDGE_RADII := Vector2(34, 16)
const EAST_HILL := Vector2(77, 43)
const EAST_RADII := Vector2(30, 13)

static func height(p: Vector2) -> float:
	var slope := (p - RIDGE) / RIDGE_RADII
	var hill := maxf(0.0, 1.0 - slope.length_squared())
	var east := (p - EAST_HILL) / EAST_RADII
	var bank := clampf((absf(p.x - RIVER_X) - 3.9) / 2.4, 0.0, 1.0)
	return 3.9 * hill * hill + 1.8 * pow(maxf(0.0, 1.0 - east.length_squared()), 2) - (1.0 - bank) * 0.92

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
	return (1.0-smoothstep(MOAT_WATER,MOAT_BANK,absf(p.x-MOAT_X))) * (1.0-smoothstep(MOAT_END-1.5,MOAT_END+1.5,absf(p.y)))

static func moat_blocks(p: Vector2) -> bool:
	return absf(p.x-MOAT_X)<MOAT_WATER and absf(p.y)>MOAT_DECK and absf(p.y)<MOAT_END

# At the bridgehead a change from a column to a line can put the outside
# files into the moat. Keep their frontage and dress them back onto their bank.
static func muster_ground(station: Vector2,company_x: float) -> Vector2:
	if moat_blocks(station):
		station.x=MOAT_X+signf(company_x-MOAT_X)*(MOAT_WATER+.24)
	return station

static func deck_height(p: Vector2, bridgehead: bool=false) -> float:
	if bridgehead and absf(p.x-MOAT_X)<5.95 and absf(p.y)<=MOAT_DECK+.18: return .13
	var ledge := parapet(p)
	if ledge>0: return ledge
	if absf(p.x - RIVER_X) < 6.6 and absf(p.y - crossing(p.y)) < 3.95:
		return 0.13
	return height(p)-(.87*moat_depth(p) if bridgehead else 0.0)

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
	return 0.87 if height(p) > 1.2 else 1.0

static func blocked(p: Vector2, open: bool, bridgehead: bool=false) -> bool:
	if bridgehead and moat_blocks(p): return true
	if absf(p.x - RIVER_X) < 4.8 and absf(p.y - crossing(p.y)) > 3.8:
		return true
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
