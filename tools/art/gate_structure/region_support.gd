extends RefCounted
const Surface:=preload("res://tools/art/authored_reset/surface_authoring.gd")
static func rectangle(x0:float,x1:float,z0:float,z1:float)->ArrayMesh:
 var nx:int=int(ceil((x1-x0)/.5));var nz:int=int(ceil((z1-z0)/.5))
 var vertices=PackedVector3Array();var normals=PackedVector3Array();var indices=PackedInt32Array()
 for z:int in nz+1:
  for x:int in nx+1:
   var p=Vector2(lerpf(x0,x1,float(x)/nx),lerpf(z0,z1,float(z)/nz))
   vertices.append(Vector3(p.x,Surface.height(p),p.y));normals.append(Surface.normal_at(p))
 for z:int in nz:
  for x:int in nx:
   var i=z*(nx+1)+x;indices.append_array([i,i+1,i+nx+1,i+1,i+nx+2,i+nx+1])
 var arrays=[];arrays.resize(Mesh.ARRAY_MAX);arrays[Mesh.ARRAY_VERTEX]=vertices;arrays[Mesh.ARRAY_NORMAL]=normals;arrays[Mesh.ARRAY_INDEX]=indices
 var mesh=ArrayMesh.new();mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays);return mesh
