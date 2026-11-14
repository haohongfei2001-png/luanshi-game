extends RefCounted
## Explicit same-scene live input diagnostic after matched stills; no Battle stepping.
const Capture:=preload("res://scripts/field/wall_clock_capture.gd")
const Review:=preload("res://scripts/review/author_dynamic_review.gd")
static func fixture_for(actor:Node3D)->Dictionary:
 var path='res://tests/fixtures/author_thrust_peak.json'
 if not FileAccess.file_exists(path):return {'error':'MISSING_EXPORTED_PHASE_FIXTURE'}
 var evidence=JSON.parse_string(FileAccess.get_file_as_string(path))
 if not evidence is Dictionary or Review.validated_peak(actor.metadata,evidence)<=0.:return {'error':'PHASE_FIXTURE_SOURCE_MISMATCH'}
 return {'evidence':evidence,'sha256':FileAccess.get_sha256(path)}
static func contact_observation(field:Node,recorder:Node)->void:
 var battle=field.battle;var hero=battle.hero
 var nearest_id:=-1;var nearest_distance:=INF
 for unit in battle.roster:
  if unit.team==hero.team or unit.hp<=0. or unit.state in [battle.State.DEAD,battle.State.ESCAPED]:continue
  var distance:float=hero.pos.distance_to(unit.pos)
  if distance<nearest_distance:nearest_distance=distance;nearest_id=unit.id
 var input:Vector2=Input.get_vector('move_left','move_right','move_up','move_down')
 var direction:Vector2=input.rotated(-field.camera_yaw)
 var probe:Vector2=hero.pos+direction.normalized()*.5 if direction.length_squared()>0. else hero.pos
 var open:bool=battle.gate_hp<=0.
 var allowed:Vector2=field.Ground.travel(hero.pos,probe-hero.pos,open,battle.bridgehead)
 recorder.write({'kind':'author_contact_observation','monotonic_us':Time.get_ticks_usec(),'tick':battle.tick,'hero_pos':[hero.pos.x,hero.pos.y],'nearest_living_enemy_id':nearest_id,'nearest_living_enemy_distance_m':nearest_distance if nearest_id>=0 else null,'actual_input_world_vector':[direction.x,direction.y],'current_ground_blocked':field.Ground.blocked(hero.pos,open,battle.bridgehead),'requested_half_metre_probe':[probe.x,probe.y],'requested_probe_blocked':field.Ground.blocked(probe,open,battle.bridgehead),'travel_probe_allowed':[allowed.x,allowed.y],'hero_surface_height':field.Ground.deck_height(hero.pos,battle.bridgehead),'water_level':field.Ground.BATTLE_WATER_LEVEL,'scope':'READ_ONLY_DISTANCE_AND_GROUND_QUERY; probe not applied, no invented hit or movement'})
static func run(tree:SceneTree,field:Node,actor:Node3D,out:String)->bool:
 tree.root.size=Vector2i(2560,1440);tree.root.scaling_3d_scale=1.
 # Last matched view is destination26. Keep its solved actor scale and follow lead.
 if field.review_camera_profile.get('pitch_degrees',0.)!=26. or field.review_camera_profile.get('fov_degrees',0.)!=65. or field.review_camera_profile.get('follow_lead_world',[])!=[3.,0.]:return false
 field.view.review_hidden_actor_id=-1
 field._camera()
 await tree.process_frame;await tree.process_frame
 var checked=fixture_for(actor)
 if checked.has('error'):return false
 var fixture:Dictionary=checked.evidence
 var recorder=Capture.new();tree.root.add_child(recorder)
 if not recorder.start(tree.root,out,field):recorder.queue_free();return false
 var harness=Review.new();tree.root.add_child(harness)
 var error=harness.begin(field,actor,recorder,actor.payload_bytes,fixture)
 if error!=OK:
  recorder.stop('author_begin_failed');harness.queue_free();recorder.queue_free();return false
 field.set_process(true);field.set_physics_process(true)
 var deadline=Time.get_ticks_usec()+25000000
 while harness.active and Time.get_ticks_usec()<deadline:
  if recorder.active:contact_observation(field,recorder)
  await tree.process_frame
 var overrun=harness.active
 if overrun:harness.finish('sequence_deadline')
 field.set_process(false);field.set_physics_process(false)
 harness.queue_free();recorder.queue_free();await tree.process_frame
 return not overrun
