extends SceneTree
const Navigation:=preload("res://scripts/field/maps/authored_navigation.gd")
func _initialize():run.call_deferred()
func run():
 var args:=OS.get_cmdline_user_args();assert(args.size()==3)
 var data:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(args[0]));var layout:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(args[1]));var b=layout.bounds
 var bounds:=Rect2(Vector2(b.x[0],b.z[0]),Vector2(b.x[1]-b.x[0],b.z[1]-b.z[0]))
 var started:=Time.get_ticks_usec();var nav:=Navigation.new();var result=nav.configure(data,bounds,{"gate_main":true})
 if result!=OK:push_error("ACTUAL_NAV_SOURCE_REJECTED "+str(result));quit(1);return
 var paths:=[]
 for pair in [[Vector2(-20,0),Vector2(40,3)],[Vector2(40,3),Vector2(80,3)],[Vector2(-20,0),Vector2(-50,0)]]:
  var route=nav.route(pair[0],pair[1]);var length:=0.
  for i in range(1,route.size()):length+=route[i-1].distance_to(route[i])
  paths.append({"from":str(pair[0]),"to":str(pair[1]),"points":route.size(),"length_m":length,"route":Array(route)})
 var report={"sidecar_sha256":FileAccess.get_sha256(args[0]),"source_status":data.status,"elapsed_ms":(Time.get_ticks_usec()-started)/1000.,"statistics":nav.statistics(),"paths":paths,"gate_open":true,"scope":"REAL_SOURCE_CONNECTED_ROUTE_QUERY_ONLY; no actual Battle, art or FPS claim"}
 FileAccess.open(args[2],FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
 print("PRODUCTION_MAP_ROUTE_QUERY ",JSON.stringify({"path_sizes":[paths[0].points,paths[1].points,paths[2].points],"elapsed_ms":report.elapsed_ms,"statistics":nav.statistics()}));quit()
