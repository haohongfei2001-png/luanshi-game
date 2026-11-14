"""Extract one complete five-blade professional source tuft, not a forest emitter.
Source file and its original mesh/UV/material/modifier stack remain unmodified.
"""
import bpy,pathlib,sys,json,hashlib
args=sys.argv[sys.argv.index('--')+1:];root=pathlib.Path(args[0]);out=pathlib.Path(args[1]);out.mkdir(parents=True,exist_ok=True)
source=root/'lib/env/plants.blend'
assert hashlib.sha256(source.read_bytes()).hexdigest()=='3ade1b32e300a35a5d0f9aa0599d21b5f5dfe7b711dab88cbe3f706017bd3320'
bpy.ops.wm.read_factory_settings(use_empty=True)
with bpy.data.libraries.load(str(source),link=False) as (a,b):b.objects=['GEO-leaf.grass.007']
obj=b.objects[0];assert obj.type=='MESH' and obj.parent is None
original_location=list(obj.location);obj.location=(0,0,0)
col=bpy.data.collections.new('FIELD-five-blade-low-grass');bpy.context.scene.collection.children.link(col);col.objects.link(obj)
col['source']='Blender Studio / Sprite Fright / CC BY 4.0'
col['scope']='one complete five-blade tuft; NOT an authored ground-cover region'
col['unit_policy']='original BU retained; explicit game scale required, not automatically metres'
bpy.ops.wm.save_as_mainfile(filepath=str(out/'low-grass-source.blend'))
(out/'source.json').write_text(json.dumps({'source_sha256':hashlib.sha256(source.read_bytes()).hexdigest(),'object':obj.name,'original_inventory_location':original_location,'inventory_translation_removed':True,'source_mesh_vertices':len(obj.data.vertices),'source_mesh_polygons':len(obj.data.polygons),'uv_layers':[u.name for u in obj.data.uv_layers],'geometry_uv_material_preserved':True,'runtime_material':'NOT_YET_BAKED','art':'NOT_ACCEPTED'},indent=2)+'\n')
