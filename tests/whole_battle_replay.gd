extends SceneTree
## Source runs use the same normal-entry input driver as the exported package.
func _initialize() -> void:
	if "--whole-battle-review" not in OS.get_cmdline_user_args():
		push_error("Use -- --whole-battle-review after the source script arguments")
		quit(1)
		return
	root.add_child(load("res://scenes/game.tscn").instantiate())
