"""Integrate a separately sewn source garment; retain its exact bound author cage."""
import bpy,sys,pathlib,json,hashlib
from mathutils import Vector
body,garment,out=map(pathlib.Path,sys.argv[sys.argv.index('--')+1:][:3]);out.mkdir(parents=True,exist_ok=True)
bpy.ops.wm.open_mainfile(filepath=str(body),use_scripts=False,load_ui=False);rig=bpy.data.objects['rig'];old=bpy.data.objects['GEO-topLT-recut'];bpy.data.objects.remove(old,do_unlink=True)
with bpy.data.libraries.load(str(garment),link=False) as (source,target):target.objects=['GEO-topLT-recut']
coat=target.objects[0];bpy.context.collection.objects.link(coat)
for m in coat.modifiers:
 if m.type=='MESH_DEFORM':
  cage=m.object
  if not cage.name in bpy.context.scene.objects:bpy.context.collection.objects.link(cage)
  cage.hide_render=True;cage.hide_set(True)
  for cm in cage.modifiers:
   if cm.type=='ARMATURE':cm.object=rig
for mat in coat.data.materials:
 if mat and mat.use_nodes:
  bs=mat.node_tree.nodes.get('Principled BSDF')
  if bs and 'facing' not in mat.name:bs.inputs['Base Color'].default_value=(.50,.46,.37,1);bs.inputs['Roughness'].default_value=.93
# Remove source leather gauntlets rather than pretending them to be cloth sleeves.
# Any exposed actual seam/gap remains visible for assessment, never alpha-masked.
removed=[]
for o in list(bpy.context.scene.objects):
 if o.type=='MESH' and 'gauntlet' in o.name.lower():removed.append(o.name);bpy.data.objects.remove(o,do_unlink=True)
bpy.context.view_layer.update();bpy.ops.wm.save_as_mainfile(filepath=str(out/'whole-garment-editable.blend'))
for o in list(bpy.data.objects):
 if o.type in {'CAMERA','LIGHT'}:bpy.data.objects.remove(o,do_unlink=True)
s=bpy.context.scene;s.use_nodes=False;s.render.engine='CYCLES';s.cycles.samples=24;s.cycles.use_denoising=False;s.view_layers[0].material_override=None
s.world=bpy.data.worlds.new('Whole assembly review');s.world.use_nodes=True;s.world.node_tree.nodes['Background'].inputs['Strength'].default_value=.45
bpy.ops.object.light_add(type='AREA',location=(-3,-4,5));bpy.context.object.data.energy=650;bpy.context.object.data.size=5
bpy.ops.object.camera_add(location=(2.5,-5,3.2));cam=bpy.context.object;cam.rotation_euler=(Vector((0,-.08,1.05))-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.type='ORTHO';cam.data.ortho_scale=2.7;s.camera=cam
s.render.resolution_x=960;s.render.resolution_y=1100;s.render.resolution_percentage=100
for side,sign in [('L',1),('R',-1)]:
 rig.pose.bones['hand_ik.'+side]['ik']=0.
 for stem,ang in [('upper_arm.',-.95*sign),('forearm.',.75*sign)]:
  b=rig.pose.bones[stem+side];b.rotation_mode='XYZ';b.rotation_euler[2]=ang
bpy.context.view_layer.update();s.render.filepath=str(out/'whole-BLENDER-NOT-GODOT.png');bpy.ops.render.render(write_still=True)
(out/'report.json').write_text(json.dumps({'body_sha256':hashlib.sha256(body.read_bytes()).hexdigest(),'garment_sha256':hashlib.sha256(garment.read_bytes()).hexdigest(),'removed_gauntlets':removed,'art_pass':False,'game_tested':False,'source_cloth_cage_preserved':True},indent=2)+'\n')
