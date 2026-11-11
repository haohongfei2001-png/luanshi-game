extends RefCounted
## Open-field flag visibility. Terrain occlusion can narrow this in a later map.
const FLAG_RANGE := 14.0
const FLAG_SPEED := 30.0
const RECOGNITION_SECONDS := 0.15
const ORDERS := ["follow", "attack", "retreat"]

static func visible(origin: Vector2, position: Vector2) -> bool:
	return origin.distance_to(position) <= FLAG_RANGE

static func delay(origin: Vector2, position: Vector2) -> float:
	return RECOGNITION_SECONDS + origin.distance_to(position) / FLAG_SPEED
