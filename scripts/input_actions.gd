class_name BattleInput
extends RefCounted
## Device bindings live here; simulation only accepts action names and vectors.

static func install() -> void:
	var bindings := {
		"move_left": [KEY_A, KEY_LEFT], "move_right": [KEY_D, KEY_RIGHT],
		"move_up": [KEY_W, KEY_UP], "move_down": [KEY_S, KEY_DOWN],
		"attack": [KEY_J], "sweep": [KEY_Q], "lunge": [KEY_E], "guard": [KEY_SPACE],
		"order_attack": [KEY_1], "order_follow": [KEY_2], "order_retreat": [KEY_3],
		"pause_battle": [KEY_ESCAPE, KEY_P], "restart_battle": [KEY_R], "toggle_help": [KEY_H], "toggle_strategy": [KEY_M],
		"field_deploy": [KEY_ENTER], "field_orders": [KEY_TAB], "field_center": [KEY_C],
		"field_sprint": [KEY_SHIFT], "field_mount": [KEY_F], "field_chariot": [KEY_V],
		"campaign_saves": [KEY_F6], "campaign_quicksave": [KEY_F5], "campaign_quickload": [KEY_F9]}
	for action in bindings:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		for key in bindings[action]:
			var event := InputEventKey.new()
			event.physical_keycode = key
			if not InputMap.action_has_event(action, event):
				InputMap.action_add_event(action, event)
	var mouse := InputEventMouseButton.new()
	mouse.button_index = MOUSE_BUTTON_LEFT
	if not InputMap.action_has_event("attack", mouse):
		InputMap.action_add_event("attack", mouse)

static func movement() -> Vector2:
	return Input.get_vector("move_left", "move_right", "move_up", "move_down")
