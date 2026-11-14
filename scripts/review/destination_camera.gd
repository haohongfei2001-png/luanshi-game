extends RefCounted
## Experimental complete-destination framing; never an official MOBA parameter.
const Body:=preload("res://scripts/review/author_unit_oracle.gd")
static func apply(field:Node,actor:Node3D,variant:String="destination26")->Dictionary:
 if variant not in ["destination26","destination28"]:return {"error":"UNKNOWN_DESTINATION_CANDIDATE"}
 var before=Body.projected_body(actor,field.camera)
 if before.has('error'):return {'error':'BASELINE_BODY_UNAVAILABLE'}
 var target:float=before.height_fraction
 field.camera_yaw=deg_to_rad(-65.)
 field.camera_center=field.battle.hero.pos+Vector2(3. if variant=='destination26' else 4.,0.)
 field.review_camera_profile={'projection':'perspective','nominal_body_fraction':.10,'pitch_degrees':26. if variant=='destination26' else 28.,'fov_degrees':65. if variant=='destination26' else 70.,'look_height':1.5,'follow_lead_world':[3. if variant=='destination26' else 4.,0.]}
 var low:=.03;var high:=.30
 for iteration in 24:
  field.review_camera_profile.nominal_body_fraction=(low+high)*.5
  field._camera()
  var current=Body.projected_body(actor,field.camera)
  if current.has('error'):return {'error':'CANDIDATE_BODY_UNAVAILABLE'}
  if float(current.height_fraction)<target:low=float(field.review_camera_profile.nominal_body_fraction)
  else:high=float(field.review_camera_profile.nominal_body_fraction)
 var after=Body.projected_body(actor,field.camera)
 if absf(float(after.height_fraction)-target)>0.0001:return {'error':'BODY_SCREEN_SCALE_CHANGED'}
 return {'error':OK,'before':before,'after':after,'variant':variant,'lead_metres':3. if variant=='destination26' else 4.,'look_height_above_ground_m':1.5,'profile':field.review_camera_profile.duplicate(),'scope':'COMPLETE_DESTINATION_INTERNAL_CANDIDATE; unchanged actor scale; not visual acceptance'}
static func projected_gate(model:Node,camera:Camera3D)->Dictionary:
 var hall=model.find_child('GateHall',true,false)
 if hall==null:return {'error':'GATE_HALL_MISSING'}
 var rect:=Rect2();var first:=true;var count:=0
 for child in hall.find_children('*','MeshInstance3D',true,false):
  var bounds: AABB=child.get_aabb()
  for i in 8:
   var point:Vector3=child.global_transform*bounds.get_endpoint(i)
   if camera.is_position_behind(point):return {'error':'GATE_BEHIND_CAMERA'}
   var screen=camera.unproject_position(point)/camera.get_viewport().get_visible_rect().size
   if first:rect=Rect2(screen,Vector2.ZERO);first=false
   else:rect=rect.expand(screen)
   count+=1
 return {'normalized_rect':[rect.position.x,rect.position.y,rect.end.x,rect.end.y],'bound_points':count,'all_bounds_inside':rect.position.x>=0. and rect.position.y>=0. and rect.end.x<=1. and rect.end.y<=1.,'scope':'conservative actual gate-hall mesh bounds, not visibility/occlusion or art proof'}
