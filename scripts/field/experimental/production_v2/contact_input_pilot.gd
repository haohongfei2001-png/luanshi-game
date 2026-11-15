extends Node
## Default-OFF input-only pilot for an explicitly bound new map_runtime.
## No actor cache, no position/HP writes, no Battle.step/action calls, no old Ground.
var field:Node
var recorder:Node
var active:=false
var started_us:=0
var next_plan_us:=0
var target_id:=-1
var route:Array[Vector2]=[]
var cursor:=0
var held_attack:=false
var held_sprint:=false
var attack_until_us:=0
var next_attack_us:=0
var keydowns:=0
var held_physics_ticks:=0
var finishing_reason:=""
var finish_after_us:=0
var initial_impacts:=0
const DURATION_US:=30000000
func begin(controller:Node,wall_recorder:Node)->Error:
 if active:return ERR_ALREADY_IN_USE
 if controller==null or wall_recorder==null or not wall_recorder.active:return ERR_INVALID_PARAMETER
 var battle=controller.battle
 if battle==null or battle.map_runtime==null or battle.map_runtime.is_legacy:return ERR_UNAVAILABLE
 if not battle.started or battle.result!="" or controller.paused:return ERR_UNAVAILABLE
 for action in ["move_left","move_right","move_up","move_down","attack","field_sprint"]:
  if Input.is_action_pressed(action):return ERR_ALREADY_IN_USE
 field=controller;recorder=wall_recorder;active=true;started_us=Time.get_ticks_usec();next_plan_us=0;target_id=-1;route=[];cursor=0;held_attack=false;held_sprint=false;attack_until_us=0;next_attack_us=0;keydowns=0;held_physics_ticks=0;finishing_reason="";finish_after_us=0;initial_impacts=battle.hero.impacts
 process_priority=field.process_priority-1;process_physics_priority=field.process_physics_priority+1
 emit({"kind":"production_input_contract","map_identity":battle.map_runtime.identity(),"duration_us":DURATION_US,"post_death_visual_tail_us":2500000,"scope":"REAL_CONTROLLER_INPUT_ONLY; no model/cache contract; no survival/hit guarantee"})
 return OK
func emit(row:Dictionary)->void:
 if is_instance_valid(recorder) and recorder.active:
  row["monotonic_us"]=Time.get_ticks_usec();row["tick"]=field.battle.tick if is_instance_valid(field) else -1;recorder.write(row)
func _physics_process(_delta:float)->void:
 if active and held_attack and Input.is_physical_key_pressed(KEY_J):held_physics_ticks+=1
func _process(_delta:float)->void:
 if not active:return
 if not is_instance_valid(field) or not is_instance_valid(recorder):finish("dependency_removed");return
 if not recorder.active:finish("recorder_stopped");return
 var now:=Time.get_ticks_usec();var battle=field.battle;var hero=battle.hero;var map=battle.map_runtime
 if not finishing_reason.is_empty():
  if now>=finish_after_us:finish(finishing_reason)
  return
 if hero.hp<=0 or battle.result!="":
  release_inputs();finishing_reason="actual_battle_ended";finish_after_us=now+2500000
  emit({"kind":"production_actual_outcome_tail","hero_hp":hero.hp,"battle_result":battle.result,"actual_impacts":hero.impacts,"note":"Input released; presentation may finish death without advancing Battle"});return
 if field.paused:finish("actual_paused");return
 if now-started_us>=DURATION_US:finish("input_time_bound");return
 if target_id<0 or battle.roster[target_id].hp<=0 or now>=next_plan_us:
  var plan:=plan_route(battle);next_plan_us=now+1000000;cursor=0
  if not plan.reachable:emit({"kind":"production_route_failure","plan":plan});finish("no_legal_new_map_route");return
  target_id=plan.target_id;route=plan.points
  emit({"kind":"production_route_plan","target_id":target_id,"query_points":route.size(),"direct_distance":hero.pos.distance_to(battle.roster[target_id].pos),"scope":"queries only, never applied as positions"})
 var enemy=battle.roster[target_id];var distance:float=hero.pos.distance_to(enemy.pos);var reach:float=battle._basic(hero).reach
 var clear:bool=map.clear_shot(hero.pos,enemy.pos,battle.gate_hp<=0)
 var attack_possible:=distance<=reach*1.05 and clear
 while cursor<route.size() and hero.pos.distance_to(route[cursor])<.6:cursor+=1
 var waypoint:Vector2=route[cursor] if cursor<route.size() else enemy.pos
 var direction:Vector2=hero.pos.direction_to(waypoint) if not (distance<=reach*.85 and clear) else Vector2.ZERO
 motion(direction.rotated(field.camera_yaw)*.8)
 sprint(distance>8.0 and now-started_us>1800000)
 var aim:Vector2=enemy.pos if attack_possible else hero.pos+direction*2.0
 var logical:Vector2=field.camera.unproject_position(map.unit_point(aim))
 var native:Vector2=field.get_viewport().get_final_transform()*logical
 var event:=InputEventMouseMotion.new();event.position=native;event.global_position=native;Input.parse_input_event(event);Input.flush_buffered_events()
 if attack_possible and now>=next_attack_us:attack_until_us=now+600000;next_attack_us=now+800000
 attack(attack_possible and now<attack_until_us)
 var observed:Vector2=field.get_viewport().get_mouse_position()
 emit({"kind":"production_real_input","target_id":target_id,"distance":distance,"reach":reach,"clear_shot":clear,"hero_pos":[hero.pos.x,hero.pos.y],"enemy_pos":[enemy.pos.x,enemy.pos.y],"requested_logical_pointer":[logical.x,logical.y],"requested_native_pointer":[native.x,native.y],"observed_pointer":[observed.x,observed.y],"walk_aim":str(field._aim_point(observed,false)),"attack_aim":str(field._aim_point(observed,true)),"actual_input":str(Input.get_vector("move_left","move_right","move_up","move_down")),"actual_J_held":Input.is_physical_key_pressed(KEY_J),"hero_state":hero.state,"hero_timer":hero.timer,"hero_hp":hero.hp,"actual_impacts":hero.impacts,"actual_received":hero.received,"camera_yaw":field.camera_yaw,"scope":"not benchmark; no fabricated contact"})
static func plan_route(battle)->Dictionary:
 var map=battle.map_runtime;var hero=battle.hero;var choices:Array=[];var attempts:Array=[]
 for unit in battle.roster:
  if unit.team!=hero.team and battle.active(unit):choices.append({"id":unit.id,"distance":hero.pos.distance_to(unit.pos)})
 choices.sort_custom(func(a,b):return a.distance<b.distance if a.distance!=b.distance else a.id<b.id)
 for i in mini(16,choices.size()):
  var target=battle.roster[choices[i].id];var p:Vector2=hero.pos;var points:Array[Vector2]=[]
  var diagnostic:Dictionary={"target_id":target.id,"target_pos":[target.pos.x,target.pos.y],"reason":"step_budget"}
  for step in 256:
   if p.distance_to(target.pos)<1.2:return {"reachable":true,"target_id":target.id,"points":points}
   var waypoint:Vector2=map.waypoint(p,target.pos)
   var distance:=p.distance_to(waypoint)
   var q:Vector2=map.travel(p,p.direction_to(waypoint)*minf(.5,distance),battle.gate_hp<=0)
   var blocked:bool=map.blocked(q,battle.gate_hp<=0)
   diagnostic.merge({"step":step,"p":[p.x,p.y],"waypoint":[waypoint.x,waypoint.y],"q":[q.x,q.y],"waypoint_distance":distance,"blocked":blocked},true)
   if q.distance_to(p)<.02 or blocked:
    diagnostic.reason="blocked_query" if blocked else ("waypoint_equals_current" if distance<.0001 else "travel_stalled")
    break
   points.append(q);p=q
  attempts.append(diagnostic)
 return {"reachable":false,"reason":"bounded16_actual_targets_no_legal_route","hero_pos":[hero.pos.x,hero.pos.y],"battle_tick":battle.tick,"attempts":attempts}
func motion(wanted:Vector2)->void:
 for spec in [["move_left",maxf(-wanted.x,0.)],["move_right",maxf(wanted.x,0.)],["move_up",maxf(-wanted.y,0.)],["move_down",maxf(wanted.y,0.)]]:
  if is_equal_approx(Input.get_action_raw_strength(spec[0]),spec[1]):continue
  var e:=InputEventAction.new();e.action=spec[0];e.pressed=spec[1]>0.;e.strength=spec[1];Input.parse_input_event(e);Input.flush_buffered_events()
  emit({"kind":"production_actual_key","action":spec[0],"pressed":e.pressed,"strength":e.strength})
func sprint(wanted:bool)->void:
 if wanted==held_sprint:return
 var e:=InputEventAction.new();e.action="field_sprint";e.pressed=wanted;e.strength=1. if wanted else 0.;Input.parse_input_event(e);Input.flush_buffered_events();held_sprint=wanted
 emit({"kind":"production_actual_key","action":"field_sprint","pressed":wanted})
func attack(wanted:bool)->void:
 if wanted==held_attack:return
 var e:=InputEventKey.new();e.keycode=KEY_J;e.physical_keycode=KEY_J;e.pressed=wanted;Input.parse_input_event(e);Input.flush_buffered_events();held_attack=wanted
 if wanted:keydowns+=1
 emit({"kind":"production_actual_key","key":"J","pressed":wanted})
func release_inputs()->void:motion(Vector2.ZERO);sprint(false);attack(false)
func finish(reason:String)->void:
 if not active:return
 release_inputs()
 if is_instance_valid(field):
  var b=field.battle
  emit({"kind":"production_input_result","reason":reason,"hero_hp":b.hero.hp,"battle_result":b.result,"paused":field.paused,"hero_impacts_delta":b.hero.impacts-initial_impacts,"actual_J_downs":keydowns,"observed_held_physics_ticks":held_physics_ticks,"inputs_released":not Input.is_action_pressed("move_left") and not Input.is_action_pressed("move_right") and not Input.is_action_pressed("move_up") and not Input.is_action_pressed("move_down") and not Input.is_action_pressed("field_sprint") and not Input.is_physical_key_pressed(KEY_J),"scope":"real input result, not survival/art/GPU performance acceptance"})
 if is_instance_valid(recorder) and recorder.active:recorder.stop(reason)
 active=false
func _exit_tree()->void:
 if active:finish("pilot_unloaded")
