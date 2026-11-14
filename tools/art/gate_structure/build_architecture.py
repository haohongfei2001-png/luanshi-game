"""Editable military gateway + structural timber bridges. No legacy game meshes.
Blender 4.3.2: --background --factory-startup --disable-autoexec --python THIS -- SOURCE.blend OUTPUTDIR
Source roof is VVayToyek CC0; original object topology/UV clipped and extended into a new hipped long-ridge roof.
"""
import bpy,math,json,sys,hashlib
from pathlib import Path
from mathutils import Vector
args=sys.argv[sys.argv.index('--')+1:];source,out=map(Path,args[:2]);out.mkdir(parents=True,exist_ok=True)
if source.suffix.lower()=='.fbx':
 bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False);bpy.ops.import_scene.fbx(filepath=str(source))
else:bpy.ops.wm.open_mainfile(filepath=str(source),load_ui=False)
source_objects={o.name:o for o in bpy.data.objects if o.type=='MESH'}
# Bake source world coordinates, normals and original per-corner UV before new scene.
roof={}
for name in [o for o in source_objects if o.startswith(('瓦面','垂脊','檐椽','飞椽','脑椽'))]:
 o=source_objects[name];uv=o.data.uv_layers.active
 roof[name]=[[(tuple(o.matrix_world@o.data.vertices[o.data.loops[i].vertex_index].co),tuple(uv.data[i].uv) if uv else (0.,0.)) for i in p.loop_indices] for p in o.data.polygons]
# Professional CC0 deck boards: preserve their actual worn silhouette and UV islands.
pier_path=out/'source/wooden_pier/modular_wooden_pier.gltf'
bpy.ops.import_scene.gltf(filepath=str(pier_path))
plank=bpy.data.objects['modular_wooden_pier_planks'];uv=plank.data.uv_layers.active
plank_polys=[[(tuple(plank.matrix_world@plank.data.vertices[plank.data.loops[i].vertex_index].co),tuple(uv.data[i].uv)) for i in p.loop_indices] for p in plank.data.polygons]
# Recover original separate boards using welded positions (glTF splits vertices at UV seams).
from collections import defaultdict
keys=[tuple(round(c,5) for c in v.co) for v in plank.data.vertices];adj=defaultdict(set)
for poly in plank.data.polygons:
 ids=list(poly.vertices)
 for a,b in zip(ids,ids[1:]+ids[:1]):adj[keys[a]].add(keys[b]);adj[keys[b]].add(keys[a])
labels={};components=[]
for key in adj:
 if key in labels:continue
 stack=[key];label=len(components);group=[]
 while stack:
  k=stack.pop()
  if k in labels:continue
  labels[k]=label;group.append(k);stack.extend(adj[k]-labels.keys())
 components.append(group)
boards=[]
for i in range(len(components)):
 polys=[plank_polys[k] for k,p in enumerate(plank.data.polygons) if labels[keys[p.vertices[0]]]==i]
 pts=[v for p in polys for v,_ in p];mn=[min(v[j] for v in pts) for j in range(3)];mx=[max(v[j] for v in pts) for j in range(3)]
 if mx[0]-mn[0]>2:boards.append((polys,mn,mx))
boards.sort(key=lambda b:b[1][1]);assert len(boards)==10

bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
for m in list(bpy.data.materials):bpy.data.materials.remove(m)
materials={}
for name,color,rough in [('masonry','897e6a',.92),('mortar','716a59',1),('timber','574635',.88),('timber_cut','736046',.9),('tile','515c60',.86),('iron','383d3c',.72),('plaster','b0a489',.95)]:
 m=bpy.data.materials.new(name);m.diffuse_color=tuple((int(color[i:i+2],16)/255)**2.2 for i in (0,2,4))+(1,);m.use_nodes=True;p=m.node_tree.nodes.get('Principled BSDF');p.inputs['Base Color'].default_value=m.diffuse_color;p.inputs['Roughness'].default_value=rough;materials[name]=m
m=bpy.data.materials.new('ProfessionalDeckWood_CC0');m.use_nodes=True;p=m.node_tree.nodes.get('Principled BSDF');p.inputs['Roughness'].default_value=.92
tex=m.node_tree.nodes.new('ShaderNodeTexImage');tex.image=bpy.data.images.load(str(out/'source/wooden_pier/modular_wooden_pier_planks_diff_2k.jpg'));m.node_tree.links.new(tex.outputs['Color'],p.inputs['Base Color']);materials['deck_wood']=m
root=bpy.data.objects.new('AuthoredArchitecture',None);bpy.context.collection.objects.link(root)
groups={}
def group(name):
 o=bpy.data.objects.new(name,None);bpy.context.collection.objects.link(o);o.parent=root;groups[name]=o;return o
gate=group('GateHall');door=group('GateDoor');walls=group('WallWalk');bridge=group('GateBridge');west=group('WestBridge')
def mesh(name,verts,faces,mat,parent,uvs=None):
 d=bpy.data.meshes.new(name);d.from_pydata(verts,[],faces);d.materials.append(materials[mat]);d.update();o=bpy.data.objects.new(name,d);bpy.context.collection.objects.link(o);o.parent=parent
 # One shared active UV channel is required when source and authored surfaces join.
 layer=d.uv_layers.new(name='UVMap')
 for poly in d.polygons:
  for li in poly.loop_indices:
   v=d.vertices[d.loops[li].vertex_index].co;layer.data[li].uv=uvs[d.loops[li].vertex_index] if uvs else (v.x*.3,v.z*.3+v.y*.05)
 return o
# All construction coordinates use metres in Godot (x,y,z), converted to Blender (x,-z,y).
def pt(x,y,z):return (x,-z,y)
def box(name,center,size,mat,parent,bevel=.025):
 x,y,z=center;a,b,c=[v/2 for v in size]
 vs=[pt(x+sx*a,y+sy*b,z+sz*c) for sx,sy,sz in [(-1,-1,-1),(1,-1,-1),(1,-1,1),(-1,-1,1),(-1,1,-1),(1,1,-1),(1,1,1),(-1,1,1)]]
 o=mesh(name,vs,[(0,3,2,1),(4,5,6,7),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7)],mat,parent)
 if bevel:
  mod=o.modifiers.new('joinery edge bevel','BEVEL');mod.width=bevel;mod.segments=2
  bpy.context.view_layer.objects.active=o;o.select_set(True);bpy.ops.object.modifier_apply(modifier=mod.name);o.select_set(False)
 return o
def beam(name,a,b,width,depth,mat,parent):
 va,vb=Vector(pt(*a)),Vector(pt(*b));axis=(vb-va).normalized();side=axis.cross(Vector((0,0,1)))
 if side.length<.1:side=axis.cross(Vector((0,1,0)))
 side.normalize();up=axis.cross(side).normalized();vs=[]
 for p in [va,vb]:
  for u,v in [(-1,-1),(1,-1),(1,1),(-1,1)]:vs.append(tuple(p+side*u*width/2+up*v*depth/2))
 o=mesh(name,vs,[(0,3,2,1),(4,5,6,7),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7)],mat,parent)
 mod=o.modifiers.new('hewn corners','BEVEL');mod.width=.025;mod.segments=2;bpy.context.view_layer.objects.active=o;o.select_set(True);bpy.ops.object.modifier_apply(modifier=mod.name);o.select_set(False);return o
# Real shallow barrel voussoir construction: minimum opening 8m wide x4.2m tall.
R=(4**2+.9**2)/(2*.9);cz=5.1-R;angle=math.asin(4/R)
for i in range(17):
 a=-angle+2*angle*i/17+.001;b=-angle+2*angle*(i+1)/17-.001;vs=[]
 for x in [46.65,53.45]:
  for r,t in [(R,a),(R,b),(R+.55,b),(R+.55,a)]:vs.append(pt(x,cz+r*math.cos(t),r*math.sin(t)))
 mesh('GateVault_ashlar_%02d'%i,vs,[(0,3,2,1),(4,5,6,7),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7)],'masonry',gate)
# Piers use battered connected masonry courses; stone joints stay restrained at normal camera.
for sign in [-1,1]:
 for row in range(7):
  y=.32+row*.6;inner=4.03;outer=8.5-.35*(y/4.2);width=outer-inner
  # Preserve the existing x49.4..52.6 wall-walk at y3.25 through both piers.
  if False: # never fill the protected ramp corridor, including its lower end
   box('GatePier_%s_%s'%(sign,row),(50.05,y,sign*(inner+width/2)),(6.9-.22*y,.584,width),'masonry',gate,.035)
  else:
   for center,depth in [(47.95,2.35),(53.15,.6)]:box('GatePier_walk_jamb',(center,y,sign*(inner+width/2)),(depth,.584,width),'masonry',gate,.025)
 for center,depth in [(47.95,2.35),(53.15,.6)]:box('GatePier_coping',(center,4.43,sign*6.25),(depth,.32,4.42),'masonry',gate)
 # Raised side platforms support the upper gate frame rather than a garden seat.
 for x in [48.,52.95]:
  beam('GateHall_column',(x,4.58,sign*5.9),(x,6.48,sign*5.9),.32,.32,'timber',gate)
  box('GateHall_column_base',(x,4.62,sign*5.9),(.48,.22,.48),'masonry',gate)
 # Wall-walk corridor stays open through the gate pier; no fake solid infill.
 for x in [48.,52.95]:
  beam('GateHall_bracket',(x,5.98,sign*5.9),(x,6.37,sign*6.6),.16,.18,'timber',gate)
for x in [48.,52.95]:
 beam('GateHall_principal_tie',(x,6.25,-6.3),(x,6.25,6.3),.32,.42,'timber',gate)
 for z in [-5.9,0,5.9]:
  beam('GateHall_cross_purlin',(47.3,6.37,z),(52.8,6.37,z),.22,.25,'timber',gate)
# Functional replaceable door leaves, independently hideable; opening preserved as gameplay-controlled.
for sign in [-1,1]:
 for i in range(11):box('GateDoor_board',(48.,2.05,sign*(.18+i*.35)),(.21,4.05,.34),'timber',door,.014)
 for y in [.65,2.05,3.55]:box('GateDoor_strap',(47.86,y,sign*1.95),(.06,.13,3.75),'iron',door,.012)
 for z in [.4,3.5]:
  for y in [.65,2.05,3.55]:box('GateDoor_bolt',(47.81,y,sign*z),(.07,.08,.08),'iron',door,.025)
# Clip professional roof polygons with UV interpolation, preserving native tile barrel geometry.
def clip(poly,axis,value,keep_less):
 result=[]
 for p,q in zip(poly,poly[1:]+poly[:1]):
  inside=lambda t:t[0][axis]<=value if keep_less else t[0][axis]>=value
  ip,iq=inside(p),inside(q)
  if ip:result.append(p)
  if ip!=iq:
   t=(value-p[0][axis])/(q[0][axis]-p[0][axis]);v=tuple(p[0][j]+t*(q[0][j]-p[0][j]) for j in range(3));uv=tuple(p[1][j]+t*(q[1][j]-p[1][j]) for j in range(2));result.append((v,uv))
 return result
S=.19;extension=5.;roof_pieces=[]
def roof_part(name,polys,offset=0,lo=None,hi=None,material='tile'):
 vs=[];fs=[];uv=[]
 for poly in polys:
  if lo is not None:poly=clip(poly,1,lo,False)
  if hi is not None:poly=clip(poly,1,hi,True)
  if len(poly)<3:continue
  fs.append(tuple(range(len(vs),len(vs)+len(poly))))
  for v,t in poly:vs.append((50.05+v[0]*S,v[1]*S+offset,2.4+v[2]*S));uv.append(t)
 o=mesh(name,vs,fs,material,gate,uv);o['source']='VVayToyek CC0 pavilion roof; polygon clipped, UV interpolated, ridge extended';roof_pieces.append(o)
roof_part('Roof_HipNorth',roof['瓦面1'],-extension)
roof_part('Roof_HipSouth',roof['瓦面3'],extension)
for source_name,label in [('瓦面2','East'),('瓦面4','West')]:
 roof_part('Roof_'+label+'_north',roof[source_name],-extension,hi=0)
 roof_part('Roof_'+label+'_south',roof[source_name],extension,lo=0)
 n=44;step=2*extension/n;half=step/S/2
 for i in range(n):roof_part('Roof_'+label+'_central_%02d'%i,roof[source_name],-extension+step*(i+.5),lo=-half,hi=half)
# Original continuous hip ridge cover closes the source tile seams.
for i in range(1,5):roof_part('Roof_HipRidge%d'%i,roof['垂脊%d'%i],-extension if i<=2 else extension)
# Source rafters retain the same curved load path as the tiles, avoiding straight
# invented rafters piercing concave professional roof surfaces.
for family in ['檐椽','飞椽','脑椽']:
 for i in [1,3]:roof_part('NativeRoofFrame_%s_%d'%(family,i),roof[family+str(i)],-extension if i==1 else extension,material='timber')
 for i in [2,4]:
  polys=roof[family+str(i)]
  roof_part('NativeRoofFrame_%s_%d_N'%(family,i),polys,-extension,hi=0,material='timber')
  roof_part('NativeRoofFrame_%s_%d_S'%(family,i),polys,extension,lo=0,material='timber')
  for k in range(12):
   step=2*extension/12
   roof_part('NativeRoofFrame_%s_%d_%02d'%(family,i,k),polys,-extension+step*(k+.5),lo=-step/S/2,hi=step/S/2,material='timber')
for x,y in [(47.35,6.38),(50.05,7.7),(52.75,6.38)]:beam('RoofLongPurlin',(x,y,-4.9),(x,y,4.9),.16,.2,'timber',gate)
# Continuous low ridge cap; crown shape with real sides, not a flat giant strip.
for i in range(40):
 z=-5+i*.25
 beam('RoofRidgeCap',(50.05,8.22,z),(50.05,8.22,z+.246),.34,.26,'tile',gate)
# Curtain wall mass and parapet remain outside protected route, at matching adult scale.
for sign in [-1,1]:
 for i in range(12):
  z=sign*(8.5+(i+.5)*14.5/12)
  box('WallBody',(47.95,1.58,z),(2.7,3.16,14.5/12-.018),'masonry',walls,.035)

  box('WallParapet',(47.25,3.79,z),(.65,1.12,14.5/12-.018),'masonry',walls,.025)
  if i%2==0:box('WallMerlon',(47.25,4.56,z),(.72,.42,14.5/12-.12),'masonry',walls,.025)
# Ramp surface matches Ground.parapet, including the full lower approach through piers.
for sign in [-1,1]:
 for i in range(35):
  a=5.5+i*.5;b=a+.5;ya=min(3.25,(a-5.5)*.43);yb=min(3.25,(b-5.5)*.43)
  mesh('WallWalk_ramp',[pt(49.4,ya,sign*a),pt(52.6,ya,sign*a),pt(52.6,yb,sign*b),pt(49.4,yb,sign*b)],[(0,1,2,3)] if sign>0 else [(3,2,1,0)],'masonry',walls)
# Timber bridge: continuous transverse deck, longitudinal stringers, pile bents,
# wedged crossheads/knee braces, rails completely outside 7.4m roadway.
def make_bridge(parent,cx,length):
 for z in [-3.6,-7.52/6,7.52/6,3.6]:beam('BridgeStringer',(cx-length/2,-.12,z),(cx+length/2,-.12,z),.22,.42,'timber',parent)
 # Fit each original board independently: whole-palette AABB repetition leaves
 # dangerous long seams because the professional source boards have different lengths.
 count=round(length/.29)
 for i in range(count):
  for j in range(3):
   polys,mn,mx=boards[(i+3*j)%len(boards)]
   vs=[];fs=[];uvs=[]
   for poly in polys:
    fs.append(tuple(range(len(vs),len(vs)+len(poly))))
    for v,uv in poly:
     x=cx-length/2+(i+.02+(v[1]-mn[1])/(mx[1]-mn[1])*.96)*length/count
     z=-3.76+(j+.002+(v[0]-mn[0])/(mx[0]-mn[0])*.996)*7.52/3
     y=.13+(v[2]-mx[2])
     vs.append(pt(x,y,z));uvs.append(uv)
   mesh('ProfessionalDeck_%d_%d'%(i,j),vs,fs,'deck_wood',parent,uvs)
 for x in [cx-length*.28,cx+length*.28]:
  beam('BridgeCrosshead',(x,-.52,-3.8),(x,-.52,3.8),.35,.42,'timber',parent)
  for z in [-3.1,0,3.1]:
   beam('BridgePile',(x,-3.6,z),(x,-.65,z),.38,.38,'timber',parent)
   for dx in [-1,1]:beam('BridgeKneeBrace',(x,-1.8,z),(x+dx*1.0,-.48,z),.19,.19,'timber',parent)
  for z in [-3.1,0]:beam('BridgeBentCrossBrace',(x,-2.5,z),(x,-.85,z+3.1),.17,.17,'timber',parent)
 for side in [-1,1]:
  z=side*3.86
  for i in range(9):
   x=cx-length/2+.18+(length-.36)*i/8
   box('BridgeRailPost',(x,.63,z),(.18,1.24,.18),'timber',parent,.025)
   box('BridgePostCap',(x,1.28,z),(.24,.12,.24),'timber_cut',parent,.025)
  for h in [.48,1.1]:beam('BridgeRail',(cx-length/2,h,z),(cx+length/2,h,z),.12,.14,'timber',parent)
 for x in [cx-length/2,cx+length/2]:box('BridgeAbutment',(x,-.75,0),(.6,1.5,7.85),'masonry',parent,.06)
 parent['deck_top']=.13;parent['clear_lane']=7.4
make_bridge(bridge,24,11.9);make_bridge(west,-32,13.2)
# Explicitly recorded topology, coordinate and integration contracts.
scene=bpy.context.scene;scene.unit_settings.system='METRIC';scene.unit_settings.scale_length=1
root['status']='ART_NOT_ACCEPTED';root['layout']='river-authored-reset-design-01';door['gameplay_hideable']=True
objects=[o for o in bpy.data.objects if o.type=='MESH']
for o in objects:o.data.calc_loop_triangles()
report={'status':'ART_NOT_ACCEPTED','source':'VVayToyek CC0 roof + Rico Cilliers Poly Haven CC0 native deck boards; authored military mass and structural bridge','mesh_objects':len(objects),'triangles':sum(len(o.data.loop_triangles) for o in objects),'roof_source_uv_preserved':True,'door_net_width':8,'bridge_clear_width':7.4,'bridge_deck_top':.13,'legacy_meshes':False}
(out/'architecture-manifest.json').write_text(json.dumps(report,indent=2)+'\n')
# Door pivot is exactly the gameplay gate center, while child geometry stays put.
for child in door.children:
 if child.type=='MESH':
  for v in child.data.vertices:v.co-=Vector(pt(48,0,0))
door.location=Vector(pt(48,0,0))
bpy.ops.file.pack_all()
bpy.ops.wm.save_as_mainfile(filepath=str(out/'source/architecture.blend'))
# Runtime meshes consolidate by load-bearing assembly; authored blend retains every editable part.
for parent in [gate,door,walls,bridge,west]:
 children=[o for o in parent.children if o.type=='MESH']
 batches={}
 for ob in children:
  key=('Roof_'+('East' if 'East' in ob.name else 'West' if 'West' in ob.name else 'HipNorth' if 'HipNorth' in ob.name else 'HipSouth') if ob.name.startswith('Roof_') else parent.name+'_Structure')
  batches.setdefault(key,[]).append(ob)
 for name,obs in batches.items():
  bpy.ops.object.select_all(action='DESELECT')
  for ob in obs:ob.select_set(True)
  bpy.context.view_layer.objects.active=obs[0];bpy.ops.object.join();obs[0].name=name
bpy.ops.object.select_all(action='DESELECT')
bpy.ops.export_scene.gltf(filepath=str(out/'architecture.glb'),export_format='GLB',export_yup=True,export_extras=True)
if '--no-preview' in args:raise SystemExit(0)
# Real Blender model review renders; explicitly not Godot gameplay evidence.
world=bpy.data.worlds.new('ReviewWorld');world.use_nodes=True;world.node_tree.nodes['Background'].inputs[0].default_value=(.21,.23,.27,1);world.node_tree.nodes['Background'].inputs[1].default_value=.7;scene.world=world
sun=bpy.data.lights.new('ReviewSun','SUN');sun.energy=2.5;o=bpy.data.objects.new('ReviewSun',sun);scene.collection.objects.link(o);o.rotation_euler=(.4,-.4,-.5)
scene.render.engine='CYCLES';scene.cycles.samples=24;scene.cycles.use_denoising=False;scene.render.resolution_x=1600;scene.render.resolution_y=1000;scene.render.resolution_percentage=100;scene.render.image_settings.file_format='PNG'
cam=bpy.data.objects.new('ReviewCamera',bpy.data.cameras.new('ReviewCamera'));scene.collection.objects.link(cam);scene.camera=cam;cam.data.type='ORTHO'
for name,center,offset,scale in [('gate',(50,0,4),( -20,-22,14),25),('bridge',(24,0,-.7),(-15,-18,12),17),('whole',(38,0,2),(-25,-30,24),42)]:
 target=Vector(center);cam.location=target+Vector(offset);cam.rotation_euler=(target-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.ortho_scale=scale;scene.render.filepath=str(out/(name+'-blender.png'));bpy.ops.render.render(write_still=True)
print('AUTHORED_ARCHITECTURE',json.dumps(report))
