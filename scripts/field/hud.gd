extends CanvasLayer
const Arms := preload("res://scripts/field/arms.gd")
const Battle := preload("res://scripts/field/battle.gd")
const FontUI := preload("res://scripts/youth_ui.gd")
signal plan_requested(style: int)
signal muster_apply(company: int,slot: int,shape: int,front: int)
signal camp_requested
signal camp_wait
signal camp_order(command: String)
signal back_report
signal deploy
signal campaign
signal pause
signal quality_changed(index: int)
signal terrain_chosen(at: Vector2)
signal weapon_changed(index: int)
signal order_requested(company: int, mission: int, channel: int)
signal retry
signal save_requested
signal load_requested
var marker:=preload("res://scripts/field/hero_marker.gd").new()
var root_control := Control.new()
var inset := preload("res://scripts/field/map_inset.gd").new()
var objective := Label.new()
var own := Label.new()
var condition := Label.new()
var feedback := Label.new()
var order_panel := PanelContainer.new()
var weapon := OptionButton.new()
var quality := OptionButton.new()
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
var slot := OptionButton.new()
var shape := OptionButton.new()
var front := OptionButton.new()
var plan:=OptionButton.new()
var deployment := VBoxContainer.new()
var orders := VBoxContainer.new()
var select_title := Label.new()
var context := Label.new()
var composition:=Label.new()
var details := Button.new()
var apply_position := Button.new()
var issue := Button.new()
var journey := OptionButton.new()
var march_button := Button.new()
var ration_button := Button.new()
var travel_row:=HBoxContainer.new()
var route_location:="?"
var resume_camp := Button.new()
var wait_hour := Button.new()
var report_button := Button.new()
var retry_button := Button.new()
var graphic_toggle := Button.new()
var graphic_row := VBoxContainer.new()
var phase := -1
var career_alive:=true


func _ready() -> void:
	add_child(marker)
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
	_button(row,graphic_toggle,"画质",func(): graphic_row.visible=not graphic_row.visible)
	_button(row,legacy,"三城旧档",func(): campaign.emit())
	root_control.add_child(graphic_row)
	graphic_row.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	graphic_row.offset_left=-225
	graphic_row.offset_right=-16
	graphic_row.offset_top=182
	_select(graphic_row,quality,"画质",["清晰 · 100%","均衡 · 85%","性能 · 70%"])
	quality.item_selected.connect(func(i: int): quality_changed.emit(i))
	graphic_row.hide()
	root_control.add_child(inset)
	inset.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	inset.offset_left=-211
	inset.offset_right=-16
	inset.offset_top=66
	inset.offset_bottom=174
	inset.chosen.connect(func(at: Vector2): terrain_chosen.emit(at))
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
	help.text="WASD 移动　Shift 疾跑　鼠标瞄准　滚轮缩放　右键平移　中键环视　C 跟随\nF 骑马 / 下马　V 登车 / 下车　1 推进　2 守阵　3 撤离"
	_label(bottom,help,14,Color("aebdb0"))
	root_control.add_child(order_panel)
	order_panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	order_panel.position=Vector2(16,65)
	order_panel.custom_minimum_size.x=268
	order_panel.add_theme_stylebox_override("panel",_style())
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation",5)
	order_panel.add_child(stack)
	_label(stack,select_title,21,Color("efdaa3"))
	_label(stack,context,14,Color("c1d0c2"))
	_select(stack,unit,"部队",[])
	_label(stack,composition,14,Color("e0c891"))
	stack.add_child(orders)
	_select(orders,plan,"全军",["自由部署","协同攻门","交替撤离"])
	plan.item_selected.connect(func(index: int): plan_requested.emit(index))
	_select(orders,weapon,"兵器",Arms.NAMES)
	weapon.select(Arms.Kit.SPEAR)
	weapon.item_selected.connect(func(i: int): weapon_changed.emit(i))
	_select(orders,mission,"任务",Battle.MISSIONS)
	_select(orders,channel,"传达",Battle.CHANNELS)
	_button(orders,issue,"交付任务",func(): order_requested.emit(unit.selected,mission.selected,channel.selected))
	stack.add_child(deployment)
	_select(deployment,slot,"阵位",[])
	_select(deployment,shape,"阵型",Battle.FORMATIONS)
	_select(deployment,front,"前排",Battle.VANGUARDS)
	_button(deployment,apply_position,"调动这支部队",func(): muster_apply.emit(unit.selected,slot.selected,shape.selected,front.selected))
	deployment.hide()
	_button(stack,details,"调整阵位与兵种",func():
		deployment.visible=not deployment.visible
		orders.visible=not deployment.visible
		details.text="返回兵器与任务" if deployment.visible else "调整阵位与兵种")
	_button(stack,go,"开战    Enter",func(): deploy.emit())
	root_control.add_child(result_box)
	result_box.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	result_box.grow_horizontal=Control.GROW_DIRECTION_BOTH
	result_box.grow_vertical=Control.GROW_DIRECTION_BOTH
	result_box.add_theme_stylebox_override("panel",_style())
	var summary := VBoxContainer.new()
	result_box.add_child(summary)
	_label(summary,result_text,19,Color("f0dfb2"))
	summary.add_child(travel_row)
	journey.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	travel_row.add_child(journey)
	_button(travel_row,march_button,"行军",func():
		if journey.selected>=0: camp_order.emit(str(journey.get_item_metadata(journey.selected))))
	_button(travel_row,ration_button,"就地补粮",func(): camp_order.emit("ration"))
	var choices:=HBoxContainer.new()
	summary.add_child(choices)
	_button(choices,resume_camp,"继续随军",func(): camp_requested.emit())
	_button(choices,wait_hour,"整备一小时",func(): camp_wait.emit())
	_button(choices,report_button,"查看战报",func(): back_report.emit())
	_button(choices,retry_button,"重新部署",func(): retry.emit())
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
	slot.clear()
	phase=-1
	career_alive=b.hero.hp>0
	plan.select(0)
	for i in b.companies_per_side:
		var point:=b.muster_slots[i]
		var wing: String="北翼" if point.y< -5 else ("南翼" if point.y>5 else "中军")
		slot.add_item("%02d · %s" % [i+1,wing])
		unit.add_item("第 %02d 队  ·  %d 人" % [i+1,b.companies[i].initial])
	weapon.select(b.hero.kit)
	select_company(b,0)
	update_model(b,false)

func select_company(b: Battle,index: int) -> void:
	if index<0 or index>=b.companies_per_side: return
	var c:=b.companies[index]
	slot.select(c.slot)
	shape.select(c.shape)
	front.select(c.front)
	if not b.started:
		mission.select(c.mission)
		var counts: Array[int]=[0,0,0,0,0,0]
		var engineers:=0
		for u in b.roster:
			if u.team!=0 or u.squad!=index or u.officer or u.hero: continue
			if u.engineer: engineers+=1
			if u.mounted: counts[5]+=1
			elif u.kit==Arms.Kit.SHIELD: counts[1]+=1
			elif u.kit in [Arms.Kit.SPEAR,Arms.Kit.GLAIVE]: counts[2]+=1
			elif u.kit==Arms.Kit.BOW: counts[3]+=1
			elif u.kit==Arms.Kit.CROSSBOW: counts[4]+=1
			else: counts[0]+=1
		composition.text="步 %d　盾 %d　长兵 %d　骑 %d\n弓 %d　弩 %d　冲车役 %d（含在编内）" % [counts[0],counts[1],counts[2],counts[5],counts[3],counts[4],engineers]
	inset.set_muster(b,index)


func update_model(b: Battle,paused: bool) -> void:
	var now:=0 if not b.started else (1 if b.result=="" else 2)
	if now!=phase:
		phase=now
		deployment.hide()
		orders.show()
		details.text="调整阵位与兵种"
		composition.visible=phase==0
		details.visible=phase==0
		plan.get_parent().visible=phase==0
		weapon.get_parent().visible=phase==0
		channel.get_parent().visible=phase==1
		legacy.visible=phase!=1
		if phase==2:
			order_panel.hide()
			graphic_row.hide()
		command_toggle.disabled=phase==2
		issue.text="交付任务" if phase==0 else "发出军令"
		select_title.text="河关 · 战前部署" if phase==0 else "临阵 · 传达军令"
		context.text="护送冲车破门，占住内庭六秒。\n点小地图勘察，选部队查看阵位。" if phase==0 else "挑选部队、任务和传达方式。\n命令送达后，军官才会行动。"
		inset.set_muster(b,maxi(0,unit.selected))
	objective.text=("河关 · 护送冲车" if not b.started else "城门 %d%%" % ceili(b.gate_hp/260.0*100.0)) if b.gate_hp>0 else "内庭 %.1f / 6" % b.capture
	own.text="我军 %d / %d　初编军官 %d　守军初编 %d" % [b.side_size-b.losses[0]-b.escaped[0],b.side_size,b.companies_per_side,b.side_size]
	condition.text="%s · 生命 %d/%d　" % [Arms.NAMES[b.hero.kit],ceili(b.hero.hp),int(b.hero.max_hp)]
	if b.hero.kit in [Arms.Kit.BOW,Arms.Kit.CROSSBOW] and not b.legacy_missiles:
		condition.text+="%s %d　" % ["箭" if b.hero.kit==Arms.Kit.BOW else "弩矢",b.hero.ammo]
	if b.vehicle!=0: condition.text+=("骑乘　" if b.vehicle==1 else "驾车　")
	elif b.breath<0.98: condition.text+="气力 %d%%　" % roundi(b.breath*100)
	health.value=b.hero.hp/b.hero.max_hp*100
	feedback.text="　"+b.notice
	help.visible=not b.started or toggle_help
	weapon.disabled=b.started
	go.visible=not b.started
	change.disabled=not b.started or b.result!=""
	change.text="继续  P" if paused else "暂停  P"
	var names: Array=Arms.LABELS[b.hero.kit].duplicate()
	if b.hero.kit in [Arms.Kit.BOW,Arms.Kit.CROSSBOW] and b.hero.ammo==0 and not b.legacy_missiles: names[0]="近身推击"
	var line := PackedStringArray()
	for i in 4:
		var delay := " %.1fs" % b.hero_cds[i] if b.hero_cds[i]>0 else ""
		line.append("%s  %s%s" % [["左键/J","Q","E","空格"][i],names[i],delay])
	action_text.text="　　 ".join(line)+"　　　 H 操作"
	result_box.visible=b.result!=""
	if result_box.visible:
		travel_row.visible=b.at_camp
		resume_camp.visible=career_alive and b.hero.hp>0 and not b.at_camp
		wait_hour.visible=b.at_camp
		report_button.visible=b.at_camp
		wait_hour.disabled=not career_alive or b.aftermath_hours>=168

func show_receipt(b: Battle,receipt: Dictionary,world: Dictionary) -> void:
	var army: Dictionary=world.army
	career_alive=world.commander.alive and not world.campaign_ended
	resume_camp.visible=career_alive and not b.at_camp
	wait_hour.disabled=not career_alive or b.aftermath_hours>=168
	travel_row.visible=career_alive and b.at_camp
	if not career_alive:
		health.value=0
		condition.text="主将阵亡"
	if b.at_camp:
		var local: Dictionary=world.local_city
		ration_button.disabled=local.is_empty() or local.owner!=army.owner or local.food<=0
		if route_location!=army.location:
			route_location=army.location
			journey.clear()
			for id: String in world.routes:
				var road: Dictionary=world.routes[id]
				if army.location!=road.from and army.location!=road.to: continue
				var destination: String=road.to if road.from==army.location else road.from
				var road_name: String={"road":"驿道","mountain":"山路","river":"河道","grain_road":"粮道"}[id]
				var city_name: String={"hequ":"河关","pingling":"平陵","anping":"安平"}[destination]
				journey.add_item("%s → %s · %d时" % [road_name,city_name,road.hours])
				journey.set_item_metadata(journey.item_count-1,id)
		march_button.disabled=journey.item_count==0 or army.soldiers<=0
		journey.visible=journey.item_count>0
		var place: String={"hequ":"河关","pingling":"平陵","anping":"安平"}.get(army.location,"行军途中")
		result_text.text="军中整备 · %s\n战后 %d 小时　军历第 %d 时\n在册 %d 人　兵器 %d 件　存粮 %d\n已送达军报 %d 份" % [place,b.aftermath_hours,world.hour,army.soldiers,army.weapons,army.food,world.reports.size()]
		if not career_alive: result_text.text+="\n主将已在战后身亡，军籍和战报留存。"
		if not army.march.is_empty():
			var arrival: String={"hequ":"河关","pingling":"平陵","anping":"安平"}[army.march.destination]
			result_text.text+="\n前往%s · 预计第 %d 时到达" % [arrival,army.march.arrives_at]
		if not world.reports.is_empty():
			var latest: Dictionary=world.reports.back()
			var subject: String={"hequ":"河关","pingling":"平陵","anping":"安平","relief":"本军"}.get(latest.subject,"沿线")
			result_text.text+="\n最近送达：%s，约 %d 小时前观测。" % [subject,maxi(0,floori((world.time_seconds-latest.observed_at_seconds)/3600.0))]
	else:
		var parts:=PackedStringArray()
		for kit in Arms.NAMES:
			if receipt.spoils.has(kit): parts.append("%s ×%d" % [kit,receipt.spoils[kit]])
		result_text.text="%s · 河关战报\n普通士兵　　　阵亡　 撤出　 存活（含撤出）\n我军　　　　　 %d　　 %d　　 %d\n守军　　　　　 %d　　 %d　　 %d\n我军军官阵亡 %d　守军军官阵亡 %d\n缴获归库：%s\n战场遗留兵器 %d 件　本军存粮 %d" % [b.result,b.losses[0],b.escaped[0],b.side_size-b.losses[0],b.losses[1],b.escaped[1],b.side_size-b.losses[1],receipt.dead_ids[0].size()-b.losses[0]-(1 if b.hero.hp<=0 else 0),receipt.dead_ids[1].size()-b.losses[1],"、".join(parts) if not parts.is_empty() else "无",receipt.loose_weapons,army.food]
		if not career_alive and b.hero.hp>0: result_text.text+="\n主将已在战后身亡。"
