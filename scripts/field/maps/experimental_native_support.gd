extends "res://scripts/field/maps/authored_support.gd"
## Explicit opt-in experiment; base support and all shipping navigation unchanged.
var kernel:RefCounted
var native_enabled:=true
func configure(surfaces:Array)->Error:
 var result:=super.configure(surfaces)
 if result!=OK:return result
 if not OS.has_feature("linux") or not OS.has_feature("x86_64"):return OK
 if not FileAccess.file_exists("res://native/hf08_query/bin/libhf08_query.so"):return OK
 if not ClassDB.class_exists("HF08SupportKernel"):
  GDExtensionManager.load_extension("res://native/hf08_query/bin/hf08_query.gdextension")
 if ClassDB.class_exists("HF08SupportKernel"):
  kernel=ClassDB.instantiate("HF08SupportKernel")
  if kernel.configure(_triangles,_cells)!=OK:kernel=null
 return OK
func _support_uncached(p:Vector2,surface_id:String="")->Dictionary:
 # Out-of-range integer conversion belongs to the engine reference, not C++ casts.
 if not native_enabled or kernel==null or not p.is_finite() or maxf(absf(p.x),absf(p.y))>2147480000.:
  return super._support_uncached(p,surface_id)
 return kernel.support(p,surface_id)
