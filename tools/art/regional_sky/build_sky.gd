extends SceneTree
## Independent physical-sky source preparation, NOT gameplay/art acceptance.
func _initialize() -> void: run.call_deferred()
func run() -> void:
 var args:=OS.get_cmdline_user_args();assert(args.size()==2,"verified decoded float32 radiance, output Sky.res")
 var source:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://tools/art/regional_sky/source.json"))
 var receipt:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(args[0]+".json"))
 assert(receipt.source_sha256==source.sha256 and FileAccess.get_sha256(args[0])==receipt.linear_float_sha256)
 var bytes:=FileAccess.get_file_as_bytes(args[0]);assert(bytes.size()==2048*1024*3*4)
 var image:=Image.create_from_data(2048,1024,false,Image.FORMAT_RGBF,bytes)
 assert(image.get_size()==Vector2i(2048,1024))
 var brightest:=0.;var peak:=Vector2i.ZERO
 for y in image.get_height()/2:
  for x in image.get_width():
   var color:=image.get_pixel(x,y);var lum:=color.r*.2126+color.g*.7152+color.b*.0722
   if lum>brightest:brightest=lum;peak=Vector2i(x,y)
 assert(absf(brightest-float(receipt.max_luminance))<.1,"Radiance clipped during source decode")
 var azimuth:=(float(peak.x)+.5)/image.get_width()*TAU
 var polar:=(float(peak.y)+.5)/image.get_height()*PI
 var source_direction:=Vector3(sin(azimuth)*sin(polar),cos(polar),-cos(azimuth)*sin(polar))
 # Existing authored river-master sun orientation is (-48,58,0) degrees.
 # Align panorama azimuth, preserving the real horizon rather than tilting it.
 var sun_basis:=Basis.from_euler(Vector3(deg_to_rad(-48.),deg_to_rad(58.),0.))
 var sun_direction:=sun_basis.z.normalized()
 var sun_azimuth:=atan2(sun_direction.x,-sun_direction.z)
 var world_to_source:=Basis(Vector3.UP,sun_azimuth-azimuth)
 var mismatch:=rad_to_deg(source_direction.angle_to(world_to_source*sun_direction))
 assert(mismatch<1.,"Source solar elevation differs from actual field sun; do not silently use incompatible illumination")
 assert(image.generate_mipmaps()==OK)
 var shader:=ShaderMaterial.new();shader.shader=load("res://shaders/experimental/regional_panorama.gdshader")
 shader.set_shader_parameter("source_panorama",ImageTexture.create_from_image(image));shader.set_shader_parameter("world_to_source",world_to_source)
 var sky:=Sky.new();sky.sky_material=shader;sky.radiance_size=Sky.RADIANCE_SIZE_256
 sky.set_meta("source_sha256",source.sha256);sky.set_meta("solar_alignment_degrees",mismatch)
 sky.set_meta("expected_sun_rotation_degrees",Vector3(-48.,58.,0.));sky.set_meta("art_status","NOT_ACCEPTED; real graphics NOT_RUN")
 assert(ResourceSaver.save(sky,args[1])==OK)
 var reopened:=load(args[1]) as Sky;assert(reopened and reopened.get_meta("source_sha256")==source.sha256)
 var result:={"source_sha256":source.sha256,"source_dimensions":image.get_size(),"peak_pixel":peak,"peak_luminance":brightest,"source_sun_elevation_degrees":90.-rad_to_deg(polar),"source_sun_azimuth_degrees":rad_to_deg(azimuth),"world_sun_azimuth_degrees":rad_to_deg(sun_azimuth),"world_to_source_y_rotation_degrees":rad_to_deg(sun_azimuth-azimuth),"world_sun_rotation_degrees":[-48,58,0],"solar_angular_mismatch_degrees":mismatch,"radiance_size":256,"image_format":image.get_format(),"source_colors":"original unclamped HDR; no exposure correction or baked terrain","output_sha256":FileAccess.get_sha256(args[1]),"graphics":"NOT_RUN","art":"NOT_ACCEPTED"}
 FileAccess.open(args[1]+".json",FileAccess.WRITE).store_string(JSON.stringify(result,"  "));print("REGIONAL_SKY_RESOURCE_BUILT ",JSON.stringify(result));quit()
