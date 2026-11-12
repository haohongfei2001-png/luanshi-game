import hashlib,json,os,pathlib,shutil,subprocess,zipfile
from collections import Counter
from PIL import Image
P=pathlib.Path
repo=os.environ["GITHUB_REPOSITORY"]
run=os.environ["VERIFIED_RUN"]
sha=os.environ["VERIFIED_SHA"]
url="https://github.com/"+repo
base=P(os.environ["RUNNER_TEMP"])/"receipts"
dest=P("docs/evidence/river-gate-v1-rc3")
dest.mkdir(parents=True,exist_ok=True)
raw=dest/"raw";raw.mkdir(exist_ok=True)
def get(group,name):
    hits=list((base/group).rglob(name))
    assert len(hits)==1,(group,name,hits)
    return hits[0]
def read(group,name): return json.loads(get(group,name).read_text())
def digest(p): return hashlib.sha256(p.read_bytes()).hexdigest()
def save(src,at):
    if not src.is_file(): raise ValueError(str(src))
    shutil.copyfile(src,at)
def markers(group,filename,tag):
    return [json.loads(line[len(tag)+1:]) for line in get(group,filename).read_text().splitlines() if line.startswith(tag+" ")]
mac=read("mac","renderer-comparison.json")
archive=get("package","Luanshi-macOS.zip")
apphash=digest(archive)
assert apphash==mac["archive_sha256"]
assert apphash in get("engineering","SHA256SUMS").read_text()
with zipfile.ZipFile(archive) as z:
    assert z.testzip() is None
    bundles=[n for n in z.namelist() if n.endswith("Contents/Info.plist")]
    assert len(bundles)==1
    import plistlib
    plist=plistlib.loads(z.read(bundles[0]))
    assert plist["CFBundleVersion"]=="16003"
assert all(m["validated"] for m in mac["samples"]) and mac["focus_control"]["validated"]
assert mac["shipping_window"]["validated"]
journey=markers("field","journey.log","JOURNEY_PASS")[0]
weapons=markers("field","field-controls.log","FIELD_WEAPON_INPUT")
vehicles=markers("field","field-controls.log","FIELD_VEHICLE_INPUTS")[0]
history=markers("engineering","field-history.log","FIELD_HISTORY_PASS")
assert {r["source_version"] for r in history}=={3,4}
rc2_history=json.loads(next(l.partition(" ")[2] for l in (base/"rc2-resume.log").read_text().splitlines() if l.startswith("FIELD_HISTORY_PASS ")))
save(base/"rc2-resume.log",raw/"rc2-resume.log")
officers={}
for l in get("engineering","field-officers.log").read_text().splitlines():
    if l.startswith("FIELD_OFFICER_"): officers[l.split(" ",1)[0].removeprefix("FIELD_OFFICER_")]=json.loads(l.partition(" ")[2])
assert officers.get("CONTACT") and officers.get("SUCCESSION")
assert len(weapons)==9 and len(vehicles)==2 and journey["camp_resumed"] and journey["camp_hours"]==1
frames=read("field","field-frame-times.json")
assert [f["soldiers_per_side"] for f in frames]==[20,100,250,512]
platebase=base/"visual"
frame_paths=list(platebase.rglob("after/frames.json"))
assert len(frame_paths)==1
plate=frame_paths[0].parent.parent
before=json.loads((plate/"before/frames.json").read_text());after=json.loads((plate/"after/frames.json").read_text())
for a,b in zip(before,after):
    assert all(a[k]==b[k] for k in ("tick","seed","center","yaw","zoom","contact","losses","gate_hp","ordinary","in_frame_count","in_frame_ids_sha256","window"))
assert len(before)==len(after)==12
for name in ("hero","officer","bowline","contact","formation","ranks","gate","siege","ford","camp","saddle","cart"):
    save(plate/(name+"-pair.jpg"),dest/(name+"-pair.jpg"))
for name in ("hero","contact","gate","ranks"):
    save(plate/"after"/(name+".jpg"),dest/(name+".jpg"))
save(plate/"river-contact-pair.mp4",dest/"before-after.mp4")
save(get("gameplay","river-gate-journey.mp4"),dest/"playthrough.mp4")
save(get("gameplay","player-nine-weapons.mp4"),dest/"nine-weapons.mp4")
film=read("field","journey-archive.json")
assert digest(dest/"playthrough.mp4")==film["original_sha256"]
for name in ("journey-01-muster.jpg","journey-05-breach.jpg","journey-06-report.jpg","journey-07-camp.jpg","soldier-portrait.jpg","journey-vehicle-horse.jpg","journey-vehicle-cart.jpg"):
    save(get("field",name),dest/name)
for name in ("renderer-comparison.json","default-metal-2-frames.json","focus-control-boot.json"):
    save(get("mac",name),raw/name)
for p in sorted((base/"mac").rglob("*-boot.json")): save(p,raw/p.name)
for p in sorted((base/"mac").rglob("*-frames.json")): save(p,raw/p.name)
for size in (20,100,250,512):
    name="field-frame-times-"+str(size)+".json"
    save(get("field",name),raw/name)
for group,src in [("field","field-lod-paired.json"),("field","journey-media.json"),("field","natural-siege.json"),("engineering","SHA256SUMS")]:
    save(get(group,src),raw/src)
sizes={}
for p in (base/"mac").rglob("*.png"):
    with Image.open(p) as im: sizes[p.stem]=im.size
media_rows={}
for p in (base/"gameplay").rglob("*.mp4"):
    media_rows[p.name]={"bytes":p.stat().st_size,"sha256":digest(p)}
artifacts=json.loads((base/"artifacts.json").read_text())["artifacts"]
artifact_rows={r["name"]:{"id":r["id"],"expires_at":r["expires_at"],"url":url+"/actions/runs/"+run+"/artifacts/"+str(r["id"])} for r in artifacts}
metrics=dict(source_sha=sha,workflow_run=int(run),source_url=url+"/commit/"+sha,workflow_url=url+"/actions/runs/"+run,
    artifacts=artifact_rows,macos_zip_sha256=apphash,macos_zip_bytes=archive.stat().st_size,package_version=plist["CFBundleVersion"],
    actual_target_m5="NOT_RUN",paired_cameras={"before":before,"after":after},linux_windows=frames,
    native_windows=mac,actual_native_png_pixels=sizes,playthrough=journey,weapons=weapons,vehicles=vehicles,
    field_officers=officers,historical_saves=history,rc2_breach_save=rc2_history,footage=media_rows,media=read("field","journey-media.json"),
    microscope=read("field","field-lod-paired.json"),natural_siege=read("field","natural-siege.json"),
    cpu_abba=json.loads(os.environ["CPU_FACTS"]),render_ab=json.loads(os.environ["DRAW_FACTS"]),grip_audit=json.loads(os.environ["GRIP_FACTS"]))
for group,fn,tag,key in [("field","field-escort-gui.log","FIELD_ESCORT_GUI_PASS","escort"),("field","field-outcomes.log","FIELD_ENDINGS_PASS","alternate_endings")]:
    v=markers(group,fn,tag)
    if v: metrics[key]=v[0]
(dest/"measurements.json").write_text(json.dumps(metrics,ensure_ascii=False,indent=2)+"\n")
print("CANDIDATE_RECEIPT",json.dumps({"sha":sha,"zip_sha256":apphash,"samples":len(frames),"weapons":len(weapons),"camera_pairs":len(before),
    "media_sha256":digest(dest/"playthrough.mp4"),"normal_speed_pair_sha256":digest(dest/"before-after.mp4"),
    "native":{r["label"]:[r.get("fps"),r.get("p50_ms"),r.get("p95_ms"),r.get("p99_ms"),r.get("max_rss_bytes")] for r in mac["samples"]}},ensure_ascii=False))
