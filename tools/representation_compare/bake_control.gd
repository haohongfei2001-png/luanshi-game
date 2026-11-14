extends SceneTree
const Asset=preload("res://tools/representation_compare/control_asset.gd")
var asset=Asset.new()
func _initialize()->void:run.call_deferred()
func save_page(image:Image,path:String)->void:
 var error=image.save_png(path)
 if error!=OK:push_error("Atlas PNG save failed: "+str(error));quit(1)
func receipt(size:Vector2i,pages:int)->Dictionary:
 return {"png_pages":pages,"rgba8_bytes":size.x*size.y*4*pages,"dimensions":[size.x,size.y]}
func run()->void:
 assert(DisplayServer.get_name()!="headless","Actual Godot graphics required")
 var output=OS.get_environment("COMPARE_ASSETS");DirAccess.make_dir_recursive_absolute(output)
 var view=SubViewport.new();view.size=Vector2i(256,256);view.own_world_3d=true;view.transparent_bg=true;view.msaa_3d=Viewport.MSAA_4X;view.render_target_update_mode=SubViewport.UPDATE_ALWAYS;root.add_child(view)
 var stage=Node3D.new();view.add_child(stage);asset.prepare(stage,true);asset.light(stage,true)
 var camera=Camera3D.new();stage.add_child(camera);camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.keep_aspect=Camera3D.KEEP_WIDTH
 var pitch=lerpf(deg_to_rad(31.),deg_to_rad(51.),smoothstep(7.,23.,22.));var yaw=deg_to_rad(-33.)
 var ray=Vector3(sin(yaw)*cos(pitch),sin(pitch),cos(yaw)*cos(pitch));var right=Vector3.UP.cross(ray).normalized();var up=ray.cross(right).normalized();camera.current=true
 var batches=asset.batches(stage,1)
 var report={"control":"UBC unclothed, not armor acceptance","clips":asset.clips,"pixels_per_metre":256.,"anchor_y":.95,"directions":16,"palette_bytes":asset.palette_bytes,"full_source_triangles":asset.mesh_triangles,"padding_failures":[],"alpha_pixel_bounds":[],"source_sha256":FileAccess.get_sha256("res://assets/ubc_lab/ubc_animated.glb"),"compression":"pending separate official editor offline pack; template only renders PNG"}
 for clip:String in asset.clips:
  var info=asset.clips[clip];var bounds=info.bounds
  var center=Vector2((bounds[0]+bounds[2])*.5,(bounds[1]+bounds[3])*.5)
  var size=Vector2i(ceili((bounds[2]-bounds[0]+.1)*256./16.)*16,ceili((bounds[3]-bounds[1]+.1)*256./16.)*16)
  view.size=size;camera.size=size.x/256.
  var anchor=Vector3(0,.95,0)+right*center.x+up*center.y;camera.position=anchor+ray*20.;camera.look_at(anchor)
  var columns=maxi(1,4096/size.x);var rows=maxi(1,4096/size.y);var capacity=columns*rows
  info["tile"]=[size.x,size.y];info["columns16"]=columns;info["columns8"]=columns;info["page_rows"]=rows;info["center_projected"]=[center.x,center.y];info["world_size"]=[size.x/256.,size.y/256.]
  var page_size=Vector2i(columns*size.x,rows*size.y)
  var page=Image.create(page_size.x,page_size.y,false,Image.FORMAT_RGBA8)
  var pages16=0
  for frame in int(info.count):
   for direction in 16:
    asset.set_actor(batches,0,Transform3D(Basis(Vector3.UP,TAU*direction/16.),Vector3.ZERO),int(info.offset)+frame)
    await process_frame;await RenderingServer.frame_post_draw
    var tile=view.get_texture().get_image();tile.convert(Image.FORMAT_RGBA8)
    var used=tile.get_used_rect();report.alpha_pixel_bounds.append([clip,frame,direction,used.position.x,used.position.y,used.size.x,used.size.y])
    var border=false
    for x in tile.get_width():border=border or tile.get_pixel(x,0).a>.01 or tile.get_pixel(x,tile.get_height()-1).a>.01
    for y in tile.get_height():border=border or tile.get_pixel(0,y).a>.01 or tile.get_pixel(tile.get_width()-1,y).a>.01
    if border:report.padding_failures.append([clip,frame,direction])
    var index=frame*16+direction;var local=index%capacity
    page.blit_rect(tile,Rect2i(Vector2i.ZERO,size),Vector2i(local%columns,local/columns)*size)
    if local==capacity-1 or index==int(info.count)*16-1:
     save_page(page,output.path_join(clip+"-16-page"+str(pages16)+".png"));pages16+=1
     page=Image.create(page_size.x,page_size.y,false,Image.FORMAT_RGBA8)
  info["atlas16"]=receipt(page_size,pages16)
  var pages8=0;var loaded_page=-1;var original:Image
  for frame in int(info.count):
   for d in 8:
    var source_index=frame*16+d*2;var source_page=source_index/capacity
    if source_page!=loaded_page:
     original=Image.load_from_file(output.path_join(clip+"-16-page"+str(source_page)+".png"));loaded_page=source_page
    var source_local=source_index%capacity;var index=frame*8+d;var local=index%capacity
    page.blit_rect(original,Rect2i(Vector2i(source_local%columns,source_local/columns)*size,size),Vector2i(local%columns,local/columns)*size)
    if local==capacity-1 or index==int(info.count)*8-1:
     save_page(page,output.path_join(clip+"-8-page"+str(pages8)+".png"));pages8+=1
     page=Image.create(page_size.x,page_size.y,false,Image.FORMAT_RGBA8)
  info["atlas8"]=receipt(page_size,pages8)
  print("CONTROL_ATLAS ",clip," ",JSON.stringify(info))
 FileAccess.open(output.path_join("atlas.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
 quit(0 if report.padding_failures.is_empty() else 1)
