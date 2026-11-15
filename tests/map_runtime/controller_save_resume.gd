extends SceneTree
## CPU SceneTree lifecycle, actual Controller/Figures/HUD/source18 actors.
## Empty identity host is deliberate: no complete-mother/GPU/art acceptance.
const Field:=preload("res://scripts/field/maps/authored_field_controller.gd")
const Host:=preload("res://scripts/field/maps/authored_scene_host.gd")
const Battle:=preload("res://scripts/field/battle.gd")
const Save:=preload("res://scripts/field/save.gd")
const Store:=preload("res://scripts/field/experimental_map_save.gd")
const Nav:=preload("res://scripts/field/maps/authored_navigation.gd")
const Runtime:=preload("res://scripts/field/maps/authored_field_runtime.gd")
const Muster:=preload("res://scripts/field/maps/authored_muster.gd")
const Actor:=preload("res://scripts/field/experimental/production_v2/shared_skeletal_actor.gd")
const Binding:=preload("res://scripts/field/experimental/production_v2/mh_spear_battle_binding.gd")
var checks:=0
var failures:Array[String]=[]
var field:Field
var runtime:Runtime
var bounds:Rect2
var packed:PackedScene
var timing:Dictionary
var actor_sha:String
var output:String
var checkpoints:=[]
var state_coverage:Dictionary={}
var actor_role_coverage:Dictionary={"hero_thrust_ids":[],"ordinary_walk_ids":[]}
var legacy_bytes:PackedByteArray
var sentinel:PackedByteArray
var fixed_resources:Dictionary
func check(ok:bool,label:String)->bool:
 checks+=1
 if not ok:failures.append(label);push_error(label)
 return ok
func bytes(b:Battle)->PackedByteArray:return var_to_bytes(Save.snapshot(b))
func digest(value:PackedByteArray)->String:return Store._digest(value).hex_encode()
func write(path:String,payload:PackedByteArray):
 var file:=FileAccess.open(path,FileAccess.WRITE)
 if not check(file!=null,"open test output "+path):return
 file.store_buffer(payload);file.close()
func host_fixture()->PackedScene:
 var scene:=Node3D.new();var identity:=runtime.identity()
 identity.visual_revision=1;identity.authored_source_sha256=runtime.source.authored_source_sha256
 for key in identity:scene.set_meta(key,identity[key])
 var sun:=DirectionalLight3D.new();scene.add_child(sun);sun.owner=scene
 var world:=WorldEnvironment.new();world.environment=Environment.new();scene.add_child(world);world.owner=scene
 var gate:=Node3D.new();gate.set_meta("extras",{"gate_id":"gate_main"});scene.add_child(gate);gate.owner=scene
 var result:=PackedScene.new();var error:=result.pack(scene)
 check(error==OK,"identity host fixture packs");scene.free();return result
func actor_pair()->Dictionary:
 var actor:=Actor.new();var binding:=Binding.new()
 check(actor.setup(packed)==OK,"actual source18 actor setup")
 check(binding.configure_timing(timing,actor_sha)==OK,"actual source18 timing")
 binding.ground_point=Callable(runtime,"unit_point");binding.enabled=true
 return {"actor":actor,"binding":binding}
func make_field(opt_in:bool)->Field:
 var b:=Battle.new();b.setup(20,61112,Battle.Arms.Kit.SPEAR,true,true,20,false)
 if not check(Muster.apply(b,runtime).error==OK,"actual20 source muster"):return null
 var identity:=runtime.identity();identity.visual_revision=1;identity.authored_source_sha256=runtime.source.authored_source_sha256
 var host:=Host.new();check(host.configure(host_fixture(),identity)==OK,"actual authored host configured")
 var hero:=actor_pair();var result:=Field.new()
 check(result.configure(b,host,hero.actor,hero.binding,bounds,"CPU_SAVE_LIFECYCLE_NOT_ART")==OK,"actual Controller configure")
 var instances:=[]
 for id in Binding.select_ordinary_ids(b,3):
  var pair:=actor_pair();pair.unit_id=id;instances.append(pair)
 check(instances.size()==6,"six actual ordinary source18 actors")
 check(result.configure_ordinary_spearmen(instances)==OK,"ordinary bindings configure")
 if opt_in:
  check(result.configure_experimental_saves("../legacy")==ERR_INVALID_PARAMETER,"unsafe Controller slot rejected")
  check(result.configure_experimental_saves("controller20")==OK,"explicit Controller save enable")
 root.add_child(result);result.set_process(false);result.set_physics_process(false)
 return result
func resources()->Dictionary:
 var actors:=[field.skeletal_actor];var result:={"map":field.map.get_instance_id(),"master":field.map.master.get_instance_id(),"actors":[],"mesh_resources":[],"skeletons":[]}
 for item in field.ordinary_actor_bindings:actors.append(item.actor)
 for actor in actors:
  result.actors.append(actor.get_instance_id());result.skeletons.append(actor.skeleton.get_instance_id())
  for mesh in actor.model.find_children("*","MeshInstance3D",true,false):
   var materials:=[]
   for surface in mesh.mesh.get_surface_count():
    var material=mesh.mesh.surface_get_material(surface);var override=mesh.get_surface_override_material(surface)
    materials.append([material.get_instance_id() if material else 0,override.get_instance_id() if override else 0])
   result.mesh_resources.append([mesh.mesh.get_instance_id(),mesh.material_override.get_instance_id() if mesh.material_override else 0,materials])
 return result
func actors()->Array:
 var result:=[field.skeletal_actor]
 for item in field.ordinary_actor_bindings:result.append(item.actor)
 return result
func bone_poses(actor:Actor)->Array:
 actor.skeleton.force_update_all_bone_transforms()
 var result:=[]
 for i in actor.skeleton.get_bone_count():
  result.append([actor.skeleton.get_bone_pose(i),actor.skeleton.get_bone_global_pose(i)])
 return result
func all_bones()->Array:
 var result:=[]
 for actor in actors():result.append(bone_poses(actor))
 return result
func live_presentation()->Array:
 var result:=[];var bindings:=[field.skeletal_binding]
 for item in field.ordinary_actor_bindings:bindings.append(item.binding)
 var current_actors:=actors()
 for i in current_actors.size():
  var actor=current_actors[i];var binding=bindings[i];var history:=[]
  for key in ["enabled","bound_unit_id","bound_actor_id","last_tick","previous_state","state_started_tick","previous_pos","movement_phase","idle_seconds","death_presentation_seconds","last_receipt","phase_clip","phase_from","phase_to","resume_sample"]:
   history.append(binding.get(key))
  result.append([bone_poses(actor),actor.transform,actor.visible,actor.player.current_animation,actor.player.current_animation_position,history.duplicate(true)])
 return result
func external_input()->Array:
 var result:=[field.paused,field.carry,field.ui_clock,field.pan,field.orbiting,field.follow,field.camera_center]
 for action in ["move_left","move_right","move_up","move_down","attack","sweep","lunge","guard","field_sprint"]:result.append(Input.get_action_strength(action))
 return result
func expire_battle_notice():
 # Only HUD display lifetime is changed, never the persisted Battle notice.
 field.hud.last_notice=field.battle.notice;field.hud.notice_tick=field.battle.tick-60;field.hud.order_panel.hide()
func verify_actual_poses(rows:Array,label:String):
 var oracle:=Actor.new();check(oracle.setup(packed)==OK,label+" independent source actor oracle")
 root.add_child(oracle)
 var current_actors:=actors()
 for i in rows.size():
  var row:Dictionary=rows[i];var unit=field.battle.roster[field.battle.hero.id if i==0 else field.ordinary_actor_bindings[i-1].unit_id]
  var expected:=""
  if unit.hp<=0 or unit.state==Battle.State.DEAD:expected="death"
  elif unit.state==Battle.State.STAGGER:expected="hit_chest"
  elif unit.state in [Battle.State.WINDUP,Battle.State.RECOVER] and unit.move_slot==0:expected="thrust"
  elif unit.state==Battle.State.MARCH:
   var moved:float=unit.pos.distance_to(unit.before)
   expected=("sprint" if moved/Battle.DT>3.55 else "walk") if moved>.0001 else "idle"
  check(not expected.is_empty() and row.get("supported",false) and row.get("semantic")==expected,label+" required state has correct supported semantic "+str(unit.id))
  if expected.is_empty() or not row.get("supported",false):continue
  var actor:Actor=current_actors[i]
  check(actor.player.current_animation==actor.clip_names[expected],label+" actual AnimationPlayer clip "+str(unit.id))
  check(is_equal_approx(actor.player.current_animation_position,row.phase*actor.clip_seconds(expected)),label+" actual AnimationPlayer time "+str(unit.id))
  oracle.player.stop();oracle.skeleton.reset_bone_poses()
  var receipt:=oracle.sample(expected,row.phase,0.)
  check(receipt.get("supported",false),label+" independent actual source sample")
  check(bone_poses(actor)==bone_poses(oracle),label+" all163 actual local/global bones equal independent source pose "+str(unit.id))
 oracle.free()
func count_nodes(node:Node)->int:
 var n:=1
 for child in node.get_children():n+=count_nodes(child)
 return n
func pose_rows()->Array:
 var rows:=[field.actor_receipt.duplicate(true)]
 for item in field.ordinary_actor_bindings:rows.append(field.ordinary_actor_receipts[item.unit_id].duplicate(true))
 return rows
func check_binding(label:String):
 check(field.view.battle==field.battle,label+" Figures binds restored Battle")
 check(field.view.review_hidden_actor_id==field.battle.hero.id,label+" hero fallback excluded")
 check(field.view.review_hidden_actor_ids.size()==6,label+" six crowd exclusions, no double representation")
 check(field.skeletal_binding.last_tick==field.battle.tick,label+" hero presentation timeline reset")
 check(field.skeletal_actor.position.distance_to(runtime.unit_point(field.battle.hero.pos))<.00001,label+" paused actor at exact restored position")
 for item in field.ordinary_actor_bindings:
  check(field.view.review_hidden_actor_ids.has(item.unit_id) and item.active and item.actor.visible,label+" ordinary actor exclusion "+str(item.unit_id))
  check(item.binding.bound_unit_id==item.unit_id and item.binding.bound_actor_id==item.actor.get_instance_id() and item.binding.last_tick==field.battle.tick,label+" ordinary identity/tick "+str(item.unit_id))
 check(resources()==fixed_resources,label+" mother/actors/skeleton/shared meshes unchanged")
 check(field.theater==null,label+" no Campaign.bind or world settlement")
func pointer_and_step(index:int):
 # Fixed camera/pointer makes the same actual Controller input repeatable.
 field.follow=false;field.camera_center=bounds.get_center();field._camera()
 var pointer:=InputEventMouseMotion.new();pointer.position=Vector2(640,400);pointer.global_position=pointer.position
 Input.parse_input_event(pointer);Input.flush_buffered_events()
 Input.action_press("move_right",.2) if index%3==0 else Input.action_release("move_right")
 if index==2:field._order(0,Battle.Mission.PRESS,Battle.Channel.COURIER)
 field._physics_process(Battle.DT);field._process(Battle.DT)
func persistent_input(b:Battle)->Array:
 return [b.hero_move,b.aim,b.sprinting,b.buffered_slot,b.buffer_ticks,b.buffer_aim,b.buffer_wall]
func exercise(label:String):
 var original:=bytes(field.battle);var old_battle:=field.battle;var saved_tick:=field.battle.tick;var persisted:=persistent_input(field.battle)
 var node_count:=count_nodes(field);var skeleton_count:=field.find_children("*","Skeleton3D",true,false).size()
 expire_battle_notice()
 var key:=InputEventAction.new();key.action="campaign_quicksave";key.pressed=true
 field._unhandled_input(key)
 check(bytes(field.battle)==original,label+" HUD save leaves typed Battle exact")
 check(field.hud.feedback.is_visible_in_tree() and field.hud.feedback.text.contains("实验进度已保存"),label+" save status visible despite expired Battle notice")
 var store:=Store.new(true);var path:=store.slot_path("controller20")
 var saved_file:=FileAccess.get_file_as_bytes(path)
 check(store.load_slot(runtime,"controller20")!=null,label+" actual independent slot readable")
 var expected:=[];field.paused=false
 for i in 6:pointer_and_step(i);expected.append(bytes(field.battle))
 check(field.battle.tick==saved_tick+6 and bytes(field.battle)!=original,label+" original live Controller actually continues")
 field.carry=.019;field.ui_clock=.09;field.pan=true;field.orbiting=true
 for action in ["move_right","attack","guard","field_sprint"]:Input.action_press(action)
 var old_view:=field.view
 field.hud.load_requested.emit()
 check(field.battle!=old_battle and not is_instance_valid(old_view),label+" restored Battle adopted and old Figures freed")
 check(bytes(field.battle)==original,label+" whole typed state exact including persisted inputs")
 check(persistent_input(field.battle)==persisted,label+" persisted movement/aim/sprint/attack buffer separately unchanged")
 check(field.paused and field.carry==0. and field.ui_clock==0. and not field.pan and not field.orbiting,label+" UI clocks/drags reset, paused")
 for action in ["move_right","attack","guard","field_sprint"]:check(not Input.is_action_pressed(action),label+" external held action cleared "+action)
 check_binding(label)
 check(count_nodes(field)==node_count and field.find_children("*","Skeleton3D",true,false).size()==skeleton_count,label+" stable node and Skeleton counts")
 var poses:=pose_rows();var bones:=all_bones()
 verify_actual_poses(poses,label)
 check(field.hud.feedback.is_visible_in_tree() and field.hud.feedback.text.contains("实验进度已恢复"),label+" load status visible")
 for row in poses:
  var unit=field.battle.roster[row.unit_id]
  if unit.hp<=0:
   var item_actor=field.skeletal_actor
   for item in field.ordinary_actor_bindings:
    if item.unit_id==unit.id:item_actor=item.actor
   var phase:=clampf((field.battle.tick-unit.lost_tick)*Battle.DT/item_actor.clip_seconds("death"),0.,1.)
   check(row.get("semantic")=="death" and is_equal_approx(row.phase,phase),label+" corpse uses saved death time, not old animation")
  if row.get("semantic")=="thrust":
   var progress:=clampf(1.-unit.timer/unit.duration,0.,1.)
   var phase:float=progress*field.skeletal_binding.thrust_peak if unit.state==Battle.State.WINDUP else lerpf(field.skeletal_binding.thrust_peak,1.,progress)
   check(is_equal_approx(row.phase,phase),label+" actual attack timer maps to source clip phase")
  if row.get("semantic")=="walk":
   var phase:=fposmod(unit.stride+unit.pos.distance_to(unit.before)/1.45,1.)
   check(is_equal_approx(row.phase,phase),label+" saved stride reconstructs walking without old live progress")
  if row.get("supported",false):
   state_coverage[row.get("semantic","unknown")]=true
   if row.get("semantic")=="thrust" and row.unit_id==field.battle.hero.id and unit.hero:
    if not row.unit_id in actor_role_coverage.hero_thrust_ids:actor_role_coverage.hero_thrust_ids.append(row.unit_id)
   if row.get("semantic")=="walk" and row.unit_id!=field.battle.hero.id and not unit.hero and not unit.officer:
    if not row.unit_id in actor_role_coverage.ordinary_walk_ids:actor_role_coverage.ordinary_walk_ids.append(row.unit_id)
 for iteration in 3:
  # Deliberately dirty presentation-only time between repeated restores.
  field._process(.37)
  check(bytes(field.battle)==original,label+" presentation does not alter saved Battle")
  old_view=field.view
  check(field.load_experimental()==OK,label+" repeated load "+str(iteration))
  check(not is_instance_valid(old_view) and bytes(field.battle)==original,label+" repeated exact snapshot")
  check(pose_rows()==poses,label+" repeated clip/phase receipts identical")
  check(all_bones()==bones,label+" repeated actual163x7 bone poses identical")
  check(resources()==fixed_resources and count_nodes(field)==node_count,label+" repeated resource/node stability")
 field.toggle_pause()
 for i in 6:
  pointer_and_step(i)
  check(bytes(field.battle)==expected[i],label+" resumed Controller typed continuation "+str(i))
 check(FileAccess.get_file_as_bytes(path)==saved_file,label+" resume never rewrites slot")
 checkpoints.append({"label":label,"actual_bones_sha256":digest(var_to_bytes(bones)),"persisted_input":persisted,"tick":Save.snapshot(store.load_slot(runtime,"controller20")).battle[0],"snapshot_sha256":digest(original),"slot_sha256":digest(saved_file),"continued_sha256":digest(bytes(field.battle)),"nodes":node_count,"skeletons":skeleton_count,"poses":poses})
func failure_cases():
 var store:=Store.new(true);var path:=store.slot_path("controller20");var valid:=FileAccess.get_file_as_bytes(path)
 var state:=bytes(field.battle);var live:=field.battle;var view:=field.view;var nodes:=count_nodes(field)
 var poses:=live_presentation();var inputs:=external_input()
 var variants:=[PackedByteArray(),valid.slice(0,30)]
 var damaged:=valid.duplicate();damaged[damaged.size()-1]^=1;variants.append(damaged)
 var saved=bytes_to_var(valid.slice(Store.MAGIC.length()+32))
 for key in ["map_id","topology_revision","topology_sha256"]:
  var wrong:Dictionary=saved.duplicate(true)
  wrong.map_identity[key]="unknown" if key=="map_id" else (99 if key=="topology_revision" else "a".repeat(64))
  var payload:=var_to_bytes(wrong)
  variants.append(Store.MAGIC.to_utf8_buffer()+Store._digest(payload)+payload)
 for corrupt in variants:
  write(path,corrupt);field.hud.load_requested.emit()
  check(field.battle==live and field.view==view and bytes(field.battle)==state,"failed load keeps exact live Battle")
  check(resources()==fixed_resources and count_nodes(field)==nodes,"failed load no resources changed")
  check(live_presentation()==poses,"failed load actual bones/player/binding history unchanged")
  check(external_input()==inputs,"failed load external inputs and clocks unchanged")
  check(FileAccess.get_file_as_bytes(path)==corrupt,"failed load does not rewrite input")
 write(path,valid)
 var mode=runtime.source.battle_mode;runtime.source.battle_mode="unsupported"
 check(field.load_experimental()==ERR_UNAVAILABLE and field.save_experimental()==ERR_UNAVAILABLE,"unsupported mode refuses Controller read/write")
 runtime.source.battle_mode=mode
 check(bytes(field.battle)==state and FileAccess.get_file_as_bytes(path)==valid,"mode refusal leaves Battle and prior slot intact")
func unsupported_resume_cases():
 var store:=Store.new(true);var path:=store.slot_path("controller20")
 var previous:=FileAccess.get_file_as_bytes(path);var fixtures:=[]
 field.paused=false
 for action in ["move_left","move_right","move_up","move_down","attack","guard"]:Input.action_release(action)
 var key:=InputEventAction.new();key.action="guard";key.pressed=true
 field._unhandled_input(key)
 check(field.battle.hero.state==Battle.State.WINDUP and field.battle.hero.move_slot==3,"real guard input enters alternate skill windup")
 for stage in ["alternate_skill_windup","guard"]:
  if stage=="guard":
   for step in 12:
    field._physics_process(Battle.DT);field._process(Battle.DT)
    if field.battle.hero.state==Battle.State.GUARD:break
   check(field.battle.hero.state==Battle.State.GUARD,"real physics reaches GUARD without editing unit state")
  var original:=bytes(field.battle);var poses:=live_presentation()
  expire_battle_notice();field.hud.save_requested.emit()
  check(bytes(field.battle)==original and live_presentation()==poses,stage+" rejected save leaves real state/bones/binding intact")
  check(FileAccess.get_file_as_bytes(path)==previous,stage+" rejected Controller save preserves previous usable slot")
  check(field.hud.feedback.is_visible_in_tree() and field.hud.feedback.text.contains("实验保存失败"),stage+" save refusal visible independently")
  # Backend format supports this legitimate state. It is the source18 Controller
  # presentation contract, not Save validation, that must refuse its adoption.
  check(store.save(field.battle,"controller20")==OK,stage+" real backend-valid unsupported presentation checkpoint")
  fixtures.append({"label":stage,"bytes":FileAccess.get_file_as_bytes(path)})
  write(path,previous)
 for step in 40:
  field._physics_process(Battle.DT);field._process(Battle.DT)
  if field.battle.hero.state==Battle.State.MARCH:break
 check(field.battle.hero.state==Battle.State.MARCH,"live timeline actually leaves GUARD")
 # Real sideways held input, with the existing independently aimed pointer.
 # The source18 actor lacks a sidestep clip; no position/facing edits stage it.
 Input.action_press("move_up",.4)
 var sidestep:=false
 for step in 8:
  field._physics_process(Battle.DT);field._process(Battle.DT)
  var u=field.battle.hero;var displacement:Vector2=u.pos-u.before
  if u.state==Battle.State.MARCH and displacement.length()>.0001 and displacement.normalized().dot(u.facing.normalized())<.8:
   sidestep=true;break
 check(sidestep,"real Controller input reaches unsupported sideways MARCH")
 var side_state:=bytes(field.battle);var side_poses:=live_presentation()
 expire_battle_notice();field.hud.save_requested.emit()
 check(bytes(field.battle)==side_state and live_presentation()==side_poses,"sidestep refused save keeps real Battle and bones")
 check(FileAccess.get_file_as_bytes(path)==previous,"sidestep save keeps previous usable slot")
 check(store.save(field.battle,"controller20")==OK,"real backend-valid sidestep checkpoint")
 fixtures.append({"label":"sideways_march","bytes":FileAccess.get_file_as_bytes(path)})
 write(path,previous);Input.action_release("move_up")
 field._physics_process(Battle.DT);field._process(Battle.DT)
 # Presentation-only poison, NOT a simulated death/HP change. A failed load must
 # retain even these real bone transforms instead of resetting/partial sampling.
 field.skeletal_actor.sample("death",.73,0.)
 field.carry=.017;field.ui_clock=.08;field.pan=true;field.orbiting=true
 Input.action_press("move_right",.3);Input.action_press("attack")
 var current:=bytes(field.battle);var live:=field.battle;var view:=field.view
 var poses:=live_presentation();var inputs:=external_input();var identities:=resources();var nodes:=count_nodes(field)
 for fixture in fixtures:
  write(path,fixture.bytes)
  check(store.load_slot(runtime,"controller20")!=null,fixture.label+" backend accepts actual typed fixture")
  expire_battle_notice();field.hud.load_requested.emit()
  check(field.battle==live and field.view==view and bytes(field.battle)==current,fixture.label+" refusal transaction keeps Battle/Figures exactly")
  check(live_presentation()==poses,fixture.label+" all actual bones/transforms/player/binding history unchanged")
  check(external_input()==inputs,fixture.label+" refusal preserves live input and clocks")
  check(resources()==identities and count_nodes(field)==nodes,fixture.label+" refusal preserves actors/materials/nodes")
  check(FileAccess.get_file_as_bytes(path)==fixture.bytes,fixture.label+" refusal leaves file bytes unchanged")
  check(field.hud.feedback.is_visible_in_tree() and field.hud.feedback.text.contains("实验读档被拒"),fixture.label+" load refusal visibly reported")
 checkpoints.append({"label":"unsupported_real_guard_transactions","states":["slot3_WINDUP","GUARD","sideways_MARCH"],"actual_bones_unchanged_sha256":digest(var_to_bytes(poses)),"saved_state_is_backend_valid":true})
 write(path,previous)
 for action in ["move_right","attack"]:Input.action_release(action)
func _initialize():run.call_deferred()
func run():
 var args:=OS.get_cmdline_user_args()
 if args.size()!=4:push_error("SOURCE_JSON SOURCE18_GLB TIMING_JSON OUTPUT_JSON");quit(2);return
 output=args[3]
 if not check(OS.get_environment("XDG_DATA_HOME").contains("save5-controller"),"isolated test XDG required"):finish();return
 var data=JSON.parse_string(FileAccess.get_file_as_string(args[0]));timing=JSON.parse_string(FileAccess.get_file_as_string(args[2]));actor_sha=FileAccess.get_sha256(args[1])
 var low:=Vector2(INF,INF);var high:=Vector2(-INF,-INF)
 for surface in data.surfaces:
  if surface.get("walkable",false):
   for p in surface.vertices:low=low.min(Vector2(p[0],p[2]));high=high.max(Vector2(p[0],p[2]))
 bounds=Rect2(low,high-low);var nav:=Nav.new()
 if not check(nav.configure(data,bounds,{"gate_main":true},.7,3.4)==OK,"HF08 source navigation"):finish();return
 runtime=Runtime.new()
 if not check(runtime.bind(nav,data)==OK,"HF08 runtime configured"):finish();return
 var document:=GLTFDocument.new();var gltf:=GLTFState.new()
 if not check(document.append_from_file(args[1],gltf)==OK,"existing source18 raw read, no copy/import"):finish();return
 var model:=document.generate_scene(gltf);packed=PackedScene.new()
 if not check(packed.pack(model)==OK,"source18 shared PackedScene"):model.free();finish();return
 model.free()
 var legacy:=Battle.new();legacy.setup(20);legacy.start();legacy.step()
 check(Save.save(legacy)==OK,"seed actual legacy quick slot");legacy_bytes=FileAccess.get_file_as_bytes(Save.FILE)
 sentinel=var_to_bytes({"grain":1234,"clock":83});write("user://world-sentinel.bin",sentinel)
 field=make_field(false)
 if field==null:finish();return
 check(not field.experimental_saves_enabled and not field.hud.save_button.visible and not field.hud.load_button.visible,"old authored Controller stays default-off")
 check(field.save_experimental()==ERR_UNAVAILABLE and field.load_experimental()==ERR_UNAVAILABLE,"disabled API no new save")
 var disabled_before:=bytes(field.battle)
 var save_key:=InputEventAction.new();save_key.action="campaign_quicksave";save_key.pressed=true
 var load_key:=InputEventAction.new();load_key.action="campaign_quickload";load_key.pressed=true
 field._unhandled_input(save_key);field._unhandled_input(load_key)
 check(bytes(field.battle)==disabled_before,"disabled real input path leaves typed Battle exact")
 check(not FileAccess.file_exists(Store.new(true).slot_path("controller20")),"disabled UI cannot write experimental slot")
 check(FileAccess.get_file_as_bytes(Save.FILE)==legacy_bytes,"disabled UI cannot touch legacy slot")
 field.free();field=make_field(true)
 if field==null:finish();return
 fixed_resources=resources();field.deploy()
 check(field.hud.save_button.visible and field.hud.load_button.visible,"only explicit Controller exposes experiment buttons")
 # Bounded real20 run. No HP/state/position edits, no direct Battle.step calls.
 # Exercise moving/queued hero input first, then any naturally observed actor death.
 for i in 24:pointer_and_step(i+10)
 var attack_key:=InputEventAction.new();attack_key.action="attack";attack_key.pressed=true
 field._unhandled_input(attack_key)
 for i in 5:pointer_and_step(i+20)
 field._unhandled_input(attack_key)
 check(field.battle.buffered_slot==0 and field.battle.buffer_ticks>0,"required real buffered basic attack coverage")
 checkpoints.append({"label":"pre_save_buffer_observation","buffered_slot":field.battle.buffered_slot,"buffer_ticks":field.battle.buffer_ticks})
 exercise("march_or_attack")
 var death_exercised:=false;var attack_exercised:=false
 for i in 500:
  pointer_and_step(i+30)
  var natural_dead:=false;var natural_attack:=false
  for item in field.ordinary_actor_bindings:
   var u=field.battle.roster[item.unit_id]
   natural_dead=natural_dead or u.hp<=0
   natural_attack=natural_attack or u.state in [Battle.State.WINDUP,Battle.State.RECOVER]
  if natural_attack and not attack_exercised:exercise("natural_attack");attack_exercised=true
  if natural_dead and not death_exercised:
   exercise("natural_death");death_exercised=true
   for after in 20:pointer_and_step(after+70)
   exercise("aged_natural_corpse");break
  if not field.battle.result.is_empty():break
 check(field.battle.ordinary_counts==PackedInt32Array([20,20]),"actual20vs20 retained")
 check(death_exercised,"required natural source18 death and aged corpse coverage")
 check(actor_role_coverage.hero_thrust_ids.has(field.battle.hero.id),"required thrust belongs to actual hero ID")
 check(not actor_role_coverage.ordinary_walk_ids.is_empty(),"required walk belongs to actual nonhero nonofficer ordinary unit")
 check(state_coverage.has("death"),"required natural death semantic coverage")
 failure_cases()
 unsupported_resume_cases()
 check(FileAccess.get_file_as_bytes(Save.FILE)==legacy_bytes,"legacy quick bytes remain exact")
 check(FileAccess.get_file_as_bytes("user://world-sentinel.bin")==sentinel,"world sentinel untouched")
 checkpoints.append({"label":"final","tick":field.battle.tick,"attacks":field.battle.attacks,"hits":field.battle.hits,"losses":field.battle.losses,"natural_attack_covered":attack_exercised,"natural_death_covered":death_exercised})
 finish()
func finish():
 var report:={"status":"PASS" if failures.is_empty() else "FAIL","checks":checks,"failures":failures,"checkpoints":checkpoints,"presentation_coverage":state_coverage,"actor_role_coverage":actor_role_coverage,"source18_sha256":actor_sha,"scope":"real CPU SceneTree Controller; identity fixture host; no GPU, complete mother render, M5, release or art acceptance"}
 if field!=null:field.free();field=null
 if not output.is_empty():write(output,JSON.stringify(report,"  ").to_utf8_buffer())
 print("CONTROLLER_SAVE_RESUME ",JSON.stringify(report));quit(0 if failures.is_empty() else 1)
