extends SceneTree
func _init() -> void:
 var path:=OS.get_environment('LUANSHI_GATE_CONTRACT_GLB')
 if path.is_empty():push_error('Explicit candidate GLB required');quit(1);return
 var doc:=GLTFDocument.new();var state:=GLTFState.new()
 if doc.append_from_file(path,state)!=OK:push_error('Candidate GLB import failed');quit(1);return
 # Check the actual glTF declaration as well as Godot's resulting material.
 # Godot ignoring texCoord=1 must be rejected, not mistaken for a good UV0 map.
 for material in state.json.get('materials',[]):
  if material.get('name','') not in ['timber','timber_cut','masonry']:continue
  var pbr:Dictionary=material.get('pbrMetallicRoughness',{})
  for texture in [material.get('occlusionTexture',{}),material.get('normalTexture',{}),pbr.get('baseColorTexture',{}),pbr.get('metallicRoughnessTexture',{})]:
   if not texture.has('index') or int(texture.get('texCoord',0))!=0:
    push_error('PBR texture declaration not supported primary UV: '+str(material.get('name')));quit(1);return
 var scene=doc.generate_scene(state)
 if scene==null:push_error('Candidate scene missing');quit(1);return
 var materials={};var pending=[scene]
 while not pending.is_empty():
  var node=pending.pop_back()
  pending.append_array(node.get_children())
  if node is MeshInstance3D:
   for i in node.mesh.get_surface_count():
    var material=node.mesh.surface_get_material(i)
    if material is StandardMaterial3D and material.resource_name in ['timber','timber_cut','masonry']:
     var arrays=node.mesh.surface_get_arrays(i)
     if arrays[Mesh.ARRAY_TEX_UV].is_empty() or arrays[Mesh.ARRAY_TEX_UV2].is_empty():
      push_error('Runtime metre UV or preserved source UV absent');scene.free();quit(1);return
     materials[material.resource_name]=material
 for name in ['timber','timber_cut','masonry']:
  if not materials.has(name):push_error('Missing actual material '+name);scene.free();quit(1);return
  var m:StandardMaterial3D=materials[name]
  if not m.ao_enabled or m.ao_texture==null or m.ao_texture_channel!=BaseMaterial3D.TEXTURE_CHANNEL_RED or m.ao_on_uv2:
   push_error('Source AO not imported as standard red-channel occlusion: '+name);scene.free();quit(1);return
  if m.albedo_texture==null or not m.normal_enabled or m.normal_texture==null or m.roughness_texture==null:
   push_error('PBR channels lost: '+name);scene.free();quit(1);return
  print('SOURCE_OCCLUSION_MATERIAL ',name,' ao_enabled=',m.ao_enabled,' ao_uv2=',m.ao_on_uv2,' channel=',m.ao_texture_channel,' normal=',m.normal_enabled,' roughness=',m.roughness_texture!=null)
 scene.free()
 print('GATE_OCCLUSION_IMPORT_PASS_NOT_GPU_ART')
 quit()
