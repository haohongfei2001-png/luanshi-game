extends SceneTree
## Compare terrain orientation to the actual engine's upward-facing PlaneMesh.
const Surface:=preload("res://tools/art/authored_reset/surface_authoring.gd")
func check(arrays:Array) -> int:
	var v:PackedVector3Array=arrays[Mesh.ARRAY_VERTEX];var ids:PackedInt32Array=arrays[Mesh.ARRAY_INDEX]
	var n:PackedVector3Array=arrays[Mesh.ARRAY_NORMAL]
	for i in range(0,ids.size(),3):
		var face:Vector3=(v[ids[i+1]]-v[ids[i]]).cross(v[ids[i+2]]-v[ids[i]])
		var normal:Vector3=n[ids[i]]+n[ids[i+1]]+n[ids[i+2]]
		assert(face.dot(normal)<0.,"Godot clockwise front winding violated; upward mesh would be culled")
	return ids.size()/3
func _initialize() -> void:
	var plane:=PlaneMesh.new();assert(check(plane.get_mesh_arrays())==2)
	var count:=0
	for p:Vector2 in [Vector2(24,-16),Vector2(32,0),Vector2(-40,-8)]:count+=check(Surface.tile(p,16.,.5).surface_get_arrays(0))
	print("SURFACE_FRONT_FACE_PASS native_plane=clockwise terrain_triangles=",count," graphics=NOT_RUN")
	quit()
