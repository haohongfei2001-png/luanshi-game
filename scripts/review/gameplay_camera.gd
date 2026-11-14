extends RefCounted
## Owner-directed player-centred candidate, NOT official Riot camera parameters.
const Body:=preload('res://scripts/review/author_unit_oracle.gd')
static func apply(field:Node,actor:Node3D)->Dictionary:
 const TARGET:=.125
 field.camera_yaw=deg_to_rad(-65.)
 field.camera_center=field.battle.hero.pos+Vector2(1.5,0.)
 field.review_camera_profile={'profile_id':'gameplay45','projection':'perspective','nominal_body_fraction':.125,'pitch_degrees':45.,'fov_degrees':50.,'look_height':1.,'follow_lead_world':[1.5,0.]}
 var low:=.03;var high:=.40
 for iteration in 24:
  field.review_camera_profile.nominal_body_fraction=(low+high)*.5;field._camera()
  var body=Body.projected_body(actor,field.camera)
  if body.has('error'):return {'error':'BODY_PROJECTION_UNAVAILABLE'}
  if float(body.height_fraction)<TARGET:low=float(field.review_camera_profile.nominal_body_fraction)
  else:high=float(field.review_camera_profile.nominal_body_fraction)
 var actual=Body.projected_body(actor,field.camera)
 if absf(float(actual.height_fraction)-TARGET)>.0001:return {'error':'PLAYER_SCREEN_SCALE_CHANGED'}
 return {'error':OK,'variant':'gameplay45','target_body_fraction':TARGET,'after':actual,'profile':field.review_camera_profile.duplicate(),'scope':'PLAYER_CENTRED_LOCAL_BATTLE; normal character size; structures may naturally crop; NOT art acceptance or official reference-game parameters'}
static func projected_structure(model:Node,camera:Camera3D)->Dictionary:
 var rect:=Rect2();var first:=true;var front:=0;var behind:=0
 for child in model.find_children('*','MeshInstance3D',true,false):
  var bounds:AABB=child.get_aabb()
  for i in 8:
   var point:Vector3=child.global_transform*bounds.get_endpoint(i)
   if camera.is_position_behind(point):behind+=1;continue
   var screen=camera.unproject_position(point)/camera.get_viewport().get_visible_rect().size
   if first:rect=Rect2(screen,Vector2.ZERO);first=false
   else:rect=rect.expand(screen)
   front+=1
 return {'normalized_front_bounds':[rect.position.x,rect.position.y,rect.end.x,rect.end.y],'front_bound_points':front,'behind_bound_points':behind,'scope':'RAW_GEOMETRY_PROJECTION; allowed natural out-of-frame structures, NOT actual visibility or occlusion measurement'}
