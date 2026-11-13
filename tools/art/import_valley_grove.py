"""Convert two licensed Quaternius CommonTree masters into the shared river-gate grove atlas.

Run in Blender's background Python. Geometry, split normals and leaf UVs come from the
published meshes. UV2 encodes the binding for the existing opaque and cutout batches.
"""
import argparse
import hashlib
import json
import sys
import tempfile
import zipfile
from pathlib import Path

import bpy

ARCHIVE_SHA256 = "298f6732b872e4cf7b30e6e7abf9641c7f6dc6b326df37ac089533ed7e3d58c9"
SOURCE = "https://store.godotengine.org/asset/quaternius/stylized-nature-megakit/download/31/"
CROWNS = (("CommonTree_1","Broad"), ("CommonTree_3","Upright"))

def sha(data):
    return hashlib.sha256(data).hexdigest()

def convert(archive, folder, output):
    license_text = archive.read("License_Standard.txt").decode("utf-8-sig")
    if "CC0" not in license_text and "public domain" not in license_text.lower():
        raise ValueError("Author license needs review")
    (output/"License_Standard.txt").write_bytes(archive.read("License_Standard.txt"))
    bpy.ops.wm.read_factory_settings(use_empty=True)
    exported = []
    manifest = {"author":"Quaternius","archive_url":SOURCE,"archive_sha256":ARCHIVE_SHA256,"members":{},"meshes":{}}
    for source, label in CROWNS:
        path = "glTF/" + source + ".gltf"
        gltf = json.loads(archive.read(path))
        members = {source+".gltf"} | {s["uri"] for s in gltf["buffers"]+gltf.get("images",[]) if "uri" in s}
        for member in sorted(members):
            data=archive.read("glTF/"+member)
            (folder/member).write_bytes(data)
            manifest["members"][member]=sha(data)
        bpy.ops.import_scene.gltf(filepath=str(folder/(source+".gltf")))
        imported=[o for o in bpy.context.selected_objects if o.type=="MESH"]
        if not imported:
            raise ValueError("No artist mesh in "+source)
        all_points=[o.matrix_world @ v.co for o in imported for v in o.data.vertices]
        low=min(p.z for p in all_points)
        height=max(p.z for p in all_points)-low
        for part in ("Bark","Foliage"):
            coords, faces, loop_uv, loop_normals, wind = [], [], [], [], []
            for obj in imported:
                mesh=obj.data
                mesh.calc_loop_triangles()
                if hasattr(mesh,"calc_normals_split"):
                    mesh.calc_normals_split()
                mapping={}
                normal_transform=obj.matrix_world.to_3x3().inverted().transposed()
                uv=mesh.uv_layers.active
                for tri in mesh.loop_triangles:
                    material=mesh.materials[tri.material_index]
                    textures=[n.image.name.lower() for n in material.node_tree.nodes if n.type=="TEX_IMAGE" and n.image] if material.use_nodes else []
                    leaves=any(any(part in t for part in ("leaf","leav","foliage")) for t in textures+[material.name.lower()])
                    if (part=="Foliage")!=leaves:
                        continue
                    face=[]
                    for i in tri.loops:
                        j=mesh.loops[i].vertex_index
                        v=obj.matrix_world @ mesh.vertices[j].co
                        if j not in mapping:
                            mapping[j]=len(coords)
                            coords.append((v.x/height,v.y/height,(v.z-low)/height))
                        face.append(mapping[j])
                        loop_uv.append(tuple(uv.data[i].uv))
                        norm=normal_transform @ mesh.loops[i].normal
                        loop_normals.append(tuple(norm.normalized()))
                        h=max(0.,min(1.,(v.z-low)/height))
                        # Godot's glTF importer preserves the exported second UV values.
                        wind.append((.40*h if leaves else 0.,1.-((12.1+.85*h) if leaves else 14.0)))
                    faces.append(face)
            if not faces:
                raise ValueError(f"{source} missing {part} using source material names")
            name=label+part
            mesh=bpy.data.meshes.new(name)
            mesh.from_pydata(coords, [], faces)
            mesh.update()
            uv0=mesh.uv_layers.new(name="Branch UV")
            uv1=mesh.uv_layers.new(name="Grove binding")
            for i,(uv,tag) in enumerate(zip(loop_uv,wind)):
                uv0.data[i].uv=uv
                uv1.data[i].uv=tag
            for poly in mesh.polygons: poly.use_smooth=True
            if hasattr(mesh,"use_auto_smooth"): mesh.use_auto_smooth=True
            mesh.normals_split_custom_set(loop_normals)
            obj=bpy.data.objects.new(name,mesh)
            bpy.context.collection.objects.link(obj)
            exported.append(obj)
            manifest["meshes"][name]={"vertices":len(coords),"triangles":len(faces),"source_height_m":round(height,5)}
        for obj in imported: bpy.data.objects.remove(obj,do_unlink=True)
    bpy.ops.object.select_all(action="DESELECT")
    for o in exported: o.select_set(True)
    bpy.context.view_layer.objects.active=exported[0]
    bpy.ops.export_scene.gltf(filepath=str(output/"grove.glb"),export_format="GLB",use_selection=True,export_texcoords=True,export_normals=True,export_materials="NONE",export_animations=False,export_yup=True)
    # The leaves already carry a clean transparent silhouette. Downsample bark only.
    for member,name in (("Leaves_NormalTree_C.png","leaves.png"),("Bark_NormalTree.png","bark.png")):
        raw=archive.read("glTF/"+member)
        manifest["members"][member]=sha(raw)
        (folder/member).write_bytes(raw)
        img=bpy.data.images.load(str(folder/member),check_existing=False)
        if max(img.size)>512:
            w,h=img.size[:]
            img.scale(round(w*512/max(w,h)),round(h*512/max(w,h)))
        img.filepath_raw=str(output/name)
        img.file_format="PNG"
        img.save()
        print("SOURCE_TEXTURE",member,tuple(img.size),img.channels,flush=True)
    (output/"sources.json").write_text(json.dumps(manifest,indent=2)+"\n")
    print("GROVE_SOURCE",json.dumps(manifest),flush=True)

if __name__=="__main__":
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument("archive",type=Path)
    parser.add_argument("output",type=Path)
    args=parser.parse_args(sys.argv[sys.argv.index("--")+1:])
    if sha(args.archive.read_bytes())!=ARCHIVE_SHA256: raise ValueError("Source archive SHA-256 changed")
    args.output.mkdir(parents=True,exist_ok=True)
    with tempfile.TemporaryDirectory() as path, zipfile.ZipFile(args.archive) as archive:
        convert(archive,Path(path),args.output.resolve())
