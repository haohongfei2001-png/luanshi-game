extends SceneTree
const Surface:=preload('res://tools/art/authored_reset/surface_authoring.gd')
var out:=OS.get_environment('ARCHITECTURE_CAPTURE_OUT')
func _initialize() -> void:run.call_deferred()
func run() -> void:
 if out.is_empty():out='user://architecture-review'
 DirAccess.make_dir_recursive_absolute(out)
 root.size=Vector2i(2560,1440)
 var scene=load('res://scenes/game.tscn').instantiate();root.add_child(scene);await process_frame
 var field=scene.field
 field.selections=20;field.hud.plan_requested.emit(5)
 field.set_process(false);field.set_physics_process(false);field.follow=false
 var old=field.map.master;old.visible=false
 # Preserve functional siege equipment and the existing scene lighting, not rejected architecture.
 field.map.ram.reparent(field);field.map.sun.reparent(field)
 var model=(load('res://assets/river_authored/architecture/architecture.glb') as PackedScene).instantiate();field.add_child(model)
 field.map.gate=model.find_child('GateDoor',true,false)
 var material=StandardMaterial3D.new();material.albedo_color=Color('8f7957');material.roughness=.95
 var support=Node3D.new();support.name='SurveySupport_NOT_FINISHED_ENVIRONMENT';field.add_child(support)
 for x in range(-48,96,16):
  for z in range(-64,64,16):
   var m=MeshInstance3D.new();m.mesh=Surface.tile(Vector2(x,z));m.material_override=material;support.add_child(m)
 var watermat=StandardMaterial3D.new();watermat.albedo_color=Color('355c5c');watermat.roughness=.3
 var water=MeshInstance3D.new();water.mesh=PlaneMesh.new();water.mesh.size=Vector2(11.7,51);water.position=Vector3(24,-1.48,0);water.material_override=watermat;support.add_child(water)
 field.hud.go.pressed.emit()
 for tick in 135:field._physics_process(.05)
 field.camera_center=Vector2(34.2,1.0);field.camera.size=22.;field._process(.05)
 var receipts=[]
 for mode in ['qhd-normal','qhd-gate-close','uhd-normal']:
  root.size=Vector2i(3840,2160) if mode=='uhd-normal' else Vector2i(2560,1440)
  field.camera_center=Vector2(50,0) if mode=='qhd-gate-close' else Vector2(34.2,1)
  field.camera.size=16. if mode=='qhd-gate-close' else 22.
  field._camera();field._draw_field();root.scaling_3d_scale=1.
  for frame in 8:await process_frame
  await RenderingServer.frame_post_draw
  var img=root.get_texture().get_image();assert(img.get_size()==root.size)
  assert(img.save_png(out+'/'+mode+'.png')==OK)
  receipts.append({'view':mode,'pixels':[img.get_width(),img.get_height()],'internal_scale':root.scaling_3d_scale,'camera_center':str(field.camera_center),'camera_size':field.camera.size,'tick':field.battle.tick,'ordinary':Array(field.battle.ordinary_counts),'hits':field.battle.hits.duplicate(),'source':OS.get_environment('GITHUB_SHA'),'stage':'ACTUAL_GAME_ARCHITECTURE_LINK_EXPERIMENT; terrain support only; old characters; full new environment NOT_READY; ART_NOT_ACCEPTED'})
 var file=FileAccess.open(out+'/receipt.json',FileAccess.WRITE);file.store_string(JSON.stringify(receipts,'  '));file.close()
 print('AUTHORED_ARCHITECTURE_ACTUAL_GAME_CAPTURE ',JSON.stringify(receipts))
 scene.queue_free();await process_frame;await process_frame;await create_timer(.15).timeout;quit()
