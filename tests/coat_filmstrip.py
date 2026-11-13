import base64
from pathlib import Path
from PIL import Image
root=Path('artifacts/coat')
files=[sorted((root/s/'motion').glob('*.jpg')) for s in ('before','after')]
assert len(files[0])==len(files[1]) and len(files[0])>=4
steps=[0,len(files[0])//3,len(files[0])*2//3,len(files[0])-1]
w,h=244,160
out=Image.new('RGB',(w*len(steps),h*2))
for side in (0,1):
    for col,i in enumerate(steps):
        frame=Image.open(files[side][i]).convert('RGB')
        assert frame.size==(960,600)
        out.paste(frame.crop((492-w//2,287-h//2,492+w//2,287+h//2)),(col*w,side*h))
path=root/'motion.jpg';out.save(path,quality=95,subsampling=0)
data=path.read_bytes()
print('COAT_PLATE',path.name,len(data),base64.b64encode(data).decode())
