extends SceneTree
const Native:=preload("res://tools/art/sprite_source/assemble_woodland_region.gd")
func _initialize() -> void: run.call_deferred()
func run() -> void:
	var args:=OS.get_cmdline_user_args();assert(args.size()==2)
	var tree:=Native.load_native(args[0]);root.add_child(tree)
	var points:=PackedVector2Array();var per_surface:=[]
	for mesh:MeshInstance3D in tree.find_children("*","MeshInstance3D",true,false):
		for i in mesh.mesh.get_surface_count():
			var material:=mesh.mesh.surface_get_material(i);var name:=material.resource_name
			if name.contains("leaves"):continue
			var count:=0
			for v:Vector3 in mesh.mesh.surface_get_arrays(i)[Mesh.ARRAY_VERTEX]:
				var p:=mesh.global_transform*v
				if p.y>=-.05 and p.y<=2.0:points.append(Vector2(p.x,p.z));count+=1
			per_surface.append({"material":name,"included_wood_vertices":count})
	assert(points.size()>100)
	var hull:=Geometry2D.convex_hull(points);var padded:=Geometry2D.offset_polygon(hull,.35,Geometry2D.JOIN_MITER);assert(padded.size()==1)
	var polygon:PackedVector2Array=padded[0];var maximum_radius:=0.
	for p:Vector2 in points:assert(Geometry2D.is_point_in_polygon(p,polygon))
	var serial:=[]
	for p:Vector2 in polygon:serial.append([p.x,p.y]);maximum_radius=maxf(maximum_radius,p.length())
	var data:={"source_gltf_sha256":FileAccess.get_sha256(args[0]),"wood_surfaces":per_surface,"wood_vertex_samples":points.size(),"physical_projection_height_m":[-.05,2.0],"actor_clearance_m":.35,"local_xz_polygon":serial,"max_radius_m":maximum_radius,"policy":"conservative convex footprint of all original low wood, excluding leaves; not canopy AABB; .35m character centre clearance","source_transform":"original GLTF root transforms evaluated; world Y up","quality":"NAVIGATION_DERIVATION_NOT_ART_PASS"}
	FileAccess.open(args[1],FileAccess.WRITE).store_string(JSON.stringify(data,"  "));print("ORIGINAL_WOOD_FOOTPRINT ",JSON.stringify(data));tree.free();quit()
