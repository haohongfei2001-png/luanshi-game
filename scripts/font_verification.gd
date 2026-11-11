extends RefCounted
## Export-safe glyph/license check; no system-font or display-dependent fallback.
const UI := preload("res://scripts/youth_ui.gd")

static func errors() -> Array[String]:
	var failures: Array[String] = []
	var font := UI.chinese_font()
	if font != UI.chinese_font() or font.allow_system_fallback:
		failures.append("Bundled font must be cached with system fallback disabled")
	var coverage := FileAccess.get_file_as_string("res://assets/fonts/coverage.txt")
	if coverage.length() < 7400:
		failures.append("Bundled GB2312 coverage manifest missing")
	for character in coverage:
		if character != "\n" and not font.has_char(character.unicode_at(0)):
			failures.append("Missing bundled glyph U+%04X" % character.unicode_at(0))
	if not FileAccess.get_file_as_string("res://assets/fonts/license.txt").contains("SIL OPEN FONT LICENSE Version 1.1"):
		failures.append("Bundled font license missing")
	return failures
