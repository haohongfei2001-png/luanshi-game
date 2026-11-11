extends SceneTree
const Verify := preload("res://scripts/font_verification.gd")
const UI := preload("res://scripts/youth_ui.gd")

func _initialize() -> void:
	var failures := Verify.errors()
	var font := UI.chinese_font()
	# Scan source, not a manually maintained sample: all current and future UI text,
	# including narrative strings in simulation scripts, must be renderable.
	for filename in DirAccess.get_files_at("res://scripts"):
		if not filename.ends_with(".gd"): continue
		for character in FileAccess.get_file_as_string("res://scripts/" + filename):
			var code := character.unicode_at(0)
			if code >= 32 and not font.has_char(code):
				failures.append(filename + ": unsupported glyph U+%04X; rebuild font" % code)
	for failure in failures:
		push_error(failure)
	print("CHINESE_FONT_SUMMARY " + JSON.stringify({"failures": failures.size(), "font": font.get_font_name()}))
	quit(0 if failures.is_empty() else 1)
