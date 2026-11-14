extends "res://scripts/field/experimental_landform_guard.gd"
func _ready() -> void:
 super._ready()
 if not Ground.native_woodland_enabled:
  visible=false
  push_error("NATIVE_WOODLAND_DISABLED: missing shared navigation opt-in; do not display traversable trunks")
