extends SceneTree
const Ground:=preload("res://scripts/field/ground.gd")
const Surface:=preload("res://tools/art/authored_reset/surface_authoring.gd")
func _initialize() -> void: run.call_deferred()
func run() -> void:
	assert(Ground.authored_landform_enabled)
	var args:=OS.get_cmdline_user_args();assert(args.size()==1)
	var packed:=load(args[0]) as PackedScene;assert(packed)
	var scene:=packed.instantiate();root.add_child(scene)
	assert(scene.get_meta("survey_bounds")==Rect2(-144.,-112.,304.,224.))
	assert(float(scene.get_meta("survey_step_m"))==.5)
	var terrains:=0;var shapes:=0;var water_triangles:=0;var max_water_dry:=0.;var max_support_error:=0.;var max_reachable_error:=0.;var reachable_samples:=0;var worst_reachable:=Vector2.ZERO
	for mesh:MeshInstance3D in scene.find_children("*","MeshInstance3D",true,false):
		var arrays:=mesh.mesh.surface_get_arrays(0);var vertices:PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
		if mesh.name=="SurveyContourWater_NO_RECTANGLE":
			water_triangles=vertices.size()/3
			for i in range(0,vertices.size(),3):
				assert((vertices[i+1]-vertices[i]).cross(vertices[i+2]-vertices[i]).y<0.,"Water front faces point down")
				var p:Vector3=(vertices[i]+vertices[i+1]+vertices[i+2])/3.
				assert(absf(p.y-Ground.BATTLE_WATER_LEVEL)<.00001)
				max_water_dry=maxf(max_water_dry,Surface.height(Vector2(p.x,p.z))-p.y)
		else:
			terrains+=1;var indices:PackedInt32Array=arrays[Mesh.ARRAY_INDEX]
			for v:Vector3 in vertices:assert(absf(v.y-Surface.height(Vector2(v.x,v.z)))<.00001)
			for i in range(0,indices.size(),3):
				var p:Vector3=(vertices[indices[i]]+vertices[indices[i+1]]+vertices[indices[i+2]])/3.
				var planar:=Vector2(p.x,p.z)
				if absf(planar.x)<=Ground.LIMIT.x and absf(planar.y)<=Ground.LIMIT.y and not Ground.blocked(planar,true,true) and absf(Ground.deck_height(planar,true)-Surface.height(planar))<.00001:
					reachable_samples+=1
					var error:=absf(p.y-Surface.height(planar))
					if error>max_reachable_error:max_reachable_error=error;worst_reachable=planar
				if p.x>=29.95 and p.x<=46.6 and absf(p.z)<=3.7:max_support_error=maxf(max_support_error,absf(p.y-Surface.height(Vector2(p.x,p.z))))
	for collision:CollisionShape3D in scene.find_children("*","CollisionShape3D",true,false):
		assert(collision.shape is ConcavePolygonShape3D);shapes+=1
	assert(terrains==266 and shapes==266 and water_triangles>1000)
	print("SURFACE_SAMPLE_DIAGNOSTIC ",JSON.stringify({"max_water_dry":max_water_dry,"max_route_error":max_support_error,"max_reachable_error":max_reachable_error,"worst_reachable":[worst_reachable.x,worst_reachable.y]}))
	assert(max_water_dry<.05 and max_support_error<.02,"Surface sampling insufficient")
	if scene.has_meta("adaptive_cell_distribution"):
		assert(max_reachable_error<.012,"Adaptive reachable terrain error exceeds 1.2cm")
	print("LANDFORM_MESH_PASS ",JSON.stringify({"terrain_tiles":terrains,"collision_shapes":shapes,"water_triangles":water_triangles,"max_water_contour_error_m":max_water_dry,"max_route_interpolation_error_m":max_support_error,"reachable_surface_samples":reachable_samples,"max_reachable_interpolation_error_m":max_reachable_error,"worst_reachable_xz":[worst_reachable.x,worst_reachable.y],"graphics":"NOT_RUN"}))
	scene.free();quit()
