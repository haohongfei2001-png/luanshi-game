extends "res://scripts/field/maps/map_query.gd"
var profile_enabled:=false
var profile:Dictionary={} # Inclusive query times; nested totals must not be summed.
## Internal open-gate field battle only. No old siege/world objective fallback.
const Navigation:=preload("res://scripts/field/maps/authored_navigation.gd")
var nav:Navigation
var source:Dictionary={}
var _landmarks:Dictionary={}
var _retreat:Array[Vector2]=[]
var _spawn_centres:Array[Vector2]=[]
var _routes:Dictionary={}
func bind(navigation:Navigation,data:Dictionary)->Error:
 if nav!=null:return ERR_ALREADY_IN_USE
 if not navigation._configured or navigation._gates.get("gate_main")!=true:return ERR_UNAVAILABLE
 if data.get("goal_regions",[]).is_empty() or data.get("retreat_regions",[]).size()!=2 or data.get("spawn_regions",[]).size()!=2:return ERR_INVALID_DATA
 var dynamic=data.get("gate_dynamic")
 if not dynamic is Dictionary or not dynamic.get("pivot") is Array or dynamic.pivot.size()!=3:return ERR_INVALID_DATA
 var gate=dynamic.pivot;var goal=data.goal_regions[0].get("center")
 if not goal is Array or goal.size()!=3:return ERR_INVALID_DATA
 for value in gate+goal:
  if not (value is int or value is float) or not is_finite(float(value)):return ERR_INVALID_DATA
 nav=navigation;source=data.duplicate(true)
 _landmarks={"gate":Vector2(gate[0],gate[2]),"court":Vector2(goal[0],goal[2])}
 for region in data.retreat_regions:_retreat.append(centre(region.xz_polygon))
 for region in data.spawn_regions:_spawn_centres.append(centre(region.xz_polygon))
 return OK
func centre(polygon:Array)->Vector2:
 var total:=Vector2.ZERO
 for p in polygon:total+=Vector2(p[0],p[1])
 return total/float(polygon.size())
func identity()->Dictionary:
 # An unbound runtime is still a MapQuery and can be inspected diagnostically.
 if nav==null or not nav._configured:return {}
 for key in ["map_id","topology_revision","topology_sha256"]:
  if not source.has(key):return {}
 return {"map_id":source.map_id,"topology_revision":int(source.topology_revision),"topology_sha256":source.topology_sha256}
func height(p:Vector2)->float:
 var found=nav.support.support(p)
 return found.position.y if found.error==OK else NAN
func pace(_p:Vector2,_mounted:bool)->float:return 1.
func blocked(p:Vector2,_open:bool)->bool:
 var hit=nav.support.support(p)
 return hit.error!=OK or nav.obstacles.obstruction(hit.position,nav._radius,nav._height,nav._gates).blocked
func can_step(p:Vector2,q:Vector2,_open:bool)->bool:
 var a=nav.support.support(p);var b=nav.support.support(q)
 return a.error==OK and b.error==OK and nav.can_travel(p,q,a.surface_id,b.surface_id)
func travel(p:Vector2,offset:Vector2,open:bool)->Vector2:
 if offset.length_squared()<.00000001:return p
 if can_step(p,p+offset,open):return p+offset
 var x:=Vector2(offset.x,0);var z:=Vector2(0,offset.y)
 if x.length_squared()>z.length_squared():
  if can_step(p,p+x,open):return p+x
  if can_step(p,p+z,open):return p+z
 else:
  if can_step(p,p+z,open):return p+z
  if can_step(p,p+x,open):return p+x
 return p
func waypoint(p:Vector2,goal:Vector2)->Vector2:
 if not profile_enabled:return _waypoint_impl(p,goal)
 var started:=Time.get_ticks_usec();var result:=_waypoint_impl(p,goal)
 profile["waypoint_calls"]=int(profile.get("waypoint_calls",0))+1
 profile["waypoint_us"]=int(profile.get("waypoint_us",0))+Time.get_ticks_usec()-started
 return result
func _waypoint_impl(p:Vector2,goal:Vector2)->Vector2:
 if p.distance_squared_to(goal)<36. and can_step(p,goal,true):return goal
 var from:=nav.graph.get_closest_point(p);var to:=nav.graph.get_closest_point(goal)
 if from<0 or to<0:return p
 var key:=Vector2i(from,to)
 if not _routes.has(key):
  if _routes.size()>2048:
   _routes.clear()
   if profile_enabled:profile["route_cache_full_clears"]=int(profile.get("route_cache_full_clears",0))+1
  var astar_start:=Time.get_ticks_usec() if profile_enabled else 0
  _routes[key]=nav.graph.get_point_path(from,to)
  if profile_enabled:
   profile["astar_calls"]=int(profile.get("astar_calls",0))+1
   profile["astar_us"]=int(profile.get("astar_us",0))+Time.get_ticks_usec()-astar_start
 elif profile_enabled:profile["route_cache_hits"]=int(profile.get("route_cache_hits",0))+1
 var route:PackedVector2Array=_routes[key]
 # route[0] is the nearest lattice node, not a forward target. Pulling back
 # to it outside0.4m oscillates before the0.5m nearest-node switch boundary.
 # Only skip ahead when the full source-supported segment is traversable.
 for index in range(mini(route.size()-1,6),0,-1):
  var point:=route[index]
  if p.distance_squared_to(point)>.01 and can_step(p,point,true):return point
 # At a bridge/river corner, only the start-node connector may be legal.
 # Forward nodes were tried first, so reconnecting here does not restore the
 # old start-node-before-forward oscillation. Never relax can_step.
 if not route.is_empty() and p.distance_squared_to(route[0])>.000001 and can_step(p,route[0],true):return route[0]
 return p
func clear_shot(p:Vector2,q:Vector2,_open:bool,_elevated:bool=false)->bool:
 var start:=height(p);var end:=height(q)
 if not is_finite(start) or not is_finite(end):return false
 return not nav.obstacles.segment_obstruction(Vector3(p.x,start+1.2,p.y),Vector3(q.x,end+1.2,q.y),nav._gates)

func parapet(_p:Vector2)->float:return 0. # Author explicitly marks wall tops non-walkable.
func landmarks()->Dictionary:return _landmarks.duplicate(true)
func retreat_goal(team:int)->Vector2:return _retreat[team]
func objective(team:int,mission:String,home:Vector2,regrouping:bool)->Vector2:
 if regrouping or mission in ["HOLD","RESERVE"]:return home
 if mission=="WITHDRAW":return retreat_goal(team)
 return _spawn_centres[1-team] # Author source opposing assembly region, not old court coordinates.
func projectile_clear(p:Vector2,q:Vector2,launch_height:float,_open:bool,_elevated:bool=false)->bool:
 # Existing projectiles are2D trajectories with launch support height. Query
 # actual solid volume at that height, not walkability of air over the river.
 return not nav.obstacles.segment_obstruction(Vector3(p.x,launch_height+1.2,p.y),Vector3(q.x,launch_height+1.2,q.y),nav._gates)
