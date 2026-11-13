#!/usr/bin/env python3
"""Read wall frames from the real Apple-hosted export and separate pan windows from quiet frames."""
import json, math, statistics, sys
from pathlib import Path

def groups(frames, windows):
    pos=0
    for sample in windows:
        size=sample["frames"]
        yield pos, pos+size, sample
        pos+=size
    if pos<len(frames): yield pos,len(frames),{}

def stats(bag):
    if not bag: return {}
    x=sorted(bag)
    return {"n":len(x),"average_ms":round(statistics.mean(x),3),"p95_ms":round(x[math.ceil(.95*len(x))-1],3),"p99_ms":round(x[math.ceil(.99*len(x))-1],3),"over_16_67":sum(i>16.67 for i in x),"over_33_33":sum(i>33.33 for i in x),"over_50":sum(i>50 for i in x),"max_ms":max(x)}

def crunch(root):
    filename,=Path(root).rglob("shipping-metal-frames.json")
    raw=json.loads(filename.read_text())
    frames=raw["raw_wall_ms"]; wins=raw["four_second_windows"]
    assert len(frames)==raw["frames"] and raw["hits_in_window"]>0 and raw["per_side"]==512
    # Sample spans immediately after scripted camera changes (initial 1.25s
    # and recorded four-second boundaries), without claiming they caused a spike.
    t=0.; times=[]
    for v in frames: t+=v; times.append(t)
    cuts=[1250.]+[times[b-1] for a,b,w in groups(frames,wins) if w]
    post=[any(0 <= stamp-c < 250 for c in cuts) for stamp in times]
    records=[]
    for a,b,w in groups(frames,wins):
        records.append({"first_frame":a,"after_frame":b,"tick_at_end":w.get("tick"),"visible_at_end":w.get("visible"),"new_hits":w.get("hits"),**stats(frames[a:b])})
    session,=Path(root).rglob("shipping-metal-session.jsonl")
    buckets=[j for l in session.read_text().splitlines() if (j:=json.loads(l)).get("kind")=="frames"]
    return {"platform":raw["processor"],"renderer":raw["renderer"],"target":raw["render_target_px"],
        "full":stats(frames),"first_250ms_after_pan":stats([x for x,b in zip(frames,post) if b]),
        "other_frames":stats([x for x,b in zip(frames,post) if not b]),"windows":records,
        "render_cpu_p95_ms":raw.get("render_cpu_p95_ms"),"render_gpu_p95_ms":raw.get("render_gpu_p95_ms"),
        "simulation_cpu_mean_ms":raw.get("sim_cpu_ms_per_frame"),"presentation_cpu_mean_ms":raw.get("view_script_ms_per_frame"),
        "max_examples":[{"frame":i,"elapsed_ms":round(times[i],1),"wall_ms":frames[i],"after_pan":post[i]} for i in sorted(range(len(frames)),key=lambda i:-frames[i])[:8]],
        "session_groups":len(buckets),"session_group_fields":sorted({k for j in buckets for k in j})}
if __name__=="__main__":
    print("TAIL_FROM_NATIVE "+json.dumps({p:crunch(p) for p in sys.argv[1:]},separators=(",",":")),flush=True)
