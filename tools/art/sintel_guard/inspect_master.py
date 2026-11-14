"""Read original guarded source, no embedded Python execution, no rebinding/export.
Inspect full native structures and explicitly detect evaluation failure.
"""
import bpy,pathlib,sys,json,hashlib,math
args=sys.argv[sys.argv.index('--')+1:];source,out=map(pathlib.Path,args[:2]);out.mkdir(parents=True,exist_ok=True)
digest=hashlib.sha256(source.read_bytes()).hexdigest()
bpy.ops.wm.open_mainfile(filepath=str(source),load_ui=False,use_scripts=False)
r={'source_sha256':digest,'autoexec':False,'objects':[],'drivers':[],'collections':{},'embedded_texts':[],'evaluation':[]}
for t in bpy.data.texts:r['embedded_texts'].append({'name':t.name,'sha256':hashlib.sha256(t.as_string().encode()).hexdigest(),'executed':False})
for c in bpy.data.collections:r['collections'][c.name]=[o.name for o in c.objects]
for ob in bpy.data.objects:
 if ob.type=='ARMATURE':
  r['objects'].append({'name':ob.name,'type':ob.type,'bones':len(ob.data.bones),'deform_bones':sum(b.use_deform for b in ob.data.bones),'pose_mode':ob.data.pose_position,'constraints':sum(len(p.constraints) for p in ob.pose.bones)})
 elif ob.type=='MESH' and ob.name.startswith('GEO'):
  r['objects'].append({'name':ob.name,'type':ob.type,'vertices':len(ob.data.vertices),'polygons':len(ob.data.polygons),'uv':[l.name for l in ob.data.uv_layers],'hidden_render':ob.hide_render,'modifiers':[{'name':m.name,'type':m.type,'viewport':m.show_viewport,'render':m.show_render} for m in ob.modifiers],'material_slots':[m.name if m else None for m in ob.data.materials]})
 for data in [ob,ob.data]:
  if data and getattr(data,'animation_data',None):
   for d in data.animation_data.drivers:r['drivers'].append({'owner':ob.name,'path':d.data_path,'expression':d.driver.expression,'type':d.driver.type,'valid':d.is_valid})
(out/'before-evaluation.json').write_text(json.dumps(r,indent=2)+'\n')
print('GUARD_SOURCE_INVENTORY_SAVED',flush=True)
# Do not alter the modifier stack. Evaluate only authored geometry, report each result.
depsgraph=bpy.context.evaluated_depsgraph_get()
for name in ['GEO-topLT','GEO-pantsLT.001','GEO-bootsLT.001','GEO-headLT','GEO-torso-beltsLT.001']:
 ob=bpy.data.objects.get(name)
 if ob is None:continue
 print('EVALUATING',name,flush=True)
 ev=ob.evaluated_get(depsgraph);me=ev.to_mesh();points=[ev.matrix_world@v.co for v in me.vertices]
 r['evaluation'].append({'name':name,'vertices':len(points),'finite':all(all(math.isfinite(x) for x in p) for p in points),'world_min':[min(p[i] for p in points) for i in range(3)],'world_max':[max(p[i] for p in points) for i in range(3)]});ev.to_mesh_clear()
 assert hashlib.sha256(source.read_bytes()).hexdigest()==digest
 (out/'evaluated.json').write_text(json.dumps(r,indent=2)+'\n')
print('GUARD_SOURCE_EVAL_DONE',flush=True)
