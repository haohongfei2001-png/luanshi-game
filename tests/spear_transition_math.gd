extends SceneTree
const Tracker=preload("res://scripts/field/experimental/spear_transition.gd")
const Palette=preload("res://scripts/field/experimental/spear_palette.gd")
var checks:=0

func check(ok:bool,message:String) -> void:
	checks+=1
	if not ok:
		push_error(message)
		quit(1)
		assert(ok,message)

func vector(a:Array) -> Vector3:
	return Vector3(a[0],a[1],a[2])

func model(row:Dictionary) -> Transform3D:
	var m:Array=row["instance"]["transform"]
	return Transform3D(Basis(vector(m[0]),vector(m[1]),vector(m[2])),vector(m[3]))

func data(row:Dictionary) -> Color:
	var a:Array=row["instance"]["custom"]
	return Color(a[0],a[1],a[2],a[3])

func point(m:Transform3D,side:int) -> Vector3:
	return m*Vector3(float(side)*.141,.123,-.016)

func plain_clip(clip:int,phase:float) -> Color:
	return Color(.5/128.,(float(clip)+.5)/32.,phase,.8818359375)

func _initialize() -> void:
	var path:=OS.get_environment("SPEAR_TEST_PALETTE")
	if path.is_empty(): path="res://assets/river_gate/figures/company_motion.png"
	var sampler:=Palette.new(Image.load_from_file(path))
	var sequence:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/native-spear-rejected/after.json"))
	var reference:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/native-spear-rejected/actual-ankles.json"))
	var label:="after" if sampler.native_pike else "before"
	var tracker:=Tracker.new()
	var rows:Array=[]
	var previous:Array[Vector3]=[]
	var previous_clip:=-1
	var worst_strain:=0.
	var worst_seam:=0.
	var lowest_sole:=INF
	for i:int in sequence["index"].size():
		var row:Dictionary=sequence["index"][i]
		var transform:=model(row)
		var custom:=data(row)
		var poses:=sampler.poses(custom)
		var clip:=int(sampler.address(custom).z)
		var offsets:=tracker.sample(poses,transform,clip,float(row["tick"])*.05)
		var feet:Array[Vector3]=[]
		var steps:Array=[]
		for side:int in [-1,1]:
			var bone:=11 if side<0 else 14
			var shin:=10 if side<0 else 13
			var original:=point(transform*poses[bone],side)
			var expected:=vector(reference[label]["frames"][i]["ankles"][str(side)])
			check(original.distance_to(expected)<.0001,"palette sampler disagrees with preserved Godot-instance replay")
			var corrected:=transform*Tracker.plus(poses[bone],offsets[bone])
			var ankle:=point(corrected,side)
			feet.append(ankle)
			worst_seam=maxf(worst_seam,ankle.distance_to(point(transform*Tracker.plus(poses[shin],offsets[shin]),side)))
			for axis:Vector3 in [corrected.basis.x,corrected.basis.y,corrected.basis.z]:
				worst_strain=maxf(worst_strain,absf(axis.length()/transform.basis.x.length()-1.))
			for dx:float in [-.05,.05]:
				for dz:float in [-.072,.187]:
					lowest_sole=minf(lowest_sole,(corrected*(Vector3(float(side)*.141,.123,-.016)+Vector3(dx,-.117,dz))).y)
			if not previous.is_empty():
				var step:=ankle.distance_to(previous[feet.size()-1])
				steps.append(step)
				if clip!=previous_clip: check(step<.00001,"new clip must begin at previous displayed pose")
		rows.append({"tick":row["tick"],"clip":clip,"ankles":feet.map(func(v:Vector3):return [v.x,v.y,v.z]),"step_m":steps})
		previous=feet
		previous_clip=clip
	# Exercise every movement heading, phase seam and interrupt at render rates.
	var synthetic:=0
	for direction:int in 8:
		for running:bool in [false,true]:
			var probe:=Tracker.new()
			var before:Array[Transform3D]=[]
			for n:int in 30:
				var gait:=(23+direction) if running else (0 if direction==0 else 15+direction)
				# Switch every three frames, faster than the .15 s transition.
				var clip:=gait if (n/3)%2==0 else 1
				var poses:=sampler.poses(plain_clip(clip,fposmod(float(n)*.067,1.)))
				var transform:=Transform3D(Basis(Vector3.UP,float(direction)*PI/4.),Vector3(float(n)*.013,0,0))
				probe.sample(poses,transform,clip,float(n)/60.)
				if n>0 and n%3==0:
					for bone:int in [11,14]: check(point(probe.previous[bone],1).distance_to(point(before[bone],1))<.00001,"interrupted transition continuity")
				before=probe.previous.duplicate()
				synthetic+=1
	# Incoming motion continues during the blend; this is not a frozen-foot pose.
	var moving:=Tracker.new()
	var p:=sampler.poses(plain_clip(1,0.))
	moving.sample(p,Transform3D.IDENTITY,1,0.)
	var incoming:=sampler.poses(plain_clip(0,.2))
	moving.sample(incoming,Transform3D.IDENTITY,0,.05)
	var start:=moving.previous[11].origin
	incoming[11].origin+=Vector3(.1,0,0)
	moving.sample(incoming,Transform3D.IDENTITY,0,.075)
	check(moving.previous[11].origin.distance_to(start)>.01,"incoming swing must remain moving")
	moving.sample(incoming,Transform3D.IDENTITY,0,.25)
	check(moving.previous[11].origin.distance_to(incoming[11].origin)<.00001,"transition must expire exactly")
	var report:={"palette":label,"actual_capture_frames":rows.size(),"actual_frames":rows,"synthetic_direction_interrupt_samples":synthetic,
		"checks":checks,"duration_s":Tracker.DURATION,"worst_boot_basis_strain":worst_strain,"shin_boot_gap_m":worst_seam,"lowest_boot_sole_y":lowest_sole,
		"verdict":"EXPERIMENT_ONLY_NOT_ACCEPTED","godot_visual_pass":false,
		"limits":"Bone-space affine inertialization can strain limbs; post-skin torso lean and cloth are not reconstructed. Not contact IK."}
	DirAccess.make_dir_recursive_absolute("res://artifacts")
	FileAccess.open("res://artifacts/spear-transition-"+label+".json",FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
	print("SPEAR_TRANSITION_MATH ",JSON.stringify({"checks":checks,"synthetic_samples":synthetic,"worst_boot_basis_strain":worst_strain,"lowest_boot_sole_y":lowest_sole,"shin_boot_gap_m":worst_seam}))
	quit()
