extends Control
## Independent strategic scenario. All presented state comes from player_view().
signal close_requested
const World := preload("res://scripts/world_sim.gd")
const NAMES := {"pingling": "Pingling", "anping": "Anping", "hequ": "Hequ"}
const SOURCES := {"安平求援使者": "Anping relief messenger", "亲历斥候": "Local eyewitness scout", "逃出城的信使": "Escaped city messenger", "安平军情信使": "Anping military messenger"}
var world := World.new()
var view: Dictionary = {}
var buttons: Dictionary = {}
var army_label: Label
var local_label: Label
var reports_label: Label
var feedback: Label
var map: Control
var scroll: ScrollContainer

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	var backdrop := ColorRect.new()
	backdrop.color = Color("111e22")
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)
	scroll = ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.offset_left = 24
	scroll.offset_top = 16
	scroll.offset_right = -24
	scroll.offset_bottom = -16
	add_child(scroll)
	var stack := VBoxContainer.new()
	stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stack.add_theme_constant_override("separation", 9)
	scroll.add_child(stack)
	var heading := HBoxContainer.new()
	stack.add_child(heading)
	var title := _label(heading, "ANPING / STRATEGIC SANDBOX", 24)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_button(heading, "close", "M  /  Return to battle", func(): close_requested.emit())
	_label(stack, "Independent scenario | Battle-world settlement pending | No saves yet", 16)
	_label(stack, "Anping called for aid three days ago. Choose relief, seize Hequ's depot, or wait. Time moves only when you advance it.", 15)
	army_label = _label(stack, "", 18)
	map = Control.new()
	map.custom_minimum_size.y = 190
	map.mouse_filter = Control.MOUSE_FILTER_IGNORE
	map.draw.connect(_draw_map)
	map.resized.connect(func(): map.queue_redraw())
	stack.add_child(map)
	var routes := HFlowContainer.new()
	stack.add_child(routes)
	for route_id in world.player_view().routes:
		var id: String = route_id
		_button(routes, id, "", func(): _command("march", id))
	var actions := HFlowContainer.new()
	stack.add_child(actions)
	_button(actions, "wait1", "Advance 1h", func(): _command("advance", "", 1))
	_button(actions, "wait6", "Advance 6h", func(): _command("advance", "", 6))
	_button(actions, "observe", "Observe here", func(): _command("observe"))
	_button(actions, "food", "Take 60 food", func(): _command("food"))
	_button(actions, "weapons", "Take 10 weapons", func(): _command("weapons"))
	_button(actions, "seize", "Assault Hequ depot", func(): _command("seize"))
	local_label = _label(stack, "", 15)
	feedback = _label(stack, "Choose a route, then advance time to travel. Taking weapons reduces the local garrison's equipment.", 15)
	feedback.add_theme_color_override("font_color", Color("e0c486"))
	_label(stack, "DELIVERED INTELLIGENCE / historical observations, not live remote ownership", 17)
	reports_label = _label(stack, "", 15)
	_button(stack, "reset", "Restart independent world scenario (battle unchanged)", func(): _command("reset"))
	refresh()

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
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(callback)
	buttons[id] = button
	parent.add_child(button)

func _command(command: String, argument: String = "", amount: int = 0) -> void:
	var current: Dictionary = world.player_view()
	var success := false
	match command:
		"march": success = world.march(argument)
		"advance": success = world.advance(amount)
		"observe": success = world.observe_city(current.army.location)
		"food": success = world.transfer(current.army.location, "relief", "food", 60)
		"weapons": success = world.transfer(current.army.location, "relief", "weapons", 10)
		"seize": success = world.seize_depot()
		"reset":
			world.reset()
			success = true
	feedback.text = ("Completed: " if success else "Unavailable: ") + command.replace("_", " ")
	if command == "seize" and success:
		feedback.text = "Depot seized with real losses. Its existing supplies are now available locally. Remote news still takes time."
	if command == "reset":
		feedback.text = "Independent world restarted. The suspended battle is unchanged."
	refresh()

func refresh() -> void:
	view = world.player_view()
	var army: Dictionary = view.army
	var location: String = NAMES.get(army.location, "In transit")
	if not army.march.is_empty():
		location = "To %s / arrival h%d (%dh remaining)" % [NAMES[army.march.destination], army.march.arrives_at, army.march.arrives_at - view.hour]
	army_label.text = "Hour %d | %s\n%d soldiers | %d weapons / %d unarmed | %d food | %d short-ration hours" % [view.hour, location, army.soldiers, army.weapons, maxi(0, army.soldiers - army.weapons), army.food, army.starving_hours]
	for id in view.routes:
		var route: Dictionary = view.routes[id]
		buttons[id].text = "%s: %s - %s / %dh" % [id.capitalize(), NAMES[route.from], NAMES[route.to], route.hours]
		buttons[id].disabled = not army.march.is_empty() or army.location not in [route.from, route.to] or army.soldiers <= 0
	var city: Dictionary = view.local_city
	buttons.observe.disabled = city.is_empty()
	var allied: bool = not city.is_empty() and city.owner == army.owner
	buttons.food.disabled = not allied or city.get("food", 0) < 60
	buttons.weapons.disabled = not allied or city.get("weapons", 0) < 10
	buttons.seize.disabled = city.get("id", "") != "hequ" or allied or _strength(army) <= _strength(city)
	local_label.text = "LOCAL TRUTH / None while travelling. Remote cities are not visible."
	if not city.is_empty():
		local_label.text = "LOCAL TRUTH / %s at h%d: %s | %d garrison | %d weapons | %d food | %d fortification" % [NAMES[city.id], view.hour, city.owner.capitalize(), city.soldiers, city.weapons, city.food, city.fort]
	var lines: PackedStringArray = []
	for report in view.reports:
		var contents: Dictionary = report.contents
		var facts := "owner: " + str(contents.get("owner", "unknown")).capitalize()
		if contents.has("under_siege"):
			facts += " / " + ("under siege" if contents.under_siege else "not under siege")
		if contents.has("outcome"):
			facts += " / " + str(contents.outcome).replace("_", " ")
		if contents.has("food"):
			facts += " / food %d / garrison %d / fort %d" % [contents.food, contents.soldiers, contents.fort]
		lines.append("%s | %s | observed h%d / delivered h%d / age %dh\n  %s" % [NAMES[report.subject], SOURCES.get(report.source, "Unidentified source"), report.observed_at, report.reported_at, view.hour - report.observed_at, facts])
	reports_label.text = "\n".join(lines)
	map.queue_redraw()

func _strength(entity: Dictionary) -> int:
	return mini(entity.get("soldiers", 0), entity.get("weapons", 0)) + maxi(0, entity.get("soldiers", 0) - entity.get("weapons", 0)) / 2

func _draw_map() -> void:
	if view.is_empty():
		return
	var font := ThemeDB.fallback_font
	var positions := {"pingling": Vector2(map.size.x * 0.15, 128), "anping": Vector2(map.size.x * 0.76, 35), "hequ": Vector2(map.size.x * 0.76, 148)}
	for id in view.routes:
		var route: Dictionary = view.routes[id]
		var start: Vector2 = positions[route.from]
		var end: Vector2 = positions[route.to]
		var offset := Vector2(0, -26) if id == "mountain" else Vector2.ZERO
		map.draw_line(start + offset, end + offset, Color("6b7975"), 2)
		var center := (start + end) * 0.5 + offset
		map.draw_string(font, center + Vector2(-42, -5), "%s %dh" % [id.replace("_", " "), route.hours], HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("cfb476"))
	for id in positions:
		var at: Vector2 = positions[id]
		var here: bool = view.army.location == id
		map.draw_circle(at, 9, Color("cfb476") if here else Color("95a9a9"))
		var label: String = NAMES[id] + (" [YOU]" if here else "")
		map.draw_string(font, at + Vector2(14, 5), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("ede7d6"))
		var status := "Ownership unknown"
		if here:
			status = "Local: " + str(view.local_city.owner).capitalize()
		elif view.known.has(id):
			var report: Dictionary = view.known[id]
			status = "Reported %s / h%d" % [str(report.contents.get("owner", "unknown")).capitalize(), report.observed_at]
		map.draw_string(font, at + Vector2(14, 24), status, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("95a9a9"))
