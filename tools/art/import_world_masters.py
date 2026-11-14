"""Import complete CC0 environmental masters for the replacement river battlefield.

Run with Blender in background, followed by -- <cache>.
The source manifests and MD5s are retained. Only the artist's matched albedo,
alpha and baked ambient occlusion are used for this restrained game adaptation.
"""
from pathlib import Path
import hashlib,json,math,re,sys
from urllib.request import Request,urlopen
from urllib.parse import unquote
import bpy
from mathutils import Matrix,Vector

ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/"assets/river_gate/world/masters"
CACHE=Path(sys.argv[sys.argv.index("--")+1])
ASSETS=[
    ("coastal_cliff_02",90000,"Rob Tuytel"),
    ("modular_wooden_pier",85000,"Rico Cilliers"),
    ("island_tree_03",180000,"Rico Cilliers and Rob Tuytel"),
    ("pine_tree_01",120000,"Rico Cilliers and Rob Tuytel"),
]
HEADERS={"User-Agent":"Luanshi-River-Art/1.0 (github.com/haohongfei2001-png/luanshi-game)"}
def read(url):
    with urlopen(Request(url,headers=HEADERS),timeout=120) as response:return response.read()
def download(entry,path):
    if not path.is_file() or hashlib.md5(path.read_bytes()).hexdigest()!=entry["md5"]:
        raw=read(entry["url"])
        assert hashlib.md5(raw).hexdigest()==entry["md5"],entry["url"]
        path.parent.mkdir(parents=True,exist_ok=True);path.write_bytes(raw)
    return path
def import_master(asset,budget,author):
    cache=CACHE/asset;cache.mkdir(parents=True,exist_ok=True)
    manifest=json.loads(read("https://api.polyhaven.com/files/"+asset))
    item=manifest["gltf"]["2k"]["gltf"]
    source=download(item,cache/"original.gltf")
    document=json.loads(source.read_bytes())
    used=set()
    for material in document.get("materials",[]):
        material.pop("normalTexture",None)
        pbr=material.get("pbrMetallicRoughness",{})
        pbr.pop("metallicRoughnessTexture",None)
        pbr["metallicFactor"]=0.0;pbr["roughnessFactor"]=.96
        for key in ("baseColorTexture",):
            if key in pbr:used.add(document["textures"][pbr[key]["index"]]["source"])
        if "occlusionTexture" in material:
            used.add(document["textures"][material["occlusionTexture"]["index"]]["source"])
        material["doubleSided"]=True
    assert used,asset
    receipt={"asset":asset,"author":author,"license":"CC0-1.0","page":"https://polyhaven.com/a/"+asset,"gltf":item["url"],"gltf_md5":item["md5"],"inputs":{}}
    for buffer in document.get("buffers",[]):
        uri=unquote(buffer["uri"])
        entry=item["include"][uri]
        download(entry,cache/uri);receipt["inputs"][uri]=entry["md5"]
    images=document.get("images",[])
    fallback=images[min(used)]["uri"]
    for i,image in enumerate(images):
        if i not in used:
            image["uri"]=fallback;continue
        uri=unquote(image["uri"])
        entry=item["include"][uri]
        download(entry,cache/uri);receipt["inputs"][uri]=entry["md5"]
    (cache/"albedo-master.gltf").write_text(json.dumps(document))
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=str(cache/"albedo-master.gltf"))
    objects=[o for o in bpy.context.scene.objects if o.type=="MESH"]
    original=[(o.name,len(o.data.polygons),list(o.dimensions)) for o in objects]
    print("MASTER_SOURCE",asset,json.dumps(original),flush=True)
    keep=[]
    for obj in objects:
        lod=re.search(r"lod[_ -]?([0-9]+)",obj.name,re.I)
        if lod and int(lod.group(1))>0:continue
        keep.append(obj)
    assert keep,asset
    total=sum(sum(len(p.vertices)-2 for p in o.data.polygons) for o in keep)
    ratio=min(1.,budget/max(total,1))
    bpy.ops.object.select_all(action="DESELECT")
    for obj in keep:
        bpy.context.view_layer.objects.active=obj
        world=obj.matrix_world.copy()
        obj.data=obj.data.copy();obj.parent=None
        obj.matrix_world=Matrix.Identity(4);obj.data.transform(world)
        obj.select_set(True)
        if ratio<.97:
            mod=obj.modifiers.new("Camera master silhouette and UV preservation","DECIMATE")
            mod.ratio=ratio
            bpy.ops.object.modifier_apply(modifier=mod.name)
        for material in obj.data.materials:
            if material and material.use_nodes:
                for node in material.node_tree.nodes:
                    if node.type=="BSDF_PRINCIPLED":
                        spec=node.inputs.get("Specular IOR Level") or node.inputs.get("Specular")
                        if spec:spec.default_value=.12
                        node.inputs["Roughness"].default_value=.96
                        node.inputs["Metallic"].default_value=0.
    selected=[o for o in keep if len(o.data.polygons)>0]
    for obj in keep:
        obj.select_set(obj in selected)
    points=[obj.matrix_world@Vector(corner) for obj in selected for corner in obj.bound_box]
    receipt["bounds_blender"]=[[min(v[i] for v in points) for i in range(3)],[max(v[i] for v in points) for i in range(3)]]
    receipt["source_triangles"]=total
    receipt["game_triangles"]=sum(sum(len(p.vertices)-2 for p in o.data.polygons) for o in selected)
    receipt["objects"]=[{"name":o.name,"triangles":sum(len(p.vertices)-2 for p in o.data.polygons)} for o in selected]
    destination=OUT/asset;destination.mkdir(parents=True,exist_ok=True)
    bpy.ops.export_scene.gltf(filepath=str(destination/(asset+".gltf")),export_format="GLTF_SEPARATE",use_selection=True,export_materials="EXPORT",export_yup=True,export_animations=False,export_cameras=False,export_lights=False)
    (destination/"SOURCE.json").write_text(json.dumps(receipt,indent=2)+"\n")
    (destination/"NOTICE.txt").write_text(asset+" by "+author+"\nCC0-1.0. https://polyhaven.com/license\nhttps://polyhaven.com/a/"+asset+"\nDerived game geometry and original matched albedo/AO; see SOURCE.json for exact source and checksums.\n")
    print("MASTER_READY",asset,receipt["source_triangles"],receipt["game_triangles"],receipt["bounds_blender"],flush=True)
CACHE.mkdir(parents=True,exist_ok=True)
for asset,budget,author in ASSETS:import_master(asset,budget,author)
