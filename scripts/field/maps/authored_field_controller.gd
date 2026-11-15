extends "res://scripts/field/controller.gd"
## Explicit internal complete-mother entry. No menu/default route creates this.
## Real base Controller input + physics; no independent simulation or HP writes.
const AuthoredHost:=preload("res://scripts/field/maps/authored_scene_host.gd")
var authored_bounds:Rect2
var skeletal_actor:Node3D
var skeletal_binding:RefCounted
var actor_receipt:Dictionary={}
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
func _ready()->void:
 if not configured:
  push_error("Authored Controller requires explicit complete source configuration");set_process(false);set_physics_process(false);return
 Actions.install();_apply_viewport_quality(Quality.NATIVE_MSAA)
 add_child(map);add_child(camera);camera.current=true;camera.far=360.
 add_child(hud);add_child(audio);add_child(skeletal_actor)
 view=Figures.new();add_child(view);view.configure(battle);view.review_hidden_actor_id=battle.hero.id
 hud.bind(battle);hud.deploy.connect(deploy);hud.pause.connect(toggle_pause);hud.order_requested.connect(_order)
 hud.unit.item_selected.connect(func(i:int):hud.select_company(battle,i))
 for control in [hud.inset,hud.plan,hud.weapon,hud.slot,hud.shape,hud.front,hud.save_button,hud.load_button,hud.continue_slot,hud.change,hud.legacy]:control.hide()
 hud.order_panel.hide();_refresh_hud();_camera();_draw_field()
func _adopt(_fresh:Battle)->bool:return false # Never load a legacy battle into this mother scene.
func _save()->void:battle.notice="内部新地图暂不写入旧存档";_refresh_hud()
func _load()->void:battle.notice="内部新地图禁止载入旧地图存档";_refresh_hud()
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
 view.sync_view(camera_center,half,clampf(carry/Battle.DT,0.,1.),camera.size,center)
 actor_receipt=skeletal_binding.update(battle,skeletal_actor,presentation_delta,clampf(carry/Battle.DT,0.,1.))
 map.update_battle(battle);hud.marker.hide();hud.inset.hide()
 if frame_log:frame_log.pose_submitted(battle)
func _process(delta:float)->void:
 presentation_delta=delta;super._process(delta)
func _refresh_hud()->void:
 if not configured:return
 hud.update_model(battle,paused);hud.inset.hide()
 hud.feedback.text=internal_label+" | 新英雄 WIP / 旧群体诊断 / 无世界结算"
