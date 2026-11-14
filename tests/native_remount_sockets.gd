extends SceneTree
const MountArt:=preload("res://scripts/field/mount_art.gd")
func _initialize() -> void:
	var maximum_loop_gap:=0.
	var minimum_height:=INF
	var maximum_height:=-INF
	for gait: float in [0.,.1,.3,.6,1.]:
		for key in 65:
			var phase:=float(key)/64.
			var pose:=MountArt.saddle_pose(phase,gait)
			assert(pose.origin.is_finite())
			assert(pose.basis.determinant()>.95 and pose.basis.determinant()<1.05)
			var seat:=pose*MountArt.SADDLE
			minimum_height=minf(minimum_height,seat.y)
			maximum_height=maxf(maximum_height,seat.y)
			if gait==0.:
				assert(seat.distance_to(MountArt.SADDLE)<.00001)
		var first:=MountArt.saddle_pose(0.,gait)*MountArt.SADDLE
		var last:=MountArt.saddle_pose(1.,gait)*MountArt.SADDLE
		maximum_loop_gap=maxf(maximum_loop_gap,first.distance_to(last))
	assert(maximum_loop_gap<.025)
	assert(maximum_height-minimum_height>.01)
	for draught: bool in [false,true]:
		for close: bool in [false,true]:
			var mesh:=MountArt.mesh(draught,close)
			assert(mesh.get_surface_count()==1)
			assert(mesh.get_aabb().size.y>1.9)
	print("NATIVE_SADDLE_PASS ",JSON.stringify({"loop_gap_m":maximum_loop_gap,"seat_range_m":[minimum_height,maximum_height],"source":"full original hierarchy and shared CPU/GPU sockets"}))
	quit()
