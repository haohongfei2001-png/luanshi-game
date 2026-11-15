extends RefCounted
## Diagnostic only: caller supplies a verified adapter. No default material change.
const Save=preload("res://scripts/field/save.gd")
func actors(field)->Array:
 var result:Array=[field.skeletal_actor]
 for row in field.ordinary_actor_bindings:
  if row.active:result.append(row.actor)
 return result
func state_signature(field,instances:Array)->String:
 var poses=[]
 for actor in instances:
  var bones=[]
  for index in actor.skeleton.get_bone_count():bones.append(str(actor.skeleton.get_bone_pose(index)))
  poses.append({"transform":str(actor.global_transform),"bones":bones,"visible":actor.visible,"pose":actor.last_receipt})
 var sun=field.map.sun
 var worlds=field.map.find_children("*","WorldEnvironment",true,false)
 var environment_id=worlds[0].environment.get_instance_id() if worlds.size()==1 else 0
 return JSON.stringify({"battle":Save.snapshot(field.battle),"camera":str(field.camera.global_transform),"projection":str(field.camera.get_camera_projection()),"sun":[str(sun.global_transform),sun.light_energy,str(sun.light_color),sun.shadow_enabled,sun.directional_shadow_max_distance],"environment_id":environment_id,"actors":poses}).sha256_text()
func material_state(instances:Array)->Array:
 var result=[]
 for actor in instances:
  for mesh in actor.model.find_children("*","MeshInstance3D",true,false):
   for surface in mesh.mesh.get_surface_count():
    var original=mesh.mesh.surface_get_material(surface);var active=mesh.get_active_material(surface)
    result.append([mesh.get_instance_id(),surface,original.get_instance_id() if original!=null else 0,active.get_instance_id() if active!=null else 0])
 return result
func capture(tree:SceneTree,field,adapter:RefCounted,out:String)->Dictionary:
 if not field.paused or field.is_processing() or field.is_physics_processing():return {"error":"controller_not_frozen"}
 if tree.root.size!=Vector2i(2560,1440) or tree.root.scaling_3d_scale!=1.:return {"error":"not_native_2K"}
 var instances:=actors(field)
 if instances.size()!=7:return {"error":"expected_hero_and_six_real_ordinary"}
 var signature:=state_signature(field,instances);var baseline:=material_state(instances)
 var rows=[];var receipts=[];var error:=""
 for enabled in [false,true]:
  if enabled:
   for actor in instances:
    var receipt:Dictionary=adapter.apply(actor,true);receipts.append(receipt)
    if not receipt.get("applied",false):error="adapter_rejected_actual_actor";break
  if not error.is_empty():break
  for frame in 3:await tree.process_frame
  await RenderingServer.frame_post_draw
  if state_signature(field,instances)!=signature:error="non_material_state_changed";break
  var image=tree.root.get_texture().get_image()
  if image==null or image.get_size()!=Vector2i(2560,1440):error="attachment_not_2K";break
  var name:="material-ON.png" if enabled else "material-OFF.png"
  if image.save_png(out+"/"+name)!=OK:error="image_write_failed";break
  rows.append({"file":name,"actual_pixels":[image.get_width(),image.get_height()],"enabled":enabled,"tick":field.battle.tick,"non_material_state_sha256":signature,"internal_scale":tree.root.scaling_3d_scale})
 var restored:=0
 for actor in instances:restored+=adapter.restore(actor)
 var restored_exact:=material_state(instances)==baseline
 if not restored_exact:error="original_materials_not_restored"
 var result={"error":error,"frames":rows,"adapter_receipts":receipts,"restored_surfaces":restored,"original_materials_restored":restored_exact,"default_enabled":false,"scope":"same-source material-only diagnostic; no GPU or visual acceptance implied"}
 var file=FileAccess.open(out+"/material-control.json",FileAccess.WRITE)
 if file==null:return {"error":"receipt_write_failed"}
 file.store_string(JSON.stringify(result,"  "))
 return result
