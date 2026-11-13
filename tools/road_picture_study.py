import base64
import json
from pathlib import Path

from PIL import Image, ImageChops, ImageStat

root = Path("proof")
states = [json.loads((root / side / "input.json").read_text()) for side in ("before", "after")]
assert states[0] == states[1] and len(states[0]) == 2, states
for row in states[0]:
    name = row["label"]
    shots = [Image.open(root / side / (name + ".png")).convert("RGB") for side in ("before", "after")]
    assert all(s.size == (1920, 1200) for s in shots)
    print("ROAD_WINDOW", name, json.dumps(row), ImageStat.Stat(ImageChops.difference(*shots)).mean)
    for part, box, width in (("full", (0, 0, 1920, 1200), 720), ("roadside", (660, 490, 1250, 1010), 590)):
        panes = [s.crop(box) for s in shots]
        dims = (width, round(width * panes[0].height / panes[0].width))
        pair = Image.new("RGB", (2 * dims[0], dims[1]))
        for i, pane in enumerate(panes):
            pair.paste(pane.resize(dims, Image.Resampling.LANCZOS), (i * dims[0], 0))
        target = root / (name + "-" + part + ".jpg")
        pair.save(target, quality=91)
        print("ROAD_PAIR", name + "-" + part, base64.b64encode(target.read_bytes()).decode())
