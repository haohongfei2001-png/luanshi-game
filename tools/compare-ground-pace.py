"""Compare the actual battle's time and state at two army sizes on the same hosted CPU."""
import json
import math
from pathlib import Path
import shutil
import statistics
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]
GROUND = Path("scripts/field/ground.gd")
DRIVER = Path("tests/land_pace_window.gd")
BASE = "280ee8d92e04c5b9394093143f36ea273a611935"

def run(root):
    reply = subprocess.run(["godot", "--headless", "--path", str(root), "--script", str(DRIVER)],
                           cwd=root, capture_output=True, text=True, timeout=240)
    output = reply.stdout + reply.stderr
    if reply.returncode or any(k in output for k in ("ERROR:", "SCRIPT ERROR", "Parse Error")):
        raise RuntimeError(output[-3200:])
    rows = [json.loads(line.split(" ", 1)[1]) for line in output.splitlines() if line.startswith("LAND_PACE_WINDOW ")]
    assert [row["ordinary"] for row in rows] == [[512,512],[2500,2500]]
    assert all(row["tick"] == 140 and sum(row["hits"]) > 0 and row["grid_comparisons"] > 240000 for row in rows)
    return rows

def quantiles(values):
    values = sorted(values)
    return {"median": statistics.median(values), "p95": values[math.ceil(len(values)*.95)-1],
            "p99": values[math.ceil(len(values)*.99)-1], "n":len(values)}

with tempfile.TemporaryDirectory() as tmp:
    old = Path(tmp) / "before"
    shutil.copytree(ROOT / "scripts", old / "scripts")
    (old / GROUND).write_bytes(subprocess.check_output(["git","show",f"{BASE}:{GROUND}"],cwd=ROOT))
    (old / "tests").mkdir()
    shutil.copy2(ROOT / DRIVER,old / DRIVER)
    for entry in (".godot","assets","scenes","project.godot"):
        (old / entry).symlink_to(ROOT / entry)
    samples = {"before": [], "after": []}
    for label in ("before","after","after","before","before","after","after","before"):
        samples[label].append(run(old if label == "before" else ROOT))
    reports=[]
    for idx in range(2):
        reference = samples["before"][0][idx]
        same = ("side","ordinary","grid_comparisons","tick","hits","losses","state_sha256")
        summary = {key:reference[key] for key in same}
        for label,repeats in samples.items():
            assert all(t[idx][key]==summary[key] for t in repeats for key in same)
            summary[label]={}
            for metric in ("whole_us","unit_phase_us"):
                summary[label][metric]=quantiles([value for trial in repeats for value in trial[idx][metric]])
                summary[label][metric]["per_run_median"]=[statistics.median(trial[idx][metric]) for trial in repeats]
        print("LAND_PACE_PAIR",json.dumps(summary,separators=(",",":")),flush=True)
        reports.append(summary)
    Path("measured").mkdir(exist_ok=True)
    Path("measured/pace-window.json").write_text(json.dumps({"summary":reports,"raw":samples},indent=2)+"\n")
