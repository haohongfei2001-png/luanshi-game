"""Reduce the CC0 HM08 head for the field rig. Run once to regenerate field_head.json.
The complete sculpt is an art-source input only. Normal asset builds use the checked-in patch.
"""
import hashlib
import json
from collections import defaultdict
from math import atan2, cos, floor, pi, sin, sqrt
from pathlib import Path
from urllib.request import urlopen

ROOT = "https://raw.githubusercontent.com/makehumancommunity/makehuman/a8bc2d54ff0ac92e78ff71431b1023eda42bf482/makehuman/data/"
def source(path, oid):
    with urlopen(ROOT + path, timeout=45) as response:
        data = response.read()
    assert hashlib.sha1(b"blob " + str(len(data)).encode() + b"\0" + data).hexdigest() == oid
    return data.decode().splitlines()

def remesh(points, faces, step):
    cells, lookup = {}, {}
    for index in sorted({q for face in faces for q in face}):
        x,y,z = points[index]
        # Keep the eyelids, cheek turning planes, nostrils and mouth corners in the close mesh.
        detail = step * (.61 if z > 1.04 and 6.03 < y < 7.26 else 1)
        key = (detail, round(x/detail), round(y/detail), round(z/detail))
        cells.setdefault(key, []).append(index)
        lookup[index] = key
    indices = {cell:i for i,cell in enumerate(cells)}
    vertices = [[round(sum(points[i][a] for i in group)/len(group),4) for a in range(3)] for group in cells.values()]
    triangles = []
    seen = set()
    for face in faces:
        ids = [indices[lookup[i]] for i in face]
        for j in range(1,len(ids)-1):
            tri = (ids[0],ids[j],ids[j+1])
            signature = tuple(sorted(tri))
            if len(set(tri)) == 3 and signature not in seen:
                triangles.append(tri)
                seen.add(signature)
    return dict(p=vertices, f=triangles)

def scalp_sections(points,faces):
    # Slice the actual cranium, then raycast each polygon edge in the cross section.
    # Caps, head wraps and the helmet share a fitted brow and nape on all five outfits.
    sections = []
    for row in range(22):
        y = 6.33 + row*.081
        edges=[]
        for face in faces:
            corners=[points[i] for i in face]
            if min(p[1] for p in corners)>y or max(p[1] for p in corners)<y: continue
            hits=[]
            for a,b in zip(corners,corners[1:]+corners[:1]):
                if (a[1]<=y<b[1]) or (b[1]<=y<a[1]):
                    t=(y-a[1])/(b[1]-a[1])
                    hits.append((a[0]+(b[0]-a[0])*t,a[2]+(b[2]-a[2])*t-.35))
            if len(hits)==2: edges.append(hits)
        radii=[]
        for col in range(32):
            angle=2*pi*col/32
            dx,dz=sin(angle),cos(angle)
            far=.03
            for (x,z),(ex,ez) in edges:
                ex-=x
                ez-=z
                denom=dx*ez-dz*ex
                if abs(denom)<1.e-8: continue
                t=(x*ez-z*ex)/denom
                u=(x*dz-z*dx)/denom
                if 0<=u<=1: far=max(far,t)
            radii.append(round(far,4))
        sections.append(radii)
    return sections

def main():
    vertices, faces, group = [], [], ""
    for line in source("3dobjs/base.obj", "d26635e9326e3cca30778fd7b9c00062b03cce09"):
        if line.startswith("v "): vertices.append(list(map(float,line.split()[1:4])))
        elif line.startswith("g "): group=line.split()[1]
        elif line.startswith("f ") and group=="body":
            faces.append([int(item.split("/")[0])-1 for item in line.split()[1:]])
    for row in source("targets/macrodetails/asian-male-young.target", "8cd3ef3e9ddb06ee2d166f75f9ac10871251f938"):
        if row and row[0].isdigit():
            index,*offset=row.split()
            p=vertices[int(index)]
            for a,d in enumerate(offset): p[a]+=float(d)
    head=[f for f in faces if all(vertices[i][1]>5.56 and abs(vertices[i][0])<.99 for i in f)]
    result={name:remesh(vertices,head,step) for name,step in (("close",.114),("line",.34))}
    result["scalp"]=scalp_sections(vertices,head)
    out=Path(__file__).with_name("field_head.json")
    out.write_text(json.dumps(result,separators=(",",":"))+"\n")
    print("FIELD_HEAD",[(n,len(result[n]["f"])) for n in ("close","line")],out.stat().st_size)
if __name__=="__main__":
    main()
