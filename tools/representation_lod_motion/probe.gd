extends SceneTree
## Full source vs index-only LOD2, same complete palette shader. Technical control.
const Palette=preload("res://scripts/field/experimental/native_rig_palette.gd")
const Adapter=preload("res://scripts/field/experimental/native_rig_material.gd")
const Lod=preload("res://tools/representation_compare/explicit_lod.gd")
var views:Array=[]
var entries:Array=[]
var obstacles:Array=[]
var folder:String
func _initialize()->void:run.call_deferred()
func fail(message:String)->void:push_error(message);quit(1)
func make_view()->SubViewport:
 var v=SubViewport.new();v.size=Vector2i(2560,1440);v.own_world_3d=true;v.msaa_3d=Viewport.MSAA_4X;v.mesh_lod_threshold=0.;root.add_child(v)
 var env=WorldEnvironment.new();env.environment=Environment.new();env.environment.background_mode=Environment.BG_COLOR;env.environment.background_color=Color(.055,.065,.075);env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.environment.ambient_light_color=Color.WHITE;env.environment.ambient_light_energy=.4;env.environment.tonemap_mode=Environment.TONE_MAPPER_FILMIC;v.add_child(env)
 var sun=DirectionalLight3D.new();sun.rotation_degrees=Vector3(-35,-25,0);sun.light_energy=.91;sun.shadow_enabled=true;v.add_child(sun)
 var c=Camera3D.new();c.fov=55.;v.add_child(c)
 var yaw=deg_to_rad(-65.);var pitch=deg_to_rad(32.);var span=1.8*cos(pitch)+(.55*abs(sin(yaw))+.35*abs(cos(yaw)))*sin(pitch);var distance=span/(2.*tan(deg_to_rad(55.)/2.)*.10)
 var target=Vector3(4,.8,0);c.position=target+Vector3(sin(yaw)*cos(pitch),sin(pitch),cos(yaw)*cos(pitch))*distance;c.look_at(target);c.current=true
 var wall=MeshInstance3D.new();var box=BoxMesh.new();box.size=Vector3(2.4,.9,.12);wall.mesh=box;wall.position=Vector3(-.45,.45,.22);wall.rotation.y=yaw;var m=StandardMaterial3D.new();m.albedo_color=Color(.24,.27,.23);m.roughness=1.;wall.material_override=m;wall.visible=false;v.add_child(wall);obstacles.append(wall)
 return v
func run()->void:
 if DisplayServer.get_name()=="headless":fail("Actual graphics required");return
 folder=OS.get_environment("LOD_MOTION_OUTPUT");if folder.is_empty():folder="user://lod-motion"
 DirAccess.make_dir_recursive_absolute(folder)
 views=[make_view(),make_view()]
 var source=load("res://assets/ubc_lab/ubc_animated.glb").instantiate();root.add_child(source);source.visible=false
 var sk:Skeleton3D=source.find_children("*","Skeleton3D",true,false)[0];var player:AnimationPlayer=source.find_children("*","AnimationPlayer",true,false)[0];player.callback_mode_process=AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
 var inventory=[]
 for native:MeshInstance3D in source.find_children("*","MeshInstance3D",true,false):
  var pack=Palette.pack_textured_mesh(native.mesh,native.skin.get_bind_count());if pack.has("error"):fail(str(pack));return
  var shaders=[]
  for s in native.mesh.get_surface_count():
   var adapted=Adapter.adapt(native.get_active_material(s));if adapted.has("error"):fail(str(adapted));return
   var material:ShaderMaterial=adapted.material;material.set_shader_parameter("influence_table",ImageTexture.create_from_image(pack.tables[s].image));material.set_shader_parameter("influence_groups",pack.tables[s].groups);pack.mesh.surface_set_material(s,material);shaders.append(material)
  var reduced=Lod.select(pack.mesh,2);if reduced.has("error"):fail(str(reduced));return
  inventory.append({"mesh":native.name,"lod":reduced.inventory})
  for index in 2:
   var batch=MultiMeshInstance3D.new();var mm=MultiMesh.new();mm.transform_format=MultiMesh.TRANSFORM_3D;mm.use_colors=true;mm.use_custom_data=true;mm.mesh=pack.mesh if index==0 else reduced.mesh;mm.instance_count=1;mm.set_instance_transform(0,native.global_transform);mm.set_instance_color(0,Color.WHITE);mm.set_instance_custom_data(0,Color(0,0,0,0));mm.custom_aabb=AABB(Vector3(-4,-4,-4),Vector3(8,8,8));batch.multimesh=mm;views[index].add_child(batch)
  entries.append({"native":native,"shaders":shaders})
 var rows=[]
 var clips=player.get_animation_list();clips.sort()
 for clip in clips:
  if clip=="RESET":continue
  for phase in [.13,.47,.83]:
   player.play(clip);player.seek(player.get_animation(clip).length*phase,true);player.advance(0.);sk.force_update_all_bone_transforms()
   for entry in entries:
    var pose=Palette.capture(sk,entry.native.skin);if pose.has("error"):fail(str(pose));return
    var bank=Palette.encode([pose.transforms]);if bank.has("error"):fail(str(bank));return
    var texture=ImageTexture.create_from_image(bank.image)
    for shader in entry.shaders:shader.set_shader_parameter("palette",texture)
   var modes=["clear","wall","cutout"] if clip in ["Walk","Death01"] else ["clear"]
   for mode in modes:
    for obstacle in obstacles:
     obstacle.visible=mode!="clear"
     if mode=="cutout":
      var cut=ShaderMaterial.new();cut.shader=Shader.new();cut.shader.code="shader_type spatial; void fragment(){ ALBEDO=vec3(.24,.27,.23); ROUGHNESS=1.; ALPHA=step(.45,fract(UV.x*8.))*step(.2,fract(UV.y*4.)); ALPHA_SCISSOR_THRESHOLD=.5; }";obstacle.material_override=cut
     else:
      var solid=StandardMaterial3D.new();solid.albedo_color=Color(.24,.27,.23);solid.roughness=1.;obstacle.material_override=solid
    for frame in 3:await process_frame
    await RenderingServer.frame_post_draw
    var label=clip+"-"+str(int(round(phase*100)))+"-"+mode
    for index in 2:
     var result=views[index].get_texture().get_image().save_png(folder+"/"+label+("-full.png" if index==0 else "-lod2.png"))
     if result!=OK:fail("PNG save failed "+str(result));return
    rows.append({"clip":clip,"phase":phase,"mode":mode,"prefix":label});print("LOD_MOTION_CAPTURE ",label)
 var report={"engine":Engine.get_version_info(),"renderer":RenderingServer.get_video_adapter_name(),"driver":RenderingServer.get_current_rendering_driver_name(),"resolution":[2560,1440],"internal":1.,"camera":{"yaw":-65,"pitch":32,"fov":55,"nominal_body_fraction":.10,"target":[4,.8,0]},"source_sha256":FileAccess.get_sha256("res://assets/ubc_lab/ubc_animated.glb"),"inventory":inventory,"rows":rows,"all_original_weights":true,"full_source_materials":true,"art_pass":false,"performance":"NOT_MEASURED","M5":"NOT_TESTED","scope":"UBC unarmored, no held weapon. Original 9 authored clips sampled at non-keyframe phases, not full-cycle motion acceptance. Opaque wall and procedural alpha-scissor cutout only; no real foliage or blend transparency acceptance."}
 var f=FileAccess.open(folder+"/report.json",FileAccess.WRITE);if f==null:fail("report write failed");return
 f.store_string(JSON.stringify(report,"  "));f.close();quit(0)
