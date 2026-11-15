"""Isolated production-v2 complete-coat transfer. Not a visual acceptance claim.
Preserves source inputs; replaces old Guardian silhouette/rig in a derivative.
"""
import bpy,sys,pathlib,json,hashlib,math
from mathutils import Vector, Matrix
from mathutils.bvhtree import BVHTree
coat_path,body_path,out=map(pathlib.Path,sys.argv[sys.argv.index('--')+1:]);out.mkdir(parents=True,exist_ok=True)
bpy.ops.wm.open_mainfile(filepath=str(coat_path),use_scripts=False,load_ui=False)
coat=bpy.data.objects['GEO-topLT-recut'];rig=bpy.data.objects['rig']
for m in coat.modifiers:
 if m.type=='SOLIDIFY':m.show_viewport=False
bpy.context.view_layer.update();dg=bpy.context.evaluated_depsgraph_get();ev=coat.evaluated_get(dg)
mesh=bpy.data.meshes.new_from_object(ev,preserve_all_data_layers=True,depsgraph=dg)
coords=[coat.matrix_world@v.co for v in mesh.vertices]
# The input is already posed. Use actual posed author joints, NOT rest joints.
def src_joint(n):return rig.matrix_world@rig.pose.bones[n].head
source_joints={s:[src_joint('upper_arm.'+s),src_joint('forearm.'+s),rig.matrix_world@rig.pose.bones['forearm.'+s].tail] for s in ['L','R']}
mesh.name='Complete_professional_coat_UV_derivative';mesh.use_fake_user=True
# Remove old objects only in this newly loaded in-memory derivative.
for ob in list(bpy.data.objects):bpy.data.objects.remove(ob,do_unlink=True)
with bpy.data.libraries.load(str(body_path),link=False) as (a,b):b.objects=list(a.objects);b.actions=list(a.actions)
for action in b.actions:
 if action:action.use_fake_user=True
for ob in b.objects:
 if ob:bpy.context.scene.collection.objects.link(ob)
bpy.context.scene.render.fps=120;bpy.context.scene.render.fps_base=1
target=bpy.data.objects['MH163'];target.animation_data_clear();target.data.pose_position='REST'
for p in target.pose.bones:p.matrix_basis.identity()
body=bpy.data.objects['Body_SourceFull'];body.hide_set(False);body.hide_render=False
for ob in bpy.data.objects:
 if ob.name in ('Cross-front robe','Body_AuthorGarmentOcclusion'):ob.hide_render=True;ob.hide_set(True)
def joint(n):return target.matrix_world@target.data.bones[n].head_local
target_joints={s:[joint('upperarm01.'+s),joint('lowerarm01.'+s),joint('wrist.'+s)] for s in ['L','R']}
def frame(a,b):
 y=(b-a).normalized();x=Vector((0,-1,0)).cross(y).normalized();z=x.cross(y).normalized();return Matrix((x,y,z)).transposed()
def limb(p,a,b,c,d):
 q=frame(a,b).transposed()@(p-a);q.y*=(d-c).length/(b-a).length;q.x*=.83;q.z*=.83;return c+frame(c,d)@q
# Full torso derives from anatomical shoulder level and width, not old chest plates.
scenter=(source_joints['L'][0]+source_joints['R'][0])/2;tcenter=(target_joints['L'][0]+target_joints['R'][0])/2
scale=(target_joints['L'][0]-target_joints['R'][0]).length/(source_joints['L'][0]-source_joints['R'][0]).length
def smooth(a,b,x):t=max(0,min(1,(x-a)/(b-a)));return t*t*(3-2*t)
for v,p in zip(mesh.vertices,coords):
 s='L' if p.x>=0 else 'R';a,b,c=source_joints[s];d,e,f=target_joints[s]
 torso=tcenter+Vector(((p.x-scenter.x)*max(scale,.82),(p.y-scenter.y)*.72,(p.z-scenter.z)*.82))
 u=(p-a).dot(b-a)/(b-a).length_squared
 arm=limb(p,a,b,d,e).lerp(limb(p,b,c,e,f),smooth(.7,1.12,u))
 weight=smooth(abs(a.x)*.80,abs(a.x)*1.28,abs(p.x))*smooth(a.z-.20,a.z-.04,p.z)
 v.co=torso.lerp(arm,weight)
ob=bpy.data.objects.new('V2_complete_coat_fit',mesh);bpy.context.scene.collection.objects.link(ob)
# Nearest body triangle barycentric transfer, all source influences retained.
body.data.calc_loop_triangles();verts=[body.matrix_world@v.co for v in body.data.vertices];tris=[tuple(t.vertices) for t in body.data.loop_triangles];tree=BVHTree.FromPolygons(verts,tris,all_triangles=True)
vg={g.index:g.name for g in body.vertex_groups};groups={n:ob.vertex_groups.new(name=n) for n in vg.values()};dist=[]
for v in mesh.vertices:
 p,n,idx,d=tree.find_nearest(v.co);dist.append(d);ids=tris[idx];a,b,c=[verts[i] for i in ids];u=b-a;w=c-a;q=p-a;den=u.dot(u)*w.dot(w)-u.dot(w)**2
 if abs(den)<1e-15:weights=[1,0,0]
 else:
  y=(w.dot(w)*q.dot(u)-u.dot(w)*q.dot(w))/den;z=(u.dot(u)*q.dot(w)-u.dot(w)*q.dot(u))/den;weights=[max(0,1-y-z),max(0,y),max(0,z)]
 acc={}
 for i,k in zip(ids,weights):
  for g in body.data.vertices[i].groups:acc[vg[g.group]]=acc.get(vg[g.group],0)+k*g.weight
 total=sum(acc.values())
 for name,w in acc.items():
  if w>0:groups[name].add([v.index],w/total,'REPLACE')
mod=ob.modifiers.new('Shared natural adult full rig','ARMATURE');mod.object=target
bpy.context.preferences.filepaths.save_version=0
bpy.ops.wm.save_as_mainfile(filepath=str(out/'natural-full-coat-fit.blend'))
report={'source_coat_sha256':hashlib.sha256(coat_path.read_bytes()).hexdigest(),'natural_source_sha256':hashlib.sha256(body_path.read_bytes()).hexdigest(),'vertices':len(mesh.vertices),'uv':[x.name for x in mesh.uv_layers],'max_body_distance':max(dist),'mean_body_distance':sum(dist)/len(dist),'rig':target.name,'status':'FIT_DERIVATIVE_NOT_VISUALLY_ACCEPTED','normal_bake':'PENDING','runtime':'NOT_RUN'}
(out/'fit-report.json').write_text(json.dumps(report,indent=2)+'\n')
