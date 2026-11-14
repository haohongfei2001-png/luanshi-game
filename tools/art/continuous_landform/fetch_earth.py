"""Restore exact CC0 source bytes, never silently replace a mismatching file."""
import hashlib, json, pathlib, sys, urllib.request
manifest=json.loads(pathlib.Path(__file__).with_name("earth_source.json").read_text())
out=pathlib.Path(sys.argv[1]); out.mkdir(parents=True,exist_ok=True)
for entry in manifest["files"]:
    path=out/entry["file"]
    data=path.read_bytes() if path.exists() else urllib.request.urlopen(entry["url"],timeout=120).read()
    if len(data)!=entry["bytes"] or hashlib.sha256(data).hexdigest()!=entry["sha256"]:
        raise SystemExit("Source mismatch: "+entry["file"])
    if not path.exists():
        temporary=path.with_suffix(path.suffix+".partial")
        temporary.write_bytes(data); temporary.replace(path)
    print("VERIFIED",entry["file"],len(data),entry["sha256"])
