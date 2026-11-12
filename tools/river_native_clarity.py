"""Compare normal-game moving frames against a spatially supersampled 3840x2400 capture."""
import hashlib
import json
import os
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

base = Path(os.environ["RAW"])
deliver = Path(os.environ["DELIVER"])
deliver.mkdir(parents=True, exist_ok=True)
ref = base / "3840-4"
scene_names = ["mounted", "contact"]
runs = {p.name: json.loads((p / "run.json").read_text()) for p in base.iterdir() if (p / "run.json").exists()}
reference = runs["3840-4"]
assert len(runs) == 7
provenance = {}
for key, r in sorted(runs.items()):
    assert not r["errors"] and r["renderer"] == "mobile"
    assert r["default"]["window"] == [r["width"], r["width"] * 5 // 8]
    assert r["default"]["msaa"] == 0 and r["default"]["resizable"] and r["default"]["hidpi"]
    for a, b in zip(reference["frames"], r["frames"], strict=True):
        assert a["ordinary"] == [512, 512] and a["shadow"] and r["default"]["scale"] == 1
        assert {k: v for k, v in a.items() if k not in ("size", "msaa")} == {k: v for k, v in b.items() if k not in ("size", "msaa")}, (key, a["scene"], a["frame"], [(k,a[k],b[k]) for k in a if a[k]!=b[k]])
        assert b["size"] == r["default"]["window"]
    provenance[key] = {k:r[k] for k in ["engine","driver","renderer","default","samples","width"]}

def image(path, box=None):
    with Image.open(path) as original:
        cut = original.crop(box) if box is not None else original
        return np.array(cut.convert("RGB"))

def reduce(a, n):
    h, w = a.shape[:2]
    return a.reshape(h//n, n, w//n, n, *a.shape[2:]).mean(axis=(1,3), dtype=np.float32)

def band(mask, dilate):
    operation = ImageFilter.MaxFilter(3) if dilate else ImageFilter.MinFilter(3)
    return np.asarray(Image.fromarray(mask.astype(np.uint8)*255).filter(operation)) > 0

def gradient(a):
    h = np.abs(np.diff(a,axis=1,prepend=a[:,:1])).mean(axis=2)
    v = np.abs(np.diff(a,axis=0,prepend=a[:1])).mean(axis=2)
    return (h+v)*.5

def mean(a, mask):
    assert mask.sum()>300
    return float(a[mask].mean())

def rounded(values):
    return {k:round(float(np.mean(x)),4) for k,x in values.items() if x}

scores = {}
for width in (1280,1920):
    height = width*5//8
    box = (width//4, height//4, width*3//4, height*3//4)
    scale = 3840//width
    ref_box = tuple(x*scale for x in box)
    for scene in scene_names:
        tracks={s:{"edge_error":[],"linear_edge_error":[],"object_detail_error":[],"object_detail_gradient":[],"reference_detail_gradient":[],"motion_edge_error":[],"band_pixels":[],"object_pixels":[]} for s in (0,2,4)}
        last, last_reference, last_edge = {}, None, None
        for i in range(5):
            name=f"{scene}-{i}"
            full=image(ref/f"{name}.png",ref_box)
            empty=image(ref/f"{name}-background.png",ref_box)
            high=full.astype(np.int16)
            reference_color=reduce(high,scale)
            # Compare both sRGB-area and linear-light area resolves on the same actor edges.
            s=full.astype(np.float32)/255.
            linear=np.where(s<=.04045,s/12.92,((s+.055)/1.055)**2.4)
            avg=reduce(linear,scale)
            linear_color=255*np.where(avg<=.0031308,12.92*avg,1.055*avg**(1/2.4)-.055)
            opacity=reduce(np.max(np.abs(high-empty.astype(np.int16)),axis=2)>12,scale)
            obj=opacity>.24
            edge=band(obj,True)&~band(obj,False)
            inside=band(band(opacity>.85,False),False)
            ref_grad=gradient(reference_color)
            for sample in (0,2,4):
                native=image(base/f"{width}-{sample}"/f"{name}.png",box).astype(np.float32)
                m=tracks[sample]
                m["edge_error"].append(mean(np.abs(native-reference_color),edge))
                m["linear_edge_error"].append(mean(np.abs(native-linear_color),edge))
                g=gradient(native)
                m["object_detail_error"].append(mean(np.abs(g-ref_grad),inside))
                m["object_detail_gradient"].append(mean(g,inside))
                m["reference_detail_gradient"].append(mean(ref_grad,inside))
                m["band_pixels"].append(int(edge.sum()))
                m["object_pixels"].append(int(inside.sum()))
                if last_reference is not None:
                    motion_delta=(native-last[sample])-(reference_color-last_reference)
                    m["motion_edge_error"].append(mean(np.abs(motion_delta),edge|last_edge))
                last[sample]=native
            last_reference,last_edge=reference_color,edge
        for sample in (0,2,4):
            data=tracks[sample]
            elapsed=np.array(runs[f"{width}-{sample}"]["timing_us"][scene])/1000.
            result=rounded(data)
            result.update({"samples":len(elapsed),"wall_p50_ms":round(float(np.percentile(elapsed,50)),3),"wall_p95_ms":round(float(np.percentile(elapsed,95)),3),"wall_p99_ms":round(float(np.percentile(elapsed,99)),3)})
            scores[f"{width}-{sample}-{scene}"]=result
            print("CLAR_SCORE",width,sample,scene,json.dumps(result),flush=True)
    for scene in scene_names:
        # Four side-by-side 1:1 center details: original, 2x, 4x, spatial reference.
        cw,ch= min(360,width//4), min(265,height//3)
        cx,cy=width//2,height//2-height//20
        crop=(cx-cw//2,cy-ch//2,cx-cw//2+cw,cy-ch//2+ch)
        contact=Image.new("RGB",(cw*2,ch*2+40),"#202020")
        draw=ImageDraw.Draw(contact)
        for j,sample in enumerate((0,2,4,"ref")):
            if sample=="ref":
                a=Image.fromarray(np.rint(reduce(image(ref/f"{scene}-1.png",tuple(x*scale for x in crop)),scale)).astype(np.uint8))
            else:
                a=Image.fromarray(image(base/f"{width}-{sample}"/f"{scene}-1.png",crop))
            x,y=(j%2)*cw,(j//2)*(ch+20)
            draw.text((x+5,y+3),["Shipped / no MSAA","Native 2x MSAA","Native 4x MSAA","3840 spatial reference"][j],fill="white")
            contact.paste(a,(x,y+20))
        contact.save(deliver/f"{scene}-{width}-crop.png")
for r in runs.values():
    for frame in r["frames"]:
        if frame["frame"]==1:
            name=f"{frame['scene']}-1.png"
            p=base/f"{r['width']}-{r['samples']}"/name
            frame["color_png_sha256"]=hashlib.sha256(p.read_bytes()).hexdigest()
report={"source":"2293008c2d76dcbd788aeaef0fb871de1bc8eee1","provenance":provenance,"scores":scores,
        "captures":{k:{x:r[x] for x in ("frames","timing_us")} for k,r in runs.items()},
        "description":"Public Ubuntu Xvfb / Mesa CPU Vulkan Mobile, 5 moving native PNG per view; exact matched simulation, 1:1 native. Actor coverage derived from an additional reference-only output with actors invisible. Edge and motion errors are RGB code-value MAE with lower better. Whole-frame hardware throughput from 30 samples per view after 12 warm; includes actual shadow and live simulation. This is not an Apple GPU benchmark."}
(deliver/"measurements.json").write_text(json.dumps(report,indent=2)+"\n")
