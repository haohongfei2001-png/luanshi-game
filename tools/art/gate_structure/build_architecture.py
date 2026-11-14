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
for name in source_objects:
 o=source_objects[name];uv=o.data.uv_layers.active
 roof[name]=[[(tuple(o.matrix_world@o.data.vertices[o.data.loops[i].vertex_index].co),tuple(uv.data[i].uv) if uv else (0.,0.),tuple((o.matrix_world.to_3x3().inverted().transposed()@o.data.corner_normals[i].vector).normalized())) for i in p.loop_indices] for p in o.data.polygons]
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
surface_scales={}
if '--surface-root' in args:
 sys.path.insert(0,str(Path(__file__).resolve().parent))
 from apply_surface_materials import apply
 surface_scales=apply(materials,args[args.index('--surface-root')+1])
root=bpy.data.objects.new('AuthoredArchitecture',None);bpy.context.collection.objects.link(root)
groups={}
def group(name):
 o=bpy.data.objects.new(name,None);bpy.context.collection.objects.link(o);o.parent=root;groups[name]=o;return o
gate=group('GateHall');door=group('GateDoor');walls=group('WallWalk');bridge=group('GateBridge');west=group('WestBridge')
def mesh(name,verts,faces,mat,parent,uvs=None,normals=None):
 d=bpy.data.meshes.new(name);d.from_pydata(verts,[],faces);d.materials.append(materials[mat]);d.update();o=bpy.data.objects.new(name,d);bpy.context.collection.objects.link(o);o.parent=parent
 # One shared active UV channel is required when source and authored surfaces join.
 layer=d.uv_layers.new(name='UVMap')
 for poly in d.polygons:
  for li in poly.loop_indices:
   v=d.vertices[d.loops[li].vertex_index].co
   if uvs:layer.data[li].uv=uvs[d.loops[li].vertex_index]
   elif '--complete-gate-masonry' in args:
    # World-metre box projection keeps vertical facade UVs non-degenerate.
    # The old mixed X/(Z+Y) plane collapsed front walls into narrow strips.
    axis=max(range(3),key=lambda k:abs(poly.normal[k]))
    layer.data[li].uv=(v.y,v.z) if axis==0 else (v.x,v.z) if axis==1 else (v.x,v.y)
   else:layer.data[li].uv=(v.x*.3,v.z*.3+v.y*.05)
 if mat in surface_scales:
  # Preserve the author's original UVMap; a separate explicitly named material
  # layer has metre-scale coordinates with timber grain along the member axis.
  material_uv=d.uv_layers.new(name='MaterialUV_Metre');tile=surface_scales[mat]
  lo=[min(v.co[k] for v in d.vertices) for k in range(3)];hi=[max(v.co[k] for v in d.vertices) for k in range(3)]
  grain=max(range(3),key=lambda k:hi[k]-lo[k])
  for poly in d.polygons:
   normal_axis=max(range(3),key=lambda k:abs(poly.normal[k]));plane=[k for k in range(3) if k!=normal_axis]
   if mat in ['timber','timber_cut'] and grain in plane:plane=[k for k in plane if k!=grain]+[grain]
   for li in poly.loop_indices:
    v=d.vertices[d.loops[li].vertex_index].co
    if mat=='masonry' and name.startswith('GateVault_') and normal_axis==0:
     # Radial voussoirs are individual cut stones: use a stone interior island,
     # never print the wall's horizontal mortar courses over an arch block.
     material_uv.data[li].uv=(.17+.28*(v.y-lo[1])/max(hi[1]-lo[1],.001),.03+.15*(v.z-lo[2])/max(hi[2]-lo[2],.001))
    else:material_uv.data[li].uv=(v[plane[0]]/tile,v[plane[1]]/tile)
 if normals:
  for poly in d.polygons:poly.use_smooth=True
  d.normals_split_custom_set([normals[loop.vertex_index] for loop in d.loops])
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
# Complete load-bearing gateway enclosure. Keep the real wall-walk corridor
# x49.4..52.6 clear to y5.45; the gallery sits on continuous facade spandrels
# and a high bearing course, not on isolated piers beneath a floating floor.
if '--complete-gate-masonry' in args:
 def arch_outer(z):
  return cz+math.sqrt(max(0.,(R+.55)**2-z*z))
 for front,back,label in [(46.65,49.12,'Front'),(52.85,53.45,'Rear')]:
  intervals=[-8.15,-4.25]+[-4.25+i*8.5/34 for i in range(1,34)]+[4.25,8.15]
  vs=[];faces=[]
  for za,zb in zip(intervals,intervals[1:]):
   # The arch's native voussoir outer edge is the exact underside of infill.
   ya=arch_outer(za) if abs(za)<4.25 else 4.59
   yb=arch_outer(zb) if abs(zb)<4.25 else 4.59
   start=len(vs)
   for x in [front,back]:
    for z,y in [(za,ya),(zb,yb),(zb,5.69),(za,5.69)]:vs.append(pt(x,y,z))
   faces.extend([tuple(start+j for j in face) for face in [(0,3,2,1),(4,5,6,7),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7)]])
  ob=mesh('GateContinuousSpandrel_'+label,vs,faces,'masonry',gate)
  ob['structural_role']='continuous arch shoulder to timber-gallery bearing; full depth facade; clear historic gameplay passage'
 # Header above the interior wall-walk. No masonry is placed in its adult
 # headroom; floor bearing continues over the passage at 2.20m clear height.
 for sign in [-1,1]:
  box('GateGalleryBearing',(50.05,5.62,sign*6.15),(6.8,.14,4.0),'masonry',gate,.012)

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
   t=(value-p[0][axis])/(q[0][axis]-p[0][axis]);v=tuple(p[0][j]+t*(q[0][j]-p[0][j]) for j in range(3));uv=tuple(p[1][j]+t*(q[1][j]-p[1][j]) for j in range(2));normal=tuple((Vector(p[2]).lerp(Vector(q[2]),t)).normalized());result.append((v,uv,normal))
 return result
S=.19;extension=5.;roof_pieces=[]
# Full adult-height upper hall: floor5.72, column head7.92, original roof frame above.
ROOF_BASE=7.92-20.36121940612793*S
def roof_part(name,polys,offset=0,lo=None,hi=None,material='tile',longitudinal_scale=1.):
 vs=[];fs=[];uv=[];normals=[]
 for poly in polys:
  if lo is not None:poly=clip(poly,1,lo,False)
  if hi is not None:poly=clip(poly,1,hi,True)
  if len(poly)<3:continue
  fs.append(tuple(range(len(vs),len(vs)+len(poly))))
  for v,t,n in poly:
   vs.append((50.05+v[0]*S,v[1]*S*longitudinal_scale+offset,ROOF_BASE+v[2]*S));uv.append(t)
   normals.append(tuple(Vector((n[0],n[1]/longitudinal_scale,n[2])).normalized()))
 o=mesh(name,vs,fs,material,gate,uv,normals);o['source']='VVayToyek CC0 pavilion roof; polygon clipped, UV interpolated, ridge extended';roof_pieces.append(o)
roof_part('Roof_HipNorth',roof['瓦面1'],-extension)
roof_part('Roof_HipSouth',roof['瓦面3'],extension)
for source_name,label in [('瓦面2','East'),('瓦面4','West')]:
 if '--native-roof-band' in args:
  # Preserve complete native hip/corner regions. The only replaced central band
  # is one full straight tile-column phase, not arbitrary narrow slices.
  native_pitch_m=.17180710002779964;half=native_pitch_m/(2*S)
  roof_part('Roof_'+label+'_north',roof[source_name],-extension,hi=-half)
  roof_part('Roof_'+label+'_south',roof[source_name],extension,lo=half)
  span=2*extension+native_pitch_m;n=round(span/native_pitch_m);step=span/n
  for i in range(n):roof_part('Roof_'+label+'_central_%02d'%i,roof[source_name],-span/2+step*(i+.5),lo=-half,hi=half,longitudinal_scale=step/native_pitch_m)
 else:
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
for x,y in [(47.35,ROOF_BASE+3.98),(50.05,ROOF_BASE+5.3),(52.75,ROOF_BASE+3.98)]:beam('RoofLongPurlin',(x,y,-4.9),(x,y,4.9),.16,.2,'timber',gate)
# Continuous low ridge cap; crown shape with real sides, not a flat giant strip.
for i in range(40):
 z=-5+i*.25
 beam('RoofRidgeCap',(50.05,ROOF_BASE+5.82,z),(50.05,ROOF_BASE+5.82,z+.246),.34,.26,'tile',gate)
# Complete upper timber hall, derived from the original load-bearing column,
# architrave, eave-board, corner-block and inner-purlin systems. Not a pavilion
# perched on walls: the square structural bays become a three-bay gate gallery.
def native_member(label,source_name,scale,translation):
 vs=[];fs=[];uvs=[];normals=[]
 for poly in roof[source_name]:
  fs.append(tuple(range(len(vs),len(vs)+len(poly))))
  for v,uv,n in poly:
   vs.append(tuple(v[i]*scale[i]+translation[i] for i in range(3)));uvs.append(uv)
   # Diagonal affine deformation: exact inverse-transpose for source corner normals.
   normals.append(tuple(Vector(tuple(n[i]/scale[i] for i in range(3))).normalized()))
 ob=mesh(label,vs,fs,'timber',gate,uvs,normals);ob['source_member']=source_name
 return ob
column_head=7.92;floor=5.72;column_scale=(column_head-floor)/20.36121940612793
# Cross frames are spaced as full bays, their inner longitudinal corners shared.
lines=[-7.09,-2.363333333,2.363333333,7.09]
for line in lines:
 for source_name in ['檐柱1','檐柱2']:
  native_member('HallNativeColumn',source_name,(S,S,column_scale),(50.05,line+11*S,floor))
 # Complete transverse frame from the original front face; no decorative plaque/text.
 for source_name in ['额枋1','檐檩垫板1','衬头木1']:
  native_member('HallNativeTransverse_'+source_name,source_name,(S,S,S),(50.05,line+11*S,ROOF_BASE))
 for source_name in ['角云1','角云4']:
  native_member('HallNativeCornerBlock',source_name,(S,S,S),(50.05,line+11*S,ROOF_BASE))
for first,last in zip(lines,lines[1:]):
 middle=(first+last)/2;length=last-first;yscale=length/22
 for source_name in ['额枋3','额枋4','檐檩垫板3','檐檩垫板4','衬头木2','衬头木4']:
  native_member('HallNativeLongitudinal_'+source_name,source_name,(S,yscale,S),(50.05,middle,ROOF_BASE))
# Inner purlins follow the roof's end caps and extended central ridge, not the
# column bay length: stretching end bays to outer columns pierces the hips.
for source_name in ['金檩金枋2','金檩金枋4']:
 roof_part('HallNativeInnerPurlin_N',roof[source_name],-extension,hi=0,material='timber')
 roof_part('HallNativeInnerPurlin_S',roof[source_name],extension,lo=0,material='timber')
 native_member('HallNativeInnerPurlin_Center',source_name,(S,10/15.409034,S),(50.05,0,ROOF_BASE))
# Native curved corner beams continue into the professional hip rafters at both ends.
for family in ['老角梁','仔角梁由戗']:
 for i in range(1,5):roof_part('HallNativeHip_'+family+str(i),roof[family+str(i)],-extension if i<=2 else extension,material='timber')
# Visible floor, gallery rail and weather enclosure use restrained real boards,
# rather than uniform huge boxes or ornamental garden seating.
box('HallFloorJoists',(50.05,floor-.13,0),(4.65,.22,14.65),'timber',gate,.018)
for i in range(61):
 z=-7.2+(i+.5)*14.4/61
 box('HallFloorBoard',(50.05,floor-.015,z),(4.52,.06,14.4/61-.012),'timber_cut',gate,.007)
for x in [47.96,52.14]:
 for first,last in zip(lines,lines[1:]):
  # Lower plank screens plus open upper viewing slots establish military use.
  for j in range(12):
   z=first+(j+.5)*(last-first)/12
   box('HallScreenBoard',(x,floor+.65,z),(.095,1.26,(last-first)/12-.025),'timber',gate,.012)
  beam('HallSill',(x,floor+.05,first),(x,floor+.05,last),.17,.15,'timber_cut',gate)
  beam('HallScreenRail',(x,floor+1.28,first),(x,floor+1.28,last),.15,.13,'timber_cut',gate)
  for j in range(1,8):
   z=first+j*(last-first)/8
   beam('HallViewingMullion',(x,floor+1.3,z),(x,column_head-.3,z),.065,.065,'timber',gate)
# End galleries retain the original connected shaped rail structure, no seats.
for sign in [-1,1]:
 z=sign*7.09
 for x in [48.45,49.5,50.6,51.65]:
  beam('HallEndGalleryBaluster',(x,floor+.1,z),(x,floor+1,z),.075,.075,'timber',gate)
 beam('HallEndGalleryRail',(47.96,floor+1.05,z),(52.14,floor+1.05,z),.14,.14,'timber_cut',gate)

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
report={'status':'ART_NOT_ACCEPTED','source':'VVayToyek CC0 roof + Rico Cilliers Poly Haven CC0 native deck boards; authored military mass and structural bridge','mesh_objects':len(objects),'triangles':sum(len(o.data.loop_triangles) for o in objects),'roof_source_uv_preserved':True,'door_net_width':8,'bridge_clear_width':7.4,'bridge_deck_top':.13,'legacy_meshes':False,'upper_hall_floor_m':5.72,'upper_hall_column_head_m':7.92,'height_variant':'approximately10m; original8.2m tentative target exceeded; same-camera acceptance REQUIRED','source_corner_normals':'original world inverse-transpose; uniform roof clip interpolation; diagonal member inverse-transpose','normal_status':'actual-shadow-on/off comparison NOT_RUN','complete_gate_masonry':('--complete-gate-masonry' in args),'protected_walkway_clear_height_m':2.20}
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
