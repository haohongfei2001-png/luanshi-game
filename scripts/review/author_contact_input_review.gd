extends "res://scripts/review/author_dynamic_review.gd"
## Independent default-OFF contact diagnostic. Does not change frozen18s harness.
const Planner=preload("res://scripts/review/author_contact_route.gd")
const CONTACT_DURATION_US:=30000000
var route:Dictionary={}
var target_id:=-1
var path_index:=0
var next_plan_us:=0
var held_motion:=Vector2.ZERO
var held_sprint:=false
var held_guard:=false
var guard_until_us:=0
var next_attack_us:=0
var attack_until_us:=0
func begin(game_field: Node, configured_actor: Node3D, wall_recorder: Node, cache_bytes: int, phase_evidence: Dictionary = {}) -> Error:
 if active:return ERR_ALREADY_IN_USE
 if not is_instance_valid(game_field) or not is_instance_valid(configured_actor) or not is_instance_valid(wall_recorder):return ERR_INVALID_PARAMETER
 if not wall_recorder.active or not game_field.battle.started or game_field.paused or game_field.battle.result != "":return ERR_UNAVAILABLE
 if game_field.battle.vehicle != 0 or game_field.battle.hero.kit != Contract.Arms.Kit.SPEAR:return ERR_INVALID_PARAMETER
 if game_field.view.review_hidden_actor_id != -1:return ERR_ALREADY_IN_USE
 # Never release input belonging to a user or another diagnostic.
 for name in ["move_left","move_right","move_up","move_down","attack","field_sprint","guard"]:
  if Input.is_action_pressed(name):return ERR_ALREADY_IN_USE
 target_id=-1;route={};path_index=0;next_plan_us=0;held_motion=Vector2.ZERO;held_sprint=false;held_guard=false;guard_until_us=0;next_attack_us=0;attack_until_us=0
 field=game_field;actor=configured_actor;recorder=wall_recorder
 binding.enabled=true;binding.thrust_peak=validated_peak(actor.metadata,phase_evidence)
 _previous_stage="";_previous_tick=-1;_previous_state=-1;releases_observed=0;binding.walk_phase=0.0;actual_attack_keydowns=0;observed_key_held_ticks=0;_last_body_frame=-1
 _prior_follow=field.follow;field.follow=true
 process_priority=field.process_priority-1
 process_physics_priority=field.process_physics_priority+1
 _initial_impacts=field.battle.hero.impacts;_initial_attacks=field.battle.attacks
 started_us=Time.get_ticks_usec();active=true;_owns_slot=true
 recorder.write({"kind":"author_dynamic_contract","monotonic_us":started_us,"duration_us":CONTACT_DURATION_US,"cache_payload_bytes":cache_bytes,"cache_size_note":"actual external evaluated cache around224MB, not35MB source blend; caller must pass measured bytes","scope":"DEFAULT_OFF_REAL_INPUT_CONTACT_ROUTE_ONE_HERO_MIXED_VISUALS","source_peak":binding.thrust_peak,"thrust_timing_source_verified":binding.thrust_peak>0.0,"source_known_failures":["spear_torso_intersection","feet_ground","stride_speed_uncalibrated"],"input":"Ground legal waypoint -> actual four-way analog actions at0.8; sprint beyond8m, normal walk near; native pointer; immediate600ms J within real reach+5percent and clear shot","camera":"existing projection/size unchanged; real follow enabled","performance":"READBACK_INSTRUMENTED_NOT_BENCHMARK","initial_tick":field.battle.tick})
 return OK

func _physics_process(delta:float)->void:
 super._physics_process(delta)
 if active and is_instance_valid(field) and is_instance_valid(recorder):
  var pointer:Vector2=field.get_viewport().get_mouse_position()
  var aim:Vector2=field._aim_point(pointer,false)
  recorder.write({"kind":"author_contact_physics_pointer","tick":field.battle.tick,"monotonic_us":Time.get_ticks_usec(),"actual_controller_pointer":[pointer.x,pointer.y],"actual_ground_hit":[aim.x,aim.y],"actual_attack_aim":str(field._aim_point(pointer,true)),"hero_facing":[field.battle.hero.facing.x,field.battle.hero.facing.y],"actual_camera_movement":str(Input.get_vector("move_left","move_right","move_up","move_down"))})

func _process(_delta:float)->void:
 if not active:return
 if not is_instance_valid(field) or not is_instance_valid(actor) or not is_instance_valid(recorder):finish("dependency_removed");return
 if not recorder.active:finish("recorder_stopped");return
 var b=field.battle;var hero=b.hero;var now=Time.get_ticks_usec()
 if now-started_us>=CONTACT_DURATION_US:finish("contact_route_time_bound");return
 if field.paused or b.result!="" or hero.hp<=0:finish("battle_interrupted");return
 if target_id<0 or b.roster[target_id].hp<=0 or now>=next_plan_us:
  route=Planner.select(b);next_plan_us=now+1000000;path_index=0
  if not route.reachable:
   recorder.write({"kind":"author_contact_route_unavailable","tick":b.tick,"monotonic_us":now,"route":route});finish("no_legal_enemy_route");return
  target_id=int(route.target_id)
  var serialized:Array=[]
  for p in route.points:serialized.append([p.x,p.y])
  recorder.write({"kind":"author_contact_route_plan","tick":b.tick,"monotonic_us":now,"target_id":target_id,"target_pos":route.target_pos,"actual_distance":route.actual_distance,"legal_probe_points":serialized,"probe_length":route.probe_length,"scope":"Ground query only; points are NOT applied to unit"})
 var enemy=b.roster[target_id];var distance:float=hero.pos.distance_to(enemy.pos)
 var reach:float=b._basic(hero).reach
 var clear:bool=Contract.Battle.Ground.clear_shot(hero.pos,enemy.pos,b.gate_hp<=0)
 var in_range:=distance<=reach*.85 and clear
 var attack_possible:=distance<=reach*1.05 and clear
 set_sprint(distance>8.0 and now-started_us>1800000)
 var waypoint:Vector2=enemy.pos
 while path_index<route.points.size() and hero.pos.distance_to(route.points[path_index])<.6:path_index+=1
 if path_index<route.points.size():waypoint=route.points[path_index]
 var direction:Vector2=hero.pos.direction_to(waypoint) if not in_range else Vector2.ZERO
 var motion:=Planner.camera_input(direction,field.camera_yaw)
 set_motion(motion)
 var aim:Vector2=enemy.pos if attack_possible else hero.pos+direction*2.0
 var screen:Vector2=field.camera.unproject_position(Contract.Battle.Ground.unit_point(aim,b.bridgehead))
 var native_screen:=native_pointer_coordinates(field.get_viewport(),screen)
 var pointer:=InputEventMouseMotion.new();pointer.position=native_screen;pointer.global_position=native_screen
 Input.parse_input_event(pointer);Input.flush_buffered_events()
 if attack_possible and now>=next_attack_us:
  attack_until_us=now+600000;next_attack_us=now+800000
 # Do not auto-brace at6m: actual spear slot3 locks GUARD for1.12s and
 # consumed the only approach attack window before a real stagger/death.
 # Leave defensive helper available for future explicitly timed real inputs.
 set_guard(now<guard_until_us)
 var attack:=attack_possible and now<attack_until_us
 set_inputs(false,attack) # inherited method owns only J; held_action stays false
 var sample:Dictionary=binding.update_once(b,actor);field.view.review_hidden_actor_id=binding.hidden_unit_id
 if not RenderingServer.frame_post_draw.is_connected(observe_camera):RenderingServer.frame_post_draw.connect(observe_camera)
 var allowed:Vector2=Contract.Battle.Ground.travel(hero.pos,direction*.5,b.gate_hp<=0,b.bridgehead)
 recorder.write({"kind":"author_contact_route_observation","monotonic_us":now,"tick":b.tick,"target_id":target_id,"actual_distance":distance,"basic_reach":reach,"clear_shot":clear,"waypoint":[waypoint.x,waypoint.y],"hero_pos":[hero.pos.x,hero.pos.y],"enemy_pos":[enemy.pos.x,enemy.pos.y],"requested_camera_input":[motion.x,motion.y],"actual_controller_input":str(Input.get_vector("move_left","move_right","move_up","move_down")),"logical_pointer":[screen.x,screen.y],"actual_controller_pointer":str(field.get_viewport().get_mouse_position()),"current_blocked":Contract.Battle.Ground.blocked(hero.pos,b.gate_hp<=0,b.bridgehead),"allowed_half_metre_probe":[allowed.x,allowed.y],"attack_key_held":held_attack,"sprint_held":held_sprint,"guard_held":held_guard,"guard_cooldown":b.hero_cds[3],"native_event_position":[native_screen.x,native_screen.y],"actual_ground_aim":str(field._aim_point(field.get_viewport().get_mouse_position(),false)),"actual_attack_aim":str(field._aim_point(field.get_viewport().get_mouse_position(),true)),"viewport_final_transform":str(field.get_viewport().get_final_transform()),"hero_state":hero.state,"hero_state_name":Contract.Battle.State.keys()[hero.state],"hero_timer":hero.timer,"hero_hp":hero.hp,"hero_cooldowns":Array(b.hero_cds),"buffered_slot":b.buffered_slot,"hero_impacts":hero.impacts,"hero_received":hero.received,"mapping":sample,"scope":"Input only; actual hero hit counter, no position/HP/Battle writes"})

func set_motion(wanted:Vector2)->void:
 for spec in [["move_left",maxf(-wanted.x,0.)],["move_right",maxf(wanted.x,0.)],["move_up",maxf(-wanted.y,0.)],["move_down",maxf(wanted.y,0.)]]:
  var strength:float=spec[1]
  if is_equal_approx(Input.get_action_raw_strength(spec[0]),strength):continue
  var event:=InputEventAction.new();event.action=spec[0];event.pressed=strength>0.;event.strength=strength
  Input.parse_input_event(event);Input.flush_buffered_events()
  input_receipt({"type":"InputEventAction","action":spec[0],"pressed":event.pressed,"strength":strength})
 held_motion=wanted

func set_guard(wanted:bool)->void:
 if wanted==held_guard:return
 var event:=InputEventKey.new();event.keycode=KEY_SPACE;event.physical_keycode=KEY_SPACE;event.pressed=wanted
 Input.parse_input_event(event);Input.flush_buffered_events();held_guard=wanted
 input_receipt({"type":"InputEventKey","key":KEY_SPACE,"pressed":wanted,"purpose":"actual defensive brace while approaching; no defense state assignment"})

func set_sprint(wanted:bool)->void:
 if wanted==held_sprint:return
 var event:=InputEventAction.new();event.action="field_sprint";event.pressed=wanted;event.strength=1.0 if wanted else 0.0
 Input.parse_input_event(event);Input.flush_buffered_events();held_sprint=wanted
 input_receipt({"type":"InputEventAction","action":"field_sprint","pressed":wanted})

func finish(reason: String = "cancelled") -> void:
 if RenderingServer.frame_post_draw.is_connected(observe_camera):RenderingServer.frame_post_draw.disconnect(observe_camera)
 if active:set_motion(Vector2.ZERO);set_sprint(false);set_guard(false)
 set_inputs(false,false)
 if is_instance_valid(actor):binding.disable(actor)
 if _owns_slot and is_instance_valid(field):
  field.view.review_hidden_actor_id=-1;field.follow=_prior_follow
 _owns_slot=false
 if active and is_instance_valid(recorder) and recorder.active:
  var impact_delta: int = field.battle.hero.impacts-_initial_impacts if is_instance_valid(field) else 0
  recorder.write({"kind":"author_dynamic_result","reason":reason,"monotonic_us":Time.get_ticks_usec(),"wall_seconds":(Time.get_ticks_usec()-started_us)/1000000.0,"hero_impacts_delta":impact_delta,"hit_status":"ACTUAL_HERO_IMPACT_OBSERVED" if impact_delta>0 else "NO_HERO_HIT_OBSERVED","actual_attack_keydown_events":actual_attack_keydowns,"observed_key_held_physics_ticks":observed_key_held_ticks,"pulse_warning":"600ms intended contact pulse may be skipped at low render cadence; only actual emitted input and observed state counts are evidence","observed_release_transitions":releases_observed,"release_sampling":"observed controller ticks; multiple catch-up ticks may skip transitions","inputs_released":not Input.is_action_pressed("move_right") and not Input.is_action_pressed("move_left") and not Input.is_action_pressed("move_up") and not Input.is_action_pressed("move_down") and not Input.is_action_pressed("field_sprint") and not Input.is_physical_key_pressed(KEY_J) and not Input.is_physical_key_pressed(KEY_SPACE),"hidden_unit_id":binding.hidden_unit_id,"art_status":"NOT_ACCEPTED_MIXED_VISUAL_DIAGNOSTIC"})
  recorder.stop(reason)
 active=false

