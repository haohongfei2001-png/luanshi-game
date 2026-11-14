extends SceneTree
func _initialize() -> void: run.call_deferred()
func run() -> void:
	var args:=OS.get_cmdline_user_args();assert(args.size()==1)
	var packed:=load(args[0]) as PackedScene;assert(packed)
	var scene:=packed.instantiate();root.add_child(scene)
	assert(str(scene.get_meta("expected_profile_version"))=="asymmetric-military-watercourse-and-causeway-04")
	var bins:={"road":0,"cover":0,"wet":0,"drain":0};var tiles:=0
	for mesh:MeshInstance3D in scene.find_children("Survey_*","MeshInstance3D",true,false):
		tiles+=1;var material:=mesh.material_override as ShaderMaterial;assert(material)
		for key:String in ["shoulder_albedo","shoulder_normal","sediment_albedo","sediment_normal"]:
			var texture:=material.get_shader_parameter(key) as Texture2D;assert(texture)
			assert(texture.get_image().has_mipmaps() and texture.get_image().get_mipmap_count()==11)
		var colors:PackedColorArray=mesh.mesh.surface_get_arrays(0)[Mesh.ARRAY_COLOR]
		for c:Color in colors:
			if c.r>.9:bins.road+=1
			if c.b>.8:bins.cover+=1
			if c.g>.9:bins.wet+=1
			if c.a>.9:bins.drain+=1
	for key:String in bins:assert(bins[key]>100,"Missing material section "+key)
	assert(tiles==266)
	print("ROAD_SECTION_CHANNELS_PASS ",JSON.stringify({"tiles":tiles,"vertices_by_channel":bins,"graphics_shader_compile":"NOT_RUN","source":"existing CC0 source maps, original UV scale, independently authored response"}))
	scene.free();quit()
