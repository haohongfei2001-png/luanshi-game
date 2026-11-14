extends SceneTree
const Footprint = preload("res://scripts/field/experimental/frustum_footprint.gd")
var failures: Array = []
var checks := 0
var samples := 0
var visible := 0
func _initialize() -> void:
	run.call_deferred()
func check(test: bool, context: String) -> void:
	checks += 1
	if not test:
		failures.append(context)
func run() -> void:
	var view := SubViewport.new()
	view.size = Vector2i(2560,1440)
	view.own_world_3d = true
	root.add_child(view)
	var camera := Camera3D.new()
	view.add_child(camera)
	camera.current = true
	camera.near = .1
	camera.far = 180.
	var rng := RandomNumberGenerator.new()
	rng.seed = 61112
	var cases := 0
	var configurations: Array = []
	for projection in [Camera3D.PROJECTION_ORTHOGONAL,Camera3D.PROJECTION_PERSPECTIVE,Camera3D.PROJECTION_FRUSTUM]:
		for pitch in [18.,38.,51.,65.]:
			for yaw in [-33.,0.,87.]:
				configurations.append([projection,pitch,yaw])
	for configuration in configurations:
		camera.projection = configuration[0]
		camera.size = 16.
		camera.fov = 50.
		camera.frustum_offset = Vector2(.15,-.08) if camera.projection == Camera3D.PROJECTION_FRUSTUM else Vector2.ZERO
		camera.keep_aspect = Camera3D.KEEP_HEIGHT
		var pitch := deg_to_rad(configuration[1])
		var yaw := deg_to_rad(configuration[2])
		var anchor := Vector3(34.2,0,1.)
		var distance := 45. if camera.projection == Camera3D.PROJECTION_ORTHOGONAL else 21.
		camera.position = anchor + Vector3(sin(yaw)*cos(pitch),sin(pitch),cos(yaw)*cos(pitch))*distance
		camera.look_at(anchor)
		await process_frame
		var result := Footprint.bounds(camera,-2.,8.,.8)
		check(result.valid,"no footprint: "+str(configuration))
		if not result.valid:
			continue
		var rect: Rect2 = result.rect
		check(rect.size.x>0 and rect.size.y>0,"invalid area: "+str(configuration))
		for i in 6000:
			var p := Vector3(rng.randf_range(-85,110),rng.randf_range(-2,8),rng.randf_range(-110,110))
			samples += 1
			if camera.is_position_in_frustum(p):
				visible += 1
				check(rect.has_point(Vector2(p.x,p.z)),"visible point culled: "+str(configuration)+" "+str(p))
		cases += 1
	# Parallel/horizon rays are explicitly supported, not silently discarded.
	camera.projection=Camera3D.PROJECTION_PERSPECTIVE
	camera.position=Vector3(0,5,0)
	camera.look_at(Vector3(0,5,-1))
	await process_frame
	var horizon := Footprint.bounds(camera,-2.,8.,0.)
	check(horizon.valid,"horizon view should intersect slab")
	check(horizon.rect.has_point(Vector2(0,-120)),"far visible horizon point not covered")
	camera.position=Vector3(0,200,0)
	camera.look_at(Vector3(0,201,0),Vector3.FORWARD)
	await process_frame
	var above := Footprint.bounds(camera,-2.,8.,0.)
	check(not above.valid,"upward frustum wrongly intersects world")
	# Legacy orthographic flat-ground formula parity at yaw=-33/pitch=50.775.
	camera.projection=Camera3D.PROJECTION_ORTHOGONAL
	camera.size=22.;camera.frustum_offset=Vector2.ZERO
	var a:=Vector3(34.2,0,1);var p:=deg_to_rad(50.77539);var y:=deg_to_rad(-33.)
	camera.position=a+Vector3(sin(y)*cos(p),sin(p),cos(y)*cos(p))*77.5;camera.look_at(a)
	await process_frame
	var flat:=Footprint.bounds(camera,0.,0.,0.)
	var hw:=camera.size*2560./1440.*.5;var hd:=camera.size*.5/sin(p)
	var expected:=Vector2(abs(cos(y))*hw+abs(sin(y))*hd,abs(sin(y))*hw+abs(cos(y))*hd)
	check(flat.valid,"flat legacy footprint invalid")
	check(flat.center.distance_to(Vector2(a.x,a.z))<.001,"flat legacy center changed")
	check(flat.half_extent.distance_to(expected)<.001,"flat legacy extents differ")
	var report := {"test":"actual Camera3D frustum-height-slab coverage, no renderer or art verdict","engine":Engine.get_version_info(),"cases":cases,"sampled_points":samples,"visible_points":visible,"checks":checks,"failures":failures,"gameplay_modified":false,"art_pass":false}
	var destination:=OS.get_environment("CAMERA_CONTRACT_OUTPUT")
	if not destination.is_empty():
		FileAccess.open(destination,FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
	print("CAMERA_FOOTPRINT_CONTRACT ",JSON.stringify(report))
	quit(0 if failures.is_empty() else 1)
