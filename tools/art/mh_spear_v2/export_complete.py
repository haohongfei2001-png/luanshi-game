"""Export isolated complete MH military derivative as a real skinned GLB.
Editable input is never changed. Explicit top-8 skin approximation is measured.
"""
import bpy,sys,pathlib,json,hashlib,struct,os
src,out=map(pathlib.Path,sys.argv[sys.argv.index('--')+1:]);out.mkdir(parents=True,exist_ok=True)
if os.environ.get('LUANSHI_USE_LOADED_SCENE')!='1':bpy.ops.wm.open_mainfile(filepath=str(src),use_scripts=False,load_ui=False)
rig=bpy.data.objects['MH163'];rig.data.pose_position='POSE'
bpy.context.scene.render.fps=120;bpy.context.scene.render.fps_base=1
rig.animation_data_create();rig.animation_data.action=bpy.data.actions.get('Idle_Loop');bpy.context.scene.frame_set(1)
assert all(n in bpy.data.actions for n in ['Idle_Loop','Walk_Loop','Hit_Chest','Death01']), 'Missing actual full-body actions'
# Normalize hidden source parents too: exporter builds full scene tree before selection.
for obj in bpy.context.scene.objects:
 if obj.type=='MESH' and any(m.type=='ARMATURE' and m.object==rig for m in obj.modifiers):
  world=obj.matrix_world.copy();obj.parent=rig;obj.matrix_world=world
sampler_evidence=[]
for material in bpy.data.materials:
 if not material.use_nodes:continue
 groups={}
 for node in material.node_tree.nodes:
  if node.type=='TEX_IMAGE' and node.image:
   groups.setdefault(node.image.name,[]).append({'node':node.name,'interpolation':node.interpolation,'extension':node.extension,'projection':node.projection})
 for image,entries in groups.items():
  if len(entries)>1:sampler_evidence.append({'material':material.name,'image':image,'sampler_settings_equal':len({(x['interpolation'],x['extension'],x['projection']) for x in entries})==1,'nodes':entries})
render=[o for o in bpy.context.scene.objects if o.type=='MESH' and not o.hide_render]
# Source boundary: do not accidentally export the hidden robe or high source.
assert all(o.name not in ('Cross-front robe','V2_complete_coat_fit','Body_AuthorGarmentOcclusion') for o in render)
max_loss=0.;affected=0;vertices=0
for o in render:
 o.parent=rig
 # Triangulate evaluated ngons before tangent generation; editable mother is unchanged.
 if not any(m.name=='RuntimeNormalTangentTriangulation' for m in o.modifiers):o.modifiers.new('RuntimeNormalTangentTriangulation','TRIANGULATE')
 for v in o.data.vertices:
  gs=sorted([(g.group,g.weight) for g in v.groups if g.weight>0],key=lambda q:-q[1]);vertices+=1
  if len(gs)>8:
   loss=sum(w for _,w in gs[8:]);max_loss=max(max_loss,loss);affected+=1
   for idx,w in gs[8:]:o.vertex_groups[idx].remove([v.index])
  total=sum(w for _,w in gs[:8])
  if total:
   for idx,w in gs[:8]:o.vertex_groups[idx].add([v.index],w/total,'REPLACE')
# Use only chosen real render objects, never hidden source mesh duplication.
bpy.ops.object.select_all(action='DESELECT');rig.hide_set(False);rig.select_set(True)
for o in render:o.hide_set(False);o.select_set(True)
bpy.context.view_layer.objects.active=rig
bpy.ops.export_scene.gltf(filepath=str(out/'spearman-v2-wip.glb'),export_format='GLB',use_selection=True,export_apply=True,export_animations=True,export_animation_mode='ACTIONS',export_skins=True,export_all_influences=True,export_tangents=True,export_materials='EXPORT',export_yup=True)
report={'source_sha256':hashlib.sha256(src.read_bytes()).hexdigest(),'glb_sha256':hashlib.sha256((out/'spearman-v2-wip.glb').read_bytes()).hexdigest(),'render_objects':[o.name for o in render],'source_animation_fps':120,'expected_action_durations_s':{a.name:(a.frame_range[1]-a.frame_range[0])/120 for a in bpy.data.actions},'source_bones':len(rig.data.bones),'actions_in_source':[a.name for a in bpy.data.actions],'skin_top8_affected_vertices':affected,'skin_top8_max_discarded_weight':max_loss,'vertices_before_export':vertices,'normal_space':'OpenGL +Y tangent','status':'WIP_NOT_ART_ACCEPTED','gpu':'NOT_RUN','ordinary_spear':'FIVE_MH_SPEAR_ACTIONS_PRESENT_WIP','sampler_evidence':sampler_evidence}
raw=(out/'spearman-v2-wip.glb').read_bytes();length=struct.unpack_from('<I',raw,12)[0];gltf=json.loads(raw[20:20+length])
report['actual_glb_clip_seconds']={a['name']:max(gltf['accessors'][q['input']]['max'][0] for q in a['samplers']) for a in gltf['animations']}
for name,expected in {'Spear_Idle_V2_DRAFT':2.5,'Spear_Walk_V2_DRAFT':160/120,'Spear_Jog_V2_DRAFT':112/120,'Spear_Sprint_V2_DRAFT':80/120,'Spear_Thrust_V2_DRAFT':.7,'Death01':2.4}.items():
 assert abs(report['actual_glb_clip_seconds'][name]-expected)<.001,(name,'actual clip cadence differs')
report['geometry']={'triangles':sum(gltf['accessors'][p['indices']]['count']//3 for m in gltf['meshes'] for p in m['primitives']),'surfaces':sum(len(m['primitives']) for m in gltf['meshes']),'materials':len(gltf['materials']),'skins':len(gltf['skins'])}
(out/'runtime-report.json').write_text(json.dumps(report,indent=2)+'\n')

for mesh in gltf['meshes']:
 for primitive in mesh['primitives']:
  if 'normalTexture' in gltf['materials'][primitive['material']]:assert 'TANGENT' in primitive['attributes'], ('Missing tangent for normal-mapped surface',mesh['name'])
assert len(gltf['animations'])==14, 'Unexpected duplicate or missing animation'
