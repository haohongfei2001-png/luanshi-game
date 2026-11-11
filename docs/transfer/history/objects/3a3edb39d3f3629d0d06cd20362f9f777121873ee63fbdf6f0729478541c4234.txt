extends SceneTree
## Bundle the engine and third-party redistribution notices with each build.

func _initialize() -> void:
	var text := "LUANSHI PROTOTYPE - THIRD-PARTY NOTICES\n\n"
	text += "Game code, text and procedural placeholder meshes: project authors.\n"
	text += "No open-source license has been selected for the game itself.\n\n"
	text += "GODOT ENGINE\n" + Engine.get_license_text() + "\n\n"
	for component in Engine.get_copyright_info():
		text += str(component.name) + "\n"
		for part in component.parts:
			for notice in part.copyright:
				text += str(notice) + "\n"
			text += "License: " + str(part.license) + "\n"
		text += "\n"
	for name in Engine.get_license_info():
		text += str(name) + "\n" + str(Engine.get_license_info()[name]) + "\n\n"
	var output := FileAccess.open("res://builds/THIRD_PARTY_NOTICES.txt", FileAccess.WRITE)
	if output == null:
		push_error("Cannot write third-party notices")
		quit(1)
		return
	output.store_string(text)
	print("NOTICES_WRITTEN " + str(text.length()))
	quit(0)
