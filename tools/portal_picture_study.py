import base64, json
from pathlib import Path
from PIL import Image, ImageChops
from io import BytesIO

root=Path("proof")
stages=("survey","approach","threshold","gallery","broken")
a,b=[json.loads((root/d/"frames.json").read_text()) for d in ("before","after")]
for i,label in enumerate(stages):
    assert a[i]==b[i], [(k,a[i][k],b[i][k]) for k in a[i] if a[i][k]!=b[i][k]]
    frames=[Image.open(root/d/(label+".png")).convert("RGB") for d in ("before","after")]
    assert all(im.size==(1920,1200) for im in frames)
    box=ImageChops.difference(*frames).getbbox()
    def emit(name,picture):
        buf=BytesIO()
        picture.save(buf,"JPEG",quality=85)
        print("PORTAL_PREVIEW",name,base64.b64encode(buf.getvalue()).decode())
    print("PORTAL_CAMERA",label,a[i]["tick"],a[i]["zoom"],a[i]["ordinary"],a[i]["contact"],a[i]["losses"],box)
    out=Image.new("RGB",(1440,450))
    for j,im in enumerate(frames):
        out.paste(im.resize((720,450),Image.Resampling.LANCZOS),(720*j,0))
    out.save(root/(label+"-pair.jpg"),quality=93)
    emit(label,out)
    if label=="survey":
        emit("survey-new",frames[1].resize((1280,800),Image.Resampling.LANCZOS))
