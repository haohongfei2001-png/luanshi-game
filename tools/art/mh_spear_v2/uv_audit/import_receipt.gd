extends SceneTree
func _initialize():run.call_deferred()
func run():
 var args=OS.get_cmdline_user_args();assert(args.size()==2)
 var scene=load(args[0]).instantiate();root.add_child(scene);var rows=[]
 for n in scene.find_children('*','MeshInstance3D',true,false):
  for i in n.mesh.get_surface_count():
   var m=n.get_active_material(i)
   if m.resource_name not in ['V2 continuous lamellar cuirass','V3 thin wrapped linen with physical overlap']:continue
   var a=n.mesh.surface_get_arrays(i);var samples=[];var custom=PackedFloat32Array()
   if a[Mesh.ARRAY_CUSTOM0]!=null:
    custom=a[Mesh.ARRAY_CUSTOM0].to_float32_array() if typeof(a[Mesh.ARRAY_CUSTOM0])==TYPE_PACKED_BYTE_ARRAY else a[Mesh.ARRAY_CUSTOM0]
   var custom_stride:int=custom.size()/a[Mesh.ARRAY_VERTEX].size();var step=maxi(1,a[Mesh.ARRAY_VERTEX].size()/24)
   for k in range(0,a[Mesh.ARRAY_VERTEX].size(),step):
    var p:Vector3=a[Mesh.ARRAY_VERTEX][k];var uv:Vector2=a[Mesh.ARRAY_TEX_UV][k];var uv2:Vector2=a[Mesh.ARRAY_TEX_UV2][k] if a[Mesh.ARRAY_TEX_UV2]!=null else Vector2(INF,INF)
    samples.append({'index':k,'position':[p.x,p.y,p.z],'uv0':[uv.x,uv.y],'uv1':[uv2.x,uv2.y],'custom0_xy':[custom[k*custom_stride],custom[k*custom_stride+1]] if custom_stride>=2 else null})
   var shader=''
   if m.has_method('get_shader_rid'):shader=RenderingServer.shader_get_code(m.get_shader_rid())
   rows.append({'node':n.name,'material':m.resource_name,'vertex_count':a[Mesh.ARRAY_VERTEX].size(),'samples':samples,'uv1_scale':[m.uv1_scale.x,m.uv1_scale.y],'uv1_offset':[m.uv1_offset.x,m.uv1_offset.y],'uv2_scale':[m.uv2_scale.x,m.uv2_scale.y],'uv2_offset':[m.uv2_offset.x,m.uv2_offset.y],'shader':shader})
 FileAccess.open(args[1],FileAccess.WRITE).store_string(JSON.stringify({'glb_sha256':FileAccess.get_sha256(args[0]),'engine':Engine.get_version_info(),'surfaces':rows},'  '));print('READ_ONLY_UV_IMPORT_RECEIPT ',rows.size());scene.free();quit()
