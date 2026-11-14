extends SceneTree
## Runs the production grid on a fresh battle. Camera and rendering are excluded.
const Field := preload("res://scripts/field/battle.gd")
const Saves := preload("res://scripts/field/save.gd")

func _initialize() -> void:
	for per_side: int in [512,2500]:
		_sample(per_side)
	quit()

func _sample(per_side: int) -> void:
	var battle:=Field.new()
	battle.setup(per_side,Field.SEED)
	battle.start()
	for tick in 36: battle.step()
	var lookups: Array[int]=[]
	var grid_times: Array[int]=[]
	var step_times: Array[int]=[]
	var signatures:=PackedStringArray()
	var contacts: int=battle.hits[0]+battle.hits[1]
	for round_index in 5:
		var start:=Time.get_ticks_usec()
		battle._rebuild_grid()
		var grid_cost:=Time.get_ticks_usec()-start
		start=Time.get_ticks_usec()
		for u in battle.roster:
			if battle.active(u): battle._assessment(u)
		var query_cost:=Time.get_ticks_usec()-start
		if round_index>0:
			lookups.append(query_cost)
			grid_times.append(grid_cost)
		# Keep each endpoint and the exact floating-point separation, including ties.
		var decisions:=PackedInt32Array()
		var offsets:=PackedVector2Array()
		for u in battle.roster:
			decisions.append(u.target)
			offsets.append(u.separation)
		signatures.append(Marshalls.raw_to_base64(decisions.to_byte_array()+offsets.to_byte_array()).sha256_text())
		for tick in 8:
			start=Time.get_ticks_usec()
			battle.step()
			if round_index>0: step_times.append(Time.get_ticks_usec()-start)
	var snapshot:=Saves.snapshot(battle)
	var full_state:=Marshalls.raw_to_base64(var_to_bytes(snapshot)).sha256_text()
	var terrain_revision: int=snapshot.get("terrain_revision",1)
	# This open-field targeting comparison predates the terrain migration tag.
	# Preserve every combat field and verify the known metadata explicitly.
	assert(terrain_revision in [1,3] and not snapshot.get("bridgehead",false))
	snapshot.erase("terrain_revision")
	var state:=Marshalls.raw_to_base64(var_to_bytes(snapshot)).sha256_text()
	print("FIELD_TARGET_TRIAL ",JSON.stringify({"ordinary":[per_side,per_side],"step_us":step_times,"grid_us":grid_times,"query_us":lookups,"decisions":signatures,"final_state_sha256":state,"full_snapshot_sha256":full_state,"terrain_revision":terrain_revision,"tick":battle.tick,"hits":battle.hits[0]+battle.hits[1]-contacts}))
