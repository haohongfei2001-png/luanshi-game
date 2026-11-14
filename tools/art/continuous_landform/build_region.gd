extends SceneTree
## Default-OFF production scene. Physical mesh and visible mesh share one survey.
const Ground:=preload("res://scripts/field/ground.gd")
const Surface:=preload("res://tools/art/authored_reset/surface_authoring.gd")
const WATER:=Ground.BATTLE_WATER_LEVEL
var water_vertices:=PackedVector3Array()
func _initialize() -> void: run.call_deferred()
func own(node:Node,scene:Node) -> void:
	for child in node.get_children():child.owner=scene;own(child,scene)
func depth_clip(input:Array[Vector3]) -> Array[Vector3]:
	var output:Array[Vector3]=[]
	for i in input.size():
		var a:Vector3=input[i];var b:Vector3=input[(i+1)%input.size()]
		if a.y<=WATER:output.append(Vector3(a.x,WATER,a.z))
		if (a.y<=WATER)!=(b.y<=WATER):
			var t:float=(WATER-a.y)/(b.y-a.y)
			var crossing:Vector3=a.lerp(b,t);crossing.y=WATER;output.append(crossing)
	return output
func append_water(a:Vector3,b:Vector3,c:Vector3) -> void:
	var polygon:=depth_clip([a,b,c])
	for i in range(1,polygon.size()-1):water_vertices.append_array([polygon[0],polygon[i],polygon[i+1]])
func zone(p:Vector2) -> Color:
	var central:=1.-smoothstep(3.7,6.1,absf(p.y))
	var side_crossing:float=(1.-smoothstep(3.7,5.,absf(absf(p.y)-35.)))*(1.-smoothstep(7.,10.,absf(p.x+32.)))
	var road:=maxf(central,side_crossing)
	var drain:=1.-smoothstep(.6,1.7,absf(absf(p.y)-(6.65+.28*sin((p.x-30.)*.24))))
	drain*=smoothstep(29.95,32.3,p.x)*(1.-smoothstep(42.8,46.6,p.x))
	var woodland:=smoothstep(6.,11.,absf(p.y))
	return Color(road,drain,woodland,1.)
func run() -> void:
	var args:=OS.get_cmdline_user_args();assert(args.size() in [1,2],"Pass output.scn [verified earth directory]")
	assert(Ground.authored_landform_enabled,"Explicit LUANSHI_AUTHORED_LANDFORM=1 required")
	var scene:=Node3D.new();scene.name="ContinuousLandform_EXPERIMENT_OFF";scene.set_script(load("res://scripts/field/experimental_landform_guard.gd"));root.add_child(scene)
	scene.set_meta("composition","continuous-causeway-drainage-01")
	scene.set_meta("status","STRUCTURE_PRODUCTION_NOT_ART_ACCEPTED")
	scene.set_meta("required_environment","LUANSHI_AUTHORED_LANDFORM=1")
	var shader:=ShaderMaterial.new();shader.shader=load("res://shaders/experimental/surveyed_landform.gdshader")
	if args.size()==2:
		preload("res://tools/art/continuous_landform/earth_material.gd").attach(shader,args[1])
		scene.set_meta("earth_source","Poly Haven dirt / Charlotte Baglioni / CC0 / fixed SHA256")
	var terrain_triangles:=0;var tiles:=0
	for z in range(-48,48,16):
		for x in range(-48,64,16):
			var mesh:=Surface.tile(Vector2(x,z),16.,.5)
			var arrays:=mesh.surface_get_arrays(0)
			var vertices:PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
			var indices:PackedInt32Array=arrays[Mesh.ARRAY_INDEX];var colors:=PackedColorArray()
			for v:Vector3 in vertices:colors.append(zone(Vector2(v.x,v.z)))
			arrays[Mesh.ARRAY_COLOR]=colors;mesh.clear_surfaces();mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
			if args.size()==2:mesh=preload("res://tools/art/continuous_landform/earth_material.gd").with_tangents(mesh)
			var instance:=MeshInstance3D.new();instance.name="Survey_%s_%s"%[x,z];instance.mesh=mesh;instance.material_override=shader;scene.add_child(instance)
			instance.create_trimesh_collision()
			for i in range(0,indices.size(),3):append_water(vertices[indices[i]],vertices[indices[i+1]],vertices[indices[i+2]])
			terrain_triangles+=indices.size()/3;tiles+=1
	var water_arrays:=[];water_arrays.resize(Mesh.ARRAY_MAX);water_arrays[Mesh.ARRAY_VERTEX]=water_vertices
	var normals:=PackedVector3Array();normals.resize(water_vertices.size());normals.fill(Vector3.UP);water_arrays[Mesh.ARRAY_NORMAL]=normals
	var water_mesh:=ArrayMesh.new();water_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,water_arrays)
	var water:=MeshInstance3D.new();water.name="SurveyContourWater_NO_RECTANGLE";water.mesh=water_mesh;scene.add_child(water)
	var water_material:=StandardMaterial3D.new();water_material.albedo_color=Color("496d6b");water_material.roughness=.42;water_material.metallic_specular=.22;water.material_override=water_material
	own(scene,scene);var packed:=PackedScene.new();assert(packed.pack(scene)==OK);assert(ResourceSaver.save(packed,args[0])==OK)
	print("CONTINUOUS_LANDFORM_BUILT ",JSON.stringify({"tiles":tiles,"terrain_triangles":terrain_triangles,"water_triangles":water_vertices.size()/3,"water_height":WATER,"collision":"same sampled mesh","graphics":"NOT_RUN","default":"OFF"}))
	scene.free();quit()
