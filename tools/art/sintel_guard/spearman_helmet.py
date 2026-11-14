"""Complete editable dome/band/neck-guard helmet study; not a costume PASS."""
import bpy,math,pathlib,sys,json,hashlib
from mathutils import Vector
src,out=map(pathlib.Path,sys.argv[sys.argv.index('--')+1:][:2]);out.mkdir(parents=True,exist_ok=True);bpy.ops.wm.open_mainfile(filepath=str(src),use_scripts=False,load_ui=False)
rig=bpy.data.objects['rig'];bone='DEF-neck.03';b=rig.data.bones[bone];unpose=(rig.matrix_world@rig.pose.bones[bone].matrix@b.matrix_local.inverted()@rig.matrix_world.inverted()).inverted()
def mat(name,color,rough,metal=0):
 m=bpy.data.materials.new(name);m.use_nodes=True;p=m.node_tree.nodes.get('Principled BSDF');p.inputs['Base Color'].default_value=(*color,1);p.inputs['Roughness'].default_value=rough;p.inputs['Metallic'].default_value=metal;return m
iron=mat('Helmet satin iron',(.18,.20,.21),.54,.65);edge=mat('Helmet worked edge',(.25,.26,.25),.57,.65);leather=mat('Helmet warm lining',(.12,.055,.025),.85);red=mat('Helmet red-brown plume',(.19,.045,.025),.9)
parts=[]
def piece(name,points,faces,material,thickness=.002):
 mesh=bpy.data.meshes.new(name);mesh.from_pydata([unpose@Vector(p) for p in points],[],faces);mesh.update();o=bpy.data.objects.new(name,mesh);bpy.context.collection.objects.link(o);mesh.materials.append(material)
 uv=mesh.uv_layers.new(name='HelmetPatternUV')
 for f in mesh.polygons:
  f.use_smooth=True
  for li in f.loop_indices:
   p=Vector(points[mesh.loops[li].vertex_index]);uv.data[li].uv=(math.atan2(p.x,-(p.y+.055))/math.tau+.5,(p.z-1.72)/.43)
 g=o.vertex_groups.new(name=bone);g.add(list(range(len(points))),1,'REPLACE');m=o.modifiers.new('Rigid original head frame','ARMATURE');m.object=rig;m.use_deform_preserve_volume=True
 if thickness:m=o.modifiers.new('Physical sheet edge','SOLIDIFY');m.thickness=thickness;m.offset=0
 bevel=o.modifiers.new('Worked edge rounding','BEVEL');bevel.width=.0007;bevel.segments=2
 parts.append({'name':name,'vertices':len(points),'faces':len(faces),'thickness_m':thickness});return o
def point(angle,height,extra=0):
 r=math.cos(height*math.pi/2);return Vector(((.111+extra)*r*math.sin(angle),-.095-(.142+extra)*r*math.cos(angle),1.963+.132*math.sin(height*math.pi/2)))
# Eight separately editable gores, touching at their manufactured seam boundaries.
for gore in range(8):
 p=[];f=[];nr=12;nc=8
 for r in range(nr+1):
  for c in range(nc+1):p.append(point((gore+c/nc)*math.tau/8,min(r/nr,.997)))
 for r in range(nr):
  for c in range(nc):a=r*(nc+1)+c;f.append((a,a+1,a+nc+2,a+nc+1))
 piece('Helmet dome gore '+str(gore),p,f,iron)
 # Narrow real raised join strip, not noisy paint pretending to be a seam.
 p=[];f=[]
 for r in range(nr+1):
  for delta in [-.012,.012]:p.append(point(gore*math.tau/8+delta,min(r/nr,.997),.0017))
 for r in range(nr):a=r*2;f.append((a,a+1,a+3,a+2))
 piece('Helmet gore seam '+str(gore),p,f,edge,.0012)
# Brow band and separate side/back neck guard, face left open.
p=[];f=[];n=96
for z in [1.947,1.975]:
 for i in range(n):a=i*math.tau/n;p.append((.114*math.sin(a),-.095-.145*math.cos(a),z))
for i in range(n):k=(i+1)%n;f.append((i,k,n+k,n+i))
piece('Helmet brow band',p,f,edge,.0025)
for label,lo,hi in [('left',.76,2.4),('back',2.4,3.88),('right',3.88,math.tau-.76)]:
 p=[];f=[];nc=20;nr=8
 for r in range(nr+1):
  t=r/nr
  for c in range(nc+1):
   a=lo+(hi-lo)*c/nc;bottom=1.77+.045*max(0,math.cos(a));p.append(((.114+.012*t)*math.sin(a),-.095-(.145+.015*t)*math.cos(a),1.962*(1-t)+bottom*t))
 for r in range(nr):
  for c in range(nc):a=r*(nc+1)+c;f.append((a,a+1,a+nc+2,a+nc+1))
 piece('Helmet articulated '+label+' guard',p,f,iron)
# Small formed crown cap, no giant knob or optional hero ornament.
p=[];f=[]
for z,r in [(2.090,.014),(2.104,.010),(2.108,.005)]:
 for i in range(16):a=i*math.tau/16;p.append((r*math.sin(a),-.095-r*math.cos(a),z))
for row in range(2):
 for i in range(16):k=(i+1)%16;a=row*16;f.append((a+i,a+k,a+16+k,a+16+i))
piece('Helmet crown fitting',p,f,edge)
bpy.ops.wm.save_as_mainfile(filepath=str(out/'helmet-kit-editable.blend'))
scene=bpy.context.scene;scene.use_nodes=False;scene.render.engine='CYCLES';scene.cycles.samples=24;scene.cycles.use_denoising=False;scene.view_layers[0].material_override=None
scene.world=bpy.data.worlds.new('Helmet full-actor review');scene.world.use_nodes=True;scene.world.node_tree.nodes['Background'].inputs['Strength'].default_value=.4
bpy.ops.object.light_add(type='AREA',location=(3,-4,5));bpy.context.object.data.energy=700;bpy.context.object.data.size=4
bpy.ops.object.camera_add(location=(2.7,-5,2.6));cam=bpy.context.object;cam.rotation_euler=(Vector((0,-.08,1.03))-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.type='ORTHO';cam.data.ortho_scale=2.5;scene.camera=cam;scene.render.resolution_x=960;scene.render.resolution_y=1200;scene.render.resolution_percentage=100;scene.render.filepath=str(out/'helmet-fullbody-BLENDER-NOT-GAME.png');bpy.ops.render.render(write_still=True)
(out/'report.json').write_text(json.dumps({'source_sha256':hashlib.sha256(src.read_bytes()).hexdigest(),'head_frame':bone,'art_pass':False,'game_tested':False,'parts':parts,'missing':['chin strap and plume','stance/grip','shoe and puttee conversion','full-motion clipping tests','owner accepted game image']},indent=2)+'\n')
