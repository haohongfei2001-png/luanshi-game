extends RefCounted
## Explicit, default-off v5 API. Never used by the shipping/legacy quick slot.
## Caller supplies an already verified/configured authored runtime on every load.
const Save := preload("res://scripts/field/save.gd")
const Battle := preload("res://scripts/field/battle.gd")
const Runtime := preload("res://scripts/field/maps/authored_field_runtime.gd")
const ROOT := "user://experimental_map_v5"
const MAGIC := "LUANSHI_MAP_V5\n"
const MAX_BYTES := 8*1024*1024
var enabled := false

func _init(explicit_opt_in: bool = false) -> void:
 enabled=explicit_opt_in

func restore(data: Variant, runtime: Runtime) -> Battle:
 if not enabled or runtime==null: return null
 return Save._restore_payload(data,runtime)

func slot_path(slot: String) -> String:
 if slot.is_empty() or slot.length()>48: return ""
 for c in slot:
  if not c in "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_-": return ""
 return ROOT.path_join(slot+".bin")

static func _digest(bytes: PackedByteArray) -> PackedByteArray:
 var hash:=HashingContext.new();hash.start(HashingContext.HASH_SHA256);hash.update(bytes)
 return hash.finish()

func save(b: Battle, slot: String = "resume") -> Error:
 if not enabled or b==null or not b.map_runtime is Runtime: return ERR_UNAVAILABLE
 var path:=slot_path(slot)
 if path.is_empty(): return ERR_INVALID_PARAMETER
 var data:=Save.snapshot(b)
 # Reject unsupported/corrupt state before touching any previous slot.
 if restore(data,b.map_runtime)==null: return ERR_INVALID_DATA
 var payload:=var_to_bytes(data)
 if payload.size()+MAGIC.length()+32>MAX_BYTES: return ERR_OUT_OF_MEMORY
 var directory:=ProjectSettings.globalize_path(ROOT)
 var err:=DirAccess.make_dir_recursive_absolute(directory)
 if err!=OK: return err
 path=ProjectSettings.globalize_path(path)
 var temp:=path+".%d.%d.tmp" % [OS.get_process_id(),Time.get_ticks_usec()]
 var out:=FileAccess.open(temp,FileAccess.WRITE)
 if out==null: return FileAccess.get_open_error()
 out.store_buffer(MAGIC.to_utf8_buffer());out.store_buffer(_digest(payload));out.store_buffer(payload)
 out.flush();err=out.get_error();out.close()
 if err==OK: err=DirAccess.rename_absolute(temp,path)
 if err!=OK: DirAccess.remove_absolute(temp)
 return err

func load_slot(runtime: Runtime, slot: String = "resume") -> Battle:
 if not enabled or runtime==null: return null
 var path:=slot_path(slot)
 if path.is_empty(): return null
 var file:=FileAccess.open(path,FileAccess.READ)
 var prefix:=MAGIC.to_utf8_buffer()
 if file==null or file.get_length()<prefix.size()+32+8 or file.get_length()>MAX_BYTES: return null
 if file.get_buffer(prefix.size())!=prefix: return null
 var digest:=file.get_buffer(32)
 var payload:=file.get_buffer(file.get_length()-file.get_position())
 if file.get_error()!=OK or _digest(payload)!=digest: return null
 # Safe decoder only, never bytes_to_var_with_objects.
 return restore(bytes_to_var(payload),runtime)
