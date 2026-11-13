"""Verify and present two copies of the same Godot input recording under different uniforms."""
import base64
import io
import json
import os
from pathlib import Path
import re

from PIL import Image, ImageChops

root=Path('artifacts/tailoring')
sides=['before','after']
for view in ('follow','actors'):
    if view=='follow':
        runs=[json.loads((root/s/'follow'/'trajectory.json').read_text()) for s in sides]
        assert len(runs[0])>=40 and runs[0]==runs[1]
    else:
        runs=[json.loads((root/s/'actors'/'receipts.json').read_text()) for s in sides]
        assert len(runs[0])==12 and runs[0]==runs[1]
        assert all(t['ordinary']==[512,512] and t['seed']==61112 for t in runs[0])
        print('TAIL_ROSTER',[(t['label'],t['actor'],t['lod'],t['tick'],t['seen']) for t in runs[0]])
    print('TAIL_MATCH',view,len(runs[0]))
inputs=[json.loads((root/s/'contact'/'input.json').read_text()) for s in sides]
assert inputs[0]==inputs[1] and all(c['follow'] and c['lens']==22 and c['ordinary']==[512,512] for c in inputs[0])
print('TAIL_INPUT',json.dumps(inputs[0]))
def emit(name,image):
    im=image.convert('RGB')
    im.save(root/(name+'.jpg'),quality=94,subsampling=0)
    out=io.BytesIO()
    im.thumbnail((1360,1020),Image.Resampling.LANCZOS)
    im.save(out,'JPEG',quality=89,subsampling=0)
    print('TAIL_IMAGE',name,base64.b64encode(out.getvalue()).decode())

def side_by_side(panels):
    w,h=panels[0].size
    result=Image.new('RGB',(w*len(panels),h))
    for i,p in enumerate(panels):result.paste(p,(w*i,0))
    return result

states=[json.loads((root/s/'actors'/'receipts.json').read_text()) for s in sides]
for side in sides:
    im=Image.open(root/side/'follow'/'snapshot-036.png')
    assert im.size==(1920,1200)
    emit('full-follow-'+side,im)
for target in ('spear-front','spear-back','spear-22m','spear-42m','shield-front','shield-back','shield-22m','spear-return'):
    halves=[]
    for i,side in enumerate(sides):
        record=next(r for r in states[i] if r['label']==target)
        im=Image.open(root/side/'actors'/(target+'.png'))
        assert im.size==(1920,1200)
        x,y=map(round,record['head'])
        width,height=(320,344) if record['camera'][0]<10 else (480,390)
        xy=(x-width//2,y-height//3)
        halves.append(im.crop(xy+(xy[0]+width,xy[1]+height)))
    out=side_by_side(halves)
    emit(target,out)
    print('TAIL_DELTA',target,ImageChops.difference(*halves).getbbox())
for side in sides:
    im=Image.open(root/side/'actors'/'spear-line.png')
    emit('full-line-'+side,im)
portraits=[]
for side in sides:
    portraits.append(Image.open(root/side/'guard-aperture.png'))
    log=(root/(side+'-face.log')).read_text()
    print('TAIL_PORTRAIT',side,re.search(r'^FIELD_PORTRAIT (\{.*\})$',log,re.M)[1])
emit('portrait',side_by_side(portraits))
assert (root/'after-face.exit').read_text().strip()=='0','candidate failed original portrait'
