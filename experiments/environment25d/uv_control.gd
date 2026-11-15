class_name LuanshiSource18UVControl
extends "res://app.gd"
## One frozen, unchanged public scene. Only the eleven existing actors' material
## overrides differ. Never loaded by default, no Battle steps or Unit writes.
const UVAdapter=preload("res://scripts/field/experimental/production_v2/uv_spatial/adapter.gd")
const CONTRACT="res://scripts/field/experimental/production_v2/uv_spatial/source18_contract.json"
var uv_adapter
var uv_receipt:Dictionary={}
var selected:Array[int]=[]
var applied_ids:Array[int]=[]
var uv_failed:=false
var cpu_only:=false
var cpu_started:=false
var off_image:Image

func _process(delta:float)->bool:
 # Dummy headless RenderingServer has no frame_post_draw. Reuse the baseline
 # construction through its first draw wait, then run only CPU state checks.
 if cpu_only and not cpu_started and actors.size()==11 and report.has("rendering"):
  cpu_started=true;cpu_release_dummy_draw.call_deferred()
 return super._process(delta)

func cpu_release_dummy_draw()->void:
 await process_frame
 # Explicitly synthetic CPU wake, never evidence that a GPU draw occurred.
 RenderingServer.frame_post_draw.emit()

func _initialize()->void:
 if OS.get_environment("LUANSHI_SOURCE18_UV_CONTROL")!="1":
  push_error("DEFAULT_OFF_SOURCE18_UV_CONTROL");quit(21);return
 if "--pose-control" not in OS.get_cmdline_user_args():
  push_error("UV_CONTROL_REQUIRES_FROZEN_POSE_CONTROL");quit(22);return
 cpu_only="--uv-cpu-only" in OS.get_cmdline_user_args()
 super._initialize()

func update_view(delta:float)->void:
 super.update_view(delta)
 hud.text=hud.text.replace("22m fixed-angle","ortho size22; camera-focus56.57m")

func digest(value:Variant)->String:
 return byte_sha(var_to_bytes(value))

func byte_sha(bytes:PackedByteArray)->String:
 var context:=HashingContext.new()
 context.start(HashingContext.HASH_SHA256);context.update(bytes)
 return context.finish().hex_encode()

func script_state(object:Object)->Array:
 var rows:Array=[]
 for property in object.get_property_list():
  if property.usage & PROPERTY_USAGE_SCRIPT_VARIABLE:
   var value=object.get(property.name)
   if value is Object:value=[value.get_class(),value.get_instance_id()]
   rows.append([property.name,value])
 return rows

func resource_properties(resource:Resource)->Array:
 var values:Array=[]
 for property in resource.get_property_list():
  if property.usage & PROPERTY_USAGE_STORAGE:
   var value=resource.get(property.name)
   if value is Object:value=[value.get_class(),value.get_instance_id(),value.resource_path if value is Resource else ""]
   values.append([property.name,value])
 return values

func snapshot()->Dictionary:
 var units:Array=[];var actor_states:Array=[];var nodes:Array=[];var geometries:Array=[]
 var seen_meshes:Dictionary={}
 for unit in battle.roster:units.append(script_state(unit))
 for id in actors:
  var actor=actors[id];var bones:Array=[]
  for index in actor.skeleton.get_bone_count():
   bones.append([actor.skeleton.get_bone_name(index),actor.skeleton.get_bone_pose(index),actor.skeleton.get_bone_global_pose(index),actor.skeleton.get_bone_rest(index)])
  actor_states.append([id,actor.global_transform,bones,actor.player.current_animation,actor.player.current_animation_position,script_state(bindings[id])])
 for node in world.find_children("*","Node3D",true,false):
  nodes.append([str(node.get_path()),node.global_transform,node.visible])
  if node is MeshInstance3D and node.skin!=null:
   var binds:Array=[]
   for bind in node.skin.get_bind_count():binds.append([node.skin.get_bind_bone(bind),node.skin.get_bind_name(bind),node.skin.get_bind_pose(bind)])
   nodes.append([str(node.get_path()),str(node.skeleton),binds])
  if node is MeshInstance3D and node.mesh!=null and not seen_meshes.has(node.mesh.get_instance_id()):
   seen_meshes[node.mesh.get_instance_id()]=true
   var surfaces:Array=[]
   for surface in node.mesh.get_surface_count():
    var base_material=node.mesh.surface_get_material(surface)
    surfaces.append([node.mesh.surface_get_arrays(surface),resource_properties(base_material) if base_material!=null else []])
   geometries.append([node.mesh.get_instance_id(),digest(surfaces)])
 var lights:Array=[]
 for node in world.find_children("*","Light3D",true,false):
  var properties:Array=[]
  for property in node.get_property_list():
   if property.usage & PROPERTY_USAGE_STORAGE:properties.append([property.name,node.get(property.name)])
  lights.append(properties)
 var environments:Array=[]
 for node in world.find_children("*","WorldEnvironment",true,false):
  var properties:Array=[]
  for property in node.environment.get_property_list():
   if property.usage & PROPERTY_USAGE_STORAGE:properties.append([property.name,node.environment.get(property.name)])
  environments.append(properties)
 var camera_data=[camera.global_transform,camera.projection,camera.size,camera.fov,camera.near,camera.far,camera.keep_aspect,camera.h_offset,camera.v_offset,camera.frustum_offset,camera.get_camera_projection()]
 var result={"tick":battle.tick,"units":digest(units),"actors_bones_bindings":digest(actor_states),"all_scene_transforms_visibility":digest(nodes),"mesh_arrays_and_base_material_identity":digest(geometries),"camera":digest(camera_data),"lights":digest(lights),"environment":digest(environments),"battle":digest([battle.tick,battle.hits,battle.losses,battle.hero.hp,battle.result,battle.started]),"viewport":digest([root.content_scale_size,root.scaling_3d_scale,root.scaling_3d_mode,root.fsr_sharpness,root.msaa_2d,root.msaa_3d,root.screen_space_aa,root.use_taa]),"hud":hud.text}
 result.signature=digest(result)
 return result

func material_state()->Array:
 var rows:Array=[]
 for id in actors:
  for node in actors[id].find_children("*","MeshInstance3D",true,false):
   var surfaces:Array=[]
   for surface in node.mesh.get_surface_count():
    var value=node.get_surface_override_material(surface)
    surfaces.append(value.get_instance_id() if value!=null else 0)
   rows.append([id,str(node.get_path()),node.material_override.get_instance_id() if node.material_override!=null else 0,surfaces])
 return rows

func candidate_rows()->Array:
 var rows:Array=[];var size:=Vector2(requested_render_size)
 for id in actors:
  var actor=actors[id];var minimum:=Vector2(INF,INF);var maximum:=Vector2(-INF,-INF)
  for index in actor.skeleton.get_bone_count():
   var point3:Vector3=actor.skeleton.global_transform*actor.skeleton.get_bone_global_pose(index).origin
   var screen:=camera.unproject_position(point3)
   minimum=minimum.min(screen);maximum=maximum.max(screen)
  var full:bool=minimum.x>=8. and minimum.y>=8. and maximum.x<size.x-8. and maximum.y<size.y-8.
  rows.append({"unit_id":id,"team":battle.roster[id].team,"hero":battle.roster[id].hero,"officer":battle.roster[id].officer,"kit":battle.roster[id].kit,"pose":actor.last_receipt,"bone_screen_bbox":[minimum.x,minimum.y,maximum.x,maximum.y],"body_screen_height":maximum.y-minimum.y,"fully_in_view":full,"visibility_claim":"projected skeleton only; actual armor occlusion must be checked in GPU originals"})
 rows.sort_custom(func(a,b):
  if a.fully_in_view!=b.fully_in_view:return a.fully_in_view
  if absf(a.body_screen_height-b.body_screen_height)>.001:return a.body_screen_height>b.body_screen_height
  return a.unit_id<b.unit_id)
 return rows

func write_receipt()->void:
 FileAccess.open(out+"/uv-control.json",FileAccess.WRITE).store_string(JSON.stringify(uv_receipt,"  "))

func uv_gate(condition:bool,reason:String)->bool:
 if condition:return true
 uv_failed=true;uv_receipt.failures.append(reason);write_receipt();push_error("UV_CONTROL_FAIL "+reason)
 return false

func observe(stage:String)->bool:
 # Nothing advances Battle, binding, animation or camera while draw waits run.
 await process_frame
 if not cpu_only:await RenderingServer.frame_post_draw
 await process_frame
 if not cpu_only:await RenderingServer.frame_post_draw
 var signature=snapshot();var row={"stage":stage,"monotonic_usec":Time.get_ticks_usec(),"snapshot":signature,"material_signature":digest(material_state()),"identical_stabilization_process_and_draw_waits":2}
 if not cpu_only:
  var image=root.get_texture().get_image()
  # Save even a wrong/blank image before judging dimensions or signatures.
  if not image.is_empty():
   var file=out+"/"+stage+".png";var error=image.save_png(file)
   row.file=stage+".png";row.save_error=error;row.pixels=[image.get_width(),image.get_height()];row.raw_pixel_sha256=byte_sha(image.get_data());row.file_sha256=FileAccess.get_sha256(file)
   if stage=="OFF":off_image=image
   elif off_image!=null and image.get_size()==off_image.get_size():
    row.image_metrics_versus_OFF=off_image.compute_image_metrics(image,false)
    row.background_tile_control=background_control(image)
   uv_gate(error==OK,"PNG_SAVE_"+stage)
   uv_gate(image.get_size()==Vector2i(2560,1440),"NOT_NATIVE_2K_"+stage)
  else:uv_gate(false,"EMPTY_FRAME_"+stage)
 uv_receipt.stages.append(row);write_receipt()
 return uv_gate(signature.signature==uv_receipt.initial_snapshot.signature,"STATE_DRIFT_"+stage)

func background_control(image:Image)->Dictionary:
 # Numeric analysis only; no derived/cropped image files. Conservative exclusion
 # uses all original actors' projected bone rectangles plus 12 px, not masks.
 var actor_rects:Array[Rect2]=[]
 for candidate in uv_receipt.candidates:
  var box=candidate.bone_screen_bbox
  actor_rects.append(Rect2(Vector2(box[0],box[1]),Vector2(box[2]-box[0],box[3]-box[1])).grow(12.))
 var result={"tile_size":64,"tiles_tested":0,"tiles_changed":0,"pixels_tested":0,"changed_tile_coordinates":[],"meaning":"pixels outside conservative actor regions; no alteration of screenshots or AA"}
 for y in range(0,image.get_height(),64):
  for x in range(0,image.get_width(),64):
   var rectangle=Rect2i(x,y,mini(64,image.get_width()-x),mini(64,image.get_height()-y))
   var excluded:=false
   for body in actor_rects:
    if body.intersects(Rect2(rectangle)):excluded=true;break
   if excluded:continue
   result.tiles_tested+=1;result.pixels_tested+=rectangle.size.x*rectangle.size.y
   if off_image.get_region(rectangle).get_data()!=image.get_region(rectangle).get_data():
    result.tiles_changed+=1;result.changed_tile_coordinates.append([x,y])
 return result

func restore_all()->void:
 var restored:=0
 if uv_adapter!=null:
  for id in applied_ids:restored+=uv_adapter.restore(actors[id])
 uv_receipt.restored_surfaces=restored
 uv_gate(digest(material_state())==uv_receipt.initial_material_signature,"MATERIAL_RESTORE_MISMATCH")

func capture()->void:
 capture_busy=true
 uv_receipt={"scope":"source18 UV/material technical OFF/ON control ONLY; rejected whole scene remains rejected","public_base_commit":"1cbdc20aaa63786b1f2fc6181bd7a62c77a84eeb","public_base_tree":"7a00714dde185b9ca8fbc75ae59fe9da2634118a","adapter_commit":"01fb175a8ee64ed65c67e16f76bf06ea37f2b6b5","cpu_only":cpu_only,"gpu":"NOT_RUN" if cpu_only else "PENDING","failures":[],"stages":[],"application_receipts":[],"source18_sha256":ACTOR_SHA,"contract_sha256":FileAccess.get_sha256(CONTRACT),"engine":{"version":Engine.get_version_info(),"debug_build":OS.is_debug_build(),"editor_hint":Engine.is_editor_hint(),"features":{"template_debug":OS.has_feature("template_debug"),"template_release":OS.has_feature("template_release"),"arm64":OS.has_feature("arm64"),"x86_64":OS.has_feature("x86_64"),"single":OS.has_feature("single"),"double":OS.has_feature("double"),"debug":OS.has_feature("debug"),"release":OS.has_feature("release"),"template":OS.has_feature("template"),"editor":OS.has_feature("editor"),"macos":OS.has_feature("macos")},"renderer":RenderingServer.get_current_rendering_method(),"device":RenderingServer.get_video_adapter_name(),"vendor":RenderingServer.get_video_adapter_vendor(),"driver_cli":OS.get_cmdline_args()},"camera":{"projection":camera.projection,"projection_name":"ORTHOGONAL","size":camera.size,"position":[camera.position.x,camera.position.y,camera.position.z],"focus_offset_vector":[0,40,40],"distance_to_existing_focus":Vector3(0,40,40).length(),"not_a_22m_camera_distance":true,"fov_inactive_for_ortho":camera.fov,"keep_aspect":camera.keep_aspect},"render":{"requested_pixels":[2560,1440],"reported_pixels":root.get_texture().get_size(),"presentation_window_pixels":DisplayServer.window_get_size(),"internal_3d_scale":root.scaling_3d_scale,"content_scale_size":root.content_scale_size,"msaa_3d":root.msaa_3d,"source_environment_pixels":[1672,941]},"all_actor_count":actors.size(),"other_kit_proxy_count":proxies.size(),"battle_tick":battle.tick,"no_new_battle_steps":true,"no_unit_writes":true}
 if not uv_gate(battle.tick==0 and not running,"NOT_FROZEN_ORIGINAL_TICK0"):capture_busy=false;return
 uv_receipt.initial_snapshot=snapshot();uv_receipt.initial_material_signature=digest(material_state())
 uv_receipt.render.use_taa=root.use_taa
 uv_receipt.render.screen_space_aa=root.screen_space_aa
 uv_receipt.render.scaling_3d_mode=root.scaling_3d_mode
 uv_receipt.render.scaling_3d_mode_name="BILINEAR" if root.scaling_3d_mode==Viewport.SCALING_3D_MODE_BILINEAR else "NON_BILINEAR_SEE_ACTUAL_ENUM"
 uv_receipt.render.fsr_sharpness=root.fsr_sharpness
 uv_receipt.render.msaa_2d=root.msaa_2d
 uv_receipt.render.quality_settings_unchanged_from_public_baseline=true
 uv_receipt.temporal_control="Two identical process/draw waits per stage. Manual animation sampling; no Battle steps or presentation updates between stages. Nonzero restored/background differences fail attribution; do not tune AA to force equality."
 uv_receipt.camera.rotation_degrees=[camera.rotation_degrees.x,camera.rotation_degrees.y,camera.rotation_degrees.z]
 var focus=camera.position-Vector3(0,40,40)
 uv_receipt.camera.existing_focus=[focus.x,focus.y,focus.z]
 var candidates=candidate_rows();uv_receipt.candidates=candidates
 var clear_candidates:=0
 for row in candidates:
  if row.fully_in_view and row.body_screen_height>=80.:clear_candidates+=1
 for id in actors:selected.append(id)
 selected.sort()
 uv_receipt.selected_ids=selected
 uv_receipt.projected_clear_candidates=clear_candidates
 if not uv_gate(selected.size()==11 and clear_candidates>=7,"FEWER_THAN_SEVEN_UNCROPPED_80PX_CANDIDATES_OR_NOT_ORIGINAL_11"):capture_busy=false;return
 uv_adapter=UVAdapter.new()
 if not uv_gate(uv_adapter.configure_contract(CONTRACT)==OK,"ADAPTER_CONTRACT"):capture_busy=false;return
 # Negative default-OFF adapter proof before any override.
 uv_receipt.adapter_default_off=uv_adapter.apply(actors[selected[0]])
 if not uv_gate(digest(material_state())==uv_receipt.initial_material_signature,"ADAPTER_DEFAULT_OFF_MUTATED"):capture_busy=false;return
 await observe("OFF")
 if not cpu_only:
  uv_gate(RenderingServer.get_current_rendering_method()=="mobile" and OS.has_feature("macos") and not RenderingServer.get_video_adapter_name().is_empty(),"NOT_ACTUAL_MAC_MOBILE_GPU")
 if not uv_failed:
  for id in selected:
   var result=uv_adapter.apply(actors[id],true);uv_receipt.application_receipts.append({"unit_id":id,"result":result})
   if result.get("applied",false):applied_ids.append(id)
   if not uv_gate(result.get("applied",false) and result.get("surfaces",0)==18,"APPLY_"+str(id)):break
 if not uv_failed:await observe("ON")
 restore_all()
 await observe("RESTORED_OFF")
 if not cpu_only:
  uv_receipt.gpu="CAPTURED_NOT_ART_ACCEPTED"
  if uv_receipt.stages.size()==3:
   uv_gate(uv_receipt.stages[0].get("raw_pixel_sha256","")==uv_receipt.stages[2].get("raw_pixel_sha256","missing"),"RESTORED_OFF_PIXELS_DIFFER")
 uv_receipt.status="FAIL" if uv_failed else ("CPU_PROTOCOL_PASS_GPU_NOT_RUN" if cpu_only else "TECHNICAL_PROTOCOL_PASS_REQUIRES_PIXEL_AND_VISUAL_REVIEW")
 write_receipt();capture_busy=false

func finish()->void:
 print("SOURCE18_UV_CONTROL ",JSON.stringify({"status":uv_receipt.get("status","FAIL"),"failures":uv_receipt.get("failures",[]),"selected_ids":selected,"cpu_only":cpu_only}))
 quit(23 if uv_failed else 0)
