extends SceneTree
## Projection-only engineering measurements. Not rendered character/art acceptance.
func _initialize()->void:run.call_deferred()
func run()->void:
 var camera=Camera3D.new();root.add_child(camera);camera.current=true;camera.projection=Camera3D.PROJECTION_ORTHOGONAL
 var rows=[]
 for pixels in [Vector2i(2560,1440),Vector2i(3840,2160)]:
  root.size=pixels;await process_frame
  for size in [12.,14.,16.,18.,22.]:
   camera.size=size
   var pitch=lerpf(deg_to_rad(31.),deg_to_rad(51.),smoothstep(7.,23.,size));var yaw=deg_to_rad(-33.)
   camera.position=Vector3(sin(yaw)*cos(pitch),sin(pitch),cos(yaw)*cos(pitch))*50.;camera.look_at(Vector3.ZERO)
   var logical=root.get_visible_rect().size
   var to_pixels=Vector2(pixels)/logical
   var foot=camera.unproject_position(Vector3.ZERO)*to_pixels;var head=camera.unproject_position(Vector3(0,1.8,0))*to_pixels
   var bounds=Rect2(foot,Vector2.ZERO)
   for x in [-.275,.275]:
    for y in [0.,1.8]:
     for z in [-.175,.175]:bounds=bounds.expand(camera.unproject_position(Vector3(x,y,z))*to_pixels)
   rows.append({'viewport':[pixels.x,pixels.y],'logical_viewport':[logical.x,logical.y],'pixel_conversion':[to_pixels.x,to_pixels.y],'orthographic_size':size,'pitch_degrees':rad_to_deg(pitch),'body_vertical_1_8m_px':foot.distance_to(head),'nominal_body_box_0_55x1_8x0_35m_px':[bounds.size.x,bounds.size.y],'nominal_box_fraction_screen_height':bounds.size.y/pixels.y,'scope':'PROJECTION_ONLY_NOT_RENDERED_NOT_WILD_RIFT_OFFICIAL_SPEC','old_baseline_only':size==22.})
 var args=OS.get_cmdline_user_args();assert(args.size()==1,'output.json')
 var file=FileAccess.open(args[0],FileAccess.WRITE);file.store_string(JSON.stringify(rows,'  '));file.close()
 print('NOMINAL_CAMERA_PIXEL_MEASUREMENT ',JSON.stringify(rows));camera.queue_free();await process_frame;quit()
