extends SceneTree
const LiveSequence:=preload("res://scripts/review/author_live_sequence.gd")
const Destination:=preload("res://scripts/review/destination_camera.gd")
const ResourceIdentity:=preload("res://scripts/review/resource_identity.gd")
const AuthorOracle:=preload("res://scripts/review/author_unit_oracle.gd")
const Traversal:=preload('res://scripts/review/traversal_review.gd')
const FreezeClock:=preload('res://scripts/review/freeze_shader_clock.gd')
const WaterContours:=preload('res://scripts/review/water_contours.gd')
const Store:=preload('res://scripts/field/save.gd')
const Support:=preload('res://scripts/review/region_support.gd')
const Surface:=preload('res://scripts/review/surface_authoring.gd')
var out:=OS.get_environment('ARCHITECTURE_CAPTURE_OUT')
func vec(v:Vector3)->Array:return [v.x,v.y,v.z]
func vec4(v:Vector4)->Array:return [v.x,v.y,v.z,v.w]
func require_capture(condition:bool,message:String)->bool:
 if condition:return true
 push_error(message);quit(1);return false
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
 if not require_capture(OS.get_environment('LUANSHI_AUTHORED_LANDFORM')=='1','Entire game process must use matching authored Ground'):return
 print('REGION_SETUP_LOADING_CONTINUOUS_LANDFORM')
 var support=(load('res://assets/river_authored/ground/continuous-region.scn') as PackedScene).instantiate();field.add_child(support)
 if not require_capture(support.transform==Transform3D.IDENTITY,'Continuous ground must remain world-space'):return
 var extra_assets={}
 if '--basin-study' in OS.get_cmdline_user_args() or '--road-section-study' in OS.get_cmdline_user_args():
  var part_paths=['res://assets/river_authored/grass/region.scn']
  if '--road-section-study' not in OS.get_cmdline_user_args():part_paths.append('res://assets/river_authored/shore/region.scn')
  for path in part_paths:
   var part=(load(path) as PackedScene).instantiate();support.add_child(part)
   if not require_capture(part.transform==Transform3D.IDENTITY,'Basin part transform changed'):return
   extra_assets[path]=FileAccess.get_sha256(path)

 var identity_paths=['res://assets/river_authored/architecture/architecture.glb','res://assets/river_authored/ground/continuous-region.scn','res://assets/river_authored/woodland/region.scn']
 identity_paths.append_array(extra_assets.keys())
 var resource_identity=ResourceIdentity.collect(identity_paths)
 for identity in resource_identity.values():
  if not require_capture(not identity.has('error'),'Packed resource identity failed: '+str(identity)):return
 print('RUNTIME_RESOURCE_IDENTITY ',JSON.stringify(resource_identity))

 print('REGION_SETUP_STARTING_REAL_BATTLE')
 field.hud.go.pressed.emit()
 for tick in 135:field._physics_process(.05)
 var oracle_actor:Node3D=null
 var oracle_receipt:Dictionary={}
 if '--author-oracle' in OS.get_cmdline_user_args():
  if not require_capture('--traversal-review' not in OS.get_cmdline_user_args(),'Static author oracle cannot masquerade as mapped combat/movement animation'):return
  print('REGION_SETUP_LOADING_ONE_REAL_UNIT_AUTHOR_ORACLE')
  var bound=AuthorOracle.bind(field,OS.get_environment('LUANSHI_AUTHOR_ORACLE_CACHE'))
  if not require_capture(bound.error==OK,'Single real-unit author oracle failed: '+str(bound.error)):return
  oracle_actor=bound.actor;oracle_receipt=bound.receipt
 field.camera_center=Vector2(34.2,1.0);field.camera.size=22.;field._process(.05)
 if '--author-dynamic-review' in OS.get_cmdline_user_args():
  if not require_capture(is_instance_valid(oracle_actor),'Dynamic fixture requires exact complete actor'):return
  var fixture_check=LiveSequence.fixture_for(oracle_actor)
  if not require_capture(not fixture_check.has('error'),'Live phase fixture unavailable: '+str(fixture_check)):return
  print('AUTHOR_DYNAMIC_FIXTURE_VALIDATED ',fixture_check.sha256)
 if '--validate-setup' in OS.get_cmdline_user_args():
  if not require_capture(field.map.gate is MeshInstance3D and not old.visible,'Wrong authored scene setup'):return
  if not require_capture(Array(field.battle.ordinary_counts)==[20,20],'Wrong real battle fixture'):return
  print('ARCHITECTURE_GAME_SETUP_PASS tick=',field.battle.tick,' ordinary=',field.battle.ordinary_counts)
  scene.queue_free();await process_frame;await process_frame;await create_timer(.15).timeout;quit();return
 var clock=FreezeClock.new()
 var clock_report=clock.freeze(scene,field.battle.tick*field.Battle.DT)
 if not require_capture(not clock.failed,'Shader time freeze failed'):return
 print('STATIC_SHADER_CLOCK_FROZEN ',JSON.stringify({'overrides':clock_report,'include_audit':clock.include_audit}))
 var frozen=var_to_bytes(Store.snapshot(field.battle))
 var hasher=HashingContext.new();hasher.start(HashingContext.HASH_SHA256);hasher.update(frozen)
 var frozen_hash=hasher.finish().hex_encode()
 var snapshot_file=FileAccess.open(out+'/battle-snapshot.bin',FileAccess.WRITE);snapshot_file.store_buffer(frozen);snapshot_file.close()
 var receipts=[]
 var reference_shadow=field.map.sun.shadow_enabled
 var modes=['qhd-after','uhd-after']
 if '--camera-study' in OS.get_cmdline_user_args():modes=['qhd-perspective-road65','qhd-perspective-road75','uhd-perspective-road65']
 if '--gate-context-study' in OS.get_cmdline_user_args():
  if not require_capture(is_instance_valid(oracle_actor),'Gate-context camera calibration requires actual author body geometry'):return
  modes=['qhd-perspective-road65','qhd-perspective-context65','uhd-perspective-context65']
 if '--destination-study' in OS.get_cmdline_user_args():
  if not require_capture(is_instance_valid(oracle_actor),'Destination camera calibration requires actual author body geometry'):return
  modes=['qhd-perspective-road65','qhd-perspective-destination26','qhd-perspective-destination28','uhd-perspective-destination26']
 if '--shadow-diagnostic' in OS.get_cmdline_user_args():modes.append('qhd-after-no-shadow')
 for mode in modes:
  root.size=Vector2i(3840,2160) if mode.begins_with('uhd') else Vector2i(2560,1440)
  # Let native viewport resize before pixel-preserving camera calibration.
  await process_frame;await process_frame
  var after=not mode.contains('before')
  field.map.sun.shadow_enabled=reference_shadow and not mode.ends_with('no-shadow')
  old.visible=not after;model.visible=after;support.visible=after;woodland.visible=after
  field.camera_center=Vector2(34.2,1);field.camera.size=22.
  if '--camera-study' in OS.get_cmdline_user_args() or '--gate-context-study' in OS.get_cmdline_user_args() or '--destination-study' in OS.get_cmdline_user_args():
   field.camera_yaw=deg_to_rad(-75. if mode.ends_with('road75') else -65.)
   field.camera_center=field.battle.hero.pos+Vector2(4.,0.)
   field.review_camera_profile={'projection':'perspective','nominal_body_fraction':.10,'pitch_degrees':32.,'fov_degrees':55.}
  field._camera()
  if mode.ends_with('context65'):
   var target_body=AuthorOracle.projected_body(oracle_actor,field.camera)
   if not require_capture(not target_body.has('error'),'Baseline author body projection failed'):return
   field.review_camera_profile.pitch_degrees=38.;field.camera_center=field.battle.hero.pos+Vector2(5.5,0.)
   var low=.03;var high=.30
   for iteration in 22:
    field.review_camera_profile.nominal_body_fraction=(low+high)*.5;field._camera()
    var body=AuthorOracle.projected_body(oracle_actor,field.camera)
    if not require_capture(not body.has('error'),'Candidate body projection failed'):return
    if body.height_px<target_body.height_px:low=field.review_camera_profile.nominal_body_fraction
    else:high=field.review_camera_profile.nominal_body_fraction
   var matched=AuthorOracle.projected_body(oracle_actor,field.camera)
   if not require_capture(absf(matched.height_px-target_body.height_px)<.2,'Candidate shrank or enlarged body instead of preserving projected scale'):return
  var destination_fit:Dictionary={}
  if mode.contains('destination'):
   destination_fit=Destination.apply(field,oracle_actor,'destination26' if mode.ends_with('destination26') else 'destination28')
   if not require_capture(destination_fit.error==OK,'Destination framing/body fit failed'):return
  var gate_projection=Destination.projected_gate(model,field.camera) if '--destination-study' in OS.get_cmdline_user_args() else {}
  if mode.contains('destination'):
   if not require_capture(not gate_projection.has('error') and gate_projection.all_bounds_inside,'Complete destination gate bounds clipped'):return
  field._draw_field();root.scaling_3d_scale=1.
  for frame in 8:await process_frame
  if not require_capture(var_to_bytes(Store.snapshot(field.battle))==frozen,'Battle state changed between matched views'):return
  var body_projection=AuthorOracle.projected_body(oracle_actor,field.camera) if is_instance_valid(oracle_actor) else {}
  if '--validate-pairs' in OS.get_cmdline_user_args():
   print('AUTHOR_BODY_PROJECTION ',mode,' ',JSON.stringify(body_projection))
   print('MATCHED_STATE_SETUP_PASS ',mode,' snapshot=',frozen_hash);continue
  print('ARCHITECTURE_CAPTURE_BEGIN ',mode)
  await RenderingServer.frame_post_draw
  var img=root.get_texture().get_image()
  if not require_capture(img.get_size()==root.size,'Wrong native attachment pixels'):return
  var image_save_error=img.save_png(out+'/'+mode+'.png')
  if image_save_error!=OK:
   push_error('Native image write failed: '+mode+' error='+str(image_save_error));quit(1);return
  if not require_capture(var_to_bytes(Store.snapshot(field.battle))==frozen,'Battle state changed during readback'):return
  if not body_projection.is_empty():
   var sy=float(img.get_height())/float(body_projection.projection_viewport[1])
   body_projection.attachment_projection={'attachment_size':[img.get_width(),img.get_height()],'scale_xy':[float(img.get_width())/float(body_projection.projection_viewport[0]),sy],'top_y':body_projection.top_y*sy,'boot_bottom_y':body_projection.boot_bottom_y*sy,'height_px':body_projection.height_px*sy,'method':'logical_camera_projection_scaled_to_native_attachment; NOT manual visible-silhouette measurement'}
  var camera=field.camera
  var projection=camera.get_camera_projection()
  var transform=camera.global_transform
  receipts.append({'destination_fit':destination_fit,'actual_gate_projection':gate_projection,'runtime_resource_identities':resource_identity,'single_real_unit_author_oracle':oracle_receipt,'actual_author_body_projection':body_projection,'runtime_architecture_sha256':resource_identity['res://assets/river_authored/architecture/architecture.glb'].packed_resource_sha256,'additional_runtime_asset_sha256':extra_assets,'runtime_ground_sha256':FileAccess.get_sha256('res://assets/river_authored/ground/continuous-region.scn'),'runtime_woodland_sha256':FileAccess.get_sha256('res://assets/river_authored/woodland/region.scn'),'camera_review_profile':field.review_camera_profile.duplicate(),'camera_profile_scope':'INTERNAL_CANDIDATE_NOT_OFFICIAL_RIOT_PARAMETERS; nominal adult box at look target, actual hero offset must be measured','shader_clock':{'fixed_seconds':field.battle.tick*field.Battle.DT,'overrides':clock_report,'include_audit':clock.include_audit},'logical_viewport_size':[root.get_visible_rect().size.x,root.get_visible_rect().size.y],'attachment_size':[img.get_width(),img.get_height()],'shadow_enabled':field.map.sun.shadow_enabled,'comparison_role':'SHADOW_ONLY_DIAGNOSTIC_NOT_STANDARD_LIGHTING' if mode.ends_with('no-shadow') else 'NEW_TERRAIN_SAME_STATE_RESOLUTION_COMPARISON_NOT_OLD_TERRAIN_PAIR','woodland_composition':woodland.get_meta('composition','MISSING'),'battle_snapshot_sha256':frozen_hash,'controller_git_blob':OS.get_environment('CONTROLLER_BLOB'),'controller_sha256':FileAccess.get_sha256('res://scripts/field/controller.gd'),'camera_transform':{'origin':vec(transform.origin),'basis':[vec(transform.basis.x),vec(transform.basis.y),vec(transform.basis.z)]},'camera_projection':[vec4(projection.x),vec4(projection.y),vec4(projection.z),vec4(projection.w)],'camera_yaw':field.camera_yaw,'viewport':[root.size.x,root.size.y],'internal_pixels':[root.size.x,root.size.y],'seed':str(field.battle.rng.seed),'composition':'original-master' if not after else 'new-architecture-and-sprite-woodland; continuous terrain with matching versioned Ground and collision; actual extents in source manifest; CC0 dry-earth PBR','view':mode,'pixels':[img.get_width(),img.get_height()],'internal_scale':root.scaling_3d_scale,'camera_center':str(field.camera_center),'camera_size':field.camera.size,'tick':field.battle.tick,'ordinary':Array(field.battle.ordinary_counts),'hits':field.battle.hits.duplicate(),'source':OS.get_environment('GITHUB_SHA'),'stage':'MATCHED_REAL_GAME_REGION_EXPERIMENT; continuous terrain with matching versioned Ground and collision; actual extents in source manifest; CC0 dry-earth PBR; legacy crowd with optional explicitly recorded single author oracle; ART_NOT_ACCEPTED; REALTIME_INPUT_SEPARATE_RECEIPT'})
  var partial=FileAccess.open(out+'/receipt.json',FileAccess.WRITE);partial.store_string(JSON.stringify(receipts,'  '));partial.close()
  print('ARCHITECTURE_CAPTURE_SAVED ',mode)
 print('MATCHED_REGION_HEADLESS_SETUP_COMPLETE' if '--validate-pairs' in OS.get_cmdline_user_args() else 'AUTHORED_ARCHITECTURE_ACTUAL_GAME_CAPTURE '+JSON.stringify(receipts))
 field.map.sun.shadow_enabled=reference_shadow
 clock.restore()
 if '--author-dynamic-review' in OS.get_cmdline_user_args() and '--validate-pairs' not in OS.get_cmdline_user_args():
  if not require_capture(is_instance_valid(oracle_actor),'Missing complete actor for explicit live diagnostic'):return
  if not await LiveSequence.run(self,field,oracle_actor,out+'/author-live-raw'):
   push_error('Author live sequence failed; partial receipt retained');quit(1);return
 if '--traversal-review' in OS.get_cmdline_user_args():await Traversal.run(self,field,out+'/traversal-raw')
 scene.queue_free();await process_frame;await process_frame;await create_timer(.15).timeout;quit()
