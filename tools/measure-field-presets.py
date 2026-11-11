"""Use only the packaged game's own graphics configuration on a fresh hosted Mac."""
import hashlib
import json
import pathlib
import plistlib
import re
import shutil
import subprocess

out = pathlib.Path("quality-evidence").resolve()
out.mkdir()
app = next(pathlib.Path("package/unpacked").glob("*.app"))
exe = app / "Contents/MacOS" / plistlib.loads((app/"Contents/Info.plist").read_bytes())["CFBundleExecutable"]
subprocess.run(["codesign","--verify","--deep","--strict",str(app)],check=True)
digest = hashlib.sha256(pathlib.Path("package/Luanshi-macOS.zip").read_bytes()).hexdigest()
# The first native startup on a fresh VM is not part of a frame-time sample.
warm=subprocess.run([str(exe),"--headless","--fixed-fps","60","--quit-after","1100","--","--field-check"],stdout=subprocess.PIPE,stderr=subprocess.STDOUT,timeout=65)
assert warm.returncode==0 and b'FIELD_PACKAGE_PASS ' in warm.stdout,warm.stdout[-900:]
settings = None
trials = []
for label,preset in [("clear-A",0),("balanced",1),("performance",2),("clear-B",0)]:
    if settings is not None:
        settings.write_text("[display]\npreset="+str(preset)+"\n")
    args=["/usr/bin/time","-l",str(exe),"--resolution","1000x600","--disable-vsync","--audio-driver","Dummy","--","--field-check","--field-profile","--field-window-tour","--field-proof="+str(out/(label+".png"))]
    log_path=out/(label+".log")
    print("Starting",label,"with verified archive",digest,flush=True)
    with log_path.open("w") as handle:
        try:
            trial=subprocess.run(args,stdout=handle,stderr=subprocess.STDOUT,timeout=95)
        except subprocess.TimeoutExpired:
            print("Incomplete process, last log:",log_path.read_text(errors="replace")[-1700:],flush=True)
            raise
    log=log_path.read_text(errors="replace")
    assert trial.returncode==0 and 'FIELD_PACKAGE_PASS ' in log and not any(err in log for err in ['SCRIPT ERROR','SHADER ERROR','ERROR:']),log[-1700:]
    line=next(l for l in log.splitlines() if l.startswith("FIELD_HOST_WINDOW "))
    metrics=json.loads(line.partition(" ")[2])
    recorder=pathlib.Path(next(l.partition(" ")[2] for l in log.splitlines() if l.startswith("FIELD_PROFILE_FILE "))).resolve()
    assert recorder.parent.name=="frame-times" and recorder.is_file()
    settings=recorder.parent.parent/"river-gate-graphics.cfg"
    shutil.copy2(recorder,out/(label+"-session.jsonl"))
    rows=[json.loads(l) for l in recorder.read_text().splitlines() if l.strip()]
    spans=[r for r in rows if r.get("kind")=="frames"]
    assert spans and all(r["preset"]==preset and r["shadows"]==(preset!=2) and abs(r["internal_scale"]-[1,.85,.70][preset])<.001 for r in spans)
    assert metrics["renderer"]=="mobile" and metrics["per_side"]==512 and metrics["seconds"]>23.7 and metrics["hits_in_window"]>0 and metrics["panned"] and len(metrics["four_second_windows"])>=5
    metrics.update(label=label,preset=preset,shadows=spans[0]["shadows"],actual_internal_px=spans[0]["estimated_internal_px"],max_rss_bytes=int(re.search(r"^\s*(\d+)\s+maximum resident set size",log,re.M).group(1)),archive_sha256=digest)
    trials.append(metrics)
    print("PRESET_TOUR",json.dumps(metrics),flush=True)
(out/"comparison.json").write_text(json.dumps(trials,indent=2))
