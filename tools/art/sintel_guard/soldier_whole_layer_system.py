"""Independent whole breast/waist/skirt proportion study; NOT approved soldier.
New armor uses explicit authored weights. All professional clothing/face source rigs stay.
Not historical reconstruction, shipping approval or crowd-ready runtime.
"""
import bpy, math, json, pathlib, sys, hashlib
from mathutils import Vector, Matrix
from mathutils.bvhtree import BVHTree
src,out=map(pathlib.Path,sys.argv[sys.argv.index('--')+1:][:2]);out.mkdir(parents=True,exist_ok=True)
bpy.ops.wm.open_mainfile(filepath=str(src),load_ui=False,use_scripts=False)
rig=bpy.data.objects['rig'];coat=bpy.data.objects['GEO-topLT-recut']
removed=[]
for o in list(bpy.data.objects):
 if o.name.startswith(('KIT ','SOURCE lamella')):
  removed.append(o.name);bpy.data.objects.remove(o,do_unlink=True)
for o in list(bpy.data.objects):
 if o.type in {'CAMERA','LIGHT'}:bpy.data.objects.remove(o,do_unlink=True)
def mat(name,rgb,rough=.82,metal=0):
 m=bpy.data.materials.new(name);m.use_nodes=True;p=m.node_tree.nodes.get('Principled BSDF');p.inputs['Base Color'].default_value=(*rgb,1);p.inputs['Roughness'].default_value=rough;p.inputs['Metallic'].default_value=metal
 return m
iron=mat('Rebuild matte weathered iron',(.13,.155,.165),.74,.35)
edge=mat('Rebuild forged edge',(.22,.23,.22),.77,.3)
carrier=mat('Rebuild full oxblood leather carrier',(.12,.047,.028),.9)
cloth=mat('Rebuild undyed textile',(.50,.46,.37),.88)
shoe=mat('Rebuild cloth shoe',(.12,.115,.095),.92)
for o in bpy.context.scene.objects:
 if o.type=='MESH' and ('bootsLT' in o.name):o.data.materials.clear();o.data.materials.append(shoe)
coat.data.materials.clear();coat.data.materials.append(cloth)
bpy.context.view_layer.update();ev=coat.evaluated_get(bpy.context.evaluated_depsgraph_get());me=ev.to_mesh();bvh=BVHTree.FromPolygons([ev.matrix_world@v.co for v in me.vertices],[list(p.vertices) for p in me.polygons]);ev.to_mesh_clear()
parts=[]
def spine_weights(z):
 t=max(0,min(1,(z-1.42)/.22));return {'DEF-spine.03':1-t,'DEF-spine.04':t}
def make(name,points,faces,weights,material,uvs=None,thickness=0):
 # Own new armor is LBS with fully retained assigned influences; original DQ rig
 # and source garment/cage are untouched. Exact inverse weighted matrix at bind.
 vs=[]
 for p,ws in zip(points,weights):
  M=Matrix(((0,0,0,0),)*4)
  for b,w in ws.items():
   A=rig.matrix_world@rig.pose.bones[b].matrix@rig.data.bones[b].matrix_local.inverted()@rig.matrix_world.inverted()
   M+=A*w
  vs.append(M.inverted()@Vector(p))
 mesh=bpy.data.meshes.new(name);mesh.from_pydata(vs,[],faces);mesh.update();o=bpy.data.objects.new(name,mesh);bpy.context.collection.objects.link(o);mesh.materials.append(material)
 for b in sorted(set(k for w in weights for k in w)):
  g=o.vertex_groups.new(name=b)
  for i,ws in enumerate(weights):
   if ws.get(b,0)>0:g.add([i],ws[b],'REPLACE')
 uv=mesh.uv_layers.new(name='CarrierPatternUV')
 for f in mesh.polygons:
  f.use_smooth=True
  for li in f.loop_indices:
   i=mesh.loops[li].vertex_index;uv.data[li].uv=uvs[i] if uvs else (points[i][0],points[i][2])
 a=o.modifiers.new('Complete source rig, new weighted armor','ARMATURE');a.object=rig;a.use_deform_preserve_volume=False
 if thickness:
  m=o.modifiers.new('Real closed sheet thickness','SOLIDIFY');m.thickness=thickness;m.offset=0
  b=o.modifiers.new('Worked edge, not specular stripe','BEVEL');b.width=.0007;b.segments=2
 parts.append({'name':name,'vertices':len(points),'faces':len(faces),'max_weights':max(map(len,weights))});return o
center=Vector((0,-.075,0))
def surface(a,z,offset=.012):
 n=Vector((math.sin(a),-math.cos(a),0));c=center.copy();c.z=z
 hit=bvh.ray_cast(c+n, -n)
 if hit[0] is None:raise RuntimeError(f'Missing fitted coat surface {a} {z}')
 return hit[0]+n*offset
# Full front/back/side carrier: one periodic surface, shaped armholes rather than
# disconnected rectangular chest bib. Its upper edge is higher across the chest.
N=64;R=12;points=[];weights=[];uv=[];faces=[]
def upper(a):return 1.69-.22*abs(math.sin(a))**12
for r in range(R+1):
 for c in range(N):
  a=c*math.tau/N;z=1.35+(upper(a)-1.35)*r/R
  points.append(surface(a,z));weights.append(spine_weights(z));uv.append((c/N,r/R))
for r in range(R):
 for c in range(N):k=(c+1)%N;faces.append((r*N+c,r*N+k,(r+1)*N+k,(r+1)*N+c))
make('REBUILD whole contoured breast back and side carrier',points,faces,weights,carrier,uv,.003)
# Lamellae use controlled broad scale and staggered overlap, no microscopic holes.
# Different rows follow whole-carrier contour rather than leaving bare side gaps.
pts=[];polys=[];ws=[];uv=[]
def add_plate(c,n,up,width,height,w,fit_body=False):
 n=Vector(n).normalized();z=Vector(up).normalized();x=z.cross(n).normalized();z=n.cross(x).normalized();c=Vector(c);start=len(pts)
 corners=[(-.5,-.5),(.5,-.5),(.5,.43),(.40,.5),(-.40,.5),(-.5,.43)]
 for xx,zz in corners:
  p=c+x*xx*width+z*zz*height
  if fit_body:
   aa=math.atan2(p.x,-(p.y+.075));p=surface(aa,p.z,.024)
  pts.append(p);ws.append(w.copy());uv.append((xx+.5,zz+.5))
 polys.append(tuple(range(start,start+6)))
for row in range(6):
 z=1.375+row*.052
 for col in range(40):
  a=(col+.5*(row%2))*math.tau/40
  if z+.032>upper(a):continue
  n=Vector((math.sin(a),-math.cos(a),0));c=surface(a,z,.020+row*.0007)
  # True separated circumferential columns, not tangent rectangles that
  # overlap coplanar when projected onto the same coat surface. Higher rows
  # overlap lower rows with > sheet thickness separation, not z-fighting.
  start=len(pts);offset=.026+row*.0022
  for xx,zz in [(-.46,-.5),(.46,-.5),(.46,.43),(.37,.5),(-.37,.5),(-.46,.43)]:
   p=surface(a+xx*math.tau/40,z+zz*.068,offset)
   pts.append(p);ws.append(spine_weights(z));uv.append((xx+.5,zz+.5))
  polys.append(tuple(range(start,start+6)))
make('REBUILD overlapping circumferential lamellar',pts,polys,ws,iron,uv,.0015)
# Broad contoured shoulder yokes, small articulated rows with graded attachment.
# Inner yoke follows torso; outer follows upper-arm. Not a rigid arm-bound barrel.
for sign,side in [(1,'L'),(-1,'R')]:
 points=[];weights=[];faces=[];uv=[];rows=6;cols=16
 for r in range(rows+1):
  t=r/rows;x=sign*(.135+.235*t)
  for c in range(cols+1):
   a=-1.28+2.56*c/cols;z=1.655+(.100-.012*t)*math.cos(a);y=-.055-(.100-.012*t)*math.sin(a)
   w={'DEF-spine.04':1-t,'DEF-upper_arm.'+side+'.01':t}
   points.append((x,y,z));weights.append(w);uv.append((t,c/cols))
 for r in range(rows):
  for c in range(cols):i=r*(cols+1)+c;faces.append((i,i+1,i+cols+2,i+cols+1))
 make('REBUILD graded shoulder yoke '+side,points,faces,weights,carrier,uv,.0025)
 pts=[];polys=[];ws=[];uv=[]
 for r in range(4):
  t=(r+.5)/4;x=sign*(.145+.22*t)
  for c in range(9):
   a=-1.16+c*.29;n=Vector((0,-math.sin(a),math.cos(a)))
   add_plate(Vector((x,-.055,1.655))+n*(.108-.012*t),n,(sign,0,0),.038,.067,{'DEF-spine.04':1-t,'DEF-upper_arm.'+side+'.01':t})
 make('REBUILD shoulder overlapping rows '+side,pts,polys,ws,iron,uv,.0015)
# Entire defined waist band between cuirass and mobile skirt, with upper/lower
# folded boundaries as actual geometry. Source cloth underlayer remains intact.
beltmat=mat('Waist oxblood woven cloth',(.20,.075,.045),.93)
for label,z0,z1,extra in [('waist band',1.26,1.345,.038),('upper folded seam',1.334,1.345,.044),('lower folded seam',1.26,1.271,.044)]:
 bp=[];bw=[];bf=[];bu=[]
 for j in range(5):
  z=z0+(z1-z0)*j/4
  for i in range(64):
   a=i*math.tau/64;bp.append(surface(a,z,extra));bw.append({'DEF-spine.02':1.});bu.append((i/64,j/4))
 for j in range(4):
  for i in range(64):k=(i+1)%64;bf.append((j*64+i,j*64+k,(j+1)*64+k,(j+1)*64+i))
 make('REBUILD structured '+label,bp,bf,bw,beltmat,bu,.004)
# Four short, broad curved split tassets, not eight rigid long rectangular leaves.
for panel,mid in enumerate([0,math.pi/2,math.pi,3*math.pi/2]):
 pts=[];polys=[];ws=[];uv=[]
 for row in range(4):
  z=1.225-row*.055
  for col in range(9):
   a=mid+(col-4)*.145;n=Vector((math.sin(a),-math.cos(a),0));radius=.247+row*.014
   c=center+n*radius;c.z=z
   w={'DEF-spine.01':1.0}
   add_plate(c,n,(0,0,1),.043,.079,w)
 make('REBUILD short curved split tasset '+str(panel),pts,polys,ws,iron,uv,.0015)
# Save editable unified actor before motion tests, original source rigs intact.
bpy.context.view_layer.update();bpy.ops.wm.save_as_mainfile(filepath=str(out/'soldier-carrier-editable.blend'))
scene=bpy.context.scene;scene.use_nodes=False;scene.render.engine='CYCLES';scene.cycles.samples=32;scene.cycles.use_denoising=False;scene.view_layers[0].material_override=None
scene.world=bpy.data.worlds.new('Rebuild natural matte review');scene.world.use_nodes=True;scene.world.node_tree.nodes['Background'].inputs['Strength'].default_value=.45
bpy.ops.object.light_add(type='AREA',location=(-3,-4,5));bpy.context.object.data.energy=650;bpy.context.object.data.size=5
bpy.ops.object.camera_add(location=(2.5,-5,3.2));cam=bpy.context.object;cam.rotation_euler=(Vector((0,-.08,1.05))-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.type='ORTHO';cam.data.ortho_scale=2.7;scene.camera=cam
scene.render.resolution_x=960;scene.render.resolution_y=1100;scene.render.resolution_percentage=100;scene.render.filepath=str(out/'whole-carrier-BLENDER-NOT-GAME.png');bpy.ops.render.render(write_still=True)
# Exact stress repeats the old rejected pose so changes are not camera trickery.
for side,sign in [('L',1),('R',-1)]:
 rig.pose.bones['hand_ik.'+side]['ik']=0.
 for stem,ang in [('upper_arm.',-.95*sign),('forearm.',.75*sign)]:
  bone=rig.pose.bones[stem+side];bone.rotation_mode='XYZ';bone.rotation_euler[2]=ang
bpy.context.view_layer.update();scene.render.filepath=str(out/'whole-carrier-arms-BLENDER-NOT-GAME.png');bpy.ops.render.render(write_still=True)
(out/'report.json').write_text(json.dumps({'source_sha256':hashlib.sha256(src.read_bytes()).hexdigest(),'removed_rejected_objects':removed,'source_armatures':{o.name:len(o.data.bones) for o in bpy.context.scene.objects if o.type=='ARMATURE'},'parts':parts,'art_pass':False,'game_tested':False,'new_deformation':'Own armor LBS graded weights; original cloth cage/DQ/face intact','missing':['weapon grip','cloth shoe/puttee topology conversion','full walk and attack','runtime LOD/bake','historical/visual acceptance']},indent=2)+'\n')
