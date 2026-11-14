extends SceneTree
## Synthetic renderer regression only. The batched adapter still rejects live
## blend shapes. This compares native blend (+optional skin) to explicit CPU data.
const WEIGHT:=0.35
var rows:=[]
func _initialize():run.call_deferred()
func build_arrays(sign_value:float)->Array:
 var a:=[];a.resize(Mesh.ARRAY_MAX)
 a[Mesh.ARRAY_VERTEX]=PackedVector3Array([Vector3(-.65,-.65,0),Vector3(0,.65,0),Vector3(.65,-.65,0)])
 a[Mesh.ARRAY_NORMAL]=PackedVector3Array([Vector3.FORWARD*-1,Vector3.FORWARD*-1,Vector3.FORWARD*-1])
 a[Mesh.ARRAY_TANGENT]=PackedFloat32Array([1,0,0,sign_value,1,0,0,sign_value,1,0,0,sign_value])
 return a
func source_and_target(sign_value:float)->Array:
 var source:=build_arrays(sign_value);var target:=build_arrays(sign_value)
 var rotation:=Basis(Vector3.UP,.3)
 for i in 3:
  target[Mesh.ARRAY_VERTEX][i]=source[Mesh.ARRAY_VERTEX][i]+Vector3(.12,.04,0)
  target[Mesh.ARRAY_NORMAL][i]=rotation*source[Mesh.ARRAY_NORMAL][i]
  var t:=rotation*Vector3.RIGHT
  for j in 3:target[Mesh.ARRAY_TANGENT][i*4+j]=t[j]
 return [source,target]
func make_mesh(source:Array,target:Array,skin_enabled:bool,reference:bool,bone:Transform3D)->ArrayMesh:
 var a:=source.duplicate(true)
 var result:=ArrayMesh.new()
 if reference:
  for i in 3:
   var p:Vector3=source[Mesh.ARRAY_VERTEX][i].lerp(target[Mesh.ARRAY_VERTEX][i],WEIGHT)
   var n:Vector3=source[Mesh.ARRAY_NORMAL][i].lerp(target[Mesh.ARRAY_NORMAL][i],WEIGHT).normalized()
   var t:=Vector3(source[Mesh.ARRAY_TANGENT][i*4],source[Mesh.ARRAY_TANGENT][i*4+1],source[Mesh.ARRAY_TANGENT][i*4+2])
   var tt:=Vector3(target[Mesh.ARRAY_TANGENT][i*4],target[Mesh.ARRAY_TANGENT][i*4+1],target[Mesh.ARRAY_TANGENT][i*4+2])
   t=t.lerp(tt,WEIGHT).normalized()
   if skin_enabled:p=bone*p;n=(bone.basis*n).normalized();t=(bone.basis*t).normalized()
   a[Mesh.ARRAY_VERTEX][i]=p;a[Mesh.ARRAY_NORMAL][i]=n
   for j in 3:a[Mesh.ARRAY_TANGENT][i*4+j]=t[j]
  result.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,a)
 else:
  if skin_enabled:
   a[Mesh.ARRAY_BONES]=PackedInt32Array([0,0,0,0,0,0,0,0,0,0,0,0])
   a[Mesh.ARRAY_WEIGHTS]=PackedFloat32Array([1,0,0,0,1,0,0,0,1,0,0,0])
  result.blend_shape_mode=Mesh.BLEND_SHAPE_MODE_NORMALIZED;result.add_blend_shape('nonzero_bend')
  result.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,a,[target])
 return result
func make_view(mesh:ArrayMesh,skin_enabled:bool,reference:bool,bone:Transform3D,axis:String)->SubViewport:
 var vp:=SubViewport.new();vp.size=Vector2i(256,256);vp.own_world_3d=true;vp.render_target_update_mode=SubViewport.UPDATE_ALWAYS;root.add_child(vp)
 var sk:=Skeleton3D.new();sk.name='Skeleton';sk.add_bone('root');sk.set_bone_rest(0,Transform3D.IDENTITY);sk.set_bone_pose_position(0,bone.origin);sk.set_bone_pose_rotation(0,bone.basis.get_rotation_quaternion());vp.add_child(sk)
 var instance:=MeshInstance3D.new();instance.mesh=mesh;sk.add_child(instance)
 if not reference:
  instance.set_blend_shape_value(0,WEIGHT)
  if skin_enabled:instance.skin=Skin.new();instance.skin.add_bind(0,Transform3D.IDENTITY);instance.skeleton=NodePath('..')
 var mat:=ShaderMaterial.new();mat.shader=Shader.new();mat.shader.code='shader_type spatial;render_mode unshaded,cull_disabled;void fragment(){ALBEDO=normalize('+axis+')*.5+vec3(.5);}'
 instance.material_override=mat
 var camera:=Camera3D.new();vp.add_child(camera);camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=2.;camera.position=Vector3(0,0,3);camera.look_at(Vector3.ZERO);camera.current=true
 return vp
func run():
 if DisplayServer.get_name()=='headless':quit(1);return
 var folder:='res://artifacts/native-character-parity/blend_skin_probe';DirAccess.make_dir_recursive_absolute(folder)
 var bone:=Transform3D(Basis(Vector3.BACK,.17),Vector3(.03,0,0));var pairs:=[]
 for skinned:bool in [false,true]:
  for hand:float in [-1.,1.]:
   var data:=source_and_target(hand)
   for axis:String in ['NORMAL','TANGENT','BINORMAL']:
    var original:=make_mesh(data[0],data[1],skinned,false,bone)
    var reference:=make_mesh(data[0],data[1],skinned,true,bone)
    var key:='%s-%s-%s'%[str(skinned),str(hand),axis]
    pairs.append({'key':key,'skin':skinned,'hand':hand,'axis':axis,'native':make_view(original,skinned,false,bone,axis),'reference':make_view(reference,skinned,true,bone,axis)})
 for frame in 8:await process_frame
 await RenderingServer.frame_post_draw
 var failures:=0
 for pair in pairs:
  var a:Image=pair.native.get_texture().get_image();var b:Image=pair.reference.get_texture().get_image()
  a.save_png(folder+'/'+pair.key+'-native.png');b.save_png(folder+'/'+pair.key+'-cpu-static.png')
  var background:=a.get_pixel(0,0);var visible:=0;var different:=0;var error_sum:=0.
  for y in 256:
   for x in 256:
    var p:=a.get_pixel(x,y);var q:=b.get_pixel(x,y);var e:=maxf(absf(p.r-q.r),maxf(absf(p.g-q.g),absf(p.b-q.b)))
    error_sum+=e
    if p!=background or q!=background:visible+=1
    if e>2./255.:different+=1
  var passed:=visible>1000 and different<visible*.02 and error_sum/(256*256)<.001
  if not passed:failures+=1
  rows.append({'case':pair.key,'skin':pair.skin,'handedness':pair.hand,'axis':pair.axis,'visible':visible,'over_2_levels':different,'mae':error_sum/(256*256),'pass':passed})
 var report:={'source':OS.get_environment('GITHUB_SHA'),'renderer':RenderingServer.get_video_adapter_name(),'blend_weight':WEIGHT,'cases':rows,'failures':failures,'scope':'Native engine regression; batch live blend shapes still unsupported'}
 var file:=FileAccess.open(folder+'/probe.json',FileAccess.WRITE);file.store_string(JSON.stringify(report,'  '));file.close();print('NATIVE_BLEND_SKIN_PROBE ',JSON.stringify(report));quit(0 if failures==0 else 1)
