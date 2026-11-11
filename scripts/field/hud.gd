extends CanvasLayer
const Arms := preload("res://scripts/field/arms.gd")
const Battle := preload("res://scripts/field/battle.gd")
const FontUI := preload("res://scripts/youth_ui.gd")
signal deploy
signal campaign
signal pause
signal weapon_changed(index: int)
signal order_requested(company: int, mission: int, channel: int)
signal retry
signal save_requested
signal load_requested
var root_control := Control.new()
var objective := Label.new()
var own := Label.new()
var condition := Label.new()
var feedback := Label.new()
var order_panel := PanelContainer.new()
var weapon := OptionButton.new()
var unit := OptionButton.new()
var mission := OptionButton.new()
var channel := OptionButton.new()
var go := Button.new()
var change := Button.new()
var help := Label.new()
var result_box := PanelContainer.new()
var result_text := Label.new()
var action_text := Label.new()
var health := ProgressBar.new()
var command_toggle := Button.new()
var legacy := Button.new()
var save_button := Button.new()
var load_button := Button.new()
var toggle_help := false

func _ready() -> void:
	add_child(root_control)
	root_control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root_control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	FontUI.apply_font(root_control)
	var top := _panel(root_control,Control.PRESET_TOP_WIDE)
	top.offset_left=16; top.offset_right=-16; top.offset_top=12
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation",16)
	top.add_child(row)
	_label(row,objective,21,Color("f2dfa6"))
	_label(row,own,16,Color("d0ded0"))
	own.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	_button(row,command_toggle,"军令  Tab",func(): order_panel.visible = not order_panel.visible)
	_button(row,change,"暂停  P",func(): pause.emit())
	_button(row,legacy,"三城战役 / 旧存档",func(): campaign.emit())
	var panel := _panel(root_control,Control.PRESET_BOTTOM_WIDE)
	panel.offset_left=16; panel.offset_right=-16; panel.offset_bottom=-14
	panel.grow_vertical=Control.GROW_DIRECTION_BEGIN
	var bottom := VBoxContainer.new()
	panel.add_child(bottom)
	var vital := HBoxContainer.new()
	bottom.add_child(vital)
	_label(vital,condition,16,Color("efddad"))
	health.custom_minimum_size=Vector2(135,14)
	health.size_flags_vertical=Control.SIZE_SHRINK_CENTER
	health.show_percentage=false
	vital.add_child(health)
	_label(vital,feedback,15,Color("c2cfc6"))
	feedback.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	_button(vital,save_button,"保存 F5",func(): save_requested.emit())
	_button(vital,load_button,"读档 F9",func(): load_requested.emit())
	_label(bottom,action_text,15,Color("e6e4d2"))
	help.text="WASD 移动　鼠标瞄准　滚轮缩放　右键拖动镜头　C 跟随\nF 骑马 / 下马　V 登车 / 下车　1 推进　2 守阵　3 撤离"
	_label(bottom,help,14,Color("aebdb0"))
	root_control.add_child(order_panel)
	order_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER_LEFT)
	order_panel.position=Vector2(18,104)
	order_panel.add_theme_stylebox_override("panel",_style())
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation",8)
	order_panel.add_child(stack)
	var title := Label.new()
	title.text="河关 · 战前部署"
	_label(stack,title,22,Color("edda9f"))
	var instruction := Label.new()
	instruction.text="护送冲车破门，进入城内守住阵地。"
	_label(stack,instruction,15,Color("d5dfcf"))
	_select(stack,weapon,"兵器",Arms.NAMES)
	weapon.select(Arms.Kit.SPEAR)
	weapon.item_selected.connect(func(i: int): weapon_changed.emit(i))
	_select(stack,unit,"部队",[])
	_select(stack,mission,"任务",Battle.MISSIONS)
	_select(stack,channel,"传达",Battle.CHANNELS)
	_button(stack,Button.new(),"下达军令",func(): order_requested.emit(unit.selected,mission.selected,channel.selected))
	_button(stack,go,"开战    Enter",func(): deploy.emit())
	root_control.add_child(result_box)
	result_box.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	result_box.grow_horizontal=Control.GROW_DIRECTION_BOTH
	result_box.grow_vertical=Control.GROW_DIRECTION_BOTH
	result_box.add_theme_stylebox_override("panel",_style())
	var summary := VBoxContainer.new()
	result_box.add_child(summary)
	_label(summary,result_text,19,Color("f0dfb2"))
	_button(summary,Button.new(),"重新部署",func(): retry.emit())
	result_box.hide()

func _style() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color=Color("1e302fef")
	s.border_color=Color("8a8667")
	s.set_border_width_all(1)
	s.set_corner_radius_all(4)
	s.content_margin_left=14
	s.content_margin_right=14
	s.content_margin_top=8
	s.content_margin_bottom=8
	return s

func _panel(parent: Control,preset: int) -> PanelContainer:
	var panel := PanelContainer.new()
	parent.add_child(panel)
	panel.set_anchors_and_offsets_preset(preset)
	panel.add_theme_stylebox_override("panel",_style())
	return panel

func _label(parent: Control,label: Label,size: int,col: Color) -> void:
	label.add_theme_font_size_override("font_size",size)
	label.add_theme_color_override("font_color",col)
	label.mouse_filter=Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)

func _button(parent: Control,button: Button,caption: String,call: Callable) -> void:
	button.text=caption
	button.focus_mode=Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size",15)
	button.pressed.connect(call)
	parent.add_child(button)

func _select(parent: Control,select: OptionButton,caption: String,items: Array) -> void:
	var row := HBoxContainer.new()
	parent.add_child(row)
	var label := Label.new()
	label.text=caption
	label.custom_minimum_size.x=48
	_label(row,label,15,Color("c5cec0"))
	select.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	for item in items: select.add_item(item)
	row.add_child(select)

func bind(b: Battle) -> void:
	unit.clear()
	for i in b.companies_per_side:
		unit.add_item("第 %02d 队  ·  %d 人" % [i+1,b.companies[i].initial])
	weapon.select(b.hero.kit)
	update_model(b,false)

func update_model(b: Battle,paused: bool) -> void:
	objective.text="河关城下" if b.gate_hp>0 else "占领内庭  %.1f / 6 秒" % b.capture
	own.text="我军 %d / %d　军官 %d　敌军初始 %d" % [b.side_size-b.losses[0]-b.escaped[0],b.side_size,b.companies_per_side,b.side_size]
	condition.text="%s · 体力 %d/%d　" % [Arms.NAMES[b.hero.kit],ceili(b.hero.hp),int(b.hero.max_hp)]
	health.value=b.hero.hp/b.hero.max_hp*100
	feedback.text="　"+b.notice
	help.visible=not b.started or toggle_help
	weapon.disabled=b.started
	go.visible=not b.started
	change.disabled=not b.started or b.result!=""
	change.text="继续  P" if paused else "暂停  P"
	var names: Array=Arms.LABELS[b.hero.kit]
	var line := PackedStringArray()
	for i in 4:
		var delay := " %.1fs" % b.hero_cds[i] if b.hero_cds[i]>0 else ""
		line.append("%s  %s%s" % [["左键/J","Q","E","空格"][i],names[i],delay])
	action_text.text="　　 ".join(line)+"　　　 H 操作"
	result_box.visible=b.result!=""
	if result_box.visible:
		result_text.text="%s\n我军阵亡 %d · 撤出 %d · 存活 %d\n敌军阵亡 %d · 撤出 %d · 存活 %d\n遗落兵器 %d / %d" % [b.result,b.losses[0],b.escaped[0],b.side_size-b.losses[0],b.losses[1],b.escaped[1],b.side_size-b.losses[1],b.equipment[0],b.equipment[1]]
