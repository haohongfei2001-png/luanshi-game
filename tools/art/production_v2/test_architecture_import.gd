extends SceneTree
func _init() -> void:
 var args=OS.get_cmdline_user_args()
 if args.size()!=1:push_error('Explicit candidate GLB required');quit(1);return
 var document=GLTFDocument.new();var state=GLTFState.new()
 if document.append_from_file(args[0],state)!=OK:push_error('GLB import failed');quit(1);return
 var scene=document.generate_scene(state)
 var door=scene.find_child('GateDoor',true,false)
 if door==null or door.position.distance_to(Vector3(30,1.2,3))>.001:push_error('Gate pivot contract lost');scene.free();quit(1);return
 if str(door.get_meta('extras',{}).get('gate_id',''))!='gate_main':push_error('Stable gate id lost');scene.free();quit(1);return
 var pending=[scene];var meshes=0;var surfaces=0;var materials={};var vertices=0
 while not pending.is_empty():
  var n=pending.pop_back();pending.append_array(n.get_children())
  if n is MeshInstance3D:
   meshes+=1
   for i in n.mesh.get_surface_count():
    surfaces+=1
    var arrays=n.mesh.surface_get_arrays(i);vertices+=arrays[Mesh.ARRAY_VERTEX].size()
    var m=n.mesh.surface_get_material(i)
    if m is StandardMaterial3D:materials[m.resource_name]=m
 for name in ['timber','timber_cut','masonry']:
  if not materials.has(name):push_error('Missing '+name);scene.free();quit(1);return
  var m=materials[name]
  if m.albedo_texture==null or not m.normal_enabled or not m.ao_enabled or m.ao_on_uv2:push_error('PBR/UV import failed '+name);scene.free();quit(1);return
 print('PRODUCTION_V2_IMPORT_PASS_NOT_GAMEPLAY_OR_ART ',JSON.stringify({'meshes':meshes,'surfaces':surfaces,'vertices':vertices,'gate_pivot':str(door.position),'gate_id':str(door.get_meta('extras',{}).get('gate_id','')),'renderer':'headless','muster_512_per_side':'NOT_RUN'}))
 scene.free();quit()
