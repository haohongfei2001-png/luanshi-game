extends Control
## Presentation only. The scene owns disk operations and authoritative world adoption.
signal close_requested
signal save_requested(slot: String)
signal load_requested(id: String, checkpoint: bool)
signal checkpoint_requested
signal list_requested(checkpoints: bool)

var panel: PanelContainer
var category: OptionButton
var entries: ItemList
var slot_name: LineEdit
var feedback: Label
var context_label: Label
var buttons: Dictionary = {}

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	var shade := ColorRect.new()
	shade.color = Color("081216df")
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	panel = PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color("14252a")
	style.border_color = Color("cfb476")
	style.set_border_width_all(1)
	style.content_margin_left = 24
	style.content_margin_right = 24
	style.content_margin_top = 18
	style.content_margin_bottom = 18
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 12)
	panel.add_child(stack)
	var heading := HBoxContainer.new()
	stack.add_child(heading)
	var title := _label(heading, "CAMPAIGN / SAVE & LOAD", 24)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_button(heading, "close", "Close / Esc", func(): close_requested.emit())
	context_label = _label(stack, "", 16)
	_label(stack, "Full world + active battle. Training skirmish is NOT included.\nF5 saves to quick; F9 loads quick. Death does not lock your saves.", 15)
	category = OptionButton.new()
	category.add_item("Named save slots")
	category.add_item("Life checkpoints")
	category.custom_minimum_size.y = 36
	category.item_selected.connect(func(_index: int):
		_update_mode()
		list_requested.emit(is_checkpoint_mode()))
	stack.add_child(category)
	entries = ItemList.new()
	entries.custom_minimum_size.y = 200
	entries.size_flags_vertical = Control.SIZE_EXPAND_FILL
	entries.add_theme_font_size_override("font_size", 17)
	entries.item_selected.connect(_select_entry)
	stack.add_child(entries)
	slot_name = LineEdit.new()
	slot_name.text = "manual_1"
	slot_name.placeholder_text = "Slot name: letters, numbers, - or _ (1-48 characters)"
	slot_name.max_length = 48
	slot_name.custom_minimum_size.y = 36
	stack.add_child(slot_name)
	var actions := HFlowContainer.new()
	stack.add_child(actions)
	_button(actions, "save", "Save / overwrite slot", func(): save_requested.emit(slot_name.text.strip_edges()))
	_button(actions, "load", "Load selected", _request_load)
	_button(actions, "checkpoint", "Create life checkpoint", func(): checkpoint_requested.emit())
	feedback = _label(stack, "Select a save or enter a new slot name. Loading replaces the current campaign.", 15)
	feedback.custom_minimum_size.y = 48
	panel.minimum_size_changed.connect(_layout)
	resized.connect(_layout)
	_layout()
	_update_mode()

func _label(parent: Node, value: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color("ede7d6"))
	parent.add_child(label)
	return label

func _button(parent: Node, id: String, title: String, callback: Callable) -> void:
	var button := Button.new()
	button.text = title
	button.custom_minimum_size.y = 38
	button.pressed.connect(callback)
	buttons[id] = button
	parent.add_child(button)

func _layout() -> void:
	panel.size = Vector2(minf(860, size.x - 48), minf(640, size.y - 48))
	panel.position = (size - panel.size) * 0.5

func is_checkpoint_mode() -> bool:
	return category.selected == 1

func _update_mode() -> void:
	slot_name.visible = not is_checkpoint_mode()
	buttons.save.visible = not is_checkpoint_mode()
	buttons.load.disabled = true

func _select_entry(index: int) -> void:
	if not is_checkpoint_mode():
		slot_name.text = str(entries.get_item_metadata(index))
	buttons.load.disabled = false

func _request_load() -> void:
	var selected := entries.get_selected_items()
	if not selected.is_empty():
		load_requested.emit(str(entries.get_item_metadata(selected[0])), is_checkpoint_mode())

func show_entries(ids: Array, selected_id: String = "") -> void:
	entries.clear()
	buttons.load.disabled = true
	for id in ids:
		entries.add_item(_entry_title(str(id)))
		entries.set_item_metadata(entries.item_count - 1, id)
		entries.set_item_tooltip(entries.item_count - 1, str(id))
		if id == selected_id:
			entries.select(entries.item_count - 1)
			_select_entry(entries.item_count - 1)

func set_context(view: Dictionary) -> void:
	var status := "Life ended: earlier saves and checkpoints remain available." if view.campaign_ended else ("Active battle preserved, including casualties and orders." if view.active_battle != "" else "Campaign map / travel / delivered reports preserved.")
	context_label.text = "World h%.2f | %d soldiers | %d food\n%s" % [view.time_seconds / 3600.0, view.army.soldiers, view.army.food, status]

func set_feedback(message: String, failure: bool = false) -> void:
	feedback.text = message
	feedback.add_theme_color_override("font_color", Color("efad97") if failure else Color("e0c486"))

func _entry_title(id: String) -> String:
	if not is_checkpoint_mode():
		return id
	var pieces := id.split("_")
	if pieces.size() != 3 or not pieces[1].is_valid_int():
		return id
	var names := {"prebattle": "Before battle", "newlife": "New life", "life": "Life checkpoint"}
	if not names.has(pieces[0]):
		return id
	var stamp := Time.get_datetime_string_from_unix_time(int(pieces[1])).replace("T", " ")
	return "%s / %s UTC / %s" % [names[pieces[0]], stamp, pieces[2].left(6)]

func set_busy(busy: bool) -> void:
	for button in buttons.values():
		button.disabled = busy
	buttons.load.disabled = busy or entries.get_selected_items().is_empty()
	category.disabled = busy
	slot_name.editable = not busy
