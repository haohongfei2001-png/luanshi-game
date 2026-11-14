extends SceneTree
func _initialize():call_deferred("run")
func run():
 var scene=Node3D.new();root.add_child(scene)
 var camera=Camera3D.new();scene.add_child(camera);camera.position=Vector3(0,0,10);camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.keep_aspect=Camera3D.KEEP_WIDTH;camera.size=8.;camera.current=true
 var linear=Color(.44,.265,.17,1);var encoded=linear.linear_to_srgb()
 var tex_image=Image.create(8,8,false,Image.FORMAT_RGBA8);tex_image.fill(encoded);var texture=ImageTexture.create_from_image(tex_image)
 var cases=["standard_encoded","shader_raw_linear","shader_hint_encoded","shader_raw_encoded","shader_texture","standard_texture"]
 for i in cases.size():
  var obj=MeshInstance3D.new();var mesh=QuadMesh.new();mesh.size=Vector2(1,1);obj.mesh=mesh;obj.position.x=float(i)-2.5;scene.add_child(obj)
  if i==0 or i==5:
   var mat=StandardMaterial3D.new();mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
   mat.albedo_color=encoded if i==0 else Color.WHITE
   if i==5:mat.albedo_texture=texture
   obj.material_override=mat
  else:
   var mat=ShaderMaterial.new();var sh=Shader.new()
   var declaration="uniform vec4 c : source_color;" if i==2 else "uniform vec4 c;"
   sh.code="shader_type spatial; render_mode unshaded; "+declaration+" uniform sampler2D tex : source_color,filter_nearest; void fragment(){ ALBEDO="+("texture(tex,UV).rgb" if i==4 else "c.rgb")+"; }"
   mat.shader=sh;mat.set_shader_parameter("c",linear if i==1 else encoded);mat.set_shader_parameter("tex",texture);obj.material_override=mat
 await process_frame;await process_frame;await RenderingServer.frame_post_draw
 var img=root.get_texture().get_image();var samples={}
 for i in cases.size():
  var point=camera.unproject_position(Vector3(float(i)-2.5,0,0));var value=img.get_pixelv(Vector2i(point));samples[cases[i]]=[value.r,value.g,value.b]
 var out=OS.get_environment("SOLDIER_OUTPUT");DirAccess.make_dir_recursive_absolute(out);img.save_png(out.path_join("color-patches-actual-godot.png"))
 FileAccess.open(out.path_join("color-probe.json"),FileAccess.WRITE).store_string(JSON.stringify({"engine":Engine.get_version_info(),"gpu":RenderingServer.get_video_adapter_name(),"linear_input":[linear.r,linear.g,linear.b],"encoded_input":[encoded.r,encoded.g,encoded.b],"unshaded_same_frame_samples":samples,"art_pass":false},"  "))
 quit()
