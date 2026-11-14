"""Assemble a complete timber bridge from intact CC0 photographed deck boards.

Run with Blender. Extract connected authored boards from Rico Cilliers'
Modular Wooden Pier, keep their original surfaces and recombine them into a
12 by 7.5 metre military crossing. No open-water gaps are hidden by a plane.
"""
from pathlib import Path
import json,math
import bpy
from mathutils import Matrix,Vector

ROOT=Path(__file__).resolve().parents[2]
SOURCE=ROOT/"assets/river_gate/world/masters/modular_wooden_pier"
OUT=ROOT/"assets/river_gate/world/bridge"

def bounds(obj):
    points=[obj.matrix_world@v.co for v in obj.data.vertices]
    return Vector([min(v[k] for v in points) for k in range(3)]),Vector([max(v[k] for v in points) for k in range(3)])

def main():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=str(SOURCE/"modular_wooden_pier.gltf"))
    original=next(o for o in bpy.context.scene.objects if o.name=="modular_wooden_pier_planks")
    bpy.ops.object.select_all(action="DESELECT")
    original.select_set(True)
    bpy.context.view_layer.objects.active=original
    bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="SELECT")
    bpy.ops.mesh.remove_doubles(threshold=.00003)
    bpy.ops.mesh.separate(type="LOOSE")
    bpy.ops.object.mode_set(mode="OBJECT")
    boards=[]
    for obj in bpy.context.selected_objects:
        low,high=bounds(obj)
        size=high-low
        major=max(size.x,size.y);minor=min(size.x,size.y)
        if major>1.2 and .05<minor<.65 and size.z<.20 and major/minor>3.:
            boards.append(obj)
    boards.sort(key=lambda obj:-len(obj.data.polygons))
    assert boards,"The upstream mesh must contain actual intact boards"
    boards=boards[:6]
    receipts=[]
    for obj in boards:
        low,high=bounds(obj)
        size=high-low
        receipts.append({"source_component":obj.name,"triangles":sum(len(f.vertices)-2 for f in obj.data.polygons),"bounds":[list(low),list(high)]})
        for vertex in obj.data.vertices:
            p=vertex.co-(low+high)*.5
            # Modelled longitudinal grain stays along a transverse bridge board.
            if size.x>size.y:p=Vector((p.y,p.x,p.z))
            p.x*=.263/min(size.x,size.y)
            p.y*=2.54/max(size.x,size.y)
            p.z*=.07/max(size.z,.001)
            vertex.co=p
    bpy.ops.object.select_all(action="DESELECT")
    assembled=[]
    for row in range(48):
        for bay in range(3):
            master=boards[(row*5+bay*3)%len(boards)]
            obj=master.copy();obj.data=master.data
            bpy.context.collection.objects.link(obj)
            obj.name="DeckBoard_%02d_%d"%(row,bay)
            obj.matrix_world=Matrix.Translation(Vector((-5.875+row*.25,-2.5+bay*2.5,.095)))
            obj.select_set(True)
            assembled.append(obj)
    bpy.context.view_layer.objects.active=assembled[0]
    bpy.ops.object.join()
    combined=bpy.context.view_layer.objects.active
    combined.name="IntactBridgeSpan"
    bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
    for face in combined.data.polygons:face.use_smooth=False
    OUT.mkdir(parents=True,exist_ok=True)
    bpy.ops.export_scene.gltf(filepath=str(OUT/"intact_bridge_span.glb"),export_format="GLB",use_selection=True,export_materials="EXPORT",export_yup=True,export_animations=False)
    receipt=json.loads((SOURCE/"SOURCE.json").read_text())
    receipt.update(derived_component="Intact connected deck boards from modular_wooden_pier_planks",board_sources=receipts,rows=48,bays=3,deck_top_m=.13,nominal_span_m=[12.,7.5],triangles=sum(len(f.vertices)-2 for f in combined.data.polygons))
    (OUT/"SOURCE.json").write_text(json.dumps(receipt,indent=2)+"\n")
    (OUT/"NOTICE.txt").write_text("Complete timber crossing assembled from original connected boards in Modular Wooden Pier by Rico Cilliers, Poly Haven, CC0-1.0. Original source, checksums and assembly coordinates are in SOURCE.json and tools/art/build_intact_bridge.py.\n")
    print("INTACT_BRIDGE",json.dumps(receipt),flush=True)

if __name__=="__main__":main()
