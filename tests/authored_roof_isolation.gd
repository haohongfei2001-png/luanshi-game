extends SceneTree
const FreezeClock:=preload('res://tools/art/gate_structure/freeze_shader_clock.gd')
const Store:=preload('res://scripts/field/save.gd')
func _initialize()->void:run.call_deferred()
func run()->void:
 assert(OS.get_environment('LUANSHI_AUTHORED_LANDFORM')=='1')
 var out=OS.get_environment('ROOF_CAPTURE_OUT');assert(not out.is_empty());DirAccess.make_dir_recursive_absolute(out)
 root.size=Vector2i(2560,1440)
 var scene=load('res://scenes/game.tscn').instantiate();root.add_child(scene);await process_frame
 var field=scene.field;field.selections=20;field.opposing_selection=20;field.hud.plan_requested.emit(5)
 field.set_process(false);field.set_physics_process(false);field.follow=false
 field.map.master.hide();field.map.ram.reparent(field);field.map.sun.reparent(field)
 for path in ['ground/continuous-region.scn','woodland/region.scn']:
  var model=(load('res://assets/river_authored/'+path) as PackedScene).instantiate();field.add_child(model)
 var models=[];var paths=['res://assets/river_authored/architecture/architecture.glb','res://assets/river_authored/roof-native-band/architecture.glb']
 for path in paths:
  var model=(load(path) as PackedScene).instantiate();field.add_child(model);model.hide();models.append(model)
 field.map.gate=models[0].find_child('GateDoor_Structure',true,false) as MeshInstance3D
 field.hud.go.pressed.emit();for tick in 135:field._physics_process(.05)
 field.camera_center=Vector2(50,0);field.camera.size=18.;field._process(.05)
 var clock=FreezeClock.new();var frozen_shaders=clock.freeze(scene,field.battle.tick*field.Battle.DT)
 var frozen=var_to_bytes(Store.snapshot(field.battle));var hash=HashingContext.new();hash.start(HashingContext.HASH_SHA256);hash.update(frozen);var snapshot_sha=hash.finish().hex_encode()
 var saved=[];var rows=[]
 for mode in ['original-lit','native-band-lit','original-normal-diagnostic','native-band-normal-diagnostic']:
  var index=0 if mode.begins_with('original') else 1
  for i in models.size():models[i].visible=i==index
  field.map.gate=models[index].find_child('GateDoor_Structure',true,false) as MeshInstance3D
  if mode.ends_with('diagnostic'):
   var shader=Shader.new();shader.code='shader_type spatial; render_mode unshaded; void fragment(){ ALBEDO=NORMAL*.5+.5; }'
   var material=ShaderMaterial.new();material.shader=shader
   for mesh:MeshInstance3D in models[index].find_children('Roof_*','MeshInstance3D',true,false):
    saved.append([mesh,mesh.material_override]);mesh.material_override=material
  field.camera_center=Vector2(50,0);field.camera.size=18.;field._camera();field._draw_field();root.scaling_3d_scale=1.
  for frame in 8:await process_frame
  assert(var_to_bytes(Store.snapshot(field.battle))==frozen)
  if '--setup-only' not in OS.get_cmdline_user_args():
   await RenderingServer.frame_post_draw
   var image=root.get_texture().get_image();assert(image.get_size()==Vector2i(2560,1440));assert(image.save_png(out+'/'+mode+'.png')==OK)
  rows.append({'view':mode,'scope':'ROOF_GEOMETRY_ISOLATION_NOT_GAMEPLAY_CAMERA_OR_ART_ACCEPTANCE','source':OS.get_environment('GITHUB_SHA'),'model_sha256':FileAccess.get_sha256(paths[index]),'pixels':[2560,1440],'internal_scale':1.,'tick':field.battle.tick,'snapshot_sha256':snapshot_sha,'camera_size':field.camera.size,'camera_center':str(field.camera_center),'camera_transform':str(field.camera.global_transform),'camera_projection':str(field.camera.get_camera_projection()),'shader_clock':frozen_shaders})
  for entry in saved:entry[0].material_override=entry[1]
  saved.clear()
  var receipt=FileAccess.open(out+'/receipt.json',FileAccess.WRITE);receipt.store_string(JSON.stringify(rows,'  '));receipt.close()
 clock.restore();print('ROOF_ISOLATION_COMPLETE ',JSON.stringify(rows));scene.queue_free();await process_frame;await process_frame;await create_timer(.2).timeout;quit()
