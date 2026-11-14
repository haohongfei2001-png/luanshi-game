"""Export derivative runtime mesh batches without changing the editable mother.
Godot 4.6 imports StandardMaterial3D PBR textures only from primary UV. All
source objects must agree on primary layer NAME before joining, including
professional deck sheets which use native UV rather than metre projection.
"""
import bpy,sys
from pathlib import Path

def export_runtime(output):
    for ob in bpy.data.objects:
        if ob.type!='MESH' or 'MaterialUV_Metre' not in ob.data.uv_layers:continue
        layers=ob.data.uv_layers;original=layers[0];material=layers['MaterialUV_Metre']
        if original==material:raise ValueError('Expected unchanged source mother UV order')
        original_values=[tuple(x.uv) for x in original.data]
        material_values=[tuple(x.uv) for x in material.data]
        original.name='RuntimeUVTemporary';material.name='SourceUV_Original';original.name='UVMap'
        for i,(old,new) in enumerate(zip(original_values,material_values)):
            original.data[i].uv=new;material.data[i].uv=old
        layers.active_index=0;original.active_render=True
    for name in ['masonry','timber','timber_cut']:
        material=bpy.data.materials.get(name)
        if material and material.use_nodes:
            for node in material.node_tree.nodes:
                if node.type in ['UVMAP','NORMAL_MAP'] and node.uv_map=='MaterialUV_Metre':node.uv_map='UVMap'
    for group in ['GateHall','GateDoor','WallWalk','GateBridge','WestBridge']:
        parent=bpy.data.objects.get(group)
        if parent is None:raise ValueError('Missing complete structural assembly '+group)
        batches={}
        for ob in parent.children:
            if ob.type!='MESH':continue
            key=('Roof_'+('East' if 'East' in ob.name else 'West' if 'West' in ob.name else 'HipNorth' if 'HipNorth' in ob.name else 'HipSouth') if ob.name.startswith('Roof_') else parent.name+'_Structure')
            batches.setdefault(key,[]).append(ob)
        for name,objects in batches.items():
            bpy.ops.object.select_all(action='DESELECT')
            for ob in objects:ob.select_set(True)
            bpy.context.view_layer.objects.active=objects[0];bpy.ops.object.join();objects[0].name=name
    bpy.ops.object.select_all(action='DESELECT')
    bpy.ops.export_scene.gltf(filepath=str(output),export_format='GLB',export_yup=True,export_extras=True)

if __name__=='__main__':
    source,output=map(Path,sys.argv[sys.argv.index('--')+1:])
    bpy.ops.wm.open_mainfile(filepath=str(source),load_ui=False)
    export_runtime(output)
