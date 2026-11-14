extends RefCounted
## Default-off diagnostic route planner. Reads existing real enemies and Ground;
## returns intended waypoints only, never assigns unit positions or steps Battle.
const Battle=preload("res://scripts/field/battle.gd")
const Ground=preload("res://scripts/field/ground.gd")
static func legal_waypoints(start:Vector2,goal:Vector2,gate_open:bool,bridgehead:bool)->Dictionary:
 var probe:=start;var points:Array[Vector2]=[];var traveled:=0.0
 for step in 256:
  if probe.distance_to(goal)<=1.2:return {"reachable":true,"points":points,"probe_length":traveled,"scope":"Ground queries only; no movement applied"}
  var waypoint:=Ground.waypoint(probe,goal,bridgehead)
  var direction:=probe.direction_to(waypoint)
  var next:=Ground.travel(probe,direction*.5,gate_open,bridgehead)
  if next.distance_to(probe)<.02:return {"reachable":false,"reason":"blocked_legal_waypoint","at":[probe.x,probe.y],"desired":[waypoint.x,waypoint.y],"scope":"Ground queries only"}
  traveled+=next.distance_to(probe);probe=next
  # Every point retained so the steering input never shortcuts a corner.
  points.append(probe)
 return {"reachable":false,"reason":"bounded_path_budget","scope":"Ground queries only"}
static func select(battle)->Dictionary:
 var origin:Vector2=battle.hero.pos;var choices:Array=[]
 for unit in battle.roster:
  if unit.team==battle.hero.team or unit.hp<=0 or unit.state in [Battle.State.DEAD,Battle.State.ESCAPED]:continue
  choices.append({"id":unit.id,"distance":origin.distance_to(unit.pos)})
 choices.sort_custom(func(a,b):return a.distance<b.distance if a.distance!=b.distance else a.id<b.id)
 var rejected:Array=[]
 for i in mini(16,choices.size()):
  var unit=battle.roster[choices[i].id]
  var route=legal_waypoints(origin,unit.pos,battle.gate_hp<=0,battle.bridgehead)
  if route.reachable:
   route["target_id"]=unit.id;route["target_pos"]=[unit.pos.x,unit.pos.y];route["actual_distance"]=choices[i].distance;route["rejected"]=rejected
   route["input_only"]=true;return route
  rejected.append({"id":unit.id,"reason":route.reason})
 return {"reachable":false,"reason":"no_reachable_enemy_in_bounded16_nearest","rejected":rejected,"input_only":true}
static func camera_input(world_direction:Vector2,yaw:float)->Vector2:
 return world_direction.normalized().rotated(yaw)*.8 if world_direction.length_squared()>.0001 else Vector2.ZERO
