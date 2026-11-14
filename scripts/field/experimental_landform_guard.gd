extends Node3D
const Ground:=preload("res://scripts/field/ground.gd")
func _ready() -> void:
	var mismatch:=has_meta("expected_profile_version") and str(get_meta("expected_profile_version"))!=Ground.AuthoredProfile.VERSION
	if not Ground.authored_landform_enabled or mismatch:
		visible=false
		for shape:CollisionShape3D in find_children("*","CollisionShape3D",true,false):shape.set_deferred("disabled",true)
		push_error("EXPERIMENTAL_LANDFORM_DISABLED: missing shared Ground opt-in or mismatched support profile")
