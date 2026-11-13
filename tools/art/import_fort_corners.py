#!/usr/bin/env python3
"""Fit the four river fort corner towers to the existing masonry and camera cut."""
from pathlib import Path
import sys
import numpy as np
from import_river_gatehouse import read_frame, OUT
from import_garrison_issues import source_file
from figure_mesh import Library

SOURCE=("meshes/structural/han_wall_tower.dae","c6b08f0b6c6d366518efd533b3c71aab86ec1534")

def frame(point):
    x,y,z=point
    # Wall-walk height is set by the actual assault ramp. Broader eaves
    # project over the walk without enlarging the base at a player's feet.
    zs=[-4.,0.,9.7,14.8,19.8,24.0]
    height=np.interp(z,zs,[-1.05,0.,3.40,5.52,7.43,8.58])
    t=float(np.clip((z-9.6)/5.6,0.,1.))
    ease=t*t*(3.-2.*t)
    return np.array([-y*(.325+.305*ease),height,x*(.447+.180*ease)])

def add_mesh(lib,label,triangles,positions,normals,transforms,uv):
    out=[];directions=[];tex=[];ids=[];used={}
    for face in triangles:
        for pi,ni,ui in face[[0,2,1]]:
            key=(int(pi),int(ni),int(ui))
            if key not in used:
                used[key]=len(out)
                normal=transforms[pi]@normals[ni]
                directions.append(normal/max(np.linalg.norm(normal),1e-12))
                out.append(positions[pi])
                tex.append((uv[ui,0],1.-uv[ui,1]))
            ids.append((used[key],))
    assert out
    attr={"POSITION":lib.accessor(out,"f",3,True),"NORMAL":lib.accessor(directions,"f",3),"TEXCOORD_0":lib.accessor(tex,"f",2)}
    ix=lib.accessor(ids,"H",1)
    index=len(lib.doc["meshes"])
    lib.doc["meshes"].append({"name":label,"primitives":[{"attributes":attr,"indices":ix}]})
    lib.doc["nodes"].append({"mesh":index,"name":label})
    lib.doc["scenes"][0]["nodes"].append(index)
    print("FORT_CORNER",label,len(ids)//3,np.min(out,axis=0).round(3),np.max(out,axis=0).round(3))

def court_house(lib, cache, label, path, sha, eave, width, depth, height):
    """Keep whole roof assemblies when the player's camera passes the building."""
    points,normals,uv,tris=read_frame(source_file(cache,path,sha))
    floor=(points.min(axis=0)+points.max(axis=0))*.5
    scale=np.array([width/np.ptp(points[:,0]),depth/np.ptp(points[:,1]),height/points[:,2].max()])
    # Align the long frontage with the existing barrack footprint. This axis
    # conversion is left-handed, as for the tower and adjacent curtain wall.
    fitted=(points-np.array([floor[0],floor[1],0.]))*scale
    fitted=fitted[:,[0,2,1]]
    inverse=np.diag(1./scale)[[0,2,1]]
    transforms=np.broadcast_to(inverse,(len(points),3,3))

    # A connected pitch may span many tile rows. Classifying its triangles
    # independently would leave floating roof tips after the sightline opens.
    parents=list(range(len(tris)))
    def root(i):
        while i!=parents[i]:
            parents[i]=parents[parents[i]]
            i=parents[i]
        return i
    welds={}
    for face_id,face in enumerate(tris):
        for vertex in points[face[:,0]]:
            key=tuple(np.rint(vertex*1000).astype(int))
            prior=welds.setdefault(key,face_id)
            parents[root(face_id)]=root(prior)
    pieces={}
    for index,face in enumerate(tris):
        pieces.setdefault(root(index),[]).append(face)
    masonry=[]
    roof=[]
    for faces in pieces.values():
        low=points[np.array(faces)[:,:,0],2].min()
        (roof if low>=eave else masonry).extend(faces)
    assert len(roof)>150 and len(masonry)>250
    for part,faces in (("Room",masonry),("Roof",roof)):
        add_mesh(lib,label+part,faces,fitted,normals,transforms,uv)

def main(cache):
    p,n,uv,tri=read_frame(source_file(cache,*SOURCE))
    assert len(tri)==1702
    fitted=np.array([frame(q) for q in p])
    basis=np.eye(3)*.001
    inverse=[np.linalg.inv(np.column_stack([(frame(q+s)-frame(q-s))/.002 for s in basis])).T for q in p]
    lib=Library()
    faces={"CornerBatter":[],"CornerGallery":[]}
    for t in tri:
        h=p[t[:,0],2]
        faces["CornerBatter" if h.max()<10.4 or (h.min()<9.2 and h.mean()<10.0) else "CornerGallery"].append(t)
    for label,triangles in faces.items():
        add_mesh(lib,label,triangles,fitted,n,inverse,uv)
    p,n,uv,tri=read_frame(source_file(cache,"meshes/structural/han_wall_medium.dae",
                                     "2fae82ec78965c6978a2b6db91c041b2d4f14ef9"))
    assert len(tri)==967
    width=np.ptp(p[:,0])
    centre=(p[:,0].min()+p[:,0].max())*.5
    # A single module between the corner footings is twenty metres long.
    # Its upper walk matches the existing playable surface at 3.25 metres.
    z_breaks=[-5.,0.,8.1,9.5,13.]
    heights=[-1.40,.0,3.25,3.49,4.32]
    fit_wall=lambda v: np.array([-v[1]*.331,np.interp(v[2],z_breaks,heights),(v[0]-centre)*20./width])
    fitted=np.array([fit_wall(q) for q in p])
    inverse=[np.linalg.inv(np.column_stack([(fit_wall(q+s)-fit_wall(q-s))/.002 for s in basis])).T for q in p]
    add_mesh(lib,"CurtainWalk",tri,fitted,n,inverse,uv)
    court_house(lib,cache,"Quarters","meshes/structural/han_house_a.dae",
               "a40e59244e5a8ab346f0821044d9f0705d70e9c4",5.0,8.60,6.00,4.35)
    court_house(lib,cache,"Stores","meshes/structural/han_storehouse.dae",
               "bf371be5bf5a5fdca0c81687021ae618d2b13ed3",4.55,8.45,6.02,5.28)
    lib.save(OUT/"corner_tower.glb")

if __name__=="__main__":
    cache=Path(sys.argv[1])
    cache.mkdir(parents=True,exist_ok=True)
    main(cache)
