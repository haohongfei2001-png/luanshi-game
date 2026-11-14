extends SceneTree
## Replay a REAL capture's frozen projection and pose against actual terrain
## colliders. This is a geometry diagnostic, not a rendered visibility/art pass:
## walls, foliage, water and occlusion are deliberately absent.
func _initialize() -> void: run.call_deferred()
func v3(values:Array) -> Vector3:return Vector3(values[0],values[1],values[2])
func v4(values:Array) -> Vector4:return Vector4(values[0],values[1],values[2],values[3])
func run() -> void:
	var args:=OS.get_cmdline_user_args();assert(args.size()==3,"terrain.scn real-receipt.json output.json")
	var packed:=load(args[0]) as PackedScene;assert(packed)
	var terrain:=packed.instantiate() as Node3D;root.add_child(terrain)
	await physics_frame;await physics_frame
	var rows:Array=JSON.parse_string(FileAccess.get_file_as_string(args[1]));var results:Array=[]
	for row:Dictionary in rows:
		var columns:Array=row.camera_projection
		var inverse:=Projection(v4(columns[0]),v4(columns[1]),v4(columns[2]),v4(columns[3])).inverse()
		var b:Array=row.camera_transform.basis
		var basis:=Basis(v3(b[0]),v3(b[1]),v3(b[2]));var origin:=v3(row.camera_transform.origin)
		var hit_count:=0;var missing:Array=[];var farthest:=0.;var top_hits:=0
		for y in 19:
			for x in 33:
				var uv:=Vector2(float(x)/32.,float(y)/18.)
				var local:=inverse*Vector4(uv.x*2.-1.,1.-uv.y*2.,-1.,1.)
				var ray:=basis*(Vector3(local.x,local.y,local.z)/local.w).normalized()
				var query:=PhysicsRayQueryParameters3D.create(origin,origin+ray*1000.)
				var hit:=terrain.get_world_3d().direct_space_state.intersect_ray(query)
				if hit.is_empty():missing.append([uv.x,uv.y])
				else:
					hit_count+=1;farthest=maxf(farthest,origin.distance_to(hit.position))
					if y<=2:top_hits+=1
		results.append({"view":row.view,"original_capture_source":row.source,"receipt_sha256":FileAccess.get_sha256(args[1]),"terrain_sha256":FileAccess.get_sha256(args[0]),"sample_count":627,"terrain_hits":hit_count,"top_three_rows_hits_of_99":top_hits,"missing_normalized_screen_samples":missing,"maximum_hit_distance_m":farthest,"scope":"GEOMETRY_ONLY_NO_WALL_TREE_WATER_OCCLUSION_NOT_GRAPHICS_ACCEPTANCE"})
	var f:=FileAccess.open(args[2],FileAccess.WRITE);assert(f);f.store_string(JSON.stringify(results,"\t"));f.close()
	print("CAMERA_TERRAIN_COVERAGE_DIAGNOSTIC ",JSON.stringify(results))
	terrain.free();await physics_frame;quit()
