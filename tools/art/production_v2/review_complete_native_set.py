"""Review the complete production set in its compatible Blender version.
Run under shared heavy-art flock, with --disable-autoexec. No asset source save.
This is offline author review, NOT gameplay evidence or acceptance.
"""
import argparse,bpy,json,hashlib,sys
from pathlib import Path
from mathutils import Vector
ap=argparse.ArgumentParser();ap.add_argument('--source',type=Path,required=True);ap.add_argument('--out',type=Path,required=True);ap.add_argument('--scene',default='030_0100');ap.add_argument('--density-factor',type=float,default=1.0);ap.add_argument('--subdivision-cap',type=int,default=1);ap.add_argument('--audit-only',action='store_true');ap.add_argument('--scatter-density-factor',type=float,default=1.0);ap.add_argument('--child-particle-factor',type=float,default=1.0);ap.add_argument('--omit-subpixel-moss',action='store_true');args=ap.parse_args(sys.argv[sys.argv.index('--')+1:]);args.out.mkdir(parents=True,exist_ok=True)
assert bpy.app.version[:3]==(3,1,2), 'PINNED_SOURCE_BLENDER_REQUIRED_3_1_2: never silently drop legacy canopy nodes'
bpy.ops.wm.open_mainfile(filepath=str(args.source),load_ui=False);s=bpy.data.scenes[args.scene]
print('OPENED_COMPLETE_SET',args.scene,len(s.objects),flush=True)
undefined=[{'group':g.name,'node':n.name,'type':n.bl_idname} for g in bpy.data.node_groups for n in g.nodes if n.bl_idname=='NodeUndefined']
densities=[];caps=[]
for o in bpy.data.objects:
 for m in o.modifiers:
  if m.type=='SUBSURF' and m.render_levels>args.subdivision_cap:
   caps.append({'object':o.name,'modifier':m.name,'original':m.render_levels,'derived':args.subdivision_cap});m.render_levels=args.subdivision_cap;m.levels=min(m.levels,args.subdivision_cap)
  if m.type=='NODES' and m.node_group and m.node_group.name.startswith('trees_leaves'):
   if 'Input_7' in m:
    before=float(m['Input_7']);m['Input_7']=before*args.density_factor;densities.append({'object':o.name,'group':m.node_group.name,'original_density':before,'diagnostic_density':m['Input_7']})
scatter=[];microgeometry=[]
for o in bpy.data.objects:
 for m in o.modifiers:
  if m.type=='NODES' and m.node_group and args.omit_subpixel_moss and m.node_group.name=='GE-moss.trees':
   microgeometry.append({'object':o.name,'group':m.node_group.name,'reason':'film moss microgeometry disabled for normal-camera diagnostic; bark body/material retained'});m.show_render=False;m.show_viewport=False
  if m.type=='NODES' and m.node_group and not m.node_group.name.startswith('trees_leaves'):
   for socket in m.node_group.inputs:
    if 'density' in socket.name.lower() and socket.identifier in m and isinstance(m[socket.identifier],(int,float)):
     original=float(m[socket.identifier]);m[socket.identifier]=original*(args.density_factor if 'leaf_system' in m.node_group.name else args.scatter_density_factor);scatter.append({'object':o.name,'group':m.node_group.name,'socket':socket.name,'original':original,'diagnostic':m[socket.identifier]})
report={'source_sha256':hashlib.sha256(args.source.read_bytes()).hexdigest(),'blender_version':bpy.app.version_string,'scene':args.scene,'scene_objects':len(s.objects),'undefined_nodes':undefined,'tree_density_changes':densities,'other_scatter_density_changes':scatter,'film_microgeometry_changes':microgeometry,'child_particle_factor':args.child_particle_factor,'subdivision_caps':caps,'status':'AUDIT_ONLY' if args.audit_only else 'RENDER_PENDING','is_game_capture':False,'source_saved':False}
(args.out/'source-review.json').write_text(json.dumps(report,indent=2))
if undefined:raise RuntimeError('UNDEFINED_NATIVE_NODES: use compatible source Blender; do not call a bare forest intact')
if args.audit_only:print('SOURCE_AUDIT_COMPLETE',flush=True);sys.exit(0)
# Limit expensive film subdivision BEFORE scene selection triggers evaluation.
s.render.use_simplify=True;s.render.simplify_subdivision_render=args.subdivision_cap;s.render.simplify_child_particles_render=args.child_particle_factor
bpy.context.window.scene=s;print('SELECTED_COMPLETE_SET',flush=True)
camd=bpy.data.cameras.new('Complete_native_set_NOT_GAME');cam=bpy.data.objects.new(camd.name,camd);s.collection.objects.link(cam);target=Vector((54,-1,1));cam.location=target+Vector((-24,-21,30));cam.rotation_euler=(target-cam.location).to_track_quat('-Z','Y').to_euler();camd.lens=35;s.camera=cam
for o in s.objects:
 if o.type=='LIGHT':o.hide_render=True
l=bpy.data.lights.new('Neutral_source_review','SUN');l.energy=2;l.angle=.1;ob=bpy.data.objects.new(l.name,l);s.collection.objects.link(ob);ob.rotation_euler=(.5,-.6,-.7)
w=bpy.data.worlds.new('Neutral_source_world');w.use_nodes=True;w.node_tree.nodes['Background'].inputs[0].default_value=(.4,.45,.5,1);w.node_tree.nodes['Background'].inputs[1].default_value=.65;s.world=w
s.render.use_stamp=False;s.render.film_transparent=False;s.render.image_settings.file_format='PNG';s.render.engine='CYCLES';s.cycles.samples=16;s.cycles.use_denoising=False;s.render.resolution_x=1280;s.render.resolution_y=720;s.render.resolution_percentage=100;s.render.filepath=str(args.out/'complete-native-set-NOT-GAME.png');s.view_settings.view_transform='Filmic';bpy.ops.render.render(write_still=True)
report['status']='OFFLINE_SOURCE_RENDERED_NOT_ART_ACCEPTED';report['image_sha256']=hashlib.sha256((args.out/'complete-native-set-NOT-GAME.png').read_bytes()).hexdigest();(args.out/'source-review.json').write_text(json.dumps(report,indent=2));print('COMPLETE_NATIVE_RENDER',flush=True)
