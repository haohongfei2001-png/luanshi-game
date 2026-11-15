extends SceneTree
const Navigation=preload("res://scripts/field/maps/authored_navigation.gd")
const Runtime=preload("res://scripts/field/maps/authored_field_runtime.gd")
const Muster=preload("res://scripts/field/maps/authored_muster.gd")
const Battle=preload("res://scripts/field/battle.gd")
func _initialize():run.call_deferred()
func run():
 var args:=OS.get_cmdline_user_args();assert(args.size() in [2,3])
 var data:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(args[0]))
 var low:=Vector2(INF,INF);var high:=Vector2(-INF,-INF)
 for surface in data.surfaces:
  if not surface.get("walkable",false):continue
  for point in surface.vertices:low=low.min(Vector2(point[0],point[2]));high=high.max(Vector2(point[0],point[2]))
 var report={"source_sha256":FileAccess.get_sha256(args[0]),"topology":data.topology_sha256,"scope":"NEW_SOURCE_FUNCTIONAL_ONLY_NO_GPU_OR_ART_ACCEPTANCE","bounds":[str(low),str(high)]}
 var nav:=Navigation.new()
 if args.size()==3 and args[2]=="native-fused":nav=load("res://scripts/field/maps/experimental_native_fused_navigation.gd").new()
 if args.size()==3 and args[2]=="native-obstacles":nav=load("res://scripts/field/maps/experimental_native_obstacle_navigation.gd").new()
 if args.size()==3 and args[2]=="native-batch":nav=load("res://scripts/field/maps/experimental_native_navigation.gd").new()
 if args.size()==3 and args[2]=="native":nav.support=load("res://scripts/field/maps/experimental_native_support.gd").new()
 var started:=Time.get_ticks_usec()
 var code:=nav.configure(data,Rect2(low,high-low),{"gate_main":true},.7,3.4)
 if args.size()==3 and args[2] in ["native","native-batch","native-obstacles","native-fused"]:assert(nav.support.get("kernel")!=null,"NATIVE_KERNEL_NOT_LOADED")
 report.native_support_kernel=args.size()==3 and args[2] in ["native","native-batch","native-obstacles","native-fused"]
 report.navigation_error=code;report.configure_ms=(Time.get_ticks_usec()-started)/1000.;report.nav=nav.statistics()
 if code!=OK:finish(args[1],report);return
 var runtime:=Runtime.new();code=runtime.bind(nav,data);report.runtime_error=code
 if code!=OK:
  assert(runtime.nav==null,"Rejected source must not partially bind runtime")
  finish(args[1],report);return
 var armies:=[]
 for size in [20,512]:
  var battle:=Battle.new();battle.setup(size,61112,Battle.Arms.Kit.SPEAR,true,true,size,false)
  var before:=[]
  for unit in battle.roster:before.append([unit.id,unit.team,unit.kit,unit.hp,unit.mounted,unit.officer])
  var receipt:=Muster.apply(battle,runtime);var invalid:=[]
  if receipt.error==OK:
   for unit in battle.roster:
    assert(before[unit.id]==[unit.id,unit.team,unit.kit,unit.hp,unit.mounted,unit.officer])
    if runtime.blocked(unit.pos,true):invalid.append(unit.id)
  armies.append({"ordinary_per_side":size,"actual_roster":battle.roster.size(),"muster":receipt,"invalid_placements":invalid})
 report.armies=armies
 var routes:=[];var pairs:=[]
 # All endpoints derive from actual author semantics, never prior map coordinates.
 var west:=runtime.centre(data.spawn_regions[0].xz_polygon);var east:=runtime.centre(data.spawn_regions[1].xz_polygon)
 pairs.append([west,east]);pairs.append([east,west]);pairs.append([west,runtime.retreat_goal(0)]);pairs.append([east,runtime.retreat_goal(1)])
 for pair in pairs:
  var p:Vector2=pair[0];var goal:Vector2=pair[1];var steps:=0;var trace:=[];var reason:="step_bound"
  for index in 2000:
   if p.distance_to(goal)<.3:reason="arrived";break
   var waypoint:=runtime.waypoint(p,goal)
   var q:=runtime.travel(p,p.direction_to(waypoint)*minf(.1425,p.distance_to(waypoint)),true)
   if index%100==0:trace.append([index,p.x,p.y])
   if q.distance_squared_to(p)<.00000001:reason="stalled";trace.append({"p":str(p),"waypoint":str(waypoint),"blocked":runtime.blocked(p,true)});break
   assert(not runtime.blocked(q,true));p=q;steps=index+1
  routes.append({"start":str(pair[0]),"goal":str(goal),"end":str(p),"steps":steps,"reason":reason,"trace":trace})
 report.routes=routes;finish(args[1],report)
func finish(path:String,report:Dictionary):
 FileAccess.open(path,FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
 print("NEW_SOURCE_PREFLIGHT_COMPLETED_NOT_AUTOMATIC_PASS ",JSON.stringify(report));quit()
