extends Control
## Player-known presentation only. All progress, costs and receipts live in WorldSim.
signal close_requested
signal map_requested
signal saves_requested
signal start_requested(enlistment: String, motivation: String)
signal action_requested(action_id: String)
signal battle_requested

const INK := Color("101c20")
const PAPER := Color("eee5d0")
const GOLD := Color("cfb476")
const MUTED := Color("a1b1ad")
const STAGES := {
	"enlistment": ["01 / 军籍", "十五岁，离乡入营"],
	"first_orders": ["02 / 初阵", "第一次随军出发"],
	"first_battle": ["02 / 初阵", "在战场上挣得一份记录"],
	"first_return": ["03 / 回营", "带回亲历的战报"],
	"dangerous_return": ["06 / 归营", "点名之前"],
	"injustice": ["03 / 军功", "名册上少了你的名字"],
	"appointment": ["04 / 编制", "第一支由你带领的小队"],
	"dangerous_orders": ["05 / 军令", "危险的差遣"],
	"dangerous_battle": ["05 / 军令", "带活着的人回来"],
	"replenishment": ["06 / 归营", "清点、补员与留下的人"],
	"endpoint": ["07 / 余波", "这一段军旅，已经写入世界"],
	"ended": ["终 / 生平", "此生至此"],
	"dead": ["终 / 生平", "此生至此"]}
var world: RefCounted
var view: Dictionary = {}
var buttons: Dictionary = {}
var action_buttons: Dictionary = {}
var scroll: ScrollContainer
var content: VBoxContainer
var stage_label: Label
var title_label: Label
var status_label: Label
var story_label: Label
var facts_label: Label
var records_label: Label
var relations_label: Label
var feedback: Label
var setup: VBoxContainer
var actions: VBoxContainer
var enlistment: OptionButton
var motivation: OptionButton
var blocked := false
var preview_new_life := false

const CHINESE_FONT: FontFile = preload("res://assets/fonts/NotoSansSC-Regular.otf")

static func chinese_font() -> FontFile:
	CHINESE_FONT.allow_system_fallback = false
	return CHINESE_FONT

static func apply_font(control: Control) -> void:
	var shared_theme := Theme.new()
	shared_theme.default_font = chinese_font()
	control.theme = shared_theme

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	apply_font(self)
	var background := ColorRect.new()
	background.color = INK
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right"]:
		margin.add_theme_constant_override("margin_" + side, 40)
	for side in ["top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 22)
	add_child(margin)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 12)
	margin.add_child(stack)
	var heading := HBoxContainer.new()
	heading.add_theme_constant_override("separation", 12)
	stack.add_child(heading)
	var mark := _label(heading, "乱世 / 少年军旅", 24, GOLD)
	mark.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_button(heading, "saves", "F6  存档 / 人生节点", func(): saves_requested.emit())
	_button(heading, "map", "世界 / 军报", func(): map_requested.emit())
	_button(heading, "close", "返回", func(): close_requested.emit())
	_label(stack, "架空边营 · 可改变的普通人物短篇 · 非正式核心剧本", 14, MUTED)
	scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	stack.add_child(scroll)
	content = VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 14)
	scroll.add_child(content)
	stage_label = _label(content, "", 15, GOLD)
	title_label = _label(content, "", 30)
	status_label = _label(content, "", 15, MUTED)
	story_label = _label(content, "", 19)
	story_label.custom_minimum_size.y = 56
	setup = VBoxContainer.new()
	setup.add_theme_constant_override("separation", 10)
	content.add_child(setup)
	_label(setup, "入伍方式与心愿分别选择。它们会改变真实的初始粮食、声望与同袍关系。", 16)
	var selectors := HBoxContainer.new()
	selectors.add_theme_constant_override("separation", 18)
	setup.add_child(selectors)
	var origins := VBoxContainer.new()
	origins.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	selectors.add_child(origins)
	_label(origins, "如何来到军中", 15, GOLD)
	enlistment = OptionButton.new()
	enlistment.name = "Enlistment"
	enlistment.add_item("遭征发：按军籍到营")
	enlistment.add_item("自愿从军：自己走进营门")
	enlistment.custom_minimum_size.y = 44
	origins.add_child(enlistment)
	var reasons := VBoxContainer.new()
	reasons.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	selectors.add_child(reasons)
	_label(reasons, "想要守住什么", 15, GOLD)
	motivation = OptionButton.new()
	motivation.name = "Motivation"
	for text in ["求生：先活下去", "求功：想有一条出路", "守乡：不愿乡里再受战火"]:
		motivation.add_item(text)
	motivation.custom_minimum_size.y = 44
	reasons.add_child(motivation)
	_button(setup, "start", "保存当前世界后，开始十五岁新人生", func():
		if not blocked:
			start_requested.emit(["forced", "volunteer"][enlistment.selected], ["survival", "merit", "homeland"][motivation.selected]))
	_label(setup, "当前世界会先另存为人生节点，成功后才建立新人生。旧存档不删除；训练场独立保留。战斗未结算时不能换人生。", 14, MUTED)
	facts_label = _label(content, "", 16)
	actions = VBoxContainer.new()
	actions.add_theme_constant_override("separation", 9)
	content.add_child(actions)
	_button(content, "battle", "进入实际战场", func():
		if not blocked: battle_requested.emit())
	records_label = _label(content, "", 16)
	relations_label = _label(content, "", 16)
	_button(content, "new_life", "另存本局，查看新人生入口", func():
		preview_new_life = true
		refresh()
		scroll.ensure_control_visible(setup))
	feedback = _label(stack, "", 15, GOLD)
	_label(stack, "阅读与选择菜单暂停当前行动；行军、候命、休整和战斗推进同一个世界时钟。F5 快存 / F9 快读。", 13, MUTED)
	if world != null:
		refresh()

func _label(parent: Node, text: String, font_size: int, color: Color = PAPER) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	parent.add_child(label)
	return label

func _button(parent: Node, id: String, text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.name = id.to_pascal_case()
	button.text = text
	button.custom_minimum_size.y = 44
	button.add_theme_font_size_override("font_size", 16)
	button.add_theme_color_override("font_color", PAPER)
	for key in ["normal", "hover", "pressed", "disabled", "focus"]:
		var style := StyleBoxFlat.new()
		style.bg_color = Color("253a3d") if key in ["hover", "focus"] else Color("182a2e")
		style.border_color = GOLD if key in ["hover", "focus"] else Color("475d5a")
		style.set_border_width_all(1)
		style.set_corner_radius_all(3)
		style.content_margin_left = 16
		style.content_margin_right = 16
		style.content_margin_top = 10
		style.content_margin_bottom = 10
		button.add_theme_stylebox_override(key, style)
	button.pressed.connect(callback)
	parent.add_child(button)
	buttons[id] = button
	return button

func set_blocked(value: bool) -> void:
	blocked = value
	refresh()

func set_feedback(text: String) -> void:
	feedback.text = text

func refresh() -> void:
	if world == null or not is_node_ready():
		return
	view = world.youth_view() if world.has_method("youth_view") else {}
	var known: Dictionary = world.player_view()
	var active: bool = view.get("enabled", false)
	var stage: String = view.get("stage", "enlistment")
	var stage_text: Array = STAGES.get(stage, ["军旅", "边营纪事"])
	stage_label.text = stage_text[0]
	title_label.text = stage_text[1]
	setup.visible = not active or preview_new_life
	buttons.new_life.visible = active and stage == "endpoint" and not preview_new_life
	buttons.new_life.disabled = blocked
	buttons.start.disabled = blocked or not known.active_battle.is_empty()
	buttons.map.disabled = blocked
	buttons.close.disabled = blocked
	buttons.saves.disabled = blocked
	enlistment.disabled = blocked
	motivation.disabled = blocked
	if not active:
		title_label.text = "十五岁，尚未写下的一生"
		status_label.text = "独立叙事人生入口 / 不是 20 对 20 训练，也不是安平技术战役"
		story_label.text = "营外传来点名声。你可以是被征来的少年，也可以为求生、求功或守乡而来。第一场仗，不会因为你年少便放过你。"
	else:
		status_label.text = _status_text(known)
		story_label.text = _story_text(stage)
		if known.campaign_ended:
			title_label.text = "此生至此"
			story_label.text = _story_text("dead")
	facts_label.text = _facts_text(known) if active else ""
	_refresh_actions(active)
	buttons.battle.visible = active and view.get("battle_ready", false)
	buttons.battle.disabled = blocked or not known.active_battle.is_empty() or known.campaign_ended
	records_label.text = _records_text() if active else ""
	relations_label.text = _relations_text() if active else ""
	if active and not known.active_battle.is_empty():
		buttons.close.text = "返回战场"
	else:
		buttons.close.text = "返回"

func _status_text(known: Dictionary) -> String:
	return "%s 岁  ·  %s  ·  世界第 %.2f 日  ·  %s" % [str(snappedf(float(view.get("age_years", 15.0)), 0.01)), _rank_text(str(view.get("rank", "recruit"))), float(known.time_seconds) / 86400.0, "本局已结束，可读取旧节点" if known.campaign_ended else ("已交回军权" if view.get("rank", "") == "relieved_of_command" else ("已获小队指挥权" if view.get("command_authority", "withdrawal_only") == "squad" else "尚无小队指挥权"))]

func _facts_text(known: Dictionary) -> String:
	var army: Dictionary = known.army
	return "眼前的人与物\n在册 %d 人（%s） / 武器 %d 件 / 随军粮 %d / 疲劳 %d / 士气 %d\n主角伤势：%d / %d 生命；人员、装备与粮食均来自现存世界。" % [army.soldiers, "含主角" if known.commander.alive else "主角已死亡", army.weapons, army.food, army.condition.fatigue, army.condition.morale, ceili(known.commander.hp), int(known.commander.hero_profile.max_hp) if known.commander.hero_profile.has("max_hp") else 100]

func _refresh_actions(active: bool) -> void:
	for child in actions.get_children():
		actions.remove_child(child)
		child.queue_free()
	for id in action_buttons:
		buttons.erase(id)
	action_buttons.clear()
	if not active:
		return
	for choice in view.get("choices", []):
		var id: String = choice.id
		var card := VBoxContainer.new()
		card.add_theme_constant_override("separation", 4)
		actions.add_child(card)
		var button := _button(card, id, str(choice.get("label", id)), func():
			if not blocked:
				action_requested.emit(id))
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.disabled = blocked or not choice.get("enabled", false)
		action_buttons[id] = button
		var consequence := "%s世界时间：%s 小时。" % [str(choice.get("description", "")), str(choice.get("hours", 0))]
		if not choice.get("enabled", false):
			consequence += " 当前不可执行：" + str(choice.get("reason", "条件不符"))
		if not consequence.is_empty():
			_label(card, consequence, 14, MUTED)

func _rank_text(rank: String) -> String:
	return {"recruit": "新卒", "squad_leader": "临时小队长", "acting_squad_leader": "临时小队长", "temporary_squad_leader": "临时小队长", "relieved_of_command": "已解任"}.get(rank, rank)

func _story_text(stage: String) -> String:
	match stage:
		"enlistment", "first_orders": return "点名册翻到你这一页。营里没有许诺荣华，只有一项随队出发的军令。先学会拿稳兵器，再想能带回什么。"
		"first_battle": return "你还不能指挥这支队伍。看清同袍的位置，自己挥枪、挡格，也可以向左侧撤离。战场不会替你保证活下来。"
		"first_return", "dangerous_return": return "战斗已经结束。回营后，伤亡会列入名册，亲历的人会留下各自的记忆。"
		"injustice":
			var incident := "报功的名册却没有照实承认你的那一份" if view.get("incident", "") == "appropriated_report" else "你的临阵行动却被上官提出异议，部分战功未获承认"
			var known_account: String = view.get("incident_details", {}).get("account", "")
			return "战斗的记录还在，%s。%s营吏合上簿册：‘有话，想清楚再说。’你可以忍下、申诉、留证，或先护住同袍。" % [incident, "\n" + known_account + "\n" if not known_account.is_empty() else ""]
		"appointment": return "前线缺人。新的差遣和一份有限的编制摆在面前。接过军令之后，你的选择会直接影响跟随的人。"
		"dangerous_orders": return "小队已有名册，粮食与兵器却仍有限。出发、拒绝军令，各有代价。眼下只知道已经送到手里的军情，远处的局势仍可能变化。"
		"dangerous_battle": return "这一次，你可以发出小队军令。击败眼前敌人，或判断时机带人撤退。战死者不会因故事需要重新归队。"
		"replenishment": return "归营点名。空下的位置不会自己补满；补员需要现有的人力、兵器、粮食和时间。也可以保留当前的队伍。"
		"endpoint": return "这一段军旅暂告一段落。能确认的人、损失与军功都已留下记录。未来尚未写定，第一份军中关系也不会凭空消失。"
		"dead", "ended": return "主角死去，此生的行动至此结束。下面留下的只是当时能够知道的记录。可以读取此前的人生节点，不会转而操控后代。"
	return "只记录你亲历、听见或已收到回报的事情。"

func _records_text() -> String:
	var lines: PackedStringArray = ["已确认的军功与记录"]
	lines.append("实际军功 %d / 记入名册 %d / 被冒领 %d / 实领赏粮 %d / 军中声望 %d" % [int(view.get("earned_merit", 0)), int(view.get("recorded_merit", 0)), int(view.get("appropriated_merit", 0)), int(view.get("reward_food", 0)), int(view.get("standing", 0))])
	lines.append("留存证据 %d 份；已选处置：%s" % [view.get("evidence", []).size(), {"endure": "隐忍", "appeal": "申诉", "keep_evidence": "保留证据", "protect_comrade": "保护同袍", "": "尚未决定"}.get(view.get("choice", ""), str(view.get("choice", "")))])
	for proof in view.get("evidence", []):
		lines.append("  · %s / 见证人 %s" % [{"witness_deposition": "证人口供", "contested_roster": "有争议的名册", "private_roster_copy": "私留战报副本", "accepted_responsibility": "承担责任的记录"}.get(proof.get("kind", ""), "记录"), view.get("relationships", {}).get(proof.get("witness", ""), {}).get("name", "未注明")])
	for record in view.get("timeline", []):
		var labels := {"start": "入营登记", "first_march": "随队第一次行军", "dangerous_march": "率小队执行险令", "battle": "实际交战已结算", "return_to_camp": "返回营地", "choice": "作出军功处置", "accept_appointment": "接受小队委任", "replenish": "从驻地补充兵员物资", "finish_without_replacements": "保留现有队伍", "refuse_order": "拒令并交回编制", "unavailable": "世界条件改变，行动中止", "interrupted": "保护未及完成，同袍已亡，尚可另作选择"}
		var label: String = labels.get(record.get("action", ""), "收到记录")
		if record.get("action", "") == "attrition":
			var lost: PackedStringArray = []
			for id in record.get("details", {}).get("dead_ids", []):
				lost.append("主角" if id == "commander" else str(view.get("relationships", {}).get(id, {}).get("name", "同袍")))
			label = "军粮断绝，确认死亡：" + "、".join(lost)
		lines.append("第 %.2f 日 · %s" % [float(record.get("at", 0.0)) / 86400.0, label])
	var endpoint: Dictionary = view.get("endpoint", {})
	if not endpoint.is_empty():
		lines.append("本段终点：%s / 已记下的在册人员 %d 人。" % [{"commander_dead": "主角因断粮死亡" if endpoint.get("cause", "") == "starvation" else "主角战死", "first_patrol_withdrawn": "初阵未取战功，已撤离初阵", "order_refused": "拒绝危险军令，交回编制", "mission_victory": "完成险令", "mission_retreat": "小队撤退归营", "no_appointment_pool": "营中已无足够兵员", "mission_target_absent": "任务目标已不存在"}.get(endpoint.get("reason", ""), "军旅暂歇"), endpoint.get("army_ids", []).size()])
		lines.append("当前已知的伤亡、关系与军功留在世界中；远方尚无回报的事情没有定论。主角死亡结束本局，不切换到后代。")
	return "\n".join(lines)

func _relations_text() -> String:
	var lines: PackedStringArray = ["同袍与往来 / 可知记录，不推断私下动机"]
	var relationships: Dictionary = view.get("relationships", {})
	var starved: Array = []
	for record in view.get("timeline", []):
		if record.get("action", "") == "attrition": starved.append_array(record.get("details", {}).get("dead_ids", []))
	var fallen := 0
	for person in relationships.values():
		if person.get("role", "") == "comrade" and not person.get("alive", true):
			fallen += 1
	lines.append("已确认同袍阵亡或因断粮死亡 %d 人；在册生还人数见上方。" % fallen)
	for id in relationships:
		var person: Dictionary = relationships[id]
		lines.append("%s · %s · 信任 %d / 敬重 %d / 芥蒂 %d / 共同战历 %d" % [person.get("name", "军中相识"), "生还" if person.get("alive", true) else ("因断粮死亡" if id in starved else "已确认阵亡"), person.get("trust", 0), person.get("respect", 0), person.get("grievance", 0), person.get("known_battles", []).size() if person.get("known_battles", []) is Array else int(person.get("known_battles", 0))])
	return "\n".join(lines)
