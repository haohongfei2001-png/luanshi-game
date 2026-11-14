extends SceneTree
const Traversal:=preload('res://tools/art/gate_structure/traversal_review.gd')
const FreezeClock:=preload('res://tools/art/gate_structure/freeze_shader_clock.gd')
const WaterContours:=preload('res://tools/art/continuous_landform/water_contours.gd')
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
 assert(OS.get_environment('LUANSHI_AUTHORED_LANDFORM')=='1','Entire game process must use matching authored Ground')
 print('REGION_SETUP_LOADING_CONTINUOUS_LANDFORM')
 var support=(load('res://assets/river_authored/ground/continuous-region.scn') as PackedScene).instantiate();field.add_child(support)
 assert(support.transform==Transform3D.IDENTITY,'Continuous ground must remain world-space')
 var extra_assets={}
 if '--basin-study' in OS.get_cmdline_user_args():
  for path in ['res://assets/river_authored/shore/region.scn','res://assets/river_authored/grass/region.scn']:
   var part=(load(path) as PackedScene).instantiate();support.add_child(part)
   assert(part.transform==Transform3D.IDENTITY)
   extra_assets[path]=FileAccess.get_sha256(path)

 print('REGION_SETUP_STARTING_REAL_BATTLE')
 field.hud.go.pressed.emit()
 for tick in 135:field._physics_process(.05)
 field.camera_center=Vector2(34.2,1.0);field.camera.size=22.;field._process(.05)
 if '--validate-setup' in OS.get_cmdline_user_args():
  assert(field.map.gate is MeshInstance3D and not old.visible)
  assert(Array(field.battle.ordinary_counts)==[20,20])
  print('ARCHITECTURE_GAME_SETUP_PASS tick=',field.battle.tick,' ordinary=',field.battle.ordinary_counts)
  scene.queue_free();await process_frame;await process_frame;await create_timer(.15).timeout;quit();return
 var clock=FreezeClock.new()
 var clock_report=clock.freeze(scene,field.battle.tick*field.Battle.DT)
 print('STATIC_SHADER_CLOCK_FROZEN ',JSON.stringify({'overrides':clock_report,'include_audit':clock.include_audit}))
 var frozen=var_to_bytes(Store.snapshot(field.battle))
 var hasher=HashingContext.new();hasher.start(HashingContext.HASH_SHA256);hasher.update(frozen)
 var frozen_hash=hasher.finish().hex_encode()
 var snapshot_file=FileAccess.open(out+'/battle-snapshot.bin',FileAccess.WRITE);snapshot_file.store_buffer(frozen);snapshot_file.close()
 var receipts=[]
 var reference_shadow=field.map.sun.shadow_enabled
 var modes=['qhd-after','uhd-after']
 if '--camera-study' in OS.get_cmdline_user_args():modes=['qhd-perspective-road65','qhd-perspective-road75','uhd-perspective-road65']
 if '--shadow-diagnostic' in OS.get_cmdline_user_args():modes.append('qhd-after-no-shadow')
 for mode in modes:
  root.size=Vector2i(3840,2160) if mode.begins_with('uhd') else Vector2i(2560,1440)
  var after=not mode.contains('before')
  field.map.sun.shadow_enabled=reference_shadow and not mode.ends_with('no-shadow')
  old.visible=not after;model.visible=after;support.visible=after;woodland.visible=after
  field.camera_center=Vector2(34.2,1);field.camera.size=22.
  if '--camera-study' in OS.get_cmdline_user_args():
   field.camera_yaw=deg_to_rad(-75. if mode.ends_with('road75') else -65.)
   field.camera_center=field.battle.hero.pos+Vector2(4.,0.)
   field.review_camera_profile={'projection':'perspective','nominal_body_fraction':.10,'pitch_degrees':32.,'fov_degrees':55.}
  field._camera();field._draw_field();root.scaling_3d_scale=1.
  for frame in 8:await process_frame
  assert(var_to_bytes(Store.snapshot(field.battle))==frozen,'Battle state changed between matched views')
  if '--validate-pairs' in OS.get_cmdline_user_args():
   print('MATCHED_STATE_SETUP_PASS ',mode,' snapshot=',frozen_hash);continue
  print('ARCHITECTURE_CAPTURE_BEGIN ',mode)
  await RenderingServer.frame_post_draw
  var img=root.get_texture().get_image();assert(img.get_size()==root.size)
  var image_save_error=img.save_png(out+'/'+mode+'.png')
  if image_save_error!=OK:
   push_error('Native image write failed: '+mode+' error='+str(image_save_error));quit(1);return
  assert(var_to_bytes(Store.snapshot(field.battle))==frozen,'Battle state changed between matched views')
  var camera=field.camera
  var projection=camera.get_camera_projection()
  var transform=camera.global_transform
  receipts.append({'additional_runtime_asset_sha256':extra_assets,'runtime_ground_sha256':FileAccess.get_sha256('res://assets/river_authored/ground/continuous-region.scn'),'runtime_woodland_sha256':FileAccess.get_sha256('res://assets/river_authored/woodland/region.scn'),'camera_review_profile':field.review_camera_profile.duplicate(),'camera_profile_scope':'INTERNAL_CANDIDATE_NOT_OFFICIAL_RIOT_PARAMETERS; nominal adult box at look target, actual hero offset must be measured','shader_clock':{'fixed_seconds':field.battle.tick*field.Battle.DT,'overrides':clock_report,'include_audit':clock.include_audit},'logical_viewport_size':[root.get_visible_rect().size.x,root.get_visible_rect().size.y],'attachment_size':[img.get_width(),img.get_height()],'shadow_enabled':field.map.sun.shadow_enabled,'comparison_role':'SHADOW_ONLY_DIAGNOSTIC_NOT_STANDARD_LIGHTING' if mode.ends_with('no-shadow') else 'NEW_TERRAIN_SAME_STATE_RESOLUTION_COMPARISON_NOT_OLD_TERRAIN_PAIR','woodland_composition':woodland.get_meta('composition','MISSING'),'battle_snapshot_sha256':frozen_hash,'controller_git_blob':OS.get_environment('CONTROLLER_BLOB'),'controller_sha256':FileAccess.get_sha256('res://scripts/field/controller.gd'),'camera_transform':{'origin':vec(transform.origin),'basis':[vec(transform.basis.x),vec(transform.basis.y),vec(transform.basis.z)]},'camera_projection':[vec4(projection.x),vec4(projection.y),vec4(projection.z),vec4(projection.w)],'camera_yaw':field.camera_yaw,'viewport':[root.size.x,root.size.y],'internal_pixels':[root.size.x,root.size.y],'seed':str(field.battle.rng.seed),'composition':'original-master' if not after else 'new-architecture-and-sprite-woodland; continuous terrain with matching versioned Ground and collision; actual extents in source manifest; CC0 dry-earth PBR','view':mode,'pixels':[img.get_width(),img.get_height()],'internal_scale':root.scaling_3d_scale,'camera_center':str(field.camera_center),'camera_size':field.camera.size,'tick':field.battle.tick,'ordinary':Array(field.battle.ordinary_counts),'hits':field.battle.hits.duplicate(),'source':OS.get_environment('GITHUB_SHA'),'stage':'MATCHED_REAL_GAME_REGION_EXPERIMENT; continuous terrain with matching versioned Ground and collision; actual extents in source manifest; CC0 dry-earth PBR; old characters; ART_NOT_ACCEPTED; REALTIME_INPUT_SEPARATE_RECEIPT'})
  var partial=FileAccess.open(out+'/receipt.json',FileAccess.WRITE);partial.store_string(JSON.stringify(receipts,'  '));partial.close()
  print('ARCHITECTURE_CAPTURE_SAVED ',mode)
 print('MATCHED_REGION_HEADLESS_SETUP_COMPLETE' if '--validate-pairs' in OS.get_cmdline_user_args() else 'AUTHORED_ARCHITECTURE_ACTUAL_GAME_CAPTURE '+JSON.stringify(receipts))
 field.map.sun.shadow_enabled=reference_shadow
 clock.restore()
 if '--traversal-review' in OS.get_cmdline_user_args():await Traversal.run(self,field,out+'/traversal-raw')
 scene.queue_free();await process_frame;await process_frame;await create_timer(.15).timeout;quit()
