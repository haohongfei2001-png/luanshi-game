extends SceneTree
## Real Controller + real source11 Skeleton, but a deliberately non-art mother
## fixture and prototype004 topology. No screenshots or visual acceptance.
const Field:=preload("res://scripts/field/maps/authored_field_controller.gd")
const Host:=preload("res://scripts/field/maps/authored_scene_host.gd")
const Battle:=preload("res://scripts/field/battle.gd")
const Nav:=preload("res://scripts/field/maps/authored_navigation.gd")
const Runtime:=preload("res://scripts/field/maps/authored_field_runtime.gd")
const Muster:=preload("res://scripts/field/maps/authored_muster.gd")
const Actor:=preload("res://scripts/field/experimental/production_v2/shared_skeletal_actor.gd")
const Pilot:=preload("res://scripts/field/experimental/production_v2/contact_input_pilot.gd")
class Recorder extends Node:
 var active:=true
 var field:Node
 var rows:Array=[]
 var reason:=""
 func write(row:Dictionary)->void:
  if row.get("kind")=="production_route_failure" and field!=null:row["failure_battle_snapshot"]=preload("res://scripts/field/save.gd").snapshot(field.battle)
  rows.append(row.duplicate(true))
 func stop(value:String)->void:reason=value;active=false
const Binding:=preload("res://scripts/field/experimental/production_v2/mh_spear_battle_binding.gd")
var actual_actor_sha:=""
func _initialize():run.call_deferred()
func fixture(identity:Dictionary)->PackedScene:
 var scene:=Node3D.new()
 for key in identity:scene.set_meta(key,identity[key])
 var sun:=DirectionalLight3D.new();scene.add_child(sun);sun.owner=scene
 var world:=WorldEnvironment.new();world.environment=Environment.new();scene.add_child(world);world.owner=scene
 var door:=Node3D.new();door.set_meta("extras",{"gate_id":"gate_main"});scene.add_child(door);door.owner=scene
 var packed:=PackedScene.new();assert(packed.pack(scene)==OK);scene.free();return packed
func press(action:String,strength:float):
 var event:=InputEventAction.new();event.action=action;event.pressed=strength>.001;event.strength=strength;Input.parse_input_event(event)
func run():
 var args:=OS.get_cmdline_user_args();assert(args.size() in [5,6]);actual_actor_sha=FileAccess.get_sha256(args[2])
 var data:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(args[0]));var layout:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(args[1]));var metadata:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(args[3]))
 var bounds:=Rect2(Vector2(layout.bounds.x[0],layout.bounds.z[0]),Vector2(layout.bounds.x[1]-layout.bounds.x[0],layout.bounds.z[1]-layout.bounds.z[0]))
 var nav:=Nav.new();assert(nav.configure(data,bounds,{"gate_main":true},.7,3.4)==OK)
 var runtime:=Runtime.new();assert(runtime.bind(nav,data)==OK)
 var battle:=Battle.new();battle.setup(20,61112,Battle.Arms.Kit.SPEAR,true,true,20,false);assert(Muster.apply(battle,runtime).error==OK)
 var document:=GLTFDocument.new();var state:=GLTFState.new();assert(document.append_from_file(args[2],state)==OK)
 var model:=document.generate_scene(state);var packed:=PackedScene.new();assert(packed.pack(model)==OK);model.free()
 var actor:=Actor.new();assert(actor.setup(packed)==OK)
 var shared_probe:=Actor.new();assert(shared_probe.setup(packed)==OK)
 var first_meshes:=actor.model.find_children("*","MeshInstance3D",true,false);var second_meshes:=shared_probe.model.find_children("*","MeshInstance3D",true,false)
 assert(first_meshes.size()==second_meshes.size());assert(actor.skeleton!=shared_probe.skeleton)
 for index in first_meshes.size():assert(first_meshes[index].mesh==second_meshes[index].mesh,"Packed instances must share original mesh resources")
 shared_probe.free()
 var binding:=Binding.new();assert(binding.configure_timing(metadata,FileAccess.get_sha256(args[2]))==OK);binding.ground_point=Callable(runtime,"unit_point");binding.enabled=true
 var identity:=runtime.identity();identity.visual_revision=1;identity.authored_source_sha256=data.authored_source_sha256
 var host:=Host.new();assert(host.configure(fixture(identity),identity)==OK)
 var field:=Field.new();assert(field.configure(battle,host,actor,binding,bounds,"CPU_INTERFACE_FIXTURE_NOT_VISUAL_ART")==OK)
 if args.size()==6 and args[5] in ["contact-group","army-group"]:
  var ordinary:=[]
  for id in Binding.select_ordinary_ids(battle,3):
   var extra_actor:=Actor.new();assert(extra_actor.setup(packed)==OK)
   var extra_binding:=Binding.new();assert(extra_binding.configure_timing(metadata,FileAccess.get_sha256(args[2]))==OK)
   extra_binding.ground_point=Callable(runtime,"unit_point");extra_binding.enabled=true
   ordinary.append({"unit_id":id,"actor":extra_actor,"binding":extra_binding})
  assert(ordinary.size()==6)
  assert(field.configure_ordinary_spearmen([ordinary[0],ordinary[0]])==ERR_INVALID_DATA)
  assert(field.ordinary_actor_bindings.is_empty())
  assert(field.configure_ordinary_spearmen(ordinary)==OK)
 root.size=Vector2i(2560,1440);root.add_child(field);field.set_process(false);field.set_physics_process(false);field.deploy()
 if args.size()==6 and args[5] in ["contact-group","army-group"]:assert(field.view.review_hidden_actor_ids.size()==6)
 await process_frame
 if args.size()==6:
  if args[5]=="army-group":army(field,args[4]);return
  await contact(field,args[4]);return
 var initial:=battle.hero.pos;var rows:=[];var clips:={}
 for step in 100:
  var goal:=initial+Vector2(4,0);var desired:=battle.hero.pos.direction_to(goal)*.45 if step<70 and battle.hero.pos.distance_to(goal)>.2 else Vector2.ZERO
  var move:=desired.rotated(field.camera_yaw)
  press("move_right",maxf(0,move.x));press("move_left",maxf(0,-move.x));press("move_down",maxf(0,move.y));press("move_up",maxf(0,-move.y))
  var target:=runtime.unit_point(battle.hero.pos+Vector2(2,0));var logical:=field.camera.unproject_position(target)
  var pointer:=InputEventMouseMotion.new();pointer.position=root.get_final_transform()*logical;pointer.global_position=pointer.position;Input.parse_input_event(pointer);Input.flush_buffered_events()
  field._physics_process(Battle.DT);field._process(Battle.DT)
  var row:=field.actor_receipt.duplicate(true);row["position"]=str(battle.hero.pos);row["pointer_actual"]=str(root.get_mouse_position());row["pointer_logical"]=str(logical);rows.append(row)
  clips[row.get("semantic",row.get("reason","unknown"))]=int(clips.get(row.get("semantic",row.get("reason","unknown")),0))+1
 for action in ["move_right","move_left","move_down","move_up"]:press(action,0)
 assert(battle.hero.pos.distance_to(initial)>1.,"Actual Controller input did not move hero")
 assert(actor.skeleton.get_bone_count()==163);assert(field.camera.fov==50.);assert(is_equal_approx(field.camera_pitch,deg_to_rad(45.)))
 assert(runtime.unit_point(battle.hero.pos).distance_to(actor.position)<.5)
 var output={"kind":"CPU_REAL_CONTROLLER_SKELETON_INTERFACE_FIXTURE_NOT_VISUAL","tick":battle.tick,"initial":str(initial),"final":str(battle.hero.pos),"clips":clips,"hero_hp":battle.hero.hp,"hero_impacts":battle.hero.impacts,"glb_sha256":FileAccess.get_sha256(args[2]),"rows":rows}
 FileAccess.open(args[4],FileAccess.WRITE).store_string(JSON.stringify(output,"  "));field.free();print("REAL_CONTROLLER_SKELETON_FIXTURE_PASS ",JSON.stringify({"tick":battle.tick,"clips":clips,"hero_hp":battle.hero.hp,"gpu":"NOT_RUN"}));quit()

func contact(field:Field,output_path:String)->void:
 Engine.max_fps=60
 var recorder:=Recorder.new();recorder.field=field;root.add_child(recorder)
 var pilot:=Pilot.new();root.add_child(pilot);assert(pilot.begin(field,recorder)==OK)
 field.set_process(true);field.set_physics_process(true)
 var started:=Time.get_ticks_usec();var last_tick:=-1;var poses:Array=[];var semantics:={}
 while recorder.active and Time.get_ticks_usec()-started<40000000:
  await process_frame
  if field.battle.tick!=last_tick or field.battle.hero.hp<=0:
   last_tick=field.battle.tick;var row:=field.actor_receipt.duplicate(true);row["monotonic_us"]=Time.get_ticks_usec();row["actual_hero_pos"]=str(field.battle.hero.pos);row["actor_position"]=str(field.skeletal_actor.position);row["camera_fov"]=field.camera.fov;row["camera_pitch"]=field.camera_pitch;row["camera_yaw"]=field.camera_yaw;row["camera_transform"]=str(field.camera.global_transform);row["ground_point"]=str(field.battle.map_runtime.unit_point(field.battle.hero.pos));row["source_sha256"]=field.map.expected_identity.authored_source_sha256
   assert(field.camera.fov==50. and is_equal_approx(field.camera_pitch,deg_to_rad(45.)));assert(field.map.master.find_children("*","WorldEnvironment",true,false).size()==1)
   row["ordinary_units"]={}
   for item in field.ordinary_actor_bindings:
    var ordinary:Dictionary=field.ordinary_actor_receipts.get(item.unit_id,{}).duplicate(true)
    ordinary["team"]=field.battle.roster[item.unit_id].team;ordinary["actual_unit_hp"]=field.battle.roster[item.unit_id].hp;ordinary["actor_position"]=str(item.actor.position)
    row.ordinary_units[item.unit_id]=ordinary
   poses.append(row)
   var semantic:String=row.get("semantic",row.get("reason","unknown"));semantics[semantic]=int(semantics.get(semantic,0))+1
 if recorder.active:pilot.finish("fixture_outer_timeout")
 var report={"kind":"CPU_REAL_CONTROLLER_CONTACT_SKELETON_NOT_GPU_ART_OR_FPS","actual_actor_sha256":actual_actor_sha,"reason":recorder.reason,"hero_hp":field.battle.hero.hp,"hero_impacts":field.battle.hero.impacts,"received":field.battle.hero.received,"result":field.battle.result,"tick":field.battle.tick,"semantics":semantics,"input_rows":recorder.rows,"pose_rows":poses,"actual_new_ordinary_ids":field.view.review_hidden_actor_ids.keys()}
 FileAccess.open(output_path,FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
 pilot.free();field.free();recorder.free()
 print("REAL_CONTROLLER_CONTACT_EXECUTED_NOT_AUTOMATIC_SUCCESS ",JSON.stringify({"reason":report.reason,"hero_hp":report.hero_hp,"impacts":report.hero_impacts,"received":report.received,"tick":report.tick,"semantics":semantics}));quit()

func army(field:Field,output_path:String)->void:
 var history:=[];var store=preload("res://scripts/field/save.gd")
 # Real Controller command event, not direct changes to unit/HP/order fields.
 press("order_attack",1.);Input.flush_buffered_events();press("order_attack",0.)
 var ticks:=0
 for step in 1200:
  field._physics_process(Battle.DT)
  var before:String=JSON.stringify(store.snapshot(field.battle)) if step%100==0 else ""
  field._process(Battle.DT)
  if not before.is_empty():assert(JSON.stringify(store.snapshot(field.battle))==before,"Presentation modified authoritative Battle")
  history.append({"tick":field.battle.tick,"ordinary":field.ordinary_actor_receipts.duplicate(true)})
  ticks=step+1
  if not field.battle.result.is_empty():break
 for tail in 55:
  var before:=JSON.stringify(store.snapshot(field.battle));field._process(Battle.DT);assert(JSON.stringify(store.snapshot(field.battle))==before)
  history.append({"tick":field.battle.tick,"ordinary":field.ordinary_actor_receipts.duplicate(true),"presentation_tail_only":true})
 var units:=[]
 for item in field.ordinary_actor_bindings:
  var unit=field.battle.roster[item.unit_id]
  if not field.battle.result.is_empty():assert(item.actor.position.distance_to(field.battle.map_runtime.unit_point(unit.pos))<.00001,"Stopped simulation must render final authoritative position")
  units.append({"unit_id":unit.id,"team":unit.team,"actual_hp":unit.hp,"state":unit.state,"actual_impacts":unit.impacts,"last_pose":field.ordinary_actor_receipts[item.unit_id],"actor_position":str(item.actor.position),"ground_point":str(field.battle.map_runtime.unit_point(unit.pos))})
 var report={"kind":"CPU_REAL_CONTROLLER_ARMY_SKELETON_GROUP_NO_GPU_NO_WALL_TIME_MOVIE","actual_actor_sha256":actual_actor_sha,"tick":field.battle.tick,"step_calls":ticks,"result":field.battle.result,"hero_hp":field.battle.hero.hp,"hero_impacts":field.battle.hero.impacts,"ordinary_ids":field.view.review_hidden_actor_ids.keys(),"units":units,"history":history,"snapshot_unchanged_by_presentation":true}
 FileAccess.open(output_path,FileAccess.WRITE).store_string(JSON.stringify(report,"  "));field.free();print("ACTUAL_ORDINARY_GROUP_EXECUTED ",JSON.stringify({"tick":report.tick,"result":report.result,"units":units}));quit()
