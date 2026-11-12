extends RefCounted
## Stateless assignments come from saved deployment slots and formation ranks.
const Ground := preload("res://scripts/field/ground.gd")

# The 3.90 x 1.48 m chassis also carries outboard wheels and a longer beam.
const HULL := Vector2(2.64, 1.16)
const CORNERS := [Vector2(-3.03, -1.60), Vector2(3.03, -1.60),
		Vector2(3.03, 1.60), Vector2(-3.03, 1.60)]

static func crew_station(ram: Vector2, id: int) -> Vector2:
	var x := -1.30 if (id % 4) < 2 else 1.30
	var z := -1.55 if (id % 2) == 0 else 1.55
	return ram + Vector2(x, z)

static func escort_station(ram: Vector2, slot: int, formation: Vector2) -> Vector2:
	# Each escort forms a screen parallel to the vehicle. Its files face out
	# along the road while its ranks add depth away from the wheels.
	var side := -1.0 if slot % 2 == 0 else 1.0
	var pair := floori(float(slot) / 2.0)
	var lead := 7.7 - float(pair % 3) * 7.7
	var anchor_x := minf(ram.x + lead, Ground.WALL_X - 8.2)
	var distance := 2.65 + absf(formation.x) * 0.84 + floorf(float(pair) / 3.0) * 6.1
	return Vector2(anchor_x + formation.y, ram.y + side * distance)

static func gate_station(slot: int, count: int, home: Vector2, formation: Vector2) -> Vector2:
	# Forward files serve both leaves. Relief ranks stop just behind the first,
	# within striking distance even if another company lost its vanguard.
	var bands := mini(5, count)
	var depth := floorf(float(slot) / bands)
	var forward := absf(formation.x) < 0.45 and absf(formation.y) <= 4.0
	var relief := absf(formation.x) <= 2.05 and absf(formation.y) <= 1.65
	if forward or relief:
		var shoulder := -1.0 if formation.y < 0.0 else 1.0
		var file := clampf(absf(formation.y) * 0.35 + float(slot % 3) * 0.23, 0.0, 1.76)
		var stand_off := 1.70 + 0.35 * (0.0 if forward else 1.0) + float(slot % 2) * 0.18
		return Ground.GATE + Vector2(-stand_off, shoulder * (1.48 + file))
	var x := Ground.WALL_X - 2.75 - depth * 6.3 + formation.x
	return Vector2(x, home.y * 0.82 + formation.y * 0.87)

static func gate_face(p: Vector2) -> Vector2:
	# The two leaves and their bindings occupy the entire rendered aperture.
	return Vector2(Ground.WALL_X - 0.71, clampf(p.y, -Ground.GATE_HALF + 0.12, Ground.GATE_HALF - 0.12))

static func hits_gate(p: Vector2, direction: Vector2, reach: float, width: float, thrust: bool) -> bool:
	if direction.x <= 0.0 or p.x >= Ground.WALL_X - 0.71:
		return false
	var face := gate_face(p)
	var distance_x := face.x - p.x
	if distance_x > reach + 0.20: return false
	# Clamp the attack ray to the near leaf or closest jamb. Lateral sweep
	# tolerance follows the actual equipped attack, as it does against units.
	face.y = clampf(p.y + distance_x * direction.y / direction.x, -Ground.GATE_HALF + 0.12, Ground.GATE_HALF - 0.12)
	var delta := face - p
	var along := direction.dot(delta)
	if along <= 0.0 or delta.length_squared() > (reach + 0.20) * (reach + 0.20): return false
	return absf(direction.cross(delta)) <= width + 0.22 if thrust else along >= delta.length() * cos(width)

static func _passage(p: Vector2, x: float, z: float, half_depth: float, direction: float) -> Vector2:
	if (p.x - x) * direction < -half_depth and absf(p.y - z) > 0.76:
		return Vector2(x - direction * (half_depth + 1.48), z)
	return Vector2(x + direction * (half_depth + 0.85), z)

static func waypoint(p: Vector2, goal: Vector2, file_z: float, id: int, gate_open: bool, ram_at_gate: bool = false) -> Vector2:
	var direction := signf(goal.x - p.x)
	if direction == 0.0:
		return Ground.waypoint(p, goal)
	# Inbound and outbound files keep right. Formation widths compress across the
	# bridge deck without changing the destination of an enemy already on it.
	var lane := direction * 0.70 + clampf(file_z * 0.39, -2.12, 2.12)
	var from_river := (p.x - Ground.RIVER_X) * direction
	var to_river := (goal.x - Ground.RIVER_X) * direction
	if from_river < 5.05 and to_river > 5.05:
		return _passage(p, Ground.RIVER_X, Ground.crossing(p.y) + lane, 4.85, direction)
	var from_gate := (p.x - Ground.WALL_X) * direction
	var to_gate := (goal.x - Ground.WALL_X) * direction
	if gate_open and from_gate < 1.55 and to_gate > 1.55:
		if absf(p.y) < Ground.WALL_Z or absf(goal.y) < Ground.WALL_Z:
			if ram_at_gate:
				# The parked chassis occupies the centre file up to the opening.
				# Keep both shoulders open from approach through the far doorpost.
				lane = _side(lane, id) * (1.64 + minf(1.30, absf(lane) * 0.47))
			return _passage(p, Ground.WALL_X, lane, 1.45, direction)
	return Ground.waypoint(p, goal)

static func _inside(p: Vector2) -> bool:
	return absf(p.x) < HULL.x and absf(p.y) < HULL.y

static func _side(value: float, id: int) -> float:
	if absf(value) > 0.01:
		return signf(value)
	return 1.0 if id % 2 == 0 else -1.0

static func _normal(p: Vector2, id: int) -> Vector2:
	if HULL.x - absf(p.x) < HULL.y - absf(p.y):
		return Vector2(_side(p.x, id), 0.0)
	return Vector2(0.0, _side(p.y, id))

static func _blocks_segment(a: Vector2, b: Vector2) -> bool:
	if (a.x <= -HULL.x and b.x <= -HULL.x) or (a.x >= HULL.x and b.x >= HULL.x):
		return false
	if (a.y <= -HULL.y and b.y <= -HULL.y) or (a.y >= HULL.y and b.y >= HULL.y):
		return false
	var d := b - a
	var enter := 0.0
	var leave := 1.0
	if absf(d.x) > 0.00001:
		var t0 := (-HULL.x - a.x) / d.x
		var t1 := (HULL.x - a.x) / d.x
		enter = maxf(enter, minf(t0, t1))
		leave = minf(leave, maxf(t0, t1))
	if absf(d.y) > 0.00001:
		var t0 := (-HULL.y - a.y) / d.y
		var t1 := (HULL.y - a.y) / d.y
		enter = maxf(enter, minf(t0, t1))
		leave = minf(leave, maxf(t0, t1))
	return enter < leave

static func around_ram(p: Vector2, goal: Vector2, ram: Vector2, id: int, gate_open: bool = false) -> Vector2:
	var a := p - ram
	if absf(a.x) > 8.5 or absf(a.y) > 7.0:
		return goal
	if _inside(a):
		return p + _normal(a, id) * 1.8
	var b := goal - ram
	if _inside(b):
		# A target inside the envelope can be struck from the nearest side.
		var outside := a.clamp(-HULL - Vector2.ONE * 0.12, HULL + Vector2.ONE * 0.12)
		b = outside
		goal = ram + outside
	if not _blocks_segment(a, b):
		return goal
	var best := INF
	var next := p
	for k in 4:
		var i := (k + (id % 2) * 2) % 4
		var corner: Vector2 = CORNERS[i]
		if a.distance_squared_to(corner) < 0.12 or (not gate_open and ram.x + corner.x >= Ground.WALL_X - 1.45) or _blocks_segment(a, corner):
			continue
		var remaining := corner.distance_to(b)
		if _blocks_segment(corner, b):
			remaining = INF
			for j in [(i + 1) % 4, (i + 3) % 4]:
				var other: Vector2 = CORNERS[j]
				if (gate_open or ram.x + other.x < Ground.WALL_X - 1.45) and not _blocks_segment(other, b):
					remaining = minf(remaining, corner.distance_to(other) + other.distance_to(b))
		var total := a.distance_to(corner) + remaining
		if total < best:
			best = total
			next = ram + corner
	return next

static func ram_motion(p: Vector2, offset: Vector2, ram: Vector2, id: int) -> Vector2:
	var a := p - ram
	if absf(a.x) > HULL.x + absf(offset.x) or absf(a.y) > HULL.y + absf(offset.y):
		return offset
	var b := a + offset
	if _inside(a):
		# A moving ram can overtake a fighter during a committed animation.
		# Let them clear the nearest side at their actual walking speed.
		var outward := _normal(a, id)
		return offset if offset.dot(outward) > 0.001 else outward * offset.length()
	if not _blocks_segment(a, b):
		return offset
	var along := Vector2(offset.x, 0.0)
	if along.x != 0.0 and not _blocks_segment(a, a + along):
		return along
	along = Vector2(0.0, offset.y)
	if not _blocks_segment(a, a + along):
		return along
	return Vector2.ZERO
