extends SceneTree
const Surface:=preload("res://tools/art/authored_reset/surface_authoring.gd")
func _initialize() -> void:
	var left:=Surface.tile(Vector2(16,-16));var right:=Surface.tile(Vector2(32,-16))
	var a:=left.surface_get_arrays(0);var b:=right.surface_get_arrays(0)
	for row:int in 33:
		var i:=row*33+32;var j:=row*33
		for channel:int in [Mesh.ARRAY_VERTEX,Mesh.ARRAY_NORMAL,Mesh.ARRAY_TEX_UV,Mesh.ARRAY_COLOR]:
			assert(a[channel][i].is_equal_approx(b[channel][j]),"Tile seam discontinuity")
	for pos:Vector3 in a[Mesh.ARRAY_VERTEX]:
		assert(absf(pos.y-Surface.height(Vector2(pos.x,pos.z)))<.00001)
	assert(a[Mesh.ARRAY_INDEX].size()/3==2048)
	# Threshold precision across both material and geometry seams.
	for z:int in range(-50,51):
		var p:=Vector2(32,z*.2)
		assert(Surface.masks(p-Vector2(.00001,0)).is_equal_approx(Surface.masks(p+Vector2(.00001,0))))
	print("SURFACE_AUTHORING_PASS UV/normal/mask/height seams; animated feet NOT_RUN")
	quit()
