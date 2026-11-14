extends RefCounted
## Opt-in authored-map identity. Not wired into Battle until the full adapter exists.
## No global active map; a loaded save resolves exact identity before any setup.
const LEGACY_ID:="legacy-field"
const SCHEMA:=1
var _manifest:Dictionary={}
func configure(manifest:Dictionary,verified_payload_hashes:Dictionary)->Error:
 if not _manifest.is_empty():return ERR_ALREADY_IN_USE
 if manifest.get("schema")!=SCHEMA or not manifest.get("map_id") is String or manifest.map_id.is_empty() or manifest.map_id==LEGACY_ID:return ERR_INVALID_DATA
 if not positive_integer(manifest.get("topology_revision")):return ERR_INVALID_DATA
 if not positive_integer(manifest.get("visual_revision")) or not valid_sha(manifest.get("topology_sha256")):return ERR_INVALID_DATA
 var source=manifest.get("authored_source_sha256","")
 if not valid_sha(source):return ERR_INVALID_DATA
 for key in ["scene","navigation"]:
  var row=manifest.get(key)
  if not row is Dictionary:return ERR_INVALID_DATA
  var path=row.get("path","");var digest=row.get("sha256","")
  if not path is String or not path.begins_with("res://") or ".." in path or not valid_sha(digest):return ERR_INVALID_DATA
  if row.get("derived_from_source_sha256")!=source:return ERR_INVALID_DATA
  if verified_payload_hashes.get(path)!=digest:return ERR_FILE_CORRUPT
 _manifest=manifest.duplicate(true)
 _manifest.topology_revision=int(_manifest.topology_revision);_manifest.visual_revision=int(_manifest.visual_revision)
 return OK
static func positive_integer(value:Variant)->bool:
 return (value is int or value is float) and is_finite(float(value)) and value>=1 and value==floor(float(value)) and value<2147483647
static func valid_sha(value:Variant)->bool:
 if not value is String or value.length()!=64:return false
 for i in value.length():
  if not value.substr(i,1) in "0123456789abcdef":return false
 return true
func identity()->Dictionary:
 if _manifest.is_empty():return {}
 return {"map_id":_manifest.map_id,"topology_revision":_manifest.topology_revision,"topology_sha256":_manifest.topology_sha256}
func manifest()->Dictionary:return _manifest.duplicate(true)
func matches(saved:Dictionary)->bool:return not _manifest.is_empty() and saved==identity()
