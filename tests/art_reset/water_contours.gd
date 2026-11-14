extends SceneTree
const Water:=preload("res://tools/art/continuous_landform/water_contours.gd")
const Surface:=preload("res://tools/art/authored_reset/surface_authoring.gd")
const Ground:=preload("res://scripts/field/ground.gd")
func _initialize() -> void:
	assert(not Ground.authored_landform_enabled,"This helper must work without height opt-in")
	var mesh:=Water.mesh(Vector2(-48,-48),Vector2(112,96))
	var v:PackedVector3Array=mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX];var error:=0.
	for i in range(0,v.size(),3):
		assert((v[i+1]-v[i]).cross(v[i+2]-v[i]).y<0.)
		var center:Vector3=(v[i]+v[i+1]+v[i+2])/3.
		error=maxf(error,Surface.height(Vector2(center.x,center.z))-center.y)
		assert(absf(center.y-Ground.BATTLE_WATER_LEVEL)<.00001)
	print("WATER_MEASURED triangles=",v.size()/3," error=",error)
	if not (error<.05 and v.size()/3==14122 and int(mesh.get_meta("discarded_sub_square_millimetre_slivers"))==2):
		push_error("Water footprint/count mismatch");quit(1);return
	print("CURRENT_GROUND_WATER_CONTOURS_PASS triangles=",v.size()/3," max_contour_error_m=",error," ground_default=OFF graphics=NOT_RUN")
	quit()
