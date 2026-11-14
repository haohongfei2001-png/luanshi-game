from pathlib import Path
from PIL import Image, ImageChops
import json
import sys

p=Path(sys.argv[1])
old,new=[json.loads((p/side/"views.json").read_text()) for side in ("before","after")]
assert old==new and len(new)==16
stats=[]
for row in new:
    label=row["tag"]
    frames=[Image.open(p/s/(label+".jpg")).convert("RGB") for s in ("before","after")]
    assert row["screen"]==[1600,1000] and row["scale"]==1 and row["ordinary"]==[512,512] and row["hit"]
    x,y=map(round,row["xy"])
    size={"hand":(430,360),"officer":(420,332),"normal":(218,164),"ranks":(168,138)}[label.split("-")[1]]
    w,h=size
    crop=(x-w//2,y-h//2,x+(w-w//2),y+(h-h//2))
    tiles=[im.crop(crop) for im in frames]
    # Use native pixels with no sharpening or contrast change.
    sheet=Image.new("RGB",(2*w,h));sheet.paste(tiles[0],(0,0));sheet.paste(tiles[1],(w,0))
    sheet.save(p/(label+"-pair.jpg"),quality=96,subsampling=0)
    diff=ImageChops.difference(*tiles)
    pixels=sum(max(rgb)>10 for rgb in diff.getdata())
    stats.append(dict(tag=label,delta=pixels,crop=crop))
assert any(s["delta"]>220 for s in stats if "-hand-" in s["tag"]),stats
(p/"visible-change.json").write_text(json.dumps(stats,indent=2)+"\n")
print("SHIELD_WINDOW_PAIRS",stats)
