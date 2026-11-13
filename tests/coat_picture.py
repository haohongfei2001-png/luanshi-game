from pathlib import Path
import base64, json
from PIL import Image, ImageChops

root=Path("artifacts/coat")
for lens in (22, 12, 8):
    sides=[root/side/str(lens) for side in ("before","after")]
    before,after=[json.loads((side/"input.json").read_text()) for side in sides]
    assert before==after and len(before)==2,(lens,before,after)
    for row in before:
        assert row["ordinary"]==[512,512] and row["lens"]==lens and row["follow"]
        assert row["screen"]==[1920,1200] and row["internal_scale"]==1, row
        tag=row["label"]
        if tag=="personal-contact": assert row["foe_hp"]<row["previous_foe_hp"] and row["hero_hits"]>0
        shots=[Image.open(side/(tag+".png")).convert("RGB") for side in sides]
        x,y,xx,yy=row["on_screen"]
        cx,cy=round((x+xx)*.5),round((y+yy)*.5)
        w,h={22:(390,272),12:(450,312),8:(510,374)}[lens]
        crop=[im.crop((cx-w//2,cy-h//2,cx+w//2,cy+h//2)) for im in shots]
        assert ImageChops.difference(*crop).getbbox(),(lens,tag)
        pair=Image.new("RGB",(2*w,h))
        for i,image in enumerate(crop): pair.paste(image,(i*w,0))
        path=root/f"{lens}m-{tag}-native.jpg"
        pair.save(path,quality=96,subsampling=0)
        printed=path.read_bytes()
        print("COAT_PLATE",path.name,len(printed),base64.b64encode(printed).decode())
        print("COAT_MATCH",lens,json.dumps(row,separators=(",",":")))
