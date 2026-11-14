"""Restore a pinned, already built open-licensed region without re-baking it."""
from pathlib import Path
import argparse, hashlib, json, shutil, sys

SOURCE = "ee5d1389944a4e3a3a13487856066e0631f8ca25"
RUN = 43627776697
FILES = {
    "assets/river_authored/architecture/architecture.glb": "9590b664efb4316d1374c79f517d4f52e6b1a17d5a04a5eaa220fd4a021f4692",
    "assets/river_authored/ground/continuous-region.scn": "8a87880eadd3448bbc4c5fdd5c9a29e9304ba098db83c32f14eb1d34dade1513",
    "assets/river_authored/woodland/region.scn": "9ba916f6270af9264aa5ca24c5b4da28cb6057be568585464ac3be0b85b5e10f",
}

def sha(path):
    h = hashlib.sha256()
    with Path(path).open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()

def verified_copy(source, target, expected):
    source, target = Path(source), Path(target)
    if source.is_symlink() or sha(source) != expected:
        raise ValueError(f"Input hash mismatch: {source.name}")
    if target.exists():
        if target.is_symlink() or sha(target) != expected:
            raise ValueError(f"Refuse to overwrite different existing input: {target}")
    else:
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(source, target)
    if sha(target) != expected:
        raise ValueError("Copied input mismatch")
    return {"path": str(target), "bytes": target.stat().st_size, "sha256": expected}

def restore(groups, architecture, target, recovered):
    sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
    from bounded_artifact_groups import restore as restore_groups
    restore_groups(groups, recovered)
    provenance = json.loads((recovered / "recovery-source.json").read_text())
    if provenance["source_sha"] != SOURCE or provenance["missing"]:
        raise ValueError("Wrong or incomplete derivative source")
    result = []
    for path, expected in FILES.items():
        source = architecture / "architecture.glb" if path.endswith(".glb") else recovered / path
        row = verified_copy(source, target / path, expected)
        row["path"] = path
        result.append(row)
    return {"source_run": RUN, "asset_source_sha": SOURCE, "files": result,
            "art_status": "ART_FAIL_PRESERVED_BASELINE_NOT_OWNER_ACCEPTED",
            "scope": "Exact reused assets; no Blender bake, no scene or battle changes"}

if __name__ == "__main__":
    p = argparse.ArgumentParser()
    for name in ("groups", "architecture", "target", "recovered"):
        p.add_argument(name, type=Path)
    a = p.parse_args()
    print(json.dumps(restore(a.groups, a.architecture, a.target, a.recovered), indent=2))
