class_name DotProductionV2NativeCapture
extends "res://scripts/review/production_v2_entry.gd"
const MaterialControl=preload("res://scripts/review/production_v2_material_control.gd")
const UVAdapter=preload("res://scripts/field/experimental/production_v2/uv_spatial/adapter.gd")
const Save=preload("res://scripts/field/save.gd")
const Recorder=preload("res://scripts/review/production_v2_wall_recorder.gd")
const Pilot=preload("res://scripts/field/experimental/production_v2/contact_input_pilot.gd")
var output:=OS.get_environment("PRODUCTION_NATIVE_OUT")
func start()->void:
 super.start()
 if field==null or entry_receipt.is_empty():return
 if entry_receipt.get("validate_only",false):return
 if DisplayServer.get_name()=="headless" or OS.get_name()!="macOS":fail("native graphics requires authorized macOS hosted job");return
 if output.is_empty():fail("explicit native output path required");return
 field.set_process(false);field.set_physics_process(false);field.paused=true
 DirAccess.make_dir_recursive_absolute(output)
 var host={"pid":OS.get_process_id(),"platform":OS.get_name(),"display":DisplayServer.get_name(),"renderer":RenderingServer.get_current_rendering_method(),"adapter":RenderingServer.get_video_adapter_name(),"engine":Engine.get_version_info(),"debug_build":OS.is_debug_build(),"feature_debug":OS.has_feature("debug"),"feature_release":OS.has_feature("release"),"feature_editor":OS.has_feature("editor"),"source":OS.get_environment("GITHUB_SHA"),"M5":"NOT_TESTED","art":"NOT_ACCEPTED"}
 print("PRODUCTION_NATIVE_FOCUS ",JSON.stringify(host))
 FileAccess.open(output+"/host.json",FileAccess.WRITE).store_string(JSON.stringify(host,"  "))
 for frame in 4:await process_frame
 root.grab_focus()
 var deadline:=Time.get_ticks_usec()+5000000
 while not root.has_focus() and Time.get_ticks_usec()<deadline:await process_frame
 print("PRODUCTION_NATIVE_WINDOW ",JSON.stringify({"pid":OS.get_process_id(),"focused":root.has_focus(),"display":DisplayServer.get_name()}))
 if not root.has_focus():fail("native window focus not observed");return
 var frozen:=JSON.stringify(Save.snapshot(field.battle)).sha256_text();var stills:=[]
 for dimensions in [Vector2i(2560,1440),Vector2i(3840,2160)]:
  root.size=dimensions;root.scaling_3d_scale=1.
  for frame in 5:await process_frame
  field._process(0.);await RenderingServer.frame_post_draw
  if not field.map.sun.shadow_enabled or not is_equal_approx(field.map.sun.light_energy,2.7) or not is_equal_approx(field.map.sun.directional_shadow_max_distance,80.):fail("author HF08 Sun changed in Controller");return
  var image:=root.get_texture().get_image()
  if image==null or image.get_size()!=dimensions or not is_equal_approx(root.scaling_3d_scale,1.):fail("actual native still attachment differs from requested pixels");return
  if JSON.stringify(Save.snapshot(field.battle)).sha256_text()!=frozen:fail("Battle changed during still resolution comparison");return
  var name:="native-%dx%d.png"%[dimensions.x,dimensions.y]
  if image.save_png(output+"/"+name)!=OK:fail("cannot save native still");return
  stills.append({"file":name,"actual_pixels":[image.get_width(),image.get_height()],"texture_metadata":[root.get_texture().get_width(),root.get_texture().get_height()],"logical_viewport":str(root.get_visible_rect()),"internal_scale":root.scaling_3d_scale,"battle_snapshot_sha256":frozen,"tick":field.battle.tick,"camera":str(field.camera.global_transform),"camera_projection":str(field.camera.get_camera_projection()),"camera_profile":field.review_camera_profile,"source_identity":field.battle.map_runtime.identity(),"author_sun_shadow_enabled":field.map.sun.shadow_enabled,"monotonic_us":Time.get_ticks_usec(),"scope":"real current player view; no camera or art acceptance"})
 FileAccess.open(output+"/stills.json",FileAccess.WRITE).store_string(JSON.stringify(stills,"  "))
 root.size=Vector2i(2560,1440)
 for frame in 5:await process_frame
 if OS.get_environment("PRODUCTION_MATERIAL_CONTROL")=="1":
  var adapter:=UVAdapter.new()
  if adapter.configure_contract("res://scripts/field/experimental/production_v2/uv_spatial/source18_contract.json")!=OK:fail("locked material contract rejected");return
  var control:=MaterialControl.new()
  var control_result:Dictionary=await control.capture(self,field,adapter,output)
  if not control_result.get("error","").is_empty():fail("material-only comparison failed "+JSON.stringify(control_result));return
 var recorder:=Recorder.new();root.add_child(recorder)
 if not recorder.begin(root,field,output+"/action"):fail("native wall recorder rejected");return
 field.paused=false;field.set_process(true);field.set_physics_process(true)
 var pilot:=Pilot.new();root.add_child(pilot)
 if pilot.begin(field,recorder)!=OK:recorder.stop("pilot_rejected");fail("actual input pilot rejected");return
 while recorder.active:await process_frame
 if pilot.active:pilot.finish("recorder_stopped")
 var final={"tick":field.battle.tick,"hero_hp":field.battle.hero.hp,"hero_hits":field.battle.hero.impacts,"hits":field.battle.hits,"losses":field.battle.losses,"result":field.battle.result,"capture_reason":recorder.stop_reason,"frame_count":recorder.frames,"inputs_released":not Input.is_action_pressed("move_left") and not Input.is_action_pressed("move_right") and not Input.is_action_pressed("move_up") and not Input.is_action_pressed("move_down") and not Input.is_action_pressed("field_sprint") and not Input.is_physical_key_pressed(KEY_J),"scope":"actual result, not mandatory survival/contact/art PASS"}
 FileAccess.open(output+"/actual-final.json",FileAccess.WRITE).store_string(JSON.stringify(final,"  "))
 print("PRODUCTION_NATIVE_COMPLETED ",JSON.stringify(final));quit()
