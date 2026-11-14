extends SceneTree
func _initialize() -> void:
	var args:=OS.get_cmdline_user_args();assert(args.size()==1)
	var material:=ShaderMaterial.new();material.shader=load("res://shaders/experimental/surveyed_landform.gdshader")
	preload("res://tools/art/continuous_landform/earth_material.gd").attach(material,args[0])
	for key:String in ["earth_albedo","earth_normal","earth_roughness","shoulder_albedo","shoulder_normal","sediment_albedo","sediment_normal"]:
		var texture:=material.get_shader_parameter(key) as Texture2D;assert(texture)
		assert(texture.get_image().get_size()==Vector2i(2048,2048) and texture.get_image().get_mipmap_count()==11)
	print("ROAD_SOURCE_LOAD_PASS fixed source hashes; seven native2048 mip chains; offline builder absolute source path; GRAPHICS_NOT_RUN")
	quit()
