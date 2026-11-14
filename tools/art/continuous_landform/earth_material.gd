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
	material.set_shader_parameter("earth_enabled",true)
	material.set_shader_parameter("earth_width_m",float(manifest.physical_width_m))
static func with_tangents(mesh:ArrayMesh) -> ArrayMesh:
	var surface:=SurfaceTool.new();surface.create_from(mesh,0);surface.generate_tangents()
	return surface.commit()
