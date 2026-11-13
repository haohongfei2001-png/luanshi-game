extends "res://tests/field_controls.gd"
## Execute the actual controls test through its portrait checkpoint.
## Raw PNG is read back from the same already-rendered viewport texture.
func _portrait() -> void:
	await super._portrait()
	var u:=field.battle.roster[0]
	var yaw:=field.camera_yaw
	# super._portrait restores the saved yaw variable. Its camera transform still
	# projects the current draw because no Godot frame is advanced here.
	var full:=root.get_texture().get_image()
	var anchor:=field.camera.unproject_position(Ground.unit_point(u.pos)+Vector3(.143,1.485,0.))
	var rect:=Rect2i(Vector2i(anchor)-Vector2i(78,52),Vector2i(156,206)).intersection(Rect2i(Vector2i.ZERO,full.get_size()))
	full.get_region(rect).save_png("res://artifacts/guard-aperture.png")
	print("APERTURE_SUBJECT id=",u.id," kit=",u.kit," pos=",u.pos," origin=",rect.position," yaw_restored=",yaw)
	quit(0 if issues.is_empty() else 1)
