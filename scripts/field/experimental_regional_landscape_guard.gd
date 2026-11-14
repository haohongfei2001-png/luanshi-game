extends "res://scripts/field/experimental_native_woodland_guard.gd"
func _ready() -> void:
 super._ready()
 if OS.get_environment("LUANSHI_REGIONAL_LANDSCAPE")!="1":
  visible=false
  push_error("REGIONAL_LANDSCAPE_NAV_DISABLED: grouped trees require their real shared footprints")
