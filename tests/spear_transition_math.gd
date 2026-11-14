extends SceneTree
const Tracker=preload("res://scripts/field/experimental/spear_transition.gd")
const Rigid=preload("res://scripts/field/experimental/spear_rigid_transition.gd")
const Shaft=preload("res://scripts/field/experimental/spear_shaft_transition.gd")
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
	var shaft_mode:=OS.get_environment("SPEAR_SHAFT")=="1"
	var rigid:=OS.get_environment("SPEAR_RIGID")=="1" or shaft_mode
	var tracker:=Shaft.new() if shaft_mode else (Rigid.new() if rigid else Tracker.new())
	var rows:Array=[]
	var previous:Array[Vector3]=[]
	var previous_clip:=-1
	var worst_strain:=0.
	var transition_jumps:Array=[]
	var maximum_support_lift:=0.
	var maximum_wrist_gap:=0.
	var maximum_arm_strain:=0.
	var maximum_reach_error:=0.
	var maximum_grip_axis_error:=0.
	var original_grip_axis_error:=0.
	var worst_seam:=0.
	var lowest_sole:=INF
	for i:int in sequence["index"].size():
		var row:Dictionary=sequence["index"][i]
		var transform:=model(row)
		var custom:=data(row)
		var poses:=sampler.poses(custom)
		var clip:=int(sampler.address(custom).z)
		var offsets:=tracker.sample(poses,transform,clip,float(row["tick"])*.05)
		if rigid: maximum_support_lift=maxf(maximum_support_lift,tracker.last_support_lift)
		if shaft_mode: maximum_reach_error=maxf(maximum_reach_error,tracker.last_reach_error)
		for hand:int in [5,8]:
			var wrist:Vector3=Rigid.PIVOTS[hand]
			var palm_pose:=transform*Tracker.plus(poses[hand],offsets[hand])
			var fore_pose:=transform*Tracker.plus(poses[hand-1],offsets[hand-1])
			maximum_wrist_gap=maxf(maximum_wrist_gap,(palm_pose*wrist).distance_to(fore_pose*wrist))
			for bone:int in [hand-2,hand-1,hand]:
				var shown:=transform*Tracker.plus(poses[bone],offsets[bone])
				for axis:Vector3 in [shown.basis.x,shown.basis.y,shown.basis.z]:
					maximum_arm_strain=maxf(maximum_arm_strain,absf(axis.length()/transform.basis.x.length()-1.))
		var source_right:=transform*poses[8]
		var source_left:=transform*poses[5]
		var source_axis:=source_right.basis.z.normalized()
		var source_gap:=source_left*Vector3(-.273,.943,.075)-source_right*Vector3(.273,.943,.075)
		original_grip_axis_error=maxf(original_grip_axis_error,(source_gap-source_axis*source_gap.dot(source_axis)).length())
		var right:=transform*Tracker.plus(poses[8],offsets[8])
		var left:=transform*Tracker.plus(poses[5],offsets[5])
		var shaft:=right.basis.z.normalized()
		var between:=left*Vector3(-.273,.943,.075)-right*Vector3(.273,.943,.075)
		maximum_grip_axis_error=maxf(maximum_grip_axis_error,(between-shaft*between.dot(shaft)).length())
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
				if clip!=previous_clip:
					transition_jumps.append({"tick":row["tick"],"side":side,"step_m":step})
					if not rigid: check(step<.00001,"new clip must begin at previous displayed pose")
		rows.append({"tick":row["tick"],"clip":clip,"ankles":feet.map(func(v:Vector3):return [v.x,v.y,v.z]),"step_m":steps})
		previous=feet
		previous_clip=clip
	# Exercise every movement heading, phase seam and interrupt at render rates.
	var synthetic:=0
	for direction:int in 8:
		for running:bool in [false,true]:
			var probe:=Shaft.new() if shaft_mode else (Rigid.new() if rigid else Tracker.new())
			var before:Array[Transform3D]=[]
			for n:int in 30:
				var gait:=(23+direction) if running else (0 if direction==0 else 15+direction)
				# Switch every three frames, faster than the .15 s transition.
				var clip:=gait if (n/3)%2==0 else 1
				if shaft_mode: clip=[gait,2,6,10,1][(n/3)%5]
				var poses:=sampler.poses(plain_clip(clip,fposmod(float(n)*.067,1.)))
				var transform:=Transform3D(Basis(Vector3.UP,float(direction)*PI/4.),Vector3(float(n)*.013,0,0))
				probe.sample(poses,transform,clip,float(n)/60.)
				if not rigid and n>0 and n%3==0:
					for bone:int in [11,14]: check(point(probe.previous[bone],1).distance_to(point(before[bone],1))<.00001,"interrupted transition continuity")
				if shaft_mode:
					for hand:int in [5,8]:
						var wrist:Vector3=Rigid.PIVOTS[hand]
						check((probe.previous[hand]*wrist).distance_to(probe.previous[hand-1]*wrist)<.002,"synthetic attack/recovery/guard wrist seam")
					if clip in [0,1,2,6] or clip>=16:
						var axis:=probe.previous[8].basis.z.normalized()
						var gap:=Shaft.grip(probe.previous[5],-1)-Shaft.grip(probe.previous[8],1)
						check((gap-axis*gap.dot(axis)).length()<.002,"synthetic shared shaft grip")
				if rigid:
					for bone:int in [11,14]:
						check(absf(probe.previous[bone].basis.x.length()-1.)<.00001,"synthetic direction preserves rigid boot scale")
						check(probe.previous[bone].origin.is_finite(),"synthetic interruption remains finite")
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
	if rigid:
		var rigid_motion:=Rigid.new()
		var still:=sampler.poses(plain_clip(1,0.))
		rigid_motion.sample(still,Transform3D.IDENTITY,1,0.)
		var walk:=sampler.poses(plain_clip(0,.1))
		rigid_motion.sample(walk,Transform3D.IDENTITY,0,.05)
		var began:=point(rigid_motion.previous[11],-1)
		walk=sampler.poses(plain_clip(0,.25))
		rigid_motion.sample(walk,Transform3D.IDENTITY,0,.075)
		check(point(rigid_motion.previous[11],-1).distance_to(began)>.001,"rigid incoming swing is not frozen")
		rigid_motion.sample(walk,Transform3D.IDENTITY,0,.25)
		check(point(rigid_motion.previous[11],-1).distance_to(point(walk[11],-1))<.00001,"rigid decay expires to exact source")
		check(worst_strain<.0001,"quaternion correction must preserve all boot axis lengths")
		check(worst_seam<.001,"connected limb chain must preserve ankle seam")
	if shaft_mode:
		check(maximum_grip_axis_error<.002,"actual capture shaft must remain registered")
		check(maximum_wrist_gap<.002,"actual capture wrist seam must remain registered")
		check(maximum_arm_strain<.0001,"actual capture arm lengths remain rigid")
		check(lowest_sole>=0.,"old planar fixture support remains above original plane")
		var old_rigid:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://docs/evidence/spear-contact-audit/rigid/spear-transition-"+label+"-rigid.json"))
		for i:int in rows.size():
			for foot:int in 2:
				check(vector(rows[i]["ankles"][foot]).distance_to(vector(old_rigid["actual_frames"][i]["ankles"][foot]))<.000001,"arm repair must not change rigid iteration feet")
	var rejection_reasons:Array=[]
	if worst_strain>.005: rejection_reasons.append("bone_scale_distortion_over_0.5_percent")
	if lowest_sole<-.001: rejection_reasons.append("boot_penetration_over_1mm")
	if maximum_grip_axis_error>.002: rejection_reasons.append("two_hand_axis_error_over_2mm")
	if maximum_wrist_gap>.002: rejection_reasons.append("wrist_seam_over_2mm")
	if maximum_arm_strain>.005: rejection_reasons.append("arm_scale_distortion_over_0.5_percent")
	var report:={"shaft_mode":shaft_mode,"maximum_wrist_gap_m":maximum_wrist_gap,"maximum_arm_basis_strain":maximum_arm_strain,"maximum_reach_error_m":maximum_reach_error,"activation_allowed":false,"rejection_reasons":rejection_reasons,"rigid":rigid,"transition_jumps":transition_jumps,"maximum_support_lift_m":maximum_support_lift,"maximum_grip_axis_error_m":maximum_grip_axis_error,"original_grip_axis_error_m":original_grip_axis_error,"palette":label,"actual_capture_frames":rows.size(),"actual_frames":rows,"synthetic_direction_interrupt_samples":synthetic,
		"checks":checks,"duration_s":Tracker.DURATION,"worst_boot_basis_strain":worst_strain,"shin_boot_gap_m":worst_seam,"lowest_boot_sole_y":lowest_sole,
		"verdict":"EXPERIMENT_ONLY_NOT_ACCEPTED","godot_visual_pass":false,
		"limits":"Rigid mode preserves lengths but two-hand shaft registration can fail; affine mode can strain limbs. Post-skin torso lean/cloth not reconstructed. Not contact IK."}
	DirAccess.make_dir_recursive_absolute("res://artifacts")
	FileAccess.open("res://artifacts/spear-transition-"+label+("-shaft" if shaft_mode else ("-rigid" if rigid else ""))+".json",FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
	print("SPEAR_TRANSITION_MATH ",JSON.stringify({"checks":checks,"synthetic_samples":synthetic,"shaft_mode":shaft_mode,"maximum_wrist_gap_m":maximum_wrist_gap,"maximum_arm_basis_strain":maximum_arm_strain,"maximum_reach_error_m":maximum_reach_error,"rigid":rigid,"maximum_support_lift_m":maximum_support_lift,"maximum_grip_axis_error_m":maximum_grip_axis_error,"original_grip_axis_error_m":original_grip_axis_error,"worst_boot_basis_strain":worst_strain,"lowest_boot_sole_y":lowest_sole,"shin_boot_gap_m":worst_seam}))
	quit()
