extends SceneTree
## This file also runs inside the archived pre-v4 game; use only its public API.
const Battle:=preload("res://scripts/field/battle.gd")
const Save:=preload("res://scripts/field/save.gd")

func _initialize() -> void:
	var dir:=OS.get_environment("LUANSHI_HISTORY_DIR")
	if dir.is_empty(): quit(1); return
	var before:=dir.path_join("before.bin")
	var after:=dir.path_join("after.bin")
	if "--write-original" in OS.get_cmdline_user_args():
		var b:=Battle.new()
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
	if resumed==null: push_error("Rejected the real v3 battle"); quit(1); return
	for i in 117: resumed.step()
	var now:=Save.snapshot(resumed)
	var different: Array=[]
	for k in expected:
		if k!="version" and now.get(k)!=expected[k]: different.append(k)
	var ok:=int(original.version)==3 and different.is_empty() and resumed.tick==278
	print("FIELD_HISTORY_"+("PASS " if ok else "FAIL ")+JSON.stringify({"source_version":original.version,"resumed_tick":resumed.tick,"hits":resumed.hits,"different_keys":different}))
	quit(0 if ok else 1)

func _write(path: String,value: Dictionary) -> void:
	var file:=FileAccess.open(path,FileAccess.WRITE)
	file.store_buffer(var_to_bytes(value))
