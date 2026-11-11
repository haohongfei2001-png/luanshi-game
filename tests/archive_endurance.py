"""Save only measured game records and validate the complete sequence of frames."""
import base64
import csv
import gzip
import hashlib
import io
import json
import os
import re
import sys
import zipfile
from pathlib import Path

OUT = Path("docs/evidence/river-gate-20261112")
TEMP = Path("artifacts/endurance")
SHIP = "eae4f9d3f23f119fdd210390a9c7f7c7533eae6d"
DRIVER = "eca0f508e0d2a2bba340dc9c480bcb952553bb94"
ORIGINAL = 43094439832

def unpack_log(path):
    data = Path(path).read_bytes()
    if zipfile.is_zipfile(io.BytesIO(data)):
        with zipfile.ZipFile(io.BytesIO(data)) as archive:
            names = [n for n in archive.namelist() if n.endswith(".txt") and not n.endswith("/")]
            return "\n".join(archive.read(n).decode("utf-8", errors="replace") for n in names)
    return data.decode("utf-8", errors="replace")

def payloads(log, marker):
    matched = re.findall(r"(?:^| )" + marker + r" (\{[^\n]+\})\r?$", log, re.MULTILINE)
    rows = [json.loads(s) for s in matched]
    return list({json.dumps(r, sort_keys=True): r for r in rows}.values())

def main():
    mode = sys.argv[1]
    if mode == "existing":
        log = unpack_log(sys.argv[2])
        trials = payloads(log, "ENDURANCE_PLAN")
        [window] = payloads(log, "ENDURANCE_WINDOW")
        encoded = re.search(r"(?:^| )ENDURANCE_GZIP ([A-Za-z0-9+/=]+)\r?$", log, re.MULTILINE)
        checksum = re.search(r"([a-f0-9]{64})  artifacts/endurance/frames.csv.gz", log)
        if not encoded or not checksum:
            raise ValueError("Incomplete frame archive in the prior log")
        packed = base64.b64decode(encoded[1], validate=True)
        if hashlib.sha256(packed).hexdigest() != checksum[1]:
            raise ValueError("Original compressed-frame SHA-256 mismatch")
        measure_run = ORIGINAL
    else:
        trials = json.loads((TEMP / "plans.json").read_text())
        window = json.loads((TEMP / "window.json").read_text())
        packed = gzip.compress((TEMP / "frames.csv").read_bytes(), mtime=0)
        measure_run = int(os.environ["GITHUB_RUN_ID"])
    if len(trials) != 3 or len({r["plan"] for r in trials}) != 3:
        raise ValueError("Missing reserve plan")
    table = list(csv.DictReader(io.StringIO(gzip.decompress(packed).decode("utf-8"))))
    if len(table) != window["wall_all"]["frames"] or not window["open_or_settled_world_valid"]:
        raise ValueError("Incomplete frame stream or failed WorldSim ledger")
    if int(table[-1]["hit_total"]) != window["hit_total"] or int(table[-1]["tick"]) != window["ticks"]:
        raise ValueError("Last frame differs from the printed encounter")
    if any(int(b["tick"]) < int(a["tick"]) or int(b["hit_total"]) < int(a["hit_total"]) for a, b in zip(table, table[1:])):
        raise ValueError("Encounter reset inside the capture")
    if sum(int(row["combat_poses"]) > 0 for row in table) == 0:
        raise ValueError("No visible combat poses")
    OUT.mkdir(parents=True, exist_ok=True)
    (OUT / "endurance-frames.csv.gz").write_bytes(packed)
    payload = {"run": measure_run, "original_attempt": ORIGINAL, "driver_commit": DRIVER,
               "game_source": SHIP, "retrieval": mode, "archive_run": int(os.environ["GITHUB_RUN_ID"]),
               "gzip_bytes": len(packed), "gzip_sha256": hashlib.sha256(packed).hexdigest(),
               "complete_frame_rows": len(table), "trials": trials, "window": window}
    (OUT / "endurance-measurements.json").write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n")
    print("ENDURANCE_VERIFIED", len(table), window["ticks"], window["hit_total"], payload["gzip_sha256"])

if __name__ == "__main__":
    main()
