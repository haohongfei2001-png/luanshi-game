from pathlib import Path
import base64,json
from PIL import Image,ImageChops
root=Path("artifacts/hands")
def pair(tag, sides, point, w, h):
    images=[Image.open(s).convert("RGB") for s in sides]
    assert images[0].size==images[1].size==(1920,1200)
    x,y=map(round,point)
    region=(x-w//2,y-h//2,x+w//2,y+h//2)
    crops=[im.crop(region) for im in images]
    changes=ImageChops.difference(*crops).getbbox()
    out=Image.new("RGB",(w*2,h))
    for i,c in enumerate(crops):out.paste(c,(w*i,0))
    path=root/(tag+".jpg")
    out.save(path,quality=96,subsampling=0)
    data=path.read_bytes()
    print("HAND_PLATE",tag,len(data),base64.b64encode(data).decode())
    print("HANDS_PIXEL_CHANGE",tag,changes)
    assert changes is not None or tag=='ranks'
dirs=[root/s/'bow' for s in ('before','after')]
old,new=[json.loads((d/'states.json').read_text()) for d in dirs]
assert old==new and len(old)>25
for tag in ('set','fingers','fingers-side','draw-front','draw-normal','loose','ranks','enemy-haft'):
    r=next(r for r in old if r['frame']==tag)
    x,y,xx,yy=r['post']
    print("HANDS_BOW_MATCH",json.dumps(r,separators=(',',':')))
    size={'draw-normal':(390,272),'ranks':(480,312),'fingers':(540,330),'fingers-side':(540,330)}.get(tag,(432,300))
    pair(tag,[d/(tag+'.png') for d in dirs],((x+xx)/2,.52*y+.48*yy),*size)
for lens in (22,8):
    dirs=[root/s/str(lens) for s in ('before','after')]
    a,b=[json.loads((d/'input.json').read_text()) for d in dirs]
    assert a==b and a[-1]['foe_hp']<a[-1]['previous_foe_hp']
    for r in a:
        tag=r['label'];x,y,xx,yy=r['on_screen']
        pair(f'{lens}m-'+tag,[d/(tag+'.png') for d in dirs],((x+xx)*.75,(y+yy)*.75),414 if lens==22 else 494,278 if lens==22 else 336)
        print('HANDS_SPEAR_MATCH',json.dumps(r,separators=(',',':')))
