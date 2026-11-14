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
var display_mode := OptionButton.new()
var physical_size := Label.new()
var unit := OptionButton.new()
var mission := OptionButton.new()
var channel := OptionButton.new()
var go := Button.new()
var continue_slot := Button.new()
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
var last_notice:=""
var notice_tick:=-1000
var phase := -1
var career_alive:=true


func _ready() -> void:
	add_child(marker)
	add_child(root_control)
	root_control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root_control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	FontUI.apply_font(root_control)
	var top:=_panel(root_control,Control.PRESET_TOP_LEFT)
	top.position=Vector2(16,13)
	var objective_row:=HBoxContainer.new()
	objective_row.add_theme_constant_override("separation",12)
	top.add_child(objective_row)
	_label(objective_row,objective,18,Color("efdfb2"))
	_label(objective_row,own,14,Color("c4c8ba"))

	var buttons:=HBoxContainer.new()
	root_control.add_child(buttons)
	buttons.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	buttons.offset_right=-16
	buttons.offset_top=13
	buttons.grow_horizontal=Control.GROW_DIRECTION_BEGIN
	buttons.add_theme_constant_override("separation",5)
	_button(buttons,command_toggle,"军令 Tab",func(): order_panel.visible=not order_panel.visible)
	_button(buttons,change,"暂停 P",func(): pause.emit())
	_button(buttons,graphic_toggle,"选项",func(): graphic_row.visible=not graphic_row.visible)
	graphic_toggle.tooltip_text="画质、保存与读档"
	_button(buttons,legacy,"三城旧档",func(): campaign.emit())

	root_control.add_child(inset)
	inset.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	inset.offset_left=-178
	inset.offset_right=-16
	inset.offset_top=52
	inset.offset_bottom=143
	inset.chosen.connect(func(at: Vector2): terrain_chosen.emit(at))
	root_control.add_child(graphic_row)
	graphic_row.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	graphic_row.offset_left=-210
	graphic_row.offset_right=-16
	graphic_row.offset_top=150
	_select(graphic_row,quality,"画质",["清晰 · 100%","均衡 · 85%","性能 · 70%"])
	quality.item_selected.connect(func(i: int): quality_changed.emit(i))
	_select(graphic_row,display_mode,"显示",["当前窗口","显示器全屏","2560 × 1440","3840 × 2160"])
	_label(graphic_row,physical_size,13,Color("c4c8ba"))
	var saves:=HBoxContainer.new()
	graphic_row.add_child(saves)
	_button(saves,save_button,"保存 F5",func(): save_requested.emit())
	_button(saves,load_button,"读档 F9",func(): load_requested.emit())
	graphic_row.hide()

	var status:=_panel(root_control,Control.PRESET_BOTTOM_LEFT)
	status.offset_left=16
	status.offset_bottom=-15
	status.grow_vertical=Control.GROW_DIRECTION_BEGIN
	status.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var bottom:=VBoxContainer.new()
	bottom.mouse_filter=Control.MOUSE_FILTER_IGNORE
	bottom.add_theme_constant_override("separation",3)
	status.add_child(bottom)
	var vital:=HBoxContainer.new()
	vital.mouse_filter=Control.MOUSE_FILTER_IGNORE
	vital.add_theme_constant_override("separation",7)
	bottom.add_child(vital)
	_label(vital,condition,15,Color("f2e4bc"))
	health.custom_minimum_size=Vector2(88,7)
	health.size_flags_vertical=Control.SIZE_SHRINK_CENTER
	health.show_percentage=false
	health.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var inset_track:=StyleBoxFlat.new()
	inset_track.bg_color=Color("263536")
	var fill:=StyleBoxFlat.new()
	fill.bg_color=Color("a9b991")
	health.add_theme_stylebox_override("background",inset_track)
	health.add_theme_stylebox_override("fill",fill)
	vital.add_child(health)
	_label(bottom,feedback,14,Color("e6cf96"))
	_label(bottom,action_text,14,Color("dfdfcc"))
	help.text="WASD 移动　Shift 疾跑　鼠标瞄准　滚轮缩放　右键平移　中键环视　C 跟随\nF 骑马 / 下马　V 登车 / 下车　1 推进　2 守阵　3 撤离"
	_label(bottom,help,14,Color("bdc9bd"))
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
	_select(orders,plan,"全军",["河关会战 · 全军","协同攻门","交替撤离","护送冲车","平陵巡防 · 按军籍","桥头攻门"])
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
	_button(stack,continue_slot,"继续上次战役",func(): load_requested.emit())
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
	s.bg_color=Color("1a2729dc")
	s.border_color=Color("8e8870a0")
	s.set_border_width_all(1)
	s.set_corner_radius_all(4)
	s.content_margin_left=10
	s.content_margin_right=10
	s.content_margin_top=5
	s.content_margin_bottom=5
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
	plan.select(5 if b.bridgehead else (4 if b.world_patrol else (3 if b.objectives.task==Battle.Objectives.Task.ESCORT else 0)))
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
		var commander: String=b.corps.title_of(b,b.roster[c.officer_id])
		if commander!="": composition.text=commander+"　"+composition.text
	inset.set_muster(b,index)


func update_model(b: Battle,paused: bool) -> void:
	var now:=0 if not b.started else (1 if b.result=="" else 2)
	if now!=phase:
		phase=now
		if phase!=0: continue_slot.hide()
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
		context.text="挑选部队、任务和传达方式。\n命令送达后，军官才会行动。"
		inset.set_muster(b,maxi(0,unit.selected))
	if phase==0:
		context.text=b.objectives.brief()+"\n"+("平陵部队已沿河道到场，按实有军械出阵。" if b.world_patrol else "点小地图勘察，选部队查看阵位。")
	if phase==0 and b.bridgehead:
		context.text=b.objectives.brief()+"\n随先队过外壕木桥，盾枪队在门前接敌。"
	if b.at_camp:
		objective.text="战后随军"
	elif b.result!="":
		objective.text=b.result
	elif not b.started:
		objective.text=Battle.Objectives.TITLES[b.objectives.task]
	elif b.objectives.task==Battle.Objectives.Task.ESCORT:
		if b.gate_hp<=0:
			objective.text="送车入门 · 距门 %d 米" % ceili(b.ram.distance_to(Battle.Ground.GATE))
		else:
			objective.text="护送冲车 · 撞门 %d/%d" % [b.objectives.strokes,Battle.Objectives.ESCORT_STROKES]
	elif b.gate_hp>0:
		objective.text="破门 · 城门耐久 %d%%" % ceili(b.gate_hp/260.0*100.0)
	else:
		objective.text="占领内庭 %.1f / 6 秒" % b.capture
	own.visible=not b.started or order_panel.visible or toggle_help
	own.text="我军 %d　守军 %d" % [b.ordinary_counts[0]-b.losses[0]-b.escaped[0],b.ordinary_counts[1]-b.losses[1]-b.escaped[1]]
	condition.text="%s · 生命 %d/%d　" % [Arms.NAMES[b.hero.kit],ceili(b.hero.hp),int(b.hero.max_hp)]
	if b.hero.kit in [Arms.Kit.BOW,Arms.Kit.CROSSBOW] and not b.legacy_missiles:
		condition.text+="%s %d　" % ["箭" if b.hero.kit==Arms.Kit.BOW else "弩矢",b.hero.ammo]
	if b.vehicle!=0: condition.text+=("骑乘　" if b.vehicle==1 else "驾车　")
	elif b.breath<0.98: condition.text+="气力 %d%%　" % roundi(b.breath*100)
	health.value=b.hero.hp/b.hero.max_hp*100
	if b.notice!=last_notice or b.tick<notice_tick:
		last_notice=b.notice
		notice_tick=b.tick
	feedback.text=b.notice
	feedback.visible=not b.notice.is_empty() and (order_panel.visible or b.tick-notice_tick<52)
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
	action_text.text="　 ".join(line)+"　 H 帮助"
	action_text.visible=b.started and b.result==""
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
			var age:=maxi(0,floori((world.time_seconds-latest.observed_at_seconds)/3600.0))
			if latest.contents.get("battle_id","")==receipt.get("battle_id","") and latest.contents.has("outcome"):
				var holding: String="我军守驻" if latest.contents.get("owner","")==army.owner else "守军仍在"
				result_text.text+="\n%s亲历：%s，%s。" % [subject,latest.contents.outcome,holding]
			else:
				result_text.text+="\n最近送达：%s，约 %d 小时前观测。" % [subject,age]
	else:
		var parts:=PackedStringArray()
		for kit in Arms.NAMES:
			if receipt.spoils.has(kit): parts.append("%s ×%d" % [kit,receipt.spoils[kit]])
		result_text.text="%s · 河关战报\n普通士兵　　　阵亡　 撤出　 存活（含撤出）\n我军　　　　　 %d　　 %d　　 %d\n守军　　　　　 %d　　 %d　　 %d\n我军军官阵亡 %d　守军军官阵亡 %d\n缴获归库：%s\n战场遗留兵器 %d 件　本军存粮 %d" % [b.result,b.losses[0],b.escaped[0],b.side_size-b.losses[0],b.losses[1],b.escaped[1],b.ordinary_counts[1]-b.losses[1],receipt.dead_ids[0].size()-b.losses[0]-(1 if b.hero.hp<=0 else 0),receipt.dead_ids[1].size()-b.losses[1],"、".join(parts) if not parts.is_empty() else "无",receipt.loose_weapons,army.food]
		if receipt.has("officers"):
			var ranks: Dictionary=receipt.officers
			result_text.text+="\n接任队正　我军 %d　守军 %d　　救出军官 %d / %d" % [ranks.successions[0],ranks.successions[1],ranks.rescued[0].size(),ranks.rescued[1].size()]
		if receipt.has("strategy") and not b.objectives.decision.is_empty():
			result_text.text+="\n"+b.objectives.decision
		if receipt.has("captured_officers") and (not receipt.captured_officers[0].is_empty() or not receipt.captured_officers[1].is_empty()):
			result_text.text+="\n被俘军官　我军 %d　守军 %d" % [receipt.captured_officers[0].size(),receipt.captured_officers[1].size()]
		if not career_alive and b.hero.hp>0: result_text.text+="\n主将已在战后身亡。"
