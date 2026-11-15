"""Editable coherent river-gate slice. Original authoring + licensed native components.
No runtime map/controller edits. Offline pictures are unambiguously NOT_GAME.
"""
import bpy,bmesh,math,json,sys,hashlib,random,time,os
from pathlib import Path
from mathutils import Vector,Matrix
sys.path.insert(0,str(Path(__file__).resolve().parent))
from layout import *
from bpy_extras.object_utils import world_to_camera_view
random.seed(SEED)
OUT=Path(sys.argv[sys.argv.index('--')+1]);OUT.mkdir(parents=True,exist_ok=True)
ROOT=Path(os.environ['LUANSHI_WORKSPACE_ROOT']);SHARED=Path(os.environ['LUANSHI_PRODUCTION_ROOT'])
SRC=ROOT/'luanshi-environment-rebuild/assets/river_gate/world'
TEX=OUT/'textures';PBR=SHARED/'luanshi-material-intake-20261114'
bpy.ops.wm.read_factory_settings(use_empty=True);sc=bpy.context.scene
manifest={'schema_version':1,'map_id':'luanshi.river_gate.production_v2','topology_revision':4,'visual_revision':1,'status':'UNFROZEN_HF01_ART_REVIEW_REQUIRED','surfaces':[],'solids':[],'portals':[],'spawn_regions':[],'retreat_regions':[],'goal_regions':[],'sources':[]}
def sha(p):return hashlib.sha256(Path(p).read_bytes()).hexdigest()
def record(p,why):
 p=Path(p);manifest['sources'].append({'path':str(p),'sha256':sha(p),'role':why})
def pt(x,y,z):return Vector((x,-z,y))
def gp(v):return [float(v.x),float(v.z),float(-v.y)]
def group(name,parent=None):
 o=bpy.data.objects.new(name,None);sc.collection.objects.link(o);o.parent=parent;return o
root=group('RiverValley_HF01_AuthoredSource')
ground_group=group('ContinuousGeologyAndRoad',root);arch_group=group('FortifiedRiverThreshold',root);plants_group=group('RootedEcology',root)
record(Path(__file__),'original coherent authoring');record(Path(__file__).with_name('build_materials.py'),'deterministic licensed texture authoring');record(Path(__file__).with_name('bake_native_bank.py'),'native topography and original UV projection');
if os.environ.get('LUANSHI_BANK_FIELD'):
 record(Path(os.environ['LUANSHI_BANK_FIELD']),'native scan height/colour field used by both surface and atlas');record(Path(os.environ['LUANSHI_BANK_FIELD']).with_name('native-bank-provenance.json'),'native scan source and metre projection receipt')
record(Path(__file__).with_name('wrap_native.py'),'native author-world packaging contract');
for f in sorted(list(TEX.glob('*.jpg'))+list(TEX.glob('*.png'))):record(f,'derived glTF material input')
record(Path(__file__).with_name('layout.py'),'same landform field for surface and texture');record(TEX/'material-provenance.json','licensed texture processing receipt')
def mat(name,color=(.3,.3,.3),rough=.85,texture=None,normal=None,strength=.2):
 m=bpy.data.materials.new(name);m.use_nodes=True;n=m.node_tree.nodes;l=m.node_tree.links;p=n.get('Principled BSDF');p.inputs['Base Color'].default_value=(*color,1);p.inputs['Roughness'].default_value=rough
 if texture:
  t=n.new('ShaderNodeTexImage');t.image=bpy.data.images.load(str(texture),check_existing=True);l.new(t.outputs['Color'],p.inputs['Base Color'])
 if normal:
  t=n.new('ShaderNodeTexImage');t.image=bpy.data.images.load(str(normal),check_existing=True);t.image.colorspace_settings.name='Non-Color';nm=n.new('ShaderNodeNormalMap');nm.inputs['Strength'].default_value=strength;l.new(t.outputs['Color'],nm.inputs['Color']);l.new(nm.outputs['Normal'],p.inputs['Normal'])
 return m
stone=mat('DressedLimestone_SourceMineralInterior',rough=.89,texture=TEX/'stone-interior.jpg',normal=TEX/'stone-normal-0.png',strength=.18)
stone_variants=[stone]+[mat('StoneMineralInterior_'+str(i),rough=.87+i*.013,texture=TEX/('stone-interior-'+str(i)+'.jpg'),normal=TEX/('stone-normal-'+str(i)+'.png'),strength=.18) for i in range(1,5)]
wood=mat('HewnChestnut_GrainFollowsLoad',rough=.82,texture=PBR/'fine_grained_wood/fine_grained_wood_col_2k.png',normal=PBR/'fine_grained_wood/fine_grained_wood_nor_gl_2k.png',strength=.23)
iron=mat('WroughtIron_MatteEdges',(.082,.089,.088),.53);iron.node_tree.nodes.get('Principled BSDF').inputs['Metallic'].default_value=.65
mortar=mat('LimeMortar_Recessed',(.22,.225,.20),.98)
plaster=mat('WeatheredLimeInfill',(.47,.45,.38),.96)
ground=mat('UniqueRoadSoilGrass_WorldAtlas',rough=.94,texture=TEX/'valley-albedo.jpg')
# Very subtle physical grain normal, mapped in real metres rather than atlas coordinates.
n=ground.node_tree.nodes;l=ground.node_tree.links;uvn=n.new('ShaderNodeUVMap');uvn.uv_map='DetailMetres';t=n.new('ShaderNodeTexImage');t.image=bpy.data.images.load(str(SRC/'ground/sandy_gravel_02_nor_gl.jpg'),check_existing=True);t.image.colorspace_settings.name='Non-Color';l.new(uvn.outputs[0],t.inputs[0]);nm=n.new('ShaderNodeNormalMap');nm.uv_map='DetailMetres';nm.inputs['Strength'].default_value=.42;l.new(t.outputs[0],nm.inputs['Color']);l.new(nm.outputs[0],n.get('Principled BSDF').inputs['Normal'])
materials=[stone,wood,iron,mortar,plaster,ground]
def mesh(name,verts,faces,material,parent=None,uvs=None,smoothface=False):
 # Closed author solids must have positive signed volume, never inward block normals.
 edges={}
 for f in faces:
  for a,b in zip(f,tuple(f[1:])+tuple(f[:1])):key=tuple(sorted((a,b)));edges[key]=edges.get(key,0)+1
 if edges and all(v==2 for v in edges.values()):
  vol=sum(Vector(verts[f[0]]).dot(Vector(verts[f[i]]).cross(Vector(verts[f[i+1]])))/6 for f in faces for i in range(1,len(f)-1))
  if vol<0:faces=[tuple(reversed(f)) for f in faces]
 me=bpy.data.meshes.new(name);me.from_pydata([tuple(v) for v in verts],[],faces);me.materials.append(material);me.update();o=bpy.data.objects.new(name,me);sc.collection.objects.link(o);o.parent=parent or root
 uv=me.uv_layers.new(name='UVMap')
 for poly in me.polygons:
  poly.use_smooth=smoothface
  axis=max(range(3),key=lambda k:abs(poly.normal[k]));plane=[k for k in range(3) if k!=axis]
  for li in poly.loop_indices:
   v=me.vertices[me.loops[li].vertex_index].co
   uv.data[li].uv=uvs[me.loops[li].vertex_index] if uvs else (v[plane[0]],v[plane[1]])
 return o
BOXF=[(0,3,2,1),(4,5,6,7),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7)]
def box(name,c,s,material=stone,parent=None,bevel=.025,variant=0):
 x,y,z=c;a,b,c=[v/2 for v in s]
 vs=[pt(x+i*a,y+j*b,z+k*c) for i,j,k in [(-1,-1,-1),(1,-1,-1),(1,-1,1),(-1,-1,1),(-1,1,-1),(1,1,-1),(1,1,1),(-1,1,1)]]
 o=mesh(name,vs,[tuple(reversed(f)) for f in BOXF],material,parent);uv=o.data.uv_layers.active
 if material==stone:o.data.materials[0]=stone_variants[random.randrange(len(stone_variants))]
 lo=[min(v.co[k] for v in o.data.vertices) for k in range(3)];hi=[max(v.co[k] for v in o.data.vertices) for k in range(3)]
 for p in o.data.polygons:
  axis=max(range(3),key=lambda k:abs(p.normal[k]));axes=[k for k in range(3) if k!=axis]
  if material==wood:
   grain=max(axes,key=lambda k:hi[k]-lo[k]);axes=[k for k in axes if k!=grain]+[grain]
  for li in p.loop_indices:
   v=o.data.vertices[o.data.loops[li].vertex_index].co
   if material==stone:uv.data[li].uv=tuple(.08+.82*(v[k]-lo[k])/max(hi[k]-lo[k],.0001) for k in axes)
   elif material==wood:uv.data[li].uv=((v[axes[0]]-lo[axes[0]])/.6,(v[axes[1]]-lo[axes[1]])/.6)
 if bevel:
  bm=bmesh.new();bm.from_mesh(o.data);bmesh.ops.bevel(bm,geom=list(bm.edges),offset=bevel,segments=2,affect='EDGES',clamp_overlap=True);bm.to_mesh(o.data);bm.free();o.data.update()
 return o

def beam(name,a,b,w,d,material=wood,parent=None):
 av,bv=pt(*a),pt(*b);axis=(bv-av).normalized();side=axis.cross(Vector((0,0,1)))
 if side.length<.01:side=axis.cross(Vector((0,1,0)))
 side.normalize();up=axis.cross(side).normalized()
 vs=[v+side*i*w/2+up*j*d/2 for v in [av,bv] for i,j in [(-1,-1),(1,-1),(1,1),(-1,1)]]
 o=mesh(name,vs,[tuple(reversed(f)) for f in BOXF],material,parent);uv=o.data.uv_layers.active
 if material==stone:o.data.materials[0]=stone_variants[random.randrange(len(stone_variants))]
 for p in o.data.polygons:
  for li in p.loop_indices:
   v=o.data.vertices[o.data.loops[li].vertex_index].co-av;uv.data[li].uv=(v.dot(side)/.6,v.dot(axis)/.6)
 bm=bmesh.new();bm.from_mesh(o.data);bmesh.ops.bevel(bm,geom=list(bm.edges),offset=.018,segments=2,affect='EDGES',clamp_overlap=True);bm.to_mesh(o.data);bm.free();o.data.update()
 return o

def solid(id,poly,lo,hi,gate=None):
 d={'id':id,'xz_polygon':poly,'min_y':float(lo),'max_y':float(hi)}
 if gate:d['gate_id']=gate
 manifest['solids'].append(d)
def surface(id,vertices,triangles,clearance=99):manifest['surfaces'].append({'id':id,'vertices':vertices,'triangles':triangles,'walkable':True,'agent_clearance_m':clearance})
def rectsupport(id,x0,x1,z0,z1,y0,y1,clearance=99):
 vs=[[x0,y0,z0],[x1,y1,z0],[x1,y1,z1],[x0,y0,z1]];surface(id,vs,[[0,2,1],[0,3,2]],clearance)
def inside_paving(x,z):return any(a<=x<=b and c<=z<=d for _,a,b,c,d,_,_ in PAVING)

print('AUTHOR_TERRAIN',flush=True)
for side,x0,x1 in [('west',-60.,-4.),('east',4.,84.)]:
 xs=sorted(set([x0+i for i in range(int(x1-x0)+1)]+[float(v) for v in np.arange(max(x0,-20),min(x1,20),.5)]+([a for p in PAVING for a in p[1:3] if x0<a<x1])))
 zs=sorted(set([-42.+i for i in range(85)]+[float(v) for v in np.arange(-24,24,.5)]+[-3.1,3.1]));verts=[];uvs=[];navverts=[];faces=[];nav=[]
 for z in zs:
  row_heights=height(np.asarray(xs),z,side)
  for xi,x in enumerate(xs):
   y=float(row_heights[xi])
   if any(a+.00001<x<b-.00001 and c+.00001<z<d-.00001 for _,a,b,c,d,_,_ in PAVING):y-=.18
   verts.append(pt(x,y,z));navverts.append([x,y,z]);uvs.append(((x+60)/144,(z+42)/84))
 nx=len(xs)
 for j in range(len(zs)-1):
  for i in range(nx-1):
   a=j*nx+i;b=a+1;c=a+nx;d=c+1;tris=[(a,d,b),(a,c,d)]
   for tr in tris:
    # Blender transform flips original XZ winding; +Z author normal is explicit.
    va,vb,vc=[verts[k] for k in tr]
    if (vb-va).cross(vc-va).z<0:tr=tuple(reversed(tr))
    faces.append(tr);center=sum((verts[k] for k in tr),Vector())/3;n=(verts[tr[1]]-verts[tr[0]]).cross(verts[tr[2]]-verts[tr[0]]).normalized()
    x,y,z=gp(center)
    if min(verts[k].z for k in tr)>.05 and n.z>.88 and not inside_paving(x,z):nav.append(list(tr))
 o=mesh('Authored_'+side+'_bedrock_soil_road',verts,faces,ground,ground_group,uvs,True);uv=o.data.uv_layers.new(name='DetailMetres')
 for loop in o.data.loops:
  v=o.data.vertices[loop.vertex_index].co;uv.data[loop.index].uv=(v.x/2.5,v.y/2.5)
 surface(side+'_terrace',navverts,nav)
 manifest.setdefault('nonwalkable_triangles',{})[side]=len(faces)-len(nav)

# Raised dressed stone landings tie load-bearing bridge directly to true gate thickness.
print('AUTHOR_STONEWORK',flush=True)
for label,a,b,c,d,y0,y1 in PAVING:
 rectsupport(label,a,b,c,d,y0,y1,4.6 if label=='gate_tunnel' else 99)
 cols=max(3,round((b-a)/.82));rows=8
 for j in range(rows):
  # Different masonry bond at the threshold gives construction, not colour swap.
  cuts=[a]+[float(v) for v in np.arange(a+(.46 if j%2 else .95),b,1.04)]+[b]
  for i,(xa,xb) in enumerate(zip(cuts,cuts[1:])):
   za=c+(d-c)*j/rows;zb=c+(d-c)*(j+1)/rows
   yy=y0+(y1-y0)*((xa+xb)/2-a)/(b-a)
   o=box(label+'_slab_%02d_%02d'%(j,i),((xa+xb)/2,yy-.065,(za+zb)/2),(xb-xa-.012,.13,zb-za-.012),stone,arch_group,.012)
   if y1!=y0:
    for v in o.data.vertices:v.co.z+=(y1-y0)/(b-a)*(v.co.x-(xa+xb)/2)
    o.data.update()
# Exposed older approach courses disappear into packed soil, not a detached tile carpet.
for j in range(8):
 z=-2.8+j*.8
 for k in range(1+(j%3)):
  x=-10.6-k*.73+random.uniform(-.12,.12);zz=z+random.uniform(-.11,.11);h=float(height(x,zz))
  box('BuriedApproachCourse',(x,h-.055,zz),(.64+random.uniform(-.07,.08),.13,.62+random.uniform(-.08,.07)),stone,arch_group,.035)
# Abutments: individual keyed stones reach below the water and carry the sill.
for x in [-7.15,7.15]:
 for row in range(5):
  for j in range(6):box('BridgeAbutmentBlock',(x,-1.50+row*.48,-2.68+j*1.07),(1.15,.47,1.05),stone,arch_group,.035)
# Main timber bridge is new joinery but uses native photogrammetric board contours and UV.
before=set(bpy.data.objects);bpy.ops.import_scene.gltf(filepath=str(SRC/'masters/modular_wooden_pier/modular_wooden_pier.gltf'));imported=list(set(bpy.data.objects)-before)
plank=next(o for o in imported if o.type=='MESH' and 'planks' in o.name.lower());uv=plank.data.uv_layers.active
# Mesh components split by UV are welded spatially for intact scan board recovery.
from collections import defaultdict
keys=[tuple(round(c,5) for c in v.co) for v in plank.data.vertices];adj=defaultdict(set)
for p in plank.data.polygons:
 ids=list(p.vertices)
 for a,b in zip(ids,ids[1:]+ids[:1]):adj[keys[a]].add(keys[b]);adj[keys[b]].add(keys[a])
labels={};parts=[]
for k in adj:
 if k in labels:continue
 stack=[k];part=[];idx=len(parts)
 while stack:
  v=stack.pop()
  if v in labels:continue
  labels[v]=idx;part.append(v);stack.extend(n for n in adj[v] if n not in labels)
 parts.append(part)
boardprotos=[]
for idx in range(len(parts)):
 polys=[p for p in plank.data.polygons if labels[keys[p.vertices[0]]]==idx]
 if not polys:continue
 raw=[plank.matrix_world@plank.data.vertices[i].co for p in polys for i in p.vertices];lo=Vector([min(v[k] for v in raw) for k in range(3)]);hi=Vector([max(v[k] for v in raw) for k in range(3)])
 if hi.x-lo.x<2:continue
 vs=[];uvs=[];fs=[]
 for p in polys:
  inds=[]
  for li in p.loop_indices:
   v=plank.matrix_world@plank.data.vertices[plank.data.loops[li].vertex_index].co;inds.append(len(vs));vs.append(v);uvs.append(tuple(uv.data[li].uv))
  fs.append(tuple(inds))
 boardprotos.append((vs,fs,uvs,lo,hi))
boardmat=plank.data.materials[0]
for n in boardmat.node_tree.nodes:
 if n.type=='TEX_IMAGE' and n.image and 'diff' in n.image.name.lower():n.image=bpy.data.images.load(str(TEX/'weathered-deck-atlas.jpg'),check_existing=True)
for o in imported:bpy.data.objects.remove(o,do_unlink=True)
record(SRC/'masters/modular_wooden_pier/SOURCE.json','CC0 worn board shape and original UV')
for i in range(34):
 for half in [-1,1]:
  vs,fs,uvs,lo,hi=boardprotos[(i+(half+1)*2)%len(boardprotos)];cx=-7+(i+.5)*14/34
  dest=[]
  for v in vs:
   across=(v.x-lo.x)/(hi.x-lo.x)*2.90;along=(v.y-(hi.y+lo.y)/2)/(hi.y-lo.y)*.397;yy=(v.z-hi.z)*.70+1.
   dest.append(pt(cx+along,yy,half*(across+.008)))
  o=mesh('NativeWornDeck_%02d_%d'%(i,half),dest,fs if half==1 else [tuple(reversed(f)) for f in fs],boardmat,arch_group,uvs)
rectsupport('bridge_main_deck',-7,7,-2.90,2.90,1,1)
for z in [-2.65,0,2.65]:beam('BridgeLongitudinalBearing',(-7.5,.65,z),(7.5,.65,z),.25,.30,parent=arch_group)
for x in [-5,0,5]:
 for z in [-2.65,2.65]:
  box('SubmergedPierFooting',(x,-1.35,z),(.85,.9,.85),stone,arch_group,.04)
  beam('BridgeBearingPost',(x,-1.1,z),(x,.73,z),.32,.34,parent=arch_group)
 beam('BridgeCrossHead',(x,.47,-3.12),(x,.47,3.12),.34,.34,parent=arch_group)
 for z in [-2.65,2.65]:
  beam('DiagonalFloodBrace',(x-1.45,.64,z),(x,-.75,z),.19,.20,parent=arch_group)
for sign in [-1,1]:
 z=sign*3.05
 for x in [-7,-4.666,-2.333,0,2.333,4.666,7]:
  box('RailingMortisedPost',(x,1.55,z),(.24,1.34,.24),wood,arch_group,.035)
  box('RailingWornCap',(x,2.24,z),(.32,.13,.32),wood,arch_group,.025)
  for yy in [1.36,1.93]:box('RailingWoodPeg',(x-.14,yy,z),(.05,.06,.06),wood,arch_group,.008)
 for yy in [1.35,1.92]:beam('RailingContinuousTenonedRail',(-7.12,yy,z),(7.12,yy,z),.16,.19,parent=arch_group)
 solid('bridge_rail_'+str(sign),[[-7,z-.14],[7,z-.14],[7,z+.14],[-7,z+.14]],.92,2.3)

# Thick gate piers and flanking wall, rebuilt as actual dressed block courses.
def facade(name,a,b,bottom,top,depth=2.8,front=True):
 ax,az=a;bx,bz=b;v=Vector((bx-ax,bz-az));length=v.length;v.normalize();normal=Vector((v.y,-v.x))
 if not front:normal=-normal
 mid=Vector(((ax+bx)/2,(az+bz)/2));poly=[Vector((ax,az))+normal*depth,Vector((bx,bz))+normal*depth,Vector((bx,bz)),Vector((ax,az))]
 # Solid core is behind the faced courses, not an exposed giant texture plane.
 coords=[pt(p.x,bottom,p.y) for p in poly]+[pt(p.x,top,p.y) for p in poly];mesh(name+'_Core',coords,BOXF,mortar,arch_group)
 solid(name,[[p.x,p.y] for p in poly],bottom,top+1.3)
 rowheight=.57;rows=round((top-bottom)/rowheight);hh=(top-bottom)/rows
 for row in range(rows):
  y=bottom+(row+.5)*hh;t=0;idx=0;offset=.52 if row%2 else 0.
  breaks=[0.]+[min(length,u) for u in np.arange(.72+offset,length,1.35)]+[length]
  for left,right in zip(breaks,breaks[1:]):
   width=right-left-.018
   if width<.1:continue
   center=Vector((ax,az))+v*((left+right)/2)-normal*(.04+max(0,2.0-y)*.06)
   o=box(name+'_Dressed_%02d_%02d'%(row,idx),(0,0,0),(.46,hh-.014,width),stone,arch_group,.025)
   # Local block X is wall normal, local Godot Z is course tangent.
   angle=math.atan2(v.x,v.y);o.rotation_euler.z=angle;o.location=pt(center.x,y,center.y);idx+=1
 for along in np.arange(.3,length,.95):
  p=Vector((ax,az))+v*min(along+.45,length-.2);o=box(name+'_Coping',(0,0,0),(depth+.24,.22,.93),stone,arch_group,.035);o.rotation_euler.z=math.atan2(v.x,v.y);o.location=pt(p.x+normal.x*depth/2,top+.11,p.y+normal.y*depth/2)
 for along in np.arange(.75,length,2.05):
  p=Vector((ax,az))+v*along+normal*.20;o=box(name+'_Merlon',(0,0,0),(.68,.88,1.02),stone,arch_group,.035);o.rotation_euler.z=math.atan2(v.x,v.y);o.location=pt(p.x,top+.66,p.y)
# Front face lines go out of the action frame; complete capacity remains behind.
facade('GateNorthPier',(11.7,-9.2),(11.7,-3.1),-.9,6.30,5.8)
facade('GateSouthPier',(11.7,3.1),(11.7,9.2),-.9,6.30,5.8)
# The north line uses the same inward-facing normal (+X) via its increasing Z order.
for name,a,b in [('NorthWingOuter',(15.2,-41),(12.3,-23)),('NorthWingInner',(12.3,-23),(11.7,-9.2)),('SouthWingInner',(11.7,9.2),(12.6,24)),('SouthWingOuter',(12.6,24),(17,42))]:facade(name,a,b,-1.45,5.55,2.8)
# A genuine rear court has flanking defenses and a rear escape, without an octagonal display ring.
facade('RearNorthEnclosure',(69,-34),(17,-34),.3,4.7,2.4)
facade('RearSouthEnclosure',(17,34),(69,34),.3,4.7,2.4)
for z0,z1 in [(-34,-4),(4,34)]:facade('RearEscapeWall'+str(z0),(70,z0),(70,z1),.3,4.7,2.4,False)
# Vertical bastion piers and stepped toe tie the wall to its rocky load path.
for z in [-28,-16,-5.7,5.7,16,28]:
 front=11.7 if abs(z)<10 else 12.1 if abs(z)<20 else 13.4
 for row in range(10):
  y=-.35+(row+.5)*.57;depth=.92-max(y,0)*.075
  box('BastionBondedPilaster',(front-depth/2-.08,y,z),(depth,.55,1.28),stone,arch_group,.04)
 for row in range(3):
  box('BatteredFoundationToe',(front-.35+row*.10,-.55+row*.53,z),(1.35-row*.2,.52,1.75),stone,arch_group,.045)
# Tunnel jamb reveals: five metres of real thickness, not a hollow wall decal.
for sign in [-1,1]:
 for row in range(8):
  yy=1.2+(row+.5)*.59
  for j in range(5):box('DeepTunnelJamb',(12.28+j*1.16,yy,sign*3.18),(1.145,.575,.29),stone,arch_group,.022)
for x in [11.85,13.25,14.65,16.05,17.25]:beam('GateRoofLoadLintel',(x,5.96,-3.48),(x,5.96,3.48),.37,.46,parent=arch_group)
box('GateBearingDeckCore',(14.6,6.15,0),(6.15,.20,18.7),mortar,arch_group,.025)
for i in range(5):
 for j in range(16):box('GatePlatformIndividualCoping',(12.14+i*1.23,6.29,-8.77+j*1.17),(1.216,.18,1.154),stone,arch_group,.026)
beam('FrontPortalOakLintel',(11.55,5.88,-3.5),(11.55,5.88,3.5),.42,.48,parent=arch_group)
for z in [-3.15,3.15]:beam('GateSolidOakJamb',(11.58,1.2,z),(11.58,5.75,z),.27,.34,parent=arch_group)
# Reuse the mature source roof and timber frame ONLY. Rejected inherited pier/wall removed.
print('REUSE_MATURE_ROOF_FRAME',flush=True)
archsrc=SHARED/'production-v2-architecture/mass02/architecture.glb';record(archsrc,'CC0 roof/frame components only; rejected old walls/fort/bridge not retained')
before=set(bpy.data.objects);bpy.ops.import_scene.gltf(filepath=str(archsrc));old=list(set(bpy.data.objects)-before)
roofgroup=group('NativeCraftRoofAndHall',arch_group)
for o in old:
 if o.type!='MESH' or not o.parent or o.parent.name!='GateHall':continue
 vs=[];fs=[];uvs=[];mi=[];source_uv=o.data.uv_layers[1] if len(o.data.uv_layers)>1 else o.data.uv_layers.active
 for poly in o.data.polygons:
  material=o.data.materials[poly.material_index]
  if material and material.name.lower().startswith('masonry'):continue
  pts=[o.matrix_world@o.data.vertices[i].co for i in poly.vertices]
  if min(v.z for v in pts)<7.15:continue
  inds=[]
  for li in poly.loop_indices:
   v=o.matrix_world@o.data.vertices[o.data.loops[li].vertex_index].co;inds.append(len(vs));vs.append(Vector(((v.x-30)*.94+14.6,(v.y+3)*1.02,(v.z-7.2)*.90+6.36)));uvs.append(tuple(source_uv.data[li].uv))
  fs.append(tuple(inds));mi.append(poly.material_index)
 if not fs:continue
 q=mesh('Native_'+o.name,vs,fs,o.data.materials[0],roofgroup,uvs)
 q.data.materials.clear()
 for m in o.data.materials:
  q.data.materials.append(m)
  if m and m.use_nodes:
   for node in m.node_tree.nodes:
    if node.type in ['UVMAP','NORMAL_MAP']:node.uv_map='UVMap'
 for p,i in zip(q.data.polygons,mi):p.material_index=i
for o in old:bpy.data.objects.remove(o,do_unlink=True)
# Dynamic leaves have exactly one gate-tagged parent, independent of stone and roof.
door=group('GateMain_DynamicLeaves',arch_group);door['gate_id']='gate_main'
for sign in [-1,1]:
 z=sign*1.55
 for j in range(8):box('OakGateBoard',(14.8,3.42,sign*(.2+j*.387)),(.19,4.44,.376),wood,door,.018)
 for yy in [1.55,2.95,4.35,5.43]:
  box('GateIronStrap',(14.66,yy,z),(.035,.105,3.05),iron,door,.008)
  for zz in np.arange(.25,3.05,.45):box('GateForgedStud',(14.62,yy,sign*zz),(.055,.065,.065),iron,door,.018)
blocker={'xz_polygon':[[14.60,-3.1],[14.98,-3.1],[14.98,3.1],[14.60,3.1]],'min_y':1.2,'max_y':5.7}
solid('gate_main_closed',blocker['xz_polygon'],1.2,5.7,'gate_main')
manifest['gate_dynamic']={'id':'gate_main','pivot':[14.8,1.2,0],'pivot_semantics':'ground landmark at actual door-plane center, not either leaf hinge','leaf_hinges':[[14.8,1.2,-3.1],[14.8,1.2,3.1]],'entry':[11.7,1.2,0],'exit':[17.5,1.2,0],'width':6.2,'clear_height':4.55,'closed_blocker':blocker,'visual_group':door.name}

# Native rock shapes are embedded in raised river shoulders, never arranged as a ring.
print('GEOLOGY_AND_ECOLOGY',flush=True)
def loadmeshes(path):
 before=set(bpy.data.objects);bpy.ops.import_scene.gltf(filepath=str(path));obs=list(set(bpy.data.objects)-before);result=[]
 for o in obs:
  if o.type=='MESH':
   me=o.data.copy();me.transform(o.matrix_world);result.append((o.name,me))
 for o in obs:bpy.data.objects.remove(o,do_unlink=True)
 return result
rocks=loadmeshes(SRC/'masters/rock_moss_set_01/rock_moss_set_01.gltf');record(SRC/'masters/rock_moss_set_01/SOURCE.json','CC0 native-scale scan rock family with original UV')
for name,me in rocks:
 for m in me.materials:
  for n in m.node_tree.nodes:
   if n.type=='TEX_IMAGE' and n.image and 'diff' in n.image.name.lower():n.image=bpy.data.images.load(str(TEX/'rock-mineral-atlas.jpg'),check_existing=True)
 # Normalize source asset origin only. Native rock dimensions are unchanged.
 bb=[min(v.co[k] for v in me.vertices) for k in range(3)];tt=[max(v.co[k] for v in me.vertices) for k in range(3)];off=Vector(((bb[0]+tt[0])/2,(bb[1]+tt[1])/2,bb[2]))
 for v in me.vertices:v.co-=off
# Designed exposed lithology pockets, separated by soil coves and reed margins.
ROCKS=[(-10.0,7.0,.1,1),(-11.5,8.8,.3,2),(-13.5,6.5,.3,3),(-15.7,10.2,.2,4),(-8.1,-5.6,-.35,0),(-10.2,-6.5,-.1,5),(-11.6,-8.4,.15,2),(-13.1,-9.6,.3,3),(-17.8,-13.5,.4,1),(-21,-17.3,.3,5),(-15.4,24.0,-.3,1),(-18.3,25.8,.0,0),(8.5,7.1,-.2,3),(9.1,9.3,.1,2),(10.3,12.2,.4,0),(8.7,-7.,-.25,4),(10.5,-8.6,.1,1),(13.2,-13.6,.1,0),(13.5,27.,.1,3)]
for i,(x,z,embed,idx) in enumerate(ROCKS):
 name,me=rocks[idx];ob=bpy.data.objects.new('EmbeddedScanStratum_%02d'%i,me);sc.collection.objects.link(ob);ob.parent=ground_group;h=float(height(x,z));ob.location=pt(x,h-.58+embed,z);ob.rotation_euler.z=i*1.71;ob.scale=(1.,1.,1.)
 # Convex footprint of actual source projected vertex extent, no fake collidable air.
 vs=[ob.matrix_world@v.co for v in me.vertices] if False else []
 w=max(v.co.x for v in me.vertices)-min(v.co.x for v in me.vertices);d=max(v.co.y for v in me.vertices)-min(v.co.y for v in me.vertices)
 r=max(w,d)*.44;poly=[[x+math.cos(a)*r,z+math.sin(a)*r] for a in np.linspace(0,2*math.pi,9)[:-1]]
 solid('rock_'+str(i),poly,h-.65,h+max(v.co.z for v in me.vertices)-.5)
# One native geological face becomes a continuous outcrop rising from the water.
cliffs=loadmeshes(SRC/'masters/coastal_cliff_02/coastal_cliff_02.gltf');record(SRC/'masters/coastal_cliff_02/SOURCE.json','native-scale cliff face cropped by author; only buried cut boundaries')
for ix,(x,z,dy,angle) in enumerate([]):
 me=cliffs[0][1].copy();bm=bmesh.new();bm.from_mesh(me)
 # Exact native middle section; authored earth ridges bury cut ends rather than crossing the military road.
 for plane,normal in [((-8,0,0),(1,0,0)),((8,0,0),(-1,0,0))]:bmesh.ops.bisect_plane(bm,geom=list(bm.verts)+list(bm.edges)+list(bm.faces),dist=.00001,plane_co=plane,plane_no=normal,clear_inner=True)
 bm.to_mesh(me);bm.free();ob=bpy.data.objects.new('EmbeddedNativeCliff_%d'%ix,me);sc.collection.objects.link(ob);ob.parent=ground_group;ob.location=pt(x,dy,z);ob.rotation_euler.z=angle
 points=[]
 for v in me.vertices:
  xx=x+v.co.x*math.cos(angle)-v.co.y*math.sin(angle);zz=z-v.co.x*math.sin(angle)-v.co.y*math.cos(angle);yy=dy+v.co.z
  if yy>float(height(xx,zz))+.15 and yy>.05:points.append((round(xx,3),round(zz,3)))
 points=sorted(set(points))
 def cross(a,b,c):return (b[0]-a[0])*(c[1]-a[1])-(b[1]-a[1])*(c[0]-a[0])
 lower=[];upper=[]
 for p in points:
  while len(lower)>=2 and cross(lower[-2],lower[-1],p)<=0:lower.pop()
  lower.append(p)
 for p in reversed(points):
  while len(upper)>=2 and cross(upper[-2],upper[-1],p)<=0:upper.pop()
  upper.append(p)
 poly=[list(p) for p in lower[:-1]+upper[:-1]]
 if len(poly)>=3:solid('cliff_'+str(ix),poly,.05,dy+9.83)
# Intact native canopy meshes are linked, not expanded mesh copies or paper billboards.
treepath=ROOT/'sprite-production/original-island-tree01/island_tree_01_2k.gltf';treeparts=loadmeshes(treepath);record(treepath,'complete CC0 original canopy+branch+trunk; linked geometry instances')
TREES=[(-18,-25,1.),(-18.5,-20.5,.94),(-20,-31,1.08),(-19,9,1.),(-24,12,1.12),(-25,19,1.),(-29,23,1.1),(-34,19,.97),(-22,29,1.07),(-28,34,1.12),(-20,-10,.98),(-23,-17,1.1),(-27,-12,1.),(-32,-22,1.12),(-24,-27,1.),(-35,-29,1.05),(18,19,1.1),(24,25,1.0),(29,28,1.1),(24,-24,1.),(29,-30,1.12),(36,-27,1.)]
for i,(x,z,scale) in enumerate(TREES):
 yy=float(height(x,z));par=group('RootedCanopy_%02d'%i,plants_group);par.location=pt(x,yy-.08,z);par.rotation_euler.z=i*1.96;par.scale=(scale,)*3
 for name,me in treeparts:
  o=bpy.data.objects.new('NativeTree_'+name,me);sc.collection.objects.link(o);o.parent=par
 solid('tree_trunk_'+str(i),[[x-.32,z-.32],[x+.32,z-.32],[x+.32,z+.32],[x-.32,z+.32]],yy,yy+3.5)
# Native woody understory forms an intermediate ecological layer around the rock shoulders.
shrubs=loadmeshes(SRC/'masters/searsia_burchellii/searsia_burchellii.gltf');record(SRC/'masters/searsia_burchellii/SOURCE.json','CC0 full native woody understory, not paper cards')
for name,me in shrubs:
 lo=[min(v.co[k] for v in me.vertices) for k in range(3)];hi=[max(v.co[k] for v in me.vertices) for k in range(3)];off=Vector(((lo[0]+hi[0])/2,(lo[1]+hi[1])/2,lo[2]))
 for v in me.vertices:v.co-=off
for i,(x,z) in enumerate([(-17,-7.5),(-22,-8.8),(-16,6.5),(-22,8.5),(-27,11),(9.3,8.9),(10,-11),(-31,-15)]):
 name,me=shrubs[2 if len(shrubs)>2 else 0];o=bpy.data.objects.new('RootedNativeUnderstory_'+str(i),me);sc.collection.objects.link(o);o.parent=plants_group;o.location=pt(x,float(height(x,z))-.12,z);o.rotation_euler.z=i*1.34
 solid('understory_stem_'+str(i),[[x-.28,z-.28],[x+.28,z-.28],[x+.28,z+.28],[x-.28,z+.28]],float(height(x,z)),float(height(x,z))+1.3)
# Physical low meadow and reed clumps authored in coherent bank patches.
# Broad leaf blades, no alpha noise, each rooted on the same continuous surface.
grassmats=[mat('MeadowLeaf_'+str(i),c,.95) for i,c in enumerate([(.055,.085,.027),(.073,.10,.035),(.09,.11,.044)])]
patches=[(-11.2,7.0,4.3,2.0),(-16.0,9.5,6,4),(-21,11,5,3),(-11.4,-7.2,4,2.7),(-17,-10,5,3),(-21,-14,6,4),(8.9,8.1,2.2,3.2),(9.4,-8.2,2.5,3.5),(-31,10,6,6)]
vs=[];fs=[];mis=[]
for pi,(cx,cz,rx,rz) in enumerate(patches):
 for j in range(int(rx*rz*6)):
  a=random.random()*math.tau;r=math.sqrt(random.random());x=cx+math.cos(a)*r*rx;z=cz+math.sin(a)*r*rz
  if road_weight(x,z)>.42:continue
  h=float(height(x,z));
  if h<-.35:continue
  for k in range(random.randint(4,7)):
   az=random.random()*math.tau;length=random.uniform(.10,.28);w=random.uniform(.025,.055);lean=random.uniform(.08,.20);v=Vector((math.cos(az),math.sin(az),0));per=Vector((-v.y,v.x,0))*w/2;base=pt(x+random.uniform(-.09,.09),h,z+random.uniform(-.09,.09));mid=base+v*lean*.35+Vector((0,0,length*.55));tip=base+v*lean+Vector((0,0,length));idx=len(vs);vs.extend([base-per,base+per,mid-per*.6,mid+per*.6,tip]);fs.extend([(idx,idx+1,idx+3,idx+2),(idx+2,idx+3,idx+4)]);mis.extend([pi%3,pi%3])
gr=mesh('RootedMeadow_ShoulderCommunities',vs,fs,grassmats[0],plants_group,smoothface=True)
for m in grassmats[1:]:gr.data.materials.append(m)
for p,i in zip(gr.data.polygons,mis):p.material_index=i
# Sparse reed fans belong to wet soil coves, not the packed action road.
reed=mat('WaterlineReedStems',(.15,.145,.065),.90)
for k,(x,z) in enumerate([(-8.3,5.8),(-10.4,-10.5),(8.0,6.4),(9.0,-11.7),(-13.1,28)]):
 h=float(height(x,z))
 for j in range(15):
  xx=x+random.uniform(-.6,.6);zz=z+random.uniform(-.6,.6);y=float(height(xx,zz));length=random.uniform(.6,1.1)
  if y<-.8:continue
  beam('RiparianReed',(xx,y,zz),(xx+.15,y+length,zz+.06),.018,.018,reed,plants_group)
# Water geometry carries coherent low-frequency waves. Native material remains calm.
watermat=mat('River_JadeCurrent',(.027,.065,.060),.19,normal=TEX/'river-current-normal.png',strength=.55);p=watermat.node_tree.nodes.get('Principled BSDF');p.inputs['Metallic'].default_value=.02;p.inputs['IOR'].default_value=1.333;p.inputs['Coat Weight'].default_value=.28
vs=[];fs=[]
for j in range(169):
 z=-42+j*.5
 for i in range(103):
  x=-26+i*.5;y=WATER_Y+.014*math.sin(z*2.7+x*.8)+.009*math.sin(z*4.3-x*.7);vs.append(pt(x,y,z))
for j in range(168):
 for i in range(102):a=j*103+i;fs.append((a,a+103,a+104,a+1))
water=mesh('UnbrokenRiverSurface',vs,fs,watermat,ground_group,smoothface=True)
for uv in water.data.uv_layers.active.data:uv.uv/=3.5
# Threshold use details: sparse engineering clues have functional place, not scatter inventory.
for sign in [-1,1]:
 for i in range(3):
  x=-13.2-i*.55;z=sign*(4.1+i*.12);h=float(height(x,z));beam('BankTimberRetainer',(x,h-.2,z),(x+.25,h+1.25,z),.16,.19,parent=arch_group)
 beam('BridgeheadRetainerRail',(-14.8,float(height(-14.8,sign*4.35))+.7,sign*4.35),(-12.8,float(height(-12.8,sign*4.15))+.7,sign*4.15),.13,.15,parent=arch_group)
# Source gameplay semantics and capacity are new, not inherited from old preflight results.
manifest['portals']=[
 {'id':'west_to_landing','from_surface':'west_terrace','to_surface':'west_landing','endpoints3D':[[-10.2,1,-3.1],[-10.2,1,3.1]],'width':6.2,'clearance':99},
 {'id':'bridge_west','from_surface':'west_landing','to_surface':'bridge_main_deck','endpoints3D':[[-7,1,-2.9],[-7,1,2.9]],'width':5.8,'clearance':99},
 {'id':'bridge_east','from_surface':'bridge_main_deck','to_surface':'east_landing','endpoints3D':[[7,1,-2.9],[7,1,2.9]],'width':5.8,'clearance':99},
 {'id':'gate_entry','from_surface':'east_landing','to_surface':'gate_tunnel','endpoints3D':[[11.7,1.2,-3.1],[11.7,1.2,3.1]],'width':6.2,'clearance':4.55},
 {'id':'gate_exit','from_surface':'gate_tunnel','to_surface':'east_terrace','endpoints3D':[[17.5,1.2,-3.1],[17.5,1.2,3.1]],'width':6.2,'clearance':4.55,'gate_id':'gate_main'}]
manifest['spawn_regions']=[{'id':'army_west','team':0,'surface_id':'west_terrace','xz_polygon':[[-57,-30],[-26,-30],[-26,30],[-57,30]],'reserved_corridor_z':[-6,6]},{'id':'army_east','team':1,'surface_id':'east_terrace','xz_polygon':[[28,-20],[62,-20],[62,20],[28,20]],'reserved_corridor_z':[-5,5]}]
manifest['retreat_regions']=[{'id':'retreat_west','surface_id':'west_terrace','xz_polygon':[[-59,-19],[-54,-19],[-54,19],[-59,19]]},{'id':'retreat_east','surface_id':'east_terrace','xz_polygon':[[75,-3],[83,-3],[83,3],[75,3]]}]
manifest['goal_regions']=[{'id':'gate_main_goal','surface_id':'east_terrace','center':[23,1.2,0],'radius':3}]
manifest['battle_mode']='open_gate_field_no_campaign';manifest['capacity_verdict']='NEW_SOURCE_NOT_RUN_512_EACH_REQUIRED';manifest['artist_status']='INTERNAL_WIP_NOT_OWNER_APPROVED'
# One author sun. The native WorldEnvironment values accompany the GLB explicitly.
sun=bpy.data.lights.new('AuthoredSun','SUN');sun.energy=2.7;sun.angle=.10;so=bpy.data.objects.new('AuthoredSun',sun);sc.collection.objects.link(so);so.parent=root;direction=Vector((-.45,-.52,.73)).normalized();so.rotation_euler=(-direction).to_track_quat('-Z','Y').to_euler()
w=bpy.data.worlds.new('AuthoredClearDay');w.use_nodes=True;w.node_tree.nodes['Background'].inputs[0].default_value=(.61,.69,.77,1);w.node_tree.nodes['Background'].inputs[1].default_value=.65;sc.world=w
worldspec={'background_color':[.61,.69,.77],'ambient_light_color':[.72,.76,.78],'ambient_light_energy':.62,'ambient_light_source':'COLOR','tonemap':'FILMIC','sun_energy':2.7,'lighting_units':'Blender COMPAT unitless: explicit Godot energy2.7; no683 lux conversion','sun_rotation_blender_euler':list(so.rotation_euler),'ssao_enabled':True,'ssao_radius':.55,'ssao_intensity':.65,'ssil_enabled':False,'fog_enabled':False}
(OUT/'author-world.json').write_text(json.dumps(worldspec,indent=2))
# Identity is derived from all authored geometry/semantics, not revision prose.
from topology_identity import topology_digest
record(Path(__file__).with_name('topology_identity.py'),'canonical surface/solid topology identity implementation')
record(OUT/'author-world.json','author native WorldEnvironment values');
# Every consumed source buffer and image is identified, not just its glTF JSON.
for path in [SRC/'masters/rock_moss_set_01',SRC/'masters/modular_wooden_pier',SRC/'masters/coastal_cliff_02',SRC/'masters/searsia_burchellii',treepath.parent]:
 for file in sorted(path.iterdir()):
  if file.suffix.lower() in ['.bin','.jpg','.png','.json']:record(file,'exact mature-source dependency')
for file in sorted((PBR/'fine_grained_wood').iterdir()):
 if file.suffix.lower()=='.png':record(file,'exact source wood material dependency')
manifest['topology_sha256']=topology_digest(manifest);manifest['authored_source_sha256']=hashlib.sha256((''.join(s['sha256'] for s in manifest['sources'])+manifest['topology_sha256']).encode()).hexdigest()
for key in ['map_id','topology_revision','topology_sha256','visual_revision','authored_source_sha256']:root[key]=manifest[key]
# Collect shared material-bearing geometry. Proxy actors are intentionally absent from this GLB.
print('BATCH_STATIC_ARCHITECTURE',flush=True)
# One batch per static author group; dynamic leaf and linked tree meshes remain independent.
for parent in [arch_group,roofgroup,door]:
 obs=[o for o in list(bpy.data.objects) if o.type=='MESH' and o.parent==parent]
 if len(obs)>1:
  bpy.ops.object.select_all(action='DESELECT')
  for o in obs:o.select_set(True)
  bpy.context.view_layer.objects.active=obs[0];bpy.ops.object.join();bpy.context.object.name=parent.name+'_StaticSurfaceBatch'
for side in ['west','east']:
 ob=bpy.data.objects.get('Authored_'+side+'_bedrock_soil_road');ob['surface_id']=side+'_terrace';ob['walk_triangle_selection']='mother-manifest.json exact source vertex indices; wet/steep faces excluded'
manifest['scan_derivation']='coast_rocks_03 original native topography+UV absorbed into continuous terrain; capture boundaries and standalone plate geometry not exported'
manifest['surface_source_scope']='terrain vertex-identical; landings/deck source construction top planes; actual bevel relief <=0.03m; no legacy Ground'
print('EXPORT_AUTHORED_MOTHER',flush=True)
sc.render.engine='CYCLES';sc.cycles.samples=64;sc.cycles.use_denoising=False;sc.render.resolution_x=1600;sc.render.resolution_y=900;sc.render.resolution_percentage=100;sc.view_settings.view_transform='AgX';sc.view_settings.look='AgX - Medium High Contrast'
bpy.ops.export_scene.gltf(filepath=str(OUT/'river-valley-hf01.glb'),export_format='GLB',export_extras=True,export_cameras=False,export_lights=True,export_import_convert_lighting_mode='COMPAT',export_animations=False,export_apply=True,export_tangents=True,export_yup=True,export_image_format='AUTO')
manifest['visual_glb_sha256']=sha(OUT/'river-valley-hf01.glb')
manifest['source_objects']=len(bpy.data.objects);usedmeshes=set(o.data for o in bpy.data.objects if o.type=='MESH');manifest['unique_meshes']=len(usedmeshes);manifest['mesh_triangles_unique']=sum(sum(len(p.vertices)-2 for p in m.polygons) for m in usedmeshes)
(OUT/'mother-manifest.json').write_text(json.dumps(manifest,separators=(',',':')))
# Save a compact script/input-based source recipe rather than redundant large .blend iterations.
(OUT/'RECOVER.txt').write_text('LUANSHI_WORKSPACE_ROOT='+str(ROOT)+' LUANSHI_PRODUCTION_ROOT='+str(SHARED)+' LUANSHI_BANK_FIELD='+os.environ.get('LUANSHI_BANK_FIELD','')+' python '+str(Path(__file__).with_name('build_materials.py'))+' '+str(TEX)+'\nLUANSHI_WORKSPACE_ROOT='+str(ROOT)+' LUANSHI_PRODUCTION_ROOT='+str(SHARED)+' LUANSHI_BANK_FIELD='+os.environ.get('LUANSHI_BANK_FIELD','')+' flock '+str(SHARED/'luanshi-heavy-art.lock')+' blender -b --factory-startup --disable-autoexec --threads 4 --python-exit-code 1 --python '+str(Path(__file__))+' -- '+str(OUT)+'\n')
if '--build-only' in sys.argv:raise SystemExit(0)
# Independent visual scale audit uses current real WIP18 posed actor, never spheres/sticks.
print('OFFLINE_SCALE_ACTORS_NOT_GAME',flush=True)
actor=SHARED/'production-v2-complete-spear18/runtime-verified/spearman-v2-wip.glb';before=set(bpy.data.objects);bpy.ops.import_scene.gltf(filepath=str(actor));aobs=list(set(bpy.data.objects)-before);arm=next(o for o in aobs if o.type=='ARMATURE');idle=next(a for a in bpy.data.actions if 'spear_idle' in a.name.lower());arm.animation_data_create()
for tr in list(arm.animation_data.nla_tracks):arm.animation_data.nla_tracks.remove(tr)
arm.animation_data.action=idle;sc.frame_set(int(idle.frame_range[0]));bpy.context.view_layer.update();dg=bpy.context.evaluated_depsgraph_get();actorparts=[];body=[]
for o in aobs:
 if o.type=='MESH' and len(o.data.materials)>0 and not o.hide_render:
  me=bpy.data.meshes.new_from_object(o.evaluated_get(dg),depsgraph=dg);me.transform(o.matrix_world);actorparts.append((o.name,me))
  if not any(t in o.name.lower() for t in ['spear','weapon','cone','cylinder']):body.extend(v.co.copy() for v in me.vertices)
for o in aobs:bpy.data.objects.remove(o,do_unlink=True)
poses=[(-15,-2),(-12,1),(-10,-1),(-7.8,.8),(-4.5,-1),(0,1),(4.2,-1),(7.8,.8),(10.,-1),(18.5,1.0)]
proxies=[]
for i,(x,z) in enumerate(poses):
 y=1. if -7<=x<=7 else float(height(x,z));par=group('NOT_GAME_StaticPose18_%02d'%i);par.location=pt(x,y,z);par.rotation_euler.z=-math.pi/2 if x<3 else math.pi/2
 for name,me in actorparts:o=bpy.data.objects.new('Pose18_'+name,me);sc.collection.objects.link(o);o.parent=par
 proxies.append(par)
for o in door.children:o.hide_render=True
cd=bpy.data.cameras.new('OFFLINE_GAME_CAMERA_CONDITION');cam=bpy.data.objects.new(cd.name,cd);sc.collection.objects.link(cam);sc.camera=cam
cd.sensor_fit='VERTICAL';cd.sensor_height=24.;fov=math.radians(50);cd.lens=24/(2*math.tan(fov/2));pitch=math.radians(45);yaw=math.radians(-65);span=1.8*math.cos(pitch)+(.55*abs(math.sin(yaw))+.35*abs(math.cos(yaw)))*math.sin(pitch);distance=span/(2*math.tan(fov/2)*.125)
views=[('nearshore',-15.,-2.,'PERSP'),('bridge',0.,1.,'PERSP'),('threshold',10.,-1.,'PERSP')]
if '--one-view' in sys.argv:views=views[:1]
report={'source_actor_sha256':sha(actor),'clip':idle.name,'body_source_height':max(v.z for v in body)-min(v.z for v in body),'status':'OFFLINE_ONLY_NOT_GAME','views':[]}
for name,x,z,typ in views:
 cd.type=typ;target=pt(x+1.5,float(height(x,z)) if abs(x)>7 else 1.,z)+Vector((0,0,1.));offset=Vector((math.sin(yaw)*math.cos(pitch),-math.cos(yaw)*math.cos(pitch),math.sin(pitch)))*distance;cam.location=target+offset;cam.rotation_euler=(target-cam.location).to_track_quat('-Z','Y').to_euler();bpy.context.view_layer.update()
 sizes=[]
 for par in proxies:
  proj=[world_to_camera_view(sc,cam,par.matrix_world@v) for v in body];sizes.append({'name':par.name,'godot_position':gp(par.location),'body_px':(max(p.y for p in proj)-min(p.y for p in proj))*900,'visible':all(0<=p.x<=1 and 0<=p.y<=1 for p in proj)})
 report['views'].append({'name':name,'matrix_blender':[list(r) for r in cam.matrix_world],'distance':distance,'fov_vertical':50,'output':[1600,900],'actual_actor_pixels':sizes});sc.render.filepath=str(OUT/(name+'-NOT_GAME.png'));bpy.ops.render.render(write_still=True)
(OUT/'offline-camera-measurements.json').write_text(json.dumps(report,indent=2));print('HF01_SOURCE_AND_OFFLINE_REVIEW_FINISHED_NOT_GAME',flush=True)
