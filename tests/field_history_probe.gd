extends SceneTree
## This file runs in both archived games and the current project. Use their shared public API.
const Battle:=preload("res://scripts/field/battle.gd")
const Save:=preload("res://scripts/field/save.gd")

func _initialize() -> void:
	var dir:=OS.get_environment("LUANSHI_HISTORY_DIR")
	if dir.is_empty(): quit(1); return
	var gate_replay := "--gate-replay" in OS.get_cmdline_user_args()
	var before:=dir.path_join("before.bin")
	var after:=dir.path_join("after.bin")
	if "--write-original" in OS.get_cmdline_user_args():
		var b:=Battle.new()
		if gate_replay:
			b.setup(512)
			for i in b.companies_per_side:
				var mission := Battle.Mission.PRESS
				if i in [2,7]: mission = Battle.Mission.ESCORT
				elif i in [0,4]: mission = Battle.Mission.FLANK
				b.command(i,mission,Battle.Channel.FLAG)
			b.start()
			while b.gate_hp > 0.0 and b.result.is_empty() and b.tick < 1600: b.step()
			if b.gate_hp > 0.0 or not b.result.is_empty():
				push_error("The archived RC1 did not reach a live breach")
				quit(1)
				return
		else:
			b.setup(100)
			b.start()
			b.command(1,Battle.Mission.FLANK,Battle.Channel.COURIER)
			for i in 161: b.step()
		_write(before,Save.snapshot(b))
		for i in 117: b.step()
		_write(after,Save.snapshot(b))
		print("FIELD_HISTORY_CREATED tick=",b.tick)
		quit(0)
		return
	var original: Dictionary=bytes_to_var(FileAccess.get_file_as_bytes(before))
	var expected: Dictionary=bytes_to_var(FileAccess.get_file_as_bytes(after))
	var resumed:=Save.restore(original)
	if resumed==null: push_error("Rejected the archived battle"); quit(1); return
	var restored_units:=Save.snapshot(resumed).units
	if restored_units!=original.units:
		print("FIELD_HISTORY_RESTORE_DIFF "+JSON.stringify(_unit_diff(original.units,restored_units)))
	for i in 117: resumed.step()
	var now:=Save.snapshot(resumed)
	var different: Array=[]
	for k in expected:
		if k!="version" and now.get(k)!=expected[k]: different.append(k)
	var expected_tick: int=expected.battle[Save.HEAD.find(&"tick")]
	var start_tick: int=original.battle[Save.HEAD.find(&"tick")]
	var expected_version := 4 if gate_replay else 3
	var ok:=int(original.version)==expected_version and different.is_empty() and resumed.tick==expected_tick and resumed.tick>start_tick
	print("FIELD_HISTORY_"+("PASS " if ok else "FAIL ")+JSON.stringify({"source_version":original.version,"start_tick":start_tick,"expected_tick":expected_tick,"resumed_tick":resumed.tick,"hits":resumed.hits,"different_keys":different}))
	if not ok and "units" in different:
		print("FIELD_HISTORY_UNIT_DIFF "+JSON.stringify(_unit_diff(expected.units,now.units)))
	quit(0 if ok else 1)

func _write(path: String,value: Dictionary) -> void:
	var file:=FileAccess.open(path,FileAccess.WRITE)
	file.store_buffer(var_to_bytes(value))

func _unit_diff(expected: Array,actual: Array) -> Array:
	var changed: Array=[]
	for id in mini(expected.size(),actual.size()):
		if expected[id]==actual[id]: continue
		var fields: Dictionary={}
		for index in mini(expected[id].size(),actual[id].size()):
			if expected[id][index]!=actual[id][index]:
				fields[Save.UNIT[index]]={"expected":expected[id][index],"actual":actual[id][index]}
		changed.append({"id":id,"fields":fields})
		if changed.size()==12: break
	return changed
