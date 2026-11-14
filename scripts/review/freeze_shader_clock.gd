extends RefCounted
## Transient static-evidence override only. Never writes source resources.
var changed:Array=[]
var seen:Dictionary={}
var report:Array=[]
var include_audit:Array=[]
var include_seen:Dictionary={}
var failed:bool=false
func fail(message:String)->void:
 failed=true;push_error(message)
func freeze(scene:Node,seconds:float)->Array:
 if not changed.is_empty():
  fail('Shader clock already overridden');return []
 failed=false
 var nodes:Array=[scene];nodes.append_array(scene.find_children('*','Node',true,false))
 for node in nodes:
  if node is GeometryInstance3D:
   material(node.material_override,seconds);material(node.material_overlay,seconds)
  if node is MeshInstance3D and node.mesh:
   for i in node.mesh.get_surface_count():material(node.get_active_material(i),seconds)
  if node is MultiMeshInstance3D and node.multimesh and node.multimesh.mesh:
   for i in node.multimesh.mesh.get_surface_count():material(node.multimesh.mesh.surface_get_material(i),seconds)
 return report.duplicate(true)
func material(value:Material,seconds:float)->void:
 if failed:return
 if not value:return
 if value.next_pass:material(value.next_pass,seconds)
 if not value is ShaderMaterial or not value.shader:return
 var shader:Shader=value.shader;var id=shader.get_instance_id()
 if seen.has(id):return
 seen[id]=true
 var code=shader.code
 audit_includes(code)
 if failed:return
 var token=RegEx.new()
 if token.compile('\\bTIME\\b')!=OK:
  fail('Static shader clock TIME pattern failed');return
 if not token.search(code):return
 var declaration=RegEx.new()
 if declaration.compile('shader_type\\s+\\w+\\s*;')!=OK:
  fail('Static shader clock declaration pattern failed');return
 var match=declaration.search(code)
 if not match:
  fail('Unknown shader declaration');return
 var modified=token.sub(code,'DOT_CAPTURE_TIME',true)
 var point=declaration.search(modified).get_end()
 modified=modified.substr(0,point)+'\nconst float DOT_CAPTURE_TIME = %.9f;\n'%seconds+modified.substr(point)
 changed.append([shader,code]);shader.code=modified
 report.append({'source_resource':shader.resource_path,'original_code_sha256':code.sha256_text(),'static_code_sha256':modified.sha256_text(),'fixed_time_seconds':seconds,'method':'transient builtin TIME token override; original code restored before realtime input'})
func restore()->void:
 for entry in changed:entry[0].code=entry[1]
 changed.clear();seen.clear()

func audit_includes(code:String)->void:
 var pattern=RegEx.new()
 if pattern.compile('#include\\s+"([^"]+)"')!=OK:
  fail('Static shader clock include pattern failed');return
 var clock=RegEx.new()
 if clock.compile('\\bTIME\\b')!=OK:
  fail('Static shader clock include TIME pattern failed');return
 for match in pattern.search_all(code):
  var path=match.get_string(1)
  if not path.begins_with('res://') or not FileAccess.file_exists(path):
   fail('Unresolved shader include');return
  if include_seen.has(path):continue
  include_seen[path]=true
  var contents=FileAccess.get_file_as_string(path)
  if clock.search(contents):
   fail('TIME in shader include needs explicit inline transformation');return
  include_audit.append({'resource':path,'sha256':contents.sha256_text(),'TIME_present':false})
  audit_includes(contents)
  if failed:return
