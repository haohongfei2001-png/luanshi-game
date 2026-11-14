"""Surface compatibility probe; preserves all source multires levels. No acceptance claim."""
import bpy,json,pathlib,sys,hashlib
from mathutils.bvhtree import BVHTree
src,out=sys.argv[sys.argv.index('--')+1:][:2]
bpy.ops.wm.open_mainfile(filepath=src,use_scripts=False,load_ui=False)
b=bpy.data.objects['GEO-bootsLT.001'];w=[o for o in bpy.context.scene.objects if o.name.startswith('CLOTH continuous bound puttee')]
m=next(m for m in b.modifiers if m.type=='MULTIRES');original=m.levels

def tree(o):
 e=o.evaluated_get(bpy.context.evaluated_depsgraph_get());me=e.to_mesh();me.calc_loop_triangles();v=[e.matrix_world@x.co for x in me.vertices];f=[tuple(t.vertices) for t in me.loop_triangles];t=BVHTree.FromPolygons(v,f,all_triangles=True);e.to_mesh_clear();return t
rows=[]
for level in sorted(set([1,original,m.total_levels])):
 m.levels=level;bpy.context.view_layer.update();bt=tree(b)
 rows.append({'level':level,'wrap_intersections':{o.name:len(tree(o).overlap(bt)) for o in w}})
r={'source_sha256':hashlib.file_digest(open(src,'rb'),'sha256').hexdigest(),'rows':rows,'source_level':original,'total_levels':m.total_levels,'not_art_pass':True};pathlib.Path(out).write_text(json.dumps(r,indent=2));print(r)
