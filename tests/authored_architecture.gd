extends SceneTree
func _initialize() -> void:run.call_deferred()
func run() -> void:
 var p=load('res://assets/river_authored/architecture/architecture.glb') as PackedScene
 assert(p)
 var model=p.instantiate();root.add_child(model)
 await process_frame
 for name in ['GateHall','GateDoor','GateBridge','WestBridge','WallWalk']:
  assert(model.find_child(name,true,false)!=null,name)
 var door=model.find_child('GateDoor',true,false) as Node3D
 assert(door.global_position.distance_to(Vector3(48,0,0))<.001)
 var meshes=model.find_children('*','MeshInstance3D',true,false)
 var triangles:=0;var surfaces:=0
 for m:MeshInstance3D in meshes:
  assert(m.mesh)
  surfaces+=m.mesh.get_surface_count()
  for i in m.mesh.get_surface_count():
   var a=m.mesh.surface_get_arrays(i)
   assert(a[Mesh.ARRAY_TEX_UV].size()==a[Mesh.ARRAY_VERTEX].size())
   triangles+=a[Mesh.ARRAY_INDEX].size()/3
 print('AUTHORED_ARCHITECTURE_IMPORT_PASS ',JSON.stringify({'meshes':meshes.size(),'surfaces':surfaces,'triangles':triangles,'door_pivot':str(door.global_position),'visual':'NOT_ACCEPTED','graphics':'NOT_RUN'}))
 model.queue_free();await process_frame;await process_frame
 quit()
