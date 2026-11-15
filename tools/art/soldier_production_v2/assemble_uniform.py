"""Complete coherent military outfit on natural MH body, isolated WIP source.
Continuous fitted garment surfaces carry lamellar relief in texture. No plate
cloud or per-lamella meshes. Complete source high coat retained but excluded.
"""
import bpy,sys,pathlib,math,json
from mathutils import Vector
from mathutils.bvhtree import BVHTree
src,maps,out,natural_source=map(pathlib.Path,sys.argv[sys.argv.index('--')+1:]);out.mkdir(parents=True,exist_ok=True)
bpy.ops.wm.open_mainfile(filepath=str(src),use_scripts=False,load_ui=False);rig=bpy.data.objects['MH163'];rig.data.pose_position='REST'
body=bpy.data.objects['Body_SourceFull'];coat=bpy.data.objects['V2_complete_coat_runtime']
# Work entirely in source natural meters. Existing source axes/UV are unchanged.
def mat(name,c,r=.8,metal=0):
 m=bpy.data.materials.new(name);m.use_nodes=True;b=m.node_tree.nodes.get('Principled BSDF');b.inputs['Base Color'].default_value=(*c,1);b.inputs['Roughness'].default_value=r;b.inputs['Metallic'].default_value=metal;return m
cloth=coat.data.materials[0];cloth.node_tree.nodes.get('Principled BSDF').inputs['Base Color'].default_value=(.35,.31,.24,1)
iron=mat('V2 controlled slate iron',(.17,.20,.22),.68,.42);leather=mat('V2 dark warm leather',(.09,.045,.024));red=mat('V2 madder waist cloth',(.25,.075,.045));puttee=mat('V2 warm linen binding',(.39,.34,.25));dark=mat('V2 dark woven trousers',(.10,.12,.12))
armor=mat('V2 continuous lamellar cuirass',(.2,.24,.25));nodes=armor.node_tree.nodes;links=armor.node_tree.links;bs=nodes.get('Principled BSDF')
for f,key in [('lamellar-basecolor.png','Base Color'),('lamellar-normal.png','Normal'),('lamellar-orm.png','ORM')]:
 t=nodes.new('ShaderNodeTexImage');t.image=bpy.data.images.load(str(maps/f));t.extension='REPEAT'
 if key=='Base Color':links.new(t.outputs['Color'],bs.inputs[key])
 else:
  t.image.colorspace_settings.name='Non-Color'
  if key=='Normal':n=nodes.new('ShaderNodeNormalMap');links.new(t.outputs['Color'],n.inputs['Color']);links.new(n.outputs['Normal'],bs.inputs['Normal'])
  else:
   sep=nodes.new('ShaderNodeSeparateColor');links.new(t.outputs['Color'],sep.inputs[0]);links.new(sep.outputs['Green'],bs.inputs['Roughness']);links.new(sep.outputs['Blue'],bs.inputs['Metallic'])
# Correct official transparent eye outer material; packed source images survive.
for m in bpy.data.materials:
 if m.name.startswith('Original Eyes') and m.use_nodes:
  b=m.node_tree.nodes.get('Principled BSDF');t=next((n for n in m.node_tree.nodes if n.type=='TEX_IMAGE'),None)
  if t: m.node_tree.links.new(t.outputs['Alpha'],b.inputs['Alpha']);m.surface_render_method='DITHERED'
body.data.calc_loop_triangles();bv=[body.matrix_world@v.co for v in body.data.vertices];bt=[tuple(t.vertices) for t in body.data.loop_triangles];tree=BVHTree.FromPolygons(bv,bt,all_triangles=True);names={g.index:g.name for g in body.vertex_groups}
coat_tree=BVHTree.FromPolygons([coat.matrix_world@v.co for v in coat.data.vertices],[list(p.vertices) for p in coat.data.polygons])
parts=[]
def skin(o,rigid=None):
 groups={n:o.vertex_groups.new(name=n) for n in ([rigid] if rigid else names.values())}
 for v in o.data.vertices:
  if rigid:groups[rigid].add([v.index],1,'REPLACE');continue
  p,n,idx,d=tree.find_nearest(v.co);ids=bt[idx];a,b,c=[bv[i] for i in ids];u=b-a;w=c-a;q=p-a;den=u.dot(u)*w.dot(w)-u.dot(w)**2
  if abs(den)<1e-14:ws=[1,0,0]
  else:
   yy=(w.dot(w)*q.dot(u)-u.dot(w)*q.dot(w))/den;zz=(u.dot(u)*q.dot(w)-u.dot(w)*q.dot(u))/den;ws=[max(0,1-yy-zz),max(0,yy),max(0,zz)]
  acc={}
  for i,k in zip(ids,ws):
   for g in body.data.vertices[i].groups:acc[names[g.group]]=acc.get(names[g.group],0)+k*g.weight
  total=sum(acc.values())
  for n,w in acc.items():
   if w>0:groups[n].add([v.index],w/total,'REPLACE')
 m=o.modifiers.new('Shared full natural-body skin','ARMATURE');m.object=rig;o.parent=rig

def patch(name,rows,cols,fn,material,uvscale=(1,1),rigid=None,thick=.003):
 verts=[];faces=[]
 for r in range(rows+1):
  for c in range(cols+1):verts.append(fn(c/cols,r/rows))
 for r in range(rows):
  for c in range(cols):i=r*(cols+1)+c;faces.append((i,i+1,i+cols+2,i+cols+1))
 mesh=bpy.data.meshes.new(name);mesh.from_pydata(verts,[],faces);mesh.update();o=bpy.data.objects.new(name,mesh);bpy.context.collection.objects.link(o);mesh.materials.append(material);uv=mesh.uv_layers.new(name='Uniform structural UV')
 for p in mesh.polygons:
  p.use_smooth=True
  for li in p.loop_indices:
   i=mesh.loops[li].vertex_index;uv.data[li].uv=(i%(cols+1)/cols*uvscale[0],i//(cols+1)/rows*uvscale[1])
 if thick:
  s=o.modifiers.new('Real bound cloth thickness','SOLIDIFY');s.thickness=thick;s.offset=0
 skin(o,rigid);parts.append(o);return o

def torso(u,v):
 angle=u*math.tau;top=1.282-.012*abs(math.sin(angle));z=.944+v*(top-.944)
 center=Vector((0,-.02,z));radial=Vector((math.sin(angle),-math.cos(angle),0))
 p,n,idx,d=coat_tree.ray_cast(center,radial,.35)
 if p is None:p=center+Vector((radial.x*.171,radial.y*.145,0))
 return p+radial*.007
patch('V2 continuous wrapped cuirass',20,64,torso,armor,(29,5))
# Six independent sewn skirt gores share a waist, with real walking slits.
for panel in range(6):
 a0=panel*math.tau/6+.055;a1=(panel+1)*math.tau/6-.055
 def skirt(u,v,a0=a0,a1=a1):
  a=a0+(a1-a0)*u;rx=.155+.037*v;ry=.12+.02*v;z=.979-.245*v+.008*math.cos(u*math.pi*2)*v
  return (rx*math.sin(a),-.005-ry*math.cos(a),z)
 patch('V2 bound short skirt gore '+str(panel),10,10,skirt,armor,(5,3.5))
# Complete short cloth under-tunic, six sewn gores; distinct lower cloth hem.
for panel in range(6):
 a0=panel*math.tau/6+.025;a1=(panel+1)*math.tau/6-.025
 def under_gore(u,v,a0=a0,a1=a1):
  a=a0+(a1-a0)*u;rx=.151+.044*v;ry=.116+.025*v
  return (rx*math.sin(a),-.005-ry*math.cos(a),.962-.283*v+.007*math.cos(u*math.pi*2)*v)
 patch('V2 sewn under-tunic gore '+str(panel),10,10,under_gore,cloth,(1,1),thick=.002)
# Real shoulder suspension straps connect the chest and back across source cloth.
for sign in [-1,1]:
 def strap(u,v,sign=sign):
  x=sign*(.084+u*.035);y=-.145+v*.270;p,n,i,d=coat_tree.ray_cast(Vector((x,y,1.55)),Vector((0,0,-1)),.35)
  return (x,y,(p.z if p is not None else 1.30)+.005)
 patch('V2 shoulder suspension strap '+str(sign),24,3,strap,leather,(1,2),thick=.004)
# Waist sash follows complete torso, not a stack of decorative hard rings.
def sash_point(u,v):
 p=Vector(torso(u,(.946+v*.055-.944)/(1.282-.944)));p+=Vector((math.sin(u*math.tau),-math.cos(u*math.tau),0))*.009;return p
patch('V2 continuous soft waist sash',4,64,sash_point,red,(2,1),thick=.006)
# Shoulders are continuous sleeve-following armor cloth, not floating tile grids.
for side in ['L','R']:
 a=rig.data.bones['upperarm01.'+side].head_local;b=rig.data.bones['lowerarm01.'+side].head_local;direction=(b-a).normalized();front=Vector((0,-1,0));up=direction.cross(front).normalized()
 if up.z<0:up=-up
 def shoulder(u,v,a=a,direction=direction,front=front,up=up):
  angle=(u-.5)*math.pi*1.28;center=a+direction*(-.015+.135*v);return center+front*math.sin(angle)*(.079+.006*v)+up*math.cos(angle)*(.079+.006*v)
 patch('V2 cloth backed shoulder '+side,9,16,shoulder,armor,(7,2),thick=.004)
# Head-size driven formed helmet, open face and bound neck protection.
top=max(v.z for v in bv);headpoints=[v for v in bv if v.z>top-.15]
cy=(min(v.y for v in headpoints)+max(v.y for v in headpoints))/2
rx=max(abs(v.x) for v in headpoints)+.011;ry=(max(v.y for v in headpoints)-min(v.y for v in headpoints))/2+.012;brow=top-.079
patch('V2 formed iron helmet',12,48,lambda u,v:(rx*math.cos(v*math.pi/2)*math.sin(u*math.tau),cy-ry*math.cos(v*math.pi/2)*math.cos(u*math.tau),brow+.098*math.sin(v*math.pi/2)),iron,rigid='head')
patch('V2 bound brow band',2,48,lambda u,v:((rx+.002)*math.sin(u*math.tau),cy-(ry+.002)*math.cos(u*math.tau),brow-.009+v*.021),leather,rigid='head',thick=.004)
patch('V2 continuous ear and nape guard',7,38,lambda u,v:((rx+.014*v)*math.sin(.83+u*(math.tau-1.66)),cy-(ry+.014*v)*math.cos(.83+u*(math.tau-1.66)),brow-.125*v),iron,rigid='head')
pants_source=bpy.data.objects['Wool trousers'];pants_tree=BVHTree.FromPolygons([pants_source.matrix_world@v.co for v in pants_source.data.vertices],[list(p.vertices) for p in pants_source.data.polygons])
# Taper the lower trouser cloth onto natural shins before adding puttees.
for v in pants_source.data.vertices:
 if .10<v.co.z<.43:
  side='L' if v.co.x>0 else 'R';k=rig.data.bones['lowerleg01.'+side].head_local;f=rig.data.bones['foot.'+side].head_local
  t=max(0,min(1,(v.co.z-f.z)/(k.z-f.z)));c=f.lerp(k,t);blend=min(1,(v.co.z-.10)/.05,(.43-v.co.z)/.05)
  v.co.x=c.x+(v.co.x-c.x)*(1-.24*blend);v.co.y=c.y+(v.co.y-c.y)*(1-.24*blend)
pants_source.data.update();pants_tree=BVHTree.FromPolygons([pants_source.matrix_world@v.co for v in pants_source.data.vertices],[list(p.vertices) for p in pants_source.data.polygons])
# Puttees conform around real calf centers; keep actual source shoes.
for side in ['L','R']:
 knee=rig.data.bones['lowerleg01.'+side].head_local;foot=rig.data.bones['foot.'+side].head_local
 def calf(u,v,k=knee,f=foot):
  c=f.lerp(k,.08+.73*v);a=u*math.tau;radial=Vector((math.sin(a),math.cos(a),0));p,n,i,d=pants_tree.ray_cast(c,radial,.16)
  return (p if p is not None else c+radial*.065)+radial*.005
 patch('V2 linen calf wrap '+side,10,24,calf,puttee,(1,1),thick=.003)
# Trousers retain source folds/UV, controlled palette removes modern visual emphasis.
pants=bpy.data.objects['Wool trousers'];pants.data.materials.clear();pants.data.materials.append(dark)
# Hidden original high/source body and robe preserved; expose only render body.
for ob in bpy.data.objects:
 if ob.name in ['Cross-front robe','Body_AuthorGarmentOcclusion','V2_complete_coat_fit']:ob.hide_render=True;ob.hide_set(True)
body.hide_render=False;body.hide_set(False)
# Restore and retain the nine actual full-MH actions explicitly. Appending only
# objects does not transfer unassigned Action datablocks and cannot be trusted.
with bpy.data.libraries.load(str(natural_source),link=False) as (a,b):b.actions=list(a.actions)
for action in b.actions:
 if action:action.use_fake_user=True
assert all(n in bpy.data.actions for n in ['Idle_Loop','Walk_Loop','Hit_Chest','Death01'])
# Hide only covered anatomical faces in a separate runtime copy, never erase
# the full editable body. Preserve head/neck/hands, avoid body through puttees.
import bmesh
runtime_body=body.copy();runtime_body.data=body.data.copy();runtime_body.name='Body_RuntimeClothingOcclusion';bpy.context.collection.objects.link(runtime_body)
hand_groups={g.index for g in body.vertex_groups if g.name.startswith(('wrist','finger','metacarpal'))}
keep=[]
for p in runtime_body.data.polygons:
 keep.append(any(runtime_body.data.vertices[i].co.z>1.33 or sum(g.weight for g in runtime_body.data.vertices[i].groups if g.group in hand_groups)>.45 for i in p.vertices))
bm=bmesh.new();bm.from_mesh(runtime_body.data);bm.faces.ensure_lookup_table();bmesh.ops.delete(bm,geom=[f for f,k in zip(bm.faces,keep) if not k],context='FACES');bm.to_mesh(runtime_body.data);bm.free()
body.hide_render=True;body.hide_set(True);runtime_body.hide_render=False;runtime_body.hide_set(False)
# Pack material inputs so the editable derivative has no ephemeral dependencies.
for im in bpy.data.images:
 if im.source=='FILE' and not im.packed_file:
  try:im.pack()
  except RuntimeError:pass
bpy.context.preferences.filepaths.save_version=0;bpy.ops.wm.save_as_mainfile(filepath=str(out/'uniform-complete-editable.blend'))
report={'status':'WHOLE_UNIFORM_WIP_NOT_ACCEPTED','added_surfaces':len(parts),'lamella_individual_meshes':0,'rig':'MH163','materials':'controlled PBR; real coat-fold normal + authored lamellar structural relief','texture_origin':'project authored construction maps, not external CC0','animations':'source clips preserved as data; new spear independently pending','godot':'NOT_RUN','visual_acceptance':False}
(out/'uniform-report.json').write_text(json.dumps(report,indent=2)+'\n')
