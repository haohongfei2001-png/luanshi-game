"""Inspect the licensed complete HM08 body before retargeting a game garment."""
import json
from pathlib import Path
import sys
sys.path.insert(0,"tools/art")
from fetch_hand_source import main as fetch
from reduce_field_head import source
import numpy as np
folder=Path("/tmp/river-hm08")
sys.argv=["fetch",str(folder)]
fetch()
points=[]
faces=[]
group=""
for line in (folder/"base.obj").read_text().splitlines():
    if line.startswith("v "): points.append(list(map(float,line.split()[1:])))
    elif line.startswith("g "): group=line[2:]
    elif group=="body" and line.startswith("f "): faces.append([int(s.split("/")[0])-1 for s in line.split()[1:]])
p=np.array(points)
for line in source("targets/macrodetails/asian-male-young.target","8cd3ef3e9ddb06ee2d166f75f9ac10871251f938"):
    if line and line[0].isdigit():
        i,*d=line.split()
        p[int(i)]+=np.array(d,dtype=float)
rig=json.loads((folder/"default.mhskel").read_text())
def at(bone,end):
    return p[rig["joints"][rig["bones"][bone][end]]].mean(axis=0)
selected=[k for k in rig["bones"] if k in ["head","neck01","neck03","root","spine01","spine05"] or k.split(".")[0] in ["shoulder01","upperarm01","lowerarm01","wrist","upperleg01","lowerleg01","foot"]]
bounds=p[sorted({i for f in faces for i in f})]
receipt={"points":len(p),"body_faces":len(faces),"bounds":[bounds.min(axis=0).tolist(),bounds.max(axis=0).tolist()],"joints":{k:{e:at(k,e).tolist() for e in ("head","tail")} for k in selected}}
Path("reports/hm08").mkdir(parents=True,exist_ok=True)
Path("reports/hm08/bind.json").write_text(json.dumps(receipt,indent=2)+"\n")
print(json.dumps(receipt,indent=2))
