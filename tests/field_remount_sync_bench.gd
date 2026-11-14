extends SceneTree
## Isolate the drawing cost on one real battle state, with settled loose horses.
## This headless CPU sample excludes Godot drawing, GPU submission and troop AI.
const Field:=preload("res://scripts/field/battle.gd")
const View:=preload("res://scripts/field/presentation.gd")
const Ground:=preload("res://scripts/field/ground.gd")

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var b:=Field.new()
	b.setup(512,Field.SEED,3,true,true,512,true)
	b.start()
	for i in 210: b.step()
	var cam:=Camera3D.new()
	cam.projection=Camera3D.PROJECTION_ORTHOGONAL
	cam.size=22.
	root.add_child(cam)
	cam.make_current()
	var center:=Ground.BRIDGE_VIEW
	var p:=Ground.unit_point(center,true)
	var yaw:=deg_to_rad(-33.)
	var pitch:=.886198
	cam.position=p+Vector3(sin(yaw)*cos(pitch),sin(pitch),cos(yaw)*cos(pitch))*77.5
	cam.look_at(p)
	var view:=View.new()
	root.add_child(view)
	view.configure(b)
	var timings:Array[int]=[]
	var empty:=0
	for u in b.roster:
		if u.mounted and u.state==Field.State.DEAD and u.mount_hp>0.: empty+=1
	for i in 330:
		# Three 60 Hz draws accompany one ordinary 20 Hz field step.
		if i%3==0: b.step()
		var alpha:float=float(i%3)/3.
		var start:=Time.get_ticks_usec()
		view.sync_view(center,Vector2(30,27),alpha,22.)
		var cost:=Time.get_ticks_usec()-start
		if i>=30: timings.append(cost)
	timings.sort()
	var n:=timings.size()
	print("MOUNT_SYNC ",JSON.stringify({"samples":n,"p50_us":timings[int(n*.50)],"p95_us":timings[int(n*.95)],"p99_us":timings[int(n*.99)],"tick":b.tick,"living_unseated":empty,"seed":b.rng.seed,"ordinary":Array(b.ordinary_counts),"visible":view.visible_soldiers,"damage":Array(b.hits),"losses":Array(b.losses)}))
	view.free()
	cam.free()
	quit()
