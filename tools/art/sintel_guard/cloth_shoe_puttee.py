"""Full source shoe/sole with a separate continuous, editable wrapped cloth pattern.
Original complete boot source is retained; this is a costume derivative, not history proof.
"""
import bpy,sys,pathlib,json,math,hashlib
from mathutils import Vector
from mathutils.bvhtree import BVHTree
src,out=map(pathlib.Path,sys.argv[sys.argv.index('--')+1:][:2]);out.mkdir(parents=True,exist_ok=True)
bpy.ops.wm.open_mainfile(filepath=str(src),use_scripts=False,load_ui=False);rig=bpy.data.objects['rig'];boot=bpy.data.objects['GEO-bootsLT.001']
def mat(name,c):
 m=bpy.data.materials.new(name);m.use_nodes=True;b=m.node_tree.nodes.get('Principled BSDF');b.inputs['Base Color'].default_value=(*c,1);b.inputs['Roughness'].default_value=.94;return m
foot=mat('Cloth shoe matte dark woven upper',(.075,.073,.064));wrap=mat('Puttee natural warm undyed cloth',(.42,.40,.33))
boot.data.materials.clear();boot.data.materials.append(foot);boot.data.materials.append(wrap)
# Retain the complete professional shoe/sole topology and UV. No alpha cuts.
# Classify actual posed original control face centers, not raw rest coordinates.
base_mods=[(m,m.show_viewport) for m in boot.modifiers if m.type=='MULTIRES']
for m,_ in base_mods:m.show_viewport=False
bpy.context.view_layer.update();e=boot.evaluated_get(bpy.context.evaluated_depsgraph_get());me=e.to_mesh();assert len(me.polygons)==len(boot.data.polygons)
for p,original in zip(me.polygons,boot.data.polygons):original.material_index=int((e.matrix_world@p.center).z>.16)
e.to_mesh_clear()
for m,state in base_mods:m.show_viewport=state
bpy.context.view_layer.update();e=boot.evaluated_get(bpy.context.evaluated_depsgraph_get());me=e.to_mesh();bvh=BVHTree.FromPolygons([e.matrix_world@v.co for v in me.vertices],[list(p.vertices) for p in me.polygons]);e.to_mesh_clear()
cage=next(m.object for m in boot.modifiers if m.type=='MESH_DEFORM');source_cage=cage;cage=cage.copy();cage.data=cage.data.copy();cage.name='DERIVED puttee complete envelope';bpy.context.collection.objects.link(cage)
for v in cage.data.vertices:v.co+=v.normal*.025
cage.hide_render=True;cage.hide_set(False)
records=[]
for sign,side in [(1,'L'),(-1,'R')]:
 pts=[];faces=[];uv=[];steps=360;cols=4
 for i in range(steps+1):
  t=i/steps;a=t*math.tau*9;z=.19+t*.34
  for j in range(cols+1):
   zz=z+(j/cols-.5)*.054;u=max(0,min(1,(zz-.15)/.44));center=Vector((sign*(.1843*(1-u)+.1529*u),-.0698*(1-u)-.0911*u,zz));n=Vector((math.cos(a),math.sin(a),0))
   hit=bvh.ray_cast(center+n*.13,-n)
   if hit[0] is None:raise RuntimeError('Missing original shin surface')
   pts.append(hit[0]+n*(.003+t*.0015));uv.append((t*9,j/cols))
 for i in range(steps):
  for j in range(cols):k=i*(cols+1)+j;faces.append((k,k+cols+1,k+cols+2,k+1))
 me=bpy.data.meshes.new('Continuous wound cloth strip '+side);me.from_pydata(pts,[],faces);me.update();o=bpy.data.objects.new('CLOTH continuous bound puttee '+side,me);bpy.context.collection.objects.link(o);me.materials.append(wrap);layer=me.uv_layers.new(name='UnrolledFabricPattern')
 for p in me.polygons:
  p.use_smooth=True
  for li in p.loop_indices:layer.data[li].uv=uv[me.loops[li].vertex_index]
 bpy.ops.object.select_all(action='DESELECT');o.select_set(True);bpy.context.view_layer.objects.active=o
 # Bind with the same evaluated neutral cage as the full source garment.
 bpy.context.view_layer.update();ce=cage.evaluated_get(bpy.context.evaluated_depsgraph_get());cm=ce.to_mesh();neutral=[v.co.copy() for v in cm.vertices];ce.to_mesh_clear();raw=cage.data;snapshot=raw.copy();cage.data=snapshot
 for v,p in zip(snapshot.vertices,neutral):v.co=p
 states=[(m,m.show_viewport,m.show_render) for m in cage.modifiers]
 for m,_,_ in states:m.show_viewport=False;m.show_render=False
 bpy.context.view_layer.update();md=o.modifiers.new('Full author cage for cloth winding','MESH_DEFORM');md.object=cage;md.precision=5;bpy.ops.object.meshdeform_bind(modifier=md.name)
 if not md.is_bound:raise RuntimeError('Puttee binding failed')
 cage.data=raw
 for m,v,r in states:m.show_viewport=v;m.show_render=r
 bpy.data.meshes.remove(snapshot);bpy.context.view_layer.update();sol=o.modifiers.new('Real cloth strip thickness','SOLIDIFY');sol.thickness=.0012;sol.offset=0
 records.append({'side':side,'vertices':len(pts),'faces':len(faces),'continuous_turns':9,'band_width_m':.054,'meshdeform_bound':md.is_bound})
cage.hide_set(True);bpy.ops.wm.save_as_mainfile(filepath=str(out/'whole-shoe-puttee-editable.blend'))
# Same full-body stress and camera as the previous complete clothing review.
for o in list(bpy.data.objects):
 if o.type in {'CAMERA','LIGHT'}:bpy.data.objects.remove(o,do_unlink=True)
s=bpy.context.scene;s.use_nodes=False;s.render.engine='CYCLES';s.cycles.samples=24;s.cycles.use_denoising=False;s.view_layers[0].material_override=None;s.world=bpy.data.worlds.new('Cloth and armor whole review');s.world.use_nodes=True;s.world.node_tree.nodes['Background'].inputs['Strength'].default_value=.45
bpy.ops.object.light_add(type='AREA',location=(-3,-4,5));bpy.context.object.data.energy=650;bpy.context.object.data.size=5
bpy.ops.object.camera_add(location=(2.5,-5,3.2));cam=bpy.context.object;cam.rotation_euler=(Vector((0,-.08,1.05))-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.type='ORTHO';cam.data.ortho_scale=2.7;s.camera=cam;s.render.resolution_x=960;s.render.resolution_y=1100;s.render.resolution_percentage=100
for side,sign in [('L',1),('R',-1)]:
 rig.pose.bones['hand_ik.'+side]['ik']=0.
 for stem,ang in [('upper_arm.',-.95*sign),('forearm.',.75*sign)]:b=rig.pose.bones[stem+side];b.rotation_mode='XYZ';b.rotation_euler[2]=ang
bpy.context.view_layer.update();s.render.filepath=str(out/'whole-BLENDER-NOT-GODOT.png');bpy.ops.render.render(write_still=True)
(out/'report.json').write_text(json.dumps({'source_sha256':hashlib.sha256(src.read_bytes()).hexdigest(),'retained_original_boot_topology_uv':True,'derived_material_regions':True,'new_complete_wrapped_cloth':records,'art_pass':False,'game_tested':False,'foot_contact_pass':False},indent=2)+'\n')
