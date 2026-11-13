"""Map slow native frame intervals back to the raw tour and the active battle session."""
import hashlib
import json
from pathlib import Path
from statistics import median

sources = {"before": "c2acd067f30896e4a754c43093dd403b141c894d10256a402f5b65a753cb0726",
           "candidate": "869dcbeae4fc69281afae410958f16552a451efc41a32679969c762a1047ad7d",
           "main": "fc731015740403cddfb9c20d2a5309a6179df103f9857cebac8297014c5a7cc4"}
rows = {}
for label, checksum in sources.items():
    archive = Path(label + ".zip")
    assert hashlib.sha256(archive.read_bytes()).hexdigest() == checksum
    root = Path(label)
    capture = json.loads(next(root.rglob("shipping-metal-frames.json")).read_text())
    session = [json.loads(line) for line in next(root.rglob("shipping-metal-session.jsonl")).read_text().splitlines()]
    sessions = [s for s in session if s["kind"]=="frames"]
    frames = capture["raw_wall_ms"]
    assert len(frames) == capture["frames"]
    assert abs(max(frames)-capture["max_ms"]) < .002
    worst = sorted(range(len(frames)), key=frames.__getitem__, reverse=True)[:8]
    wall = 0.0
    ends = []
    for duration in frames:
        wall += duration
        ends.append(wall)
    # Bins are emitted immediately before the camera change. Zero-based index
    # equals the first interval whose start boundary follows that pan command.
    pans = [next(i+1 for i,w in enumerate(ends) if w>=1250)]
    counts = 0
    for b in capture["four_second_windows"]:
        counts += b["frames"]
        pans.append(counts)
    peaks=[]
    for i in worst:
        nearest = min(pans, key=lambda p:abs(p-i))
        nearest_session = min(((abs(x-frames[i]),s,k,x) for s in sessions for k,x in enumerate(s["raw_wall_ms"])),key=lambda m:m[0])
        difference, s, k, interval = nearest_session
        # Session logger observes a different callback. Only attach summary stats
        # for an isolated large interval with a close numerical match.
        linked = None
        ranked = sorted(v for u in sessions for v in u["raw_wall_ms"])
        if i==worst[0] and difference <= max(2.0,frames[i]*.02) and ranked[-1]-ranked[-2]>10:
            linked = {key:s.get(key) for key in ("start_tick","end_tick","camera_size","camera_travel","visible_soldiers","visible_combat_poses","sim_cpu_ms","view_script_ms","render_cpu","render_gpu","wall","hits_in_window")}
            linked.update(callback_ms=interval,interval_index_in_session_block=k)
        peaks.append({"frame_zero_based":i,"ms":frames[i],"wall_end_ms":round(ends[i],3),"nearest_pan_delta_frames":i-nearest,"nearest_pan_delta_wall_ms":round(ends[i]-ends[max(0,nearest-1)],3),"surrounding_median_ms":round(median(frames[max(0,i-5):i]+frames[i+1:i+6]),3),"session_candidate":linked})
    rows[label]={"adapter":capture["adapter"],"frames":len(frames),"fps":capture["fps"],"hits":capture["hits_in_window"],"p50":capture["p50_ms"],"p95":capture["p95_ms"],"p99":capture["p99_ms"],"max":capture["max_ms"],"over_50_ms":sum(x>50 for x in frames),"over_100_ms":sum(x>100 for x in frames),"pan_indices":pans,"peaks":peaks,"session_peak":max(max(s["raw_wall_ms"]) for s in sessions)}
print("NATIVE_TAIL_REVIEW",json.dumps(rows,separators=(",",":")))
Path("tail-context.json").write_text(json.dumps(rows,indent=2)+"\n")
