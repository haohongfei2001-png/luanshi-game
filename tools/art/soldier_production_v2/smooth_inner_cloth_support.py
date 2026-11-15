"""Diffuse measured inner-cloth skin discontinuities, not rigid armor or body.
Retains source topology, UV, positions and all actions. Requires unchanged gate.
"""
import bpy,sys,pathlib,numpy as np,json
src,out=map(pathlib.Path,sys.argv[sys.argv.index('--')+1:]);out.mkdir(parents=True,exist_ok=True)
bpy.ops.wm.open_mainfile(filepath=str(src),use_scripts=False,load_ui=False)
o=bpy.data.objects['V2_complete_coat_runtime'];names=[g.name for g in o.vertex_groups];w=np.zeros((len(o.data.vertices),len(names)))
for v in o.data.vertices:
 for g in v.groups:w[v.index,g.group]=g.weight
nb=[set() for v in o.data.vertices]
for e in o.data.edges:a,b=e.vertices;nb[a].add(b);nb[b].add(a)
def smooth(a,b,x):
 t=max(0,min(1,(x-a)/(b-a)));return t*t*(3-2*t)
mask=np.array([smooth(.68,.80,v.co.z)*(1-smooth(1.25,1.35,v.co.z))*(1-smooth(.24,.34,abs(v.co.x))) for v in o.data.vertices])
# Diffuse across real connected cloth, so near-seam vertices share a continuous
# support field, while actual disconnected lower panels remain separate.
for step in range(24):
 new=w.copy()
 for i,n in enumerate(nb):
  if n and mask[i]>0:new[i]=w[i]*(1-.7*mask[i])+np.mean(w[list(n)],axis=0)*(.7*mask[i])
 w=new
for v in o.data.vertices:
 if mask[v.index]<=0:continue
 for g in list(v.groups):o.vertex_groups[g.group].remove([v.index])
 row=w[v.index];row/=max(row.sum(),1e-20)
 for k,value in enumerate(row):
  if value>1e-8:o.vertex_groups[k].add([v.index],float(value),'REPLACE')
bpy.context.preferences.filepaths.save_version=0
bpy.ops.wm.save_as_mainfile(filepath=str(out/'supported-uniform-editable.blend'))
(out/'cloth-support.json').write_text(json.dumps({'status':'UNTESTED','changed_object':o.name,'changed_vertices':int(sum(mask>0)),'iterations':24,'positions_uv_topology_unchanged':True,'rigid_armor_unchanged':True,'body_unchanged':True},indent=2))
