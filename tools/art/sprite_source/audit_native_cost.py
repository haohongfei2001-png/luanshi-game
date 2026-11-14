"""Source evaluation inventory, no rendering and no source writes."""
import bpy,json,pathlib,sys,resource
source,collection_name,out=sys.argv[sys.argv.index('--')+1:]
bpy.ops.wm.read_factory_settings(use_empty=True)
with bpy.data.libraries.load(source,link=False) as (a,b):b.collections=[collection_name]
bpy.context.scene.collection.children.link(b.collections[0]);s=bpy.context.scene
s.render.use_simplify=True;s.render.simplify_subdivision=1;s.render.simplify_subdivision_render=1
cost={};deps=bpy.context.evaluated_depsgraph_get()
for inst in deps.object_instances:
 o=inst.object
 if o.type!='MESH' or o.hide_render or not inst.show_self:continue
 key=o.original.name
 if key not in cost:
  mesh=o.to_mesh();tri=sum(len(p.vertices)-2 for p in mesh.polygons);o.to_mesh_clear()
  cost[key]={'name':key,'source_data':o.original.data.name,'triangles_each':tri,'instances':0,'materials':[m.name for m in o.original.data.materials if m]}
 cost[key]['instances']+=1
rows=sorted(cost.values(),key=lambda x:x['triangles_each']*x['instances'],reverse=True)
pathlib.Path(out).write_text(json.dumps({'source':source,'collection':collection_name,'subdivision_cap':1,'rows':rows,'triangles':sum(r['triangles_each']*r['instances'] for r in rows),'peak_rss_kib_linux':resource.getrusage(resource.RUSAGE_SELF).ru_maxrss},indent=2))
