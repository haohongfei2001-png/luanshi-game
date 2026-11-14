"""Independent bounded native three-joint finger fit; no mesh/bone scale edits."""
import bpy,sys,pathlib,math,json,numpy as np
from mathutils import Vector
src,out=map(pathlib.Path,sys.argv[sys.argv.index('--')+1:][:2]);out.mkdir(parents=True,exist_ok=True)
bpy.ops.wm.open_mainfile(filepath=str(src),use_scripts=False,load_ui=False);rig=bpy.data.objects['rig'];axis=Vector((.5,0,.8660254));center=Vector((0,-.36,1.40));rows=[]
def radial(p):
 q=p-center;return (q-axis*q.dot(axis)).length
for side in ['L','R']:
 for stem in ['finger_index','finger_middle','finger_ring','finger_pinky','thumb']:
  master=rig.pose.bones[stem+'.'+side];master.scale=(1,1,1)
  joints=[rig.pose.bones[f'{stem}.{i:02d}.{side}'] for i in [1,2,3]]
  for b in joints:b.rotation_mode='XYZ';b.rotation_euler=(0,0,0)
  x=[.30,1.1,.7] if stem!='thumb' else [.0,.6,.7]
  def evaluate(v):
   for b,a in zip(joints,v):b.rotation_euler.x=a
   bpy.context.view_layer.update()
   # Match actual centerline to outside cylinder; tip and distal segment should wrap, not float.
   vals=[]
   for i,b in enumerate(joints):
    for t in [.25,.5,.75,1.]:
     p=b.head.lerp(b.tail,t);r=radial(p);desired=.022 if stem!='thumb' else .025
     vals.append((r-desired)**2*(1 if i else .15)+max(0,.020-r)**2*8)
   return sum(vals)+.00001*sum((a-ref)**2 for a,ref in zip(v,[.2,1.1,.7]))
  score=evaluate(x)
  for step in [.35,.18,.08,.035]:
   for _ in range(5):
    changed=False
    for j in range(3):
     for delta in [-step,step]:
      v=x.copy();v[j]=max(-.2,min(1.8,v[j]+delta));s=evaluate(v)
      if s<score:x,score=v,s;changed=True
    if not changed:break
  evaluate(x);rows.append({'side':side,'finger':stem,'native_joint_x_radians':x,'centerline_objective':score,'scale_preserved':[list(b.scale) for b in joints]})
bpy.ops.wm.save_as_mainfile(filepath=str(out/'joint-grip.blend'))
(out/'joint-fit.json').write_text(json.dumps({'art_pass':False,'method':'independent native joint rotations, original masters neutral scale1; no hand/body/wrist move; centerline fit is not surface contact acceptance','fingers':rows},indent=2)+'\n')
for o in list(bpy.data.objects):
 if o.type in {'CAMERA','LIGHT'}:bpy.data.objects.remove(o,do_unlink=True)
scene=bpy.context.scene;scene.use_nodes=False;scene.render.engine='CYCLES';scene.cycles.samples=24;scene.cycles.use_denoising=False;scene.view_layers[0].material_override=None
scene.world=bpy.data.worlds.new('Joint grip review');scene.world.use_nodes=True;scene.world.node_tree.nodes['Background'].inputs['Strength'].default_value=.45
bpy.ops.object.light_add(type='AREA',location=(-3,-4,5));bpy.context.object.data.energy=650;bpy.context.object.data.size=5
bpy.ops.object.camera_add(location=(2.5,-5,3.2));cam=bpy.context.object;cam.rotation_euler=(Vector((0,-.1,1.1))-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.type='ORTHO';cam.data.ortho_scale=3.2;scene.camera=cam
scene.render.resolution_x=960;scene.render.resolution_y=1100;scene.render.resolution_percentage=100;scene.render.filepath=str(out/'whole-BLENDER.png');bpy.ops.render.render(write_still=True)
