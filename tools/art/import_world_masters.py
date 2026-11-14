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
from mathutils.kdtree import KDTree

ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/"assets/river_gate/world/masters"
CACHE=Path(sys.argv[sys.argv.index("--")+1])
ASSETS=[
    ("coastal_cliff_02",90000,"Rob Tuytel"),
    ("coast_rocks_03",65000,"Rico Cilliers and Rob Tuytel"),
    ("rock_moss_set_01",90000,"Kless Gyzen"),
    ("modular_wooden_pier",85000,"Rico Cilliers"),
    ("island_tree_03",180000,"Rico Cilliers and Rob Tuytel"),
    ("pine_tree_01",120000,"Rico Cilliers and Rob Tuytel"),
    ("island_tree_01",220000,"Rico Cilliers and Rob Tuytel"),
    ("fern_02",6000,"Rico Cilliers and Rob Tuytel"),
    ("shrub_03",22000,"Rico Cilliers"),
    ("shrub_01",42000,"Rico Cilliers"),
    ("searsia_burchellii",100000,"James Ray Cock and Jenelle van Heerden"),
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

def uses_leaf_material(obj):
    return any(obj.data.materials[index] and "leaves" in obj.data.materials[index].name.lower()
               for index in {face.material_index for face in obj.data.polygons})

def author_leaf_canopy(obj, woody_parts):
    """Keep complete native leaves and enlarge their readable silhouette."""
    source = obj.data
    parents = list(range(len(source.vertices)))
    def root(index):
        while parents[index] != index:
            parents[index] = parents[parents[index]]
            index = parents[index]
        return index
    for edge in source.edges:
        a, b = edge.vertices
        parents[root(b)] = root(a)
    groups = {}
    for vertex in source.vertices:
        groups.setdefault(root(vertex.index), []).append(vertex.index)
    wood = [part.matrix_world @ vertex.co for part in woody_parts for vertex in part.data.vertices]
    tree = KDTree(len(wood))
    for index, point in enumerate(wood):
        tree.insert(point, index)
    tree.balance()
    kept = {}
    coordinates = []
    selected_islands = 0
    # Whole-leaf selection leaves the native curved contour, stem and UV intact.
    # A larger leaf makes the canopy readable at the normal 22-metre camera.
    for ordinal, indices in enumerate(groups.values()):
        if ordinal % 3 != 0:
            continue
        selected_islands += 1
        anchor_index = min(indices, key=lambda index: tree.find(source.vertices[index].co)[2])
        anchor = source.vertices[anchor_index].co
        for index in indices:
            kept[index] = len(coordinates)
            coordinates.append(anchor + (source.vertices[index].co - anchor) * 2.1)
    polygons = []
    materials = []
    smooth = []
    uv_layers = {layer.name: [] for layer in source.uv_layers}
    for face in source.polygons:
        if face.vertices[0] not in kept:
            continue
        assert all(index in kept for index in face.vertices)
        polygons.append([kept[index] for index in face.vertices])
        materials.append(face.material_index)
        smooth.append(face.use_smooth)
        for layer in source.uv_layers:
            for loop in face.loop_indices:
                uv_layers[layer.name].extend(layer.data[loop].uv)
    mesh = bpy.data.meshes.new(source.name + "_readable_native_leaves")
    mesh.from_pydata(coordinates, [], polygons)
    mesh.update()
    for material in source.materials:
        mesh.materials.append(material)
    for face, material, shading in zip(mesh.polygons, materials, smooth):
        face.material_index = material
        face.use_smooth = shading
    for name, values in uv_layers.items():
        layer = mesh.uv_layers.new(name=name)
        layer.data.foreach_set("uv", values)
    obj.data = mesh
    return {
        "source_leaf_islands": len(groups),
        "retained_whole_leaves": selected_islands,
        "native_leaf_scale": 2.1,
        "attachment": "Nearest original woody surface vertex remains anchored",
        "policy": "Every third complete source leaf, original curved contour and matched UV retained",
    }

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
    if asset=="rock_moss_set_01" and len(objects)==1:
        bpy.context.view_layer.objects.active=objects[0]
        bpy.ops.object.mode_set(mode="EDIT")
        bpy.ops.mesh.select_all(action="SELECT")
        bpy.ops.mesh.separate(type="LOOSE")
        bpy.ops.object.mode_set(mode="OBJECT")
        objects=[o for o in bpy.context.scene.objects if o.type=="MESH"]
    original=[(o.name,len(o.data.polygons),list(o.dimensions)) for o in objects]
    print("MASTER_SOURCE",asset,json.dumps(original),flush=True)
    keep=[]
    for obj in objects:
        lod=re.search(r"lod[_ -]?([0-9]+)",obj.name,re.I)
        if lod and int(lod.group(1))>0:continue
        keep.append(obj)
    if asset=="rock_moss_set_01":
        keep=sorted((obj for obj in keep if len(obj.data.polygons)>150),
                    key=lambda obj:(-len(obj.data.polygons),obj.name))[:6]
        assert len(keep)>=3, "The authored rock set needs separate complete stone volumes"
        for index,obj in enumerate(keep):obj.name="RockVolume%02d"%index
    assert keep,asset
    # Dense native crowns consist of many disconnected leaves. A global collapse
    # modifier deletes entire leaves before it preserves the tree's silhouette.
    # Separate the author's material parts so only woody geometry is collapsed.
    if asset=="island_tree_01":
        expanded=[]
        for obj in keep:
            bpy.ops.object.select_all(action="DESELECT")
            obj.select_set(True);bpy.context.view_layer.objects.active=obj
            bpy.ops.object.mode_set(mode="EDIT")
            bpy.ops.mesh.select_all(action="SELECT")
            bpy.ops.mesh.separate(type="MATERIAL")
            bpy.ops.object.mode_set(mode="OBJECT")
            expanded.extend(bpy.context.selected_objects)
        keep=list(dict.fromkeys(expanded))
    total=sum(sum(len(p.vertices)-2 for p in o.data.polygons) for o in keep)
    ratio=min(1.,budget/max(total,1))
    foliage=[]
    bpy.ops.object.select_all(action="DESELECT")
    for obj in keep:
        bpy.context.view_layer.objects.active=obj
        world=obj.matrix_world.copy()
        obj.data=obj.data.copy();obj.parent=None
        obj.matrix_world=Matrix.Identity(4);obj.data.transform(world)
        obj.select_set(True)
        source_count=sum(len(p.vertices)-2 for p in obj.data.polygons)
        leaf_part=asset=="island_tree_01" and uses_leaf_material(obj)
        if leaf_part:
            woody=[part for part in keep if part!=obj and not uses_leaf_material(part)]
            authored=author_leaf_canopy(obj,woody)
            foliage.append({"object":obj.name,"source_triangles":source_count,
                "game_triangles":sum(len(p.vertices)-2 for p in obj.data.polygons),**authored})
        elif ratio<.97:
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
    bpy.context.view_layer.update()
    points=[obj.matrix_world@Vector(corner) for obj in selected for corner in obj.bound_box]
    receipt["bounds_blender"]=[[min(v[i] for v in points) for i in range(3)],[max(v[i] for v in points) for i in range(3)]]
    receipt["foliage"]=foliage
    receipt["canopy_revision"]=2 if asset=="island_tree_01" else 0
    receipt["source_triangles"]=total
    receipt["game_triangles"]=sum(sum(len(p.vertices)-2 for p in o.data.polygons) for o in selected)
    receipt["objects"]=[{"name":o.name,"triangles":sum(len(p.vertices)-2 for p in o.data.polygons)} for o in selected]
    destination=OUT/asset;destination.mkdir(parents=True,exist_ok=True)
    bpy.ops.export_scene.gltf(filepath=str(destination/(asset+".gltf")),export_format="GLTF_SEPARATE",use_selection=True,export_materials="EXPORT",export_yup=True,export_animations=False,export_cameras=False,export_lights=False)
    (destination/"SOURCE.json").write_text(json.dumps(receipt,indent=2)+"\n")
    (destination/"NOTICE.txt").write_text(asset+" by "+author+"\nCC0-1.0. https://polyhaven.com/license\nhttps://polyhaven.com/a/"+asset+"\nDerived game geometry and original matched albedo/AO; see SOURCE.json for exact source and checksums.\n")
    print("MASTER_READY",asset,receipt["source_triangles"],receipt["game_triangles"],receipt["bounds_blender"],flush=True)
CACHE.mkdir(parents=True,exist_ok=True)
requested=set(sys.argv[sys.argv.index("--")+2:])
unknown=requested-{row[0] for row in ASSETS}
assert not unknown,unknown
for asset,budget,author in ASSETS:
    if requested and asset not in requested:continue
    import_master(asset,budget,author)
