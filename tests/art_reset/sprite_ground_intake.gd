extends SceneTree
## Imported terrain support parity, not graphical acceptance.
const Ground:=preload("res://scripts/field/ground.gd")
func _initialize() -> void: run.call_deferred()
func run() -> void:
	var args:=OS.get_cmdline_user_args();assert(args.size() in [1,2])
	var expected_vertices:=5070;var expected_triangles:=9856
	if args.size()==2:
		var report:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(args[1]))
		expected_vertices=int(report["source_vertices"])
		if report.has("derived_triangles"):expected_triangles=int(report["derived_triangles"])
		else:
			var crop:Array=report.get("safe_core_crop_local_y",[])
			assert(expected_vertices==3849 and int(report.get("source_polygons",0))==3724 and crop.size()==2 and float(crop[0])==-8. and float(crop[1])==8.,"Unknown legacy receipt, no guessed triangles")
			expected_triangles=7448
	var doc:=GLTFDocument.new();var state:=GLTFState.new()
	assert(doc.append_from_file(args[0],state)==OK)
	var scene:=doc.generate_scene(state);assert(scene);root.add_child(scene)
	var vertices:=0;var worst:=0.0;var triangles:=0;var meshes:=0;var faces:=[]
	for node:MeshInstance3D in scene.find_children("*","MeshInstance3D",true,false):
		meshes+=1
		for surface:int in node.mesh.get_surface_count():
			var arrays:=node.mesh.surface_get_arrays(surface)
			triangles+=int(arrays[Mesh.ARRAY_INDEX].size()/3)
			var indices:PackedInt32Array=arrays[Mesh.ARRAY_INDEX]
			var points:PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
			for index in range(0,indices.size(),3):
				faces.append([node.global_transform*points[indices[index]],node.global_transform*points[indices[index+1]],node.global_transform*points[indices[index+2]]])
			for vertex:Vector3 in arrays[Mesh.ARRAY_VERTEX]:
				var p:=node.global_transform*vertex;vertices+=1
				assert(p.x>=29.599 and p.x<=46.601 and abs(p.z)<=24.001)
				var xz:=Vector2(p.x,p.z)
				var expected:=Ground.height(xz,true)-Ground.MOAT_BED_DEPTH*Ground.moat_depth(xz)
				worst=maxf(worst,absf(p.y-expected))
	assert(meshes==1 and vertices>=expected_vertices and triangles==expected_triangles,"Geometry differs from conversion receipt")
	assert(worst<.015,"Imported vertex deviates from shared gameplay ground")
	var holes:=0;var interior_error:=0.0;var checked:=0
	for xi in 33:
		for zi in 15:
			var p:=Vector2(30.+xi*.5,-3.5+zi*.5);var found:=false
			for face:Array in faces:
				var a:Vector3=face[0];var b:Vector3=face[1];var c:Vector3=face[2]
				var av:=Vector2(a.x,a.z);var bv:=Vector2(b.x,b.z);var cv:=Vector2(c.x,c.z)
				var den:float=(bv-av).cross(cv-av)
				if absf(den)<.0000001:continue
				var u:float=(p-av).cross(cv-av)/den;var v:float=(bv-av).cross(p-av)/den
				if u>=-.00001 and v>=-.00001 and u+v<=1.00001:
					var y:=a.y*(1.-u-v)+b.y*u+c.y*v
					var expected:=Ground.height(p,true)-Ground.MOAT_BED_DEPTH*Ground.moat_depth(p)
					interior_error=maxf(interior_error,absf(y-expected));found=true;break
			checked+=1
			if not found:holes+=1
	print("GROUND_ROUTE_SUPPORT ",JSON.stringify({"sample_count":checked,"holes":holes,"max_interpolated_error_m":interior_error}))
	assert(holes==0 and interior_error<.05,"Authored ground cannot yet cover the protected route")
	print("SPRITE_GROUND_INTAKE ",JSON.stringify({"vertices":vertices,"triangles":triangles,"max_vertex_height_error_m":worst,"interior_triangle_support":"495 protected-route samples; not exhaustive","graphics":"NOT_RUN"}))
	scene.free();quit()
