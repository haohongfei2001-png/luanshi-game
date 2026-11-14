extends SceneTree
const Support=preload('res://tools/art/gate_structure/region_support.gd')
func _initialize()->void:
 var expected=PlaneMesh.new().get_mesh_arrays()
 var vertices:PackedVector3Array=expected[Mesh.ARRAY_VERTEX]
 var indices:PackedInt32Array=expected[Mesh.ARRAY_INDEX]
 var standard=(vertices[indices[1]]-vertices[indices[0]]).cross(vertices[indices[2]]-vertices[indices[0]]).y
 assert(standard<0.,'Engine front-face convention unexpectedly changed')
 var mesh=Support.rectangle(29.1,29.6,-12.5,-12.)
 var arrays=mesh.surface_get_arrays(0)
 var v:PackedVector3Array=arrays[Mesh.ARRAY_VERTEX];var ids:PackedInt32Array=arrays[Mesh.ARRAY_INDEX]
 for i in range(0,ids.size(),3):
  var normal=(v[ids[i+1]]-v[ids[i]]).cross(v[ids[i+2]]-v[ids[i]])
  assert(normal.y<0.,'Support surface is backface-culled from above')
 print('AUTHORED_SUPPORT_CLOCKWISE_FRONT_FACE_PASS triangles=',ids.size()/3,' engine_plane_cross_y=',standard)
 quit()
