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

def exterior(points,triangles,role):
    # Some artist meshes have complete coincident inward and outward walls.
    # The river shader draws both sides. Remove reversed twins before computing
    # normals or the two normals cancel and produce black blotches on the brow.
    center=np.array([0.,.39,.043]) if role!="Archer" else np.array([0.,.47,.026])
    faces={}
    for f in triangles:
        p=points[list(f)]
        signature=tuple(sorted(tuple(x) for x in p.round(5)))
        normal=np.cross(p[1]-p[0],p[2]-p[0])
        facing=float(normal @ (p.mean(axis=0)-center))
        if signature not in faces or facing>faces[signature][0]:
            faces[signature]=(facing,f)
    clean=[f for _,f in faces.values()]
    removed=len(triangles)-len(clean)
    print("COINCIDENT_HEAD_FACES_REMOVED",role,removed)
    if role=="Regular": assert removed==84
    if role=="Officer": assert removed>=32
    return clean

def bound(role,x,h,z,scale,bind_y,bind_z):
    # Work with the original brow/hem rings and cheek/nape silhouettes. The
    # annular binding sits away from the forehead and extends across the brow.
    if role=="Regular":
        edge=np.exp(-((h-.373)/.064)**2)
        x*=1.+.13*edge
        z+=edge*(.090*max(0.,(z+.12)/.482)-.022)
        h-=.125*max(0.,h-.39)
    elif role=="Guard":
        skirt=float(np.clip((.39-h)/.50,0.,1.))
        front=max(0.,z/.38)
        x*=1.+.095*skirt
        # Clear the forward cheeks and hang a flared lower edge over the nape.
        h+=.152*skirt*front**1.6
        z-=.089*skirt*(.33+max(0.,-z/.22))
        z+=.077*np.exp(-((h-.363)/.052)**2)*front
        h-=.066*max(0.,h-.38)
    elif role=="Archer":
        roll=np.exp(-((h-.457)/.061)**2)
        x*=1.+.11*roll
        z+=.019*roll*(z-.025)/.30
        gathered=max(0.,(h-.46)/.186)
        x-=.038*gathered
        z-=.082*gathered
        h-=.053*gathered
    elif role=="Officer":
        brim=np.exp(-((h-.414)/.068)**2)
        x*=1.+.17*brim
        z+=.061*brim*max(0.,(z+.11)/.43)
        if h>.66:
            above=h-.66
            z-=.79*above
            h=.66+.51*above
    return (x*scale[0],bind_y+h*scale[1],bind_z+z*scale[2])

def garment_material(role,p):
    x,h,z=p
    if role=="Archer":
        if h<.39: return "leather"
        if h<.50: return "facing"
        return "coat"
    if role=="Regular":
        if h<.306: return "felt"
        if h<.421: return "iron_binding"
        return "iron"
    if role=="Guard":
        if h<.040: return "binding"
        if h<.272: return "lames"
        if h<.395: return "iron_binding"
        return "black_iron"
    if h>.75: return "sash"
    if h<.305: return "lames"
    if h<.401: return "iron_binding"
    return "black_iron"

def bake(role,item,cache):
    original,signature,scale,bind_y,bind_z=item
    points,triangles=source_mesh(source_file(cache,"meshes/props/helmet/"+original+".dae",signature))
    triangles=exterior(points,triangles,role)
    surface=Surface()
    vertices={}
    for face in triangles:
        section=garment_material(role,np.mean(points[list(face)],axis=0))
        ids=[]
        for i in face:
            key=(i,section)
            if key not in vertices:
                x,h,z=points[i]
                fitted=bound(role,x,h,z,scale,bind_y,bind_z)
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
