"""Fit Rob Tuytel's CC0 plaster scan to the existing warm gate facing."""
from pathlib import Path
import json,sys
import numpy as np
from PIL import Image,ImageFilter
from bake_gate_apron import DEST,scan

def bake(cache):
    cache.mkdir(parents=True,exist_ok=True)
    receipt=json.loads((DEST/"source.json").read_text())
    image=Image.fromarray(scan("plastered_wall_03",cache,receipt))
    rgb=np.asarray(Image.blend(image.filter(ImageFilter.GaussianBlur(1.2)),image,.65),dtype=np.float32)/255.
    value=rgb@np.array([.27,.58,.15],dtype=np.float32)
    lo,hi=np.quantile(value,[.015,.985])
    t=np.clip((value-lo)/max(hi-lo,.1),0.,1.)
    deep=np.array([.340,.285,.204]);light=np.array([.608,.493,.343])
    color=deep+(light-deep)*t[:,:,None]
    Image.fromarray(np.rint(np.clip(color,0,1)*255).astype("uint8")).save(DEST/"rammed_earth.jpg",quality=95,subsampling=0)
    receipt["plastered_wall_03"].update(author="Rob Tuytel",output="rammed_earth.jpg",operation="warm earth palette, fine scanned relief retained")
    (DEST/"source.json").write_text(json.dumps(receipt,indent=2)+"\n")
    print("GATE_PLASTER",image.size,receipt["plastered_wall_03"]["md5"])
if __name__=="__main__":bake(Path(sys.argv[1]))
