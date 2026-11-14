"""Read one CC0 timber scan and register individual strips to the real transverse planks."""
from pathlib import Path
import json,sys
import numpy as np
from PIL import Image,ImageFilter
from bake_gate_apron import DEST,scan

def bake(cache):
    capture=json.loads((DEST/"source.json").read_text())
    raw=scan("wood_planks",cache,capture).astype("float32")/255.
    y=raw@np.array([.30,.56,.14],dtype="float32")
    # Seams make rows or columns persistently dark across the whole image.
    # Reorient to rows; select their interiors, never paint a second fake
    # plank seam inside the true bevel of a modelled board.
    row_curve=np.percentile(y,40,axis=1)
    col_curve=np.percentile(y,40,axis=0)
    if np.percentile(col_curve,85)-np.percentile(col_curve,5)>np.percentile(row_curve,85)-np.percentile(row_curve,5):
        raw=np.swapaxes(raw,0,1);y=y.T
    line=np.convolve(np.quantile(y,.40,axis=1),np.full(9,1/9),mode="same")
    candidates=[]
    for i in np.argsort(line[20:-20])+20:
        if all(abs(i-s)>100 for s in candidates):
            candidates.append(i)
        if len(candidates)>=11: break
    edges=sorted([0,*candidates,len(line)-1])
    strips=sorted(zip(edges,edges[1:]),key=lambda z:z[1]-z[0],reverse=True)[:8]
    size=2048
    tile_height=128
    atlas=Image.new("RGB",(size,tile_height*len(strips)))
    for i,(start,end) in enumerate(strips):
        pad=max(4,int((end-start)*.15))
        row=raw[start+pad:end-pad]
        lum=row@np.array([.30,.56,.14],dtype="float32")
        low,high=np.quantile(lum,[.015,.99])
        val=np.clip((lum-low)/max(high-low,.12),0.,1.)
        dark=np.array([.265,.222,.175]); mid=np.array([.536,.469,.376]); light=np.array([.722,.634,.501])
        tone=dark+np.minimum(val[:,:,None]*2.,1.)*(mid-dark)+np.maximum(val[:,:,None]*2.-1.,0.)*(light-mid)
        tone*=.94+.02*(i%5)
        image=Image.fromarray((np.clip(tone,0,1)*255).astype("uint8"))
        image=image.resize((size,tile_height-8),Image.Resampling.LANCZOS)
        band=np.pad(np.asarray(image),((4,4),(0,0),(0,0)),mode="edge")
        atlas.paste(Image.fromarray(band),(0,i*tile_height))
    atlas.save(DEST/"bridge_oak.jpg",quality=95,subsampling=0)
    (DEST/"source.json").write_text(json.dumps(capture,indent=2)+"\n")
    print("BRIDGE_OAK",atlas.size,strips)
if __name__=="__main__": bake(Path(sys.argv[1]))
