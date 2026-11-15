extends SceneTree
const Closure:=preload("res://scripts/review/resource_closure.gd")
const Identity:=preload("res://scripts/review/resource_identity.gd")
func _initialize():
 var args:=OS.get_cmdline_user_args();assert(args.size()==3)
 # This probe does not assume a source checkout. A fixture PCK provides the
 # remaps, actual packed resources and its independently prepared expected list.
 assert(ProjectSettings.load_resource_pack(args[0]))
 assert(not FileAccess.file_exists(args[1]),"Probe requires absent raw source")
 var closure:=Closure.collect([args[1]])
 if not closure.error.is_empty():print("ACTUAL_CLOSURE_REJECTED ",JSON.stringify(closure));quit(3);return
 var expected:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(args[2]));var paths:=[]
 for row in expected.resources:paths.append(row.path)
 paths.sort();assert(paths==closure.paths,"Actual transitive set must equal declared set")
 for row in expected.resources:
  var observed:=Identity.describe(row.path)
  if observed.get("packed_resource_sha256")!=row.packed_sha:print("ACTUAL_PACKED_BYTES_REJECTED ",JSON.stringify(observed));quit(3);return
 print("TRANSITIVE_PCK_IDENTITY_PASS ",JSON.stringify({"actual_paths":closure.paths,"raw_source_absent":true,"scope":"HEADLESS_RESOURCE_CONTRACT_NOT_GPU_ART"}));quit()
