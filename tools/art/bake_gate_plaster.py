"""Bake the licensed fine lime/earth plaster into the gate's existing UV projection."""
from pathlib import Path
import hashlib,json,sys
from urllib.request import urlopen
import numpy as np
from PIL import Image,ImageFilter
ROOT=Path(__file__).resolve().parents[2]
DEST=ROOT/"assets/third_party/polyhaven_bank"
def bake(cache):
    cache.mkdir(parents=True,exist_ok=True)
    asset="plastered_wall_03"
    with urlopen("https://api.polyhaven.com/files/"+asset,timeout=45) as response:
        files=json.load(response)
    item=files["diff"]["2k"]["jpg"]
    path=cache/"plastered_wall_03.jpg"
    if not path.exists() or hashlib.md5(path.read_bytes()).hexdigest()!=item["md5"]:
        with urlopen(item["url"],timeout=60) as response:
            path.write_bytes(response.read())
    assert hashlib.md5(path.read_bytes()).hexdigest()==item["md5"]
    image=Image.open(path).convert("RGB")
    assert image.size==(2048,2048),image.size
    rgb=np.asarray(Image.blend(image.filter(ImageFilter.GaussianBlur(1.2)),image,.65),dtype=np.float32)/255.
    value=rgb@np.array([.27,.58,.15],dtype=np.float32)
    lo,hi=np.quantile(value,[.015,.985])
    t=np.clip((value-lo)/max(hi-lo,.1),0.,1.)
    deep=np.array([.340,.285,.204]);light=np.array([.608,.493,.343])
    color=deep+(light-deep)*t[:,:,None]
    Image.fromarray(np.rint(np.clip(color,0,1)*255).astype("uint8")).save(DEST/"rammed_earth.jpg",quality=95,subsampling=0)
    receipt=json.loads((DEST/"source.json").read_text())
    receipt["gate_plaster"]={"asset":asset,"author":"Rob Tuytel","license":"CC0-1.0","source":item["url"],"md5":item["md5"],"output":"rammed_earth.jpg","operation":"warm earth palette, fine scanned relief preserved in albedo"}
    (DEST/"source.json").write_text(json.dumps(receipt,indent=2)+"\n")
    print("GATE_PLASTER",image.size,item["md5"])
if __name__=="__main__":bake(Path(sys.argv[1]))
