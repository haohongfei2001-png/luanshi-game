extends SceneTree
## Headless glTF import evidence, separate from a rendered preview and gameplay.

const ROOT := "res://assets/river_gate/art_v1/"
var checked: Array[Dictionary] = []
var errors: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var paths: Array[String] = []
	_collect(ROOT, paths)
	if paths.is_empty():
		errors.append("No GLB assets found")
	for path in paths:
		var document := GLTFDocument.new()
		var state := GLTFState.new()
		var error := document.append_from_file(path, state)
		if error != OK:
			errors.append("%s: append error %s" % [path, error])
			continue
		var scene := document.generate_scene(state)
		if scene == null:
			errors.append("%s: empty generated scene" % path)
			continue
		var meshes := scene.find_children("*", "MeshInstance3D", true, false)
		var animations: Array[String] = []
		var skeletons := scene.find_children("*", "Skeleton3D", true, false)
		for child in scene.find_children("*", "AnimationPlayer", true, false):
			for animation in (child as AnimationPlayer).get_animation_list():
				animations.append(String(animation))
		checked.append({"file": path.trim_prefix("res://"), "sha256": FileAccess.get_sha256(path),
			"mesh_instances": meshes.size(), "skeletons": skeletons.size(), "animations": animations,
			"status": "GODOT_IMPORT_VERIFIED"})
		if meshes.is_empty():
			errors.append("%s: no meshes" % path)
		scene.free()
	var output := "res://docs/art/river-gate-20261113/godot_import_report.json"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--art-report="):
			output = arg.trim_prefix("--art-report=")
	var report := {"status": "PASS" if errors.is_empty() else "FAIL", "evidence_kind": "headless_gltf_import",
		"engine": Engine.get_version_info(), "display_server": DisplayServer.get_name(),
		"count": checked.size(), "assets": checked, "errors": errors,
		"battle_integrated": false, "m5_performance_verified": false,
		"utc_time": Time.get_datetime_string_from_system(true) + "Z"}
	var file := FileAccess.open(output, FileAccess.WRITE)
	if file == null:
		errors.append("Could not write report: " + output)
	else:
		file.store_string(JSON.stringify(report, "\t") + "\n")
	print("ART_IMPORT_%s files=%s errors=%s" % ["PASS" if errors.is_empty() else "FAIL", checked.size(), errors.size()])
	for error in errors:
		push_error(error)
	quit(0 if errors.is_empty() else 1)

func _collect(path: String, result: Array[String]) -> void:
	var directory := DirAccess.open(path)
	if directory == null:
		return
	for filename in directory.get_files():
		if filename.ends_with(".glb") or filename.ends_with(".gltf"):
			result.append(path.path_join(filename))
	for child in directory.get_directories():
		if child != "source":
			_collect(path.path_join(child), result)
