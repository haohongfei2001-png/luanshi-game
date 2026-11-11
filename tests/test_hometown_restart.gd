extends SceneTree
func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var proof := preload("res://scripts/hometown_persistence_smoke.gd").run(args[0], args[1])
	print("HOMETOWN_RESTART_SUMMARY " + JSON.stringify(proof))
	quit(0 if proof.ok else 1)
