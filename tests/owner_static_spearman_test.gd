extends SceneTree
const Actor=preload('res://scripts/field/experimental/owner_static_spearman.gd')
func _initialize():call_deferred('_run')
func _run():
 root.size=Vector2i(2560,1440)
 var camera=Camera3D.new();root.add_child(camera);camera.global_position=Vector3(4,6,9);camera.look_at(Vector3(0,1,0));camera.fov=55
 var image=Image.create(1199,1312,false,Image.FORMAT_RGBA8);image.fill(Color.WHITE)
 var texture=ImageTexture.create_from_image(image)
 var actor=Actor.new();root.add_child(actor)
 var checks=0
 for projection in [Camera3D.PROJECTION_PERSPECTIVE,Camera3D.PROJECTION_ORTHOGONAL]:
  camera.projection=projection;camera.size=12
  for height in [100.0,180.0,270.0]:
   var ground=Vector3(1,.2,0)
   assert(actor.configure(camera,ground,height,texture)==OK)
   assert(actor.global_position==ground and not actor.no_depth_test and not actor.fixed_size)
   assert(actor.source_pixel_world(Actor.FOOT_ANCHOR,camera).distance_to(ground)<1e-6)
   assert(absf(actor.projected_markers(camera).height_logical_px-height)<.02)
   assert(actor.offset==Vector2(-590,-68))
   var face=actor.generate_triangle_mesh().get_faces()
   assert(face.size()==6)
   assert(actor.receipt(camera).camera_locked)
   checks+=7
 assert(actor.configure(camera,Vector3.ZERO,NAN,texture)==ERR_INVALID_PARAMETER)
 assert(actor.configure(camera,Vector3.ZERO,0,texture)==ERR_INVALID_PARAMETER)
 assert(camera.get_viewport().get_visible_rect().size==Vector2(2560,1440))
 print('OWNER_STATIC_SPEARMAN_CONTRACT_PASS checks=',checks+3,' VIEWPORT=2560x1440 GRAPHICS_NOT_RUN')
 quit()
