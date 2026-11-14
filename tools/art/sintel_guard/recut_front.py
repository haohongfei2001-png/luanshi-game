"""Whole original garment recut along mesh-edge seams, with sewn replacement panels.
Independent source derivative. No overlay mesh, old front faces are removed.
"""
import bpy,sys,pathlib,json,hashlib,heapq,math
from mathutils import Vector
from mathutils.bvhtree import BVHTree
src,out=map(pathlib.Path,sys.argv[sys.argv.index('--')+1:][:2]);out.mkdir(parents=True,exist_ok=True)
before=hashlib.sha256(src.read_bytes()).hexdigest();bpy.ops.wm.open_mainfile(filepath=str(src),load_ui=False,use_scripts=False)
rig=bpy.data.objects['rig'];cage=bpy.data.objects['GEO-deformation_cage'];ob=bpy.data.objects['GEO-topLT']
# Bake two subdivisions of ORIGINAL sculpt to retain complete sleeve/back wrinkles.
# Original high Multires and editable control cage remain in the exact source file.
for m in ob.modifiers:
 if m.type=='MULTIRES':m.levels=2
bpy.context.view_layer.update();dg=bpy.context.evaluated_depsgraph_get();ev=ob.evaluated_get(dg);me=ev.to_mesh()
verts=[ev.matrix_world@v.co for v in me.vertices];faces=[list(f.vertices) for f in me.polygons];uvs=[[tuple(me.uv_layers.active.data[i].uv) for i in f.loop_indices] for f in me.polygons]
bvh=BVHTree.FromPolygons(verts,faces);ev.to_mesh_clear()
edgefaces={};adj=[set() for _ in verts]
for fi,f in enumerate(faces):
 for a,b in zip(f,f[1:]+f[:1]):
  edgefaces.setdefault(tuple(sorted((a,b))),[]).append(fi);adj[a].add(b);adj[b].add(a)
def nearest(p):return min(range(len(verts)),key=lambda i:(verts[i]-Vector(p)).length_squared)
def path(a,b):
 q=[(0,a)];ds={a:0};parent={}
 while q:
  d,u=heapq.heappop(q)
  if u==b:break
  if d>ds[u]:continue
  for v in adj[u]:
   cost=(verts[u]-verts[v]).length*(1+max(0,verts[v].y+.08)*100)
   if d+cost<ds.get(v,1e9):ds[v]=d+cost;parent[v]=u;heapq.heappush(q,(d+cost,v))
 result=[b]
 while result[-1]!=a:result.append(parent[result[-1]])
 return result[::-1]
def seam(sign):
 anchors=[(.085,-.13,1.76),(.14,-.21,1.65),(.16,-.24,1.50),(.14,-.24,1.32),(.14,-.23,1.21)]
 ids=[nearest((sign*x,y,z)) for x,y,z in anchors];result=[]
 for a,b in zip(ids,ids[1:]):result+=path(a,b)[:-1]
 result.append(ids[-1]);return result
left=seam(-1);right=seam(1)
# Explicit neck and hem closures form the cutting loop. Flood fill uses only these
# graph seams, never a body-coordinate threshold to delete anatomy or cloth.
top=path(left[0],right[0]);bottom=path(left[-1],right[-1]);cut=set()
for line in [left,right,top,bottom]:
 for a,b in zip(line,line[1:]):cut.add(tuple(sorted((a,b))))
centers=[sum((verts[i] for i in f),Vector())/len(f) for f in faces];seed=min(range(len(faces)),key=lambda i:(centers[i]-Vector((0,-.25,1.50))).length_squared)
remove={seed};queue=[seed]
while queue:
 f=faces[queue.pop()]
 for a,b in zip(f,f[1:]+f[:1]):
  e=tuple(sorted((a,b)))
  if e in cut:continue
  for k in edgefaces[e]:
   if k not in remove:remove.add(k);queue.append(k)
assert 50<len(remove)<len(faces)*.55,(len(remove),len(faces))
# Verify cut seams have a kept face on one side and replaced face on the other.
def boundary(line):
 return sum(any(i in remove for i in edgefaces[tuple(sorted((a,b)))]) and any(i not in remove for i in edgefaces[tuple(sorted((a,b)))]) for a,b in zip(line,line[1:]))
assert boundary(left)==len(left)-1 and boundary(right)==len(right)-1,'Cut does not form full sewn side seams'
kept=[(f,u) for i,(f,u) in enumerate(zip(faces,uvs)) if i not in remove];newfaces=[f for f,u in kept];newuv=[u for f,u in kept]
# New front pieces share ORIGINAL side seam vertex IDs. They are actual sewn
# members of the same garment mesh, not detached strips laid over old front faces.
def project(x,z,offset):
 hit=bvh.ray_cast(Vector((x,-1,z)),Vector((0,1,0)))
 if not hit[0]:raise RuntimeError('Front pattern has no original garment support')
 return Vector((x,hit[0].y-offset,z))
for side,line in [('left',left),('right',right)]:
 rows=[];columns=len(top)-1 if side=='right' else 12
 zs=[verts[i].z for i in line];hi=max(zs);lo=min(zs)
 for r,oldid in enumerate(line):
  p=verts[oldid];t=max(0,min(1,(hi-p.z)/(hi-lo)))
  # The free seam crosses towards the wearer's right; underlap is recessed.
  endx=(-.065+.19*t) if side=='left' else (-.09+.07*t)
  row=[oldid]
  if side=='right' and r==0:
   rows.append(list(reversed(top)));continue
  for c in range(1,columns+1):
   x=p.x+(endx-p.x)*c/columns
   v=project(x,p.z,.006 if side=='left' else .001)
   row.append(len(verts));verts.append(v)
  rows.append(row)
 for r in range(len(rows)-1):
  for c in range(columns):
   f=[rows[r][c],rows[r+1][c],rows[r+1][c+1],rows[r][c+1]]
   u=[(c/columns,r/(len(rows)-1)),(c/columns,(r+1)/(len(rows)-1)),((c+1)/columns,(r+1)/(len(rows)-1)),((c+1)/columns,r/(len(rows)-1))]
   if side=='right':f.reverse();u.reverse()
   newfaces.append(f);newuv.append(u)
# Failed hem experiment preserved, never enabled by default.
if '--rejected-hem' in sys.argv:
 # Extend the ORIGINAL connected lower hem as a tailored short-robe panel.
 # This is edge extrusion from authored clothing, not a body shell or separate skirt.
 boundary_edges=[e for e,fs in edgefaces.items() if len(fs)==1]
 badj={}
 for a,b in boundary_edges:badj.setdefault(a,[]).append(b);badj.setdefault(b,[]).append(a)
 seen=set();loops=[]
 for start in badj:
  if start in seen:continue
  loop=[start];prev=None;cur=start
  while True:
   nxt=next(v for v in badj[cur] if v!=prev)
   if nxt==start:break
   loop.append(nxt);prev,cur=cur,nxt
  seen.update(loop);loops.append(loop)
 hem=min(loops,key=lambda ids:sum(verts[i].z for i in ids)/len(ids))
 # Orient to oppose the existing face boundary when adding each new quad.
 a,b=hem[:2];fi=edgefaces[tuple(sorted((a,b)))][0];f=faces[fi]
 if not any(u==a and v==b for u,v in zip(f,f[1:]+f[:1])):hem.reverse()
 side_vents={min(range(len(hem)),key=lambda i:(verts[hem[i]]-Vector((sg*.2,-.1,1.21))).length_squared) for sg in [-1,1]}
 rows=[hem];nr=8
 for r in range(1,nr+1):
  t=r/nr;row=[]
  for old in hem:
   v=verts[old].copy();v.z-=.18*t;v.x*=1+.1*t;v.y=-.1+(v.y+.1)*(1+.04*t);row.append(len(verts));verts.append(v)
  rows.append(row)
 for r in range(nr):
  for i in range(len(hem)):
   if r>=3 and i in side_vents:continue
   k=(i+1)%len(hem);newfaces.append([rows[r][k],rows[r][i],rows[r+1][i],rows[r+1][k]])
   newuv.append([(k/len(hem),r/nr),(i/len(hem),r/nr),(i/len(hem),(r+1)/nr),(k/len(hem),(r+1)/nr)])
# Bake derivative low sculpt with new UV islands; no claim to preserve original
# Multires index identity after changing topology. Source high remains untouched.
mesh=bpy.data.meshes.new('Sewn full garment derivative');mesh.from_pydata(verts,[],newfaces);mesh.update();uv=mesh.uv_layers.new(name='SourceAndSewnUV')
for f,coords in zip(mesh.polygons,newuv):
 for li,t in zip(f.loop_indices,coords):uv.data[li].uv=t
 f.use_smooth=True
bpy.data.objects.remove(ob,do_unlink=True);ob=bpy.data.objects.new('GEO-topLT-recut',mesh);bpy.context.collection.objects.link(ob)
bpy.ops.object.select_all(action='DESELECT');ob.select_set(True);bpy.context.view_layer.objects.active=ob
# Independent expanded clothing envelope; original author cage remains untouched.
# The baked sculpt can lie outside the author's CONTROL mesh binding volume.
source_cage=cage;expanded=cage.copy();expanded.data=cage.data.copy();expanded.name='DERIVED cloth envelope';bpy.context.collection.objects.link(expanded)
for v in expanded.data.vertices:v.co+=v.normal*.035
expanded.hide_render=True;expanded.hide_set(False);cage=expanded
# Blender MeshDeform binding must see the SAME physical neutral cage as the
# evaluated garment. This source rig neutral differs from raw cage by 0.53 m.
# Temporarily expose exact evaluated cage coordinates during bind, then restore
# untouched raw cage + original armature. No source pose or weight is modified.
bpy.context.view_layer.update();ce=cage.evaluated_get(bpy.context.evaluated_depsgraph_get());cm=ce.to_mesh();neutral=[v.co.copy() for v in cm.vertices];ce.to_mesh_clear()
original_data=cage.data;snapshot=original_data.copy();cage.data=snapshot
for v,p in zip(snapshot.vertices,neutral):v.co=p
states=[(m,m.show_viewport,m.show_render) for m in cage.modifiers]
for m,_,_ in states:m.show_viewport=False;m.show_render=False
bpy.context.view_layer.update()
md=ob.modifiers.new('Rebound full neutral-pose cage','MESH_DEFORM');md.object=cage;md.precision=5
try:bpy.ops.object.meshdeform_bind(modifier=md.name);assert md.is_bound
finally:
 cage.data=original_data
 for m,a,b in states:m.show_viewport=a;m.show_render=b
 bpy.data.meshes.remove(snapshot)
bpy.context.view_layer.update()
solid=ob.modifiers.new('Turned cloth thickness','SOLIDIFY');solid.thickness=.002;solid.offset=0
for name in ['GEO-torso-beltsLT.001','GEO-symbolLT.001','GEO-symbolJA.005','GEO-symbolJA.006','GEO-toplaceLT.001','GEO-belt2JA.003','GEO-pant_detailsL_S','GEO-pant_detailsR_S','GEO-hoodLT','GEO-capeLT.001','GEO-headLT.003']:
 o=bpy.data.objects.get(name)
 if o:bpy.data.objects.remove(o,do_unlink=True)
mat=bpy.data.materials.new('Neutral tailoring inspection');mat.use_nodes=True;bs=mat.node_tree.nodes.get('Principled BSDF');bs.inputs['Base Color'].default_value=(.16,.24,.28,1);bs.inputs['Roughness'].default_value=.85
mesh.materials.append(mat)
def plain(name,color,rough=.8):
 m=bpy.data.materials.new(name);m.use_nodes=True;b=m.node_tree.nodes.get('Principled BSDF');b.inputs['Base Color'].default_value=(*color,1);b.inputs['Roughness'].default_value=rough;return m
cloth=plain('New indigo cloth',(.055,.105,.145));trouser=plain('New undyed trousers',(.27,.255,.22));leather=plain('New matte leather',(.085,.047,.027));skin=plain('New matte skin approximation',(.44,.265,.17),.72);hair=plain('New dark hair',(.012,.009,.006));eye=plain('Source eye diffuse only',(1,1,1),.25)
n=eye.node_tree.nodes.new('ShaderNodeTexImage');n.image=bpy.data.images.load(str(src.parent/'textures/sintel_eyeball_colour.png'),check_existing=True);eye.node_tree.links.new(n.outputs['Color'],eye.node_tree.nodes.get('Principled BSDF').inputs['Base Color'])
cornea=plain('New transmissive cornea',(1,1,1),.04);b=cornea.node_tree.nodes.get('Principled BSDF');b.inputs['Transmission Weight'].default_value=1;b.inputs['IOR'].default_value=1.38
for o in bpy.context.scene.objects:
 if o.type!='MESH' or o in [cage,source_cage]:continue
 if o.name=='GEO-headLT.002':
  o.show_instancer_for_render=False
  # Legacy 2.50 width did not migrate to plausible modern strand radii:
  # default radius_scale=.01 made 10 mm roots. Explicit new 70 micron roots.
  for ps in o.particle_systems:
   ps.settings=ps.settings.copy();ps.settings.radius_scale=.0001;ps.settings.root_radius=.7;ps.settings.tip_radius=.08

 m=cloth if o==ob or 'sash' in o.name else trouser if 'pantsLT' in o.name else leather if 'boots' in o.name or 'gauntlets' in o.name else hair if o.name=='GEO-headLT.002' else cornea if 'cornea' in o.name else eye if 'eyeballs' in o.name else skin
 o.data.materials.clear();o.data.materials.append(m)
 for f in o.data.polygons:f.material_index=0
bpy.ops.wm.save_as_mainfile(filepath=str(out/'recut-editable.blend'))
scene=bpy.context.scene;scene.use_nodes=False;scene.render.engine='CYCLES';scene.cycles.samples=16;scene.cycles.use_denoising=False;scene.view_layers[0].material_override=None
scene.world=bpy.data.worlds.new('Review');scene.world.use_nodes=True;scene.world.node_tree.nodes['Background'].inputs['Strength'].default_value=.35
bpy.ops.object.light_add(type='AREA',location=(3,-4,5));bpy.context.object.data.energy=650;bpy.context.object.data.size=4
bpy.ops.object.camera_add(location=(2.7,-5,2.6));cam=bpy.context.object;cam.rotation_euler=(Vector((0,-.08,1.03))-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.type='ORTHO';cam.data.ortho_scale=2.5;scene.camera=cam
scene.render.resolution_x=960;scene.render.resolution_y=1200;scene.render.resolution_percentage=100;scene.render.filepath=str(out/'recut-fullbody-blender-not-game.png');bpy.ops.render.render(write_still=True)
for side,sign in [('L',1),('R',-1)]:
 rig.pose.bones['hand_ik.'+side]['ik']=0.
 for stem,angle in [('upper_arm.',-.45*sign),('forearm.',.65*sign)]:
  b=rig.pose.bones[stem+side];b.rotation_mode='XYZ';b.rotation_euler[2]=angle
bpy.context.view_layer.update();scene.render.filepath=str(out/'recut-fk-blender-not-game.png');bpy.ops.render.render(write_still=True)
# Same actual field camera transform, orthographic vertical extent 22 m.
# This is a Blender pixel-size review, NOT a Godot screenshot.
cam.location=(-26.6917,-41.10162,60.03715);cam.rotation_euler=(-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.sensor_fit='VERTICAL';cam.data.ortho_scale=22.;cam.data.clip_start=51.520748;cam.data.clip_end=360.
scene.render.resolution_x=2560;scene.render.resolution_y=1440;scene.cycles.samples=32;scene.render.filepath=str(out/'field-camera-native-2k-BLENDER-NOT-GODOT.png');bpy.ops.render.render(write_still=True)
report={'source_sha256':before,'source_unchanged':hashlib.sha256(src.read_bytes()).hexdigest()==before,'source_faces':len(faces),'removed_original_front_faces':len(remove),'left_seam':left,'right_seam':right,'left_sewn_edges':boundary(left),'right_sewn_edges':boundary(right),'derived_faces':len(newfaces),'rig_bones':len(rig.data.bones),'cage_points':len(cage.data.vertices),'original_H_compatible':False,'game_tested':False,'art_pass':False,'source_multires_retained_in_original':True,'derivative_multires_index_preserved':False}
(out/'report.json').write_text(json.dumps(report,indent=2)+'\n')
