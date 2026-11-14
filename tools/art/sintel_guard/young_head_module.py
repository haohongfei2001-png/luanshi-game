"""Full native MakeHuman face module on the independent Guardian garment oracle.
Keeps every source face weight and all 163 MH bones. No compressed old rig.
"""
import bpy,bmesh,sys,pathlib,json,hashlib
from mathutils import Matrix,Vector
src,mhsrc,out=map(pathlib.Path,sys.argv[sys.argv.index('--')+1:][:3]);out.mkdir(parents=True,exist_ok=True)
bpy.ops.wm.open_mainfile(filepath=str(src),load_ui=False,use_scripts=False);bodyrig=bpy.data.objects['rig']
with bpy.data.libraries.load(str(mhsrc),link=False) as (a,b):b.objects=['MH163','Body_SourceFull','Eyes','eyebrow001','eyelashes01']
loaded=b.objects
for o in loaded:
 if o and o.name not in bpy.context.scene.objects:bpy.context.collection.objects.link(o)
r=next(o for o in loaded if o.type=='ARMATURE');r.animation_data_clear()
sourcebody=next(o for o in loaded if o.name.startswith('Body_SourceFull'));head=sourcebody.copy();head.data=sourcebody.data.copy();head.name='Young complete author face module';head.hide_render=False;head.hide_set(False);bpy.context.collection.objects.link(head)
sourcebody.hide_render=True;sourcebody.hide_set(True)
headbone=r.data.bones['head'];names={headbone.name,'neck02','neck03'}|{b.name for b in headbone.children_recursive};groups={g.index:g.name for g in head.vertex_groups}
keep={v.index for v in head.data.vertices if sum(g.weight for g in v.groups if groups[g.group] in names)>.5}
bm=bmesh.new();bm.from_mesh(head.data);bm.verts.ensure_lookup_table();bmesh.ops.delete(bm,geom=[v for v in bm.verts if v.index not in keep],context='VERTS');bm.to_mesh(head.data);bm.free()
# Whole-head rig/object transform, leaving the source vertex groups/UV/rest bones intact.
root=bpy.data.objects.new('Full MH face module attachment',None);bpy.context.collection.objects.link(root)
for o in loaded+[head]:
 if o is sourcebody:continue
 if o.parent not in loaded:
  world=o.matrix_world.copy();o.parent=root;o.matrix_world=world
# Keep a source copy of the FULL body out of the rendered scene, not a lost master.
scale=1.18;root.matrix_world=Matrix.Translation((0,-.055,.130))@Matrix.Scale(scale,4)
bpy.context.view_layer.update();c=root.constraints.new('CHILD_OF');c.name='Original body head motion, full face rig kept';c.target=bodyrig;c.subtarget='DEF-neck.03';c.inverse_matrix=(bodyrig.matrix_world@bodyrig.pose.bones['DEF-neck.03'].matrix).inverted()
# Remove only old rendered source identity parts in this separate derivative.
removed=[]
for name in ['GEO-headLT','GEO-headLT.002','GEO-headLT.003','GEO-cornea','GEO-cornea.001','GEO-eyeballs_new','GEO-eyeballs_new.001','GEO-body_mouth.003']:
 o=bpy.data.objects.get(name)
 if o:removed.append(name);bpy.data.objects.remove(o,do_unlink=True)
bpy.ops.wm.save_as_mainfile(filepath=str(out/'young-face-kit-editable.blend'))
scene=bpy.context.scene;scene.use_nodes=False;scene.render.engine='CYCLES';scene.cycles.samples=24;scene.cycles.use_denoising=False;scene.view_layers[0].material_override=None
scene.world=bpy.data.worlds.new('Young head module review');scene.world.use_nodes=True;scene.world.node_tree.nodes['Background'].inputs['Strength'].default_value=.4
bpy.ops.object.light_add(type='AREA',location=(3,-4,5));bpy.context.object.data.energy=700;bpy.context.object.data.size=4
bpy.ops.object.camera_add(location=(2.7,-5,2.6));cam=bpy.context.object;cam.rotation_euler=(Vector((0,-.08,1.03))-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.type='ORTHO';cam.data.ortho_scale=2.5;scene.camera=cam;scene.render.resolution_x=960;scene.render.resolution_y=1200;scene.render.resolution_percentage=100;scene.render.filepath=str(out/'young-module-fullbody-BLENDER-NOT-GAME.png');bpy.ops.render.render(write_still=True)
(out/'report.json').write_text(json.dumps({'body_source_sha256':hashlib.sha256(src.read_bytes()).hexdigest(),'mh_source_sha256':hashlib.sha256(mhsrc.read_bytes()).hexdigest(),'head_vertices':len(head.data.vertices),'head_faces':len(head.data.polygons),'face_rig_bones':len(r.data.bones),'body_rig_bones':len(bodyrig.data.bones),'full_weight_max':max(len(v.groups) for v in head.data.vertices),'removed_old_identity_objects':removed,'art_pass':False,'game_tested':False,'new_character_identity':False,'limitations':['Head/body seam and movement not yet verified','Full MH face rig increases total source bones to 471','No reduction of face influences is authorized by this construction']},indent=2)+'\n')
