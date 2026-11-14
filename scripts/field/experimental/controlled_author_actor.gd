extends Node3D
## ONE-ACTOR authoring oracle for an isolated real-field visual experiment.
## No cameras, lights, ground, battle writes or production crowd integration.
## Complete source/master remains authoritative; all art/actions unaccepted.
var metadata:Dictionary={}
var mats:Array[ShaderMaterial]=[]
var payload_bytes:int=0
var _loaded:bool=false
func cache_texture(path:String)->ImageTexture:
 var bytes=FileAccess.get_file_as_bytes(path)
 var height=ceili(float(bytes.size())/(1024*16));bytes.resize(height*1024*16);payload_bytes+=bytes.size()
 return ImageTexture.create_from_image(Image.create_from_data(1024,height,false,Image.FORMAT_RGBAF,bytes))
func configure_author_oracle(folder:String)->Error:
 if _loaded:return ERR_ALREADY_IN_USE
 var path=folder.path_join("character.json")
 if not FileAccess.file_exists(path):return ERR_FILE_NOT_FOUND
 var parsed=JSON.parse_string(FileAccess.get_file_as_string(path))
 if not parsed is Dictionary:return ERR_PARSE_ERROR
 metadata=parsed
 if metadata.get("art_pass",true) or metadata.get("default_enabled",true):return ERR_INVALID_DATA
 var meta=metadata
 var clip:Dictionary=meta.clips[0]
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
   var mat=ShaderMaterial.new();mat.shader=load("res://tools/art/soldier_controlled_probe/cache.gdshader");mat.set_shader_parameter("position_cache",pt);mat.set_shader_parameter("normal_cache",nt);mat.set_shader_parameter("vertex_count",count);mat.set_shader_parameter("frame_limit",int(clip.first_frame+clip.frames-1));mat.set_shader_parameter("base_color",Color(s.color[0],s.color[1],s.color[2],s.color[3]).linear_to_srgb());mat.set_shader_parameter("roughness_value",s.roughness);mat.set_shader_parameter("metal_value",s.metallic);mat.set_shader_parameter("uses_alpha",s.alpha_texture)
   if s.has("texture"):
    var image=Image.load_from_file(folder.path_join(s.texture));image.generate_mipmaps();mat.set_shader_parameter("diffuse_texture",ImageTexture.create_from_image(image));mat.set_shader_parameter("has_diffuse",true)
   mesh.surface_set_material(mesh.get_surface_count()-1,mat);mats.append(mat)
  var instance=MeshInstance3D.new();instance.name=m.name;instance.mesh=mesh;instance.custom_aabb=AABB(Vector3(-3,-1,-3),Vector3(6,5,6));add_child(instance)
 _loaded=true
 return OK
func apply_author_phase(clip_name:String,phase:float)->Error:
 if not _loaded or phase<0. or phase>1.:return ERR_INVALID_PARAMETER
 for clip in metadata.clips:
  if clip.name!=clip_name:continue
  for mat in mats:
   mat.set_shader_parameter("frame_limit",int(clip.first_frame+clip.frames-1))
   mat.set_shader_parameter("sample_frame",float(clip.first_frame)+phase*float(clip.frames-1))
  return OK
 return ERR_DOES_NOT_EXIST
func receipt()->Dictionary:
 return {"source_files":metadata.get("source_files",{}),"source_author_rigs":metadata.get("source_author_rigs",{}),"mesh_count":get_child_count(),"vertices":metadata.get("vertices",0),"triangles":metadata.get("triangles",0),"cache_bytes":payload_bytes,"runtime_cpu_skeletons":0,"art_pass":false,"single_actor_author_oracle_not_army_runtime":true,"battle_state_written":false,"camera_or_lighting_changed":false,"actions_accepted":false}
