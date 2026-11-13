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
        out=[];directions=[];tex=[];ids=[];used={}
        for face in triangles:
            for pi,ni,ui in face[[0,2,1]]:
                key=(int(pi),int(ni),int(ui))
                if key not in used:
                    used[key]=len(out)
                    normal=inverse[pi]@n[ni]
                    directions.append(normal/max(np.linalg.norm(normal),1e-12))
                    out.append(fitted[pi])
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
    lib.save(OUT/"corner_tower.glb")

if __name__=="__main__":
    cache=Path(sys.argv[1])
    cache.mkdir(parents=True,exist_ok=True)
    main(cache)
