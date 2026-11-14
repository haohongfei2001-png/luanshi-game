extends SceneTree
const Traversal:=preload('res://tools/art/gate_structure/traversal_review.gd')
const Store:=preload('res://scripts/field/save.gd')
const Support:=preload('res://tools/art/gate_structure/region_support.gd')
const Surface:=preload('res://tools/art/authored_reset/surface_authoring.gd')
var out:=OS.get_environment('ARCHITECTURE_CAPTURE_OUT')
func vec(v:Vector3)->Array:return [v.x,v.y,v.z]
func vec4(v:Vector4)->Array:return [v.x,v.y,v.z,v.w]
func _initialize() -> void:run.call_deferred()
func run() -> void:
 if out.is_empty():out='user://architecture-review'
 DirAccess.make_dir_recursive_absolute(out)
 root.size=Vector2i(2560,1440)
 print('REGION_SETUP_LOADING_GAME')
 var scene=load('res://scenes/game.tscn').instantiate();root.add_child(scene);await process_frame
 var field=scene.field
 field.selections=20;field.opposing_selection=20;field.hud.plan_requested.emit(5)
 field.set_process(false);field.set_physics_process(false);field.follow=false
 var old=field.map.master;old.visible=false
 # Preserve functional siege equipment and the existing scene lighting, not rejected architecture.
 field.map.ram.reparent(field);field.map.sun.reparent(field)
 var model=(load('res://assets/river_authored/architecture/architecture.glb') as PackedScene).instantiate();field.add_child(model)
 field.map.gate=model.find_child('GateDoor_Structure',true,false) as MeshInstance3D
 print('REGION_SETUP_LOADING_WOODLAND')
 var woodland=(load('res://assets/river_authored/woodland/region.scn') as PackedScene).instantiate();field.add_child(woodland)
 var material=StandardMaterial3D.new();material.albedo_color=Color('8f7957');material.roughness=.95
 var support=Node3D.new();support.name='SurveySupport_NOT_FINISHED_ENVIRONMENT';field.add_child(support)
 # Exact non-overlapping support rectangle partition: never offset the professional ground.
 print('REGION_SETUP_BUILDING_SUPPORT')
 var xs=[-48.,29.6,46.6,96.];var zs=[-64.,-12.,12.,64.]
 for ix in 3:
  for iz in 3:
   if ix==1 and iz==1:continue
   var m=MeshInstance3D.new();m.mesh=Support.rectangle(xs[ix],xs[ix+1],zs[iz],zs[iz+1]);m.material_override=material;support.add_child(m)
 print('REGION_SETUP_LOADING_GROUND')
 var ground=(load('res://assets/river_authored/ground/ground-approach.glb') as PackedScene).instantiate();support.add_child(ground)
 assert(ground.transform==Transform3D.IDENTITY,'Native ground must remain world-space, no scale/offset')
 var watermat=StandardMaterial3D.new();watermat.albedo_color=Color('355c5c');watermat.roughness=.3
 var water=MeshInstance3D.new();water.mesh=PlaneMesh.new();water.mesh.size=Vector2(11.7,51);water.position=Vector3(24,-1.48,0);water.material_override=watermat;support.add_child(water)
 print('REGION_SETUP_STARTING_REAL_BATTLE')
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
 var reference_shadow=field.map.sun.shadow_enabled
 var modes=['qhd-before','qhd-after','uhd-before','uhd-after']
 if '--shadow-diagnostic' in OS.get_cmdline_user_args():modes.append('qhd-after-no-shadow')
 for mode in modes:
  root.size=Vector2i(3840,2160) if mode.begins_with('uhd') else Vector2i(2560,1440)
  var after=mode.contains('after')
  field.map.sun.shadow_enabled=reference_shadow and not mode.ends_with('no-shadow')
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
  receipts.append({'shadow_enabled':field.map.sun.shadow_enabled,'comparison_role':'SHADOW_ONLY_DIAGNOSTIC_NOT_STANDARD_LIGHTING' if mode.ends_with('no-shadow') else 'FIXED_SAME_LIGHTING_PAIR','woodland_composition':woodland.get_meta('composition','MISSING'),'battle_snapshot_sha256':frozen_hash,'controller_git_blob':OS.get_environment('CONTROLLER_BLOB'),'controller_sha256':FileAccess.get_sha256('res://scripts/field/controller.gd'),'camera_transform':{'origin':vec(transform.origin),'basis':[vec(transform.basis.x),vec(transform.basis.y),vec(transform.basis.z)]},'camera_projection':[vec4(projection.x),vec4(projection.y),vec4(projection.z),vec4(projection.w)],'camera_yaw':field.camera_yaw,'viewport':[root.size.x,root.size.y],'internal_pixels':[root.size.x,root.size.y],'seed':str(field.battle.rng.seed),'composition':'original-master' if not after else 'new-architecture-and-sprite-woodland; professional safe-core approach 17x24m; other terrain support only','view':mode,'pixels':[img.get_width(),img.get_height()],'internal_scale':root.scaling_3d_scale,'camera_center':str(field.camera_center),'camera_size':field.camera.size,'tick':field.battle.tick,'ordinary':Array(field.battle.ordinary_counts),'hits':field.battle.hits.duplicate(),'source':OS.get_environment('GITHUB_SHA'),'stage':'MATCHED_REAL_GAME_REGION_EXPERIMENT; professional safe-core approach 17x24m; other terrain support only; old characters; ART_NOT_ACCEPTED; REALTIME_INPUT_NOT_RUN'})
  var partial=FileAccess.open(out+'/receipt.json',FileAccess.WRITE);partial.store_string(JSON.stringify(receipts,'  '));partial.close()
  print('ARCHITECTURE_CAPTURE_SAVED ',mode)
 print('MATCHED_REGION_HEADLESS_SETUP_COMPLETE' if '--validate-pairs' in OS.get_cmdline_user_args() else 'AUTHORED_ARCHITECTURE_ACTUAL_GAME_CAPTURE '+JSON.stringify(receipts))
 field.map.sun.shadow_enabled=reference_shadow
 if '--traversal-review' in OS.get_cmdline_user_args():await Traversal.run(self,field,out+'/traversal-raw')
 scene.queue_free();await process_frame;await process_frame;await create_timer(.15).timeout;quit()
