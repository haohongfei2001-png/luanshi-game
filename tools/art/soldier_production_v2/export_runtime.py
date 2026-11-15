"""Export isolated complete MH military derivative as a real skinned GLB.
Editable input is never changed. Explicit top-8 skin approximation is measured.
"""
import bpy,sys,pathlib,json,hashlib
src,out=map(pathlib.Path,sys.argv[sys.argv.index('--')+1:]);out.mkdir(parents=True,exist_ok=True)
bpy.ops.wm.open_mainfile(filepath=str(src),use_scripts=False,load_ui=False);rig=bpy.data.objects['MH163'];rig.data.pose_position='POSE'
bpy.context.scene.render.fps=120;bpy.context.scene.render.fps_base=1
rig.animation_data_create();rig.animation_data.action=bpy.data.actions.get('Idle_Loop');bpy.context.scene.frame_set(1)
assert all(n in bpy.data.actions for n in ['Idle_Loop','Walk_Loop','Hit_Chest','Death01']), 'Missing actual full-body actions'
render=[o for o in bpy.context.scene.objects if o.type=='MESH' and not o.hide_render]
# Source boundary: do not accidentally export the hidden robe or high source.
assert all(o.name not in ('Cross-front robe','V2_complete_coat_fit','Body_AuthorGarmentOcclusion') for o in render)
max_loss=0.;affected=0;vertices=0
for o in render:
 o.parent=rig
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
report={'source_sha256':hashlib.sha256(src.read_bytes()).hexdigest(),'glb_sha256':hashlib.sha256((out/'spearman-v2-wip.glb').read_bytes()).hexdigest(),'render_objects':[o.name for o in render],'source_animation_fps':120,'expected_action_durations_s':{a.name:(a.frame_range[1]-a.frame_range[0])/120 for a in bpy.data.actions},'source_bones':len(rig.data.bones),'actions_in_source':[a.name for a in bpy.data.actions],'skin_top8_affected_vertices':affected,'skin_top8_max_discarded_weight':max_loss,'vertices_before_export':vertices,'normal_space':'OpenGL +Y tangent','status':'WIP_NOT_ART_ACCEPTED','gpu':'NOT_RUN','ordinary_spear':'PENDING_SEPARATE_MH_ACTION_SOURCE'}
(out/'runtime-report.json').write_text(json.dumps(report,indent=2)+'\n')
