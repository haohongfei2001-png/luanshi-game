"""Retain professional sewn coat/folds, change whole military garment structure.
Long continuous inner tunic with walking splits and fitted sleeve ends. No new
primitive torso or plate cloud; original source remains separate and unchanged.
"""
import bpy,sys,pathlib,json,bmesh
from mathutils import Vector
from mathutils.bvhtree import BVHTree
src,out=map(pathlib.Path,sys.argv[sys.argv.index('--')+1:]);out.mkdir(parents=True,exist_ok=True)
bpy.ops.wm.open_mainfile(filepath=str(src),use_scripts=False,load_ui=False);rig=bpy.data.objects['MH163'];rig.data.pose_position='REST';coat=bpy.data.objects['V2_complete_coat_fit'];body=bpy.data.objects['Body_SourceFull']
def smooth(a,b,x):t=max(0,min(1,(x-a)/(b-a)));return t*t*(3-2*t)
for v in coat.data.vertices:
 p=v.co.copy();inner=1-smooth(.19,.26,abs(p.x));hem=(1-smooth(.94,1.075,p.z))*inner
 v.co.z-=.31*hem;v.co.x*=1+.10*hem;v.co.y=-.02+(v.co.y+.02)*(1+.07*hem)
 # Continuous sleeve taper driven by forearm coordinates, not arbitrary global X.
 side='L' if p.x>0 else 'R';a=rig.data.bones['lowerarm01.'+side].head_local;b=rig.data.bones['wrist.'+side].head_local;axis=b-a;t=(p-a).dot(axis)/axis.length_squared
 if -.1<t<1.2 and abs(p.x)>.28:
  c=a+axis*t;radial=p-c;v.co-=radial*(.32*smooth(.10,.95,t))
coat.data.update()
# Real front/back walking slits in lower garment; keep all upper sewn topology.
bm=bmesh.new();bm.from_mesh(coat.data);remove=[]
for f in bm.faces:
 c=f.calc_center_median()
 if c.z<.81 and abs(c.x)<.009 and abs(c.y+.02)>.05:remove.append(f)
bmesh.ops.delete(bm,geom=remove,context='FACES');bm.to_mesh(coat.data);bm.free()
body.data.calc_loop_triangles();verts=[v.co.copy() for v in body.data.vertices];tris=[tuple(t.vertices) for t in body.data.loop_triangles];tree=BVHTree.FromPolygons(verts,tris,all_triangles=True);names={g.index:g.name for g in body.vertex_groups}
# New longer hem must follow natural thighs, not remain weighted to old waist.
for group in list(coat.vertex_groups):coat.vertex_groups.remove(group)
groups={n:coat.vertex_groups.new(name=n) for n in names.values()}
for v in coat.data.vertices:
 p,n,idx,d=tree.find_nearest(v.co);ids=tris[idx];a,b,c=[verts[i] for i in ids];u=b-a;w=c-a;q=p-a;den=u.dot(u)*w.dot(w)-u.dot(w)**2
 if abs(den)<1e-14:ws=[1,0,0]
 else:
  y=(w.dot(w)*q.dot(u)-u.dot(w)*q.dot(w))/den;z=(u.dot(u)*q.dot(w)-u.dot(w)*q.dot(u))/den;ws=[max(0,1-y-z),max(0,y),max(0,z)]
 acc={}
 for i,k in zip(ids,ws):
  for g in body.data.vertices[i].groups:acc[names[g.group]]=acc.get(names[g.group],0)+k*g.weight
 total=sum(acc.values())
 for name,w in acc.items():
  if w>0:groups[name].add([v.index],w/total,'REPLACE')
bpy.context.preferences.filepaths.save_version=0;bpy.ops.wm.save_as_mainfile(filepath=str(out/'long-uniform-high.blend'))
(out/'retailor-report.json').write_text(json.dumps({'status':'WHOLE_GARMENT_RETAILOR_WIP','source_coat_topology':'complete sewn professional coat with lower walking slits','vertices':len(coat.data.vertices),'hem_extension_m':.31,'sleeve_taper_max':.32,'normal_rebake':'REQUIRED_NEXT','art_acceptance':False},indent=2)+'\n')
