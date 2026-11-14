extends Node3D
const Ground:=preload("res://scripts/field/ground.gd")
func _ready() -> void:
	if not Ground.authored_landform_enabled:
		visible=false
		for shape:CollisionShape3D in find_children("*","CollisionShape3D",true,false):shape.set_deferred("disabled",true)
		push_error("EXPERIMENTAL_LANDFORM_DISABLED: no visual/collision activation without shared Ground opt-in")
