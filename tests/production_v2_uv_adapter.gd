extends SceneTree
const Adapter=preload('res://scripts/field/experimental/production_v2/uv_spatial/adapter.gd')
const Actor=preload('res://scripts/field/experimental/production_v2/shared_skeletal_actor.gd')
const Binding=preload('res://scripts/field/experimental/production_v2/mh_spear_battle_binding.gd')
const Battle=preload('res://scripts/field/battle.gd')
func ground(p:Vector2)->Vector3:return Vector3(p.x,0,p.y)
func _initialize():run.call_deferred()
func run():
 var args=OS.get_cmdline_user_args();assert(args.size()==5)
 var adapter=Adapter.new();assert(adapter.configure_contract(args[3])==OK)
 var raw_adapter=Adapter.new();assert(raw_adapter.configure(args[0])==OK);assert(raw_adapter.descriptions==adapter.descriptions)
 var bad=adapter.descriptions[Adapter.TARGETS[0]].duplicate(true);bad.alphaMode='BLEND';assert(not adapter.validate_description(bad));bad=adapter.descriptions[Adapter.TARGETS[0]].duplicate(true);bad.emissiveFactor=[1,0,0];assert(not adapter.validate_description(bad))
 var packed=load(args[0]);var b=Battle.new();b.setup(20,61112,Battle.Arms.Kit.SPEAR,true,true,20,false);b.start()
 var units=[]
 for u in b.roster:
  if u.kit==Battle.Arms.Kit.SPEAR and not u.mounted:units.append(u)
  if units.size()==11:break
 assert(units.size()==11)
 var actors=[];var bindings=[];var original_materials=[];var timing=JSON.parse_string(FileAccess.get_file_as_string(args[1]))
 for u in units:
  var actor=Actor.new();root.add_child(actor);assert(actor.setup(packed)==OK);assert(not adapter.apply(actor).applied)
  var list=[]
  for mesh in actor.model.find_children('*','MeshInstance3D',true,false):
   for s in mesh.mesh.get_surface_count():list.append([mesh,s,mesh.mesh.surface_get_material(s)])
  var receipt=adapter.apply(actor,true);assert(receipt.applied,JSON.stringify(receipt));assert(receipt.surfaces==18)
  for row in list:
   assert(row[0].mesh.surface_get_material(row[1])==row[2],'Mutated shared Mesh material')
   var actual=row[0].get_active_material(row[1])
   if row[2].resource_name in Adapter.TARGETS:
    assert(actual is ShaderMaterial);assert(actual.get_shader_parameter('normal_texture')==row[2].normal_texture)
   else:assert(actual==row[2],'Touched unrelated material')
  var binding=Binding.new();binding.enabled=true;binding.ground_point=ground;assert(binding.configure_timing(timing,Adapter.SOURCE_SHA)==OK)
  actors.append(actor);bindings.append(binding);original_materials.append(list)
 assert(adapter.materials.size()==2,'Expected two shared ShaderMaterial variants, not per-unit copies')
 for tick in 80:
  b.step();var state=[]
  for u in units:state.append([u.id,u.hp,u.pos,u.state])
  for i in actors.size():
   bindings[i].update_unit(b,units[i],actors[i],.05,1.)
   for bone in actors[i].skeleton.get_bone_count():assert(actors[i].skeleton.get_bone_global_pose(bone).is_finite())
  var after=[]
  for u in units:after.append([u.id,u.hp,u.pos,u.state])
  assert(state==after,'Material/actor binding mutated actual Unit state')
 var imported=JSON.parse_string(FileAccess.get_file_as_string(args[2]));var parity=[]
 for surface in imported.surfaces:
  var d:Dictionary=adapter.descriptions[surface.material];var p:Dictionary=d.pbrMetallicRoughness;var channels={'normal':d.normalTexture}
  if p.has('baseColorTexture'):channels.base=p.baseColorTexture
  if p.has('metallicRoughnessTexture'):channels.ORM=p.metallicRoughnessTexture
  for s in surface.samples:
   var uv0=Vector2(s.uv0[0],s.uv0[1]);var uv1=Vector2(s.uv1[0],s.uv1[1]);var uv2=Vector2(s.custom0_xy[0],s.custom0_xy[1]) if s.custom0_xy!=null else Vector2.ZERO;var values={}
   for key in channels:
    var uv=Adapter.transform_uv(channels[key],uv0,uv1,uv2);values[key]=[uv.x,uv.y]
   parity.append({'node':surface.node,'index':s.index,'corrected_uv':values})
 var shader_materials=[]
 for material in adapter.materials.values():
  var v:Vector4=material.get_shader_parameter('base_factor')
  shader_materials.append({'name':material.resource_name,'base_factor_linear':[v.x,v.y,v.z,v.w],'metallic_factor':material.get_shader_parameter('metallic_factor'),'roughness_factor':material.get_shader_parameter('roughness_factor'),'normal_scale':material.get_shader_parameter('normal_scale'),'normal_coord':material.get_shader_parameter('normal_coord'),'base_coord':material.get_shader_parameter('base_coord'),'orm_coord':material.get_shader_parameter('orm_coord')})
 var report={'shader_materials':shader_materials,'source_sha256':Adapter.SOURCE_SHA,'actual_units':units.map(func(u):return {'id':u.id,'hero':u.hero,'kit':u.kit,'hp':u.hp,'state':u.state}),'actual_battle_tick':b.tick,'actors':actors.size(),'adapted_surfaces':18*actors.size(),'shared_materials':adapter.materials.size(),'source_meshes_and_textures_unchanged':true,'binding_state_mutation':false,'shader_uniforms_in_headless':Adapter.SHADER.get_shader_uniform_list().size(),'scope':'headless resource and CPU UV parity, not shader GPU execution or art acceptance','parity_samples':parity}
 var restored=0
 for actor in actors:restored+=adapter.restore(actor)
 assert(restored==198)
 for list in original_materials:
  for row in list:assert(row[0].get_active_material(row[1])==row[2],'Restore altered original material')
 report['restored_original_surfaces']=restored
 FileAccess.open(args[4],FileAccess.WRITE).store_string(JSON.stringify(report,'  '));print('UV_ADAPTER_11_REAL_BINDINGS_HEADLESS_PASS shared_materials=',adapter.materials.size(),' uniforms=',report.shader_uniforms_in_headless)
 for actor in actors:actor.free()
 quit()
