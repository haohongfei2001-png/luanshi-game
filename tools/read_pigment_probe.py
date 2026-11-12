import base64, io, json, pathlib
import numpy as np
from PIL import Image, ImageDraw
root=pathlib.Path("receipts")
methods=["gl_compatibility","mobile"]
views=["gate","bridge","camp"]
def load(side,renderer,name):
    return np.asarray(Image.open(root/side/renderer/(name+".png")).convert("RGB"),dtype=np.int16)
report={}
for view in views:
    paths=[(side,method) for side in ("before","after") for method in methods]
    raw={key:load(*key,view) for key in paths}
    mask={key:load(*key,view+"-ids") for key in paths}
    pose=[]
    for side,method in paths:
        trace=json.loads((root/side/method/"frames.json").read_text())
        pose.append(next(row for row in trace if row["label"]==view))
    check=("center","yaw","zoom","tick","ordinary","seed","contact","losses","gate_hp","in_frame_count","in_frame_ids_sha256","window","internal_scale","shadows")
    assert all(all(row[k]==pose[0][k] for k in check) for row in pose[1:])
    facts={}
    for index,role in enumerate(("timber","masonry","roof")):
        other=[j for j in range(3) if j!=index]
        zones=[(a[:,:,index]>245)&(a[:,:,other[0]]<8)&(a[:,:,other[1]]<8) for a in mask.values()]
        valid=zones[0]&zones[1]&zones[2]&zones[3]
        # Exclude changing silhouettes and the material-ID antialiasing fringe.
        padded=np.pad(valid,1)
        for dy,dx in ((0,1),(2,1),(1,0),(1,2)):
            valid=valid&padded[dy:dy+valid.shape[0],dx:dx+valid.shape[1]]
        if valid.sum()<120: continue
        ref=raw[("before","gl_compatibility")][valid]
        sample={}
        for side,method in paths:
            patch=raw[(side,method)][valid]
            sample[side+"_"+method]={"median_rgb":np.median(patch,axis=0).round(2).tolist(),"mean_abs_rgb_error_to_opengl":round(float(np.abs(patch-ref).mean()),3)}
        facts[role]={"pixels":int(valid.sum()),"samples":sample}
    assert facts
    report[view]={"combat":pose[0],"groups":facts}
    print("MATERIAL_READBACK",view,json.dumps(facts,separators=(",",":")))
    tile=Image.new("RGB",(1280,800))
    for i,key in enumerate(paths):
        frame=Image.fromarray(raw[key].astype("uint8")).resize((640,400),Image.Resampling.LANCZOS)
        canvas=ImageDraw.Draw(frame)
        canvas.rectangle((0,373,222,399), fill="black")
        canvas.text((7,380),key[0]+" / "+key[1],fill="white")
        tile.paste(frame,((i%2)*640,(i//2)*400))
    tile.save(root/(view+"-backends.jpg"),quality=91)
    if view=="gate":
        preview=io.BytesIO()
        tile.thumbnail((960,600))
        tile.save(preview,format="JPEG",quality=79)
        coded=base64.b64encode(preview.getvalue()).decode()
        for idx in range(0,len(coded),14000): print("MATERIAL_GATE_JPEG",idx//14000,coded[idx:idx+14000])
(root/"material-readback.json").write_text(json.dumps(report,indent=2)+"\n")
