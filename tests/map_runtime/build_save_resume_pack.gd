extends SceneTree
## Editor-only pack construction. The template boots an inert scene instead.
func _initialize():
 var args:=OS.get_cmdline_user_args()
 if args.size()!=1:quit(2);return
 var manifest=JSON.parse_string(FileAccess.get_file_as_string(args[0]))
 if not manifest is Dictionary or not manifest.get("packs") is Array:quit(2);return
 for spec in manifest.packs:
  var pack:=PCKPacker.new()
  if pack.pck_start(spec.output)!=OK:quit(2);return
  for item in spec.files:
   if pack.add_file(item.resource,item.path)!=OK:quit(2);return
  if pack.flush()!=OK:quit(2);return
  print("PACKED_SAVE5_BUILT ",spec.output)
 quit()
