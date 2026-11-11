extends Control

signal action_requested(action: String)
signal restart_requested
signal strategy_requested
signal pause_requested
signal saves_requested
signal youth_requested

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
var saves_button: Button
var strategy_button: Button
var pause_button: Button
var restart_button: Button
var campaign_mode := false
var settlement_complete := false
var youth_button: Button
var youth_context: Dictionary = {}
var font: Font

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	font = preload("res://scripts/youth_ui.gd").chinese_font()
	add_theme_font_override("font", font)
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
	strategy_button = Button.new()
	strategy_button.text = "M  /  STRATEGY"
	strategy_button.focus_mode = Control.FOCUS_NONE
	strategy_button.pressed.connect(func(): strategy_requested.emit())
	add_child(strategy_button)
	saves_button = Button.new()
	saves_button.text = "F6  /  SAVE & LOAD"
	saves_button.focus_mode = Control.FOCUS_NONE
	saves_button.pressed.connect(func(): saves_requested.emit())
	add_child(saves_button)
	youth_button = Button.new()
	youth_button.text = "少年军旅 / 人生"
	youth_button.add_theme_font_override("font", preload("res://scripts/youth_ui.gd").chinese_font())
	youth_button.focus_mode = Control.FOCUS_NONE
	youth_button.pressed.connect(func(): youth_requested.emit())
	add_child(youth_button)
	result_panel = PanelContainer.new()
	result_panel.add_theme_stylebox_override("panel", _style(Color("14252af5"), GOLD))
	result_panel.visible = false
	add_child(result_panel)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 18)
	result_panel.add_child(stack)
	result_label = Label.new()
	result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_label.add_theme_font_size_override("font_size", 19)
	result_label.add_theme_color_override("font_color", PAPER)
	stack.add_child(result_label)
	restart_button = Button.new()
	restart_button.text = "R   /   BEGIN A NEW TRAINING SKIRMISH"
	restart_button.custom_minimum_size.y = 44
	restart_button.focus_mode = Control.FOCUS_NONE
	restart_button.pressed.connect(func(): restart_requested.emit())
	stack.add_child(restart_button)
	resized.connect(_layout)
	_layout()

func _style(fill: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 8
	style.content_margin_bottom = 8
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
	strategy_button.position = Vector2(size.x - 162, 68)
	strategy_button.size = Vector2(134, 26)
	saves_button.position = Vector2(size.x - 345, 68)
	saves_button.size = Vector2(176, 26)
	youth_button.position = Vector2(size.x - 345, 25)
	youth_button.size = Vector2(202, 36)
	result_panel.position = Vector2(size.x * 0.5 - 260, size.y * 0.5 - 160)
	result_panel.size = Vector2(520, 320)

func update_state(state: BattleSimulation, is_paused: bool, measured_fps: float) -> void:
	sim = state
	paused = is_paused
	fps = measured_fps
	var names := {"attack": "J / CLICK   Strike", "sweep": "Q   Sweeping cut", "lunge": "E   Spear lunge", "guard": "SPACE   Brace"}
	if not youth_context.is_empty():
		names = {"attack": "J / 左键  刺击", "sweep": "Q  横扫", "lunge": "E  突刺", "guard": "SPACE  挡格"}
	for action in names:
		var cd: float = sim.cooldowns[action]
		buttons[action].text = names[action] + ("\n%.1fs" % cd if cd > 0.0 else "\nREADY")
		var requires_weapon: bool = action in ["sweep", "lunge"] and sim.player().weapon == ""
		if requires_weapon:
			buttons[action].text = names[action] + "\nNO WEAPON"
		buttons[action].disabled = sim.ended or paused or cd > 0.0 or requires_weapon
	for order_name in ["attack", "follow", "retreat"]:
		var key: int = ["attack", "follow", "retreat"].find(order_name) + 1
		buttons["order_" + order_name].text = "%d   %s\n%s" % [key, order_name.to_upper(), "FLAG ISSUED" if sim.order == order_name and sim.signal_sequence > 0 else "SIGNAL NEARBY"]
		buttons["order_" + order_name].disabled = sim.ended or paused
		if not youth_context.is_empty() and youth_context.get("command_authority", "withdrawal_only") != "squad":
			buttons["order_" + order_name].disabled = sim.ended or paused or order_name != "retreat"
			buttons["order_" + order_name].text = "3  RETREAT SIGNAL" if order_name == "retreat" else "NO COMMAND AUTHORITY"
	pause_button.text = "RESUME" if paused else "II   PAUSE"
	pause_button.disabled = sim.ended
	restart_button.text = "R   /   RETURN TO CAMPAIGN" if campaign_mode else "R   /   BEGIN A NEW TRAINING SKIRMISH"
	restart_button.disabled = campaign_mode and not settlement_complete
	result_panel.visible = sim.ended
	if sim.ended:
		var summary := sim.report()
		var result_title := "Hequ depot captured" if campaign_mode and summary.enemy_survivors == 0 and summary.player_alive else sim.result
		result_label.text = "%s\n\nOur company: %d survivors / %d fallen\nOpposition: %d survivors / %d fallen\n\n%.1f seconds   |   Commander %s" % [
			result_title, summary.friendly_survivors + (1 if campaign_mode and summary.player_alive else 0), summary.friendly_casualties + (1 if campaign_mode and not summary.player_alive else 0),
			summary.enemy_survivors, summary.enemy_casualties, sim.elapsed,
			"survived" if summary.player_alive else "died. Run ended."]
		if campaign_mode:
			result_label.text += "\n\n" + ("Losses, equipment and time recorded." if settlement_complete else "Settling campaign consequences...")
			if not summary.player_alive:
				result_label.text += "\nCampaign ended. Load an earlier save or life checkpoint."
	if not youth_context.is_empty():
		pause_button.text = "继续" if paused else "暂停"
		strategy_button.text = "M / 世界军报"
		saves_button.text = "F6 / 存档与回溯"
		for order_name in ["attack", "follow", "retreat"]:
			buttons["order_" + order_name].text = {"attack": "1  进攻", "follow": "2  跟随", "retreat": "3  撤退"}[order_name]
			if youth_context.get("command_authority", "withdrawal_only") != "squad":
				buttons["order_" + order_name].text = "3  预定撤离信号" if order_name == "retreat" else "尚无指挥权"
		restart_button.text = "R / 返回人生记录"
		if sim.ended:
			var summary := sim.report()
			result_label.text = "%s\n\n我方生还 %d / 阵亡 %d\n敌方生还 %d / 阵亡 %d\n实际交战 %.1f 秒 / 主角%s\n\n%s" % ["此生至此" if not summary.player_alive else ("撤出战场" if sim.result == "The company withdrew" else "战斗结束"), summary.friendly_survivors + (1 if summary.player_alive else 0), summary.friendly_casualties + (0 if summary.player_alive else 1), summary.enemy_survivors, summary.enemy_casualties, sim.elapsed, "生还" if summary.player_alive else "战死", "人员、装备与时间已写回世界。" if settlement_complete else "正在结算世界后果……"]
	queue_redraw()

func is_world_pointer(pos: Vector2) -> bool:
	return pos.y > 103 and pos.y < size.y - 149 and not (sim != null and sim.ended)

func _unarmed(team: int) -> int:
	var count := 0
	for unit in sim.units:
		if unit.team == team and not unit.hero and unit.hp > 0.0 and unit.weapon == "":
			count += 1
	return count

func _text(pos: Vector2, value: String, font_size: int, color: Color) -> void:
	draw_string(font, pos, value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)

func _draw() -> void:
	if sim == null or font == null:
		return
	draw_rect(Rect2(0, 0, size.x, 98), INK)
	draw_line(Vector2(0, 98), Vector2(size.x, 98), GOLD.darkened(0.4), 1)
	_text(Vector2(28, 29), "L U A N S H I    /    " + ("CAMPAIGN ENCOUNTER" if campaign_mode else "TRAINING SKIRMISH"), 12, GOLD)
	_text(Vector2(28, 63), ("初阵 · 随队交战" if youth_context.get("battle_purpose", "") == "first_battle" else "险令 · 小队作战") if not youth_context.is_empty() else ("Hequ Depot Assault" if campaign_mode else "Border Skirmish"), 28, PAPER)
	_text(Vector2(28, 84), "REAL ROSTER / REAL LOSSES / FREE SAVES" if campaign_mode else "PRACTICE ONLY / M OPENS YOUR CAMPAIGN", 10, MUTED)
	_text(Vector2(420, 34), "OUR COMPANY", 11, MUTED)
	_text(Vector2(420, 68), "%02d / %02d" % [sim.alive_count(0, campaign_mode), sim.report().friendly_survivors + sim.report().friendly_casualties + (1 if campaign_mode else 0)], 29, Color("78bcb6"))
	_text(Vector2(610, 34), "OPPOSITION", 11, MUTED)
	_text(Vector2(610, 68), "%02d / %02d" % [sim.alive_count(1), sim.report().enemy_survivors + sim.report().enemy_casualties], 29, Color("dd9278"))
	_text(Vector2(420, 86), "%d unarmed" % _unarmed(0), 11, MUTED)
	_text(Vector2(610, 86), "%d unarmed" % _unarmed(1), 11, MUTED)
	_text(Vector2(808, 35), "ELAPSED", 11, MUTED)
	_text(Vector2(808, 66), "%02d:%02d" % [int(sim.elapsed) / 60, int(sim.elapsed) % 60], 24, PAPER)
	_text(Vector2(932, 65), "%.0f FPS" % fps, 13, MUTED)
	var bottom := size.y - 149
	draw_rect(Rect2(0, bottom, size.x, 149), INK)
	draw_line(Vector2(0, bottom), Vector2(size.x, bottom), GOLD.darkened(0.4), 1)
	_text(Vector2(28, bottom + 27), profile_label(), 11, GOLD)
	var health := float(sim.player().hp)
	draw_rect(Rect2(140, bottom + 15, 210, 12), Color("293738"))
	draw_rect(Rect2(140, bottom + 15, 210 * health / sim.player().max_hp, 12), GOLD)
	_text(Vector2(362, bottom + 27), "%d / %d" % [ceili(health), int(sim.player().max_hp)], 12, PAPER)
	_text(Vector2(size.x - 456, bottom + 27), local_signal_label(), 11, GOLD)
	_text(Vector2(28, size.y - 12), "WASD / arrows  Move    Mouse  Aim    H  Help    P / Esc  Pause    R  " + ("Return after battle" if campaign_mode else "New training after battle"), 11, MUTED)
	if show_help and not sim.ended:
		draw_rect(Rect2(28, 114, 330, 95), Color("14252add"))
		if youth_context.is_empty():
			_text(Vector2(42, 137), "Hold the frontier. Bring your people home.", 14, PAPER)
			_text(Vector2(42, 160), "1  Attack   /   2  Follow   /   3  Retreat", 13, GOLD)
			_text(Vector2(42, 183), "Retreat: lead survivors to the left-hand gate.", 12, MUTED)
			_text(Vector2(42, 200), "The commander's death ends this run.", 11, MUTED)
		else:
			_text(Vector2(42, 137), "WASD 移动 / 鼠标瞄准 / 左键攻击", 14, PAPER)
			_text(Vector2(42, 160), "已获小队军权：1 进攻 / 2 跟随 / 3 撤退" if youth_context.get("command_authority", "") == "squad" else "你是新卒；1 / 2 不可用，3 预定撤离信号。", 13, GOLD)
			_text(Vector2(42, 183), "撤退：向左侧营门移动，不能瞬间脱战。", 12, MUTED)
			_text(Vector2(42, 200), "生命只有 100；主角战死即局终，可读档。", 11, MUTED)
	if paused and not sim.ended:
		draw_rect(Rect2(size.x * 0.5 - 150, size.y * 0.5 - 38, 300, 76), Color("14252aee"))
		_text(Vector2(size.x * 0.5 - 62, size.y * 0.5 + 10), "PAUSED", 30, PAPER)

func profile_label() -> String:
	match sim.hero_profile.id:
		"early_v1": return "EARLY / 100HP"
		"late_v1": return "LATE TEST"
		"legacy_test_v0": return "V0.6 LEGACY"
	return "COMMANDER"

func local_signal_label() -> String:
	if sim.signal_model == "legacy_global_v0": return "LEGACY SAVE / GLOBAL ORDERS"
	var status := sim.signal_status()
	if not youth_context.is_empty() and youth_context.get("command_authority", "withdrawal_only") != "squad":
		return "撤离信号 %d/%d 已收 / %d 传达中" % [status.delivered, status.recipients, status.pending]
	if status.sequence == 0: return "LOCAL FLAGS / 14m / NO SIGNAL ISSUED"
	return "%s: %d/%d RECEIVED / %d PENDING" % [status.issued.to_upper(), status.delivered, status.recipients, status.pending]
