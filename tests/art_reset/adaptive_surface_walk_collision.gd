extends SceneTree
const Ground:=preload("res://scripts/field/ground.gd")
const Surface:=preload("res://tools/art/authored_reset/surface_authoring.gd")
func _initialize() -> void: run.call_deferred()
func run() -> void:
	assert(Ground.authored_landform_enabled)
	var args:=OS.get_cmdline_user_args();assert(args.size()==1)
	var packed:=load(args[0]) as PackedScene;assert(packed)
	var scene:=packed.instantiate() as Node3D;root.add_child(scene)
	await physics_frame;await physics_frame
	var space:=scene.get_world_3d().direct_space_state
	var checked:=0;var maximum:=0.;var total_distance:=0.
	# Existing Ground.travel rules, then actual PhysicsServer rays against the
	# packed terrain colliders, not a second analytical mock collision function.
	for route:Array in [[Vector2(-23.3,8.16),Vector2(3,2)],[Vector2(30,0),Vector2(16,0)],[Vector2(34,8),Vector2(6,2)]]:
		var p:Vector2=route[0];var delta:Vector2=route[1]/120.
		for tick in 120:
			var next:=Ground.travel(p,delta,true,true);total_distance+=p.distance_to(next);p=next
			assert(not Ground.blocked(p,true,true))
			var expected:=Ground.unit_point(p,true)
			assert(absf(expected.y-Surface.height(p))<.00001,"Do not pretend terrain-only test includes bridge/wall decks")
			var query:=PhysicsRayQueryParameters3D.create(expected+Vector3.UP*3.,expected-Vector3.UP*3.)
			var hit:=space.intersect_ray(query);assert(not hit.is_empty(),"Missing physical support at "+str(p))
			var error:=absf(float(hit.position.y)-expected.y);maximum=maxf(maximum,error)
			assert(error<.02,"Foot/support gap exceeds 2cm at "+str(p)+" gap="+str(error));checked+=1
	assert(checked==360 and total_distance>20.)
	print("ADAPTIVE_TRAVEL_COLLISION_PASS ",JSON.stringify({"travel_samples":checked,"distance_m":total_distance,"maximum_collision_gap_m":maximum,"physics":"actual PhysicsServer ray hits","animated_gameplay":"NOT_RUN"}))
	scene.free();await physics_frame;quit()
