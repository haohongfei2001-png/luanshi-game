extends SceneTree
const Map:=preload("res://scripts/field/river_pass_master.gd")
const Ground:=preload("res://scripts/field/ground.gd")
func _initialize() -> void:_run.call_deferred()
func _run() -> void:
	var map:=Map.new();map.bridgehead=true;root.add_child(map);await process_frame
	var audit:=map.composition_audit()
	assert(audit.layout=="river-pass-master-v1" and not audit.runtime_scattering)
	assert(audit.terrain_tiles==80 and audit.native_instances>400)
	for group:String in ["SculptedTerrain","RiverAndMoat","BridgesAndLandings","GateAndGarrison","RearSettlement","ForegroundRiparianWoodland","MiddleTerraceWoodland","RidgeForestAndCliffs","AuthoredShoreGroups","OuterRoadPavilions"]:
		assert(map.master.has_node(group),"Missing authored spatial layer "+group)
	assert(map.gate!=null and map.ram!=null and map.ram_beam!=null and not map.ram_wheels.is_empty())
	var sampled:=0;var max_error:=0.
	for tile:MeshInstance3D in map.master.get_node("SculptedTerrain").get_children():
		var arrays:Array=tile.mesh.surface_get_arrays(0)
		var vertices:PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
		for i in range(0,vertices.size(),17):
			var v:=vertices[i];var p:=Vector2(v.x,v.z)
			var expected:=map._land_height(p)
			max_error=maxf(max_error,absf(expected-v.y));sampled+=1
	assert(max_error<.0001,"Baked master and actor support geometry disagree")
	for mesh:MeshInstance3D in map.master.get_node("AuthoredShoreGroups").find_children("*","MeshInstance3D",true,false):
		assert(not "RockPath" in mesh.mesh.resource_name,"Compound rock carpets must not fill the channel")
		if "Rock_Medium" in mesh.mesh.resource_name:
			var bounds:AABB=mesh.global_transform*mesh.mesh.get_aabb()
			assert(maxf(bounds.size.x,bounds.size.z)<2.8,"Bank single-rock footprint exceeded authored bound")
	# This proves support-surface parity, NOT animated sole/ankle contact.
	print("RIVER_PASS_MASTER_PASS ",JSON.stringify({"audit":audit,"sampled_baked_vertices":sampled,"max_height_error":max_error,"animated_foot_contact":"NOT_RUN","graphics":"NOT_RUN"}))
	map.queue_free();await process_frame;quit(0)
