extends SceneTree
const Ground:=preload("res://scripts/field/ground.gd")
const Surface:=preload("res://tools/art/authored_reset/surface_authoring.gd")
const Plan:=preload("res://scripts/field/regional_landscape_plan.gd")
func _initialize():run.call_deferred()
func run():
 var args:=OS.get_cmdline_user_args();assert(args.size()==2,"resource directory and original terrain05")
 var trees:PackedScene=load(args[0].path_join("woodland06.scn"));var grass:PackedScene=load(args[0].path_join("grass06.scn"));var terrain:PackedScene=load(args[0].path_join("terrain06.scn"))
 for pass_id in 3:
  var forest:=trees.instantiate();root.add_child(forest);assert(forest.get_child_count()==16)
  var meshes:={};var mesh_nodes:=0
  for tree:Node3D in forest.get_children():
   assert(is_equal_approx(tree.scale.x,1.));assert(absf(tree.position.y-Surface.height(Vector2(tree.position.x,tree.position.z))+.08)<.00001)
   for mesh:MeshInstance3D in tree.find_children("*","MeshInstance3D",true,false):
    meshes[mesh.mesh.get_instance_id()]=true;mesh_nodes+=1
  assert(meshes.size()==1 and mesh_nodes==16,"All original trees must share source mesh and generated LODs")
  forest.free()
 var cover:=grass.instantiate();root.add_child(cover);var positions:Array=cover.get_child(0).get("authored_transforms");assert(positions.size()>10000 and positions.size()<16000)
 for pose:Transform3D in positions:
  var p:=Vector2(pose.origin.x,pose.origin.z)
  assert(absf(p.y)>4.7 and not Ground.blocked(p,true,true));assert(absf(pose.origin.y-Surface.height(p))<.00001)
 cover.free()
 var current:=terrain.instantiate();var old:Node=(load(args[1]) as PackedScene).instantiate()
 var count:=0
 for collision:CollisionShape3D in current.find_children("*","CollisionShape3D",true,false):
  var source:=old.get_node(current.get_path_to(collision)) as CollisionShape3D
  assert(source and source.shape is ConcavePolygonShape3D and collision.shape is ConcavePolygonShape3D)
  assert(source.shape.get_faces()==collision.shape.get_faces(),"Landscape art changed real support mesh")
  count+=1
 assert(count==266)
 current.free();old.free()
 print("REGIONAL_LANDSCAPE06_RESOURCE_PASS opens=3 shared_tree_mesh=1 trees=16 grass=",positions.size()," exact_original_collision_tiles=",count," graphics=NOT_RUN")
 quit()
