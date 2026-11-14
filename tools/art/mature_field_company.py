"""Build a complete field-person library from the verified, editable body and clothes.

HM08 forms the face, neck, forearm and leg surfaces. Wildfire's actual long
sleeve garments provide the complete dressed upper body. Previous tube bodies
and broad shoulder trim are absent from this library.
"""
import json
from pathlib import Path
import sys
import math
import numpy as np
from figure_atlas import NAMES, uv
from figure_mesh import Library, Surface
from refine_field_outfit import FieldSurface, subdivide, palette, align_neckline, collar_boundary, fit_under_collar
from import_garrison_issues import source_file, fit_garment
from fit_field_headwear import bake as helmet, FITS
from field_dress import player_half_mantle

ROOT=Path(__file__).resolve().parents[2]
MODELS={
    "cloth":("m_dress_sleeves","d5b93fcba83f3d2c2f96da0f323a67949452c9e0"),
    "armour":("m_armor_tunic_long_sleeves","25923b832db6b0e1d74d500997f0c3a857cbf370"),
}
ROLES={"Levy":("cloth","Archer",2,"Archer"),"Archer":("cloth","Archer",2,"Archer"),
       "Regular":("armour","Guard",0,"Regular"),"Guard":("armour","Guard",1,"Guard"),
       "Officer":("armour","Guard",1,"Officer"),"Player":("armour","Guard",1,"Officer")}

def append(target,source):
    offset=len(target.positions)
    target.positions.extend(source.positions);target.tex.extend(source.tex);target.joints.extend(source.joints)
    target.faces.extend(tuple(i+offset for i in f) for f in source.faces)
    for i,normal in enumerate(source.normals()): target.reference_normals[i+offset]=normal

def anatomical_body(look,tier,data,boundary):
    target=FieldSurface(tier=="Close")
    heavy=look in ("Regular","Guard","Officer","Player")
    for part in ("head","forearms","legs","feet"):
        mesh=data[part+tier];used={}
        positions=mesh["p"]
        if part=="head":
            positions=[]
            for point, chart in zip(mesh["p"],mesh["chart"]):
                p=list(point)
                jaw=max(0,min(1,(7.1-chart[1])/1.37))
                if look in ("Guard","Officer"): p[0]*=1.+.09*jaw
                elif look=="Levy": p[0]*=1.-.08*jaw
                positions.append(p)
            positions=fit_under_collar(positions,boundary)
        for face in mesh["f"]:
            pp=[mesh["p"][i] for i in face]
            x,y,z=(sum(p[k] for p in pp)/3 for k in range(3))
            chart=[mesh["chart"][i] for i in face]
            sx,sy,sz=(sum(p[k] for p in chart)/3 for k in range(3))
            if part=="head":
                angle=math.atan2(sx,sz-.35)
                brow=7.+.44*math.cos(angle)+.07*math.sin(angle+.4)
                if heavy and sy>brow+.10: continue
                if not heavy and sy>7.13+.33*math.cos(angle): continue
                material="visage"
            elif part=="forearms":
                # The new native long sleeve covers the upper forearm. Only
                # the hand transition can show; accurate held hands are separate.
                if not .935<y<1.12: continue
                material="skin" if y<.965 else "binding"
            elif part=="feet":
                if y>.16: continue
                material="boots"
            else:
                if not .135<y<.863: continue
                material="felt" if y>.35 else "binding"
            ids=[]
            for i in face:
                key=(i,material)
                if key not in used:
                    p=list(positions[i]);sx,sy,sz=mesh["chart"][i]
                    if part=="head":
                        jaw=max(0,min(1,(7.1-sy)/1.37))
                        coord=(4.+max(.012,min(.988,.5+sx/1.90))/8.,
                               (2.+max(.012,min(.988,(8.13-sy)/2.63)))/4.)
                    else:
                        # Continuous chart across the knee and ankle. A modulo
                        # chart stretched one triangle over the whole painted tile.
                        value=(p[1]-.135)/.728 if part=="legs" else (p[1]-.935)/.185 if part=="forearms" else (p[2]+.10)/.36
                        coord=uv(material,max(.08,min(.92,.5+(p[2]-.015)*3)),.08+.84*max(0.,min(1.,value)))
                    if part!="head" and material in ("binding","felt"):
                        coord=((5. if material=="binding" else 6.)+coord[0],coord[1])
                    used[key]=target.vertex(tuple(p),coord,tuple(mesh["w"][i]))
                    normal=np.asarray(mesh["n"][i],dtype=float)
                    if part=="head":
                        if look in ("Guard","Officer"): normal[0]/=1.+.09*jaw
                        elif look=="Levy": normal[0]/=1.-.08*jaw
                    normal/=max(1.e-12,np.linalg.norm(normal))
                    target.reference_normals[used[key]]=tuple(normal)
                ids.append(used[key])
            target.faces.append(tuple(ids))
    # Recompute only the fitted lower-neck normal field. The full original face
    # and ears retain their dense, smooth source normals.
    authored=target.reference_normals.copy()
    target.reference_normals={}
    fitted=target.normals()
    for i,p in enumerate(target.positions):
        if 4.<=target.tex[i][0]<5. and p[1]<1.525:
            authored[i]=fitted[i]
    target.reference_normals=authored
    return target

def main():
    cache=Path(sys.argv[1]);cache.mkdir(parents=True,exist_ok=True)
    data=json.loads(Path(__file__).with_name("source").joinpath("field_anatomy.json").read_text())
    library=Library()
    record={}
    paint=palette(cache,ROOT/"assets/third_party/wildfire_garments/field_colours.png")
    for look,(style,cut,slot,hat) in ROLES.items():
        model,sha=MODELS[style]
        cloth=fit_garment(source_file(cache,"meshes/skeletal/new/"+model+".dae",sha),cut,1 if look=="Regular" else slot)
        if look=="Regular":
            # Light and heavy corselets have their own published Han maps.
            cloth.tex=[(u-.5,v) if 2.5<u<3. else (u,v) for u,v in cloth.tex]
            cloth.positions=[(x*.967,y,z) for x,y,z in cloth.positions]
        align_neckline(cloth)
        rounded=subdivide(cloth)
        headgear=helmet(hat,FITS[hat],cache)
        headgear.positions=[(x*.86,1.725+(y-1.725)*.86,.015+(z-.015)*.89) for x,y,z in headgear.positions]
        for tier in ("Close","Line","Rank"):
            garment=cloth if tier=="Rank" else rounded
            boundary=collar_boundary(garment)
            body=anatomical_body(look,tier,data,boundary)
            append(body,garment);append(body,headgear)
            if look=="Player": player_half_mantle(body,rank=tier=="Rank")
            assert np.isfinite(body.positions).all(), (look,tier)
            library.insert(look+tier+"Master",body,check_tiles=False)
            record[look+tier]={"triangles":len(body.faces),"vertices":len(body.positions),"neckline":{"xz":boundary[0].tolist(),"top":boundary[1]}}
            print("COMPLETE_FIELD_PERSON",look,tier,record[look+tier],flush=True)
    dest=ROOT/"assets/river_gate/figures/field_company_master.glb"
    library.save(dest)
    (ROOT/"reports/hm08/master.json").write_text(json.dumps({"source":"MakeHuman HM08 and Wildfire long sleeve issues","roles":ROLES,"cost":record,"palette":paint},indent=2)+"\n")
if __name__=="__main__": main()
