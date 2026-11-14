"""Original Guardian IK and finger controls on unified actor. Diagnostic, not accepted grip."""
import bpy,sys,pathlib,math,json,hashlib
from mathutils import Matrix,Vector
src,out=map(pathlib.Path,sys.argv[sys.argv.index('--')+1:][:2]);out.mkdir(parents=True,exist_ok=True)
bpy.ops.wm.open_mainfile(filepath=str(src),use_scripts=False,load_ui=False);rig=bpy.data.objects['rig'];axis=Vector((.5,0,.8660254));shaft_center=Vector((0,-.36,1.40))
rows=[]
for side,sign,t in [('L',1,.20),('R',-1,-.20)]:
 x=axis.copy();y=Vector((-.8660254*sign,0,.5*sign));z=x.cross(y).normalized()
 # Flip X with the hand, retaining right-handed frame and a shared shaft axis.
 if side=='R':x=-x;z=x.cross(y).normalized()
 desired=Matrix((x,y,z)).transposed().to_4x4();grip=shaft_center+axis*t;desired.translation=grip-y*.145+z*.035
 rig.pose.bones['hand_ik.'+side]['ik']=1.;rig.pose.bones['hand_ik.'+side].matrix=desired
 for stem in ['finger_index.','finger_middle.','finger_ring.','finger_pinky.']:
  b=rig.pose.bones.get(stem+side)
  if b:b.rotation_mode='XYZ';b.rotation_euler[0]=.3;b.scale[1]=.65
 b=rig.pose.bones['thumb.'+side];b.rotation_mode='XYZ';b.rotation_euler[0]=.5;b.scale[1]=.72
 bpy.context.view_layer.update()
 rows.append({'side':side,'desired_wrist':list(desired.translation),'actual_wrist':list(rig.pose.bones['DEF-hand.'+side].head),'wrist_error_m':(rig.pose.bones['DEF-hand.'+side].head-desired.translation).length,'target_grip':list(grip)})
def material(name,rgb,rough=.8,metal=0):
 m=bpy.data.materials.new(name);m.use_nodes=True;p=m.node_tree.nodes.get('Principled BSDF');p.inputs['Base Color'].default_value=(*rgb,1);p.inputs['Roughness'].default_value=rough;p.inputs['Metallic'].default_value=metal;return m
wood=material('Spear matte ash wood',(.22,.13,.07));iron=material('Spear forged iron',(.22,.24,.24),.6,.45)
a=shaft_center-axis*1.15;b=shaft_center+axis*1.48
bpy.ops.mesh.primitive_cylinder_add(vertices=16,radius=.014,depth=(b-a).length,location=(a+b)/2);shaft=bpy.context.object;shaft.name='SPEAR whole unbroken wood shaft no tassel';shaft.rotation_euler=(b-a).to_track_quat('Z','Y').to_euler();shaft.data.materials.append(wood)
# Leaf point with central ridge, complete shaft socket, no red tassel.
x=Vector((.8660254,0,-.5));y=Vector((0,1,0));p=[b-axis*.03-x*.025,b-axis*.03+x*.025,b+axis*.23,b+y*.009,b-y*.009];f=[(0,1,3),(1,2,3),(2,0,3),(1,0,4),(2,1,4),(0,2,4)];me=bpy.data.meshes.new('Spear editable leaf head');me.from_pydata(p,[],f);me.update();o=bpy.data.objects.new('SPEAR forged leaf point',me);bpy.context.collection.objects.link(o);me.materials.append(iron)
bpy.ops.wm.save_as_mainfile(filepath=str(out/'soldier-grip-editable.blend'))
for o in list(bpy.data.objects):
 if o.type in {'CAMERA','LIGHT'}:bpy.data.objects.remove(o,do_unlink=True)
scene=bpy.context.scene;scene.use_nodes=False;scene.render.engine='CYCLES';scene.cycles.samples=32;scene.cycles.use_denoising=False;scene.view_layers[0].material_override=None
scene.world=bpy.data.worlds.new('Grip matte review');scene.world.use_nodes=True;scene.world.node_tree.nodes['Background'].inputs['Strength'].default_value=.45
bpy.ops.object.light_add(type='AREA',location=(-3,-4,5));bpy.context.object.data.energy=650;bpy.context.object.data.size=5
bpy.ops.object.camera_add(location=(2.5,-5,3.2));cam=bpy.context.object;cam.rotation_euler=(Vector((0,-.1,1.1))-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.type='ORTHO';cam.data.ortho_scale=3.2;scene.camera=cam
scene.render.resolution_x=960;scene.render.resolution_y=1100;scene.render.resolution_percentage=100;scene.render.filepath=str(out/'whole-grip-BLENDER-NOT-GAME.png');bpy.ops.render.render(write_still=True)
(out/'report.json').write_text(json.dumps({'source_sha256':hashlib.sha256(src.read_bytes()).hexdigest(),'hand_controls':rows,'spear_length_m':2.86,'spear_tassel':False,'art_pass':False,'game_tested':False,'finger_contact_tested':False,'animations_complete':False},indent=2)+'\n')
