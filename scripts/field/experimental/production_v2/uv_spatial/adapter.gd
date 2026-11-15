extends RefCounted
## Isolated default-OFF source18 material adapter. Does not touch mesh/skin/GLB.
const SOURCE_SHA:="afb966396bf5ad656b3cb0cd2edc388fc6fa02eba59df8b81d9a23ac53f3be8b"
const CONTRACT_SHA:="6e499e13a720acdebfab6bad834d2a79d5971a3f51735f7d2cd7ccba292d83c7"
const TARGETS:=["V2 continuous lamellar cuirass","V3 thin wrapped linen with physical overlap"]
const SHADER=preload("res://scripts/field/experimental/production_v2/uv_spatial/source18.gdshader")
var document:Dictionary={}
var descriptions:Dictionary={}
var materials:Dictionary={}
var configured:=false
var source_verification:=""
var default_material:=StandardMaterial3D.new()
func configure(glb_path:String)->Error:
 if configured:return ERR_ALREADY_IN_USE
 if FileAccess.get_sha256(glb_path)!=SOURCE_SHA:return ERR_INVALID_DATA
 var file=FileAccess.open(glb_path,FileAccess.READ)
 if file==null:return ERR_FILE_CANT_OPEN
 if file.get_32()!=0x46546c67 or file.get_32()!=2:return ERR_FILE_CORRUPT
 file.get_32();var count:=file.get_32()
 if count>4000000 or file.get_32()!=0x4e4f534a:return ERR_FILE_CORRUPT
 document=JSON.parse_string(file.get_buffer(count).get_string_from_utf8())
 source_verification='raw GLB SHA verified at runtime'
 return finish_configuration()
func configure_contract(contract_path:String)->Error:
 if configured:return ERR_ALREADY_IN_USE
 if FileAccess.get_sha256(contract_path)!=CONTRACT_SHA:return ERR_INVALID_DATA
 var contract=JSON.parse_string(FileAccess.get_file_as_string(contract_path))
 if contract.schema!='luanshi-source18-texture-uv-v1' or contract.source_glb_sha256!=SOURCE_SHA:return ERR_INVALID_DATA
 document=contract.document
 source_verification='locked sidecar SHA verified at runtime; original GLB SHA requires preparation/import provenance, not a runtime raw-GLB read'
 return finish_configuration()
func finish_configuration()->Error:
 for description in document.materials:
  if description.get('name','') in TARGETS:
   if not validate_description(description):return ERR_UNAVAILABLE
   descriptions[description.name]=description
 if descriptions.size()!=2:return ERR_INVALID_DATA
 configured=true;return OK
func validate_description(d:Dictionary)->bool:
 # Fail closed, do not silently drop opacity, culling, emissive, AO or extensions.
 var keys=['name','doubleSided','normalTexture','pbrMetallicRoughness','alphaMode']
 for key in d:
  if key not in keys:return false
 if d.get('alphaMode','OPAQUE')!='OPAQUE' or not d.get('doubleSided',false):return false
 var p:Dictionary=d.pbrMetallicRoughness
 for key in p:
  if key not in ['baseColorFactor','baseColorTexture','metallicFactor','roughnessFactor','metallicRoughnessTexture']:return false
 if float(p.get('baseColorFactor',[1,1,1,1])[3])!=1.:return false
 if not d.has('normalTexture'):return false
 for info in [p.get('baseColorTexture',{}),d.normalTexture,p.get('metallicRoughnessTexture',{})]:
  if info.is_empty():continue
  for key in info:
   if key not in ['index','texCoord','extensions','scale']:return false
  var transform:Dictionary=info.get('extensions',{}).get('KHR_texture_transform',{})
  for key in info.get('extensions',{}):
   if key!='KHR_texture_transform':return false
  for key in transform:
   if key not in ['scale','offset','rotation','texCoord']:return false
  if int(transform.get('texCoord',info.get('texCoord',0))) not in [0,1,2]:return false
  var sampler:Dictionary=document.samplers[document.textures[int(info.index)].get('sampler',0)]
  if int(sampler.get('wrapS',10497))!=10497 or int(sampler.get('wrapT',10497))!=10497 or int(sampler.get('magFilter',9729))!=9729 or int(sampler.get('minFilter',9987))!=9987:return false
 return true
static func transform_uv(info:Dictionary,uv0:Vector2,uv1:Vector2,uv2:Vector2)->Vector2:
 var tr:Dictionary=info.get('extensions',{}).get('KHR_texture_transform',{})
 var index:=int(tr.get('texCoord',info.get('texCoord',0)));var uv:Vector2=[uv0,uv1,uv2][index]
 var scale=tr.get('scale',[1.,1.]);var offset=tr.get('offset',[0.,0.])
 return (uv*Vector2(scale[0],scale[1])).rotated(float(tr.get('rotation',0.)))+Vector2(offset[0],offset[1])
func set_mapping(material:ShaderMaterial,prefix:String,info:Dictionary)->void:
 var tr:Dictionary=info.get('extensions',{}).get('KHR_texture_transform',{});var scale=tr.get('scale',[1.,1.]);var offset=tr.get('offset',[0.,0.])
 material.set_shader_parameter(prefix+'_coord',int(tr.get('texCoord',info.get('texCoord',0))))
 material.set_shader_parameter('normal_scale_uv' if prefix=='normal' else prefix+'_scale',Vector2(scale[0],scale[1]))
 material.set_shader_parameter(prefix+'_offset',Vector2(offset[0],offset[1]));material.set_shader_parameter(prefix+'_rotation',float(tr.get('rotation',0.)))
func material_for(original:StandardMaterial3D)->ShaderMaterial:
 var key=original.get_instance_id()
 if materials.has(key):return materials[key]
 var d:Dictionary=descriptions[original.resource_name];var p:Dictionary=d.pbrMetallicRoughness
 var material=ShaderMaterial.new();material.shader=SHADER;material.resource_name=original.resource_name+' / exact glTF UV WIP'
 var color=p.get('baseColorFactor',[1.,1.,1.,1.]);material.set_shader_parameter('base_factor',Vector4(color[0],color[1],color[2],color[3]))
 material.set_shader_parameter('metallic_factor',float(p.get('metallicFactor',1.)));material.set_shader_parameter('roughness_factor',float(p.get('roughnessFactor',1.)));material.set_shader_parameter('specular_factor',original.metallic_specular)
 material.set_shader_parameter('normal_scale',float(d.normalTexture.get('scale',1.)));material.set_shader_parameter('normal_texture',original.normal_texture);set_mapping(material,'normal',d.normalTexture)
 if p.has('baseColorTexture'):
  material.set_shader_parameter('has_base_texture',true);material.set_shader_parameter('base_texture',original.albedo_texture);set_mapping(material,'base',p.baseColorTexture)
 if p.has('metallicRoughnessTexture'):
  material.set_shader_parameter('has_orm_texture',true);material.set_shader_parameter('orm_texture',original.metallic_texture);set_mapping(material,'orm',p.metallicRoughnessTexture)
 materials[key]=material;return material
func apply(actor_root:Node,enabled:bool=false)->Dictionary:
 if not enabled:return {'applied':false,'reason':'default_OFF'}
 if not configured:return {'applied':false,'reason':'unconfigured'}
 var pending=[]
 for node in actor_root.find_children('*','MeshInstance3D',true,false):
  for surface in node.mesh.get_surface_count():
   var material=node.mesh.surface_get_material(surface)
   if material==null or material.resource_name not in TARGETS:continue
   if not material is StandardMaterial3D or node.material_override!=null or node.get_surface_override_material(surface)!=null:return {'applied':false,'reason':'preexisting_or_nonstandard_material_override'}
   if material.transparency!=BaseMaterial3D.TRANSPARENCY_DISABLED or material.cull_mode!=BaseMaterial3D.CULL_DISABLED or material.shading_mode!=BaseMaterial3D.SHADING_MODE_PER_PIXEL or material.next_pass!=null:return {'applied':false,'reason':'unsupported_imported_render_state'}
   for feature in BaseMaterial3D.FEATURE_MAX:
    if feature!=BaseMaterial3D.FEATURE_NORMAL_MAPPING and material.get_feature(feature):return {'applied':false,'reason':'unsupported_additional_material_feature','feature':feature}
   for flag in BaseMaterial3D.FLAG_MAX:
    if material.get_flag(flag)!=default_material.get_flag(flag):return {'applied':false,'reason':'unsupported_material_flag','flag':flag}
   if material.depth_draw_mode!=BaseMaterial3D.DEPTH_DRAW_OPAQUE_ONLY or material.blend_mode!=BaseMaterial3D.BLEND_MODE_MIX or material.diffuse_mode!=BaseMaterial3D.DIFFUSE_BURLEY or material.specular_mode!=BaseMaterial3D.SPECULAR_SCHLICK_GGX or material.distance_fade_mode!=BaseMaterial3D.DISTANCE_FADE_DISABLED:return {'applied':false,'reason':'unsupported_PBR_depth_blend_or_fade_mode'}
   if material.billboard_mode!=BaseMaterial3D.BILLBOARD_DISABLED or material.is_grow_enabled() or material.no_depth_test or material.render_priority!=0:return {'applied':false,'reason':'unsupported_billboard_depth_or_geometry_state'}
   if not material.normal_enabled or material.normal_texture==null or material.metallic_specular!=.5:return {'applied':false,'reason':'unexpected_normal_or_specular'}
   var arrays=node.mesh.surface_get_arrays(surface);var d:Dictionary=descriptions[material.resource_name];var coord=int(d.normalTexture.get('texCoord',0))
   if coord==1 and arrays[Mesh.ARRAY_TEX_UV2]==null:return {'applied':false,'reason':'UV2_missing'}
   if coord==2 and arrays[Mesh.ARRAY_CUSTOM0]==null:return {'applied':false,'reason':'CUSTOM0_missing'}
   var p:Dictionary=d.pbrMetallicRoughness
   if not is_equal_approx(material.metallic,float(p.get('metallicFactor',1.))) or not is_equal_approx(material.roughness,float(p.get('roughnessFactor',1.))) or not is_equal_approx(material.normal_scale,float(d.normalTexture.get('scale',1.))):return {'applied':false,'reason':'modified_PBR_factors'}
   if material.texture_filter!=BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS or not material.texture_repeat:return {'applied':false,'reason':'modified_sampler'}
   if p.has('baseColorTexture') and material.albedo_texture==null:return {'applied':false,'reason':'base_texture_missing'}
   if p.has('metallicRoughnessTexture') and (material.metallic_texture==null or material.roughness_texture!=material.metallic_texture):return {'applied':false,'reason':'ORM_not_shared_original'}
   pending.append([node,surface,material])
 if pending.size()!=18:return {'applied':false,'reason':'unexpected_surface_count','count':pending.size()}
 var prepared=[]
 for row in pending:prepared.append(material_for(row[2]))
 if SHADER.get_shader_uniform_list().size()<20:return {'applied':false,'reason':'shader_frontend_compile_or_uniform_validation_failed'}
 for index in pending.size():pending[index][0].set_surface_override_material(pending[index][1],prepared[index])
 return {'applied':true,'surfaces':pending.size(),'shared_material_variants':materials.size(),'source_sha256':SOURCE_SHA,'source_verification':source_verification,'scope':'UV-only material override; shader GPU/art NOT_ACCEPTED; geometry/skin/actions unchanged'}
func restore(actor_root:Node)->int:
 var restored:=0;var owned=materials.values()
 for node in actor_root.find_children('*','MeshInstance3D',true,false):
  for surface in node.mesh.get_surface_count():
   if node.get_surface_override_material(surface) in owned:
    node.set_surface_override_material(surface,null);restored+=1
 return restored
