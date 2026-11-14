extends RefCounted
## Exact revision resolver, instance-owned. Missing old save identity means legacy;
## unknown/mutated new identity fails closed, never silently relocates old units.
const Identity:=preload("res://scripts/field/maps/map_identity.gd")
const MAP_SAVE_VERSION:=5
var _profiles:Dictionary={}
func register(profile:RefCounted)->Error:
 var identity:Dictionary=profile.identity()
 if identity.is_empty():return ERR_INVALID_DATA
 var key:String=identity.map_id+":"+str(identity.topology_revision)
 if _profiles.has(key):return ERR_ALREADY_EXISTS
 _profiles[key]=profile
 return OK
func resolve_save(save_data:Dictionary)->Dictionary:
 if not save_data.has("map_identity"):
  if save_data.get("version") not in [1,2,3,4]:return {"error":ERR_INVALID_DATA,"legacy":false}
  return {"error":OK,"legacy":true,"profile":null,"mutation":"NONE"}
 if save_data.get("version")!=MAP_SAVE_VERSION:return {"error":ERR_INVALID_DATA,"legacy":false}
 var identity=save_data.map_identity
 if not identity is Dictionary:return {"error":ERR_INVALID_DATA,"legacy":false}
 var key=str(identity.get("map_id",""))+":"+str(identity.get("topology_revision",-1))
 if not _profiles.has(key):return {"error":ERR_DOES_NOT_EXIST,"legacy":false}
 var profile:RefCounted=_profiles[key]
 if not profile.matches(identity):return {"error":ERR_FILE_CORRUPT,"legacy":false}
 return {"error":OK,"legacy":false,"profile":profile,"mutation":"NONE"}
