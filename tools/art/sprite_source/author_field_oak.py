"""Independent whole-tree production study. Original movie libraries remain immutable.
Uses one complete professional branch hierarchy, NOT the rejected root-claw stump.
Crown sockets derive from actual evaluated terminal twigs, never world scatter.
Output is editable source for review, NOT an accepted game asset.
"""
import bpy, json, pathlib, sys, hashlib
from mathutils import Vector
args=sys.argv[sys.argv.index('--')+1:]
source=pathlib.Path(args[0]);out=pathlib.Path(args[1]);out.mkdir(parents=True,exist_ok=True)
spacing=float(args[2]) if len(args)>2 else .20
max_sprays=int(args[3]) if len(args)>3 else 96
minimum_height=float(args[4]) if len(args)>4 else 1.0
assert .1<=spacing<=1. and 1<=max_sprays<=120
bpy.ops.wm.read_factory_settings(use_empty=True)
scene=bpy.context.scene;scene.render.use_simplify=True
scene.render.simplify_subdivision=1;scene.render.simplify_subdivision_render=1

def load_col(file,name):
    with bpy.data.libraries.load(str(source/file),link=False) as (a,b):
        assert name in a.collections
        b.collections=[name]
    return b.collections[0]
wood=load_col('lib/env/branches.blend','EN-tree_branch_medium.05')
scene.collection.children.link(wood)
sockets=[]
for instance in bpy.context.evaluated_depsgraph_get().object_instances:
    obj=instance.object
    if obj.type!='MESH' or not obj.original.name.startswith('GEO-tree_branch_twig'):continue
    mesh=obj.to_mesh()
    # Twig source origin is the professional attachment socket. Preserve all
    # parent inverse / collection offset effects from evaluated matrix_world.
    tip=max((v.co.copy() for v in mesh.vertices),key=lambda p:p.length_squared)
    base=instance.matrix_world.translation.copy()-wood.instance_offset
    end=instance.matrix_world@tip-wood.instance_offset
    obj.to_mesh_clear()
    if end.z<minimum_height:continue
    sockets.append((base,end,obj.original.name))
scene.collection.children.unlink(wood)
foliage=load_col('lib/env/trees.blend','EN-branch1')
assembly=bpy.data.collections.new('FIELD-oak-source-study-01')
scene.collection.children.link(assembly)
trunk=bpy.data.objects.new('Complete_professional_branch_system',None)
trunk.instance_type='COLLECTION';trunk.instance_collection=wood;assembly.objects.link(trunk)
# No extra offset: Blender collection instances automatically subtract their offset.
chosen=[]
for base,end,name in sorted(sockets,key=lambda s:(-s[1].z,s[1].x,s[1].y)):
    if any((end-other[1]).length<spacing for other in chosen):continue
    chosen.append((base,end,name))
    if len(chosen)==max_sprays:break
for index,(base,end,name) in enumerate(chosen):
    leaf=bpy.data.objects.new('Crown_socket_%02d'%index,None)
    leaf.instance_type='COLLECTION';leaf.instance_collection=foliage
    # Source leaf spray root joins the actual twig; leaf fan extends outwards.
    leaf.location=base.lerp(end,.75)
    direction=(end-base).normalized()
    leaf.rotation_euler=direction.to_track_quat('Y','Z').to_euler()
    leaf.scale=(.9,.9,.9)
    assembly.objects.link(leaf)
assembly['status']='SOURCE_ASSEMBLY_STUDY_NOT_GAME_ART_ACCEPTED'
assembly['source_license']='Blender Studio Sprite Fright / CC BY 4.0'
scene['render_subdivision_cap']=1
bpy.ops.wm.save_as_mainfile(filepath=str(out/'field-oak-source-study.blend'))
report={'status':'SOURCE_ASSEMBLY_STUDY_NOT_GAME_ART_ACCEPTED','source_package_sha256':'21ee25dfffc76030770b644de5fe897559aead064b384fba77166b71a9337791','sources':{f:hashlib.sha256((source/f).read_bytes()).hexdigest() for f in ['lib/env/trees.blend','lib/env/branches.blend']},'wood_collection':wood.name,'leaf_spray_collection':foliage.name,'complete_wood_hierarchy_preserved':True,'source_mesh_uv_material_mutation':False,'source_twig_candidates':len(sockets),'crown_sprays':len(chosen),'socket_rule':'actual evaluated twig endpoint; .9 uniform leaf spray scale','spacing_m':spacing,'max_sprays':max_sprays,'minimum_socket_height_m':minimum_height,'sockets':[{'twig':n,'base':list(b),'tip':list(e)} for b,e,n in chosen],'runtime_lod':'NOT_PRODUCED','game_visual':'NOT_RUN'}
(out/'assembly.json').write_text(json.dumps(report,indent=2)+'\n')
print('FIELD_OAK_SOURCE_ASSEMBLY',len(chosen))
