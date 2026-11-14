"""Editable lamellar kit study from the owner-approved direction, not an art PASS.
Uses real punched/crowned/thickened plate master and original full rig.
Ordinary spear has NO red tassel. No character identity or story is defined.
"""
import bpy,bmesh,math,json,pathlib,sys,hashlib
from mathutils import Vector,Matrix
from mathutils.bvhtree import BVHTree
src,out=map(pathlib.Path,sys.argv[sys.argv.index('--')+1:][:2]);out.mkdir(parents=True,exist_ok=True);sha=hashlib.sha256(src.read_bytes()).hexdigest()
bpy.ops.wm.open_mainfile(filepath=str(src),load_ui=False,use_scripts=False);rig=bpy.data.objects['rig'];coat=bpy.data.objects['GEO-topLT-recut']
def material(name,color,rough=.72,metal=0):
 m=bpy.data.materials.new(name);m.use_nodes=True;p=m.node_tree.nodes.get('Principled BSDF');p.inputs['Base Color'].default_value=(*color,1);p.inputs['Roughness'].default_value=rough;p.inputs['Metallic'].default_value=metal;return m
steel=material('Kit satin dark iron',(.19,.205,.21),.58,.65);leather=material('Kit oxblood binding',(.17,.065,.035));cloth=material('Kit warm undyed sleeve',(.48,.44,.35));white=material('Kit undyed collar',(.68,.64,.54));red=material('Kit red brown sash',(.26,.075,.035));dark=material('Kit charcoal trousers',(.075,.08,.08));wood=material('Kit ash shaft',(.22,.12,.055));shoe=material('Kit cloth shoe',(.055,.055,.05))
coat.data.materials.clear();coat.data.materials.append(cloth)
for o in bpy.context.scene.objects:
 if o.type!='MESH':continue
 m=red if 'sash' in o.name else dark if 'pantsLT' in o.name else None
 if m:o.data.materials.clear();o.data.materials.append(m)
# One editable master: six connected cells with four actual through-holes.
vs=[];fs=[]
xs=[-.017,0,.017];zs=[-.045,-.015,.015,.045]
for row in range(3):
 for col in range(2):
  a,b=xs[col:col+2];c,d=zs[row:row+2];cx=(a+b)/2;cz=(c+d)/2
  outer=[(a,c),(cx,c),(b,c),(b,cz),(b,d),(cx,d),(a,d),(a,cz)]
  start=len(vs)
  for x,z in outer:vs.append((x,-.0012*(1-(x/.017)**2),z))
  if row!=1:
   for k in range(8):
    an=-3*math.pi/4+k*math.pi/4;x=cx+.0022*math.cos(an);z=cz+.0022*math.sin(an);vs.append((x,-.0012*(1-(x/.017)**2),z))
   for k in range(8):fs.append((start+k,start+(k+1)%8,start+8+(k+1)%8,start+8+k))
  else:fs.append(tuple(start+k for k in range(8)))
me=bpy.data.meshes.new('Punched crowned lamella editable');me.from_pydata(vs,[],fs);me.update();master=bpy.data.objects.new('SOURCE lamella master',me);bpy.context.collection.objects.link(master)
bpy.context.view_layer.objects.active=master;master.select_set(True)
bm=bmesh.new();bm.from_mesh(me);bmesh.ops.remove_doubles(bm,verts=list(bm.verts),dist=.000001);bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces));bm.to_mesh(me);bm.free()
solid=master.modifiers.new('Physical iron thickness 2mm','SOLIDIFY');solid.thickness=.002;solid.offset=0
bevel=master.modifiers.new('Worked rounded edges','BEVEL');bevel.width=.00065;bevel.segments=2
bpy.context.view_layer.update();ev=master.evaluated_get(bpy.context.evaluated_depsgraph_get());em=ev.to_mesh();pv=[v.co.copy() for v in em.vertices];pf=[list(f.vertices) for f in em.polygons];ev.to_mesh_clear();master.hide_render=True;master.hide_set(True)
verts=[];faces=[];mats=[];weights=[];pieces=[];expected=[]
def thicken_panel(points,polygons,thickness=.003):
 points=list(map(Vector,points));norm=[Vector() for _ in points];edges={}
 for f in polygons:
  n=(points[f[1]]-points[f[0]]).cross(points[f[2]]-points[f[0]]).normalized()
  for i in f:norm[i]+=n
  for a,b in zip(f,list(f[1:])+[f[0]]):edges.setdefault(tuple(sorted((a,b))),[]).append((a,b))
 nn=[n.normalized() for n in norm];count=len(points);out=[p+n*thickness/2 for p,n in zip(points,nn)]+[p-n*thickness/2 for p,n in zip(points,nn)]
 faces=[list(f) for f in polygons]+[[i+count for i in reversed(f)] for f in polygons]
 for es in edges.values():
  if len(es)==1:a,b=es[0];faces.append([b,a,a+count,b+count])
 return out,faces
def add_mesh(points,polygons,bone,mat_index,label):
 if 'backing' in label or 'whole leather vest' in label:points,polygons=thicken_panel(points,polygons)
 # New rigid armor pieces have intentionally rigid attachment, not truncated
 # source cloth weights. Unpose once to the exact original full rig's rest frame.
 b=rig.data.bones[bone];pb=rig.pose.bones[bone];unpose=(rig.matrix_world@pb.matrix@b.matrix_local.inverted()@rig.matrix_world.inverted()).inverted()
 start=len(verts);expected.extend(Vector(p) for p in points);verts.extend(unpose@Vector(p) for p in points);weights.extend([bone]*len(points));faces.extend([[start+i for i in f] for f in polygons]);mats.extend([mat_index]*len(polygons));pieces.append({'label':label,'bone':bone,'vertices':len(points)})
def plate(center,normal,up,bone,label):
 n=Vector(normal).normalized();z=Vector(up).normalized();x=z.cross(n).normalized();z=n.cross(x).normalized();center=Vector(center)
 add_mesh([center+x*p.x-n*p.y+z*p.z for p in pv],pf,bone,0,label)
def cord(a,b,bone,label,r=.0014):
 a,b=Vector(a),Vector(b);axis=(b-a).normalized();x=axis.cross(Vector((0,0,1)))
 if x.length<.1:x=axis.cross(Vector((0,1,0)))
 x.normalize();y=axis.cross(x);points=[]
 for t in [0,.25,.5,.75,1]:
  c=a.lerp(b,t)+Vector((0,-.0015*math.sin(math.pi*t),0))
  for i in range(6):points.append(c+r*(x*math.cos(i*math.tau/6)+y*math.sin(i*math.tau/6)))
 polys=[]
 for row in range(4):
  for k in range(6):polys.append((row*6+k,row*6+(k+1)%6,(row+1)*6+(k+1)%6,(row+1)*6+k))
 add_mesh(points,polys,bone,1,label)
dg=bpy.context.evaluated_depsgraph_get();ev=coat.evaluated_get(dg);em=ev.to_mesh();bvh=BVHTree.FromPolygons([ev.matrix_world@v.co for v in em.vertices],[list(f.vertices) for f in em.polygons]);ev.to_mesh_clear()
# Four articulated chest courses and a separate back, each laced through holes.
for front in [True,False]:
 direction=Vector((0,1 if front else -1,0));origin=-1 if front else 1
 for row in range(6):
  z=1.30+row*.075;bone='DEF-spine.03' if z<1.53 else 'DEF-spine.04';centers=[]
  for col in range(10):
   x=(col-4.5)*.034;hit=bvh.ray_cast(Vector((x,origin,z)),direction)
   if hit[0] is None:continue
   n=hit[1];n=n if n.dot(direction)<0 else -n;c=hit[0]+n*.017;plate(c,n,(0,0,1),bone,f'body {front} {row} {col}');centers.append(c)
  for a,b in zip(centers,centers[1:]):
   for dz in [-.029,.029]:cord(a+Vector((.008,-.003 if front else .003,dz)),b+Vector((-.008,-.003 if front else .003,dz)),bone,'body lacing')
# Continuous underlying leather front/back carrier, fitted as real closed panels.
for front in [True,False]:
 points=[];polygons=[];rows=12;cols=12;origin=-1 if front else 1;direction=Vector((0,1 if front else -1,0))
 for r in range(rows+1):
  z=1.25+r*.04;half=.165 if r<8 else .165-(r-8)*.014
  for c in range(cols+1):
   x=-half+2*half*c/cols;hit=bvh.ray_cast(Vector((x,origin,z)),direction)
   if hit[0] is None:raise RuntimeError('Carrier seam missing underlying garment')
   n=hit[1] if hit[1].dot(direction)<0 else -hit[1];points.append(hit[0]+n*.011)
 for r in range(rows):
  for c in range(cols):
   a=r*(cols+1)+c;polygons.append((a,a+1,a+cols+2,a+cols+1))
 add_mesh(points,polygons,'DEF-spine.03',1,'whole leather vest front' if front else 'whole leather vest back')
# Whole shoulder mantle: curved articulated courses, not floating flat squares.
for sign,side in [(1,'L'),(-1,'R')]:
 points=[];polys=[]
 for r in range(5):
  for c in range(13):
   an=math.radians(-82+c*14);points.append(Vector((sign*(.235+r*.06),-.052,1.654))+Vector((0,-math.sin(an),math.cos(an)))*.13)
 for r in range(4):
  for c in range(12):a=r*13+c;polys.append((a,a+1,a+14,a+13))
 add_mesh(points,polys,'DEF-upper_arm.'+side+'.01',1,'whole shoulder leather backing '+side)
 for row in range(3):
  for col in range(12):
   angle=math.radians(-75+col*14);n=Vector((0,-math.sin(angle),math.cos(angle)));center=Vector((sign*(.285+row*.068),-.052,1.654))+n*.135
   plate(center,n,(sign,0,0),'DEF-upper_arm.'+side+'.01',f'shoulder {side} {row} {col}')
# Eight separated armored skirt leaves: backing and plates retain real gaps.
for panel in range(8):
 angle=(panel/8)*math.tau;n=Vector((math.sin(angle),-math.cos(angle),0));tangent=Vector((math.cos(angle),math.sin(angle),0));bone='DEF-thigh.L.01' if n.x>.1 else 'DEF-thigh.R.01' if n.x<-.1 else 'DEF-spine.01'
 backing=[]
 for z,radius in [(1.22,.235),(.86,.285)]:
  for x in [-.055,.055]:backing.append(Vector((0,-.09,z))+n*radius+tangent*x)
 add_mesh(backing,[(0,1,3,2)],bone,1,f'skirt backing {panel}')
 for row in range(4):
  z=1.17-row*.078;rad=.245+row*.012
  for col in range(3):plate(Vector((0,-.09,z))+n*rad+tangent*((col-1)*.034),n,(0,0,1),bone,f'skirt {panel} {row} {col}')
mesh=bpy.data.meshes.new('Complete lamellar construction');mesh.from_pydata(verts,[],faces);mesh.update();arm=bpy.data.objects.new('KIT articulated lamellar complete',mesh);bpy.context.collection.objects.link(arm)
mesh.materials.append(steel);mesh.materials.append(leather)
for f,mi in zip(mesh.polygons,mats):f.material_index=mi;f.use_smooth=True
for bone in sorted(set(weights)):
 g=arm.vertex_groups.new(name=bone);g.add([i for i,b in enumerate(weights) if b==bone],1,'REPLACE')
m=arm.modifiers.new('Original 308 bone rig armor attachments','ARMATURE');m.object=rig;m.use_deform_preserve_volume=True
bpy.context.view_layer.update();eval_arm=arm.evaluated_get(bpy.context.evaluated_depsgraph_get());am=eval_arm.to_mesh();rest_error=max((arm.matrix_world@v.co-p).length for v,p in zip(am.vertices,expected));eval_arm.to_mesh_clear();print('KIT_REST_ERROR',rest_error,flush=True)
bpy.ops.wm.save_as_mainfile(filepath=str(out/'spearman-kit-editable.blend'))
# Diagnostic whole-actor image, not gameplay or costume acceptance.
scene=bpy.context.scene;scene.use_nodes=False;scene.render.engine='CYCLES';scene.cycles.samples=24;scene.cycles.use_denoising=False;scene.view_layers[0].material_override=None
scene.world=bpy.data.worlds.new('Kit review');scene.world.use_nodes=True;scene.world.node_tree.nodes['Background'].inputs['Strength'].default_value=.4
bpy.ops.object.light_add(type='AREA',location=(3,-4,5));bpy.context.object.data.energy=700;bpy.context.object.data.size=4
bpy.ops.object.camera_add(location=(2.7,-5,2.6));cam=bpy.context.object;cam.rotation_euler=(Vector((0,-.08,1.03))-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.type='ORTHO';cam.data.ortho_scale=2.5;scene.camera=cam
scene.render.resolution_x=960;scene.render.resolution_y=1200;scene.render.resolution_percentage=100;scene.render.filepath=str(out/'kit-first-wholebody-BLENDER-NOT-GAME.png');bpy.ops.render.render(write_still=True)
for side,sign in [('L',1),('R',-1)]:
 rig.pose.bones['hand_ik.'+side]['ik']=0.
 for stem,ang in [('upper_arm.',-.95*sign),('forearm.',.75*sign)]:
  bone=rig.pose.bones[stem+side];bone.rotation_mode='XYZ';bone.rotation_euler[2]=ang
bpy.context.view_layer.update();scene.render.filepath=str(out/'kit-lowered-arms-stress-BLENDER-NOT-GAME.png');bpy.ops.render.render(write_still=True)
(out/'report.json').write_text(json.dumps({'source_sha256':sha,'source_unchanged':hashlib.sha256(src.read_bytes()).hexdigest()==sha,'owner_reference_sha256':'fef54505bf0adb82646cd5c9e955170b255b3cbb8c5d6cfe1dc49c623167a932','art_pass':False,'game_tested':False,'ordinary_spear_tassel':False,'rig_bones':len(rig.data.bones),'rest_attachment_error_m':rest_error,'kit_vertices':len(verts),'kit_faces':len(faces),'construction':pieces,'missing':['helmet','young head replacement','cloth shoes and puttees','spear and grip','motion clearance and complete UV/material production']},indent=2)+'\n')
