#!/usr/bin/env python3
"""Replay real instance inputs, not isolated clip endpoints. No visual PASS implied.

Explicit layouts keep a changed texture height from silently enabling a different
shader path. This audit handles unmounted regular soldiers, including same-state
walk/idle/run switches; player travelling-leg overrides need separate capture.
"""
import argparse
import hashlib
import json
from math import dist, floor
from pathlib import Path

LAYOUT_HEIGHT = {"rc25": 1684, "rejected-native-pike": 1756}


def address(row, layout):
    data = row["instance"]["custom"]
    code = floor(data[0] * 128.)
    state, slot = code % 8, (code // 8) % 4
    if code >= 64:
        raise ValueError("Mounted actor requires per-bone saddle sampling; unsupported, not PASS")
    phase = data[1]
    if state == 0:
        clip = floor(phase * 32.) if phase > .001 or slot == 3 else 1
        phase = data[2]
    elif state in (1, 2):
        clip = (2 if state == 1 else 6) + slot
    elif state in (3, 4):
        clip = state + 7
    elif state == 5:
        clip, phase = 12, data[2]
    else:
        clip = state + 7
    kit = 2 if (code // 32) % 2 and state in (1, 2) else row["kit"]
    strip = kit * 31 + clip
    if kit == row["kit"]:
        lot = floor(data[3] * 8.)
        variant = 1 if lot in (1, 4) else 2 if lot in (2, 5, 7) else 0
        carrier = {3: 0, 4: 1, 7: 2}.get(kit, -1)
        carry = 0 if clip == 1 else 1 if clip == 0 else clip - 14 if 16 <= clip <= 22 else clip + 7 if 2 <= clip <= 9 else -1
        if variant and carrier >= 0 and carry >= 0:
            strip = 279 + carrier * 34 + (variant - 1) * 17 + carry
    if clip in (10, 11) and slot in (1, 2):
        strip = 381 + kit * 4 + (0 if clip == 10 else 2) + slot - 1
    phase = max(0., min(1., phase))
    frame = phase * (32. if clip in (0, 1, 12) or clip >= 15 else 31.)
    if layout == "rejected-native-pike" and kit == 3 and clip in (2, 6):
        segment = min(floor(phase * 8.), 7)
        strip = 423 + (8 if clip == 6 else 0) + segment
        frame = (phase * 8. - segment) * 31.
    return {"clip": clip, "strip": strip, "frame": frame, "state": state}


def world(matrix, p):
    return [sum(matrix[c][axis] * p[c] for c in range(3)) + matrix[3][axis] for axis in range(3)]


def replay(sequence, palette, layout):
    # Palette replay needs authoring dependencies; address/fixture audits do not.
    from PIL import Image
    from check_company_motion import decoded
    from company_motion import LB, RB, LS, RS, leg_nodes, trans
    bank = Image.open(palette).convert("RGBA")
    if bank.size != (528, LAYOUT_HEIGHT[layout]):
        raise ValueError(f"Palette {bank.size} does not match explicit layout {layout}")
    rows = []
    previous_tick = None
    for row in sequence["index"]:
        if previous_tick is not None and row["tick"] != previous_tick + 1:
            raise ValueError("Require consecutive simulation ticks; missing frames cannot PASS")
        previous_tick = row["tick"]
        if row["instance"]["matching_origin_error_squared"] > .0001:
            raise ValueError("Capture does not identify the requested actor")
        at = address(row, layout)
        ankles, seams = {}, {}
        matrix = row["instance"]["transform"]
        for side, bone, shin in ((-1, LB, LS), (1, RB, RS)):
            ankle = leg_nodes(side)[2]
            boot_m = decoded(bank, bone, 0, at["strip"], at["frame"])
            shin_m = decoded(bank, shin, 0, at["strip"], at["frame"])
            ankles[str(side)] = world(matrix, trans(boot_m, ankle))
            seams[str(side)] = dist(ankles[str(side)], world(matrix, trans(shin_m, ankle)))
        rows.append(dict(at, tick=row["tick"], ankles=ankles, shin_boot_gap_m=seams,
                         root=matrix[3], actor=row["actor"]))
    if len(rows) < 2:
        raise ValueError("No consecutive frames")
    steps = []
    for a, b in zip(rows, rows[1:]):
        steps.append({"to_tick": b["tick"], "state": b["state"], "from_state": a["state"],
                      "from_clip": a["clip"], "clip": b["clip"],
                      "clip_changed": a["clip"] != b["clip"],
                      "root_step_m": dist(a["root"], b["root"]),
                      "ankle_step_m": {s: dist(a["ankles"][s], b["ankles"][s]) for s in ("-1", "1")}})
    return {"frames": rows, "steps": steps,
            "palette_sha256": hashlib.sha256(Path(palette).read_bytes()).hexdigest()}


def regressions(before, after, tolerance=.002):
    if len(before["steps"]) != len(after["steps"]):
        raise ValueError("Unequal captures")
    failures = []
    for old, new in zip(before["steps"], after["steps"]):
        if old["to_tick"] != new["to_tick"]:
            raise ValueError("Different capture ticks")
        # Swing motion within one clip is authored movement, not a defect.
        # Gate actual clip transitions, including transitions inside state MARCH.
        if not new.get("clip_changed", new["state"] != new["from_state"]):
            continue
        for side in ("-1", "1"):
            excess = new["ankle_step_m"][side] - old["ankle_step_m"][side]
            if excess > tolerance:
                failures.append({"tick": new["to_tick"], "side": side, "excess_m": excess,
                                 "before_m": old["ankle_step_m"][side], "after_m": new["ankle_step_m"][side],
                                 "same_state": new["state"] == new["from_state"]})
    return failures


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("before_sequence"); p.add_argument("before_palette")
    p.add_argument("after_sequence"); p.add_argument("after_palette")
    p.add_argument("--before-layout", choices=LAYOUT_HEIGHT, default="rc25")
    p.add_argument("--after-layout", choices=LAYOUT_HEIGHT, default="rejected-native-pike")
    p.add_argument("--output", required=True)
    args = p.parse_args()
    sequences = [json.loads(Path(v).read_text()) for v in (args.before_sequence, args.after_sequence)]
    if sequences[0] != sequences[1]:
        raise ValueError("A/B sequences differ: preserve simulation, camera and actual instance inputs")
    before = replay(sequences[0], args.before_palette, args.before_layout)
    after = replay(sequences[1], args.after_palette, args.after_layout)
    failures = regressions(before, after)
    report = {"before": before, "after": after, "regressions": failures,
              "verdict": "REJECT_CONTINUITY_REGRESSION" if failures else "NO_RELATIVE_REGRESSION",
              "absolute_contact_acceptance": False, "godot_visual_pass": False,
              "note": "Ankle displacement includes actor translation/rotation and swing; not planted-foot slip. Relative nonregression is necessary, not sufficient."}
    Path(args.output).write_text(json.dumps(report, indent=2) + "\n")
    print(json.dumps({k: v for k, v in report.items() if k not in ("before", "after")}))
    return 1 if failures else 0


if __name__ == "__main__":
    raise SystemExit(main())
