extends "res://tests/field_playthrough.gd"
## A second continuous visit to the same shipping shell via its actual menus.
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
	await _snap("patrol-muster")
	await _choose(h.plan,0)
	_check(field.battle.side_size==512 and not field.battle.world_patrol,"Reopen full meeting engagement in the same shell")
	await _choose(h.plan,3)
	var b:=field.battle
	_check(b.objectives.task==Battle.Objectives.Task.ESCORT,"Actual escort objective selected")
	await _click(h.go)
	var prior:=0
	var frames:=0
	while b.result=="" and frames<1480 and b.tick<2800:
		frames+=1
		if b.tick-prior>=90:
			_at(h.inset.position+h.inset._point(b.ram))
			prior=b.tick
		if b.ram.x>24 and not ("escort-approach" in screens): await _snap("escort-approach")
		await process_frame
	await _frames(3)
	_check(b.result=="护送冲车成功" and not field.theater.receipt.is_empty(),"The protected crew reached the gate from normal deployment")
	if not field.theater.receipt.is_empty():
		_check(not field.theater.receipt.captured_gate and field.theater.snapshot().cities.hequ.owner=="bei","Escort victory leaves a defended city in its owner's hands")
		await _snap("escort-report")
		await _click(h.resume_camp)
		_check(b.at_camp and h.wait_hour.visible,"Escort survivors can enter the same camp")
	var record:=b.report()
	record.merge({"errors":errors,"popup_semantic_fallbacks":menu_activations,"patrol":[patrol.ordinary_counts[0],patrol.ordinary_counts[1]],"screens":screens})
	var file:=FileAccess.open("res://artifacts/field-escort-gui.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(record,"  "))
	print("FIELD_ESCORT_GUI_"+("PASS " if errors.is_empty() else "FAIL ")+JSON.stringify(record))
	shell.queue_free()
	await process_frame
	quit(0 if errors.is_empty() else 1)
