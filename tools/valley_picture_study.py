import base64
import json
from pathlib import Path

from PIL import Image, ImageChops, ImageStat

root = Path("proof")
for record in ("input.json", "valley/frames.json"):
    before, after = [json.loads((root / side / record).read_text()) for side in ("before", "after")]
    assert before == after and len(before) in (2, 6), (record, before, after)
    for item in after:
        key = item["label"]
        subdir = Path(record).parent
        pair = []
        for side in ("before", "after"):
            raw = Image.open(root / side / subdir / (key + ".png")).convert("RGB")
            assert raw.size == (1920, 1200)
            pair.append(raw)
        delta = ImageStat.Stat(ImageChops.difference(*pair)).mean
        print("VALLEY_WINDOW", key, [round(x, 3) for x in delta], json.dumps(item))
        contact = Image.new("RGB", (1440, 450))
        for i, raw in enumerate(pair):
            contact.paste(raw.resize((720,450), Image.Resampling.LANCZOS), (i*720,0))
        for suffix, pic in (("pair", contact), ("window", pair[1].resize((1280,800), Image.Resampling.LANCZOS))):
            path = root / (key+"-"+suffix+".jpg")
            pic.save(path, quality=86)
            payload = base64.b64encode(path.read_bytes()).decode()
            print("VALLEY_INFO", key+"-"+suffix, len(payload))
            for offset in range(0, len(payload), 7200):
                print("VALLEY_PART", key+"-"+suffix, offset, payload[offset:offset+7200])
