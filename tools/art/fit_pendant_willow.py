"""Normalize the complete CC0 willow mesh to a 6.8 m foot pivot, retaining the source UVs and silhouette."""
from pathlib import Path
from urllib.request import Request,urlopen
import hashlib,json,sys
import bpy
from mathutils import Vector,Matrix

folder=Path(__file__).resolve().parents[2]/"assets/third_party/river_willow"
folder.mkdir(exist_ok=True,parents=True)
entry="https://grab3d.com/dl/willow-tree/willow-tree.glb"
cache=Path(sys.argv[sys.argv.index("--")+1]); cache.mkdir(exist_ok=True,parents=True)
raw=cache/"willow.glb"
if not raw.is_file():
    with urlopen(Request(entry,headers={"User-Agent":"Luanshi-River-Art/1.0"}),timeout=80) as response: raw.write_bytes(response.read())
if raw.read_bytes()[:4]!=b'glTF': raise ValueError("Expected the artist GLB")
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=str(raw))
objs=[o for o in bpy.context.scene.objects if o.type=="MESH"]
if not objs: raise ValueError("No field mesh in source")
# Draw complete connected ribbons. Do not reconstruct the canopy from a few billboards.
bounds=[o.matrix_world@v.co for o in objs for v in o.data.vertices]
lo=Vector([min(p[k] for p in bounds) for k in range(3)])
hi=Vector([max(p[k] for p in bounds) for k in range(3)])
anchor=(lo+hi)*.5; anchor.z=lo.z
factor=6.8/(hi.z-lo.z)
for i,o in enumerate(objs):
    world=o.matrix_world.copy()
    o.data=o.data.copy()
    o.parent=None
    o.matrix_world=Matrix.Identity(4)
    o.data.transform(world)
    for v in o.data.vertices: v.co=(v.co-anchor)*factor
    o.name="Crown%02d"%i; o.data.name=o.name
    print("WILLOW_PART",o.name,len(o.data.polygons),[(m.name if m else None) for m in o.data.materials],flush=True)
bpy.ops.object.select_all(action="DESELECT")
for o in objs: o.select_set(True)
bpy.ops.export_scene.gltf(filepath=str(folder/"pollard.glb"),export_format="GLB",use_selection=True,export_animations=False)
(folder/"source.json").write_text(json.dumps({"asset":entry,"sha256":hashlib.sha256(raw.read_bytes()).hexdigest(),
    "licence":"CC0-1.0","page":"https://grab3d.com/models/nature/willow-tree/","parts":len(objs)},indent=2)+"\n")
