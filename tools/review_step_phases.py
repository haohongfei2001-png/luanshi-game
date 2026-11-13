import json
import statistics
import sys
from pathlib import Path

out = Path(sys.argv[1])
passes = [json.loads(line.split(" ", 1)[1]) for line in (out / "timings.log").read_text().splitlines() if line.startswith("STEP_PHASES ")]
assert len(passes) == 4
phases = ["grid", "officers_and_orders", "acquire_targets", "individual_state_and_density", "arrows", "ram", "objectives"]
rows = []
for run in passes:
    ticks = run["ticks"]
    assert len(ticks) == 186 and all(len(t[2]) == len(phases) for t in ticks)
    largest = max(ticks, key=lambda t: t[1])
    vicinity = [t for t in ticks if 359 <= t[0] <= 369]
    tick = next(t for t in ticks if t[0] == 365)
    stats = sorted(t[1] for t in ticks)
    rows.append({"pass": run["pass"], "p50_ms": statistics.median(stats) / 1000,
                 "p95_ms": stats[176] / 1000, "p99_ms": stats[183] / 1000,
                 "max_ms": largest[1] / 1000, "peak_tick": largest[0],
                 "tick365_ms": tick[1] / 1000, "tick365_ms_by_phase": dict(zip(phases, [a / 1000 for a in tick[2]])),
                 "nearby_peak_ms": max(t[1] for t in vicinity) / 1000,
                 "largest_phase_at_peak": phases[largest[2].index(max(largest[2]))]})
print("STEP_REPLAY_SUMMARY", json.dumps(rows))
(out / "phase-report.json").write_text(json.dumps({"environment": "Ubuntu headless Godot Linux; same roster, bow and initial order; no graphical camera, gamepad or key tour", "rows": rows, "state": passes[0]["state"]}, indent=2))
