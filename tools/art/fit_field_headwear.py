#!/usr/bin/env python3
"""Fit four author-released Wildfire Games pieces onto the river-company skull.

The separate glTF contains only headwear. Faces, hands, weapons, body, and their
licences stay in their existing resources. Character forward is positive Z.
"""
from pathlib import Path
import sys
import xml.etree.ElementTree as ET

import numpy as np

from figure_atlas import uv
from figure_mesh import Library, Surface
from import_garrison_issues import ROOT, source_file

HEAD = 2
# Width/depth scale, height scale and offset line the original brow against
# the HM08 skull. Furthest straps are allowed to drape behind the ear.
FITS = {
    "Archer": ("han_cap", "75a7918c2a4bf09350e58768ea5bb8d270900440", (.463,.347,.443), 1.514, .005),
    "Regular": ("han_advanced_melee_helmet", "63317077bf5a080f1459e4691bb0b84a5903e9b8", (.566,.312,.483), 1.539, -.020),
    "Guard": ("han_officer_helmet_01", "4cff639c3aa31c468c9f6fc4adac7593ca68d0cf", (.495,.378,.460), 1.529, -.008),
    "Officer": ("han_heavy_helmet_b", "cc4c7d741eeca408d7a6e7d3fd6a44386be69f7d", (.549,.376,.501), 1.509, -.007),
}

def source_mesh(path):
    root=ET.parse(path).getroot()
    for node in root.iter():
        node.tag=node.tag.rsplit("}",1)[-1]
    geo=root.find(".//library_geometries/geometry")
    mesh=geo.find("mesh")
    ids={s.get("id"):s for s in mesh.findall("source")}
    pos=mesh.find("vertices/input[@semantic='POSITION']").get("source")[1:]
    points=np.fromstring(ids[pos].findtext("float_array"),sep=" ").reshape((-1,3))
    node=next(n for n in root.findall(".//visual_scene//node") if n.find("instance_geometry") is not None and n.find("instance_geometry").get("url")=="#"+geo.get("id"))
    transform=np.fromstring(node.findtext("matrix"),sep=" ").reshape((4,4))
    world=points @ transform[:3,:3].T + transform[:3,3]
    # Exactly the same handedness conversion as the equipped Wildfire tunic.
    points=np.column_stack((-world[:,0],world[:,2],-world[:,1]))
    triangles=[]
    for prim in list(mesh.findall("triangles"))+list(mesh.findall("polylist")):
        stride=1+max(int(e.get("offset")) for e in prim.findall("input"))
        offset=int(prim.find("input[@semantic='VERTEX']").get("offset"))
        rings=np.fromstring(prim.findtext("p"),sep=" ",dtype=int).reshape((-1,stride))[:,offset]
        counts=([3]*int(prim.get("count")) if prim.tag=="triangles" else
                np.fromstring(prim.findtext("vcount"),sep=" ",dtype=int))
        cursor=0
        for count in counts:
            for i in range(1,count-1):
                triangles.append((rings[cursor],rings[cursor+i+1],rings[cursor+i]))
            cursor+=count
        assert cursor==len(rings)
    return points,triangles

def garment_material(role,p):
    x,h,z=p
    if role=="Archer":
        if h<.32: return "felt"
        if h<.465: return "facing"
        return "felt"
    if role=="Regular":
        if h<.306: return "felt"
        if h<.399: return "iron_binding"
        return "iron"
    if role=="Guard":
        if h<.038: return "binding"
        if h<.288: return "lames"
        if h<.383: return "iron_binding"
        return "iron"
    if h>.75: return "sash"
    if h<.305: return "lames"
    if h<.401: return "iron_binding"
    return "black_iron"

def bake(role,item,cache):
    original,signature,scale,bind_y,bind_z=item
    points,triangles=source_mesh(source_file(cache,"meshes/props/helmet/"+original+".dae",signature))
    surface=Surface()
    vertices={}
    for face in triangles:
        section=garment_material(role,np.mean(points[list(face)],axis=0))
        ids=[]
        for i in face:
            key=(i,section)
            if key not in vertices:
                x,h,z=points[i]
                # The officer's original hair brush is kept a short, tied knot
                # laying backward, not a pair of needle-like helmet spikes.
                if role=="Officer" and h>.66:
                    above=h-.66
                    z-=.79*above
                    h=.66+.51*above
                fitted=(x*scale[0],bind_y+h*scale[1],bind_z+z*scale[2])
                # Registered swatches retain large sections of matte iron and
                # cloth, contiguous across welded geometry and all LODs.
                coord=uv(section,float(np.clip(.5+x*.80,.17,.83)),float(np.clip(.52-h*.54,.17,.83)))
                vertices[key]=surface.vertex(fitted,coord,HEAD)
            ids.append(vertices[key])
        surface.faces.append(tuple(ids))
    bounds=np.asarray(surface.positions)
    assert .084<max(abs(bounds[:,0]))<.16
    assert 1.45<min(bounds[:,1])<1.63 and 1.71<max(bounds[:,1])<1.865
    print("HEADWEAR",role,len(triangles),bounds.min(axis=0),bounds.max(axis=0))
    return surface

def main():
    cache=Path(sys.argv[1])
    cache.mkdir(parents=True,exist_ok=True)
    lib=Library()
    for role,item in FITS.items():
        lib.insert(role+"Headwear",bake(role,item,cache))
    destination=ROOT/"assets/third_party/wildfire_headwear/headwear.glb"
    destination.parent.mkdir(parents=True,exist_ok=True)
    lib.save(destination)

if __name__=="__main__":
    main()
