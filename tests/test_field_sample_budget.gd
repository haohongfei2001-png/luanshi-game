extends SceneTree
const Budget := preload("res://tests/field_sample_budget.gd")
var assertions := 0
var failures := 0
func check(ok: bool, message: String) -> void:
	assertions+=1
	if not ok:
		failures+=1
		push_error(message)
func _initialize() -> void:
	# Reproduce RC25's 2.195 seconds/frame: the old shared contact+sample
	# deadline left 19.76s and only nine frames. Sampling gets a fresh clock.
	check(Budget.keep_sampling(19755665,9),"Nine genuine slow frames are insufficient, but may continue")
	for interval_us: int in [10000,2195074,5000000]:
		var frames:=0
		var elapsed:=0
		while Budget.keep_sampling(elapsed,frames):
			frames+=1
			elapsed+=interval_us
		check(frames>=20,"Fast and slow renderers preserve the 20-frame minimum")
		check(elapsed>=Budget.MIN_US,"Fast renderer preserves the measurement duration")
		check(elapsed<=Budget.MAX_US,"Known slow renderer finishes inside the bounded budget")
	check(not Budget.keep_sampling(Budget.MAX_US,9),"Slow/stalled recording still reaches a finite deadline")
	check(Budget.keep_sampling(Budget.MIN_US-1,20),"Twenty very fast frames alone cannot shorten sample time")
	check(not Budget.keep_sampling(Budget.MIN_US,20),"Both minimums complete the measurement")
	check(Budget.keep_sampling(0,0),"A fresh sample is independent of earlier contact wait")
	print("FIELD_SAMPLE_BUDGET %d assertions / %d failures"%[assertions,failures])
	quit(0 if failures==0 else 1)
