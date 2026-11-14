"""Bake a continuous 4K dirt apron from two CC0 surface scans in metre coordinates."""
import hashlib
from pathlib import Path
import json
import sys
import urllib.request

import numpy as np
from PIL import Image

ROOT=Path(__file__).resolve().parents[2]
DEST=ROOT/"assets/third_party/polyhaven_bank"


def scan(asset,cache,receipt):
    headers={"User-Agent":"Luanshi-River-Art/1.0 (github.com/haohongfei2001-png/luanshi-game)"}
    def read(url):
        with urllib.request.urlopen(urllib.request.Request(url,headers=headers),timeout=75) as response:
            return response.read()
    manifest=json.loads(read("https://api.polyhaven.com/files/"+asset))
    entry=next(v for k,v in manifest.items() if k.lower()=="diffuse")["2k"]["jpg"]
    p=cache/(asset+".jpg")
    if not p.exists() or hashlib.md5(p.read_bytes()).hexdigest()!=entry["md5"]:
        data=read(entry["url"])
        if hashlib.md5(data).hexdigest()!=entry["md5"]: raise ValueError(asset)
        p.write_bytes(data)
    im=Image.open(p).convert("RGB")
    if min(im.size)<2048: raise ValueError(im.size)
    receipt[asset]={"source":entry["url"],"md5":entry["md5"],"license":"CC0-1.0"}
    return np.asarray(im)


def tile(pic,x,z):
    # Mutually prime frequencies and metre-scale distortion keep tile edges
    # invisible. Integer texel footprints are native to the downstream bake.
    h,w=pic.shape[:2]
    i=np.floor(x*w).astype("int32")%w
    j=np.floor(z*h).astype("int32")%h
    return pic[j,i].astype("float32")/255.


def apron(cache):
    receipt=json.loads((DEST/"source.json").read_text())
    dust=scan("brown_mud_dry",cache,receipt)
    grit=scan("sandy_gravel_02",cache,receipt)
    size=(4096,2160)
    im=Image.new("RGB",size)
    x=14.+(np.arange(size[0],dtype="float32")[None,:]+.5)*36./size[0]
    weights=np.array([.27,.58,.15],dtype="float32")
    grooves=[(-3.65, .13, .35),(-1.21,.13,1.),(1.21,.105,.96),(3.18,.15,.38)]
    for row in range(0,size[1],96):
        end=min(size[1],row+96)
        z=-9.5+(np.arange(row,end,dtype="float32")[:,None]+.5)*19./size[1]
        drift=.23*np.sin(x*.27)+.17*np.sin(x*.54+.4)+.085*np.sin(x*1.18)
        bend=.17*np.sin(z*.67+x*.24)+.27*np.sin(z*.32-x*.17)
        loam=tile(dust,x*.20+z*.087+bend*.09,z*.23-x*.049+drift*.13)@weights
        rocks=tile(grit,x*.37-z*.11+drift*.04,z*.344+x*.076+bend*.03)@weights
        fine=tile(dust,x*.86+z*.18,z*.89-x*.17)@weights
        fleck=np.clip((rocks-.32)*1.9,0,1)
        band=np.clip(.47+.23*np.sin(.33*x+.41*z)+.17*np.sin(x*.47-z*.67+1.4)+.11*np.sin(x*.88+z*.19),0.,1.)
        tone=.60*(loam-.45)+.19*(fine-.43)+.24*(rocks-.47)*band
        pigment=np.stack([.58+tone*.90,.487+tone*.87,.377+tone*.75],axis=-1)
        for lateral,width,strength in grooves:
            offset=z-lateral-drift*(1.+.09*lateral)-.11*np.sin(x*.36+lateral)
            wear=(.55+.45*band)*strength
            cut=np.exp(-np.square(offset/width))
            bank=np.exp(-np.square((offset-width*1.6)/(width*.85)))
            pigment+=(-.10*cut+.049*bank)[:,:,None]*wear[:,:,None]
        # A chamber approach has coarse gravel concentrated in separated fans;
        # the travelled centre reads as one lighter plane beneath the feet.
        verge=np.clip((np.abs(z-drift)-2.65)/3.6,0.,1.)
        pigment+=(.072*(fleck-.45)*(.3+verge)*band)[:,:,None]
        im.paste(Image.fromarray(np.rint(np.clip(pigment,0.,1.)*255).astype("uint8")),(0,row))
    im.save(DEST/"forecourt.jpg",quality=94,subsampling=0)
    (DEST/"source.json").write_text(json.dumps(receipt,indent=2)+"\n")

if __name__=="__main__": apron(Path(sys.argv[1]))
