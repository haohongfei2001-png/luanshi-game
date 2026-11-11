extends Node
## Detaching a mode suspends it, retaining its active battle and unsaved world in memory.
var field: Node3D
var campaign: Node3D
var active: Node3D
func _ready() -> void:
	var legacy := false
	for argument in OS.get_cmdline_user_args():
		if argument in ["--smoke-scene","--campaign-smoke","--training"] or argument.begins_with("--persistence-smoke-") or argument.begins_with("--youth-smoke-") or argument.begins_with("--training-profile=") or argument.begins_with("--campaign-save-id="):
			legacy=true
	if legacy: open_campaign()
	else:
		open_field()
		if "--field-check" in OS.get_cmdline_user_args():
			load("res://scripts/field/package_probe.gd").run(get_tree(),field)

func open_field() -> void:
	if not field:
		field=load("res://scenes/river_gate.tscn").instantiate()
		field.campaign_requested.connect(open_campaign,CONNECT_DEFERRED)
	_show_mode(field)

func open_campaign() -> void:
	if not campaign:
		campaign=load("res://scenes/battle.tscn").instantiate()
		campaign.field_requested.connect(open_field,CONNECT_DEFERRED)
	_show_mode(campaign)

func _show_mode(next: Node3D) -> void:
	if active==next: return
	if active: remove_child(active)
	active=next
	add_child(active)
	if active.get("camera"):
		active.camera.make_current()

func _exit_tree() -> void:
	for mode in [field,campaign]:
		if is_instance_valid(mode) and mode.get_parent()==null: mode.free()
