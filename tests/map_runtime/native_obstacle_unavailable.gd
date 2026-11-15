extends SceneTree
# Generic mathematical plane and strip, not authored input geometry.
func _initialize():
 var vertices:=[];var triangles:=[];var polygon:=[]
 for corner in 4:
  var right:=corner==1 or corner==2;var upper:=corner>=2
  vertices.append([4. if right else 0.,0.,4. if upper else 0.])
  polygon.append([2.1 if right else 1.9,2. if upper else 0.])
 for corner in range(1,3):triangles.append([0,corner,corner+1])
 var surface:={"id":"ground","walkable":true,"vertices":vertices,"triangles":triangles}
 var wall:={"id":"wall","xz_polygon":polygon,"min_y":0.,"max_y":3.}
 var data:={"surfaces":[surface],"solids":[wall],"portals":[]}
 var args:=OS.get_cmdline_user_args()
 var reference=load("res://scripts/field/maps/authored_navigation.gd").new()
 var native=load("res://scripts/field/maps/experimental_native_fused_navigation.gd" if args.size()==1 and args[0]=="native-fused" else "res://scripts/field/maps/experimental_native_obstacle_navigation.gd").new()
 assert(reference.configure(data,Rect2(0,0,4,4))==OK);assert(native.configure(data,Rect2(0,0,4,4))==OK)
 assert(native.support.kernel==null and native.obstacles.kernel==null,"Requires optional library to be absent")
 for p in [Vector3(2,0,1),Vector3.ZERO,Vector3(3,0,3),Vector3(2,3,1)]:assert(var_to_bytes(reference.obstacles.obstruction(p,.45,1.9))==var_to_bytes(native.obstacles.obstruction(p,.45,1.9)))
 for a in [Vector2(1,1),Vector2(3,1),Vector2(1,3)]:
  for b in [Vector2(3,3),Vector2(1,1),Vector2(4,4)]:assert(reference.can_travel(a,b,"ground","ground")==native.can_travel(a,b,"ground","ground"))
 assert(reference.graph.get_point_ids()==native.graph.get_point_ids())
 for id in reference.graph.get_point_ids():assert(reference.graph.get_point_connections(id)==native.graph.get_point_connections(id))
 print("NATIVE_BODY_UNAVAILABLE_FALLBACK_PASS original graph/body/segments without optional library");quit()
