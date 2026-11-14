extends Node
var base: String
var output: String
func texture(name: String,w: int,h: int)->ImageTexture:
 var data=FileAccess.get_file_as_bytes(base.path_join(name+".f32"))
 assert(data.size()==w*h*16)
 return ImageTexture.create_from_image(Image.create_from_data(w,h,false,Image.FORMAT_RGBAF,data))
func stage(width: int,shader_path: String)->SubViewport:
 var view=SubViewport.new()
 view.size=Vector2i(width,3)
 view.disable_3d=true
 view.transparent_bg=false
 view.render_target_update_mode=SubViewport.UPDATE_ALWAYS
 view.canvas_item_default_texture_filter=Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
 add_child(view)
 var rect=ColorRect.new()
 rect.size=Vector2(width,3)
 var mat=ShaderMaterial.new()
 mat.shader=load(shader_path)
 rect.material=mat
 view.add_child(rect)
 return view
func compare(img: Image,name: String,count: int)->Dictionary:
 var truth=FileAccess.get_file_as_bytes(base.path_join(name+".f32")).to_float32_array()
 var max_error=0.0
 var sum_squared=0.0
 for v in count:
  var delta=Vector3.ZERO
  for axis in 3:
   var color=img.get_pixel(v,axis)
   var n=int(round(color.r*255.0))|(int(round(color.g*255.0))<<8)|(int(round(color.b*255.0))<<16)
   delta[axis]=float(n)/16777215.0*8.0-4.0-truth[v*3+axis]
  max_error=maxf(max_error,delta.length())
  sum_squared+=delta.length_squared()
 return {"max_m":max_error,"rms_m":sqrt(sum_squared/count)}
func _ready()->void:
 base=OS.get_environment("GUARDIAN_GPU_FIXTURE")
 output=OS.get_environment("GUARDIAN_GPU_OUTPUT")
 DirAccess.make_dir_recursive_absolute(output)
 var meta=JSON.parse_string(FileAccess.get_file_as_string(base.path_join("meta.json")))
 var cage=stage(566,"res://dq.gdshader")
 var cm=cage.get_child(0).material
 cm.set_shader_parameter("weights_tex",texture("weights",566,5))
 cm.set_shader_parameter("rest_tex",texture("rest",566,1))
 var coat=stage(1373,"res://response.gdshader")
 var tm=coat.get_child(0).material
 tm.set_shader_parameter("response_tex",texture("response",1373,218))
 tm.set_shader_parameter("cage_rest_tex",texture("cage_rest",566,1))
 tm.set_shader_parameter("top_rest_tex",texture("top_rest",1373,1))
 var a=meta.cage_to_top
 tm.set_shader_parameter("cage_to_top",Basis(Vector3(a[0][0],a[1][0],a[2][0]),Vector3(a[0][1],a[1][1],a[2][1]),Vector3(a[0][2],a[1][2],a[2][2])))
 var rows=[]
 var failures=0
 for i in int(meta.poses):
  var start=Time.get_ticks_usec()
  cm.set_shader_parameter("dq_tex",texture("dq_"+str(i),79,2))
  await RenderingServer.frame_post_draw
  await RenderingServer.frame_post_draw
  var cage_image=cage.get_texture().get_image()
  # Explicit isolated pass boundary/readback, not a production performance claim.
  tm.set_shader_parameter("cage_tex",ImageTexture.create_from_image(cage_image))
  await RenderingServer.frame_post_draw
  await RenderingServer.frame_post_draw
  var coat_image=coat.get_texture().get_image()
  var c=compare(cage_image,"cage_"+str(i),566)
  var t=compare(coat_image,"top_"+str(i),1373)
  var passed=c.max_m<0.000005 and t.max_m<0.0001
  if not passed:failures+=1
  rows.append({"pose":i,"cage":c,"coat":t,"pass":passed,"four_frame_readback_wall_ms":(Time.get_ticks_usec()-start)/1000.0})
  if i==0 or i==12:
   cage_image.save_png(output.path_join("cage-"+str(i)+"-encoded.png"))
   coat_image.save_png(output.path_join("coat-"+str(i)+"-encoded.png"))
 var report={"engine":Engine.get_version_info(),"renderer":RenderingServer.get_video_adapter_name(),"poses":rows,"failures":failures,"scope":"actual GPU arithmetic pixels, not garment artwork; 1373 coat base points only","thresholds_m":{"cage":0.000005,"coat":0.0001},"performance_claim":false}
 var f=FileAccess.open(output.path_join("gpu-report.json"),FileAccess.WRITE)
 f.store_string(JSON.stringify(report,"  "))
 print("GUARDIAN_DQ_GPU ",JSON.stringify(report))
 get_tree().quit(0 if failures==0 else 1)
