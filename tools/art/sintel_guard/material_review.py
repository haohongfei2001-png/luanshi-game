"""Local diagnostic migration, not shader equivalence or production Chinese art.
Preserves original materials as datablocks; no original file is overwritten.
"""
import bpy,json,pathlib,sys,hashlib
from mathutils import Vector
args=sys.argv[sys.argv.index('--')+1:]
source,legacy,out=map(pathlib.Path,args[:3]);height_distance=float(args[3]) if len(args)>3 else 0.0;out.mkdir(parents=True,exist_ok=True)
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
before=sha(source);data=json.loads(legacy.read_text())
bpy.ops.wm.open_mainfile(filepath=str(source),load_ui=False,use_scripts=False)
report={'source_sha256':before,'legacy_mapping_sha256':sha(legacy),'kind':'Blender diffuse-only migration diagnostic, NOT original shader reconstruction','autoexec':False,'game_pass':False,'assignments':[],'limitations':['Old multi-layer skin and specular shaders are not reconstructed.','GuardianTop secondary leather is height-only (mapto=2), never base-color mixed; modern bump scale is experimental.','Constant roughness is diagnostic, not authored PBR.']}
lookup={m['name']:m for m in data['materials']}
cache={}
for obj in list(bpy.context.scene.objects):
 if obj.type!='MESH':continue
 for slot in obj.material_slots:
  old=slot.material
  if not old:continue
  if old.name not in cache:
   m=lookup.get(old.name,{});slots=[s for s in m.get('slots',[]) if s.get('path') and not m.get('disabled_texture_bits',0)&(1<<s['slot'])]
   # Only exact source garment diffuse references. Unknown parts stay neutral.
   primary=next((s for s in slots if old.name.startswith('Guardian') and '_diff.' in s['path']),None)
   mat=bpy.data.materials.new('DIAGNOSTIC_'+old.name);mat.use_nodes=True
   bs=mat.node_tree.nodes.get('Principled BSDF');bs.inputs['Roughness'].default_value=.8;bs.inputs['Base Color'].default_value=(.28,.34,.38,1)
   entry={'source_material':old.name,'diagnostic_material':mat.name,'texture':None,'mode':'neutral unresolved'}
   if primary:
    path=source.parent/primary['path'].removeprefix('//');assert path.is_file(),path
    tex=mat.node_tree.nodes.new('ShaderNodeTexImage');tex.image=bpy.data.images.load(str(path),check_existing=True);tex.image.colorspace_settings.name='sRGB'
    mat.node_tree.links.new(tex.outputs['Color'],bs.inputs['Base Color'])
    entry.update(texture=str(path.relative_to(source.parent)),sha256=sha(path),mode='source diffuse only')
   if old.name=='GuardianTop' and height_distance>0:
    # Exact legacy slot semantics: both height; negative norfac. No RGB normal decode.
    # Distance is a labelled probe, NOT a conversion of old norfac into metres.
    previous=None
    for filename,relative in [('jack_top_diff.png',.125),('leather_01_diff.png',1.0)]:
     path=source.parent/'textures'/filename;assert path.is_file(),path
     tex=mat.node_tree.nodes.new('ShaderNodeTexImage');tex.image=bpy.data.images.load(str(path),check_existing=False);tex.image.colorspace_settings.name='Non-Color'
     bump=mat.node_tree.nodes.new('ShaderNodeBump');bump.invert=True;bump.inputs['Strength'].default_value=1;bump.inputs['Distance'].default_value=height_distance*relative
     mat.node_tree.links.new(tex.outputs['Color'],bump.inputs['Height'])
     if previous:mat.node_tree.links.new(previous,bump.inputs['Normal'])
     previous=bump.outputs['Normal']
    mat.node_tree.links.new(previous,bs.inputs['Normal'])
    entry['height_probe_metres']=height_distance;entry['legacy_equivalent']=False
   cache[old.name]=(mat,entry)
  mat,entry=cache[old.name];slot.material=mat
  report['assignments'].append({'object':obj.name,**entry})
scene=bpy.context.scene;scene.use_nodes=False;scene.render.engine='CYCLES';scene.cycles.samples=24;scene.cycles.use_denoising=False
scene.world=bpy.data.worlds.new('Diagnostic world');scene.world.use_nodes=True;scene.world.node_tree.nodes['Background'].inputs['Color'].default_value=(.22,.22,.22,1);scene.world.node_tree.nodes['Background'].inputs['Strength'].default_value=.4
bpy.ops.object.light_add(type='AREA',location=(3,-4,5));bpy.context.object.data.energy=700;bpy.context.object.data.size=4
bpy.ops.object.camera_add(location=(3.5,-5,2.6));cam=bpy.context.object;cam.rotation_euler=(Vector((0,-.08,1.03))-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.type='ORTHO';cam.data.ortho_scale=2.6;scene.camera=cam
scene.render.resolution_x=960;scene.render.resolution_y=1200;scene.render.resolution_percentage=100
scene.render.filepath=str(out/'native-diffuse-diagnostic-not-game.png');bpy.ops.render.render(write_still=True)
bpy.ops.wm.save_as_mainfile(filepath=str(out/'diagnostic-editable-not-production.blend'))
assert sha(source)==before
report['source_unchanged']=True
(out/'review.json').write_text(json.dumps(report,indent=2)+'\n')
