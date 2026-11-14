extends SceneTree
const Sampler=preload('res://tools/art/continuous_landform/adaptive_surface.gd')
const G=preload('res://scripts/field/ground.gd')
const S=preload('res://tools/art/authored_reset/surface_authoring.gd')
func _initialize():
 var sampler=Sampler.new();var worst=0.;var pos=Vector3.ZERO
 var mesh=sampler.tile(Vector2(16,-32),16.)
 var a=mesh.surface_get_arrays(0);var v=a[Mesh.ARRAY_VERTEX];var ids=a[Mesh.ARRAY_INDEX]
 for i in range(0,ids.size(),3):
  var p=(v[ids[i]]+v[ids[i+1]]+v[ids[i+2]])/3.;var xz=Vector2(p.x,p.z)
  if not G.blocked(xz,true,true):
   var error=abs(p.y-S.height(xz))
   if error>worst:worst=error;pos=p
 print('TIP_PATCH_RESULT error=',worst,' point=',pos,' triangles=',ids.size()/3,' levels=',sampler.distribution)
 quit(0 if worst<.012 else 1)
