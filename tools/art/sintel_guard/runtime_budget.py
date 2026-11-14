"""Measure intact visible native character; no destructive LOD or runtime rig claims."""
import bpy,pathlib,sys,json,hashlib,math
args=sys.argv[sys.argv.index('--')+1:];src,out=map(pathlib.Path,args[:2]);out.parent.mkdir(parents=True,exist_ok=True)
sha=hashlib.sha256(src.read_bytes()).hexdigest();bpy.ops.wm.open_mainfile(filepath=str(src),load_ui=False,use_scripts=False)
render_level_probe=len(args)>2 and args[2]=='--render-levels'
if render_level_probe:
 for obj in bpy.context.scene.objects:
  for mod in obj.modifiers:
   mod.show_viewport=mod.show_render
   if mod.type in {'SUBSURF','MULTIRES'}:mod.levels=mod.render_levels
 bpy.context.view_layer.update()
dg=bpy.context.evaluated_depsgraph_get();rows=[]
for obj in bpy.context.scene.objects:
 if obj.type!='MESH' or obj.hide_render or not obj.visible_get():continue
 ev=obj.evaluated_get(dg);me=ev.to_mesh();me.calc_loop_triangles()
 rows.append({'name':obj.name,'base_vertices':len(obj.data.vertices),'base_faces':len(obj.data.polygons),'evaluated_vertices':len(me.vertices),'evaluated_triangles':len(me.loop_triangles),'original_uv_layers':[u.name for u in obj.data.uv_layers],'materials':[s.material.name if s.material else None for s in obj.material_slots],'shape_keys':len(obj.data.shape_keys.key_blocks) if obj.data.shape_keys else 0,'native_modifiers':[{'type':m.type,'viewport':m.show_viewport,'render':m.show_render,'levels':getattr(m,'levels',None),'render_levels':getattr(m,'render_levels',None),'total_levels':getattr(m,'total_levels',None),'cage':getattr(getattr(m,'object',None),'name',None)} for m in obj.modifiers]});ev.to_mesh_clear()
r={'source_sha256':sha,'source_unchanged':hashlib.sha256(src.read_bytes()).hexdigest()==sha,'mode':'actual depsgraph with render-level modifiers in memory; particles excluded' if render_level_probe else 'actual viewport depsgraph, not render subdivision or exported GLB','meshes':rows,'total_evaluated_triangles':sum(x['evaluated_triangles'] for x in rows),'total_evaluated_vertices':sum(x['evaluated_vertices'] for x in rows),'no_decimation':True,'no_rebind':True,'runtime_export':'NOT_IMPLEMENTED','gpu_performance':'NOT_TESTED'}
out.write_text(json.dumps(r,indent=2)+'\n');print('BUDGET',len(rows),r['total_evaluated_triangles'],flush=True)
