extends Control
## Campaign map. All presented world state comes from player_view().
signal close_requested
signal assault_requested
signal campaign_reset
const World := preload("res://scripts/world_sim.gd")
const NAMES := {"pingling": "Pingling", "anping": "Anping", "hequ": "Hequ"}
const SOURCES := {"安平求援使者": "Anping relief messenger", "亲历斥候": "Local eyewitness scout", "逃出城的信使": "Escaped city messenger", "安平军情信使": "Anping military messenger"}
var world := World.new()
var view: Dictionary = {}
var buttons: Dictionary = {}
var army_label: Label
var local_label: Label
var economy_label: Label
var reports_label: Label
var feedback: Label
var map: Control
var scroll: ScrollContainer
var status_label: Label
var campaign_battle := false
var battle_pending := false

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
	var title := _label(heading, "ANPING / CAMPAIGN PROTOTYPE", 24)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_button(heading, "close", "M  /  Return to training", func(): close_requested.emit())
	status_label = _label(stack, "Real campaign roster and losses | Separate training skirmish | No saves yet", 16)
	_label(stack, "Anping called for aid three days ago. Choose relief, assault Hequ's depot in person, or wait. Battle seconds also advance the world.", 15)
	army_label = _label(stack, "", 16)
	army_label.mouse_filter = Control.MOUSE_FILTER_PASS
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
	economy_label = _label(stack, "", 15)
	feedback = _label(stack, "Choose a route, then advance time to travel. Taking weapons reduces the local garrison's equipment.", 15)
	feedback.add_theme_color_override("font_color", Color("e0c486"))
	_label(stack, "DELIVERED INTELLIGENCE / historical observations, not live remote ownership", 17)
	reports_label = _label(stack, "", 15)
	_button(stack, "reset", "Start a NEW campaign (discard this campaign)", func(): _command("reset"))
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
	if current.get("active_battle", "") != "" or (current.get("campaign_ended", false) and command != "reset"):
		set_feedback("Finish the current battle before issuing world orders." if battle_pending else "The commander died. This campaign has ended.")
		return
	var success := false
	match command:
		"march": success = world.march(argument)
		"advance": success = world.advance(amount)
		"observe": success = world.observe_city(current.army.location)
		"food": success = world.transfer(current.army.location, "relief", "food", 60)
		"weapons": success = world.transfer(current.army.location, "relief", "weapons", 10)
		"seize":
			assault_requested.emit()
			return
		"reset":
			world.reset()
			campaign_reset.emit()
			success = true
	feedback.text = ("Completed: " if success else "Unavailable: ") + command.replace("_", " ")
	if command == "reset":
		feedback.text = "A new campaign has begun. The separate training skirmish is unchanged."
	refresh()

func set_feedback(message: String) -> void:
	feedback.text = message
	refresh()

func set_battle_context(is_campaign_battle: bool, is_pending: bool) -> void:
	campaign_battle = is_campaign_battle
	battle_pending = is_pending
	refresh()

func show_battle_result(summary: Dictionary) -> void:
	var current: Dictionary = world.player_view()
	feedback.text = "Battle recorded once: %d soldiers returned / %d fallen. %.1fs passed in the world. %d soldiers remain in the army." % [summary.friendly_survivors + (1 if summary.player_alive else 0), summary.friendly_casualties + (0 if summary.player_alive else 1), summary.elapsed_seconds, current.army.soldiers]
	if not summary.player_alive:
		feedback.text += " The commander died. This campaign is over; its known reports remain below."
	refresh()

func refresh() -> void:
	view = world.player_view()
	battle_pending = view.get("active_battle", "") != ""
	var army: Dictionary = view.army
	var ended: bool = view.get("campaign_ended", false)
	var locked := battle_pending or ended
	status_label.text = "CAMPAIGN ENDED / Commander died. Only known reports are shown." if ended else ("BATTLE PAUSED / Army and equipment reserved. Return to finish the encounter." if battle_pending else "Real campaign roster and losses | Separate training skirmish | No saves yet")
	buttons.close.text = "M  /  " + ("Resume campaign battle" if battle_pending else ("Review battle result" if campaign_battle else "Return to training"))
	buttons.reset.disabled = battle_pending
	buttons.wait1.disabled = locked
	buttons.wait6.disabled = locked
	var now: float = view.time_seconds
	army_label.text = _army_text(army, now)
	army_label.tooltip_text = _condition_details(army.condition)
	var warning: bool = army.condition.low_food or army.condition.stage in ["shortage", "weakened", "attrition"]
	army_label.add_theme_color_override("font_color", Color("e0c486") if warning else Color("ede7d6"))
	for id in view.routes:
		var route: Dictionary = view.routes[id]
		buttons[id].text = "%s: %s - %s / %dh" % [id.capitalize(), NAMES[route.from], NAMES[route.to], route.hours]
		buttons[id].disabled = locked or not army.march.is_empty() or army.location not in [route.from, route.to] or army.soldiers <= 0
	var city: Dictionary = view.local_city
	buttons.observe.disabled = locked or city.is_empty()
	var allied: bool = not city.is_empty() and city.owner == army.owner
	buttons.food.disabled = locked or not allied or city.get("food", 0) < 60
	buttons.weapons.disabled = locked or not allied or city.get("weapons", 0) < 10
	buttons.seize.disabled = locked or city.get("id", "") != "hequ" or allied or army.soldiers <= 0
	buttons.seize.text = "Assault Hequ depot / up to 20 vs %d" % city.get("soldiers", 0) if city.get("id", "") == "hequ" else "Assault Hequ depot"
	local_label.text = "LOCAL TRUTH / None while travelling. Remote cities are not visible."
	if not city.is_empty():
		local_label.text = "LOCAL TRUTH / %s at %s: %s | %d garrison | %d weapons | %d food | %d fortification" % [NAMES[city.id], _time_text(now, true), city.owner.capitalize(), city.soldiers, city.weapons, city.food, city.fort]
		if city.id == "hequ" and not allied and not locked:
			local_label.text += "\nAssault commits %d people including you; %d stay in reserve. Unarmed soldiers fight without spears." % [mini(20, army.soldiers), maxi(0, army.soldiers - 20)]
	economy_label.text = _economy_text(city)
	economy_label.visible = not economy_label.text.is_empty()
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
		var observed: float = report.observed_at_seconds
		var delivered: float = report.reported_at_seconds
		var age := maxf(0.0, now - observed)
		lines.append("%s | %s | observed h%d / delivered h%d / age %dh\n  %s" % [NAMES[report.subject], SOURCES.get(report.source, "Unidentified source"), report.observed_at, report.reported_at, floori(age / 3600.0), facts])
		if not is_zero_approx(fposmod(observed, 3600.0)) or not is_zero_approx(fposmod(delivered, 3600.0)):
			lines.append("  Exact: observed %s / delivered %s / age %s" % [_time_text(observed, true), _time_text(delivered, true), _time_text(age)])
	reports_label.text = "\n".join(lines)
	map.queue_redraw()

func _army_text(army: Dictionary, now: float) -> String:
	# Consume only the detached own-army projection. Never inspect remote condition.
	var condition: Dictionary = army.condition
	var location: String = NAMES.get(army.location, "In transit")
	if not army.march.is_empty():
		var arrival: float = army.march.arrives_at_seconds
		location = "To %s / arrival %s (%s remaining)" % [NAMES[army.march.destination], _time_text(arrival, true), _time_text(maxf(0.0, arrival - now))]
	var supply := "~%.1fh at %d/h" % [condition.food_hours, condition.food_needed_per_hour] if condition.food_needed_per_hour > 0 else "no rations needed"
	var rest := "Safe rest available" if condition.activity == "rest" else "No safe rest: " + str(condition.activity)
	var warning: String = str(condition.stage).to_upper()
	match condition.stage:
		"shortage": warning += ": Resupply before losses"
		"weakened": warning += ": Resupply now; attrition risk"
		"attrition": warning += ": Starvation losses; resupply now"
		"recovering": warning += ": Keep fed; rest to recover"
		_: warning += ": LOW FOOD; resupply soon" if condition.low_food else ": Full rations + safe rest recover condition"
	if condition.stage in ["shortage", "weakened", "attrition"] and army.food >= condition.food_needed_per_hour and condition.food_needed_per_hour > 0:
		warning = str(condition.stage).to_upper() + ": Rations restored; recovery takes time"
	if condition.hunger > 0:
		warning += " | Hunger %.2f rations; attrition at %.2f" % [float(condition.hunger) / condition.ration_scale, float(condition.attrition_at) / condition.ration_scale]
	return "World %s | %s\n%d soldiers | %d weapons / %d unarmed | Food %d (%s) | Fatigue %d/100 | Morale %d/100\n%s | %s" % [_time_text(now, true), location, army.soldiers, army.weapons, maxi(0, army.soldiers - army.weapons), army.food, supply, condition.fatigue, condition.morale, warning, rest]

func _condition_details(condition: Dictionary) -> String:
	# These are displayed rule values, not a second prediction/simulation of outcomes.
	return "OWN ARMY / PROVISIONAL BALANCE\nLast hourly ration: %d eaten / %d needed; activity: %s.\nHunger: %d points; %d = one whole hourly ration missed.\nWeakening at %d; attrition threshold at %d with another food shortfall.\nCurrent next-battle entry: speed %d%% / damage %d%%.\nFull rations and an entire hour of safe rest recover fatigue and morale.\nSupply hours use the current roster and carried food only, not city stocks." % [condition.last_eaten, condition.last_needed, condition.last_activity, condition.hunger, condition.ration_scale, condition.weakened_at, condition.attrition_at, condition.modifiers.speed_percent, condition.modifiers.damage_percent]

func _economy_text(city: Dictionary) -> String:
	# Only the caller's local projection is accepted, never a remote city lookup.
	if city.is_empty():
		return ""
	var plan: Dictionary = city.production_plan
	var food := _rate_text(plan.food_per_month_numerator, plan.rate_denominator)
	var weapons := _rate_text(plan.weapons_per_month_numerator, plan.rate_denominator)
	var upkeep := _rate_text(plan.civilian_food_per_hour_numerator, plan.civilian_food_rate_denominator)
	var month_days := _rate_text(plan.hours_per_month, plan.hours_per_day)
	var lines: PackedStringArray = [
		"LOCAL ECONOMY / %d civilians (garrison excluded) | %d workers | stability %d/%d" % [city.population, city.workable_population, city.stability, plan.rate_denominator],
		"Allocated labor: %d farmers / %d land slots | %d crafters / %d workshop slots" % [plan.farmers, city.arable_land, plan.crafters, city.workshop_capacity],
		"Current output: %s food + %s weapons / %s-day month | Civilian food need: %s / hour" % [food, weapons, month_days, upkeep],
	]
	if plan.besieged:
		lines.append("Under siege: production halted; civilians still need food.")
	return "\n".join(lines)

func _rate_text(numerator: int, denominator: int) -> String:
	# Exact decimal for the current integer/percentage rules. Keep an exact fraction
	# if future rule data cannot be expressed in hundredths, rather than rounding to 0.
	@warning_ignore("integer_division")
	var whole: int = numerator / denominator
	var remainder := numerator % denominator
	if remainder == 0:
		return str(whole)
	if 100 % denominator != 0:
		return "%d/%d" % [numerator, denominator]
	@warning_ignore("integer_division")
	var hundredths: int = remainder * 100 / denominator
	return ("%d.%02d" % [whole, hundredths]).trim_suffix("0")

func _time_text(seconds: float, clock: bool = false) -> String:
	# Round to display precision before splitting so 59.96s carries into the next minute.
	var tenths := roundi(absf(seconds) * 10.0)
	var hours := tenths / 36000
	var minutes := (tenths % 36000) / 600
	var remainder := float(tenths % 600) / 10.0
	var hour_text := ("h%d" if clock else "%dh") % hours
	return ("-" if seconds < 0.0 else "") + "%s %02dm %04.1fs" % [hour_text, minutes, remainder]

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
