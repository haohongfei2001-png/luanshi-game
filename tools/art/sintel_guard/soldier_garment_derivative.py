"""Editable full-garment tailoring study. NOT a completed historic soldier.
Original CC BY 3 Guardian source is read-only. No source rig/cage reductions.
"""
import bpy,sys,pathlib,json,hashlib,math,struct
from mathutils import Vector
from mathutils.bvhtree import BVHTree
src,out=map(pathlib.Path,sys.argv[sys.argv.index('--')+1:][:2]);out.mkdir(parents=True,exist_ok=True)
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
before=sha(src);bpy.ops.wm.open_mainfile(filepath=str(src),load_ui=False,use_scripts=False)
rig=bpy.data.objects['rig'];cage=bpy.data.objects['GEO-deformation_cage'];top=bpy.data.objects['GEO-topLT']
report={'source_sha256':before,'default_enabled':False,'historic_validation':False,'godot_run':False,'removed_derivative_objects':[],'source_rig_bones':len(rig.data.bones),'source_cage_vertices':len(cage.data.vertices),'limitations':['Original film face remains and is rejected as final identity.','This is a tailoring study, not a completed late Tang uniform.','No spear pose or grip has been authored.','Modern simple materials are not original Blender Internal equivalents.']}
# Remove actual derivative geometry, not transparent masks or material hiding.
for name in ['GEO-torso-beltsLT.001','GEO-symbolLT.001','GEO-symbolJA.005','GEO-symbolJA.006','GEO-toplaceLT.001','GEO-belt2JA.003','GEO-pant_detailsL_S','GEO-pant_detailsR_S','GEO-hoodLT','GEO-capeLT.001','GEO-headLT.002','GEO-headLT.003']:
 ob=bpy.data.objects.get(name)
 if ob:report['removed_derivative_objects'].append({'name':name,'vertices':len(ob.data.vertices)});bpy.data.objects.remove(ob,do_unlink=True)
# Retain original connected sleeve/shoulder topology and Multires sculpt.
# Extend the actual original hem below the waist, rather than add a rod skirt.
changed=[]
for v in top.data.vertices:
 world=top.matrix_world@v.co
 t=max(0,min(1,(1.39-world.z)/.19));d=.18*t*t*(3-2*t)
 if d:
  v.co.z-=d;v.co.x*=1+.06*t;changed.append(v.index)
report['top_tailoring']={'extended_hem_metres':.18,'changed_base_vertices':changed,'original_vertex_count':len(top.data.vertices),'original_uv_layers':[x.name for x in top.data.uv_layers],'multires_levels':[m.total_levels for m in top.modifiers if m.type=='MULTIRES']}
# Tailor the whole source waist wrap outwards for the extended blouse envelope.
sash=bpy.data.objects['GEO-sashDG.001']
for v in sash.data.vertices:
 w=sash.matrix_world@v.co;w.x*=1.08;w.y=-.1+(w.y+.1)*1.14;v.co=sash.matrix_world.inverted()@w
report['waist_wrap_fit']={'x_scale':1.08,'depth_scale':1.14,'depth_center_m':-.1,'whole_source_topology_retained':True}
bpy.context.view_layer.update();dg=bpy.context.evaluated_depsgraph_get();ev=top.evaluated_get(dg);me=ev.to_mesh()
p=[ev.matrix_world@v.co for v in me.vertices];polys=[list(f.vertices) for f in me.polygons];bvh=BVHTree.FromPolygons(p,polys);ev.to_mesh_clear()
def mat(name,c,rough=.85):
 m=bpy.data.materials.new(name);m.use_nodes=True;n=m.node_tree.nodes.get('Principled BSDF');n.inputs['Base Color'].default_value=(*c,1);n.inputs['Roughness'].default_value=rough;return m
cloth=mat('DERIVED indigo wool linen',(.055,.105,.145));trim=mat('DERIVED collar facing',(.115,.16,.18));pants=mat('DERIVED unbleached trousers',(.27,.255,.22));leather=mat('DERIVED plain leather',(.085,.047,.027));skin=mat('DERIVED provisional skin',(.44,.265,.17),.65)
# These are explicit new diffuse-only materials, not the old layered skin graph.
def diffuse_material(name,file,rough):
 m=mat(name,(1,1,1),rough);n=m.node_tree.nodes.new('ShaderNodeTexImage');n.image=bpy.data.images.load(str(src.parent/'textures'/file),check_existing=True);m.node_tree.links.new(n.outputs['Color'],m.node_tree.nodes.get('Principled BSDF').inputs['Base Color']);return m
face=diffuse_material('DERIVED source face diffuse only','lao_face_diff.png',.72)
eye=diffuse_material('DERIVED original eye diffuse','sintel_eyeball_colour.png',.25)

for ob in bpy.context.scene.objects:
 if ob.type!='MESH' or ob==cage:continue
 material=cloth if ob.name=='GEO-topLT' else pants if 'pantsLT' in ob.name else trim if 'sash' in ob.name else leather if 'boots' in ob.name or 'gauntlets' in ob.name else skin
 if ob.name=='GEO-headLT':material=face
 if ob.name.startswith('GEO-eyeballs'):material=eye
 if ob.name.startswith('GEO-cornea'):continue
 ob.data.materials.clear();ob.data.materials.append(material)
 for f in ob.data.polygons:f.material_index=0
# Explicit garment front pattern, sampled against the WHOLE professional top,
# not against anatomy; independent UVs, thickness, seam allowance and cage bind.
def front_y(x,z):
 hit=bvh.ray_cast(Vector((x,-1,z)),Vector((0,1,0)))
 if hit[0] is None:raise RuntimeError('Pattern leaves garment support '+str((x,z)))
 return hit[0].y-.012

def patch(name,left_top,right_top,left_bottom,right_bottom,nu,nv,material):
 verts=[];faces=[]
 for j in range(nv+1):
  v=j/nv;l=Vector(left_top).lerp(Vector(left_bottom),v);r=Vector(right_top).lerp(Vector(right_bottom),v)
  for i in range(nu+1):
   x,z=l.lerp(r,i/nu);verts.append((x,front_y(x,z),z))
 for j in range(nv):
  for i in range(nu):a=j*(nu+1)+i;faces.append((a,a+1,a+nu+2,a+nu+1))
 mesh=bpy.data.meshes.new(name);mesh.from_pydata(verts,[],faces);mesh.update();uv=mesh.uv_layers.new(name='TailoringUV')
 for f in mesh.polygons:
  for li in f.loop_indices:
   k=mesh.loops[li].vertex_index;uv.data[li].uv=(k%(nu+1)/nu,k//(nu+1)/nv)
 ob=bpy.data.objects.new(name,mesh);bpy.context.collection.objects.link(ob);mesh.materials.append(material)
 for f in mesh.polygons:f.use_smooth=True
 bpy.ops.object.select_all(action='DESELECT');ob.select_set(True);bpy.context.view_layer.objects.active=ob
 bind=ob.modifiers.new('Full original cage attachment','MESH_DEFORM');bind.object=cage;bind.precision=5
 bpy.ops.object.meshdeform_bind(modifier=bind.name);assert bind.is_bound
 sub=ob.modifiers.new('Tailored cloth surface','SUBSURF');sub.levels=2;sub.render_levels=2
 solid=ob.modifiers.new('Real cloth turned edge','SOLIDIFY');solid.thickness=.0025;solid.offset=0
 report.setdefault('new_pattern_pieces',[]).append({'name':name,'vertices':len(verts),'quads':len(faces),'full_original_cage_bound':bind.is_bound,'thickness_m':solid.thickness})
 return ob
# Left-over-right diagonal front edge; historical accuracy still requires review.
patch('TAILORED full overlapping front',(-.15,1.65),(-.08,1.736),(-.158,1.24),(.145,1.29),20,28,cloth)
patch('TAILORED broad diagonal facing',(-.08,1.736),(-.049,1.746),(.145,1.29),(.165,1.32),4,32,trim)
# Hash actual derived geometry/binding identities. Source H is never relabelled.
def geometry_hash(ob):
 h=hashlib.sha256()
 for v in ob.data.vertices:h.update(struct.pack('<3f',*v.co))
 for f in ob.data.polygons:h.update(struct.pack('<I',len(f.vertices)));h.update(struct.pack('<'+'I'*len(f.vertices),*f.vertices))
 for uv in ob.data.uv_layers:
  h.update(uv.name.encode())
  for v in uv.data:h.update(struct.pack('<2f',*v.uv))
 return h.hexdigest()
report['derived_geometry']=[{'name':ob.name,'vertices':len(ob.data.vertices),'faces':len(ob.data.polygons),'positions_topology_uv_sha256':geometry_hash(ob),'reuse_original_H':False} for ob in [top,cage,sash]+[o for o in bpy.context.scene.objects if o.name.startswith('TAILORED')]]
report['rig_pose_oracle']='Full unchanged rig controls/constraints in independent blend; recompute cloth responses from this exact derivative, not original H.'
# Save an editable derivative before diagnostic-only lighting and cameras.
assert len(rig.data.bones)==308 and len(cage.data.vertices)==566
bpy.ops.wm.save_as_mainfile(filepath=str(out/'soldier-tailoring-study.blend'))
scene=bpy.context.scene;scene.use_nodes=False;scene.render.engine='CYCLES';scene.cycles.samples=16;scene.cycles.use_denoising=False
scene.world=bpy.data.worlds.new('Tailoring review world');scene.world.use_nodes=True;scene.world.node_tree.nodes['Background'].inputs['Strength'].default_value=.35
bpy.ops.object.light_add(type='AREA',location=(3,-4,5));bpy.context.object.data.energy=650;bpy.context.object.data.size=4
bpy.ops.object.camera_add(location=(2.7,-5,2.6));cam=bpy.context.object;cam.rotation_euler=(Vector((0,-.08,1.03))-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.type='ORTHO';cam.data.ortho_scale=2.5;scene.camera=cam
scene.render.resolution_x=960;scene.render.resolution_y=1200;scene.render.resolution_percentage=100;scene.render.filepath=str(out/'tailoring-fullbody-blender-not-game.png');bpy.ops.render.render(write_still=True)
assert sha(src)==before;report['source_unchanged']=True;(out/'report.json').write_text(json.dumps(report,indent=2)+'\n')
