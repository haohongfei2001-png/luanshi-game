extends SceneTree
const Battle:=preload("res://scripts/field/battle.gd")
const Save:=preload("res://scripts/field/save.gd")
const Navigation:=preload("res://scripts/field/maps/authored_navigation.gd")
const Runtime:=preload("res://scripts/field/maps/authored_field_runtime.gd")
const Muster:=preload("res://scripts/field/maps/authored_muster.gd")
func memory_receipt()->Dictionary:
 var result:={"godot_static_bytes":OS.get_static_memory_usage(),"godot_static_peak_bytes":OS.get_static_memory_peak_usage()}
 if FileAccess.file_exists("/proc/self/status"):
  for line in FileAccess.get_file_as_string("/proc/self/status").split("\n"):
   if line.begins_with("VmRSS:") or line.begins_with("VmHWM:"):
    var pieces:=line.split(" ",false);result[pieces[0].trim_suffix(":")+"_KiB"]=int(pieces[1])
 return result
# Passive end-of-tick observations. These never call a query or mutate battle state.
# This is a tick-ordered observable trace, not a claim about intra-tick event order.
func combat_observation(battle,previous_health:Array,command_attempt:Variant)->Dictionary:
 var changes:=[]
 for u in battle.roster:
  var health:=[u.hp,u.mount_hp,u.impacts,u.received]
  if previous_health.size()<=u.id or health!=previous_health[u.id]:changes.append([u.id,health])
  if previous_health.size()>u.id:previous_health[u.id]=health
  else:previous_health.append(health)
 var companies:=[]
 for c in battle.companies:companies.append([c.team,c.slot,c.mission,c.standing,c.serial,c.delivered,c.regrouping])
 var orders:=[]
 for o in battle.orders:orders.append([o.squad,o.serial,o.mission,o.channel,o.pos,o.age,o.delay,o.leg,o.due,o.refused])
 return {"tick":battle.tick,"attacks":battle.attacks,"blocked_hits":battle.blocked_hits,"hits":battle.hits.duplicate(),"losses":battle.losses.duplicate(),"escaped":battle.escaped.duplicate(),"projectiles":battle.arrow_count,"orders_delivered":battle.messages_arrived,"orders_lost":battle.messages_lost,"orders_refused":battle.messages_refused,"health_changes":changes,"companies":companies,"pending_orders":orders,"command_attempt":command_attempt,"result":battle.result}
# Typed state evidence, not a claim that this experiment implements Save.restore.
# Keep the exact original Save payload separate from map fields it does not include.
func save_variant_observation(battle,output:String)->Dictionary:
 var prefix:=output+".tick-%04d"%battle.tick
 var payload:PackedByteArray=var_to_bytes(Save.snapshot(battle))
 var file:=FileAccess.open(prefix+".snapshot.variant",FileAccess.WRITE);file.store_buffer(payload);file.close()
 var units:=[];var homes:=[]
 for u in battle.roster:units.append([u.station,u.wall_post,u.engineer,u.ram_station])
 for c in battle.companies:homes.append(c.home)
 var mapped:={"schema":1,"mode":"open_gate_field_no_campaign","units":units,"company_homes":homes,"muster_slots":battle.muster_slots.duplicate(),"sprinting":battle.sprinting,"agent_radius":battle.map_runtime.nav._radius,"agent_height":battle.map_runtime.nav._height}
 var supplement:PackedByteArray=var_to_bytes(mapped)
 file=FileAccess.open(prefix+".mapped-state.variant",FileAccess.WRITE);file.store_buffer(supplement);file.close()
 return {"tick":battle.tick,"snapshot_bytes":payload.size(),"snapshot_sha256":FileAccess.get_sha256(prefix+".snapshot.variant"),"mapped_state_bytes":supplement.size(),"mapped_state_sha256":FileAccess.get_sha256(prefix+".mapped-state.variant")}
func write_event_observation(json_file:FileAccess,variant_file:FileAccess,row:Dictionary):
 json_file.store_line(JSON.stringify(row))
 var payload:PackedByteArray=var_to_bytes(row)
 variant_file.store_32(payload.size());variant_file.store_buffer(payload)
func _initialize():run.call_deferred()
func run():
 var args:=OS.get_cmdline_user_args();assert(args.size() in [5,6])
 var data:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(args[0]));var layout:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(args[1]));var count:=int(args[2]);var steps:=int(args[3]);var output:=args[4]
 var b=layout.bounds;var bounds:=Rect2(Vector2(b.x[0],b.z[0]),Vector2(b.x[1]-b.x[0],b.z[1]-b.z[0]))
 var nav:=Navigation.new()
 if args.size()==6 and args[5]=="profile-native-fused":nav=load("res://scripts/field/maps/experimental_native_fused_navigation.gd").new()
 if args.size()==6 and args[5]=="profile-native-obstacles":nav=load("res://scripts/field/maps/experimental_native_obstacle_navigation.gd").new()
 if args.size()==6 and args[5]=="profile-native-batch":nav=load("res://scripts/field/maps/experimental_native_navigation.gd").new()
 if args.size()==6 and args[5]=="profile-native":nav.support=load("res://scripts/field/maps/experimental_native_support.gd").new()
 nav.support.exact_cache_enabled=not (args.size()==6 and args[5]=="profile-nocache");var started:=Time.get_ticks_usec();assert(nav.configure(data,bounds,{"gate_main":true},.7,3.4)==OK)
 if args.size()==6 and args[5] in ["profile-native","profile-native-batch","profile-native-obstacles","profile-native-fused"]:assert(nav.support.get("kernel")!=null,"NATIVE_KERNEL_NOT_LOADED")
 var graph_end:=Time.get_ticks_usec()
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
 var probe_end:=Time.get_ticks_usec()
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
 var muster_end:=Time.get_ticks_usec()
 runtime.profile_enabled=args.size()==6;nav.support.profile_enabled=runtime.profile_enabled;nav.obstacles.profile_enabled=runtime.profile_enabled
 if args.size()==6 and args[5] in ["profile-native","profile-native-batch","profile-native-obstacles","profile-native-fused"]:nav.support.kernel.reset_profile()
 var has_native_body:bool=nav.obstacles.get_script().resource_path.ends_with("experimental_native_obstacles.gd") and nav.obstacles.get("kernel")!=null
 if has_native_body:nav.obstacles.kernel.reset_profile()
 battle.start();var command_count:=0;var checkpoints:=[]
 var trace_enabled:=OS.get_environment("HF08_CAPTURE_COMBAT_TRACE")=="1"
 var trace_file:FileAccess;var variant_trace_file:FileAccess;var previous_health:=[];var snapshot_checkpoints:=[];var variant_checkpoints:=[]
 if trace_enabled:
  trace_file=FileAccess.open(output+".events.jsonl",FileAccess.WRITE);assert(trace_file!=null)
  variant_trace_file=FileAccess.open(output+".events.variant-stream",FileAccess.WRITE);assert(variant_trace_file!=null)
  write_event_observation(trace_file,variant_trace_file,combat_observation(battle,previous_health,null))
  variant_checkpoints.append(save_variant_observation(battle,output))
  snapshot_checkpoints.append([battle.tick,JSON.stringify(Save.snapshot(battle)).sha256_text()])
 for request in steps:
  var command_attempt:Variant=null
  if request in [5,80]:
   var mission:=Battle.Mission.HOLD if request==5 else Battle.Mission.PRESS
   var accepted:=battle.command(0,mission,Battle.Channel.FLAG)
   if accepted:command_count+=1
   command_attempt={"request":request,"squad":0,"mission":mission,"channel":Battle.Channel.FLAG,"accepted":accepted}
  battle.step()
  if trace_enabled:
   write_event_observation(trace_file,variant_trace_file,combat_observation(battle,previous_health,command_attempt))
   if request%100==99:
    trace_file.flush();variant_trace_file.flush();snapshot_checkpoints.append([battle.tick,JSON.stringify(Save.snapshot(battle)).sha256_text()]);variant_checkpoints.append(save_variant_observation(battle,output))
  if request%100==99:
   var row={"sample_unit_pos":str(battle.roster[0].pos),"company_aim":str(battle.companies[0].aim),"sample_next":str(runtime.waypoint(battle.roster[0].pos,battle.companies[0].aim)),"requests":request+1,"tick":battle.tick,"attacks":battle.attacks,"hits":battle.hits.duplicate(),"losses":battle.losses.duplicate(),"hero_hp":battle.hero.hp};checkpoints.append(row);print("REAL_PRODUCTION_BATTLE_PROGRESS ",JSON.stringify(row))
  if battle.result!="":break
 var simulation_end:=Time.get_ticks_usec()
 var native_support_battle:Dictionary=nav.support.kernel.statistics() if args.size()==6 and args[5] in ["profile-native","profile-native-batch","profile-native-obstacles","profile-native-fused"] else {}
 var native_body_battle:Dictionary=nav.obstacles.kernel.statistics() if has_native_body else {}
 runtime.profile_enabled=false;nav.support.profile_enabled=false;nav.obstacles.profile_enabled=false
 var invalid:=[];var moved:=0
 for u in battle.roster:
  if u.pos.distance_to(input_positions[u.id])>.1:moved+=1
  if battle.active(u) and runtime.blocked(u.pos,true):invalid.append(u.id)
 var unit_states:=[]
 for u in battle.roster:unit_states.append({"id":u.id,"team":u.team,"pos":str(u.pos),"state":u.state,"target":u.target,"squad":u.squad,"facing":str(u.facing),"station":str(u.station),"officer":u.officer,"hero":u.hero})
 var report={"unit_states":unit_states,"source_sidecar_sha256":FileAccess.get_sha256(args[0]),"source_status":data.status,"map_identity":runtime.identity(),"initial_setup":receipt,"ordinary_per_side":Array(battle.ordinary_counts),"roster":battle.roster.size(),"requested_steps":steps,"actual_tick":battle.tick,"attacks":battle.attacks,"hits":battle.hits.duplicate(),"losses":battle.losses.duplicate(),"escaped":battle.escaped.duplicate(),"hero_hp":battle.hero.hp,"actual_result":battle.result,"units_moved":moved,"active_units_invalid_support_or_obstacle":invalid,"accepted_command_calls":command_count,"orders_delivered":battle.messages_arrived,"checkpoints":checkpoints,"elapsed_ms":(Time.get_ticks_usec()-started)/1000.,"gpu":"NOT_RUN","performance":"CPU_INSTRUMENTED_NOT_FPS","mode":"INTERNAL_OPEN_GATE_NO_RAM_NO_SIEGE_OR_WORLD_OBJECTIVE; ordinary/hero/officer stats not altered by setup"}
 var full_snapshot:=JSON.stringify(Save.snapshot(battle))
 FileAccess.open(output+".snapshot.json",FileAccess.WRITE).store_string(full_snapshot)
 report["full_snapshot_sha256"]=full_snapshot.sha256_text()
 if trace_enabled:
  trace_file.close();variant_trace_file.close()
  if variant_checkpoints[-1].tick!=battle.tick:variant_checkpoints.append(save_variant_observation(battle,output))
  report["variant_checkpoint_hashes"]=variant_checkpoints
  report["variant_trace_sha256"]=FileAccess.get_sha256(output+".events.variant-stream")
  report["snapshot_encoding_note"]="snapshot.json is diagnostic JSON, not type-preserving or load proof. *.snapshot.variant is exact original Save.snapshot via var_to_bytes; *.mapped-state.variant is separate missing-field evidence, not merged into Save."
  report["combat_trace_sha256"]=FileAccess.get_sha256(output+".events.jsonl")
  report["combat_trace_scope"]="Passive end-of-tick observations, not intra-tick event order"
  report["snapshot_checkpoint_hashes"]=snapshot_checkpoints
 report["native_support_kernel"]=nav.support.get_script().resource_path.ends_with("experimental_native_support.gd") and nav.support.get("kernel")!=null
 report["phase_ms"]={"navigation_configure":(graph_end-started)/1000.,"continuous_probe":(probe_end-graph_end)/1000.,"setup_muster_validation":(muster_end-probe_end)/1000.,"400_or_actual_steps_including_progress_queries":(simulation_end-muster_end)/1000.,"final_validation_snapshot":(Time.get_ticks_usec()-simulation_end)/1000.}
 report["memory"]=memory_receipt()
 report["native_query_profile_battle_only"]=native_support_battle
 report["native_obstacle_profile_battle_only"]=native_body_battle
 report["native_fused_enabled"]=args.size()==6 and args[5]=="profile-native-fused"
 report["native_query_profile"]=nav.support.kernel.statistics() if report.native_support_kernel else {}
 report["native_batch_enabled"]=args.size()==6 and args[5] in ["profile-native-batch","profile-native-obstacles","profile-native-fused"]
 report["native_obstacle_kernel"]=nav.obstacles.get_script().resource_path.ends_with("experimental_native_obstacles.gd") and nav.obstacles.get("kernel")!=null
 report["exact_support_cache"]={"enabled":nav.support.exact_cache_enabled,"capacity":nav.support.EXACT_CACHE_CAPACITY,"final_entries":nav.support._exact_cache.size(),"coordinates":"exact Vector2 without quantization"}
 report["query_profile"]={"enabled_during_battle_only":args.size()==6,"runtime":runtime.profile,"support":nav.support.profile,"obstacles":nav.obstacles.profile,"scope":"INCLUSIVE_NESTED_TIMES_NOT_ADDITIVE; CPU_SHARED_ENV_NOT_GPU_FPS"}
 FileAccess.open(output,FileAccess.WRITE).store_string(JSON.stringify(report,"  "));print("REAL_PRODUCTION_BATTLE_RESULT ",JSON.stringify(report))
 assert(invalid.is_empty(),"Real movement left authored legal space")
 quit()
