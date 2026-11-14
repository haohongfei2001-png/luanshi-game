extends RefCounted
## Original source GLBs may not exist in PCKs. Hash the resource Godot actually loads.
static func describe(path:String)->Dictionary:
 var packed:=path
 if FileAccess.file_exists(path+'.import'):
  var config:=ConfigFile.new()
  if config.load(path+'.import')!=OK:return {'error':'INVALID_IMPORT_REMAP','source_resource_path':path}
  packed=str(config.get_value('remap','path',''))
  if not packed.begins_with('res://.godot/imported/'):return {'error':'UNEXPECTED_IMPORT_PATH','source_resource_path':path}
 var digest:=FileAccess.get_sha256(packed)
 if digest.length()!=64:return {'error':'PACKED_RESOURCE_UNREADABLE','source_resource_path':path,'packed_resource_path':packed}
 return {'source_resource_path':path,'packed_resource_path':packed,'packed_resource_sha256':digest,'identity_method':'godot_import_remap' if packed!=path else 'direct_resource'}
static func collect(paths:Array)->Dictionary:
 var rows:Dictionary={}
 for path in paths:rows[path]=describe(path)
 return rows
