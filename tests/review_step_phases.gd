extends SceneTree
const Battle:=preload("res://scripts/field/battle.gd")
const Arms:=preload("res://scripts/field/arms.gd")

func _initialize() -> void:
	var first:Dictionary={}
	for replay in 4:
		var b:=Battle.new()
		b.setup(512,Battle.SEED,Arms.Kit.BOW)
		b.start()
		b.command(0,Battle.Mission.PRESS,Battle.Channel.HORN)
		var elapsed:=[]
		for step in 465:
			var begin:=Time.get_ticks_usec()
			b.step()
			var end:=Time.get_ticks_usec()
			if b.tick>=280:
				elapsed.append([b.tick,end-begin,Array(b.review_phases)])
		var state:=b.report()
		if replay==0: first=state
		if state!=first or state.ordinary_rosters!=[512,512] or b.tick!=465 or b.hits[0]<=0 or b.hits[1]<=0:
			printerr("The repeated engagement diverged")
			quit(1)
			return
		print("STEP_PHASES ",JSON.stringify({"pass":replay,"state":state,"ticks":elapsed}))
	quit(0)
