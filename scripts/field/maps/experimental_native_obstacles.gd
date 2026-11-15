extends "res://scripts/field/maps/authored_obstacles.gd"
## Explicit experiment only. Original parsing/index/order remain authoritative.
var kernel:RefCounted
var native_enabled:=true
func configure(solids:Array,gates:Array=[])->Error:
 var result:=super.configure(solids,gates)
 if result!=OK:return result
 var library:=""
 if OS.has_feature("linux") and OS.has_feature("x86_64"):library="res://native/hf08_query/bin/libhf08_query.so"
 if library.is_empty() or not FileAccess.file_exists(library):return OK
 if not ClassDB.class_exists("HF08ObstacleKernel"):GDExtensionManager.load_extension("res://native/hf08_query/bin/hf08_query.gdextension")
 if ClassDB.class_exists("HF08ObstacleKernel"):
  kernel=ClassDB.instantiate("HF08ObstacleKernel")
  if kernel.configure(_solids,_cells)!=OK:kernel=null
 return OK
func _obstruction_impl(foot:Vector3,radius:float,height:float,open_gates:Dictionary={},force_linear:bool=false)->Dictionary:
 if not native_enabled or kernel==null:return super._obstruction_impl(foot,radius,height,open_gates,force_linear)
 var result:Dictionary=kernel.obstruction(foot,radius,height,open_gates,force_linear)
 if result.error==ERR_UNAVAILABLE:return super._obstruction_impl(foot,radius,height,open_gates,force_linear)
 return result
