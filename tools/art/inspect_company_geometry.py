"""Read exact imported GLB index counts and report whole assembled fighters."""
import hashlib
import json
import os
from pathlib import Path
import struct
import subprocess

FILES=(
    "assets/river_gate/figures/field_company_master.glb",
    "assets/river_gate/figures/river_company.glb",
    "assets/river_gate/equipment/field_equipment.glb",
    "assets/third_party/wildfire_shields/garrison_shield.glb",
)
def main():
    meshes={}
    sources=[]
    for name in FILES:
        data=Path(name).read_bytes()
        assert data[:4]==b"glTF"
        length,kind=struct.unpack_from("<II",data,12)
        assert kind==0x4E4F534A
        gltf=json.loads(data[20:20+length])
        for mesh in gltf["meshes"]:
            triangles=0
            vertices=0
            for primitive in mesh["primitives"]:
                assert primitive.get("mode",4)==4
                vertices+=gltf["accessors"][primitive["attributes"]["POSITION"]]["count"]
                count=gltf["accessors"][primitive["indices"]]["count"]
                assert count%3==0
                triangles+=count//3
            meshes[mesh["name"]]={"triangles":triangles,"vertices":vertices}
        sources.append({"path":name,"sha256":hashlib.sha256(data).hexdigest(),
                        "git_blob":subprocess.check_output(["git","hash-object",name],text=True).strip()})
    rows=[]
    for role in ("Levy","Regular","Archer","Guard","Officer","Player"):
        for tier in ("Close","Line","Rank"):
            body=meshes[role+tier+"Master"]
            for kit in range(9):
                arms=meshes[("FieldArms" if kit in (0,1,3,7,8) else "Arms")+str(kit)+tier]
                shield=meshes["GarrisonShield"] if kit==7 else {"triangles":0,"vertices":0}
                rows.append({"role":role,"tier":tier,"kit":kit,
                             "body_triangles":body["triangles"],"held_triangles":arms["triangles"]+shield["triangles"],
                             "total_triangles":body["triangles"]+arms["triangles"]+shield["triangles"],
                             "total_vertices":body["vertices"]+arms["vertices"]+shield["vertices"]})
    out=Path("docs/evidence/river-gate-v1-rc23/native-chain/company-geometry.json")
    out.write_text(json.dumps({"source":os.environ.get("GITHUB_SHA"),"units":"one assembled fighter, one geometry submission, excludes multipass/shadows",
                              "files":sources,"parts":meshes,"assembled":rows},indent=2)+"\n")
    print("COMPANY_GEOMETRY",json.dumps({"files":sources,"bodies":{k:v for k,v in meshes.items() if k.endswith("Master")}}))

if __name__=="__main__": main()
