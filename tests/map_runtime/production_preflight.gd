extends SceneTree
const Obstacles:=preload("res://scripts/field/maps/authored_obstacles.gd")
const Support:=preload("res://scripts/field/maps/authored_support.gd")
func _initialize():run.call_deferred()
func run():
 var args:=OS.get_cmdline_user_args();assert(args.size()==2)
 var source:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(args[0]));var started:=Time.get_ticks_usec()
 var map:=Support.new();var result=map.configure(source.surfaces)
 if result!=OK:push_error("ACTUAL_SOURCE_SUPPORT_REJECTED "+str(result));quit(1);return
 var blockers:=Obstacles.new();var solids:Array=source.get("solids",[]);assert(blockers.configure(solids)==OK)
 var rows:=[];var bridge:=[]
 for x in [-10.,-7.,-6.9,0.,6.9,7.,10.]:
  var id="west_terrace" if x<=-7 else "east_terrace" if x>=7 else "bridge_main_deck"
  bridge.append({"xz":[x,0],"surface":id,"support":map.support(Vector2(x,0),id)})
 for spawn in source.spawn_regions:
  var polygon:=PackedVector2Array();var low:=Vector2(INF,INF);var high:=Vector2(-INF,-INF)
  for p in spawn.xz_polygon:var v:=Vector2(p[0],p[1]);polygon.append(v);low=low.min(v);high=high.max(v)
  var accepted:=[];var rejected:=0
  var x:=low.x+.75
  while x<=high.x-.75:
   var z:=low.y+.75
   while z<=high.y-.75:
    var p:=Vector2(x,z)
    if Geometry2D.is_point_in_polygon(p,polygon) and not(z>=spawn.reserved_corridor_z[0]-.6 and z<=spawn.reserved_corridor_z[1]+.6):
     var hit=map.support(p)
     var valid=hit.error==OK
     if valid and blockers.obstruction(hit.position,.45,1.9).blocked:valid=false
     for delta in [Vector2(.45,0),Vector2(-.45,0),Vector2(0,.45),Vector2(0,-.45)]:
      if map.support(p+delta).error!=OK:valid=false
     if valid:accepted.append([x,z])
     else:rejected+=1
    z+=1.25
   x+=1.25
  rows.append({"team":spawn.team,"region":spawn.id,"candidate_count":accepted.size(),"rejected_no_support":rejected,"first_512_if_available":accepted.slice(0,512),"scope":"SUPPORT_CORRIDOR_AND_AVAILABLE_SOLIDS; VEGETATION_SOLIDS_PENDING_NOT_FINAL_MUSTER"})
 var report={"source_sha256":FileAccess.get_sha256(args[0]),"author_source_sha256":source.authored_source_sha256,"source_status":source.status,"support_statistics":map.statistics(),"obstacle_statistics":blockers.statistics(),"elapsed_ms":(Time.get_ticks_usec()-started)/1000.,"bridge":bridge,"candidates":rows,"scene_acceptance":"NOT_RUN","final_navigation":"PREFLIGHT_SOURCE_ONLY_NOT_FINAL_NAVIGATION","battle":"NOT_RUN"}
 FileAccess.open(args[1],FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
 print("PRODUCTION_V2_SOURCE_PREFLIGHT ",JSON.stringify({"stats":map.statistics(),"candidate_counts":[rows[0].candidate_count,rows[1].candidate_count],"elapsed_ms":report.elapsed_ms,"final_navigation":"NOT_ACCEPTED_PENDING_SOLIDS"}));quit()
