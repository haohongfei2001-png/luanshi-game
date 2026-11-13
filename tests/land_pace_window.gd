extends SceneTree
const Field := preload("res://scripts/field/battle.gd")
const Saves := preload("res://scripts/field/save.gd")
const Ground := preload("res://scripts/field/ground.gd")

func _initialize() -> void:
	var comparisons:=0
	for zz in range(-128,129):
		for xx in range(-236,237):
			var p:=Vector2(float(xx)*0.5,float(zz)*0.5)
			for mounted: bool in [false,true]:
				var expected:=0.87 if Ground.height(p)>1.2 else 1.0
				if absf(p.x-Ground.RIVER_X)<6.6: expected=0.72
				if p.distance_squared_to(Ground.GROVE)<169.0: expected=0.54 if mounted else 0.82
				if Ground.pace(p,mounted)!=expected:
					push_error("Movement changed at "+str(p))
					quit(1)
					return
				comparisons+=1
	for size: int in [512,2500]:
		_measure(size,comparisons)
	quit()

func _measure(size: int, comparisons: int) -> void:
	var field:=Field.new()
	field.setup(size,Field.SEED)
	field.start()
	field.trace_phase_us.resize(7)
	for i in 40: field.step()
	var total:=PackedInt64Array()
	var motion:=PackedInt64Array()
	for i in 100:
		field.trace_phase_us.fill(0)
		var begin:=Time.get_ticks_usec()
		field.step()
		total.append(Time.get_ticks_usec()-begin)
		motion.append(field.trace_phase_us[3])
	var signature:=Marshalls.raw_to_base64(var_to_bytes(Saves.snapshot(field))).sha256_text()
	print("LAND_PACE_WINDOW ",JSON.stringify({"side":size,"tick":field.tick,"ordinary":field.ordinary_counts,"hits":field.hits,"losses":field.losses,"state_sha256":signature,"whole_us":total,"unit_phase_us":motion,"grid_comparisons":comparisons}))
