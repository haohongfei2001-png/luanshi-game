class_name RepresentationBattleControl
extends SceneTree
const ContactCamera=preload("res://tools/representation_compare/contact_camera.gd")
const Asset=preload("res://tools/representation_compare/control_asset.gd")
const Battle=preload("res://scripts/field/battle.gd")
const Ground=preload("res://scripts/field/ground.gd")
const Save=preload("res://scripts/field/save.gd")
const Landscape=preload("res://scripts/field/river_master_map.gd")
var asset=Asset.new()
var battle=Battle.new()
var scene:Node3D
var camera:Camera3D
var batches:Array=[]
var sprites:Dictionary={}
var mode="shared3d"
var out:String
var direction_count=8
var size=20
var start_tick=300
var end_tick=500
var start_us=0
var previous_us=0
var carry=0.0
var timings:Array=[]
var sim_cost:Array=[]
var view_cost:Array=[]
var distance:PackedFloat64Array
var atlas_meta:Dictionary
var atlas_memory=0
var visible_units=0
var observed_states:Dictionary={}
var engine_delta_seconds=0.0
var capture=false
var camera_size=22.
var presentation_sha:String
var expected_end_sha:String
var controlled_time_shaders:Array=[]
var scene_scope="complete"
var follow_contact:=false
var camera_offset:=Vector3.ZERO
var camera_track:Array=[]
var camera_reference:Dictionary={}
var camera_cost:Array=[]
var visible_samples:Array=[]
var screen_alive_samples:Array=[]
var frame_observations:Array=[]
var screen_alive:=0
var failed:=false
func _initialize()->void:setup.call_deferred()
func quantile(values:Array,q:float)->float:
 if values.is_empty():return 0.
 var sorted=values.duplicate();sorted.sort();return sorted[mini(sorted.size()-1,int(q*(sorted.size()-1)))]
func summary(values:Array)->Dictionary:
 if values.is_empty():return {}
 var sum=0.
 for value in values:sum+=value
 return {"average_ms":sum/values.size(),"p50_ms":quantile(values,.5),"p95_ms":quantile(values,.95),"p99_ms":quantile(values,.99),"samples":values.size()}
func fail(reason:String)->void:
 failed=true;push_error(reason);quit(1)
func source_hash()->String:
 return FileAccess.get_sha256("res://assets/ubc_lab/ubc-source.glb.bin") if FileAccess.file_exists("res://assets/ubc_lab/ubc-source.glb.bin") else FileAccess.get_sha256("res://assets/ubc_lab/ubc_animated.glb")
func setup()->void:
 if OS.get_environment("COMPARE_VALIDATE_PACK")=="1":
  var packed=load("res://assets/ubc_lab/ubc_animated.glb") as PackedScene
  if packed==null or source_hash()!="64705ebc4a20650b79f863bae4b6ec47df06dfefe0ed451fe73a04ebc46295c0":fail("Comparison PCK source closure failed");return
  var proof=packed.instantiate();root.add_child(proof)
  if proof.find_children("*","Skeleton3D",true,false).size()!=1:fail("Comparison source skeleton missing");return
  var map=Landscape.new();map.bridgehead=true;root.add_child(map)
  if asset.prepare(root)!=OK:fail("Full shared source/palette/LOD closure failed");return
  var atlas_path=OS.get_environment("COMPARE_ASSETS")
  var metadata=JSON.parse_string(FileAccess.get_file_as_string(atlas_path.path_join("atlas.json")))
  if not metadata is Dictionary or metadata.source_sha256!=source_hash():fail("External atlas provenance missing");return
  var pages:=0
  for clip in metadata.clips:
   for page in metadata.clips[clip].atlas8.pages:
    var file=atlas_path.path_join(page.file)
    if FileAccess.get_sha256(file)!=page.sha256 or FileAccess.get_file_as_bytes(file).size()!=int(page.bytes):fail("External atlas payload mismatch");return
    pages+=1
  print("REPRESENTATION_COMPLETE_PACK_CLOSURE_PASS atlas8_pages=",pages," original_model=",source_hash()," full_source_and_environment_loaded; actual arrays require GPU")
  quit(0);return
 if DisplayServer.get_name()=="headless":fail("Graphics run required");return
 if OS.get_environment("COMPARE_REQUIRE_METAL")=="1" and (RenderingServer.get_current_rendering_driver_name()!="metal" or RenderingServer.get_current_rendering_method()!="mobile"):
  fail("Actual Mobile Metal required, no backend fallback");return
 print("REPRESENTATION_FOCUS ",OS.get_process_id())
 # Reuse the verified native-region startup: pump native events before resize.
 # A large initial project window is clamped by macOS; it is not a 2K target.
 for frame in 3:await process_frame
 root.grab_focus()
 var focus_deadline=Time.get_ticks_usec()+3000000
 while not root.has_focus() and Time.get_ticks_usec()<focus_deadline:await process_frame
 if not root.has_focus():fail("Own native comparison window is not focused");return
 root.size=Vector2i(2560,1440)
 await process_frame;await process_frame
 if root.size!=Vector2i(2560,1440):fail("Native comparison resize did not reach 2560x1440");return
 mode=OS.get_environment("COMPARE_MODE");size=int(OS.get_environment("COMPARE_COUNT"));out=OS.get_environment("COMPARE_OUTPUT");capture=OS.get_environment("COMPARE_CAPTURE")=="1"
 if mode.is_empty():mode="shared3d"
 if size==0:size=20
 follow_contact=OS.get_environment("COMPARE_SCALE_MATRIX")=="1"
 if follow_contact:start_tick=250 if size==512 else 50
 if OS.has_environment("COMPARE_END_TICK"):end_tick=int(OS.get_environment("COMPARE_END_TICK"))
 if end_tick<=start_tick or end_tick>620:fail("Bounded comparison end tick invalid");return
 if mode not in ["shared3d","sprite8","sprite16","hybrid","environment"] or size not in [20,100,250,512] or out.is_empty():fail("Invalid explicit comparison case");return
 DirAccess.make_dir_recursive_absolute(out)
 scene=Node3D.new();camera=Camera3D.new()
 root.add_child(scene)
 root.msaa_3d=Viewport.MSAA_4X;root.scaling_3d_scale=1.
 RenderingServer.global_shader_parameter_add("representation_clock",RenderingServer.GLOBAL_VAR_TYPE_FLOAT,0.)
 var map=Landscape.new();map.bridgehead=true;scene.add_child(map);lock_environment_clock(map)
 scene_scope=OS.get_environment("COMPARE_SCENE_SCOPE")
 if scene_scope.is_empty():scene_scope="complete"
 if scene_scope not in ["complete","actors_only"]:fail("Unknown diagnostic scene scope");return
 if scene_scope=="actors_only":
  for geometry in map.find_children("*","GeometryInstance3D",true,false):geometry.visible=false
 if OS.has_environment("COMPARE_CAMERA_SIZE"):camera_size=float(OS.get_environment("COMPARE_CAMERA_SIZE"))
 scene.add_child(camera);camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=camera_size;camera.far=360.
 var pitch=lerpf(deg_to_rad(31.),deg_to_rad(51.),smoothstep(7.,23.,22.));var yaw=deg_to_rad(-33.)
 var anchor=Vector3(Ground.BRIDGE_VIEW.x,0,Ground.BRIDGE_VIEW.y)
 camera.position=anchor+Vector3(sin(yaw)*cos(pitch),sin(pitch),cos(yaw)*cos(pitch))*77.5;camera.look_at(anchor);camera.near=maxf(.1,77.5-camera_size*.5/tan(pitch)-17.);camera.current=true
 camera_offset=camera.position-anchor
 var reference=Battle.new();reference.setup(size,Battle.SEED,Battle.Arms.Kit.SPEAR,true,true,-1,true);reference.start()
 for i in (start_tick if capture else end_tick):
  reference.step()
  if follow_contact and reference.tick>=start_tick:camera_reference[reference.tick]=ContactCamera.observe(reference)
 expected_end_sha=var_to_bytes(Save.snapshot(reference)).hex_encode().sha256_text()
 battle.setup(size,Battle.SEED,Battle.Arms.Kit.SPEAR,true,true,-1,true);battle.start();distance.resize(battle.roster.size())
 for i in start_tick:
  battle.step()
  for u in battle.roster:distance[u.id]+=u.before.distance_to(u.pos)
 if follow_contact:update_contact_camera()
 presentation_sha=var_to_bytes(Save.snapshot(battle)).hex_encode().sha256_text()
 if mode in ["shared3d","hybrid"]:
  if asset.prepare(scene)!=OK:quit(1);return
  batches=asset.batches(scene,battle.roster.size())
 if mode.begins_with("sprite") or mode=="hybrid":
  direction_count=16 if mode=="sprite16" else 8
  var path=OS.get_environment("COMPARE_ASSETS");atlas_meta=JSON.parse_string(FileAccess.get_file_as_string(path.path_join("atlas.json")))
  if mode!="hybrid":asset.clips=atlas_meta.clips
  if atlas_meta.source_sha256!=source_hash():fail("Atlas source identity mismatch");return
  for clip:String in asset.clips:
   var data=atlas_meta.clips[clip];var texture:Texture2DArray=load_atlas_pages(path,data["atlas"+str(direction_count)])
   if texture==null:return
   var mat=ShaderMaterial.new();mat.shader=load("res://tools/representation_compare/sprite.gdshader");mat.set_shader_parameter("atlas",texture);mat.set_shader_parameter("tile_pixels",Vector2(data.tile[0],data.tile[1]));mat.set_shader_parameter("atlas_pixels",Vector2(texture.get_width(),texture.get_height()));mat.set_shader_parameter("columns",int(data["columns"+str(direction_count)]));mat.set_shader_parameter("directions",direction_count);mat.set_shader_parameter("page_rows",int(data.page_rows));mat.set_shader_parameter("projected_center",Vector2(data.center_projected[0],data.center_projected[1]));mat.set_shader_parameter("per_frame_center",data.has("center_offsets16"))
   var quad=QuadMesh.new();quad.size=Vector2(data.world_size[0],data.world_size[1]);quad.material=mat
   var node=MultiMeshInstance3D.new();var mm=MultiMesh.new();mm.transform_format=MultiMesh.TRANSFORM_3D;mm.use_custom_data=true;mm.use_colors=true;mm.mesh=quad;mm.instance_count=battle.roster.size();mm.custom_aabb=AABB(Vector3(-150,-5,-100),Vector3(300,60,200));node.multimesh=mm;scene.add_child(node);sprites[clip]=node
   atlas_memory+=int(data["atlas"+str(direction_count)].compressed_mip_bytes)
 update_view()
 if failed:return
 for frame in 5:await process_frame
 if capture:
  await RenderingServer.frame_post_draw
  var image=root.get_texture().get_image()
  if image.get_size()!=Vector2i(2560,1440):fail("Actual native attachment is not 2560x1440");return
  image.save_png(out.path_join("same-tick-native.png"))
  finish();return
 start_us=Time.get_ticks_usec();previous_us=start_us
func update_contact_camera()->void:
 if not camera_reference.has(battle.tick):fail("Missing exact-tick reference camera");return
 var row:Dictionary=camera_reference[battle.tick].duplicate(true);var xy=Vector2(row.center[0],row.center[1])
 var anchor=Vector3(xy.x,Ground.deck_height(xy,true),xy.y)
 camera.position=anchor+camera_offset;camera.look_at(anchor)
 row["camera_position"]=[camera.position.x,camera.position.y,camera.position.z]
 camera_track.append(row)
func counts_summary(values:Array)->Dictionary:
 if values.is_empty():return {}
 var sorted=values.duplicate();sorted.sort()
 return {"min":sorted[0],"median":sorted[int(sorted.size()/2)],"max":sorted[-1],"samples":values.size()}
func state(u)->Dictionary:
 var clip="Idle";var phase=fposmod(float(battle.tick)*Battle.DT/asset.clips.Idle.length,1.)
 if u.state==Battle.State.DEAD:
  clip="Death01";phase=clampf(float(battle.tick-u.lost_tick)*Battle.DT/asset.clips[clip].length,0.,1.)
 elif u.state==Battle.State.STAGGER:
  clip="Hit_Chest";phase=clampf((u.duration-u.timer)/asset.clips[clip].length,0.,1.)
 elif u.state in [Battle.State.WINDUP,Battle.State.RECOVER]:
  clip="Sword_Attack";phase=clampf((u.duration-u.timer)/maxf(.01,u.duration),0.,1.)
 elif u.pos.distance_squared_to(u.before)>.000001:
  clip="Walk";phase=fposmod(distance[u.id]/1.345947387,1.)
 var count=int(asset.clips[clip].count);return {"clip":clip,"local":mini(count-1,int(phase*count)),"yaw":atan2(u.facing.x,u.facing.y)}
func update_view()->void:
 RenderingServer.global_shader_parameter_set("representation_clock",float(battle.tick)*Battle.DT)
 var before=var_to_bytes(Save.snapshot(battle)) if start_us==0 else PackedByteArray()
 var used={};var count3=0;visible_units=0;screen_alive=0
 for clip in sprites:used[clip]=0
 var screen_rect=Rect2(Vector2.ZERO,root.get_visible_rect().size)
 var rectangle=screen_rect.grow(root.get_visible_rect().size.x/camera_size*3.)
 for u in battle.roster:
  observed_states[u.state]=true
  if u.state==Battle.State.ESCAPED:continue
  var p=Vector3(u.pos.x,Ground.deck_height(u.pos,true),u.pos.y)
  if camera.is_position_behind(p):continue
  var projected=camera.unproject_position(p+Vector3(0,1,0))
  if not rectangle.has_point(projected):continue
  visible_units+=1
  if u.hp>0 and u.state!=Battle.State.DEAD and screen_rect.has_point(projected):screen_alive+=1
  if mode=="environment":continue # Diagnostic only: no character draw, real simulation remains.
  var pose=state(u)
  var use3=mode=="shared3d" or (mode=="hybrid" and (u.hero or u.officer))
  if use3:
   asset.set_actor(batches,count3,Transform3D(Basis(Vector3.UP,pose.yaw),p),int(asset.clips[pose.clip].offset)+pose.local);count3+=1
  elif not sprites.is_empty():
   var mm:MultiMesh=sprites[pose.clip].multimesh;var index=int(used[pose.clip]);mm.set_instance_color(index,Color.WHITE);mm.set_instance_transform(index,Transform3D(Basis.IDENTITY,p+Vector3(0,.95,0)));var facing=posmod(roundi(pose.yaw/TAU*direction_count),direction_count)
   var center=Vector2.ZERO;var clip_meta:Dictionary=atlas_meta.clips[pose.clip]
   if clip_meta.has("center_offsets16"):
    var source_direction=facing if direction_count==16 else facing*2
    var offset:Array=clip_meta.center_offsets16[pose.local*16+source_direction];center=Vector2(offset[0],offset[1])
   mm.set_instance_custom_data(index,Color(pose.local,facing,center.x,center.y));used[pose.clip]=index+1
 for node in batches:node.multimesh.visible_instance_count=count3
 for clip in sprites:sprites[clip].multimesh.visible_instance_count=used[clip]
 if not before.is_empty() and before!=var_to_bytes(Save.snapshot(battle)):fail("Presentation mutated real combat");return
func _process(delta:float)->bool:
 if failed:return true
 if start_us==0:return false
 var now=Time.get_ticks_usec();timings.append((now-previous_us)/1000.);previous_us=now
 engine_delta_seconds+=delta
 carry+=delta
 var begin=Time.get_ticks_usec();var camera_us:=0
 while carry>=Battle.DT and battle.tick<end_tick:
  battle.step();carry-=Battle.DT
  if follow_contact:
   var camera_begin=Time.get_ticks_usec();update_contact_camera();camera_us+=Time.get_ticks_usec()-camera_begin
  for u in battle.roster:distance[u.id]+=u.before.distance_to(u.pos)
 sim_cost.append((Time.get_ticks_usec()-begin-camera_us)/1000.);camera_cost.append(camera_us/1000.)
 begin=Time.get_ticks_usec();update_view();view_cost.append((Time.get_ticks_usec()-begin)/1000.)
 visible_samples.append(visible_units);screen_alive_samples.append(screen_alive)
 frame_observations.append({"tick":battle.tick,"conservative_visible_including_dead":visible_units,"alive_centers_in_screen":screen_alive,"camera_position":[camera.position.x,camera.position.y,camera.position.z]})
 if battle.result!="" and battle.tick<end_tick:fail("Battle ended before required measurement window");return true
 if battle.tick>=end_tick:finish();return true
 return false
func finish()->void:
 if failed:return
 if var_to_bytes(Save.snapshot(battle)).hex_encode().sha256_text()!=expected_end_sha:fail("Renderer/full-chain differs from independent simulation-only oracle");return
 var wall=(Time.get_ticks_usec()-start_us)/1000000. if start_us>0 else 0.
 var report={"input_contract":"neutral default hero input on both routes; actual ordinary AI combat, not a player-action quality test","camera_cpu":summary(camera_cost),"camera_cost_policy":"O(1) exact-tick replay of independent real Battle prepass, generated before timing; final actual Battle SHA verified; visibility reuses existing projection no extra scans","camera_tracking":"actual_contact_fixed_lens" if follow_contact else "static_bridge_control","camera_track_sha256":JSON.stringify(camera_track).sha256_text(),"conservative_visible_summary":counts_summary(visible_samples),"alive_screen_centers_summary":counts_summary(screen_alive_samples),"scene_scope":scene_scope,"environment_resources_retained":true,"diagnostic_drawing_only":scene_scope=="actors_only" or mode=="environment","control_only":"draw isolation diagnostic, not playable performance" if mode=="environment" or scene_scope=="actors_only" else "unclothed UBC, no armor or held weapon quality claim","engine_delta_seconds_accumulated":engine_delta_seconds,"simulation_clock_policy":"engine callback delta, may clamp below actual wall time; no realtime-speed claim","mode":mode,"per_side":size,"seed":Battle.SEED,"start_tick":start_tick,"end_tick":battle.tick,"start_snapshot_sha":presentation_sha,"end_snapshot_sha":var_to_bytes(Save.snapshot(battle)).hex_encode().sha256_text(),"hits":battle.hits.duplicate(),"losses":battle.losses.duplicate(),"roster":battle.roster.size(),"visible_units_conservative_cull":visible_units,"state_keys":observed_states.keys(),"battle_unchanged_by_renderer":true,"independent_simulation_oracle_sha":expected_end_sha,"invariant_guard_policy":"startup before-after; final independent simulation oracle, no per-frame serialization in timings","capture_run_not_performance":capture,"frames":timings.size(),"wall_seconds":wall,"average_fps":timings.size()/wall if wall>0 else 0.,"measurement_scope":"short fixed-simulation-window control, not thermal/device qualification", "sample_adequacy":{"actual_frames":timings.size(),"wall_seconds":wall,"p99_tail_sample_count":timings.size()*.01,"stable_p99_claimed":false,"M5_tested":false},"frame_time":summary(timings),"simulation_cpu":summary(sim_cost),"presentation_cpu":summary(view_cost),"explicit_lod_inventory":asset.explicit_lod_inventory,"palette_bytes":asset.palette_bytes,"unnecessary_3d_source_loaded":mode in ["shared3d","hybrid"],"controlled_shader_clock":controlled_time_shaders,"clock_seconds":float(battle.tick)*Battle.DT,"atlas_compressed_mip_bytes":atlas_memory,"texture_memory":Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED),"video_memory":Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED),"process_static_memory":OS.get_static_memory_usage(),"process_static_peak":OS.get_static_memory_peak_usage(),"render_primitives":Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),"renderer":RenderingServer.get_video_adapter_name(),"driver":RenderingServer.get_current_rendering_driver_name(),"method":RenderingServer.get_current_rendering_method(),"source_model_sha256":source_hash(),"engine":Engine.get_version_info(),"viewport":[root.size.x,root.size.y],"native_resize_policy":"after event-loop/focus, no SubViewport or image resize","logical_viewport":[root.get_visible_rect().size.x,root.get_visible_rect().size.y],"internal_scale":root.scaling_3d_scale,"camera_ortho_size":camera_size,"camera_pitch_policy":"fixed Field22 pitch while comparing new MOBA screen scale; atlas uses identical elevation","camera_transform":str(camera.transform),"shadow_note":"sprite casts alpha plane shadow, not body-depth-correct; quality pending","missing_visuals":["all weapons","riding","full unit class costumes"],"resident_process_memory":resident_memory(),"gpu_memory_scope":"Godot allocation counters; driver residency and software-render RAM duplication not measured","lighting_note":"same sun/ambient; atlas LDR linear-tonemap bake followed by final scene FILMIC, HDR clipping needs image review","sprite_quality_gaps":["direction quantization","LDR bake","no normal/depth atlas","alpha threshold/mipmap/compression edges","flat-plane shadow"],"art_pass":false,"M5":"NOT_TESTED"}
 FileAccess.open(out.path_join("raw-intervals.json"),FileAccess.WRITE).store_string(JSON.stringify({"frame_ms":timings,"simulation_ms":sim_cost,"presentation_ms":view_cost,"camera_replay_ms":camera_cost,"visibility_and_camera":frame_observations,"fixed_tick_contact_camera":camera_track}))
 FileAccess.open(out.path_join("report.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
 print("REPRESENTATION_CONTROL ",JSON.stringify(report));quit()

func resident_memory()->Dictionary:
 var result={"scope":"Linux /proc/self/status process RSS/HWM, not total system memory"}
 if not FileAccess.file_exists("/proc/self/status"):return {"available":false}
 var stream=FileAccess.open("/proc/self/status",FileAccess.READ)
 while not stream.eof_reached():
  var line=stream.get_line()
  if line.begins_with("VmRSS:") or line.begins_with("VmHWM:"):result[line.get_slice(":",0)]=line.get_slice(":",1).strip_edges()
 return result
func lock_environment_clock(map:Node)->void:
 var seen={}
 for node in map.find_children("*","GeometryInstance3D",true,false):
  var mesh:Mesh
  if node is MeshInstance3D:mesh=node.mesh
  elif node is MultiMeshInstance3D and node.multimesh:mesh=node.multimesh.mesh
  if mesh==null:continue
  for surface in mesh.get_surface_count():
   var material=node.get_active_material(surface) if node is MeshInstance3D else mesh.surface_get_material(surface)
   if not material is ShaderMaterial or material.shader==null:continue
   var shader:Shader=material.shader
   if not shader.code.contains("TIME"):continue
   var id=shader.get_instance_id()
   if not seen.has(id):
    var controlled=Shader.new();var regex=RegEx.new();regex.compile("\\bTIME\\b")
    controlled.code=regex.sub(shader.code,"representation_clock",true).replace("shader_type spatial;","shader_type spatial;\nglobal uniform float representation_clock;")
    seen[id]=controlled;controlled_time_shaders.append(shader.resource_path)
   material.shader=seen[id]

func load_atlas_pages(path:String,receipt:Dictionary)->Texture2DArray:
 var images:Array[Image]=[]
 for page:Dictionary in receipt.pages:
  var filename=path.path_join(page.file)
  if FileAccess.get_sha256(filename)!=page.sha256:fail("Compressed page SHA changed");return null
  var bytes=FileAccess.get_file_as_bytes(filename)
  if bytes.size()!=int(page.bytes):fail("Compressed page byte count changed");return null
  var image=Image.create_from_data(int(page.width),int(page.height),page.mipmaps,int(page.format),bytes)
  if image==null or image.is_empty():fail("Invalid atlas image payload");return null
  images.append(image)
 var texture=Texture2DArray.new()
 var creation_error=texture.create_from_images(images)
 if creation_error!=OK:push_error("Actual Texture2DArray creation failed: "+str(creation_error));quit(1);return null
 if texture.get_width()!=int(receipt.pages[0].width) or texture.get_layers()!=int(receipt.layers):fail("Atlas array dimensions mismatch");return null
 return texture
