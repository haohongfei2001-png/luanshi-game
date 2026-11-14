"""Fit complete licensed field weapons to the existing human hand and motion bank.

The original mesh and matching native UV artwork remain paired. The three
source masters cover jian, dao and spear, including both sword hands and shield
sword. Existing staff, long blade, bow and crossbow are retained until their own
full source and animation review is complete.
"""
from pathlib import Path
import json,sys
import numpy as np
from PIL import Image
from figure_mesh import Library,Surface
from company_figures import grip,RH,LH
from hand_grips import field_hands
from import_garrison_issues import source_file,UPSTREAM
from import_river_gatehouse import read_frame

ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/"assets/river_gate/equipment"
MASTERS={
    "jian":("sword/weap_han_sword_a.dae","90d53cd94266ef5e7a113ee5a56ddbd7c1ce5a24"),
    "dao":("sword/weap_han_curved_dao.dae","f69c96bfb58280752b09279e1b4eb00094a024d8"),
    "spear":("spear/weap_han_standard_spear.dae","49277a13b8fe00a58e684be16e59a4ee36909e09"),
}
PAINT=("textures/skins/props/prop_weap.dds","0d1e7d24f2c436f7721c0860b692ba55d5ef8348")

def main(cache):
    cache.mkdir(parents=True,exist_ok=True)
    OUT.mkdir(parents=True,exist_ok=True)
    Image.open(source_file(cache,*PAINT)).convert("RGB").save(OUT/"native_iron_wood.png")
    loaded={}
    records=[]
    for name,(path,sha) in MASTERS.items():
        loaded[name]=read_frame(source_file(cache,"meshes/props/weapons/"+path,sha))
    library=Library()
    for kit in (0,1,3,7,8):
        name="spear" if kit==3 else ("dao" if kit==1 else "jian")
        original,normals,uv,faces=loaded[name]
        length=float(np.ptp(original[:,2]))
        target=2.749 if kit==3 else (1.01 if kit==8 else 1.25)
        scale=target/length
        offset=-.715-float(original[:,2].min())*scale if kit==3 else 0.
        for lod in ("Close","Line","Rank"):
            hands=Surface(lod=="Close")
            field_hands(hands,kit,lod)
            positions=list(hands.positions)
            directions=hands.normals()
            tex=list(hands.tex)
            joints=list(hands.joints)
            triangles=list(hands.faces)
            for side in ((-1,1) if kit==8 else (1,)):
                socket=np.asarray(grip(side))
                fitted=original*scale+socket
                fitted[:,2]+=offset
                bound=RH if side>0 else LH
                found={}
                for face in faces:
                    ids=[]
                    for pi,ni,ti in face:
                        key=(int(pi),int(ni),int(ti))
                        if key not in found:
                            found[key]=len(positions)
                            positions.append(tuple(fitted[pi]))
                            normal=normals[ni]
                            directions.append(tuple(normal/max(float(np.linalg.norm(normal)),1.e-9)))
                            # Panel 38 reserves an independent material atlas. Padding
                            # prevents the edge of a source UV from selecting panel 39.
                            tex.append((8.+float(np.clip(uv[ti,0],.00001,.99999)),
                                        float(np.clip(1.-uv[ti,1],.00001,.99999))))
                            joints.append(((bound*32+bound+.5)/1024.,1.))
                        ids.append(found[key])
                    triangles.append(tuple(ids))
                record={"kit":kit,"lod":lod,"master":name,"source":MASTERS[name][0],"source_blob":MASTERS[name][1],
                        "shaft_axis":"+Z","scale":scale,"hand_offset":offset,
                        "weapon_bounds":[fitted.min(axis=0).tolist(),fitted.max(axis=0).tolist()]}
                records.append(record)
            assert len(positions)<65536
            assert np.isfinite(np.asarray(positions)).all()
            mesh_name="FieldArms%d%s"%(kit,lod)
            attrs={"POSITION":library.accessor(positions,"f",3,True),
                   "NORMAL":library.accessor(directions,"f",3),
                   "TEXCOORD_0":library.accessor(tex,"f",2),
                   "TEXCOORD_1":library.accessor(joints,"f",2)}
            index=library.accessor([(i,) for face in triangles for i in face],"H",1)
            number=len(library.doc["meshes"])
            library.doc["meshes"].append({"name":mesh_name,"primitives":[{"attributes":attrs,"indices":index}]})
            library.doc["nodes"].append({"name":mesh_name,"mesh":number})
            library.doc["scenes"][0]["nodes"].append(number)
            print("FIELD_EQUIPMENT",mesh_name,len(triangles),flush=True)
    library.save(OUT/"field_equipment.glb")
    (OUT/"SOURCE.json").write_text(json.dumps({"upstream":UPSTREAM,"license":"CC BY-SA 3.0",
        "authors":"Wildfire Games contributors","texture":PAINT,"records":records},indent=2)+"\n")
    (OUT/"NOTICE.txt").write_text("Complete jian, curved dao and spear masters and prop_weap artwork by Wildfire Games contributors, from 0 A.D.\n"
        "https://github.com/0ad/0ad/tree/"+UPSTREAM+"/binaries/data/mods/public/art\n"
        "CC BY-SA 3.0 https://creativecommons.org/licenses/by-sa/3.0/\n"
        "Derived hand registration, shader joint encoding and atlas conversion are distributed under the same license. "
        "The original hand meshes retain their separate licenses in tools/art/source/README.md. See SOURCE.json for exact inputs.\n")
if __name__=="__main__":main(Path(sys.argv[1]))
