extends Node3D
var materials:Array[ShaderMaterial]=[]
var meta:Dictionary
var skeleton:Skeleton3D
var start:int
var frames:Array=[]
var duration:float=3.0
var out:String
var bytes_uploaded:int=0
var vertices:int=0
var triangles:int=0
var distance:float=22.0
var capturing:bool=false
func transform(values:Array)->Transform3D:
 return Transform3D(Basis(Vector3(values[0],values[1],values[2]),Vector3(values[3],values[4],values[5]),Vector3(values[6],values[7],values[8])),Vector3(values[9],values[10],values[11]))
func texture(path:String)->ImageTexture:
 var data=FileAccess.get_file_as_bytes(path)
 var height:int=int(ceil(float(data.size())/(1024*16)))
 data.resize(height*1024*16)
 bytes_uploaded+=data.size()
 return ImageTexture.create_from_image(Image.create_from_data(1024,height,false,Image.FORMAT_RGBAF,data))
func _ready():
 var source=OS.get_environment("GUARDIAN_CACHE")
 out=OS.get_environment("GUARDIAN_OUTPUT")
 if out.is_empty():out="user://capture"
 DirAccess.make_dir_recursive_absolute(out)
 if not OS.get_environment("GUARDIAN_DISTANCE").is_empty():distance=float(OS.get_environment("GUARDIAN_DISTANCE"))
 if not OS.get_environment("GUARDIAN_DURATION").is_empty():duration=float(OS.get_environment("GUARDIAN_DURATION"))
 meta=JSON.parse_string(FileAccess.get_file_as_string(source.path_join("character.json")))
 assert(meta.source_rig_bones==308 and meta.source_unchanged)
 skeleton=Skeleton3D.new();add_child(skeleton)
 for b in meta.bones:skeleton.add_bone(b.name)
 for i in meta.bones.size():
  var b=meta.bones[i];var parent:int=int(b.parent);skeleton.set_bone_parent(i,parent)
  var rest=transform(b.rest_global)
  if parent>=0:rest=transform(meta.bones[parent].rest_global).affine_inverse()*rest
  skeleton.set_bone_rest(i,rest)
 for m in meta.meshes:
  var count:int=int(m.vertices);var raw=FileAccess.get_file_as_bytes(source.path_join(m.positions_file));var normalraw=FileAccess.get_file_as_bytes(source.path_join(m.normals_file))
  var points=PackedVector3Array();var normals=PackedVector3Array();var uv=PackedVector2Array()
  for i in count:
   points.append(Vector3(raw.decode_float(i*16),raw.decode_float(i*16+4),raw.decode_float(i*16+8)))
   normals.append(Vector3(normalraw.decode_float(i*16),normalraw.decode_float(i*16+4),normalraw.decode_float(i*16+8)))
   uv.append(Vector2(m.uv[i][0],1.0-m.uv[i][1]))
  var arrays=[];arrays.resize(Mesh.ARRAY_MAX);arrays[Mesh.ARRAY_VERTEX]=points;arrays[Mesh.ARRAY_NORMAL]=normals;arrays[Mesh.ARRAY_TEX_UV]=uv;arrays[Mesh.ARRAY_INDEX]=PackedInt32Array(m.indices)
  var mesh=ArrayMesh.new();mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
  var mat=ShaderMaterial.new();mat.shader=load("res://cache.gdshader");mat.set_shader_parameter("position_cache",texture(source.path_join(m.positions_file)));mat.set_shader_parameter("normal_cache",texture(source.path_join(m.normals_file)));mat.set_shader_parameter("vertex_count",count);materials.append(mat)
  var instance=MeshInstance3D.new();instance.name=m.name;instance.mesh=mesh;instance.material_override=mat;instance.custom_aabb=AABB(Vector3(-3,-1,-3),Vector3(6,5,6));add_child(instance)
  vertices+=count;triangles+=int(m.indices.size()/3)
 var light=DirectionalLight3D.new();light.rotation_degrees=Vector3(-45,-30,0);light.light_energy=1.8;add_child(light)
 var environment=WorldEnvironment.new();environment.environment=Environment.new();environment.environment.background_mode=Environment.BG_COLOR;environment.environment.background_color=Color(.055,.055,.055);environment.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;environment.environment.ambient_light_color=Color(.6,.6,.6);environment.environment.ambient_light_energy=.6;add_child(environment)
 var camera=Camera3D.new();add_child(camera);camera.position=Vector3(2,0.5,3).normalized()*distance+Vector3(0,1,0);camera.look_at(Vector3(0,1,0));camera.fov=35;camera.current=true
 var ground=MeshInstance3D.new();var plane=PlaneMesh.new();plane.size=Vector2(8,8);ground.mesh=plane;add_child(ground)
 start=Time.get_ticks_usec()
 print("GUARDIAN_CACHE_READY bones=",skeleton.get_bone_count()," meshes=",materials.size()," vertices=",vertices," triangles=",triangles," cache_texture_payload_bytes=",bytes_uploaded)
func _process(_delta):
 if start==0 or capturing:return
 var elapsed=(Time.get_ticks_usec()-start)/1000000.0
 var frame=fmod(elapsed,2.0)*24.0
 if not OS.get_environment("GUARDIAN_POSE_FRAME").is_empty():frame=float(OS.get_environment("GUARDIAN_POSE_FRAME"))
 for mat in materials:mat.set_shader_parameter("sample_frame",frame)
 # Complete original named bone interface follows the same source pose cache.
 var a:int=int(floor(frame));var b:int=min(a+1,48);var globals:Array[Transform3D]=[]
 for i in meta.bones.size():globals.append(transform(meta.poses[a][i]).interpolate_with(transform(meta.poses[b][i]),fmod(frame,1.0)))
 for i in meta.bones.size():
  var local=globals[i];var parent:int=int(meta.bones[i].parent)
  if parent>=0:local=globals[parent].affine_inverse()*local
  var pose=skeleton.get_bone_rest(i).affine_inverse()*local
  skeleton.set_bone_pose_position(i,pose.origin);skeleton.set_bone_pose_rotation(i,pose.basis.get_rotation_quaternion());skeleton.set_bone_pose_scale(i,pose.basis.get_scale())
 var record={"monotonic_usec":Time.get_ticks_usec(),"elapsed_seconds":elapsed,"source_frame":frame}
 frames.append(record)
 if OS.get_environment("GUARDIAN_RECORD")=="1" and DisplayServer.get_name()!="headless":
  capturing=true
  await RenderingServer.frame_post_draw
  record["rendered_monotonic_usec"]=Time.get_ticks_usec()
  record["image"]="frame-%06d.png"%frames.size()
  get_viewport().get_texture().get_image().save_png(out.path_join(record.image))
  capturing=false
 if elapsed>=duration:
  set_process(false)
  var report={"kind":"actual Godot source-cache diagnostic; not combat/general skinning","display":DisplayServer.get_name(),"bones":skeleton.get_bone_count(),"meshes":materials.size(),"vertices":vertices,"triangles":triangles,"cache_texture_payload_bytes":bytes_uploaded,"cache_created_once":true,"gpu_allocation_measured":false,"cpu_vertex_upload_per_frame_bytes":0,"frames":frames,"viewport":str(get_viewport().get_visible_rect().size),"render_scale":get_viewport().scaling_3d_scale,"camera_distance_m":distance,"art_pass":false}
  if DisplayServer.get_name()!="headless":
   await RenderingServer.frame_post_draw
   get_viewport().get_texture().get_image().save_png(out.path_join("actual-godot.png"))
  FileAccess.open(out.path_join("report.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
  get_tree().quit()
