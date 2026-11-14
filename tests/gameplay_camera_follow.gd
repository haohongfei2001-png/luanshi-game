extends SceneTree
## Real Controller _process/_camera, only resource-heavy setup/draw suppressed.
## No substitute camera math; this is headless projection, NOT gameplay GPU.
const Field=preload("res://scripts/field/controller.gd")
class CameraField extends Field:
	func _ready()->void:pass
	func _draw_field()->void:pass
	func _refresh_hud()->void:pass
func _initialize()->void:call_deferred("run")
func run()->void:
	var field=CameraField.new();root.add_child(field)
	field.set_process(false);field.set_physics_process(false)
	field.add_child(field.camera)
	field.battle=Field.Battle.new();field.battle.setup(20,Field.Battle.SEED,Field.Battle.Arms.Kit.SPEAR,true,true,-1,true);field.battle.start()
	field.follow=true;field.camera_yaw=deg_to_rad(-65.0)
	field.review_camera_profile={"projection":"perspective","pitch_degrees":45.0,"nominal_body_fraction":0.12,"fov_degrees":50.0,"look_height":1.0,"follow_lead_world":[1.5,0.0]}
	var profile=field.review_camera_profile.duplicate(true)
	field.camera_center=field.battle.hero.pos+Vector2(1.5,0.0)
	var old=field.camera_center
	for i in 120:
		field.battle.input_state(Vector2.RIGHT*0.6,Vector2.RIGHT);field.battle.step()
		var expected=field.camera_center.lerp(field.battle.hero.pos+Vector2(1.5,0.0),1.0-exp(-(1.0/60.0)*7.5))
		field._process(1.0/60.0)
		assert(field.camera_center.distance_to(expected)<0.000001)
		assert(field.camera.projection==Camera3D.PROJECTION_PERSPECTIVE)
		assert(is_equal_approx(field.camera.fov,50.0))
		assert(is_equal_approx(field.camera_pitch,deg_to_rad(45.0)))
		assert(field.review_camera_profile==profile)
		var target=field.camera.position-field.camera.basis.z*(field.camera.position-Field.Ground.unit_point(field.camera_center,true)-Vector3(0,1.0,0)).length()
		assert(target.distance_to(Field.Ground.unit_point(field.camera_center,true)+Vector3(0,1.0,0))<0.0001)
	assert(field.camera_center.distance_to(old)>0.1)
	print("GAMEPLAY_REAL_CONTROLLER_CAMERA_PASS 120steps gameplay45 FOV50 pitch45 yaw-65 lead1.5 lookheight1.0 retained; renderer/actor NOT_RUN")
	var detached:Array=[]
	collect_script_nodes(field,{},detached)
	field.free()
	for node in detached:
		if is_instance_valid(node) and node.get_parent()==null:node.free()
	quit()
func collect_script_nodes(node:Node,seen:Dictionary,found:Array)->void:
	if seen.has(node.get_instance_id()):return
	seen[node.get_instance_id()]=true
	for property in node.get_property_list():
		if int(property.usage)&PROPERTY_USAGE_SCRIPT_VARIABLE==0:continue
		var value=node.get(property.name)
		if value is Node and is_instance_valid(value):
			found.append(value);collect_script_nodes(value,seen,found)
