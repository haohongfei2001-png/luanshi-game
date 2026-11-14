extends Node3D
## ONE-ACTOR authoring oracle for an isolated real-field visual experiment.
## No cameras, lights, ground, battle writes or production crowd integration.
## Complete source/master remains authoritative; all art/actions unaccepted.
var metadata:Dictionary={}
var mats:Array[ShaderMaterial]=[]
var payload_bytes:int=0
var _loaded:bool=false
var _body_markers:Array=[]
var _sample_frame:=0.0
var _frame_limit:=0
var marker_cpu_bytes:=0
func cache_texture(path:String)->ImageTexture:
 var bytes=FileAccess.get_file_as_bytes(path)
 var height=ceili(float(bytes.size())/(1024*16));bytes.resize(height*1024*16);payload_bytes+=bytes.size()
 return ImageTexture.create_from_image(Image.create_from_data(1024,height,false,Image.FORMAT_RGBAF,bytes))
func configure_author_oracle(folder:String)->Error:
 if _loaded:return ERR_ALREADY_IN_USE
 if folder.begins_with("res://"):return ERR_INVALID_PARAMETER
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
  if str(m.name).begins_with("Helmet") or str(m.name).begins_with("Young complete author face") or str(m.name).begins_with("GEO-boots"):
   _body_markers.append({"name":m.name,"positions":raw,"vertices":count});marker_cpu_bytes+=raw.size()
  var positions=PackedVector3Array();var normals=PackedVector3Array();var uv=PackedVector2Array()
  for i in count:
   positions.append(Vector3(raw.decode_float(i*16),raw.decode_float(i*16+4),raw.decode_float(i*16+8)))
   normals.append(Vector3(nr.decode_float(i*16),nr.decode_float(i*16+4),nr.decode_float(i*16+8)))
   uv.append(Vector2(m.uv[i][0],1.0-m.uv[i][1]))
  var pt=cache_texture(folder.path_join(m.positions));var nt=cache_texture(folder.path_join(m.normals));var mesh=ArrayMesh.new()
  for s in m.surfaces:
   var a=[];a.resize(Mesh.ARRAY_MAX);a[Mesh.ARRAY_VERTEX]=positions;a[Mesh.ARRAY_NORMAL]=normals;a[Mesh.ARRAY_TEX_UV]=uv;a[Mesh.ARRAY_INDEX]=PackedInt32Array(s.indices);mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,a)
   var mat=ShaderMaterial.new();mat.shader=load("res://scripts/field/experimental/controlled_author_cache.gdshader");mat.set_shader_parameter("position_cache",pt);mat.set_shader_parameter("normal_cache",nt);mat.set_shader_parameter("vertex_count",count);mat.set_shader_parameter("frame_limit",int(clip.first_frame+clip.frames-1));mat.set_shader_parameter("base_color",Color(s.color[0],s.color[1],s.color[2],s.color[3]).linear_to_srgb());mat.set_shader_parameter("roughness_value",s.roughness);mat.set_shader_parameter("metal_value",s.metallic);mat.set_shader_parameter("uses_alpha",s.alpha_texture)
   if s.has("texture"):
    # Cache is an external raw-data delivery, never an imported res:// PNG.
    var image=Image.new()
    var image_error=image.load_png_from_buffer(FileAccess.get_file_as_bytes(folder.path_join(s.texture)))
    if image_error!=OK:return image_error
    image.generate_mipmaps();mat.set_shader_parameter("diffuse_texture",ImageTexture.create_from_image(image));mat.set_shader_parameter("has_diffuse",true)
   mesh.surface_set_material(mesh.get_surface_count()-1,mat);mats.append(mat)
  var instance=MeshInstance3D.new();instance.name=m.name;instance.mesh=mesh;instance.custom_aabb=AABB(Vector3(-3,-1,-3),Vector3(6,5,6));add_child(instance)
 _loaded=true
 return OK
func apply_author_phase(clip_name:String,phase:float)->Error:
 if not _loaded or phase<0. or phase>1.:return ERR_INVALID_PARAMETER
 for clip in metadata.clips:
  if clip.name!=clip_name:continue
  _sample_frame=float(clip.first_frame)+phase*float(clip.frames-1)
  _frame_limit=int(clip.first_frame+clip.frames-1)
  for mat in mats:
   mat.set_shader_parameter("frame_limit",int(clip.first_frame+clip.frames-1))
   mat.set_shader_parameter("sample_frame",float(clip.first_frame)+phase*float(clip.frames-1))
  return OK
 return ERR_DOES_NOT_EXIST
func receipt()->Dictionary:
 return {"source_files":metadata.get("source_files",{}),"source_author_rigs":metadata.get("source_author_rigs",{}),"mesh_count":get_child_count(),"vertices":metadata.get("vertices",0),"triangles":metadata.get("triangles",0),"cache_bytes":payload_bytes,"diagnostic_body_marker_cpu_bytes":marker_cpu_bytes,"runtime_cpu_skeletons":0,"art_pass":false,"single_actor_author_oracle_not_army_runtime":true,"battle_state_written":false,"camera_or_lighting_changed":false,"actions_accepted":false}

func projected_current_body(camera:Camera3D)->Dictionary:
 # CPU mirrors exact cached-position interpolation. Geometry footprint, not pixel mask.
 var low:=Vector2(INF,INF);var high:=Vector2(-INF,-INF);var points:=0
 var a:=floori(_sample_frame);var b:=mini(a+1,_frame_limit);var weight:=fposmod(_sample_frame,1.0)
 for marker in _body_markers:
  var raw:PackedByteArray=marker.positions;var count:int=marker.vertices
  for i in count:
   var ia:=(a*count+i)*16;var ib:=(b*count+i)*16
   var pa:=Vector3(raw.decode_float(ia),raw.decode_float(ia+4),raw.decode_float(ia+8))
   var pb:=Vector3(raw.decode_float(ib),raw.decode_float(ib+4),raw.decode_float(ib+8))
   var world:=global_transform*pa.lerp(pb,weight)
   if camera.is_position_behind(world):return {"valid":false,"reason":"selected_body_vertex_behind_camera"}
   var screen:=camera.unproject_position(world);low=low.min(screen);high=high.max(screen);points+=1
 if points==0:return {"valid":false,"reason":"body_markers_missing"}
 var viewport:=camera.get_viewport();var logical:=viewport.get_visible_rect().size
 var native:=Vector2(viewport.get_texture().get_width(),viewport.get_texture().get_height())
 return {"valid":true,"scope":"current cached helmet/face/boots geometric projection, not visible silhouette; no weapon/shadow","sample_frame":_sample_frame,"vertices":points,"logical_viewport":[logical.x,logical.y],"native_attachment":[native.x,native.y],"logical_box":[low.x,low.y,high.x,high.y],"logical_height":high.y-low.y,"native_height":(high.y-low.y)*native.y/logical.y,"height_fraction":(high.y-low.y)/logical.y}
