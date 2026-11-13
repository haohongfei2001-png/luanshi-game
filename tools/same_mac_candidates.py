import hashlib
import json
import plistlib
import subprocess
import tempfile
from pathlib import Path
import rc3_native_probe as probe

data=Path.home()/"Library/Application Support/Godot/app_userdata/Luanshi - Border Skirmish"
expected={"old":"2dc1200783ee40792fa47b0d2632c90a59ebcaa69950297de9bf7e165663995c","new":"45a0317f4ad79072cee2476afcb7ab00d64e8721abe75dbf2d1aa83e27b2a0bc"}
rows=[]
for name,sha in expected.items():
    p=Path(name,"Luanshi-macOS.zip")
    assert hashlib.sha256(p.read_bytes()).hexdigest()==sha
    dest=p.parent/"app"
    subprocess.run(["ditto","-x","-k",p,dest],check=True)
    bundle,=dest.glob("*.app")
    subprocess.run(["codesign","--verify","--deep","--strict",bundle],check=True)
with tempfile.TemporaryDirectory() as temp:
    helper=Path(temp)/"focus"
    subprocess.run(["clang","-fobjc-arc","-framework","AppKit","-o",helper,"tools/macos_probe_focus.m"],check=True)
    for idx,name in enumerate(("old","new","new","old")):
        dest=Path("proof",f"{idx+1}-{name}").resolve()
        dest.mkdir(parents=True,exist_ok=True)
        bundle,=Path(name,"app").resolve().glob("*.app")
        metadata=plistlib.loads((bundle/"Contents/Info.plist").read_bytes())
        exe=bundle/"Contents/MacOS"/metadata["CFBundleExecutable"]
        result=probe.trial(exe,dest,data,helper,probe.SHIPPING)
        result["trial"]=idx+1
        result["candidate"]=name
        result["sha256"]=expected[name]
        rows.append(result)
        print("RIVER_NATIVE_PAIR",json.dumps(result,separators=(",",":")),flush=True)
        Path("proof/run-summary.json").write_text(json.dumps(rows,indent=2))
        assert result["validated"]
for key in ("adapter","processor","estimated_internal_px","render_target_px","per_side","requested_msaa_samples","renderer","shadows","preset"):
    assert all(r[key]==rows[0][key] for r in rows)
assert all(r["seconds"]>=24 and r["per_side"]==512 and r["hits_in_window"]>0 for r in rows)
