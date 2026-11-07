extends SceneTree
const Smoke := preload("res://scripts/campaign_persistence_smoke.gd")
func _initialize() -> void:
	call_deferred("_run")
func _run() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() != 2:
		quit(1)
		return
	var result := Smoke.run(args[0], args[1])
	print("PERSISTENCE_SMOKE_" + args[0].to_upper() + ("_PASS " if result.ok else "_FAIL ") + JSON.stringify(result))
	quit(0 if result.ok else 1)
