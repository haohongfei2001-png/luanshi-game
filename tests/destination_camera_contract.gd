extends SceneTree
const Fit:=preload("res://scripts/review/destination_camera.gd")
const Author:=preload("res://scripts/review/author_unit_oracle.gd")
const Store:=preload("res://scripts/field/save.gd")
func _initialize()->void:run.call_deferred()
func check(ok:bool,message:String)->bool:
 if ok:return true
 push_error(message);quit(1);return false
func run()->void:
 root.size=Vector2i(2560,1440)
 await process_frame;await process_frame
 if not check(OS.get_environment('LUANSHI_AUTHORED_LANDFORM')=='1','Ground version must match'):return
 var scene=load('res://scenes/game.tscn').instantiate();root.add_child(scene);await process_frame
 var field=scene.field
 field.selections=20;field.opposing_selection=20;field.hud.plan_requested.emit(5)
 field.set_process(false);field.set_physics_process(false);field.follow=false
 field.map.master.visible=false
 var model=(load('res://assets/river_authored/architecture/architecture.glb') as PackedScene).instantiate();field.add_child(model)
 field.hud.go.pressed.emit()
 for tick in 135:field._physics_process(.05)
 var snapshot=var_to_bytes(Store.snapshot(field.battle))
 var bound=Author.bind(field,OS.get_environment('LUANSHI_AUTHOR_ORACLE_CACHE'))
 if not check(bound.error==OK,'Author binding failed'):return
 var actor=bound.actor
 # The optional look-height field must not change the original no-review path.
 field.review_camera_profile={};field._camera();var default_transform=field.camera.transform
 field._camera()
 if not check(field.camera.transform==default_transform,'Default camera drift'):return
 var records=[]
 for variant in ['destination26','destination28']:
  field.camera_yaw=deg_to_rad(-65.);field.camera_center=field.battle.hero.pos+Vector2(4.,0.)
  field.review_camera_profile={'projection':'perspective','nominal_body_fraction':.10,'pitch_degrees':32.,'fov_degrees':55.}
  field._camera()
  var implicit_height=field.camera.transform
  field.review_camera_profile['look_height']=.8;field._camera()
  if not check(field.camera.transform==implicit_height,'Omitted look_height changed the legacy review camera'):return
  var result=Fit.apply(field,actor,variant)
  if not check(result.error==OK,'Candidate body scale solver failed'):return
  var gate=Fit.projected_gate(model,field.camera)
  print('DESTINATION_DIAGNOSTIC ',variant,' ',JSON.stringify({'gate':gate,'body':result}))
  if not check(not gate.has('error') and gate.all_bounds_inside,'Complete actual gate bounds clipped'):return
  if not check(var_to_bytes(Store.snapshot(field.battle))==snapshot,'Framing changed battle'):return
  if not check(float(result.after.boot_bottom_y)/root.get_visible_rect().size.y<.75,'Hero pushed too far down'):return
  records.append({'variant':variant,'body':result,'gate':gate,'camera_origin':str(field.camera.global_position),'camera_target':str(field.camera_center),'battle_unchanged':true})
 print('DESTINATION_CAMERA_CONTRACT_PASS ',JSON.stringify({'records':records,'scope':'HEADLESS actual geometry projection only; no GPU/art/occlusion acceptance'}))
 scene.queue_free();await process_frame;await process_frame;quit()
