extends SceneTree
const Battle:=preload("res://scripts/field/battle.gd")
const Save:=preload("res://scripts/field/save.gd")
const Navigation:=preload("res://scripts/field/maps/authored_navigation.gd")
const Runtime:=preload("res://scripts/field/maps/authored_field_runtime.gd")
const Muster:=preload("res://scripts/field/maps/authored_muster.gd")
func _initialize():run.call_deferred()
func run():
 var args:=OS.get_cmdline_user_args();assert(args.size()==5)
 var data:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(args[0]));var layout:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(args[1]));var count:=int(args[2]);var steps:=int(args[3]);var output:=args[4]
 var b=layout.bounds;var bounds:=Rect2(Vector2(b.x[0],b.z[0]),Vector2(b.x[1]-b.x[0],b.z[1]-b.z[0]))
 var nav:=Navigation.new();var started:=Time.get_ticks_usec();assert(nav.configure(data,bounds,{"gate_main":true},.7,3.4)==OK)
 print("REAL_MAP_GRAPH_READY ",JSON.stringify(nav.statistics()))
 var runtime:=Runtime.new();assert(runtime.bind(nav,data)==OK)
 var route_probe:=Vector2(-20,0);var route_goal:=Vector2(40,3);var route_steps:=0;var progress_trace:=[]
 for step in 1000:
  var next:=runtime.waypoint(route_probe,route_goal)
  var moved:=runtime.travel(route_probe,route_probe.direction_to(next)*minf(.1425,route_probe.distance_to(next)),true)
  assert(not runtime.blocked(moved,true));route_probe=moved;route_steps=step+1
  if step%100==0:progress_trace.append([step,route_probe.x,route_probe.y])
  if route_probe.distance_to(route_goal)<.25:break
 assert(route_probe.distance_to(route_goal)<.25,"CONTINUOUS_SOURCE_ROUTE_STALLED "+str(route_probe))
 print("CONTINUOUS_SOURCE_TRAVEL_PASS ",JSON.stringify({"steps":route_steps,"end":str(route_probe),"trace":progress_trace,"no_direct_position_assignment":"every step passed real runtime.travel"}))
 var battle:=Battle.new();battle.setup(count,61112,Battle.Arms.Kit.SPEAR,true,true,count,false)
 var before:=[]
 for u in battle.roster:before.append([u.id,u.team,u.kit,u.hp,u.mount_hp,u.mounted,u.officer,u.hero])
 var receipt=Muster.apply(battle,runtime);assert(receipt.error==OK,JSON.stringify(receipt));assert(battle.roster.size()==before.size())
 for u in battle.roster:
  assert([u.id,u.team,u.kit,u.hp,u.mount_hp,u.mounted,u.officer,u.hero]==before[u.id],"Initial map placement changed combatants/statistics")
  assert(not runtime.blocked(u.pos,true),"Spawn outside source support or inside real obstacle")
 assert(Save.snapshot(battle).version==5);assert(Save.save(battle)==ERR_UNAVAILABLE,"Do not overwrite legacy quick slot")
 var input_positions:=[]
 for u in battle.roster:input_positions.append(u.pos)
 FileAccess.open(output+".initial.json",FileAccess.WRITE).store_string(JSON.stringify(receipt,"  "));print("REAL_INITIAL_MUSTER_COMPLETE ",JSON.stringify(receipt))
 battle.start();var command_count:=0;var checkpoints:=[]
 for request in steps:
  if request==5 and battle.command(0,Battle.Mission.HOLD,Battle.Channel.FLAG):command_count+=1
  if request==80 and battle.command(0,Battle.Mission.PRESS,Battle.Channel.FLAG):command_count+=1
  battle.step()
  if request%100==99:
   var row={"sample_unit_pos":str(battle.roster[0].pos),"company_aim":str(battle.companies[0].aim),"sample_next":str(runtime.waypoint(battle.roster[0].pos,battle.companies[0].aim)),"requests":request+1,"tick":battle.tick,"attacks":battle.attacks,"hits":battle.hits.duplicate(),"losses":battle.losses.duplicate(),"hero_hp":battle.hero.hp};checkpoints.append(row);print("REAL_PRODUCTION_BATTLE_PROGRESS ",JSON.stringify(row))
  if battle.result!="":break
 var invalid:=[];var moved:=0
 for u in battle.roster:
  if u.pos.distance_to(input_positions[u.id])>.1:moved+=1
  if battle.active(u) and runtime.blocked(u.pos,true):invalid.append(u.id)
 var unit_states:=[]
 for u in battle.roster:unit_states.append({"id":u.id,"team":u.team,"pos":str(u.pos),"state":u.state,"target":u.target,"squad":u.squad,"facing":str(u.facing),"station":str(u.station),"officer":u.officer,"hero":u.hero})
 var report={"unit_states":unit_states,"source_sidecar_sha256":FileAccess.get_sha256(args[0]),"source_status":data.status,"map_identity":runtime.identity(),"initial_setup":receipt,"ordinary_per_side":Array(battle.ordinary_counts),"roster":battle.roster.size(),"requested_steps":steps,"actual_tick":battle.tick,"attacks":battle.attacks,"hits":battle.hits.duplicate(),"losses":battle.losses.duplicate(),"escaped":battle.escaped.duplicate(),"hero_hp":battle.hero.hp,"actual_result":battle.result,"units_moved":moved,"active_units_invalid_support_or_obstacle":invalid,"accepted_command_calls":command_count,"orders_delivered":battle.messages_arrived,"checkpoints":checkpoints,"elapsed_ms":(Time.get_ticks_usec()-started)/1000.,"gpu":"NOT_RUN","performance":"CPU_INSTRUMENTED_NOT_FPS","mode":"INTERNAL_OPEN_GATE_NO_RAM_NO_SIEGE_OR_WORLD_OBJECTIVE; ordinary/hero/officer stats not altered by setup"}
 FileAccess.open(output,FileAccess.WRITE).store_string(JSON.stringify(report,"  "));print("REAL_PRODUCTION_BATTLE_RESULT ",JSON.stringify(report))
 assert(invalid.is_empty(),"Real movement left authored legal space")
 quit()
