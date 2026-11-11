extends RefCounted
## All planar coordinates are (x,z). Geometry and simulated movement share these landmarks.
const LIMIT := Vector2(118, 64)
const RIVER_X := -32.0
const CROSSINGS := [-35.0, 0.0, 35.0]
const WALL_X := 48.0
const BACK_X := 89.0
const WALL_Z := 23.0
const GATE_HALF := 4.0
const GATE := Vector2(WALL_X, 0)
const COURT := Vector2(66, 0)
const CAMP := Vector2(-83, 0)
const GROVE := Vector2(-2, 37)
const RIDGE := Vector2(9, -36)

static func height(p: Vector2) -> float:
	var slope := (p - RIDGE) / Vector2(34, 16)
	var hill := maxf(0.0, 1.0 - slope.length_squared())
	var east := (p - Vector2(77, 43)) / Vector2(30, 13)
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

static func deck_height(p: Vector2) -> float:
	var ledge := parapet(p)
	if ledge>0: return ledge
	if absf(p.x - RIVER_X) < 6.6 and absf(p.y - crossing(p.y)) < 3.95:
		return 0.13
	return height(p)

static func unit_point(p: Vector2) -> Vector3:
	return Vector3(p.x, deck_height(p), p.y)

static func pace(p: Vector2, mounted: bool) -> float:
	if p.distance_squared_to(GROVE) < 13.0 * 13.0:
		return 0.54 if mounted else 0.82
	if absf(p.x - RIVER_X) < 6.6:
		return 0.72
	return 0.87 if height(p) > 1.2 else 1.0

static func blocked(p: Vector2, open: bool) -> bool:
	if absf(p.x - RIVER_X) < 4.8 and absf(p.y - crossing(p.y)) > 3.8:
		return true
	if absf(p.x - WALL_X) < 1.4 and absf(p.y) <= WALL_Z + 1.0:
		return not (open and absf(p.y) < GATE_HALF - 0.3)
	if absf(p.x - BACK_X) < 1.2 and absf(p.y) <= WALL_Z + 1.0:
		return true
	return p.x >= WALL_X and p.x <= BACK_X and absf(absf(p.y) - WALL_Z) < 1.2

static func can_step(p: Vector2, q: Vector2, open: bool) -> bool:
	if blocked(q,open): return false
	if maxf(p.x,q.x)<WALL_X or minf(p.x,q.x)>WALL_X+5.0: return true
	return absf(parapet(q)-parapet(p))<0.56

static func travel(p: Vector2, offset: Vector2, open: bool) -> Vector2:
	var dest := (p + offset).clamp(-LIMIT, LIMIT)
	if can_step(p,dest,open):
		return dest
	var slide := Vector2(dest.x, p.y)
	if can_step(p,slide,open):
		return slide
	slide = Vector2(p.x, dest.y)
	return slide if can_step(p,slide,open) else p

static func waypoint(p: Vector2, goal: Vector2) -> Vector2:
	if (p.x < RIVER_X - 5.0 and goal.x > RIVER_X - 5.0) or (p.x > RIVER_X + 5.0 and goal.x < RIVER_X + 5.0):
		var z := crossing(p.y)
		if absf(p.y - z) > 2.7:
			return Vector2(RIVER_X + signf(p.x - RIVER_X) * 7.0, z)
		return Vector2(RIVER_X - signf(p.x - RIVER_X) * 7.1, z)
	if p.x < WALL_X and goal.x >= WALL_X and absf(p.y) > GATE_HALF - 1.2:
		return Vector2(WALL_X - 4.0, 0)
	return goal

static func clear_shot(a: Vector2, b: Vector2, open: bool, over_front: bool=false) -> bool:
	# Segment vs the actual wall strips; includes diagonal approaches and parapets.
	if maxf(a.x,b.x) < WALL_X - 1.4:
		return true
	for x: float in [WALL_X, BACK_X]:
		if (a.x < x) != (b.x < x):
			var z := lerpf(a.y, b.y, (x - a.x) / (b.x - a.x))
			if absf(z) < WALL_Z + 0.8 and (x == BACK_X or (not over_front and (not open or absf(z) >= GATE_HALF))):
				return false
	for z: float in [-WALL_Z, WALL_Z]:
		if (a.y < z) != (b.y < z):
			var x := lerpf(a.x, b.x, (z - a.y) / (b.y - a.y))
			if x > WALL_X and x < BACK_X:
				return false
	return true
