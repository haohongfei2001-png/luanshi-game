extends SceneTree
## Minimal renderer diagnosis, NOT a production fix or a parity PASS.
func _initialize():run.call_deferred()
func mesh(skinned:bool)->ArrayMesh:
 var a:=[];a.resize(Mesh.ARRAY_MAX)
 a[Mesh.ARRAY_VERTEX]=PackedVector3Array([Vector3(-.8,-.8,0),Vector3(0,.8,0),Vector3(.8,-.8,0)])
 a[Mesh.ARRAY_NORMAL]=PackedVector3Array([Vector3(0,0,1),Vector3(0,0,1),Vector3(0,0,1)])
 a[Mesh.ARRAY_TANGENT]=PackedFloat32Array([1,0,0,1,1,0,0,1,1,0,0,1])
 if skinned:
  a[Mesh.ARRAY_BONES]=PackedInt32Array([0,0,0,0,0,0,0,0,0,0,0,0])
  a[Mesh.ARRAY_WEIGHTS]=PackedFloat32Array([1,0,0,0,1,0,0,0,1,0,0,0])
 var m:=ArrayMesh.new();m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,a);return m
func run():
 if DisplayServer.get_name()=="headless":quit(1);return
 var out:="res://artifacts/native-character-parity/tangent_probe"
 DirAccess.make_dir_recursive_absolute(out)
 var cases:=[]
 for kind in ["static","identity_skin","identity_skin_roundtrip"]:
  var vp:=SubViewport.new();vp.size=Vector2i(256,256);vp.own_world_3d=true;vp.render_target_update_mode=SubViewport.UPDATE_ALWAYS;root.add_child(vp)
  var sk:=Skeleton3D.new();sk.name="Skeleton";sk.add_bone("root");sk.set_bone_rest(0,Transform3D.IDENTITY);vp.add_child(sk)
  var instance:=MeshInstance3D.new();instance.mesh=mesh(kind!="static");sk.add_child(instance)
  if kind=="identity_skin_roundtrip":
   var copy:=ArrayMesh.new();copy.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,instance.mesh.surface_get_arrays(0));instance.mesh=copy
  if kind!="static":
   instance.skin=Skin.new();instance.skin.add_bind(0,Transform3D.IDENTITY);instance.skeleton=NodePath("..")
  var mat:=ShaderMaterial.new();mat.shader=Shader.new();mat.shader.code="shader_type spatial;render_mode unshaded,cull_disabled;void fragment(){ALBEDO=normalize(TANGENT)*.5+vec3(.5);}"
  instance.material_override=mat
  var camera:=Camera3D.new();vp.add_child(camera);camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=2.;camera.position=Vector3(0,0,3);camera.look_at(Vector3.ZERO);camera.current=true
  cases.append({"kind":kind,"viewport":vp,"format":instance.mesh.surface_get_format(0),"source_tangent":Array(instance.mesh.surface_get_arrays(0)[Mesh.ARRAY_TANGENT]).slice(0,4)})
 for frame in 6:await process_frame
 await RenderingServer.frame_post_draw
 var rows:=[]
 for entry in cases:
  var pic:Image=entry.viewport.get_texture().get_image();pic.save_png(out+"/"+entry.kind+".png")
  rows.append({"kind":entry.kind,"surface_format":entry.format,"source_tangent":entry.source_tangent,"center_rgb":pic.get_pixel(128,128)})
 var report:={"source":OS.get_environment("GITHUB_SHA"),"renderer":RenderingServer.get_video_adapter_name(),"bone_count":1,"bone_pose":"identity","weights":"exact [1,0,0,0]","source_tangent":"exact [1,0,0,1]","diagnostic_only":true,"samples":rows}
 var file:=FileAccess.open(out+"/probe.json",FileAccess.WRITE);file.store_string(JSON.stringify(report,"  "));file.close()
 print("NATIVE_SKIN_TANGENT_PROBE ",JSON.stringify(report));quit()
