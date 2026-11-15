extends SceneTree
## Export preparation only, after THIS PLATFORM's official editor import.
## Never invent original hashes from packed hashes or reuse another host's imports.
const Closure=preload("res://scripts/review/resource_closure.gd")
const Identity=preload("res://scripts/review/resource_identity.gd")
func _initialize()->void:
 var args:=OS.get_cmdline_user_args()
 if args.size()!=2:reject("expected INPUT_MANIFEST OUTPUT_MANIFEST");return
 var source=JSON.parse_string(FileAccess.get_file_as_string(args[0]))
 if not source is Dictionary:reject("input manifest must be a dictionary");return
 var result:=build(source)
 if not result.error.is_empty():reject(JSON.stringify(result));return
 if FileAccess.file_exists(args[1]):reject("output already exists; preserve prior evidence and choose a new output path");return
 var output:=FileAccess.open(args[1],FileAccess.WRITE)
 if output==null:reject("cannot create output");return
 output.store_string(JSON.stringify(result.manifest,"  ")+"\n");output.close()
 print("PRODUCTION_RESOURCE_IDENTITIES ",JSON.stringify({"resources":result.manifest.resource_identities.size(),"scope":"local imported bytes only; exported empty-cwd PCK validation still required"}));quit()
func reject(reason:String)->void:
 push_error("RESOURCE_IDENTITY_PREPARATION_REJECTED "+reason);quit(2)
static func build(source:Dictionary)->Dictionary:
 var roots:Array=[];var pinned:Dictionary={}
 for field in ["scene","navigation","actor"]:
  var spec=source.get(field)
  if not spec is Dictionary:return {"error":"missing resource specification","field":field}
  var pairs:=[['path','sha256']]
  if field=="actor":pairs.append(['timing_path','timing_sha256'])
  for pair in pairs:
   var path=spec.get(pair[0]);var digest=spec.get(pair[1])
   if not path is String or not path.begins_with("res://") or ".." in path or "\\" in path:return {"error":"unsafe root path"}
   if not digest is String or digest.length()!=64 or not digest.is_valid_hex_number(false):return {"error":"invalid original source hash","path":path}
   if pinned.has(path) and pinned[path]!=digest:return {"error":"conflicting original source identity","path":path}
   pinned[path]=digest;roots.append(path)
 var closure:=Closure.collect(roots)
 if not closure.error.is_empty():return closure
 var identities:Dictionary={}
 for path in closure.paths:
  # Raw source is mandatory here, even if its import can still load. Runtime
  # later validates remapped bytes after the exporter omits original files.
  if not FileAccess.file_exists(path):return {"error":"original source unavailable during preparation","path":path}
  var digest:=FileAccess.get_sha256(path)
  if pinned.has(path) and pinned[path]!=digest:return {"error":"pinned source bytes differ","path":path}
  var row:=Identity.describe(path)
  if row.has("error"):return row
  row["original_source_sha256"]=digest;identities[path]=row
 var manifest:=source.duplicate(true);manifest["resource_identities"]=identities
 return {"error":"","manifest":manifest,"dependencies":closure.dependencies}
