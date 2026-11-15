extends SceneTree
# ISOLATED DEFAULT-OFF 2.5D FEASIBILITY. Never loaded by the main game.
const Battle=preload("res://scripts/field/battle.gd")
const Navigation=preload("res://scripts/field/maps/authored_navigation.gd")
const Runtime=preload("res://scripts/field/maps/authored_field_runtime.gd")
const Muster=preload("res://scripts/field/maps/authored_muster.gd")
const Actor=preload("res://scripts/field/experimental/production_v2/shared_skeletal_actor.gd")
const Binding=preload("res://scripts/field/experimental/production_v2/mh_spear_battle_binding.gd")
const SOURCE_SIZE=Vector2(1672,941)
const PLATE_HEIGHT=36.0
const CAMERA_SIZE=22.0
const SIN45=0.7071067811865476
const ACTOR_SHA="afb966396bf5ad656b3cb0cd2edc388fc6fa02eba59df8b81d9a23ac53f3be8b"
var world:Node3D
var camera:Camera3D
var battle
var runtime
var source:Dictionary
var actors:Dictionary={}
var proxies:Dictionary={}
var bindings:Dictionary={}
var material:StandardMaterial3D
var elapsed:=0.0
var carry:=0.0
var running:=false
var capture_busy:=false
var next_capture:=0.0
var sample_index:=0
var initial_positions:Dictionary={}
var initial_identity:Array=[]
var mode:="combat"
var out:=""
var report:Dictionary={}
var trace:Array=[]
var route_index:=0
var paths:Array[Vector2]=[]
var headless_test:=false
var camera_offset:=Vector2(-3.,0.)
var hud:Label
var interactive:=false
var shadows:Dictionary={}
var user_pan:=Vector2.ZERO
var mouse_aim:=Vector2.RIGHT
# The authored coordinates below are source-image pixels. Their single inverse
# projection is used by both rendered surfaces and navigation/collisions.
func point(pixel:Vector2,y:float=0.)->Vector3:
 var vertical:float=(pixel.y/SOURCE_SIZE.y-.5)*PLATE_HEIGHT
 return Vector3((pixel.x/SOURCE_SIZE.x-.5)*PLATE_HEIGHT*SOURCE_SIZE.x/SOURCE_SIZE.y,y,(vertical+y*SIN45)/SIN45)
func pixel(world_point:Vector3)->Vector2:
 return Vector2((world_point.x/(PLATE_HEIGHT*SOURCE_SIZE.x/SOURCE_SIZE.y)+.5)*SOURCE_SIZE.x,((world_point.z*SIN45-world_point.y*SIN45)/PLATE_HEIGHT+.5)*SOURCE_SIZE.y)
func plan(raw:Array)->Array:
 var a:Array=[]
 for p in raw:
  var q=point(Vector2(p[0],p[1]));a.append([q.x,q.z])
 return a
func centre(raw:Array)->Vector3:
 var q:=Vector3.ZERO
 for p in raw:q+=point(Vector2(p[0],p[1]))
 return q/raw.size()
func build_source()->Dictionary:
 var parts:Array=[
  [[0,941],[0,800],[200,650],[380,510],[600,455],[810,420],[861,439],[1070,486],[1000,600],[800,705],[580,823],[350,941]],
  [[861,439],[1108,348],[1330,382],[1070,486]],
  [[1108,348],[1188,324],[1246,329],[1323,330],[1343,350],[1330,382]],
  [[1246,329],[1246,248],[1320,248],[1323,330]],
  [[1246,248],[1246,190],[1550,170],[1610,230],[1320,248]]
 ]
 var verts:Array=[];var faces:Array=[]
 for poly in parts:
  var points:=PackedVector2Array();var offset:=verts.size()
  for p in poly:
   points.append(Vector2(p[0],p[1]));var q=point(Vector2(p[0],p[1]));verts.append([q.x,q.y,q.z])
  var indices=Geometry2D.triangulate_polygon(points)
  assert(not indices.is_empty())
  for i in range(0,indices.size(),3):faces.append([offset+indices[i],offset+indices[i+1],offset+indices[i+2]])
 var west=plan([[665,496],[889,485],[990,548],[750,640]])
 var east=plan([[1110,355],[1265,340],[1300,368],[1120,417]])
 if mode=="traversal":east=plan([[1270,192],[1545,180],[1565,225],[1325,238]])
 var gate=point(Vector2(1285,330));var court=point(Vector2(1330,220))
 var d={"map_id":"luanshi.experimental25d.ownerplate.v2","topology_revision":1,"topology_sha256":"","surfaces":[{"id":"same_source_walk","walkable":true,"vertices":verts,"triangles":faces}],"solids":[],"portals":[],"gate_dynamic":{"pivot":[gate.x,gate.y,gate.z]},"goal_regions":[{"center":[court.x,court.y,court.z]}],"spawn_regions":[{"id":"west","team":0,"xz_polygon":west,"reserved_corridor_z":[1000,1001]},{"id":"east","team":1,"xz_polygon":east,"reserved_corridor_z":[1000,1001]}],"retreat_regions":[{"xz_polygon":west},{"xz_polygon":plan([[1260,210],[1500,190],[1500,215],[1260,235]])}],"status":"ISOLATED_PROJECTION_TOPOLOGY_NOT_MOTHER_ART_ACCEPTANCE"}
 # Rail foot footprints are also generated from the same visible endpoints.
 for row in [["near_rail",[1070,486],[1330,382]],["far_rail",[861,439],[1108,348]]]:
  var a:Vector3=point(Vector2(row[1][0],row[1][1]));var b:Vector3=point(Vector2(row[2][0],row[2][1]));var side:=Vector2(-(b.z-a.z),b.x-a.x).normalized()*.08
  d.solids.append({"id":row[0],"xz_polygon":[[a.x+side.x,a.z+side.y],[b.x+side.x,b.z+side.y],[b.x-side.x,b.z-side.y],[a.x-side.x,a.z-side.y]],"min_y":-.5,"max_y":1.5})
 d.topology_sha256=JSON.stringify(d).sha256_text();return d
func mesh_polygon(name:String,raw:Array,baseline:Array=[],y_constant:float=-60.)->void:
 var pts:=PackedVector2Array();var verts:=PackedVector3Array();var uvs:=PackedVector2Array()
 for p in raw:
  var px:=Vector2(p[0],p[1]);pts.append(px);var y:=y_constant
  if not baseline.is_empty():
   var base_y:float=lerpf(float(baseline[0][1]),float(baseline[1][1]),(px.x-float(baseline[0][0]))/(float(baseline[1][0])-float(baseline[0][0])))
   y=(base_y-px.y)/SOURCE_SIZE.y*PLATE_HEIGHT/SIN45
  verts.append(point(px,y));uvs.append(px/SOURCE_SIZE)
 var indices=Geometry2D.triangulate_polygon(pts);assert(not indices.is_empty(),name)
 var arrays:=[];arrays.resize(Mesh.ARRAY_MAX);arrays[Mesh.ARRAY_VERTEX]=verts;arrays[Mesh.ARRAY_TEX_UV]=uvs;arrays[Mesh.ARRAY_INDEX]=indices
 var mesh:=ArrayMesh.new();mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
 var node:=MeshInstance3D.new();node.name=name;node.mesh=mesh;node.material_override=material;node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;world.add_child(node)
func make_environment()->void:
 var tex=load("res://assets/environment-wide-v2.png");assert(tex.get_size()==SOURCE_SIZE)
 material=StandardMaterial3D.new();material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;material.albedo_texture=tex;material.cull_mode=BaseMaterial3D.CULL_DISABLED
 material.texture_filter=BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
 mesh_polygon("WorldAnchoredBasePlate_NOT_SCREEN_BACKGROUND",[[0,0],[1672,0],[1672,941],[0,941]])
 # Vector silhouette crops of the generated material. No raster editing or
 # opaque rectangle hides units. The rail's open gaps remain truly open.
 var near_base=[[1070,486],[1330,382]]
 for poly in [
  [[1065,428],[1087,428],[1087,481],[1071,489]],
  [[1146,400],[1164,394],[1164,450],[1147,457]],
  [[1229,370],[1248,366],[1248,419],[1231,427]],
  [[1289,350],[1308,346],[1308,396],[1290,403]],
  [[1080,438],[1333,346],[1333,354],[1080,447]],
  [[1080,459],[1333,366],[1333,374],[1080,467]],
  [[1070,480],[1337,381],[1337,399],[1070,501]]
 ]:mesh_polygon("BridgeNearRailDepth",poly,near_base)
 var far_base=[[861,439],[1108,348]]
 for poly in [
  [[851,385],[871,383],[871,432],[851,442]],
  [[930,358],[947,355],[947,404],[930,410]],
  [[1005,333],[1023,329],[1023,375],[1005,381]],
  [[1057,314],[1073,311],[1073,357],[1057,364]],
  [[864,393],[1111,310],[1111,318],[864,401]],
  [[864,416],[1111,332],[1111,340],[864,424]]
 ]:mesh_polygon("BridgeFarRailDepth",poly,far_base)
 var gate_base=[[1190,338],[1347,350]]
 for poly in [
  [[1150,180],[1195,187],[1195,338],[1150,350]],
  [[1340,207],[1398,217],[1398,385],[1340,354]],
  [[1177,194],[1364,208],[1364,246],[1177,226]],
  [[1190,233],[1253,238],[1253,320],[1190,339]],
  [[1320,244],[1344,249],[1344,348],[1320,329]]
 ]:mesh_polygon("GateActualDepthMask",poly,gate_base)
func _initialize()->void:
 var args=OS.get_cmdline_user_args()
 if OS.get_environment("LUANSHI_25D_EXPERIMENT")!="1":push_error("DEFAULT_OFF: explicit LUANSHI_25D_EXPERIMENT=1 required");quit(4);return
 headless_test="--test" in args
 interactive="--interactive" in args
 if "--traversal" in args:mode="traversal"
 out=OS.get_environment("LUANSHI_25D_OUT")
 if out.is_empty():out=ProjectSettings.globalize_path("res://evidence")
 DirAccess.make_dir_recursive_absolute(out)
 start.call_deferred()
func start()->void:
 source=build_source();var nav=Navigation.new();assert(nav.configure(source,Rect2(-34,-26,68,55),{"gate_main":true},.45,1.9,.5)==OK)
 runtime=Runtime.new();assert(runtime.bind(nav,source)==OK)
 battle=Battle.new();battle.setup(8,61112,Battle.Arms.Kit.SPEAR,true,false,8,false)
 var receipt=Muster.apply(battle,runtime);assert(receipt.error==OK,JSON.stringify(receipt))
 for u in battle.roster:initial_positions[u.id]=u.pos;initial_identity.append([u.id,u.team,u.kit,u.max_hp,u.officer,u.hero])
 report={"experiment":"2.5D fixed-angle world-anchored projection","mode":mode,"source_texture_sha":FileAccess.get_sha256("res://assets/environment-wide-v2.png"),"actor_sha":FileAccess.get_sha256("res://assets/spearman-v2-wip.glb"),"topology":source.topology_sha256,"setup":receipt,"ordinary_per_side":Array(battle.ordinary_counts),"roster":battle.roster.size(),"camera_size":CAMERA_SIZE,"camera_angle_degrees":45,"source_texture_pixels":SOURCE_SIZE,"art":"FAIL_WIP_NOT_OWNER_ACCEPTED","rotation":"UNSUPPORTED_THIS_ISOLATED_MODE_ONLY_MAIN_UNCHANGED","dynamic_environment_light":"UNSUPPORTED_PRELIT","512v512":"NOT_RUN_NO_CAPACITY_CLAIM","input":"real Battle.input_state/press_action; no live Unit positions or HP assigned"}
 FileAccess.open(out+"/topology.json",FileAccess.WRITE).store_string(JSON.stringify(source))
 paths=[Vector2(900,485),Vector2(1025,430),Vector2(1170,375),Vector2(1280,342),Vector2(1280,290),Vector2(1360,215)]
 for i in paths.size():var p=point(paths[i]);paths[i]=Vector2(p.x,p.z)
 if headless_test:test_headless();return
 world=Node3D.new();root.add_child(world);make_environment()
 var env:=WorldEnvironment.new();var e:=Environment.new();e.background_mode=Environment.BG_COLOR;e.background_color=Color(.12,.05,.17);e.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;e.ambient_light_color=Color(.68,.74,.8);e.ambient_light_energy=.75;env.environment=e;world.add_child(env)
 var sun:=DirectionalLight3D.new();sun.rotation_degrees=Vector3(-55,-35,0);sun.light_energy=1.8;sun.shadow_enabled=false;world.add_child(sun)
 camera=Camera3D.new();camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=CAMERA_SIZE;camera.far=300.;world.add_child(camera);camera.current=true
 var packed=load("res://assets/spearman-v2-wip.glb");var timing=JSON.parse_string(FileAccess.get_file_as_string("res://assets/timing.json"))
 for u in battle.roster:
  if u.kit==Battle.Arms.Kit.SPEAR and not u.mounted:
   var actor=Actor.new();world.add_child(actor);assert(actor.setup(packed)==OK);var binding=Binding.new();binding.enabled=true;binding.ground_point=Callable(runtime,"unit_point");assert(binding.configure_timing(timing,ACTOR_SHA)==OK);actors[u.id]=actor;bindings[u.id]=binding
  else:
   # Explicit other-kit diagnostic proxies are NOT disguised as spear soldiers.
   var proxy=MeshInstance3D.new();var shape=CapsuleMesh.new();shape.radius=.28;shape.height=1.6;proxy.mesh=shape;var mat=StandardMaterial3D.new();mat.albedo_color=Color(.2,.45,.7) if u.team==0 else Color(.65,.25,.18);proxy.material_override=mat;world.add_child(proxy);proxies[u.id]=proxy
 for u in battle.roster:
  var shadow=MeshInstance3D.new();var plane=PlaneMesh.new();plane.size=Vector2(.9,.65);shadow.mesh=plane;var sm=ShaderMaterial.new();var ss=Shader.new();ss.code="shader_type spatial; render_mode unshaded, cull_disabled, depth_draw_never; void fragment(){ ALBEDO=vec3(0.04,0.035,0.03); ALPHA=0.28*(1.0-smoothstep(0.15,0.5,length(UV-vec2(0.5)))); }";sm.shader=ss;shadow.material_override=sm;world.add_child(shadow);shadows[u.id]=shadow
 report.new_spear_actors=actors.keys();report.other_kit_diagnostic_proxies=proxies.keys();report.rendering={"engine":Engine.get_version_info(),"os":OS.get_name(),"device":RenderingServer.get_video_adapter_name(),"vendor":RenderingServer.get_video_adapter_vendor(),"method":RenderingServer.get_current_rendering_method(),"viewport":root.size,"internal_scale":root.scaling_3d_scale}
 var layer=CanvasLayer.new();root.add_child(layer);hud=Label.new();hud.position=Vector2(18,18);hud.add_theme_font_size_override("font_size",24);layer.add_child(hud)
 var driver=load("res://physics_driver.gd").new();driver.experiment=self;root.add_child(driver)
 battle.start();running=true;update_view(0.);await process_frame
 print("25D_GPU_STARTED ",JSON.stringify(report))
func set_camera(foot:Vector3)->void:
 var focus=foot+Vector3(camera_offset.x+user_pan.x,1.0,camera_offset.y+user_pan.y)
 var source_focus=pixel(focus);var half=SOURCE_SIZE*(CAMERA_SIZE/PLATE_HEIGHT)*.5
 source_focus=source_focus.clamp(half,SOURCE_SIZE-half)
 focus=point(source_focus,1.0)
 camera.position=focus+Vector3(0,40,40);camera.look_at(focus)
func update_view(delta:float)->void:
 for id in actors:bindings[id].update_unit(battle,battle.roster[id],actors[id],delta,clampf(carry/Battle.DT,0,1) if battle.result=="" else 1.)
 for id in shadows:shadows[id].position=runtime.unit_point(battle.roster[id].pos)+Vector3(0,.025,0)
 for id in proxies:
  var u=battle.roster[id];proxies[id].position=runtime.unit_point(u.pos)+Vector3(0,.8,0)
  if u.hp<=0:proxies[id].rotation.z=1.57;proxies[id].position.y=.28
 set_camera(runtime.unit_point(battle.hero.pos))
 hud.text="ISOLATED 2.5D WIP | 22m fixed-angle | %s | tick %d | hits %s | losses %s\nReal spear actors: %d | other-kit capsules: %d (diagnostic, NOT art pass)\nWASD move / mouse aim / click attack | rotation + dynamic environment light NOT supported"%[mode,battle.tick,str(battle.hits),str(battle.losses),actors.size(),proxies.size()]
func auto_input()->void:
 var direction:=Vector2.ZERO
 if route_index<paths.size():
  if battle.hero.pos.distance_to(paths[route_index])<.65:route_index+=1
  if route_index<paths.size():direction=battle.hero.pos.direction_to(runtime.waypoint(battle.hero.pos,paths[route_index]))
 var nearest=null;var distance:=INF
 for u in battle.roster:
  if u.team!=battle.hero.team and battle.active(u) and battle.hero.pos.distance_to(u.pos)<distance:nearest=u;distance=battle.hero.pos.distance_to(u.pos)
 var aim=direction
 if mode=="combat" and nearest!=null and distance<4.:
  aim=battle.hero.pos.direction_to(nearest.pos)
  if distance<2.9:direction=Vector2.ZERO;battle.press_action(0)
 battle.input_state(direction,aim)
func _process(delta:float)->bool:
 if not running:return false
 elapsed+=delta
 update_view(delta)
 if elapsed>=next_capture and not capture_busy:
  next_capture=elapsed+(2.0 if OS.get_environment("LUANSHI_25D_STILLS_ONLY")=="1" else .1);capture.call_deferred()
 if not interactive and (elapsed>=24. or (battle.result!="" and elapsed>=10.)):finish.call_deferred();running=false
 return false
func physics_tick(delta:float)->void:
 if not running:return
 carry+=delta
 while carry>=Battle.DT:
  carry-=Battle.DT
  if interactive:
   var walk=Vector2(float(Input.is_physical_key_pressed(KEY_D))-float(Input.is_physical_key_pressed(KEY_A)),float(Input.is_physical_key_pressed(KEY_S))-float(Input.is_physical_key_pressed(KEY_W)))
   battle.input_state(walk,mouse_aim)
  else:auto_input()
  battle.step()
func handle_input(event:InputEvent)->void:
 if not running or not interactive:return
 if event is InputEventMouseMotion:
  var origin=camera.project_ray_origin(event.position);var ray=camera.project_ray_normal(event.position)
  if absf(ray.y)>.00001:
   var at=origin-ray*origin.y/ray.y;mouse_aim=battle.hero.pos.direction_to(Vector2(at.x,at.z))
 if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT:battle.press_action(0)
 if event is InputEventKey and event.pressed:
  if event.keycode==KEY_ESCAPE:running=false;finish.call_deferred()
  if event.keycode==KEY_LEFT:user_pan.x-=1.
  if event.keycode==KEY_RIGHT:user_pan.x+=1.
  if event.keycode==KEY_UP:user_pan.y-=1.
  if event.keycode==KEY_DOWN:user_pan.y+=1.
func capture()->void:
 capture_busy=true;await RenderingServer.frame_post_draw
 var image=root.get_texture().get_image()
 if not image.is_empty():
  image.save_png(out+"/frame-%05d.png"%sample_index)
  report.actual_capture_pixels=[image.get_width(),image.get_height()]
 var foot=runtime.unit_point(battle.hero.pos);var original=pixel(foot)
 trace.append({"frame":sample_index,"wall_seconds":elapsed,"tick":battle.tick,"hero_position":[foot.x,foot.y,foot.z],"source_foot_pixel":[original.x,original.y],"viewport_foot_pixel":camera.unproject_position(foot),"camera_position":camera.position,"hero_hp":battle.hero.hp,"hits":battle.hits.duplicate(),"losses":battle.losses.duplicate()})
 sample_index+=1;capture_busy=false
func finish()->void:
 if capture_busy:await process_frame;finish.call_deferred();return
 report.render_input_path="isolated Battle-driven Node._physics_process, NOT original Controller input acceptance";report.finite_camera_bounds="source plate bounds clamped at constant22m; main camera unchanged";report.simulated_seconds=battle.tick*Battle.DT;report.elapsed_seconds=elapsed;report.actual_tick=battle.tick;report.actual_hits=battle.hits;report.actual_losses=battle.losses;report.hero_hp=battle.hero.hp;report.path_waypoints_reached=route_index;report.frames=sample_index;report.trace=trace
 report.active_invalid=[]
 for u in battle.roster:
  if battle.active(u) and runtime.blocked(u.pos,true):report.active_invalid.append(u.id)
 FileAccess.open(out+"/result.json",FileAccess.WRITE).store_string(JSON.stringify(report,"  "));print("25D_FINAL ",JSON.stringify(report));quit()
func test_headless()->void:
 var probe=point(Vector2(900,485));var p:=Vector2(probe.x,probe.z);var steps:=0;var reached:=0
 for goal in paths:
  for i in 700:
   var next=runtime.waypoint(p,goal);p=runtime.travel(p,p.direction_to(next)*minf(.1,p.distance_to(next)),true);steps+=1
   assert(not runtime.blocked(p,true))
   if p.distance_to(goal)<.3:reached+=1;break
  if p.distance_to(goal)>=.3:break
 var max_error:=0.
 for screen in [Vector2(900,485),Vector2(1070,486),Vector2(1285,330)]:
  for h in [-60.,0.,1.,5.]:max_error=maxf(max_error,pixel(point(screen,h)).distance_to(screen))
 # Orthographic translation has no depth-dependent parallax. Verify exact
 # shared projection world points, not merely declared image coordinates.
 report.projection_roundtrip_max_source_px=max_error;report.route_reached=reached;report.route_steps=steps;report.route_end=[p.x,p.y];report.route_total=paths.size();report.gpu="NOT_RUN"
 var invalid=[];battle.start()
 for i in 600:
  battle.input_state(Vector2.ZERO,Vector2.RIGHT);battle.step()
  if battle.result!="":break
 for u in battle.roster:
  if battle.active(u) and runtime.blocked(u.pos,true):invalid.append(u.id)
 report.battle_tick=battle.tick;report.hits=battle.hits;report.losses=battle.losses;report.active_invalid=invalid
 FileAccess.open(out+"/headless.json",FileAccess.WRITE).store_string(JSON.stringify(report,"  "));print("25D_HEADLESS ",JSON.stringify(report));quit(0 if reached==paths.size() and max_error<.001 and invalid.is_empty() else 3)
