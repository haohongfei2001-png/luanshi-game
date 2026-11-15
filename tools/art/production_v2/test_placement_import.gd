extends SceneTree
func imported(path:String)->Node3D:
 var d=GLTFDocument.new();var s=GLTFState.new()
 if d.append_from_file(path,s)!=OK:return null
 return d.generate_scene(s)
func architecture_root(s:Node)->Node3D:
 return s if s.name=='ProductionV2Architecture' else s.find_child('ProductionV2Architecture',true,false)
func bounds(scene:Node,pose:Transform3D)->Dictionary:
 var result={};var pending=[scene]
 while not pending.is_empty():
  var n=pending.pop_back();pending.append_array(n.get_children())
  if n is MeshInstance3D:
   for i in n.mesh.get_surface_count():
    var vertices:PackedVector3Array=n.mesh.surface_get_arrays(i)[Mesh.ARRAY_VERTEX]
    var low=Vector3(INF,INF,INF);var high=Vector3(-INF,-INF,-INF)
    for p in vertices:
     var q=pose*n.global_transform*p;low=low.min(q);high=high.max(q)
    result[str(n.name)+':'+str(i)]={'low':low,'high':high,'vertices':vertices.size()}
 return result
func vec(p)->Vector3:return Vector3(p[0],p[1],p[2])
func _initialize()->void:run.call_deferred()
func run()->void:
 var a=OS.get_cmdline_user_args()
 if a.size()!=3:push_error('sourceGLB placedGLB placedContract required');quit(1);return
 var source=imported(a[0]);var placed=imported(a[1]);var c=JSON.parse_string(FileAccess.get_file_as_string(a[2]))
 if source==null or placed==null or c==null:push_error('Cannot import placement inputs');quit(1);return
 var authored_root=architecture_root(placed)
 root.add_child(source);root.add_child(placed)
 var pose=Transform3D(Basis(Vector3.UP,deg_to_rad(float(c['placement']['yaw_degrees']))),vec(c['placement']['translation_xyz']))
 if not authored_root.global_transform.is_equal_approx(pose):push_error('Actual root pose differs from recorded one matrix');source.free();placed.free();quit(1);return
 var expected=bounds(source,pose);var actual=bounds(placed,Transform3D.IDENTITY);var checked=0;var worst=0.0
 for key in expected:
  if not actual.has(key) or expected[key]['vertices']!=actual[key]['vertices']:push_error('Visual surface missing or topology changed '+key);source.free();placed.free();quit(1);return
  for edge in ['low','high']:
   var error:float=expected[key][edge].distance_to(actual[key][edge]);worst=maxf(worst,error)
   if error>.002:push_error('Surface not transformed by same parent '+key+' '+str(error));source.free();placed.free();quit(1);return
  checked+=1
 var points={'gate_entry':c['gate_dynamic']['entry'],'gate_exit':c['gate_dynamic']['exit'],'GateDoor':c['gate_dynamic']['pivot'],'fort_rear_exit':c['retreat_portal']['center']}
 for name in points:
  var node=placed.find_child(name,true,false)
  if node==null or node.global_position.distance_to(vec(points[name]))>.001:push_error('Portal/door world position differs from sidecar '+name);source.free();placed.free();quit(1);return
 for surface in c['walk_surfaces']:
  var node=placed.find_child(surface['id'],true,false)
  var data=JSON.parse_string(str(node.get_meta('extras',{}).get('contract_json',''))) if node!=null else null
  if data==null or data['xz_polygon']!=surface['xz_polygon'] or data['y']!=surface['y']:push_error('Embedded world walk data differs');source.free();placed.free();quit(1);return
 print('ONE_PARENT_PLACEMENT_IMPORT_PASS_NOT_GAMEPLAY_OR_ART ',JSON.stringify({'surface_bounds_checked':checked,'max_bound_error_m':worst,'portal_world_positions_checked':points.size(),'yaw_degrees':c['placement']['yaw_degrees'],'translation':c['placement']['translation_xyz'],'renderer':'headless','gpu':'NOT_RUN'}))
 source.free();placed.free();quit()
