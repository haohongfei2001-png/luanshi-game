extends SceneTree
## One original Idle pose, actual renderer, no full atlas or production replacement.
const Asset=preload("res://tools/representation_compare/control_asset.gd")
var out:String
func _initialize():go.call_deferred()
func capture(view:SubViewport,path:String)->Image:
 for i in 3:await process_frame
 await RenderingServer.frame_post_draw
 var image=view.get_texture().get_image();image.save_png(path);return image
func compare(reference:Image,candidate:Image)->Dictionary:
 var interior=0;var over2=0;var max_error=0.;var total=0.;var alpha_error=0.;var union=0;var intersection=0
 for y in reference.get_height():
  for x in reference.get_width():
   var a=reference.get_pixel(x,y);var b=candidate.get_pixel(x,y)
   if a.a>.35 or b.a>.35:union+=1
   if a.a>.35 and b.a>.35:intersection+=1
   alpha_error=maxf(alpha_error,absf(a.a-b.a))
   if a.a<.99 or b.a<.99:continue
   interior+=1
   var error=maxf(absf(a.r-b.r),maxf(absf(a.g-b.g),absf(a.b-b.b)))
   total+=error;max_error=maxf(max_error,error)
   if error>2./255.:over2+=1
 assert(interior>1000,"No real opaque character pixels")
 return {"interior_pixels":interior,"max_rgb_error_levels":max_error*255.,"mean_max_rgb_error_levels":total/interior*255.,"over_two_levels_fraction":float(over2)/interior,"silhouette_iou_alpha035":float(intersection)/union,"max_alpha_error":alpha_error,"art_pass":false}
func go():
 assert(DisplayServer.get_name()!="headless","Actual graphics required")
 out=OS.get_environment("TONEMAP_OUTPUT");DirAccess.make_dir_recursive_absolute(out)
 var viewport=SubViewport.new();viewport.size=Vector2i(512,512);viewport.own_world_3d=true;viewport.transparent_bg=true;viewport.msaa_3d=Viewport.MSAA_4X;viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS;root.add_child(viewport)
 var stage=Node3D.new();viewport.add_child(stage)
 var asset=Asset.new();asset.prepare(stage);asset.light(stage,true)
 var world:WorldEnvironment=stage.find_children("*","WorldEnvironment",true,false)[0]
 var camera=Camera3D.new();stage.add_child(camera);camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=2.5;camera.near=.1;camera.far=50.;camera.current=true
 var pitch=lerpf(deg_to_rad(31.),deg_to_rad(51.),smoothstep(7.,23.,22.));var yaw=deg_to_rad(-33.)
 var anchor=Vector3(0,.95,0);camera.position=anchor+Vector3(sin(yaw)*cos(pitch),sin(pitch),cos(yaw)*cos(pitch))*20.;camera.look_at(anchor)
 var batches=asset.batches(stage,1);asset.set_actor(batches,0,Transform3D.IDENTITY,0)
 world.environment.tonemap_mode=Environment.TONE_MAPPER_FILMIC
 var reference:Image=await capture(viewport,out.path_join("native-filmic.png"))
 var quad=MeshInstance3D.new();var mesh=QuadMesh.new();mesh.size=Vector2(2.5,2.5);quad.mesh=mesh;quad.position=anchor;quad.visible=false;quad.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;stage.add_child(quad)
 var material=ShaderMaterial.new();var shader=Shader.new()
 shader.code='shader_type spatial; render_mode unshaded,cull_disabled,depth_prepass_alpha; uniform sampler2D pigment:source_color,filter_linear,repeat_disable; uniform float reconstruction_gain=1.; void vertex(){MODELVIEW_MATRIX=VIEW_MATRIX*mat4(INV_VIEW_MATRIX[0],INV_VIEW_MATRIX[1],INV_VIEW_MATRIX[2],MODEL_MATRIX[3]);} void fragment(){vec4 p=texture(pigment,UV);ALBEDO=p.rgb*reconstruction_gain;ALPHA=p.a;}'
 material.shader=shader;mesh.material=material
 var report={"source_sha256":FileAccess.get_sha256("res://assets/ubc_lab/ubc_animated.glb"),"pose":"Idle frame0 only","resolution":[512,512],"format":"uncompressed RGBA8 isolates tone response, NOT S3TC quality test","engine":Engine.get_version_info(),"renderer":RenderingServer.get_video_adapter_name(),"samples":[],"art_pass":false}
 for exposure in [1.,.5,.25,.125]:
  quad.visible=false
  for node in batches:node.visible=true
  world.environment.tonemap_mode=Environment.TONE_MAPPER_LINEAR;world.environment.tonemap_exposure=exposure
  var baked:Image=await capture(viewport,out.path_join("bake-"+str(exposure)+".png"))
  material.set_shader_parameter("pigment",ImageTexture.create_from_image(baked));material.set_shader_parameter("reconstruction_gain",1./exposure)
  for node in batches:node.visible=false
  quad.visible=true;world.environment.tonemap_mode=Environment.TONE_MAPPER_FILMIC;world.environment.tonemap_exposure=1.
  var candidate:Image=await capture(viewport,out.path_join("sprite-"+str(exposure)+".png"))
  var result=compare(reference,candidate);result["bake_exposure"]=exposure;result["runtime_gain"]=1./exposure;report.samples.append(result)
 report["sampler_and_pass_probe"]=[]
 var original_bake=Image.load_from_file(out.path_join("bake-1.0.png"))
 for array_sampler in [false,true]:
  for scissor in [false,true]:
   var pipeline=ShaderMaterial.new();var variant=Shader.new()
   var sampler="sampler2DArray" if array_sampler else "sampler2D"
   var coordinates="vec3(UV,0.)" if array_sampler else "UV"
   var cut="ALPHA_SCISSOR_THRESHOLD=.35;" if scissor else ""
   variant.code='shader_type spatial; render_mode unshaded,cull_disabled,depth_prepass_alpha; uniform '+sampler+' pigment:source_color,filter_linear,repeat_disable; void vertex(){MODELVIEW_MATRIX=VIEW_MATRIX*mat4(INV_VIEW_MATRIX[0],INV_VIEW_MATRIX[1],INV_VIEW_MATRIX[2],MODEL_MATRIX[3]);} void fragment(){vec4 p=texture(pigment,'+coordinates+');ALBEDO=p.rgb;ALPHA=p.a;'+cut+'}'
   pipeline.shader=variant
   if array_sampler:
    var array=Texture2DArray.new();var images:Array[Image]=[original_bake];assert(array.create_from_images(images)==OK);pipeline.set_shader_parameter("pigment",array)
   else:pipeline.set_shader_parameter("pigment",ImageTexture.create_from_image(original_bake))
   mesh.material=pipeline
   var candidate:Image=await capture(viewport,out.path_join("pipe-array"+str(array_sampler)+"-scissor"+str(scissor)+".png"))
   var result=compare(reference,candidate);result["sampler_array"]=array_sampler;result["alpha_scissor"]=scissor;report.sampler_and_pass_probe.append(result)
 FileAccess.open(out.path_join("report.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"  "));print("TONEMAP_PROBE ",JSON.stringify(report));quit()
