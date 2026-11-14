extends SceneTree
const Store:=preload('res://scripts/field/save.gd')
func _initialize()->void:run.call_deferred()
func run()->void:
 var scene=load('res://scenes/game.tscn').instantiate();root.add_child(scene);await process_frame
 var field=scene.field;field.set_process(false);field.set_physics_process(false)
 field.selections=20;field.opposing_selection=20;field.hud.plan_requested.emit(5);field.hud.go.pressed.emit()
 for tick in 135:field._physics_process(.05)
 field.camera_center=Vector2(34.2,1);field.camera.size=22.;field._camera()
 var baseline=field.camera.global_transform;var baseline_projection=field.camera.get_camera_projection()
 var snapshot=var_to_bytes(Store.snapshot(field.battle));var rows=[]
 for projection in ['orthographic','perspective']:
  for fraction in [.1,.12,.14]:
   field.review_camera_profile={'projection':projection,'nominal_body_fraction':fraction,'pitch_degrees':42.,'fov_degrees':40.}
   field._camera();field._draw_field()
   assert(var_to_bytes(Store.snapshot(field.battle))==snapshot,'Review camera must not step or modify real battle')
   assert(field.camera_center==Vector2(34.2,1),'Culling footprint must not change camera target')
   assert(is_equal_approx(field.camera.near,.1) and is_equal_approx(field.camera.far,400.))
   var foot=field.Ground.unit_point(field.camera_center,field.battle.bridgehead)
   var pixels=root.get_visible_rect().size
   var b=Rect2(field.camera.unproject_position(foot),Vector2.ZERO)
   for x in [-.275,.275]:
    for y in [0.,1.8]:
     for z in [-.175,.175]:b=b.expand(field.camera.unproject_position(foot+Vector3(x,y,z)))
   assert(absf(b.size.y/pixels.y-fraction)<.003,'Nominal adult measurement misses target')
   rows.append({'projection':projection,'target_nominal_fraction':fraction,'actual_anonymous_box_fraction':b.size.y/pixels.y,'pitch':42.,'camera_size':field.camera.size,'camera_fov':field.camera.fov,'graphics':'NOT_RUN'})
 for yaw in [-65.,-75.]:
  field.camera_yaw=deg_to_rad(yaw)
  for ahead in [4.]:
   field.camera_center=field.battle.hero.pos+Vector2(ahead,0)
   field.review_camera_profile={'projection':'perspective','nominal_body_fraction':.12,'pitch_degrees':32.,'fov_degrees':55.}
   field._camera()
   var visible=true;var bounds=Rect2(Vector2.INF,Vector2.ZERO);var first=true
   for y in [0.,4.2]:
    for z in [-4.,4.]:
     var world=Vector3(48,y,z);visible=visible and field.camera.is_position_in_frustum(world)
     var at=field.camera.unproject_position(world)/root.get_visible_rect().size
     if first:bounds=Rect2(at,Vector2.ZERO);first=false
     else:bounds=bounds.expand(at)
   var hero_floor=field.Ground.unit_point(field.battle.hero.pos,true)
   var hero_rect=Rect2(field.camera.unproject_position(hero_floor),Vector2.ZERO)
   for xx in [-.275,.275]:
    for yy in [0.,1.8]:
     for zz in [-.175,.175]:hero_rect=hero_rect.expand(field.camera.unproject_position(hero_floor+Vector3(xx,yy,zz)))
   print('GATE_DESTINATION_PROJECTION ',JSON.stringify({'actual_hero_box_fraction':hero_rect.size.y/root.get_visible_rect().size.y,'yaw_degrees':rad_to_deg(field.camera_yaw),'ahead':ahead,'hero':str(field.battle.hero.pos),'center':str(field.camera_center),'all_opening_corners_in_frustum':visible,'normalized_opening_bounds':str(bounds),'scope':'PROJECTED_ONLY_NOT_IMAGE_ACCEPTANCE'}))
 field.camera_yaw=deg_to_rad(-33.)
 field.camera_center=Vector2(34.2,1)
 field.review_camera_profile={};field.camera.size=22.;field.shadow_zoom=-1.;field._camera()
 assert(field.camera.global_transform.is_equal_approx(baseline),'Default camera transform changed')
 for column in 4:assert(field.camera.get_camera_projection()[column].is_equal_approx(baseline_projection[column]),'Default camera projection changed')
 print('REVIEW_CAMERA_CONTRACT_PASS ',JSON.stringify(rows))
 scene.queue_free();await process_frame;await process_frame;await create_timer(.2).timeout;quit()
