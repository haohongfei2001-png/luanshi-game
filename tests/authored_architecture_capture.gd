extends SceneTree
const Store:=preload('res://scripts/field/save.gd')
const Surface:=preload('res://tools/art/authored_reset/surface_authoring.gd')
var out:=OS.get_environment('ARCHITECTURE_CAPTURE_OUT')
func vec(v:Vector3)->Array:return [v.x,v.y,v.z]
func vec4(v:Vector4)->Array:return [v.x,v.y,v.z,v.w]
func _initialize() -> void:run.call_deferred()
func run() -> void:
 if out.is_empty():out='user://architecture-review'
 DirAccess.make_dir_recursive_absolute(out)
 root.size=Vector2i(2560,1440)
 var scene=load('res://scenes/game.tscn').instantiate();root.add_child(scene);await process_frame
 var field=scene.field
 field.selections=20;field.opposing_selection=20;field.hud.plan_requested.emit(5)
 field.set_process(false);field.set_physics_process(false);field.follow=false
 var old=field.map.master;old.visible=false
 # Preserve functional siege equipment and the existing scene lighting, not rejected architecture.
 field.map.ram.reparent(field);field.map.sun.reparent(field)
 var model=(load('res://assets/river_authored/architecture/architecture.glb') as PackedScene).instantiate();field.add_child(model)
 field.map.gate=model.find_child('GateDoor_Structure',true,false) as MeshInstance3D
 var woodland=(load('res://assets/river_authored/woodland/region.scn') as PackedScene).instantiate();field.add_child(woodland)
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
 if '--validate-setup' in OS.get_cmdline_user_args():
  assert(field.map.gate is MeshInstance3D and not old.visible)
  assert(Array(field.battle.ordinary_counts)==[20,20])
  print('ARCHITECTURE_GAME_SETUP_PASS tick=',field.battle.tick,' ordinary=',field.battle.ordinary_counts)
  scene.queue_free();await process_frame;await process_frame;await create_timer(.15).timeout;quit();return
 var frozen=var_to_bytes(Store.snapshot(field.battle))
 var hasher=HashingContext.new();hasher.start(HashingContext.HASH_SHA256);hasher.update(frozen)
 var frozen_hash=hasher.finish().hex_encode()
 var snapshot_file=FileAccess.open(out+'/battle-snapshot.bin',FileAccess.WRITE);snapshot_file.store_buffer(frozen);snapshot_file.close()
 var receipts=[]
 for mode in ['qhd-before','qhd-after','uhd-before','uhd-after']:
  root.size=Vector2i(3840,2160) if mode.begins_with('uhd') else Vector2i(2560,1440)
  var after=mode.ends_with('after')
  old.visible=not after;model.visible=after;support.visible=after;woodland.visible=after
  field.camera_center=Vector2(34.2,1);field.camera.size=22.
  field._camera();field._draw_field();root.scaling_3d_scale=1.
  for frame in 8:await process_frame
  assert(var_to_bytes(Store.snapshot(field.battle))==frozen,'Battle state changed between matched views')
  if '--validate-pairs' in OS.get_cmdline_user_args():
   print('MATCHED_STATE_SETUP_PASS ',mode,' snapshot=',frozen_hash);continue
  print('ARCHITECTURE_CAPTURE_BEGIN ',mode)
  await RenderingServer.frame_post_draw
  var img=root.get_texture().get_image();assert(img.get_size()==root.size)
  assert(img.save_png(out+'/'+mode+'.png')==OK)
  assert(var_to_bytes(Store.snapshot(field.battle))==frozen,'Battle state changed between matched views')
  var camera=field.camera
  var projection=camera.get_camera_projection()
  var transform=camera.global_transform
  receipts.append({'battle_snapshot_sha256':frozen_hash,'controller_git_blob':OS.get_environment('CONTROLLER_BLOB'),'controller_sha256':FileAccess.get_sha256('res://scripts/field/controller.gd'),'camera_transform':{'origin':vec(transform.origin),'basis':[vec(transform.basis.x),vec(transform.basis.y),vec(transform.basis.z)]},'camera_projection':[vec4(projection.x),vec4(projection.y),vec4(projection.z),vec4(projection.w)],'camera_yaw':field.camera_yaw,'viewport':[root.size.x,root.size.y],'internal_pixels':[root.size.x,root.size.y],'seed':str(field.battle.rng.seed),'composition':'original-master' if not after else 'new-architecture-and-sprite-woodland; terrain support only','view':mode,'pixels':[img.get_width(),img.get_height()],'internal_scale':root.scaling_3d_scale,'camera_center':str(field.camera_center),'camera_size':field.camera.size,'tick':field.battle.tick,'ordinary':Array(field.battle.ordinary_counts),'hits':field.battle.hits.duplicate(),'source':OS.get_environment('GITHUB_SHA'),'stage':'MATCHED_REAL_GAME_REGION_EXPERIMENT; terrain support only; old characters; ART_NOT_ACCEPTED; REALTIME_INPUT_NOT_RUN'})
  var partial=FileAccess.open(out+'/receipt.json',FileAccess.WRITE);partial.store_string(JSON.stringify(receipts,'  '));partial.close()
  print('ARCHITECTURE_CAPTURE_SAVED ',mode)
 print('MATCHED_REGION_HEADLESS_SETUP_COMPLETE' if '--validate-pairs' in OS.get_cmdline_user_args() else 'AUTHORED_ARCHITECTURE_ACTUAL_GAME_CAPTURE '+JSON.stringify(receipts))
 scene.queue_free();await process_frame;await process_frame;await create_timer(.15).timeout;quit()
