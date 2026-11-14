"""Fit Kless Gyzen's CC0 Rock Moss Set 01 scan to reusable metre-wide river blocks.

Run Blender in background with this script, followed by '-- <cache-directory>'.
The inputs are downloaded once for authoring, never at game startup.
"""
from pathlib import Path
import hashlib
import json
import math
import sys
import urllib.request
from urllib.parse import unquote, urlparse

import bpy
from mathutils import Vector
from PIL import Image, ImageEnhance, ImageFilter, ImageOps

ROOT = Path(__file__).resolve().parents[2]
DEST = ROOT / "assets/third_party/polyhaven_bank"
ASSET = "rock_moss_set_01"
CACHE = Path(sys.argv[sys.argv.index("--") + 1])
CACHE.mkdir(parents=True, exist_ok=True)
DEST.mkdir(parents=True, exist_ok=True)


def fetch(url):
    request = urllib.request.Request(url, headers={"User-Agent": "Luanshi-River-Art/1.0 (github.com/haohongfei2001-png/luanshi-game)"})
    with urllib.request.urlopen(request, timeout=75) as response:
        return response.read()


def download(entry, path):
    if not path.is_file() or hashlib.md5(path.read_bytes()).hexdigest()!=entry["md5"]:
        data = fetch(entry["url"])
        if hashlib.md5(data).hexdigest()!=entry["md5"]:
            raise ValueError("Upstream digest mismatch for "+entry["url"])
        path.parent.mkdir(parents=True,exist_ok=True)
        path.write_bytes(data)
    return path


def source_files():
    manifest = json.loads(fetch("https://api.polyhaven.com/files/"+ASSET))
    entry=manifest["gltf"]["2k"]["gltf"]
    src=download(entry,CACHE/"rocks.gltf")
    scene=json.loads(src.read_text())
    if len(scene.get("materials",[]))<1:
        raise ValueError("Missing surface in source")
    for needed in scene.get("buffers",[]):
        uri=unquote(needed["uri"])
        download(entry["include"][uri],CACHE/uri)
    # Only use the scanned colour. Roughness/metal/normal maps would add noise at play distance.
    tex=scene["materials"][0]["pbrMetallicRoughness"]["baseColorTexture"]["index"]
    uri=unquote(scene["images"][scene["textures"][tex]["source"]]["uri"])
    color=download(entry["include"][uri],CACHE/uri)
    # The mesh importer otherwise tries loading unused optional PBR images.
    for material in scene["materials"]:
        material.pop("normalTexture",None)
        material.pop("occlusionTexture",None)
        material.get("pbrMetallicRoughness",{}).pop("metallicRoughnessTexture",None)
    for im in scene["images"]:
        if not (CACHE/unquote(im["uri"])).exists(): im["uri"]=uri
    (CACHE/"bank-source.gltf").write_text(json.dumps(scene))
    receipt={"source":entry["url"],"gltf_md5":entry["md5"],"inputs":{k:v["md5"] for k,v in entry["include"].items() if (CACHE/unquote(k)).exists()},"author":"Kless Gyzen","license":"CC0-1.0"}
    (DEST/"source.json").write_text(json.dumps(receipt,indent=2)+"\n")
    return CACHE/"bank-source.gltf",color


def mineral_paint(path):
    # Keep the registered large weathered faces, fissures, and green lichen.
    # Reduce only sub-centimetre mottling before mipmapping; the broad planes
    # stay light enough to frame the dark water and the warm cartway.
    original=Image.open(path).convert("RGB")
    if min(original.size)<2048: raise ValueError(original.size)
    smooth=original.filter(ImageFilter.GaussianBlur(2.1))
    albedo=Image.blend(smooth,original,.30)
    albedo=ImageEnhance.Color(albedo).enhance(.73)
    tint=ImageOps.colorize(ImageOps.grayscale(albedo),black="#383c36",mid="#929383",white="#d4cdb6")
    albedo=Image.blend(albedo,tint,.54)
    albedo.save(DEST/"lichen_and_stone.jpg",quality=95,subsampling=0)


def rock_meshes(path):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=str(path))
    parts=[o for o in bpy.context.scene.objects if o.type=="MESH"]
    if len(parts)==1:
        bpy.context.view_layer.objects.active=parts[0]
        bpy.ops.object.mode_set(mode="EDIT")
        bpy.ops.mesh.select_all(action="SELECT")
        bpy.ops.mesh.separate(type="LOOSE")
        bpy.ops.object.mode_set(mode="OBJECT")
        parts=[o for o in bpy.context.scene.objects if o.type=="MESH"]
    print("SCAN_OBJECTS",[(o.name,len(o.data.polygons)) for o in parts],flush=True)
    keep=[o for o in parts if len(o.data.polygons)>150]
    if len(keep)>6:
        finest=[o for o in keep if "lod" not in o.name.lower() or "lod0" in o.name.lower().replace("_","")]
        if len(finest)>=3: keep=finest
    keep=sorted(keep,key=lambda o:(-len(o.data.polygons),o.name))[:6]
    if len(keep)<3: raise ValueError("Expected several distinct scanned stones")
    bpy.ops.object.select_all(action="DESELECT")
    for i,obj in enumerate(keep):
        obj.data=obj.data.copy()
        world=obj.matrix_world.copy()
        obj.parent=None
        from mathutils import Matrix
        obj.matrix_world=Matrix.Identity(4)
        obj.data.transform(world)
        positions=[v.co for v in obj.data.vertices]
        lo=Vector([min(p[k] for p in positions) for k in range(3)])
        hi=Vector([max(p[k] for p in positions) for k in range(3)])
        root=(lo+hi)*.5
        root.z=lo.z
        span=max(hi.x-lo.x,hi.y-lo.y)
        for v in obj.data.vertices: v.co=(v.co-root)/span
        obj.name="RiverStone%02d"%i
        obj.data.name=obj.name
        obj.data.materials.clear()
        bpy.context.view_layer.objects.active=obj
        target=2200 if i<3 else 1250
        dec=obj.modifiers.new("Preserve scanned profile and texture seams","DECIMATE")
        dec.ratio=min(1.,target/len(obj.data.polygons))
        bpy.ops.object.modifier_apply(modifier=dec.name)
        print("RIVER_STONE",obj.name,len(obj.data.polygons),flush=True)
        obj.select_set(True)
    bpy.ops.export_scene.gltf(filepath=str(DEST/"bank_stones.glb"),export_format="GLB",use_selection=True,
        export_materials="NONE",export_texcoords=True,export_normals=True,export_yup=True,export_animations=False)


def gate_materials():
    original=json.loads((DEST/"source.json").read_text())
    for asset, key in (("medieval_blocks_03","foundation"),("patterned_clay_wall","rammed_earth")):
        listing=json.loads(fetch("https://api.polyhaven.com/files/"+asset))
        entry=listing["Diffuse"]["2k"]["jpg"] if "Diffuse" in listing else listing["diffuse"]["2k"]["jpg"]
        pic=Image.open(download(entry,CACHE/(asset+".jpg"))).convert("RGB")
        if min(pic.size)<2048: raise ValueError(pic.size)
        gray=ImageOps.grayscale(pic)
        gray=ImageOps.autocontrast(gray, cutoff=(1,2))
        if key=="foundation":
            tones=ImageOps.colorize(gray,black="#353939",mid="#848681",white="#b9b4a2")
            paint=Image.blend(tones,ImageEnhance.Color(pic).enhance(.4),.13)
        else:
            tones=ImageOps.colorize(gray,black="#675446",mid="#ad8768",white="#bf9c7f")
            paint=Image.blend(tones.filter(ImageFilter.GaussianBlur(1.35)),tones,.35)
        paint.save(DEST/(key+".jpg"),quality=95,subsampling=0)
        original[key]={"url":entry["url"],"md5":entry["md5"],"license":"CC0-1.0"}
    (DEST/"source.json").write_text(json.dumps(original,indent=2)+"\n")


src,colour=source_files()
mineral_paint(colour)
rock_meshes(src)
gate_materials()
