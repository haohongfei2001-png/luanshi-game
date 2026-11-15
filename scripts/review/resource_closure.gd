extends RefCounted
## Discover actual transitive Godot resource dependencies, not just declared keys.
static func collect(roots:Array)->Dictionary:
 var pending:Array=roots.duplicate();var seen:Dictionary={};var dependencies:Dictionary={}
 while not pending.is_empty():
  var path:String=str(pending.pop_back())
  if not path.begins_with("res://") or ".." in path or "\\" in path:return {"error":"UNSAFE_RESOURCE_PATH","path":path}
  if seen.has(path):continue
  if seen.size()>=10000:return {"error":"RESOURCE_CLOSURE_LIMIT"}
  seen[path]=true;dependencies[path]=[]
  # JSON/notice files are included raw and cannot declare Godot resources.
  if path.get_extension() in ["json","txt","md"]:
   if not FileAccess.file_exists(path):return {"error":"RAW_PAYLOAD_MISSING","path":path}
   continue
  if not ResourceLoader.exists(path):return {"error":"LOADABLE_RESOURCE_MISSING","path":path}
  for raw in ResourceLoader.get_dependencies(path):
   var pieces:=str(raw).split("::");var child:String=pieces[-1]
   if not child.begins_with("res://") and pieces[0].begins_with("uid://"):
    var uid:=ResourceUID.text_to_id(pieces[0])
    if ResourceUID.has_id(uid):child=ResourceUID.get_id_path(uid)
   if not child.begins_with("res://"):return {"error":"UNRESOLVED_DEPENDENCY","parent":path,"dependency":raw}
   dependencies[path].append(child);pending.append(child)
 var paths:=seen.keys();paths.sort()
 return {"error":"","paths":paths,"dependencies":dependencies}
