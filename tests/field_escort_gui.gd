extends "res://tests/field_playthrough.gd"
## Two legal deployments take different routes through the same shipping shell.
func _run() -> void:
	if DisplayServer.get_name()=="headless": quit(1); return
	var shell=load("res://scenes/game.tscn").instantiate()
	root.add_child(shell)
	field=shell.field
	await _frames(3)
	var h:=field.hud
	await _choose(h.plan,4)
	var patrol:=field.battle
	_check(patrol.world_patrol and patrol.ordinary_counts[0]!=patrol.ordinary_counts[1],"World roster selected in the normal muster")
	_check(h.objective.text=="夺取河关","Muster names the selected court mission")
	await _snap("patrol-muster")
	await _choose(h.plan,0)
	_check(field.battle.side_size==512 and not field.battle.world_patrol,"Reopen full meeting engagement in the same shell")
	var record: Dictionary=await _play_escort(false)
	await _click(h.retry_button)
	_check(not field.battle.started and field.battle.side_size==512,"Camp can reopen a 512v512 muster")
	var vanguard: Dictionary=await _play_escort(true)
	record["vanguard_delivery"]=vanguard
	record.merge({"errors":errors,"popup_semantic_fallbacks":menu_activations,"patrol":[patrol.ordinary_counts[0],patrol.ordinary_counts[1]],"screens":screens})
	var file:=FileAccess.open("res://artifacts/field-escort-gui.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(record,"  "))
	print("FIELD_ESCORT_GUI_"+("PASS " if errors.is_empty() else "FAIL ")+JSON.stringify(record))
	shell.queue_free()
	await process_frame
	quit(0 if errors.is_empty() else 1)

func _play_escort(advance_vanguard: bool) -> Dictionary:
	var h:=field.hud
	await _choose(h.plan,3)
	var b:=field.battle
	_check(b.objectives.task==Battle.Objectives.Task.ESCORT,"Actual escort objective selected")
	_check(h.objective.text=="护送冲车" and h.context.text.contains("先破门"),"Muster explains when a gate can open early")
	if advance_vanguard:
		# Keep the two regular escort companies. Send the other screens ahead
		# through the player's company and mission selectors.
		for company: int in [1,5,6,9,10,13,14]:
			await _choose(h.unit,company)
			await _choose(h.mission,Battle.Mission.PRESS)
			await _click(h.issue)
			_check(b.companies[company].mission==Battle.Mission.PRESS,"Selected vanguard received its task")
	await _click(h.go)
	var prior:=0
	var frames:=0
	var delivery_text:=""
	var delivery_tick:=-1
	var distance_at_open:=-1.0
	var opened_tick:=-1
	var approach:="escort-vanguard-approach" if advance_vanguard else "escort-approach"
	while b.result=="" and frames<1480 and b.tick<2800:
		frames+=1
		if b.tick-prior>=90:
			_at(h.inset.position+h.inset._point(b.ram))
			prior=b.tick
		if b.ram.x>24 and not (approach in screens): await _snap(approach)
		if b.gate_hp<=0 and opened_tick<0:
			opened_tick=b.tick
			distance_at_open=b.ram.distance_to(Ground.GATE)
		if b.gate_hp<=0 and delivery_text.is_empty() and h.objective.text.begins_with("送车入门"):
			delivery_text=h.objective.text
			delivery_tick=b.tick
			if advance_vanguard: await _snap("escort-open-gate")
		await process_frame
	await _frames(3)
	if b.gate_hp<=0 and opened_tick<0:
		opened_tick=b.tick
		distance_at_open=b.ram.distance_to(Ground.GATE)
	var report_title:=h.objective.text
	_check(b.result=="护送冲车成功" and not field.theater.receipt.is_empty(),"The protected crew reached the gate from normal deployment")
	_check(report_title==b.result,"The report replaces the stroke count with the actual outcome")
	if advance_vanguard:
		_check(distance_at_open>4.8 and not delivery_text.is_empty() and delivery_tick<b.tick,"Early breach shows the real delivery phase before the cart arrives")
	if not field.theater.receipt.is_empty():
		_check(not field.theater.receipt.captured_gate and field.theater.snapshot().cities.hequ.owner=="bei","Escort leaves the garrison in possession")
		await _snap("escort-vanguard-report" if advance_vanguard else "escort-report")
		await _click(h.resume_camp)
		await _frames(3)
		_check(b.at_camp and h.wait_hour.visible and h.objective.text=="战后随军","Escort survivors enter a correctly titled camp")
	var result:=b.report()
	result.merge({"opened_tick":opened_tick,"ram_distance_at_open":distance_at_open,"delivery_tick":delivery_tick,"delivery_prompt":delivery_text,"report_title":report_title})
	return result
