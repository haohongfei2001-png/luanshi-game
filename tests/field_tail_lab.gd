extends SceneTree
## Wall-clock slice around a real fixed simulation step, separate from rendering.
const Battle := preload("res://scripts/field/battle.gd")
const Save := preload("res://scripts/field/save.gd")
const Ground := preload("res://scripts/field/ground.gd")

func digest(b: Battle) -> String:
	var h:=HashingContext.new()
	h.start(HashingContext.HASH_SHA256)
	h.update(var_to_bytes(Save.snapshot(b)))
	return h.finish().hex_encode()

func _initialize() -> void:
	var side:=int(OS.get_environment("TAIL_N"))
	var tag:=OS.get_environment("TAIL_TAG")
	var final_tick:=int(OS.get_environment("TAIL_TICKS"))
	var b:=Battle.new()
	b.setup(side,Battle.SEED)
	for i in b.companies_per_side:
		var mission:=Battle.Mission.PRESS
		if i in [2,7]: mission=Battle.Mission.ESCORT
		elif i in [0,4]: mission=Battle.Mission.FLANK
		b.command(i,mission,Battle.Channel.FLAG)
	b.start()
	var steps:=PackedInt32Array()
	var flags:=PackedInt32Array()
	var snapshots:={}
	var phases: Array=[]
	var instrumented: bool="tail_names" in b
	var names: Array=b.get("tail_names") if instrumented else []
	var cavalry:=0
	for u in b.roster:
		if u.mounted: cavalry+=1
	var max_shots:=0
	var gate_at:=-1
	var breach:=-1
	var ram_at:=-1
	var charging_ticks:=0
	while b.tick<final_tick and b.result=="":
		if b.tick==32: b.command(0,b.companies[0].mission,Battle.Channel.HORN)
		var t:=Time.get_ticks_usec()
		b.step()
		steps.append(Time.get_ticks_usec()-t)
		if instrumented: phases.append(b.get("tail_us").duplicate())
		if gate_at<0 and b.gate_hp<260: gate_at=b.tick
		if breach<0 and b.gate_hp<=0: breach=b.tick
		if ram_at<0 and b.ram.distance_squared_to(Ground.GATE)<16.0: ram_at=b.tick
		var mask:=0
		if gate_at>0 and breach<0: mask|=1
		if b.shots.size()>=maxi(2,side/32): mask|=2
		if b.ram.distance_squared_to(Ground.GATE)<16.0: mask|=4
		var charging:=false
		for u in b.roster:
			if u.mounted and b.active(u) and (u.charging_strike or u.charge_speed>=3.0):
				charging=true
				break
		if charging:
			mask|=8
			charging_ticks+=1
		if b.hits[0]+b.hits[1]>0: mask|=16
		flags.append(mask)
		max_shots=maxi(b.shots.size(),max_shots)
		if b.tick%100==0: snapshots[str(b.tick)]=digest(b)
	snapshots[str(b.tick)]=digest(b)
	var out:={"seed":Battle.SEED,"side":side,"tag":tag,"ticks":b.tick,"report":b.report(),"gate_damage_tick":gate_at,
		"breach_tick":breach,"ram_near_tick":ram_at,"peak_active_shots":max_shots,"mounted_roster":cavalry,"charging_ticks":charging_ticks,
		"state_sha256":snapshots,"step_us":steps,"flags":flags,"phase_names":names,"phase_us":phases,"clock":"Godot Time.get_ticks_usec; one 50 ms simulation tick, not render frames"}
	var f:=FileAccess.open(OS.get_environment("TAIL_OUT"),FileAccess.WRITE)
	if f==null: quit(2); return
	f.store_string(JSON.stringify(out))
	f.close()
	if b.tick<100 or b.attacks==0 or b.hits[0]+b.hits[1]==0: quit(3); return
	print("TAIL_TRACE ",tag," ",side," ticks=",b.tick," hits=",b.hits," gate=",gate_at," breach=",breach)
	quit(0)
