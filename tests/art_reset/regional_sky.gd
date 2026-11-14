extends SceneTree
const Apply:=preload("res://scripts/field/experimental_regional_environment.gd")
func _initialize() -> void: run.call_deferred()
func run() -> void:
 var args:=OS.get_cmdline_user_args();assert(args.size()==1)
 var world:=WorldEnvironment.new();world.environment=Environment.new();world.environment.background_mode=Environment.BG_COLOR;root.add_child(world)
 var sun:=DirectionalLight3D.new();sun.rotation_degrees=Vector3(-48,58,0);root.add_child(sun)
 var old:=world.environment;var transform:=sun.transform
 if OS.get_environment("LUANSHI_REGIONAL_SKY")!="1":
  assert(not Apply.apply(world,sun,args[0]) and world.environment==old)
  print("REGIONAL_SKY_DEFAULT_UNCHANGED_PASS")
 else:
  assert(Apply.apply(world,sun,args[0]));assert(world.environment!=old and old.background_mode==Environment.BG_COLOR)
  assert(world.environment.background_mode==Environment.BG_SKY and world.environment.sky.radiance_size==Sky.RADIANCE_SIZE_256)
  assert(sun.transform==transform and world.environment.tonemap_mode==old.tonemap_mode)
  var m:=world.environment.sky.sky_material as ShaderMaterial
  var texture:=m.get_shader_parameter("source_panorama") as Texture2D
  assert(texture.get_image().get_format()==Image.FORMAT_RGBF and texture.get_image().has_mipmaps())
  assert(texture.get_image().get_pixel(1218,239).r>70000.,"Source sun clipped in packed texture")
  print("REGIONAL_SKY_RESOURCE_PASS original_float_radiance=true sun_transform_unchanged=true camera_exposure_unchanged=true graphics=NOT_RUN")
 world.free();sun.free();quit()
