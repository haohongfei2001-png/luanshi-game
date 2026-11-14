extends RefCounted
## Real mapped input, no simulation stepping, teleport, healing or battle changes.
const Capture=preload('res://scripts/field/wall_clock_capture.gd')
static func run(tree:SceneTree,field:Node,out:String)->void:
 tree.root.size=Vector2i(2560,1440);tree.root.scaling_3d_scale=1.
 if field.review_camera_profile.is_empty():field.camera.size=22.
 field.follow=true;field._camera()
 field.set_process(true);field.set_physics_process(true)
 var recorder=Capture.new();tree.root.add_child(recorder)
 var recorder_started=recorder.start(tree.root,out,field)
 if not recorder_started:
  push_error('Traversal recorder preflight failed');tree.quit(1);return
 recorder.write({'kind':'traversal_contract','source':OS.get_environment('GITHUB_SHA'),'camera':'actual selected profile with follow; NOT_FIXED_CAMERA_COMPARISON','camera_configuration':camera_metadata(field),'initial_tick':field.battle.tick,'start_fixture':'same static battle initialized at tick135; subsequent motion real engine only','route':[[17.,-1.25],[46.2,-1.25]],'scope':'bridge-to-gate movement only, not full combat action acceptance'})
 var targets=[Vector2(17.,-1.25),Vector2(46.2,-1.25)]
 var index=0;var held={};var start=Time.get_ticks_usec()
 while Time.get_ticks_usec()-start<45000000 and recorder.active:
  if field.battle.result!='' or field.battle.hero.hp<=0:break
  if index<targets.size() and field.battle.hero.pos.distance_to(targets[index])<1.:
   recorder.write({'kind':'route_reached','target':index,'tick':field.battle.tick,'monotonic_us':Time.get_ticks_usec()});index+=1
  var requested={}
  if index<targets.size():
   var direction=(targets[index]-field.battle.hero.pos).normalized().rotated(field.camera_yaw)
   if direction.x>.3:requested[KEY_D]=true
   if direction.x<-.3:requested[KEY_A]=true
   if direction.y>.3:requested[KEY_S]=true
   if direction.y<-.3:requested[KEY_W]=true
  for key in [KEY_W,KEY_A,KEY_S,KEY_D]:
   var pressed=requested.has(key)
   if pressed!=held.has(key):
    var event=InputEventKey.new();event.keycode=key;event.physical_keycode=key;event.pressed=pressed
    Input.parse_input_event(event);Input.flush_buffered_events()
    recorder.write({'kind':'mapped_input','key':key,'pressed':pressed,'tick':field.battle.tick,'monotonic_us':Time.get_ticks_usec()})
  held=requested
  recorder.write({'kind':'camera_observation','tick':field.battle.tick,'monotonic_us':Time.get_ticks_usec(),'center':[field.camera_center.x,field.camera_center.y],'size':field.camera.size,'camera_configuration':camera_metadata(field),'hero_pos':[field.battle.hero.pos.x,field.battle.hero.pos.y]})
  await tree.process_frame
 for key in held:
  var event=InputEventKey.new();event.keycode=key;event.physical_keycode=key;event.pressed=false;Input.parse_input_event(event)
 Input.flush_buffered_events()
 if recorder.active:
  recorder.write({'kind':'traversal_result','reached':index,'required':targets.size(),'status':'ROUTE_COMPLETED_REQUIRES_VISUAL_REVIEW' if index==targets.size() else 'NOT_COMPLETED','battle_result':field.battle.result,'hero_hp':field.battle.hero.hp,'actual_wall_seconds':(Time.get_ticks_usec()-start)/1000000.})
  recorder.stop('review_complete')
 field.set_process(false);field.set_physics_process(false)
 recorder.queue_free();await tree.process_frame

static func camera_metadata(field:Node)->Dictionary:
 var camera:Camera3D=field.camera
 return {'profile':field.review_camera_profile.duplicate(true),'projection':camera.projection,'size':camera.size,'fov_degrees':camera.fov,'yaw_radians':field.camera_yaw,'pitch_radians':field.camera_pitch,'near':camera.near,'far':camera.far,'transform':str(camera.global_transform),'projection_matrix':str(camera.get_camera_projection()),'scope':'MOVING_FOLLOW_CAMERA_NOT_FIXED_COMPARISON; actual actor pixel occupancy not asserted'}
