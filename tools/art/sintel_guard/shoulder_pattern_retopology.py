"""Independent whole shoulder patterns with rigid source-frame articulation.
No sleeve projection or source-cloth stretch is used to define hard plates.
"""
import bpy,sys,pathlib,math,json,hashlib
from mathutils import Vector,Matrix
src,out=map(pathlib.Path,sys.argv[sys.argv.index('--')+1:][:2]);out.mkdir(parents=True,exist_ok=True);bpy.ops.wm.open_mainfile(filepath=str(src),use_scripts=False,load_ui=False);rig=bpy.data.objects['rig']
removed=[]
for o in list(bpy.data.objects):
 if o.name.startswith('REBUILD ') and 'shoulder' in o.name:removed.append(o.name);bpy.data.objects.remove(o,do_unlink=True)
def material(name,c):
 m=bpy.data.materials.new(name);m.use_nodes=True;p=m.node_tree.nodes.get('Principled BSDF');p.inputs['Base Color'].default_value=(*c,1);p.inputs['Roughness'].default_value=.88;p.inputs['Metallic'].default_value=.25;return m
iron=material('Whole shoulder matte worked iron',(.105,.125,.13));lining=material('Whole shoulder dark textile edge',(.12,.06,.037));lining.node_tree.nodes.get('Principled BSDF').inputs['Metallic'].default_value=0;records=[]
def patch(name,net,bone,material,window=(0,1,0,1),lift=0):
 # Tensor cubic pattern with four purposeful cross sections, not a tube/loft.
 n=12;v=[];f=[]
 def B(t):return [(1-t)**3,3*t*(1-t)**2,3*t*t*(1-t),t**3]
 for i in range(n+1):
  u=window[0]+(window[1]-window[0])*i/n;a=B(u)
  for j in range(n+1):
   w=window[2]+(window[3]-window[2])*j/n;b=B(w);p=sum((net[x][y]*a[x]*b[y] for x in range(4) for y in range(4)),Vector())
   if lift:
    eps=.0001;aa=B(u+eps);bb=B(w+eps)
    pu=sum((net[x][y]*aa[x]*b[y] for x in range(4) for y in range(4)),Vector());pv=sum((net[x][y]*a[x]*bb[y] for x in range(4) for y in range(4)),Vector());normal=(pu-p).cross(pv-p).normalized()
    if normal.z<0:normal=-normal
    p+=normal*lift
   v.append(p)
 for i in range(n):
  for j in range(n):k=i*(n+1)+j;f.append((k,k+1,k+n+2,k+n+1))
 transform=rig.matrix_world@rig.pose.bones[bone].matrix@rig.data.bones[bone].matrix_local.inverted()@rig.matrix_world.inverted();inverse=transform.inverted();me=bpy.data.meshes.new(name);me.from_pydata([inverse@p for p in v],[],f);me.update();o=bpy.data.objects.new(name,me);bpy.context.collection.objects.link(o);me.materials.append(material);uv=me.uv_layers.new(name='WholeShoulderPatternUV')
 for face in me.polygons:
  face.use_smooth=True
  for li in face.loop_indices:k=me.loops[li].vertex_index;uv.data[li].uv=(k//(n+1)/n,k%(n+1)/n)
 g=o.vertex_groups.new(name=bone);g.add(list(range(len(v))),1,'REPLACE');a=o.modifiers.new('Rigid full source joint frame, no stretched blend','ARMATURE');a.object=rig;sol=o.modifiers.new('Real formed plate thickness','SOLIDIFY');sol.thickness=.003;sol.offset=0;bev=o.modifiers.new('Rolled nonsharp edge','BEVEL');bev.width=.0015;bev.segments=2
 records.append({'name':name,'bone':bone,'vertices':len(v),'faces':len(f),'single_rigid_influence':True});return o
for side,sign in [('L',1),('R',-1)]:
 shoulder=rig.matrix_world@rig.pose.bones['DEF-upper_arm.'+side+'.01'].head
 # Whole front-to-back bearing strap connects the cuirass to the cap region.
 # It is a distinct editable pattern, with clearance under the rigid crown.
 strap=[[Vector((sign*(.14+.15*i/3),[-.205,-.075,.035,.115][j],[1.715,1.795,1.795,1.715][j]-.018*i)) for j in range(4)] for i in range(4)]
 patch('PATTERN complete chest shoulder back bearing '+side,strap,'DEF-spine.04',lining)
 for r in range(3):
  for c in range(5):patch(f'PATTERN bearing lamella {side} {r} {c}',strap,'DEF-spine.04',iron,(r/3+.015,(r+1)/3-.015,c/5+.005,min(1,(c+1)/5+.015)),.004+c*.0005)
 # Neck/shoulder bridge, crown and outer hanging edge are separate landmarks.
 # Four front-to-back stations; inner edge clears neck, outer edge clears axilla.
 xs=[-.040,-.010,.055,.105];zs=[.035,.090,.070,-.015];ys=[-.105,-.050,.050,.100]
 net=[[shoulder+Vector((sign*xs[i],ys[j],zs[i]+([-.025,.012,.012,-.025][j]))) for j in range(4)] for i in range(4)]
 patch('PATTERN whole shoulder crown '+side,net,'DEF-spine.04',lining)
 for r in range(3):
  for c in range(3):patch(f'PATTERN crown lamella {side} {r} {c}',net,'DEF-spine.04',iron,(r/3+.01,min(1,(r+1)/3+.02),c/3+.01,(c+1)/3-.01),.004+r*.001)
 # One lower articulated leaf moves rigidly with the original upper arm.
 # Explicit overlap/clearance is a candidate to inspect, not contact acceptance.
 xs=[.050,.085,.110,.115];zs=[.050,.005,-.030,-.070];ys=[-.100,-.050,.050,.095]
 net=[[shoulder+Vector((sign*xs[i],ys[j],zs[i]+([-.025,.015,.015,-.025][j]))) for j in range(4)] for i in range(4)]
 patch('PATTERN articulated shoulder leaf '+side,net,'DEF-upper_arm.'+side+'.01',iron)
bpy.ops.wm.save_as_mainfile(filepath=str(out/'whole-shoulder-pattern.blend'))
for o in list(bpy.data.objects):
 if o.type in {'CAMERA','LIGHT'}:bpy.data.objects.remove(o,do_unlink=True)
s=bpy.context.scene;s.use_nodes=False;s.render.engine='CYCLES';s.cycles.samples=24;s.cycles.use_denoising=False;s.view_layers[0].material_override=None;s.world=bpy.data.worlds.new('Independent shoulder pattern review');s.world.use_nodes=True;s.world.node_tree.nodes['Background'].inputs['Strength'].default_value=.45
bpy.ops.object.light_add(type='AREA',location=(-3,-4,5));bpy.context.object.data.energy=650;bpy.context.object.data.size=5
bpy.ops.object.camera_add(location=(2.5,-5,3.2));cam=bpy.context.object;cam.rotation_euler=(Vector((0,-.08,1.05))-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.type='ORTHO';cam.data.ortho_scale=2.7;s.camera=cam;s.render.resolution_x=960;s.render.resolution_y=1100;s.render.resolution_percentage=100
for variant in ['source','raised']:
 if variant=='raised':
  for side,sign in [('L',1),('R',-1)]:
   rig.pose.bones['hand_ik.'+side]['ik']=0.
   for stem,ang in [('upper_arm.',-.95*sign),('forearm.',.75*sign)]:b=rig.pose.bones[stem+side];b.rotation_mode='XYZ';b.rotation_euler[2]=ang
 bpy.context.view_layer.update();s.render.filepath=str(out/(variant+'-whole-BLENDER-NOT-GODOT.png'));bpy.ops.render.render(write_still=True)
(out/'report.json').write_text(json.dumps({'source_sha256':hashlib.sha256(src.read_bytes()).hexdigest(),'removed_old_shoulders':removed,'parts':records,'art_pass':False,'game_tested':False,'rigid_articulation_contact_tested':False},indent=2)+'\n')
