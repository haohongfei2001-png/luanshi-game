extends Node3D
var meta:Dictionary
var mats:Array[ShaderMaterial]=[]
var actor_nodes:Array[MeshInstance3D]=[]
var clip:Dictionary
var start:int
var output:String
var captures:Array=[]
var payload_bytes:int=0
var capturing:bool=false
var camera_record:Dictionary={}
func cache_texture(path:String)->ImageTexture:
 var bytes=FileAccess.get_file_as_bytes(path)
 var height=ceili(float(bytes.size())/(1024*16));bytes.resize(height*1024*16);payload_bytes+=bytes.size()
 return ImageTexture.create_from_image(Image.create_from_data(1024,height,false,Image.FORMAT_RGBAF,bytes))
func _ready():
 var folder=OS.get_environment("SOLDIER_CACHE");output=OS.get_environment("SOLDIER_OUTPUT")
 if output.is_empty():output="user://oracle"
 DirAccess.make_dir_recursive_absolute(output)
 meta=JSON.parse_string(FileAccess.get_file_as_string(folder.path_join("character.json")))
 var clip_name=OS.get_environment("SOLDIER_CLIP")
 if clip_name.is_empty():clip_name="walk"
 for c in meta.clips:
  if c.name==clip_name:clip=c
 assert(not clip.is_empty())
 for m in meta.meshes:
  var raw=FileAccess.get_file_as_bytes(folder.path_join(m.positions));var nr=FileAccess.get_file_as_bytes(folder.path_join(m.normals));var count:int=int(m.vertices)
  var positions=PackedVector3Array();var normals=PackedVector3Array();var uv=PackedVector2Array()
  for i in count:
   positions.append(Vector3(raw.decode_float(i*16),raw.decode_float(i*16+4),raw.decode_float(i*16+8)))
   normals.append(Vector3(nr.decode_float(i*16),nr.decode_float(i*16+4),nr.decode_float(i*16+8)))
   uv.append(Vector2(m.uv[i][0],1.0-m.uv[i][1]))
  var pt=cache_texture(folder.path_join(m.positions));var nt=cache_texture(folder.path_join(m.normals));var mesh=ArrayMesh.new()
  for s in m.surfaces:
   var a=[];a.resize(Mesh.ARRAY_MAX);a[Mesh.ARRAY_VERTEX]=positions;a[Mesh.ARRAY_NORMAL]=normals;a[Mesh.ARRAY_TEX_UV]=uv;a[Mesh.ARRAY_INDEX]=PackedInt32Array(s.indices);mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,a)
   var mat=ShaderMaterial.new();mat.shader=load("res://cache.gdshader");mat.set_shader_parameter("position_cache",pt);mat.set_shader_parameter("normal_cache",nt);mat.set_shader_parameter("vertex_count",count);mat.set_shader_parameter("frame_limit",int(clip.first_frame+clip.frames-1));mat.set_shader_parameter("base_color",Color(s.color[0],s.color[1],s.color[2],s.color[3]).linear_to_srgb());mat.set_shader_parameter("roughness_value",s.roughness);mat.set_shader_parameter("metal_value",s.metallic);mat.set_shader_parameter("uses_alpha",s.alpha_texture)
   if s.has("texture"):
    var image=Image.load_from_file(folder.path_join(s.texture));image.generate_mipmaps();mat.set_shader_parameter("diffuse_texture",ImageTexture.create_from_image(image));mat.set_shader_parameter("has_diffuse",true)
   mesh.surface_set_material(mesh.get_surface_count()-1,mat);mats.append(mat)
  var instance=MeshInstance3D.new();instance.name=m.name;instance.mesh=mesh;instance.custom_aabb=AABB(Vector3(-3,-1,-3),Vector3(6,5,6));add_child(instance);actor_nodes.append(instance)
 var camera=Camera3D.new();add_child(camera);camera.current=true
 if OS.get_environment("SOLDIER_CAMERA")=="near":
  camera.position=Vector3(2.5,2.0,4.0);camera.look_at(Vector3(0,1.1,0));camera.fov=50
  camera_record={"projection":"perspective","fov":50.,"position":[2.5,2.,4.],"target":[0,1.1,0],"official_game_camera":false}
 else:
  # Exact latest internal review profile, not an official Wild Rift constant.
  var pitch=deg_to_rad(32.0);var yaw=deg_to_rad(-65.0);var fraction=.10
  var body_depth=.55*absf(sin(yaw))+.35*absf(cos(yaw))
  var body_span=1.8*cos(pitch)+body_depth*sin(pitch)
  camera.projection=Camera3D.PROJECTION_PERSPECTIVE;camera.fov=55.
  var distance=body_span/(2.*tan(deg_to_rad(camera.fov)*.5)*fraction)
  var target=Vector3(4.,.8,0.)
  camera.position=target+Vector3(sin(yaw)*cos(pitch),sin(pitch),cos(yaw)*cos(pitch))*distance;camera.look_at(target);camera.near=.1;camera.far=400.
  camera_record={"projection":"perspective","fov":55.,"pitch_degrees":32.,"yaw_degrees":-65.,"nominal_adult_box_fraction":.10,"target":[4.,.8,0.],"distance":distance,"reference_commit":"9c214ca46836dbd8f22eb75e25f12fdeecda98d4","official_game_camera":false}
 camera_record["transform"]=str(camera.transform)

 var env=WorldEnvironment.new();env.environment=Environment.new();env.environment.background_mode=Environment.BG_COLOR;env.environment.background_color=Color(0.12,0.13,0.12);env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.environment.ambient_light_color=Color(0.75,0.8,0.8);env.environment.ambient_light_energy=.55;add_child(env)
 var sun=DirectionalLight3D.new();sun.rotation_degrees=Vector3(-48,58,0);sun.light_color=Color("fff1d7");sun.light_energy=1.;sun.shadow_enabled=true;add_child(sun)
 var floor_mesh=MeshInstance3D.new();var plane=PlaneMesh.new();plane.size=Vector2(40,40);floor_mesh.mesh=plane;var floor_mat=StandardMaterial3D.new();floor_mat.albedo_color=Color(0.34,0.32,0.26);floor_mat.roughness=.9;floor_mesh.material_override=floor_mat;floor_mesh.position.y=-.015;add_child(floor_mesh)
 start=Time.get_ticks_usec();print("ACTUAL_CONTROLLED_ACTOR_READY vertices=",meta.vertices," triangles=",meta.triangles," cache_bytes=",payload_bytes," clip=",clip.name)
func _process(_dt):
 if start==0 or capturing:return
 var elapsed=float(Time.get_ticks_usec()-start)/1e6
 if OS.get_environment("SOLDIER_TURN")=="1":
  for actor_node in actor_nodes:actor_node.rotation.y=elapsed*PI*.5
 var phase=fmod(elapsed,float(clip.duration_seconds))/float(clip.duration_seconds)
 if not OS.get_environment("SOLDIER_PHASE").is_empty():phase=float(OS.get_environment("SOLDIER_PHASE"))
 var frame=float(clip.first_frame)+phase*float(clip.frames-1)
 for mat in mats:mat.set_shader_parameter("sample_frame",frame)
 if elapsed>1.5 and (OS.get_environment("SOLDIER_RECORD")!="1" or elapsed>4.0):
  set_process(false)
  if DisplayServer.get_name()!="headless":
   await RenderingServer.frame_post_draw
   get_viewport().get_texture().get_image().save_png(output.path_join("actual-godot.png"))
  var size=get_viewport().get_visible_rect().size
  var report={"root_yaw_diagnostic_not_turn_clip":OS.get_environment("SOLDIER_TURN")=="1","hit_braced_not_full_source_arm_equivalence":clip.name=="hit_braced","engine":"Godot4.6.3 actual graphical run only when display is not headless","display":DisplayServer.get_name(),"source_files":meta.source_files,"source_limitations":meta.limitations,"capture_overhead_not_performance_benchmark":true,"clip":clip,"actual_viewport":[size.x,size.y],"render_scale":get_viewport().scaling_3d_scale,"camera":OS.get_environment("SOLDIER_CAMERA"),"camera_profile":camera_record,"cache_bytes":payload_bytes,"vertices":meta.vertices,"triangles":meta.triangles,"source_author_rigs":meta.source_author_rigs,"base_color_semantics":"Blender linear BSDF encoded to sRGB for source_color uniform; image textures unchanged","runtime_cpu_skeletons":0,"single_actor_cache_not_army_architecture":true,"frames":captures,"art_pass":false,"gpu":RenderingServer.get_video_adapter_name()}
  FileAccess.open(output.path_join("report.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"  "));get_tree().quit()
 elif OS.get_environment("SOLDIER_RECORD")=="1" and DisplayServer.get_name()!="headless":
  capturing=true;await RenderingServer.frame_post_draw
  var pts=Time.get_ticks_usec();var name="frame-%05d.png"%captures.size();get_viewport().get_texture().get_image().save_png(output.path_join(name));captures.append({"elapsed_seconds":elapsed,"rendered_monotonic_usec":pts,"source_frame":frame,"image":name});capturing=false
