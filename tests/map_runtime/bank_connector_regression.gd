extends SceneTree
const Navigation:=preload("res://scripts/field/maps/authored_navigation.gd")
const Runtime:=preload("res://scripts/field/maps/authored_field_runtime.gd")
func _initialize():run.call_deferred()
func run():
 var args:=OS.get_cmdline_user_args();assert(args.size()==3)
 var data:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(args[0]));var layout:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(args[1]));var b=layout.bounds
 var nav:=Navigation.new();assert(nav.configure(data,Rect2(Vector2(b.x[0],b.z[0]),Vector2(b.x[1]-b.x[0],b.z[1]-b.z[0])),{"gate_main":true},.7,3.4)==OK)
 var runtime:=Runtime.new();assert(runtime.bind(nav,data)==OK)
 var output:=[]
 for spec in [[Vector2(-20,0),Vector2(40,3),.1425],[Vector2(-13.1905,-8.864645),Vector2(35.18184,9.24607),.5]]:
  var p:Vector2=spec[0];var goal:Vector2=spec[1];var trace:=[]
  for step in 1200:
   var waypoint:=runtime.waypoint(p,goal);var offset:=p.direction_to(waypoint)*minf(float(spec[2]),p.distance_to(waypoint));var q:=runtime.travel(p,offset,true)
   assert(not runtime.blocked(q,true));assert(runtime.can_step(p,q,true));trace.append({"step":step,"p":str(p),"next":str(waypoint),"q":str(q)})
   assert(q.distance_to(p)>.000001 or p.distance_to(goal)<.25,"Legal connector stalled")
   p=q
   if p.distance_to(goal)<.25:break
   assert(offset.length()>.00001,"Legal source connector stalled")
  assert(p.distance_to(goal)<.25,"Continuous legal route did not reach actual goal")
  output.append({"start":str(spec[0]),"goal":str(goal),"end":str(p),"steps":trace.size(),"trace":trace})
 FileAccess.open(args[2],FileAccess.WRITE).store_string(JSON.stringify({"source_sha256":FileAccess.get_sha256(args[0]),"routes":output},"  "))
 print("BANK_CONNECTOR_REAL_SOURCE_CONTINUOUS_PASS ",JSON.stringify({"route_steps":[output[0].steps,output[1].steps],"source_only":"functional004 not new art"}));quit()
