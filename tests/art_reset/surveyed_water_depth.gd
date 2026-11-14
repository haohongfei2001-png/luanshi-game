extends SceneTree
const Ground:=preload("res://scripts/field/ground.gd")
const Surface:=preload("res://tools/art/authored_reset/surface_authoring.gd")
func _initialize() -> void: run.call_deferred()
func run() -> void:
	assert(Ground.authored_landform_enabled)
	var args:=OS.get_cmdline_user_args();assert(args.size()==1)
	var packed:=load(args[0]) as PackedScene;var scene:=packed.instantiate();root.add_child(scene)
	var water:=scene.get_node("SurveyContourWater_NO_RECTANGLE") as MeshInstance3D
	var material:=water.material_override as ShaderMaterial;assert(material)
	assert(material.shader.resource_path=="res://shaders/experimental/surveyed_water.gdshader")
	var arrays:=water.mesh.surface_get_arrays(0)
	var vertices:PackedVector3Array=arrays[Mesh.ARRAY_VERTEX];var colors:PackedColorArray=arrays[Mesh.ARRAY_COLOR]
	assert(vertices.size()==colors.size())
	var max_error:=0.;var max_depth:=0.;var shallows:=0
	for i in vertices.size():
		var point:Vector3=vertices[i]
		var depth:=clampf(Ground.BATTLE_WATER_LEVEL-Surface.height(Vector2(point.x,point.z)),0.,4.)
		max_depth=maxf(max_depth,depth);max_error=maxf(max_error,absf(colors[i].r*4.-depth))
		if depth<.12:shallows+=1
		assert(absf(point.y-Ground.BATTLE_WATER_LEVEL)<.00001,"Normal slopes must not change actual water support")
	assert(max_depth>1. and shallows>100 and max_error<.02)
	print("SURVEYED_WATER_DEPTH_PASS ",JSON.stringify({"vertices":vertices.size(),"max_depth_m":max_depth,"shallow_vertices":shallows,"max_encoded_depth_error_m":max_error,"render":"NOT_RUN","water_level":"UNCHANGED"}))
	scene.free();quit()
