extends RefCounted
## Explicit optional material study; fixed source manifest and no gameplay changes.
static func attach(material:ShaderMaterial,directory:String) -> void:
	var manifest:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://tools/art/continuous_landform/earth_source.json"))
	var keys:={"Diffuse":"earth_albedo","nor_gl":"earth_normal","Rough":"earth_roughness"}
	for entry:Dictionary in manifest.files:
		var path:=directory.path_join(str(entry.file))
		assert(FileAccess.get_sha256(path)==str(entry.sha256),"Unverified material source: "+path)
		var image:=Image.load_from_file(path);assert(image and image.get_size()==Vector2i(2048,2048))
		# Preserve source channels, no baked lighting, saturation, sharpening or blur.
		# Godot ImageTexture gets an explicit full mip chain even for runtime files.
		assert(image.generate_mipmaps(str(entry.channel)=="nor_gl")==OK)
		material.set_shader_parameter(keys[entry.channel],ImageTexture.create_from_image(image))
	var zone_manifest:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://tools/art/continuous_landform/road_material_sources.json"))
	for entry:Dictionary in zone_manifest.files:
		assert(FileAccess.get_sha256("res://"+str(entry.path))==str(entry.sha256),"Unverified road-zone source")
	var zone_textures:={"shoulder_albedo":"leafy_grass.jpg","shoulder_normal":"leafy_grass_nor_gl.jpg","sediment_albedo":"brown_mud_dry.jpg","sediment_normal":"brown_mud_dry_nor_gl.jpg"}
	for key:String in zone_textures:
		var image:=Image.load_from_file(ProjectSettings.globalize_path("res://assets/river_gate/world/ground/"+zone_textures[key]));assert(image)
		assert(image.generate_mipmaps(key.ends_with("normal"))==OK)
		material.set_shader_parameter(key,ImageTexture.create_from_image(image))
	material.set_shader_parameter("earth_enabled",true)
	material.set_shader_parameter("earth_width_m",float(manifest.physical_width_m))
static func with_tangents(mesh:ArrayMesh) -> ArrayMesh:
	var surface:=SurfaceTool.new();surface.create_from(mesh,0);surface.generate_tangents()
	return surface.commit()
