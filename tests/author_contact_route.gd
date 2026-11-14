extends SceneTree
const Planner=preload("res://scripts/review/author_contact_route.gd")
const Battle=preload("res://scripts/field/battle.gd")
const Save=preload("res://scripts/field/save.gd")
func _initialize()->void:
 var b=Battle.new();b.setup(20,Battle.SEED,Battle.Arms.Kit.SPEAR,true,true,-1,true);b.start()
 for i in 135:b.step()
 var before=var_to_bytes(Save.snapshot(b));var route=Planner.select(b)
 assert(var_to_bytes(Save.snapshot(b))==before)
 assert(route==Planner.select(b))
 assert(route.reachable and route.points.size()>0)
 var p=b.hero.pos
 for q in route.points:
  assert(Battle.Ground.can_step(p,q,b.gate_hp<=0,b.bridgehead));assert(p.distance_to(q)<=.501);p=q
 assert(p.distance_to(b.roster[route.target_id].pos)<=1.2)
 for yaw in [-1.134464,0.,1.0]:
  var desired=Vector2(.3,.7).normalized();var input=Planner.camera_input(desired,yaw)
  assert(input.rotated(-yaw).normalized().distance_to(desired)<.00001)
 print("AUTHOR_CONTACT_ROUTE_READONLY_PASS target=",route.target_id," actual_distance=",route.actual_distance," legal_probe_points=",route.points.size()," path_m=",route.probe_length,"; no actual movement/contact/GPU claim")
 quit()
