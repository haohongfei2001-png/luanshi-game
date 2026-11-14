"""Compare real before/after soldier targeting on a single Linux host with a warmed import.

git cat-file supplies the exact previous gameplay script to a temporary project.
The normal working tree is untouched. Both versions run in alternating order.
"""
import json
from pathlib import Path
import shutil
import statistics
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]
BASE = "4621944adf8e30dda2516b4291e7a0ceebc011d7"
BATTLE = Path("scripts/field/battle.gd")
DRIVER = Path("tests/field_target_timing.gd")


def run(root):
    result = subprocess.run(
        ["godot", "--headless", "--path", str(root), "--script", str(DRIVER)],
        cwd=root, text=True, capture_output=True, timeout=160,
    )
    output = result.stdout + result.stderr
    if result.returncode or any(word in output for word in ("SCRIPT ERROR", "Parse Error", "ERROR:")):
        raise RuntimeError(output[-4500:])
    rows = [json.loads(line.removeprefix("FIELD_TARGET_TRIAL ")) for line in output.splitlines() if line.startswith("FIELD_TARGET_TRIAL ")]
    if [row["ordinary"] for row in rows] != [[512, 512], [2500, 2500]]:
        raise RuntimeError(output[-4500:])
    return rows


def main():
    # The original target implementation must run with its own field, save and
    # officer contracts. The current field additionally supports the bridgehead.
    sources = [BATTLE, Path("scripts/field/save.gd"), Path("scripts/field/officer_corps.gd"),
               Path("scripts/field/formation_traffic.gd"), Path("scripts/field/ground.gd"),
               Path("scripts/field/field_objectives.gd")]
    before = {path: subprocess.check_output(["git", "show", f"{BASE}:{path.as_posix()}"], cwd=ROOT) for path in sources}
    with tempfile.TemporaryDirectory() as temp:
        previous = Path(temp) / "previous"
        # The imported asset files are read-only in these headless game processes.
        # Only script source differs. Each project resolves its own res:// paths.
        shutil.copytree(ROOT / "scripts", previous / "scripts")
        for path, content in before.items():
            (previous / path).write_bytes(content)
        (previous / "tests").mkdir()
        shutil.copy2(ROOT / DRIVER, previous / DRIVER)
        for entry in (".godot", "assets", "scenes", "project.godot"):
            (previous / entry).symlink_to(ROOT / entry)
        samples = {"before": [], "after": []}
        for side in ("before", "after", "after", "before"):
            samples[side].append(run(previous if side == "before" else ROOT))
        result = []
        for index in range(2):
            reference = samples["before"][0][index]
            row = {"ordinary": reference["ordinary"], "hits": reference["hits"], "final_state_sha256": reference["final_state_sha256"],
                   "comparison_contract": "Every legacy combat field, byte-exact. Known open-field terrain_revision metadata recorded separately.",
                   "terrain_revisions": {side: [trial[index]["terrain_revision"] for trial in repeats] for side, repeats in samples.items()},
                   "full_snapshot_sha256": {side: [trial[index]["full_snapshot_sha256"] for trial in repeats] for side, repeats in samples.items()}}
            for repetitions in samples.values():
                for pair in repetitions:
                    for key in ("tick", "hits", "decisions", "final_state_sha256"):
                        if pair[index][key] != reference[key]:
                            raise ValueError(f"{reference['ordinary']} changed {key}")
            if reference["hits"] <= 0:
                raise ValueError("No live contacts in the measurement")
            for key, repeats in samples.items():
                row[key] = {}
                for metric in ("query_us", "grid_us", "step_us"):
                    values = sorted(item for repetition in repeats for item in repetition[index][metric])
                    row[key][metric] = {"median":statistics.median(values), "p95":values[(len(values)*95+99)//100-1], "samples":len(values)}
            result.append(row)
            print("FIELD_TARGET_PAIR", json.dumps(row, separators=(",", ":")), flush=True)
        (ROOT / "artifacts/field-target-pair.json").write_text(json.dumps(result, indent=2) + "\n")


if __name__ == "__main__":
    main()
