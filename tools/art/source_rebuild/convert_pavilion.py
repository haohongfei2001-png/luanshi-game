import bpy,json,os,sys
args=sys.argv[sys.argv.index('--')+1:];source,out=args
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.fbx(filepath=source)
objects=[]
for ob in bpy.data.objects:
 if ob.type=='MESH':
  me=ob.data;me.calc_loop_triangles()
  objects.append({'name':ob.name,'vertices':len(me.vertices),'tris':len(me.loop_triangles),'materials':[x.name for x in me.materials], 'dimensions':list(ob.dimensions),'location':list(ob.location)})
report={'source':source,'meshes':len(objects),'vertices':sum(x['vertices'] for x in objects),'triangles':sum(x['tris'] for x in objects),'objects':objects}
print('ASSET_REPORT',json.dumps(report,ensure_ascii=False));open(out+'.json','w').write(json.dumps(report,ensure_ascii=False,indent=2))
bpy.ops.wm.save_as_mainfile(filepath=out+'.blend')
bpy.ops.export_scene.gltf(filepath=out+'.glb',export_format='GLB')
