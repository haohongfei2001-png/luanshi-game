"""Review real full-resolution game output; the archived PNG crops are never resampled."""
import base64, io, json
from pathlib import Path
from PIL import Image

root=Path("receipts")
records=[json.loads((root/side/"frames.json").read_text()) for side in ("rc4","field")]
assert len(records[0])==len(records[1])==7
for left,right in zip(*records):
    for key in ("label","tick","window","zoom","center","yaw","ordinary","contact","losses","in_frame_ids_sha256"):
        assert left[key]==right[key],(key,left,right)
    name=left["label"]
    frames=[Image.open(root/side/(name+".png")).convert("RGB") for side in ("rc4","field")]
    assert frames[0].size==frames[1].size==(1600,1000)
    box=(562,277,1038,671)
    pair=Image.new("RGB",(2*(box[2]-box[0]),box[3]-box[1]))
    for i,p in enumerate(frames):
        pair.paste(p.crop(box),(i*(box[2]-box[0]),0))
    pair.save(root/(name+"-crop.png"))
    if name in ("hero","contact","officer","follow"):
        preview=io.BytesIO()
        pair.save(preview,"WEBP",quality=92)
        print("ARMOUR_VISUAL_"+name,base64.b64encode(preview.getvalue()).decode())
print("ARMOUR_PAIR_PASS",len(records[0]))
