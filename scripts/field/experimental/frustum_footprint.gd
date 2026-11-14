extends RefCounted
## Conservative XZ footprint of the ACTUAL clipped view frustum intersected with
## an author-supplied world-height slab. Handles orthographic and perspective;
## does not assume that all four screen rays point below the horizon.
## The slab must include terrain + full visible actor/weapon height.
static func bounds(camera: Camera3D, height_min: float, height_max: float, horizontal_pad: float = 0.0) -> Dictionary:
	assert(height_max >= height_min and horizontal_pad >= 0.0)
	var pixels := camera.get_viewport().get_visible_rect().size
	if pixels.x <= 0.0 or pixels.y <= 0.0:
		return {"valid": false, "reason": "empty viewport"}
	var screen := [Vector2.ZERO, Vector2(pixels.x,0), pixels, Vector2(0,pixels.y)]
	var corners: Array[Vector3] = []
	for depth in [camera.near, camera.far]:
		for xy in screen:
			corners.append(camera.project_position(xy, depth))
	var points: Array[Vector3] = []
	for point in corners:
		if point.y >= height_min and point.y <= height_max:
			points.append(point)
	var edges := [[0,1],[1,2],[2,3],[3,0],[4,5],[5,6],[6,7],[7,4],[0,4],[1,5],[2,6],[3,7]]
	for edge in edges:
		var a := corners[edge[0]]
		var b := corners[edge[1]]
		var dy := b.y-a.y
		if absf(dy) < 0.00000001:
			continue
		for height in [height_min,height_max]:
			var t: float = (height-a.y)/dy
			if t >= 0.0 and t <= 1.0:
				points.append(a.lerp(b,t))
	if points.is_empty():
		return {"valid": false, "reason": "frustum outside world-height slab"}
	var lo := Vector2(INF,INF)
	var hi := Vector2(-INF,-INF)
	for point in points:
		lo = lo.min(Vector2(point.x,point.z))
		hi = hi.max(Vector2(point.x,point.z))
	var rect := Rect2(lo, hi-lo).grow(horizontal_pad + 0.0001)
	return {"valid": true, "rect": rect, "center": rect.get_center(), "half_extent": rect.size*.5, "vertices": points.size(), "projection": camera.projection, "height_slab": Vector2(height_min,height_max)}
