extends "res://scripts/field/controller.gd"
## Explicit internal complete-mother entry. No menu/default route creates this.
## Real base Controller input + physics; no independent simulation or HP writes.
const ExperimentalStore:=preload("res://scripts/field/experimental_map_save.gd")
const MappedState:=preload("res://scripts/field/maps/mapped_save_state.gd")
const SpearBinding:=preload("res://scripts/field/experimental/production_v2/mh_spear_battle_binding.gd")
const SkeletalActor:=preload("res://scripts/field/experimental/production_v2/shared_skeletal_actor.gd")
const AuthoredHost:=preload("res://scripts/field/maps/authored_scene_host.gd")
# A second, explicit opt-in after configure(), before entering the tree.
var experimental_saves_enabled:=false
var experimental_save_slot:=""
var experimental_save_notice:=""
var _experimental_store:=ExperimentalStore.new()
var _save_runtime:ExperimentalStore.Runtime
var authored_bounds:Rect2
var skeletal_actor:Node3D
var skeletal_binding:RefCounted
var actor_receipt:Dictionary={}
var ordinary_actor_receipts:Dictionary={}
var ordinary_actor_bindings:Array=[]
const MAX_NEW_ORDINARY_PER_TEAM:=3
var configured:=false
var presentation_delta:=0.
var internal_label:="INTERNAL_INTERFACE_FIXTURE_NOT_ART"
var source_height_range:=Vector2(-32,64)
func configure(fresh:Battle,host:AuthoredHost,actor:Node3D,binding:RefCounted,bounds:Rect2,label:String)->Error:
 if configured or is_inside_tree():return ERR_ALREADY_IN_USE
 if fresh==null or fresh.map_runtime.is_legacy or host==null or not host.configured:return ERR_INVALID_DATA
 if actor==null or binding==null or not binding.enabled or not binding.ground_point.is_valid():return ERR_INVALID_DATA
 if fresh.map_runtime.identity().topology_sha256!=host.expected_identity.topology_sha256:return ERR_FILE_CORRUPT
 if bounds.size.x<=0 or bounds.size.y<=0 or label.is_empty():return ERR_INVALID_PARAMETER
 # The unused inherited Landscape never enters the tree or builds geometry.
 map.sun.free();map.free();map=host;battle=fresh
 skeletal_actor=actor;skeletal_binding=binding;authored_bounds=bounds;internal_label=label
 review_camera_profile={"pitch_degrees":45.,"nominal_body_fraction":.125,"projection":"perspective","fov_degrees":50.,"look_height":1.,"follow_lead_world":[1.5,0.]}
 camera_yaw=deg_to_rad(-65.);camera_center=battle.hero.pos
 source_height_range=Vector2(INF,-INF)
 for triangle in fresh.map_runtime.nav.support._triangles:
  for point in [triangle.a,triangle.b,triangle.c]:
   source_height_range.x=minf(source_height_range.x,point.y-.05);source_height_range.y=maxf(source_height_range.y,point.y+.05)
 configured=true;return OK
func configure_experimental_saves(slot:String="controller_resume")->Error:
 if not configured or is_inside_tree() or experimental_saves_enabled:return ERR_ALREADY_IN_USE
 if _experimental_store.slot_path(slot).is_empty():return ERR_INVALID_PARAMETER
 if not MappedState.supports_runtime(battle.map_runtime):return ERR_UNAVAILABLE
 if not skeletal_binding is SpearBinding or not skeletal_actor is SkeletalActor:return ERR_UNAVAILABLE
 for item in ordinary_actor_bindings:
  if not item.binding is SpearBinding or not item.actor is SkeletalActor:return ERR_UNAVAILABLE
 _save_runtime=battle.map_runtime;experimental_save_slot=slot
 _experimental_store=ExperimentalStore.new(true);experimental_saves_enabled=true
 return OK
func _save_context_valid()->bool:
 if not experimental_saves_enabled or not configured or not is_node_ready() or battle==null:return false
 if battle.map_runtime!=_save_runtime or not MappedState.supports_runtime(_save_runtime):return false
 var identity:=_save_runtime.identity()
 for key in ["map_id","topology_revision","topology_sha256"]:
  if identity.get(key)!=map.expected_identity.get(key):return false
 return true
func save_experimental()->Error:
 if not _save_context_valid() or not _presentation_resumable(battle):return ERR_UNAVAILABLE
 return _experimental_store.save(battle,experimental_save_slot)
func load_experimental()->Error:
 if not _save_context_valid():return ERR_UNAVAILABLE
 var restored:=_experimental_store.load_slot(_save_runtime,experimental_save_slot)
 if restored==null:return ERR_FILE_CORRUPT
 if not _adopt_experimental(restored):return ERR_UNAVAILABLE
 return OK
func _presentation_resumable(restored:Battle)->bool:
 # All actors must be sampleable before any live scene, input or binding writes.
 if not _save_context_valid() or restored==null or restored.map_runtime!=_save_runtime:return false
 # Fixed actor IDs were selected from this roster; do not remap them to a
 # different-size army where the same index could name the opposing side.
 if restored.ordinary_counts!=battle.ordinary_counts:return false
 if restored.hero.kit!=Battle.Arms.Kit.SPEAR or restored.hero.mounted or restored.vehicle!=0:return false
 if not skeletal_binding is SpearBinding or not skeletal_actor is SkeletalActor:return false
 if not skeletal_binding.can_resume(restored,restored.hero,skeletal_actor):return false
 for item in ordinary_actor_bindings:
  if not item.binding is SpearBinding or not item.actor is SkeletalActor:return false
  if item.unit_id<0 or item.unit_id>=restored.roster.size():return false
  var unit=restored.roster[item.unit_id]
  if unit.hero or unit.officer or unit.mounted or unit.kit!=Battle.Arms.Kit.SPEAR or unit.team!=battle.roster[item.unit_id].team:return false
  if not item.binding.can_resume(restored,unit,item.actor):return false
 return true
func _adopt_experimental(restored:Battle)->bool:
 # No base _adopt: Campaign.bind would reset world/army state. No new muster.
 if not _presentation_resumable(restored):return false
 var replacement:=Figures.new()
 # configure() is not repeatable: it creates MultiMeshes. Replace, never append.
 replacement.configure(restored)
 replacement.contact_for_all=view.contact_for_all
 remove_child(view);view.free();view=replacement;add_child(view)
 battle=restored;selections=battle.side_size;opposing_selection=battle.ordinary_counts[1]
 skeletal_binding.reset_for_resume(battle,battle.hero)
 skeletal_actor.player.stop();skeletal_actor.skeleton.reset_bone_poses();skeletal_actor.show()
 view.review_hidden_actor_id=battle.hero.id
 actor_receipt.clear();ordinary_actor_receipts.clear()
 for item in ordinary_actor_bindings:
  item.binding.reset_for_resume(battle,battle.roster[item.unit_id]);item.actor.player.stop();item.actor.skeleton.reset_bone_poses()
  item.active=true;item.actor.show();view.review_hidden_actor_ids[item.unit_id]=true
 # UI/device state is not simulation state. Keep serialized hero_move, aim,
 # sprinting and buffered actions EXACT until the next normal input sample.
 for action in ["move_left","move_right","move_up","move_down","attack","sweep","lunge","guard","field_sprint"]:
  Input.action_release(action)
 pan=false;orbiting=false;follow=true;paused=true
 carry=0.;ui_clock=0.;presentation_delta=0.;step_distance=0.
 sim_us=0;view_us=0;max_step_us=0
 last_hero_hit=-100;last_sound_tick=battle.tick;last_shot_tick=battle.tick
 camera_center=battle.hero.pos
 for voice in audio.voices:voice.stop()
 audio.next=0
 hud.bind(battle);hud.order_panel.visible=not battle.started
 _refresh_hud();_camera();_draw_field()
 return true
func configure_ordinary_spearmen(instances:Array)->Error:
 # Default empty. This is a small real-unit art probe, not a thousand-skeleton
 # replacement. Never turn archers/officers/riders into generic spearmen.
 if not configured or is_inside_tree() or experimental_saves_enabled or not ordinary_actor_bindings.is_empty():return ERR_ALREADY_IN_USE
 if instances.size()>2*MAX_NEW_ORDINARY_PER_TEAM:return ERR_PARAMETER_RANGE_ERROR
 var ids:Dictionary={};var actors:Dictionary={};var bindings:Dictionary={};var counts:=[0,0]
 for spec in instances:
  if not spec is Dictionary or not spec.get("unit_id") is int:return ERR_INVALID_DATA
  var id:int=spec.unit_id
  if id<0 or id>=battle.roster.size() or ids.has(id):return ERR_INVALID_DATA
  var unit=battle.roster[id]
  if unit.hero or unit.officer or unit.mounted or unit.kit!=Battle.Arms.Kit.SPEAR or unit.hp<=0:return ERR_UNAVAILABLE
  var actor=spec.get("actor");var binding=spec.get("binding")
  if not actor is Node3D or not binding is RefCounted or not binding.has_method("update_unit"):return ERR_INVALID_DATA
  if actor==skeletal_actor or binding==skeletal_binding or actor.get_parent()!=null or actors.has(actor.get_instance_id()) or bindings.has(binding.get_instance_id()):return ERR_INVALID_DATA
  if not binding.enabled or binding.ground_point.get_object()!=battle.map_runtime or binding.ground_point.get_method()!=&"unit_point":return ERR_INVALID_DATA
  counts[unit.team]+=1
  if counts[unit.team]>MAX_NEW_ORDINARY_PER_TEAM:return ERR_PARAMETER_RANGE_ERROR
  ids[id]=true;actors[actor.get_instance_id()]=true;bindings[binding.get_instance_id()]=true
 for spec in instances:ordinary_actor_bindings.append({"unit_id":spec.unit_id,"actor":spec.actor,"binding":spec.binding,"active":false})
 return OK
func _ready()->void:
 if not configured:
  push_error("Authored Controller requires explicit complete source configuration");set_process(false);set_physics_process(false);return
 Actions.install();_apply_viewport_quality(Quality.NATIVE_MSAA)
 add_child(map);add_child(camera);camera.current=true;camera.far=360.
 add_child(hud);add_child(audio);add_child(skeletal_actor)
 view=Figures.new();add_child(view);view.configure(battle);view.review_hidden_actor_id=battle.hero.id
 for item in ordinary_actor_bindings:
  add_child(item.actor)
  var receipt:Dictionary=item.binding.update_unit(battle,battle.roster[item.unit_id],item.actor,0.,1.)
  ordinary_actor_receipts[item.unit_id]=receipt
  if receipt.get("supported",false):view.review_hidden_actor_ids[item.unit_id]=true;item.active=true
  else:item.actor.hide() # Original real unit remains visible if binding failed.
 hud.bind(battle);hud.deploy.connect(deploy);hud.pause.connect(toggle_pause);hud.order_requested.connect(_order)
 hud.unit.item_selected.connect(func(i:int):hud.select_company(battle,i))
 for control in [hud.inset,hud.plan,hud.weapon,hud.slot,hud.shape,hud.front,hud.save_button,hud.load_button,hud.continue_slot,hud.change,hud.legacy]:control.hide()
 if experimental_saves_enabled:
  hud.save_requested.connect(_save);hud.load_requested.connect(_load)
  hud.save_button.text="实验保存 F5";hud.load_button.text="实验读档 F9"
  hud.save_button.show();hud.load_button.show()
 hud.order_panel.hide();_refresh_hud();_camera();_draw_field()
func _adopt(_fresh:Battle)->bool:return false # Never load a legacy battle into this mother scene.
func _save()->void:
 if not experimental_saves_enabled:
  experimental_save_notice="内部新地图暂不写入旧存档";_refresh_hud();return
 var error:=save_experimental()
 experimental_save_notice="实验进度已保存" if error==OK else "实验保存失败，原存档保留"
 _refresh_hud()
func _load()->void:
 if not experimental_saves_enabled:
  experimental_save_notice="内部新地图禁止载入旧地图存档";_refresh_hud();return
 var error:=load_experimental()
 experimental_save_notice="实验进度已恢复，已暂停" if error==OK else "实验读档被拒，当前战场保留"
 _refresh_hud()
func deploy()->void:
 if not battle.started:battle.start();paused=false;hud.order_panel.hide()
func _synchronize_world_after_step()->bool:
 # This internal mode has no campaign clock/settlement. It is not a fake sync PASS.
 return not battle.map_runtime.is_legacy and not battle.objectives.enabled
func _unhandled_input(event:InputEvent)->void:
 if event.is_action_pressed("field_mount") or event.is_action_pressed("field_chariot"):
  battle.notice="新地图骑乘接线尚未验收";return
 super._unhandled_input(event)
func _camera()->void:
 var authored_shadow_distance:=map.sun.directional_shadow_max_distance
 var authored_shadow_fade:=map.sun.directional_shadow_fade_start
 super._camera()
 map.sun.directional_shadow_max_distance=authored_shadow_distance
 map.sun.directional_shadow_fade_start=authored_shadow_fade
func _camera_ground_point()->Vector3:
 var p:=battle.map_runtime.unit_point(camera_center)
 if is_finite(p.y):return p
 # A camera can look over water. Only the camera focus uses a neighbouring
 # supported height; all actual units still use strict source support.
 var nav=battle.map_runtime.nav;var id:int=nav.graph.get_closest_point(camera_center)
 if id<0:return battle.map_runtime.unit_point(battle.hero.pos)
 p.y=battle.map_runtime.height(nav.graph.get_point_position(id));return p
func pan_to(p:Vector2)->void:
 follow=false;camera_center=p.clamp(authored_bounds.position,authored_bounds.end);_camera()
func _screen_ground(point:Vector2)->Vector2:
 var origin:=camera.project_ray_origin(point);var direction:=camera.project_ray_normal(point)
 if absf(direction.y)<.00001:return battle.hero.pos
 var start:=maxf(0.,(source_height_range.y-origin.y)/direction.y)
 var end:=maxf(start,(source_height_range.x-origin.y)/direction.y)
 # Query exact tagged support triangles along the projected ray. Visual roofs
 # are not support surfaces, and no legacy height ray can override the mother.
 var support=battle.map_runtime.nav.support
 var count:=maxi(1,ceili((end-start)*Vector2(direction.x,direction.z).length()/.5))
 var tested:Dictionary={};var best_distance:=INF;var best:=Vector2.ZERO
 for index in range(count+1):
  var at:=lerpf(start,end,float(index)/count);var p:=origin+direction*at
  var cell:=Vector2i(floori(p.x/support.CELL),floori(p.z/support.CELL))
  for dx in range(-1,2):
   for dz in range(-1,2):
    for slot in support._cells.get(cell+Vector2i(dx,dz),[]):
     if tested.has(slot):continue
     tested[slot]=true;var triangle:Dictionary=support._triangles[slot]
     var hit=Geometry3D.ray_intersects_triangle(origin,direction,triangle.a,triangle.b,triangle.c)
     if hit==null:continue
     var distance:float=origin.distance_squared_to(hit)
     if distance<best_distance:best_distance=distance;best=Vector2(hit.x,hit.z)
 if is_finite(best_distance):return best
 # Invalid surface click aims along the ray but is not a walk/teleport request.
 var fallback:=origin+direction*end;return Vector2(fallback.x,fallback.z)
func _aim_point(screen:Vector2,target_figures:bool)->Vector2:
 var floor:=_screen_ground(screen)
 if not is_finite(battle.map_runtime.height(floor)):return floor
 return super._aim_point(screen,target_figures)
func _draw_field()->void:
 if not configured or view==null:return
 var footprint:=ReviewFrustum.bounds(camera,source_height_range.x,source_height_range.y,8.)
 var center:Vector2=footprint.center if footprint.valid else authored_bounds.get_center()
 var half:Vector2=footprint.half_extent if footprint.valid else authored_bounds.size*.5
 # Once simulation stops, present its final authoritative transform, not a stale before point.
 var alpha:=1.0 if paused or not battle.result.is_empty() else clampf(carry/Battle.DT,0.,1.)
 view.sync_view(camera_center,half,alpha,camera.size,center)
 actor_receipt=skeletal_binding.update(battle,skeletal_actor,presentation_delta,alpha)
 for item in ordinary_actor_bindings:
  if item.active:ordinary_actor_receipts[item.unit_id]=item.binding.update_unit(battle,battle.roster[item.unit_id],item.actor,presentation_delta,alpha)
 map.update_battle(battle);hud.marker.hide();hud.inset.hide()
 if frame_log:frame_log.pose_submitted(battle)
func _process(delta:float)->void:
 presentation_delta=delta;super._process(delta)
func _refresh_hud()->void:
 if not configured:return
 hud.update_model(battle,paused);hud.inset.hide()
 hud.feedback.text=internal_label+" | 新英雄 WIP / 新普通枪兵 %d / 其余旧群体诊断 / 无世界结算" % view.review_hidden_actor_ids.size()
 if not experimental_save_notice.is_empty():
  hud.feedback.text+=" | "+experimental_save_notice
  # HUD's ordinary notice lifetime belongs to Battle.notice. This independent
  # experiment status remains visible until the next save/load attempt.
  hud.feedback.show()
