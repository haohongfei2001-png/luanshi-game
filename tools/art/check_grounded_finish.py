"""Measure actual baked corpse joints and shell vertices, not a posed still."""
import argparse,json,struct
from pathlib import Path
from math import dist
from PIL import Image
from check_company_motion import decoded
from company_motion import CLIPS,FRAMES,trans
from figure_atlas import NAMES

def unpack(path):
    raw=path.read_bytes()
    length=struct.unpack_from("<I",raw,12)[0]
    doc=json.loads(raw[20:20+length])
    base=28+length
    def arr(index):
        a=doc["accessors"][index]
        bv=doc["bufferViews"][a["bufferView"]]
        n={"VEC2":2,"VEC3":3,"SCALAR":1}[a["type"]]
        ty="f" if a["componentType"]==5126 else "H"
        off=base+bv.get("byteOffset",0)+a.get("byteOffset",0)
        return [v for v in struct.iter_unpack("<"+ty*n,raw[off:off+struct.calcsize(ty)*n*a["count"]])]
    result={}
    for m in doc["meshes"]:
        part=m["primitives"][0]["attributes"]
        result[m["name"]]=list(zip(arr(part["POSITION"]),arr(part["TEXCOORD_0"]),arr(part["TEXCOORD_1"])))
    return result

def measurements(bank,library,bodies):
    rows=[]
    for kit in range(9):
        role="Archer" if kit in (5,6) else "Regular" if kit in (1,3) else "Guard" if kit in (4,7) else "Levy"
        values={key:[] for key in ("skull","trunk","boots")}
        joints=[decoded(bank,i,kit,14,FRAMES-1) for i in range(16)]
        source=bodies[role+"CloseBody"] if role+"CloseBody" in bodies else library[role+"Close"]
        garment=library[role+"Close"]
        # Trunk on the original sewn body, skull and boots from the actor
        # actually drawn. Both use exactly the same weighted bone matrices.
        for group,mesh in (("body",source),("trunk",garment)):
            for p,uv,skin in mesh:
                idx=int(uv[0]*8)+8*int(uv[1]*4)
                mat=NAMES[idx]
                k=int(skin[0]*1024)
                a,b=k//32,k%32
                if group=="trunk":
                    if not (1.06<p[1]<1.414 and abs(p[0])<.189 and mat in ("coat","quilt","dyed","linen","lamellar","lames")): continue
                    tag="trunk"
                elif mat=="boots": tag="boots"
                elif p[1]>1.49 and a==2 and mat in ("skin","visage","hair","felt","black_iron"): tag="skull"
                else: continue
                ya,yb=trans(joints[a],p)[1],trans(joints[b],p)[1]
                values[tag].append(yb+(ya-yb)*skin[1])
        row={}
        for tag,x in values.items():
            row[tag]=[round(min(x),4),round(max(x),4)]
        row["ankles_m"]=[round(trans(joints[b],(side*.141,.123,-.016))[1],4) for b,side in ((11,-1),(14,1))]
        row["chest_m"]=round(trans(joints[1],(0,1.28,0))[1],4)
        row["kit"]=kit
        rows.append(row)
    return rows

if __name__=="__main__":
    cli=argparse.ArgumentParser()
    cli.add_argument("baseline",type=Path);cli.add_argument("output",type=Path)
    args=cli.parse_args()
    root=Path(__file__).resolve().parents[2]/"assets/river_gate/figures"
    before=Image.open(args.baseline).convert("RGBA")
    after=Image.open(root/"company_motion.png").convert("RGBA")
    changes=[]
    for lane in range(after.height//4):
        box=(0,lane*4,before.width,(lane+1)*4)
        if before.crop(box).tobytes()!=after.crop(box).tobytes(): changes.append(lane)
    assert changes==[i*CLIPS+14 for i in range(9)],changes
    lib=unpack(root/"river_company.glb");lo=unpack(root/"garrison_bodies.glb")
    old=measurements(before,lib,lo);new=measurements(after,lib,lo)
    result={"changed_lanes":changes,"other_lanes_unchanged":after.height//4-9,"before":old,"after":new}
    args.output.write_text(json.dumps(result,indent=2))
    print("GROUND_REST_PROBES",json.dumps(result))
    for row in new:
        for foot in row["ankles_m"]: assert .035<foot<.17,row
        assert .04<row["chest_m"]<.35,row
        for part in ("skull","trunk","boots"):
            assert -.075<row[part][0]<.13 and row[part][1]<.51,(part,row)
