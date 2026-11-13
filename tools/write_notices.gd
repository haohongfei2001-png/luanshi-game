extends SceneTree
## Bundle the engine and third-party redistribution notices with each build.

func _initialize() -> void:
	var text := "LUANSHI PROTOTYPE - THIRD-PARTY NOTICES\n\n"
	text += "Game code, text and original art by the project authors. Additional assets are credited below.\n"
	text += "No open-source license has been selected for the game itself.\n\n"
	text += "Head topology, anatomical hands and finger articulation derived from the MakeHuman Team HM08 mesh, skin weights and youth morph. Published under CC0 1.0 Universal.\n"
	text += "https://github.com/makehumancommunity/makehuman/blob/a8bc2d54ff0ac92e78ff71431b1023eda42bf482/LICENSE.ASSETS.md\n\n"
	text += "CommonTree_1 and CommonTree_3 meshes, bark and leaves by Quaternius from the free Stylized Nature MegaKit Standard, CC0 1.0 Universal. Adapted for River Gate.\n"
	text += "https://quaternius.com/packs/stylizednaturemegakit.html\n\n"
	text += "Walk_Loop, Walk_Formal_Loop and Jog_Fwd_Loop adapted from the Quaternius Universal Animation Library (free Standard edition). CC0 1.0 Universal.\n"
	text += "https://quaternius.com/packs/universalanimationlibrary.html\n\n"
	text += FileAccess.get_file_as_string("res://assets/third_party/wildfire_garments/NOTICE.txt") + "\n\n"
	text += "Terrain textures adapted from Poly Haven scans under CC0 1.0 Universal.\n"
	text += "Sparse Grass by Amal Kumar. https://polyhaven.com/a/sparse_grass\n"
	text += "Brown Mud Dry by Rob Tuytel. https://polyhaven.com/a/brown_mud_dry\n"
	text += "Sandy Gravel 02 by Dario Barresi. https://polyhaven.com/a/sandy_gravel_02\n"
	text += "https://polyhaven.com/license\n\n"
	text += "Noto Sans SC Regular. Copyright 2014-2021 Adobe and the upstream font authors.\n"
	text += FileAccess.get_file_as_string("res://assets/fonts/OFL.txt") + "\n\n"
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
