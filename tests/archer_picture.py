from pathlib import Path
import base64, io, json
from PIL import Image, ImageChops

root=Path("artifacts/archer")
before,after=[json.loads((root/s/"states.json").read_text()) for s in ("before","after")]
assert before==after and len(before)>=20
print("ARCHER_MATCH",len(before))
for tag in ("set","draw","draw-front","draw-back","draw-normal","ranks","loose"):
    row=next(r for r in before if r["frame"]==tag)
    pictures=[Image.open(root/s/(tag+".png")).convert("RGB") for s in ("before","after")]
    assert all(im.size==(1920,1200) for im in pictures) and row["ordinary"]==[512,512] and row["scale"]==1
    w,h=(650,466) if tag in ("ranks","draw-normal") else (470,370)
    x,y,xx,yy=map(round,row["post"])
    box=(x-w//2,(y+yy)//2-h//2,x+(w+1)//2,(y+yy)//2+(h+1)//2)
    crops=[im.crop(box) for im in pictures]
    diff=ImageChops.difference(*crops)
    assert diff.getbbox(),tag
    preview=Image.new("RGB",(w*2,h))
    for i,c in enumerate(crops):preview.paste(c,(i*w,0))
    preview.save(root/(tag+"-native-pair.jpg"),quality=94,subsampling=0)
    data=(root/(tag+"-native-pair.jpg")).read_bytes()
    print("ARCHER_PLATE",tag,len(data),base64.b64encode(data).decode())
    print("ARCHER_RECEIPT",json.dumps(row,separators=(",",":")))
