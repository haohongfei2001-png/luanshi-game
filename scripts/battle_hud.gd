extends Control

signal action_requested(action: String)
signal restart_requested
signal pause_requested

const INK := Color("111e22")
const PAPER := Color("ede7d6")
const GOLD := Color("cfb476")
const MUTED := Color("95a9a9")
var sim: BattleSimulation
var paused := false
var show_help := true
var fps := 0.0
var buttons: Dictionary = {}
var result_panel: PanelContainer
var result_label: Label
var pause_button: Button
var font: Font

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	font = ThemeDB.fallback_font
	for action in ["attack", "sweep", "lunge", "guard", "order_attack", "order_follow", "order_retreat"]:
		var button := Button.new()
		button.focus_mode = Control.FOCUS_NONE
		button.add_theme_font_size_override("font_size", 14)
		button.add_theme_color_override("font_color", PAPER)
		button.add_theme_stylebox_override("normal", _style(Color("1b2d31"), Color("435552")))
		button.add_theme_stylebox_override("hover", _style(Color("324341"), GOLD))
		button.add_theme_stylebox_override("pressed", _style(Color("675b3c"), GOLD))
		button.pressed.connect(func(): action_requested.emit(action))
		buttons[action] = button
		add_child(button)
	pause_button = Button.new()
	pause_button.text = "II   PAUSE"
	pause_button.focus_mode = Control.FOCUS_NONE
	pause_button.pressed.connect(func(): pause_requested.emit())
	add_child(pause_button)
	result_panel = PanelContainer.new()
	result_panel.add_theme_stylebox_override("panel", _style(Color("14252af5"), GOLD))
	result_panel.visible = false
	add_child(result_panel)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 18)
	result_panel.add_child(stack)
	result_label = Label.new()
	result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_label.add_theme_font_size_override("font_size", 22)
	result_label.add_theme_color_override("font_color", PAPER)
	stack.add_child(result_label)
	var restart := Button.new()
	restart.text = "R   /   BEGIN A NEW SKIRMISH"
	restart.custom_minimum_size.y = 44
	restart.pressed.connect(func(): restart_requested.emit())
	stack.add_child(restart)
	resized.connect(_layout)
	_layout()

func _style(fill: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.content_margin_left = 20
	style.content_margin_right = 20
	style.content_margin_top = 18
	style.content_margin_bottom = 18
	return style

func _layout() -> void:
	if buttons.is_empty():
		return
	var y := size.y - 94.0
	var x := 28.0
	for action in ["attack", "sweep", "lunge", "guard"]:
		buttons[action].position = Vector2(x, y)
		buttons[action].size = Vector2(142, 62)
		x += 150.0
	x = size.x - 456.0
	for action in ["order_attack", "order_follow", "order_retreat"]:
		buttons[action].position = Vector2(x, y)
		buttons[action].size = Vector2(136, 62)
		x += 142.0
	pause_button.position = Vector2(size.x - 136, 25)
	pause_button.size = Vector2(108, 36)
	result_panel.position = Vector2(size.x * 0.5 - 260, size.y * 0.5 - 160)
	result_panel.size = Vector2(520, 320)

func update_state(state: BattleSimulation, is_paused: bool, measured_fps: float) -> void:
	sim = state
	paused = is_paused
	fps = measured_fps
	var names := {"attack": "J / CLICK   Strike", "sweep": "Q   Sweeping cut", "lunge": "E   Spear lunge", "guard": "SPACE   Brace"}
	for action in names:
		var cd: float = sim.cooldowns[action]
		buttons[action].text = names[action] + ("\n%.1fs" % cd if cd > 0.0 else "\nREADY")
		buttons[action].disabled = sim.ended or paused or cd > 0.0
	for order_name in ["attack", "follow", "retreat"]:
		var key: int = ["attack", "follow", "retreat"].find(order_name) + 1
		buttons["order_" + order_name].text = "%d   %s\n%s" % [key, order_name.to_upper(), "ACTIVE" if sim.order == order_name else "ISSUE ORDER"]
		buttons["order_" + order_name].disabled = sim.ended or paused
	pause_button.text = "RESUME" if paused else "II   PAUSE"
	result_panel.visible = sim.ended
	if sim.ended:
		var summary := sim.report()
		result_label.text = "%s\n\nOur company: %d survivors / %d fallen\nOpposition: %d survivors / %d fallen\n\n%.1f seconds   |   Commander %s" % [
			sim.result, summary.friendly_survivors, summary.friendly_casualties,
			summary.enemy_survivors, summary.enemy_casualties, sim.elapsed,
			"survived" if summary.player_alive else "died. Run ended."]
	queue_redraw()

func is_world_pointer(pos: Vector2) -> bool:
	return pos.y > 103 and pos.y < size.y - 149 and not (sim != null and sim.ended)

func _text(pos: Vector2, value: String, font_size: int, color: Color) -> void:
	draw_string(font, pos, value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)

func _draw() -> void:
	if sim == null or font == null:
		return
	draw_rect(Rect2(0, 0, size.x, 98), INK)
	draw_line(Vector2(0, 98), Vector2(size.x, 98), GOLD.darkened(0.4), 1)
	_text(Vector2(28, 29), "L U A N S H I    /    FIRST PLAYABLE", 12, GOLD)
	_text(Vector2(28, 63), "Border Skirmish", 28, PAPER)
	_text(Vector2(28, 84), "A FICTIONAL DYNASTY  /  AUTUMN FRONTIER", 10, MUTED)
	_text(Vector2(420, 34), "OUR COMPANY", 11, MUTED)
	_text(Vector2(420, 68), "%02d / 20" % sim.alive_count(0), 29, Color("78bcb6"))
	_text(Vector2(610, 34), "OPPOSITION", 11, MUTED)
	_text(Vector2(610, 68), "%02d / 20" % sim.alive_count(1), 29, Color("dd9278"))
	_text(Vector2(808, 35), "ELAPSED", 11, MUTED)
	_text(Vector2(808, 66), "%02d:%02d" % [int(sim.elapsed) / 60, int(sim.elapsed) % 60], 24, PAPER)
	_text(Vector2(932, 65), "%.0f FPS" % fps, 13, MUTED)
	var bottom := size.y - 149
	draw_rect(Rect2(0, bottom, size.x, 149), INK)
	draw_line(Vector2(0, bottom), Vector2(size.x, bottom), GOLD.darkened(0.4), 1)
	_text(Vector2(28, bottom + 27), "COMMANDER", 11, GOLD)
	var health := float(sim.player().hp)
	draw_rect(Rect2(140, bottom + 15, 210, 12), Color("293738"))
	draw_rect(Rect2(140, bottom + 15, 210 * health / sim.player().max_hp, 12), GOLD)
	_text(Vector2(362, bottom + 27), "%d / 360" % ceili(health), 12, PAPER)
	_text(Vector2(size.x - 456, bottom + 27), "COMPANY ORDERS  /  20 SOLDIERS + YOU", 11, GOLD)
	_text(Vector2(28, size.y - 12), "WASD / arrows  Move    Mouse  Aim    H  Help    P / Esc  Pause    R  Restart after battle", 11, MUTED)
	if show_help and not sim.ended:
		draw_rect(Rect2(28, 114, 330, 95), Color("14252add"))
		_text(Vector2(42, 137), "Hold the frontier. Bring your people home.", 14, PAPER)
		_text(Vector2(42, 160), "1  Attack   /   2  Follow   /   3  Retreat", 13, GOLD)
		_text(Vector2(42, 183), "Retreat: lead survivors to the left-hand gate.", 12, MUTED)
		_text(Vector2(42, 200), "The commander's death ends this run.", 11, MUTED)
	if paused and not sim.ended:
		draw_rect(Rect2(size.x * 0.5 - 150, size.y * 0.5 - 38, 300, 76), Color("14252aee"))
		_text(Vector2(size.x * 0.5 - 62, size.y * 0.5 + 10), "PAUSED", 30, PAPER)
