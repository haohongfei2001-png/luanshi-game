import hashlib,json,os,pathlib,shutil,subprocess,zipfile
from collections import Counter
from PIL import Image
P=pathlib.Path
repo=os.environ["GITHUB_REPOSITORY"]
run=os.environ["VERIFIED_RUN"]
sha=os.environ["VERIFIED_SHA"]
url="https://github.com/"+repo
base=P(os.environ["RUNNER_TEMP"])/"receipts"
dest=P("docs/evidence/river-gate-v1-rc4")
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
    assert plist["CFBundleVersion"]=="16004"
    notices=z.read("THIRD_PARTY_NOTICES.txt")
    assert all(k in notices for k in (b"MakeHuman",b"Sparse Grass",b"Brown Mud Dry",b"Sandy Gravel 02",b"polyhaven.com/license"))
assert all(m["validated"] for m in mac["samples"]) and mac["focus_control"]["validated"]
assert mac["shipping_window"]["validated"]
journey=markers("field","journey.log","JOURNEY_PASS")[0]
weapons=markers("field","field-controls.log","FIELD_WEAPON_INPUT")
vehicles=markers("field","field-controls.log","FIELD_VEHICLE_INPUTS")[0]
history=markers("engineering","field-history.log","FIELD_HISTORY_PASS")
assert {r["source_version"] for r in history}=={3,4}
rc3_history=json.loads(next(l.partition(" ")[2] for l in (base/"rc3-resume.log").read_text().splitlines() if l.startswith("FIELD_HISTORY_PASS ")))
save(base/"rc3-resume.log",raw/"rc3-resume.log")
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
assert len(before)==len(after)==14
for name in ("hero","officer","bowline","contact","formation","ranks","gate","siege","ford","bank","margin","camp","saddle","cart"):
    save(plate/(name+"-pair.jpg"),dest/(name+"-pair.jpg"))
for name in ("hero","officer","saddle","contact","gate","ranks","ford","bank","margin","camp"):
    save(plate/"after"/(name+".jpg"),dest/(name+".jpg"))
save(plate/"river-contact-pair.mp4",dest/"before-after.mp4")
for name in ("footwork-pair.mp4","battlefield-motion.mp4"):
    save(plate/name,dest/name)
for name in ("before-motion.log","after-motion.log","battlefield-motion.log"):
    save(plate/name,raw/name)
def footage_info(path):
    return json.loads(subprocess.check_output(["ffprobe","-v","error","-show_entries","stream=codec_name,channels,width,height,duration,avg_frame_rate,nb_frames","-of","json",str(path)]))["streams"]
long_film=footage_info(dest/"battlefield-motion.mp4")
assert long_film[0]["avg_frame_rate"]=="30/1" and float(long_film[0]["duration"])>=32 and long_film[1]["channels"]==2
# A short normal-speed looping preview is taken from the actual combat film.
subprocess.run(["ffmpeg","-nostdin","-loglevel","error","-y","-ss","10.5","-i",str(dest/"battlefield-motion.mp4"),"-t","5.5","-vf","fps=15,scale=756:-2","-c:v","libwebp","-q:v","75","-compression_level","4","-loop","0","-an",str(dest/"contact-loop.webp")],check=True)
subprocess.run(["ffmpeg","-nostdin","-loglevel","error","-y","-ss","0.8","-i",str(plate/"after-motion.mp4"),"-vf","fps=3,scale=480:-2,tile=3x2:margin=2:padding=2","-frames:v","1","-q:v","3",str(dest/"motion-steps.jpg")],check=True)
subprocess.run(["ffmpeg","-nostdin","-loglevel","error","-y","-ss","0.6","-i",str(plate/"after-motion.mp4"),"-t","3.2","-vf","fps=20,scale=880:-2","-c:v","libwebp","-q:v","80","-compression_level","4","-loop","0","-an",str(dest/"footwork.webp")],check=True)
cut=Image.open(dest/"contact-loop.webp")
assert getattr(cut,"n_frames",0)>70
action_receipts={k:markers("visual",k+"-motion.log","FIELD_MOTION_RECEIPT")[0] for k in ("before","after")}
line_receipt=markers("visual","battlefield-motion.log","FIELD_LINE_FILM")[0]
assert not line_receipt["errors"] and line_receipt["frames"]>=990 and line_receipt["hero_hits"]>0

assert action_receipts["before"]["seed"] == action_receipts["after"]["seed"]
assert action_receipts["before"]["ordinary"] == action_receipts["after"]["ordinary"] == [512,512]
for key in ("view_size","start_tick","end_tick","hero_hits","hero_received","hero_hp"):
    assert action_receipts["before"][key]==action_receipts["after"][key],(key,action_receipts)
save(get("gameplay","river-gate-journey.mp4"),dest/"playthrough.mp4")
save(get("gameplay","player-nine-weapons.mp4"),dest/"nine-weapons.mp4")
save(get("gameplay","river-gate-full-siege.mp4"),dest/"siege.mp4")
save(get("mac","shipping-metal.png"),dest/"macos-window.png")
with Image.open(dest/"macos-window.png") as native_image:
    assert list(native_image.size)==mac["shipping_window"]["png_ihdr_px"]
film=read("field","journey-archive.json")
assert digest(dest/"playthrough.mp4")==film["original_sha256"]
for name in ("journey-01-muster.jpg","journey-05-breach.jpg","journey-06-report.jpg","journey-07-camp.jpg","soldier-portrait.jpg","journey-vehicle-horse.jpg","journey-vehicle-cart.jpg"):
    save(get("field",name),dest/name)
for name in ("renderer-comparison.json","default-metal-2-frames.json","focus-control-boot.json"):
    save(get("mac",name),raw/name)
for p in sorted((base/"mac").rglob("*-boot.json")): save(p,raw/p.name)
for label in [s["label"] for s in [*mac["samples"],mac["focus_control"],mac["shipping_window"]]]:
    save(get("mac",label+".log"),raw/(label+".log"))
for group, filename in (("field","field-controls.log"),("engineering","field-officers.log"),("field","journey.log"),
                         ("field","field-escort-gui.log"),("field","field-outcomes.log"),("engineering","field-history.log")):
    save(get(group,filename),raw/filename)

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
for p in sorted(dest.rglob("*.mp4")):
    media_rows[p.name]={"bytes":p.stat().st_size,"sha256":digest(p),"streams":footage_info(p)}
artifacts=json.loads((base/"artifacts.json").read_text())["artifacts"]
artifact_rows={r["name"]:{"id":r["id"],"expires_at":r["expires_at"],"url":url+"/actions/runs/"+run+"/artifacts/"+str(r["id"])} for r in artifacts}
metrics=dict(source_sha=sha,workflow_run=int(run),source_url=url+"/commit/"+sha,workflow_url=url+"/actions/runs/"+run,
    artifacts=artifact_rows,macos_zip_sha256=apphash,macos_zip_bytes=archive.stat().st_size,package_version=plist["CFBundleVersion"],
    actual_target_m5="NOT_RUN",paired_cameras={"before":before,"after":after},linux_windows=frames,
    native_windows=mac,actual_native_png_pixels=sizes,playthrough=journey,weapons=weapons,vehicles=vehicles,
    field_officers=officers,historical_saves=history,rc3_breach_save=rc3_history,footage=media_rows,media=read("field","journey-media.json"),
    microscope=read("field","field-lod-paired.json"),natural_siege=read("field","natural-siege.json"),
    tested_build_sha=os.environ["BUILD_SHA"],art_status="ART_REVIEW_REQUIRED",reference_art="ART_DIRECTION_REJECTED",long_film_streams=long_film,footwork=action_receipts,uncut_play=line_receipt)
for group,fn,tag,key in [("field","field-escort-gui.log","FIELD_ESCORT_GUI_PASS","escort"),("field","field-outcomes.log","FIELD_ENDINGS_PASS","alternate_endings")]:
    v=markers(group,fn,tag)
    if v: metrics[key]=v[0]
sampling_study=json.loads("{\"source_url\":\"https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43270239615\",\"baseline\":\"6e36e8f69526f2caf25501da5a777f63484f3162\",\"filtered\":\"ace497bed03f932b855dc2e01499c1563b5788ed\",\"metrics\":\"max range of planted shoe position including 16 subframes per authored key in 16 gait headings, PNG decoding; paired software GPU samples 1280x800\",\"foot\":[{\"sampling\":\"nearest\",\"peak_metres\":0.079089,\"eight_walk_then_eight_run\":[0.05177,0.05167,0.05168,0.05167,0.05168,0.05167,0.05168,0.05173,0.07909,0.07905,0.07909,0.07905,0.07909,0.07905,0.07909,0.07905]},{\"sampling\":\"filtered\",\"peak_metres\":0.000765,\"eight_walk_then_eight_run\":[0.00053,0.00047,0.00014,0.00023,0.0002,0.00024,0.00018,0.0005,0.00029,0.00036,0.00021,0.00069,0.00077,0.00069,0.00021,0.00036]}],\"render\":{\"before\":[{\"camera_size\":26,\"case\":\"line\",\"dead\":[35,78],\"draws\":164,\"hits\":[332,174],\"memory_bytes\":72535257,\"p50_ms\":221.748,\"p95_ms\":228.18,\"p99_ms\":229.115,\"per_side\":512,\"render_cpu95_ms\":217.149002075195,\"render_gpu95_ms\":217.757995605469,\"renderer\":\"llvmpipe (LLVM 20.1.2, 256 bits)\",\"samples\":32,\"seed\":61112,\"tick\":94,\"triangles\":751696,\"visible\":461},{\"camera_size\":12,\"case\":\"melee\",\"dead\":[71,111],\"draws\":137,\"hits\":[474,307],\"memory_bytes\":72551514,\"p50_ms\":267.533,\"p95_ms\":275.597,\"p99_ms\":276.379,\"per_side\":512,\"render_cpu95_ms\":267.406005859375,\"render_gpu95_ms\":268.054992675781,\"renderer\":\"llvmpipe (LLVM 20.1.2, 256 bits)\",\"samples\":32,\"seed\":61112,\"tick\":144,\"triangles\":1014808,\"visible\":283},{\"camera_size\":27,\"case\":\"gate\",\"dead\":[186,219],\"draws\":137,\"hits\":[975,762],\"memory_bytes\":72487414,\"p50_ms\":203.589,\"p95_ms\":209.858,\"p99_ms\":212.301,\"per_side\":512,\"render_cpu95_ms\":198.580001831055,\"render_gpu95_ms\":199.203002929688,\"renderer\":\"llvmpipe (LLVM 20.1.2, 256 bits)\",\"samples\":32,\"seed\":61112,\"tick\":539,\"triangles\":868832,\"visible\":394},{\"camera_size\":50,\"case\":\"pan\",\"dead\":[192,225],\"draws\":176,\"hits\":[1007,791],\"memory_bytes\":72545459,\"p50_ms\":188.963,\"p95_ms\":201.465,\"p99_ms\":203.63,\"per_side\":512,\"render_cpu95_ms\":194.281005859375,\"render_gpu95_ms\":194.889999389648,\"renderer\":\"llvmpipe (LLVM 20.1.2, 256 bits)\",\"samples\":32,\"seed\":61112,\"tick\":604,\"triangles\":677186,\"visible\":563}],\"after\":[{\"camera_size\":26,\"case\":\"line\",\"dead\":[35,78],\"draws\":164,\"hits\":[332,174],\"memory_bytes\":72536481,\"p50_ms\":222.772,\"p95_ms\":231.393,\"p99_ms\":232.404,\"per_side\":512,\"render_cpu95_ms\":218.774002075195,\"render_gpu95_ms\":219.296997070312,\"renderer\":\"llvmpipe (LLVM 20.1.2, 256 bits)\",\"samples\":32,\"seed\":61112,\"tick\":94,\"triangles\":751696,\"visible\":461},{\"camera_size\":12,\"case\":\"melee\",\"dead\":[71,111],\"draws\":137,\"hits\":[474,307],\"memory_bytes\":72552738,\"p50_ms\":271.767,\"p95_ms\":277.33,\"p99_ms\":278.391,\"per_side\":512,\"render_cpu95_ms\":270.299987792969,\"render_gpu95_ms\":270.941009521484,\"renderer\":\"llvmpipe (LLVM 20.1.2, 256 bits)\",\"samples\":32,\"seed\":61112,\"tick\":144,\"triangles\":1014808,\"visible\":283},{\"camera_size\":27,\"case\":\"gate\",\"dead\":[186,219],\"draws\":137,\"hits\":[975,762],\"memory_bytes\":72488638,\"p50_ms\":205.596,\"p95_ms\":209.836,\"p99_ms\":209.883,\"per_side\":512,\"render_cpu95_ms\":201.005996704102,\"render_gpu95_ms\":201.630004882812,\"renderer\":\"llvmpipe (LLVM 20.1.2, 256 bits)\",\"samples\":32,\"seed\":61112,\"tick\":539,\"triangles\":868832,\"visible\":394},{\"camera_size\":50,\"case\":\"pan\",\"dead\":[192,225],\"draws\":176,\"hits\":[1007,791],\"memory_bytes\":72546683,\"p50_ms\":188.496,\"p95_ms\":203.511,\"p99_ms\":205.055,\"per_side\":512,\"render_cpu95_ms\":198.419006347656,\"render_gpu95_ms\":198.376007080078,\"renderer\":\"llvmpipe (LLVM 20.1.2, 256 bits)\",\"samples\":32,\"seed\":61112,\"tick\":604,\"triangles\":677186,\"visible\":563}]}}")
(raw/"motion-sampling.json").write_text(json.dumps(sampling_study,ensure_ascii=False,indent=2)+"\n")
metrics["fractional_foot_motion"]=sampling_study
willow_study=json.loads("{\"run\":\"https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43274207432\",\"full_resolution\":\"https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43274207432/artifacts/13968714450\",\"source\":\"3a0a0d3099409cb6b5e7128f32a31fde2b4ad4a1\",\"baseline\":\"314b9dee2f16fa43851783132dc25e915d00f182\",\"metrics\":\"同一台托管 llvmpipe 的 56 帧窗口对比，原始间隔见来源\",\"window\":[1280,800],\"source_evidence\":\"https://github.com/haohongfei2001-png/luanshi-game/blob/97698f8d614f0f292aaf921888783afcab22118a/artifacts/willow-review/record.json\",\"fields\":[\"source_sha\",\"before_sha\",\"harness_sha\",\"run\",\"full_resolution\",\"original_viewport\",\"preview\",\"seed\",\"units\",\"images\",\"frames\",\"samples\"]}")
garment_study=json.loads("{\"run\":\"https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43274354516\",\"before\":\"6e36e8f69526f2caf25501da5a777f63484f3162\",\"after\":\"100946c76df142e08a5ac4e97b735309ba33b8ca\",\"settings\":\"1280x800 same cloud software GPU, commit pair in the same job; four 32-frame windows\",\"frames\":{\"before\":[{\"camera_size\":26,\"case\":\"line\",\"dead\":[35,78],\"draws\":164,\"hits\":[332,174],\"memory_bytes\":72535233,\"p50_ms\":126.721,\"p95_ms\":135.287,\"p99_ms\":139.568,\"per_side\":512,\"render_cpu95_ms\":98.7180023193359,\"render_gpu95_ms\":128.800003051758,\"renderer\":\"llvmpipe (LLVM 20.1.2, 256 bits)\",\"samples\":32,\"seed\":61112,\"tick\":94,\"triangles\":751696,\"visible\":461},{\"camera_size\":12,\"case\":\"melee\",\"dead\":[71,111],\"draws\":137,\"hits\":[474,307],\"memory_bytes\":72551490,\"p50_ms\":152.065,\"p95_ms\":155.461,\"p99_ms\":156.097,\"per_side\":512,\"render_cpu95_ms\":150.223999023438,\"render_gpu95_ms\":150.578002929688,\"renderer\":\"llvmpipe (LLVM 20.1.2, 256 bits)\",\"samples\":32,\"seed\":61112,\"tick\":144,\"triangles\":1014808,\"visible\":283},{\"camera_size\":27,\"case\":\"gate\",\"dead\":[186,219],\"draws\":137,\"hits\":[975,762],\"memory_bytes\":72487390,\"p50_ms\":116.415,\"p95_ms\":119.539,\"p99_ms\":123.513,\"per_side\":512,\"render_cpu95_ms\":112.819000244141,\"render_gpu95_ms\":113.227996826172,\"renderer\":\"llvmpipe (LLVM 20.1.2, 256 bits)\",\"samples\":32,\"seed\":61112,\"tick\":539,\"triangles\":868832,\"visible\":394},{\"camera_size\":50,\"case\":\"pan\",\"dead\":[192,225],\"draws\":176,\"hits\":[1007,791],\"memory_bytes\":72545435,\"p50_ms\":107.848,\"p95_ms\":115.452,\"p99_ms\":116.693,\"per_side\":512,\"render_cpu95_ms\":111.450996398926,\"render_gpu95_ms\":111.761001586914,\"renderer\":\"llvmpipe (LLVM 20.1.2, 256 bits)\",\"samples\":32,\"seed\":61112,\"tick\":604,\"triangles\":677186,\"visible\":563}],\"after\":[{\"camera_size\":26,\"case\":\"line\",\"dead\":[35,78],\"draws\":164,\"hits\":[332,174],\"memory_bytes\":72551303,\"p50_ms\":132.631,\"p95_ms\":177.258,\"p99_ms\":197.562,\"per_side\":512,\"render_cpu95_ms\":170.712997436523,\"render_gpu95_ms\":171.055999755859,\"renderer\":\"llvmpipe (LLVM 20.1.2, 256 bits)\",\"samples\":32,\"seed\":61112,\"tick\":94,\"triangles\":764488,\"visible\":461},{\"camera_size\":12,\"case\":\"melee\",\"dead\":[71,111],\"draws\":137,\"hits\":[474,307],\"memory_bytes\":72567560,\"p50_ms\":170.043,\"p95_ms\":175.718,\"p99_ms\":175.737,\"per_side\":512,\"render_cpu95_ms\":170.462997436523,\"render_gpu95_ms\":170.798004150391,\"renderer\":\"llvmpipe (LLVM 20.1.2, 256 bits)\",\"samples\":32,\"seed\":61112,\"tick\":144,\"triangles\":1034439,\"visible\":283},{\"camera_size\":27,\"case\":\"gate\",\"dead\":[186,219],\"draws\":137,\"hits\":[975,762],\"memory_bytes\":72503460,\"p50_ms\":122.666,\"p95_ms\":128.088,\"p99_ms\":128.373,\"per_side\":512,\"render_cpu95_ms\":122.323997497559,\"render_gpu95_ms\":122.662002563477,\"renderer\":\"llvmpipe (LLVM 20.1.2, 256 bits)\",\"samples\":32,\"seed\":61112,\"tick\":539,\"triangles\":869768,\"visible\":394},{\"camera_size\":50,\"case\":\"pan\",\"dead\":[192,225],\"draws\":176,\"hits\":[1007,791],\"memory_bytes\":72561505,\"p50_ms\":110.555,\"p95_ms\":122.88,\"p99_ms\":123.897,\"per_side\":512,\"render_cpu95_ms\":115.86499786377,\"render_gpu95_ms\":116.206001281738,\"renderer\":\"llvmpipe (LLVM 20.1.2, 256 bits)\",\"samples\":32,\"seed\":61112,\"tick\":604,\"triangles\":674898,\"visible\":563}]}}")
(raw/"garment-cost.json").write_text(json.dumps(garment_study,ensure_ascii=False,indent=2)+"\n")
willow_study["samples"]=json.loads("[{\"draw_frames\":[143.284,137.528,137.056,135.348,135.78,134.514,136.14,136.9,134.833,133.983,136.249,133.874,134.314,135.649,132.839,134.223,134.174,135.204,131.665,131.973,132.573,132.844,132.475,134.019,134.898,133.02,133.106,130.367,131.605,131.2,134.041,129.739,130.069,130.518,130.766,128.954,131.803,131.282,136.698,132.601,136.896,132.955,130.055,131.523,132.271,132.345,137.843,130.621,130.844,132.37,131.819,134.301,135.907,132.226,129.92,130.008],\"hits\":[448,271],\"label\":\"ford\",\"ordinary\":[512,512],\"p50_ms\":132.955,\"p95_ms\":137.528,\"p99_ms\":143.284,\"tick\":129,\"window\":[1280,800]},{\"draw_frames\":[234.48,233.02,241.093,235.73,238.386,234.587,235.181,239.183,245.72,238.752,234.892,239.643,234.424,234.376,237.262,237.978,233.611,234.119,237.359,233.026,239.488,240.482,240.991,240.406,240.7,243.63,240.777,239.06,250.22,240.633,242.013,242.6,246.277,246.486,256.902,243.053,241.552,249.42,244.647,257.997,254.291,257.761,252.481,256.91,279.479,270.612,270.792,256.042,261.468,259.226,270.365,258.892,260.121,258.546,257.291,258.746],\"hits\":[655,458],\"label\":\"field\",\"ordinary\":[512,512],\"p50_ms\":242.013,\"p95_ms\":270.612,\"p99_ms\":279.479,\"tick\":193,\"window\":[1280,800]},{\"draw_frames\":[155.703,156.531,155.303,158.953,154.518,155.178,154.771,151.842,153.58,151.809,157.482,152.981,151.698,154.588,154.728,154.208,157.37,154.595,152.2,150.922,153.995,152.375,151.781,154.512,153.771,149.347,154.756,149.495,148.831,151.801,149.85,150.7,149.97,149.69,148.666,150.602,154.988,147.949,149.231,149.362,150.212,151.576,152.226,155.019,149.328,152.21,155.742,152.581,151.746,150.553,155.825,149.912,150.091,151.422,150.48,150.077],\"hits\":[448,271],\"label\":\"ford\",\"ordinary\":[512,512],\"p50_ms\":152.2,\"p95_ms\":157.37,\"p99_ms\":158.953,\"tick\":129,\"window\":[1280,800]},{\"draw_frames\":[248.246,244.964,248.684,245.796,252.592,245.899,247.05,245.322,245.766,245.19,246.712,245.457,248.998,246.247,246.63,244.857,251.735,244.004,245.704,247.195,254.45,249.931,250.472,245.917,251.43,260.032,255.541,250.73,258.554,249.007,250.062,249.276,256.547,255.066,252.906,249.975,253.812,251.778,249.638,254.103,251.715,252.675,258.969,261.103,267.331,247.507,270.039,266.12,258.355,256.773,252.899,254.159,257.911,256.109,255.104,254.981],\"hits\":[655,458],\"label\":\"field\",\"ordinary\":[512,512],\"p50_ms\":251.43,\"p95_ms\":266.12,\"p99_ms\":270.039,\"tick\":193,\"window\":[1280,800]}]")
(raw/"willow-cost.json").write_text(json.dumps(willow_study,ensure_ascii=False,indent=2)+"\n")
metrics["willow_cost"]=willow_study
metrics["garment_cost"]=garment_study
soil_study=json.loads("{\"base\":\"3a0a0d3099409cb6b5e7128f32a31fde2b4ad4a1\",\"first\":\"0b782835a40e663f656b788b9d50374b1e9ae6e6\",\"first_run\":43278490993,\"device\":\"Linux llvmpipe, Godot 4.6.3 compatibility\",\"resolution\":[1280,800],\"scope\":\"Isolated terrain A/B in a live 512+512 simulation with the same character and camera state\",\"before\":[{\"draw_frames\":[146.281,149.134,146.713,146.59,176.447,158.48,148.501,145.642,146.94,154.34,151.097,151.832,156.572,160.61,162.491,158.271,152.216,157.534,153.815,155.603,156.293,159.566,167.971,158.93,174.727,159.217,178.097,168.754,183.874,167.078,168.527,164.984,159.456,160.463,166.411,161.655,160.786,161.618,162.58,160.819,163.627,162.317,162.167,162.134,167.021,163.47,171.74,165.566,165.089,164.954,165.186,165.199,169.532,161.158,162.822,161.865],\"hits\":[448,271],\"label\":\"contact\",\"ordinary\":[512,512],\"p50_ms\":161.655,\"p95_ms\":176.447,\"p99_ms\":183.874,\"tick\":129,\"window\":[1280,800]},{\"draw_frames\":[112.468,110.184,112.789,110.763,116.082,113.082,112.064,110.532,113.396,113.85,112.828,110.718,110.231,114.656,110.84,110.811,109.572,109.196,109.772,109.377,111.118,113.881,115.45,111.557,109.254,111.345,110.808,110.63,111.696,110.361,110.035,116.949,122.621,111.707,109.627,109.817,110.072,109.595,112.182,109.647,109.421,115.327,114.689,110.981,110.147,109.372,110.797,111.381,110.938,110.36,113.694,110.09,108.701,110.041,109.921,109.571],\"hits\":[655,458],\"label\":\"ford\",\"ordinary\":[512,512],\"p50_ms\":110.808,\"p95_ms\":116.082,\"p99_ms\":122.621,\"tick\":193,\"window\":[1280,800]}],\"first_result\":[{\"draw_frames\":[146.427,141.846,141.523,142.428,146.281,153.484,145.546,150.207,153.52,155.027,157.394,155.859,148.667,147.457,154.538,148.113,148.099,154.381,149.153,152.493,156.444,158.185,153.928,154.724,155.356,155.162,156.44,159.719,157.711,154.634,154.765,156.344,157.619,163.007,158.425,157.084,158.038,156.634,157.538,157.38,157.818,158.793,157.961,158.671,157.027,160.264,165.433,160.473,159.95,161.452,160.244,159.065,160.431,158.85,157.942,156.587],\"hits\":[448,271],\"label\":\"contact\",\"ordinary\":[512,512],\"p50_ms\":156.587,\"p95_ms\":161.452,\"p99_ms\":165.433,\"tick\":129,\"window\":[1280,800]},{\"draw_frames\":[106.278,105.268,107.547,105.954,107.442,111.426,105.686,104.7,105.694,105.703,104.278,104.212,105.25,103.493,105.315,125.624,105.878,104.885,107.641,105.322,109.098,104.119,105.415,104.203,104.625,108.126,104.455,106.63,106.205,106.202,103.437,104.504,104.605,105.549,107.698,103.88,102.35,103.361,103.881,103.065,102.793,102.726,104.641,103.29,106.123,103.289,102.29,103.132,102.69,102.52,106.463,101.775,101.279,102.583,106.355,104.046],\"hits\":[655,458],\"label\":\"ford\",\"ordinary\":[512,512],\"p50_ms\":104.7,\"p95_ms\":109.098,\"p99_ms\":125.624,\"tick\":193,\"window\":[1280,800]}],\"sources\":[\"https://polyhaven.com/a/sparse_grass\",\"https://polyhaven.com/a/brown_mud_dry\",\"https://polyhaven.com/a/sandy_gravel_02\"],\"source_license\":\"https://polyhaven.com/license\",\"three_version_run\":43279682115,\"selected\":\"7cabd7bdd191ccbc0e23ca7cc54b400ef1a4bd16\",\"surface_readback\":[\"RIVER_ART_PASS ticks=193 seed=61112\",\"RIVER_ART_PASS ticks=193 seed=61112\",\"GROUND_FLATNESS hero 0.0202 0.0165\",\"GROUND_FLATNESS saddle 0.015 0.013\",\"GROUND_FLATNESS cart 0.0065 0.0023\",\"GROUND_FLATNESS ford 0.0065 0.0053\",\"GROUND_FLATNESS camp 0.0078 0.0033\",\"GROUND_FLATNESS officer 0.0063 0.004\",\"GROUND_FLATNESS bowline 0.0187 0.0112\",\"GROUND_FLATNESS ranks 0.0072 0.0038\",\"GROUND_FLATNESS contact 0.0045 0.0012\",\"GROUND_FLATNESS formation 0.0077 0.004\",\"WILLOW_TIMES contact [162.36, 171.38, 184.14] [159.74, 165.22, 166.97]\",\"WILLOW_TIMES ford [111.02, 118.17, 124.74] [107.25, 110.02, 111.5]\"],\"before_final_pair\":[{\"draw_frames\":[145.448,156.235,149.804,159.034,165.596,149.799,162.299,160.174,161.756,151.373,155.014,152.92,150.114,151.516,161.423,163.441,163.203,163.195,155.164,154.317,162.661,160.064,163.554,157.235,158.599,163.094,184.139,168.968,173.461,168.474,171.382,160.884,165.522,162.723,166.266,160.942,161.014,162.152,164.146,166.642,166.17,162.209,161.816,166.112,160.678,165.557,166.853,164.446,165.618,164.024,164.763,167.585,166.189,162.364,162.342,161.845],\"hits\":[448,271],\"label\":\"contact\",\"ordinary\":[512,512],\"p50_ms\":162.364,\"p95_ms\":171.382,\"p99_ms\":184.139,\"tick\":129,\"window\":[1280,800]},{\"draw_frames\":[110.786,110.781,118.574,114.085,111.018,114.123,113.444,113.075,111.494,118.173,124.738,114.9,111.547,111.695,111.112,110.981,111.813,110.034,110.755,110.655,112.517,111.568,114.527,116.338,114.962,114.291,110.797,110.615,110.667,112.63,113.588,110.658,110.775,112.023,110.426,112.795,109.269,110.082,109.9,114.24,109.837,112.691,112.268,110.793,109.985,109.821,110.332,109.765,113.089,110.049,109.039,109.407,110.942,110.227,110.373,108.548],\"hits\":[655,458],\"label\":\"ford\",\"ordinary\":[512,512],\"p50_ms\":111.018,\"p95_ms\":118.173,\"p99_ms\":124.738,\"tick\":193,\"window\":[1280,800]}],\"final_pair\":[{\"draw_frames\":[145.142,147.949,155.368,145.068,157.327,150.451,148.263,145.85,148.774,149.599,160.349,151.841,157.689,151.375,150.786,150.422,151.529,151.393,153.706,158.221,155.275,155.521,156.389,156.907,157.26,159.956,159.884,157.957,158.964,158.283,158.324,161.801,161.572,162.135,159.736,160.552,161.969,161.866,163.436,161.562,160.773,160.528,162.836,163.375,164.728,163.142,165.07,165.033,163.333,165.923,166.968,165.215,162.356,162.16,160.158,160.002],\"hits\":[448,271],\"label\":\"contact\",\"ordinary\":[512,512],\"p50_ms\":159.736,\"p95_ms\":165.215,\"p99_ms\":166.968,\"tick\":129,\"window\":[1280,800]},{\"draw_frames\":[107.615,109.544,111.503,107.904,108.188,109.583,109.225,108.683,110.37,108.411,106.998,109.405,107.535,110.018,108.007,106.634,106.64,107.249,105.627,107.108,110.018,109.197,107.854,106.949,107.153,109.179,106.412,105.379,107.946,108.967,108.187,105.754,107.5,104.992,105.573,106.87,103.874,105.24,106.647,108.721,106.704,107.067,108.079,106.172,107.589,106.125,106.904,105.625,104.306,109.754,104.954,104.752,106.364,107.136,108.44,104.835],\"hits\":[655,458],\"label\":\"ford\",\"ordinary\":[512,512],\"p50_ms\":107.249,\"p95_ms\":110.018,\"p99_ms\":111.503,\"tick\":193,\"window\":[1280,800]}],\"timing_scope\":\"Timings compare the willow-only and selected soil revisions. Screenshots also include the intervening soil variant.\"}")
(raw/"soil-materials.json").write_text(json.dumps(soil_study,ensure_ascii=False,indent=2)+"\n")
metrics["soil_material_ab"]=soil_study
metrics["archive_run"]=int(os.environ["GITHUB_RUN_ID"])
metrics["archive_source"]=os.environ["GITHUB_SHA"]
metrics["integration_event"]=os.environ["VERIFIED_EVENT"]
metrics["tested_review_head"]=os.environ["REVIEW_CODE_HEAD"]
metrics["tested_review_run"]=int(os.environ["REVIEW_CI"])

soil_credits=json.loads("[{\"game_file\":\"root-turf.png\",\"author\":\"Amal Kumar\",\"asset_page\":\"https://polyhaven.com/a/sparse_grass\",\"license\":\"CC0 1.0 Universal\",\"license_source\":\"https://polyhaven.com/license\",\"original\":\"https://dl.polyhaven.org/file/ph-assets/Textures/jpg/1k/sparse_grass/sparse_grass_diff_1k.jpg\",\"source_sha256\":\"ae94f2b34597b9108eefd88217f55eccaec6d6b382e858a478ee92df90e66617\",\"game_png_sha256\":\"8be6b3cfb046ed966d56700833429b470da2f3ced935d9b7ed69990c3a42c62b\"},{\"game_file\":\"compacted-loam.png\",\"author\":\"Rob Tuytel\",\"asset_page\":\"https://polyhaven.com/a/brown_mud_dry\",\"license\":\"CC0 1.0 Universal\",\"license_source\":\"https://polyhaven.com/license\",\"original\":\"https://dl.polyhaven.org/file/ph-assets/Textures/jpg/1k/brown_mud_dry/brown_mud_dry_diff_1k.jpg\",\"source_sha256\":\"a56281b644de614787340f3db45e28d2f72ec32fc19a442f99002bae0ab11398\",\"game_png_sha256\":\"c3a737c4adde0bd68ef72f7f7ca77f23af157f3f30e57611c9566da550577d4a\"},{\"game_file\":\"bank-silt.png\",\"author\":\"Dario Barresi\",\"asset_page\":\"https://polyhaven.com/a/sandy_gravel_02\",\"license\":\"CC0 1.0 Universal\",\"license_source\":\"https://polyhaven.com/license\",\"original\":\"https://dl.polyhaven.org/file/ph-assets/Textures/jpg/1k/sandy_gravel_02/sandy_gravel_02_diff_1k.jpg\",\"source_sha256\":\"c9d143db07db9a6be2eba285fae961d868520422ee5fa4d38d55da24f9968d51\",\"game_png_sha256\":\"29ef60ed2054641a0915536d42ccd136ddc75318a9a7bba03a4faa9901705633\"}]")
for credit in soil_credits:
    source_png=P(os.environ["GITHUB_WORKSPACE"])/"tested"/"assets"/"environment"/credit["game_file"]
    assert digest(source_png)==credit["game_png_sha256"], credit["game_file"]
(raw/"soil-sources.json").write_text(json.dumps(soil_credits,ensure_ascii=False,indent=2)+"\n")

def word_link(title, path):
    return "["+title+"]("+path+")"
def millisecond(x):
    return f"{x:.2f}"
def frame_budget(values):
    assert values and all(v>0 for v in values)
    return dict(frames=len(values),over_16_67_ms=sum(v>16.67 for v in values),
                over_33_33_ms=sum(v>33.33 for v in values),maximum_ms=max(values))

native=mac["shipping_window"]
native_walls=read("mac","shipping-metal-frames.json")["raw_wall_ms"]
assert len(native_walls)==native["frames"]
budget={"hosted_macos":frame_budget(native_walls),
        "linux_software":{str(n):frame_budget(read("field","field-frame-times-"+str(n)+".json")["sorted_frame_ms"]) for n in (20,100,250,512)}}
metrics["wall_frame_budget"]=budget
def after_camera_commands(values, four_second_windows):
    # All commands are issued after post_draw. The next frame begins at this index.
    import math
    boundaries = []
    end_ms = 0
    for index, duration in enumerate(values):
        end_ms += duration
        if end_ms >= 1250:
            boundaries.append(index + 1)
            break
    frames_drawn = 0
    for interval in four_second_windows:
        frames_drawn += interval["frames"]
        if frames_drawn < len(values):
            boundaries.append(frames_drawn)
    following, other = [], []
    elapsed_ms = 0
    last_pan_ms = None
    for index, duration in enumerate(values):
        if index in boundaries:
            last_pan_ms = elapsed_ms
        selected = last_pan_ms is not None and elapsed_ms-last_pan_ms < 500
        (following if selected else other).append(duration)
        elapsed_ms += duration
    def describe(sample):
        ordered = sorted(sample)
        return dict(samples=len(sample),p50_ms=ordered[math.ceil(len(sample)*.50)-1],
                    p95_ms=ordered[math.ceil(len(sample)*.95)-1],p99_ms=ordered[math.ceil(len(sample)*.99)-1],
                    maximum_ms=ordered[-1])
    return dict(command_after_frame_counts=boundaries,post_command_500ms=describe(following),other=describe(other))

budget["hosted_macos"]["camera_tour"]=after_camera_commands(native_walls,native["four_second_windows"])
(raw/"frame-budget.json").write_text(json.dumps(budget,indent=2)+"\n")
package_artifact=next(v["url"] for k,v in artifact_rows.items() if k.startswith("Luanshi-macOS-"))
reference="https://github.com/"+repo+"/commit/799e1e41a098bf534b63f699ea6f683e4707306f"
center=action_receipts["after"]
compiled=os.environ["BUILD_SHA"]
battle_stream=long_film[0]
doc=[
    "# 河关 0.16.0-rc.4 · 实机画面与可玩包",
    "",
    "**美术状态为 ART_REVIEW_REQUIRED。** RC3 的人物美术已由 Owner 退回。这份候选把人物、动作、马匹和地形接入原战役。玩家的参考是《英雄联盟》实战镜头里清楚的轮廓、承重和挥击节奏。河关的兵器、衣甲、地图和声音均沿用本作设定。",
    "",
    "[34 秒连续实战](battlefield-motion.mp4) · [同输入脚步对照](footwork-pair.mp4) · [从布阵到行军](playthrough.mp4) · [完整攻城实录](siege.mp4) · [macOS 候选包实际窗口](macos-window.png) · [九种武器](nine-weapons.mp4) · "+word_link("macOS 候选包",package_artifact),
    "",
    "![真实战斗片段](contact-loop.webp)",
    "",
    "## 镜头里能看到什么",
    "",
    "- 对照左为 RC3，右为 RC4。在两版正式 Godot 场景重放同一批 512+512 名普通兵、32 名军官与主角。十四组截图的随机种子、模拟时刻、镜头中心、角度、缩放、画内单位、伤亡与城门状态一一对应。1280×800，内部缩放 1，阴影开启。 [主角](hero-pair.jpg) · [对阵](contact-pair.jpg) · [箭线](bowline-pair.jpg) · [军官](officer-pair.jpg) · [城门](gate-pair.jpg) · [坐骑](saddle-pair.jpg) · [战车](cart-pair.jpg) · [渡口](ford-pair.jpg) · [柳树与水岸](bank-pair.jpg) · [林缘](margin-pair.jpg) · [军营](camp-pair.jpg) · [远阵](formation-pair.jpg)",
    "- 贴地的步伐、侧身移步、胯肩反向承重、抬手预备、击后收势都采样自正式输入与动画。第一次等输入回放发现起始镜头不同，最终镜头统一。持枪主角近身前走了 %.2f 米，命中 %d 次、承受 %d 次打击后倒下。两版均记录到模拟第 %d 步。 [连续动作分帧](motion-steps.jpg) · [两版数据](raw/after-motion.log)"%(center["distance_m"],center["hero_hits"],center["hero_received"],center["end_tick"]),
    "- 弓手连续实录 %d 帧，主角命中 %d 次，镜头随后沿交战线移向冲车。两军累计有效命中 %d / %d 次，累计伤亡 %d / %d。此片按正常 30 帧时基录制，设备性能见实测表。 [原始日志](raw/battlefield-motion.log)"%(line_receipt["frames"],line_receipt["hero_hits"],*line_receipt["hits"],*line_receipt["losses"]),
    "",
    "- 后续实装了靛蓝粗布、夹袄、深色铁札与绛披。主角和士兵在持枪行军时把枪尖举过前排肩线，交战时降至命中高度。服装和三张脸的原画只作为 UV 贴图使用。 [正式角色画面](hero.jpg) · [连续持械步伐](footwork.webp)",
    "- 对 16 组方向步态的接地段在每个姿势之间再采 16 个点，最差鞋底位移从 79.1 毫米降至 0.77 毫米。1280×800 同宿主软件绘制四个镜头的 P95 变化为 −0.02 至 +3.21 毫秒，镜头内几何、伤亡及命中一致。此表检验了插值改动，最新包的完整帧时另列于下。 [逐项 A/B](raw/motion-sampling.json)",
    "",
    "## 性能与启动",
    "",
    "Godot 4.6.3。GitHub 托管 macOS 的 "+native["processor"]+"，"+native["renderer"]+" 清晰档，阴影开启，实际画幅 %d×%d。双方各 512 名普通士兵的战役实际巡场 %.1f 秒。"%(native["png_ihdr_px"][0],native["png_ihdr_px"][1],native["seconds"]),
    "",
    "| 托管设备与普通兵/方 | 平均 FPS | P50 ms | P95 ms | P99 ms | 进程内存 MiB |",
    "|---|---:|---:|---:|---:|---:|",
    "| Apple M1 (Virtual) · 512 | %.1f | %.2f | %.2f | %.2f | %.0f |"%(native["fps"],native["p50_ms"],native["p95_ms"],native["p99_ms"],native["max_rss_bytes"]/2**20),
]
for row in frames:
    doc.append("| Linux 软件渲染 · %d | %.2f | %.2f | %.2f | %.2f | %.0f |"%(row["soldiers_per_side"],row["fps"],row["median_ms"],row["p95_ms"],row["p99_ms"],row["resident_kib"]/1024))
doc += [
    "",
    "表中 macOS 为峰值 RSS，Linux 为各场景采样时的 RSS。不同宿主的结果分开读。真实 MacBook Air M5 为 **NOT_RUN**。实测采样含阵线接触、镜头平移、攻城、骑兵与投射物。软件绘制和虚拟显示器不代表玩家设备。["+ "逐帧时间、画质与设备" +"](measurements.json)",
    "",
    "本次 Mac 巡场共 %d 帧，其中 %d 帧超过 16.67 毫秒，%d 帧超过 33.33 毫秒，最慢 %.2f 毫秒。Linux 的 512 对 512 采样了 %d 个渲染帧。 [超过预算的帧数](raw/frame-budget.json)"%(len(native_walls),budget["hosted_macos"]["over_16_67_ms"],budget["hosted_macos"]["over_33_33_ms"],budget["hosted_macos"]["maximum_ms"],budget["linux_software"]["512"]["frames"]),
    "",
    "把默认镜头巡场中每次平移命令后 500 毫秒与其余帧分开，前者 %d 帧、P95 %.2f 毫秒，其余 %d 帧、P95 %.2f 毫秒。按实际提交命令的帧号分组，同一时段还包含士兵移动与战斗更新。 [原始分组与 P99](raw/frame-budget.json)"%(budget["hosted_macos"]["camera_tour"]["post_command_500ms"]["samples"],budget["hosted_macos"]["camera_tour"]["post_command_500ms"]["p95_ms"],budget["hosted_macos"]["camera_tour"]["other"]["samples"],budget["hosted_macos"]["camera_tour"]["other"]["p95_ms"]),
    "",
    "托管 Mac 正式游玩摄像巡场中，模拟与战场显示脚本平均每个渲染帧分别占 %.2f 与 %.2f 毫秒。渲染线程 CPU P95 为 %.2f 毫秒。%sLinux 千人窗口的每个模拟步平均 %.2f 毫秒，软件绘制计时的 P95 为 %.2f 毫秒。 [原生逐帧样本](raw/shipping-metal-frames.json) · [四档同宿主窗口](measurements.json)"%(native["sim_cpu_ms_per_frame"],native["view_script_ms_per_frame"],native["render_cpu_p95_ms"],("原生 GPU P95 为 %.2f 毫秒。"%native["render_gpu_p95_ms"] if native.get("render_gpu_p95_ms") is not None else "该次驱动没有交回非零 GPU 时间戳，原生 GPU 毫秒数保留为空。"),frames[-1]["sim_ms_per_tick"],frames[-1]["render_gpu_p95_ms"]),
    "",
    "八次独立进程均以空游戏数据启动，覆盖兼容后端、Metal、焦点控制与默认窗口。系统图形驱动和 WindowServer 缓存按实际宿主状态保留。兼容后端第一次首帧 %.2f 秒，第二次 %.2f 秒。默认 Metal 首次 %.2f 秒，再开 %.2f 秒。每次记录首帧、前台、部署、首次模拟和命中。 [原始时序和启动日志](raw/renderer-comparison.json)"%(mac["samples"][0]["launch_milestones_ms"]["first_post_draw"]/1000,mac["samples"][-1]["launch_milestones_ms"]["first_post_draw"]/1000,next(s for s in mac["samples"] if s["label"]=="default-metal-1")["launch_milestones_ms"]["first_post_draw"]/1000,next(s for s in mac["samples"] if s["label"]=="default-metal-2")["launch_milestones_ms"]["first_post_draw"]/1000),
    "",
    "RC2 曾在首次兼容后端启动时停在模拟第 0 步。这次每个窗口均记录到实际命中。首开仍可能显著慢于再次打开，系统图形缓存及宿主差异仍待调查。 [RC2 失败现场](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43157917697/job/130986662440) · [本版启动时序](raw/renderer-comparison.json)",
    "",
    "独立改动也保留了相同 GPU 与机位的对照。柳岸实装后的渡口软件绘制 P95 从 137.53 增至 157.37 毫秒。贴图与头部轮廓更新后，野战近身镜头的软件绘制 P95 从 155.46 增至 175.72 毫秒。完整包取样和单项实验分别记录。 [河岸对照](raw/willow-cost.json) · [角色对照](raw/garment-cost.json)",
    "",
    "常用镜头的浅色地面已换成沿车道、旧田和河岸混合的草根、压实土与湿砂。远镜头降低碎亮点和连续双车辙的对比度。在完全相同的十个机位，地表实验没有增加绘制批次或三角形。千人接阵的 56 帧软件绘制 P95 为 171.38 → 165.22 毫秒，渡口为 118.17 → 110.02 毫秒。 [逐帧样本](raw/soil-materials.json) · [四个机位的三版原图](https://github.com/haohongfei2001-png/luanshi-game/tree/71d1f296e417a715da72bb8bb7176c56b84ba798/artifacts/soil-material-review) · [来源与校验值](raw/soil-sources.json) · [材料授权](https://polyhaven.com/license)",
    "",
    "正常缩放下队伍装备与远景脸型仍有重复。密集门口前排偶尔会遮住主角持械手。柳冠体块与路面材质还有细化空间。是否达到美术方向以实际游玩画面为准。 [门洞](gate.jpg) · [接敌](contact.jpg) · [正常机位下的行列](formation-pair.jpg)",
    "",
    "## 战役与存档回归",
    "",
    "- 实际输入覆盖%s，并覆盖骑乘、下马、战车、部署、号令、敌我军官、救援、继任、护送与战后结算。主流程经过 %d 个可交互阶段，从营地读档并推进 %d 小时。 [武器与载具](raw/field-controls.log) · [将领](raw/field-officers.log) · [军令与战报](raw/journey.log) · [护送](raw/field-escort-gui.log) · [胜负分支](raw/field-outcomes.log)"%("、".join(r["weapon"] for r in weapons),len(journey["screens"]),journey["camp_hours"]),
    "- 原始 RC3 写出的破门存档从第 %d 步继续至第 %d 步。逐字段差异数 %d。历史 v3、v4 存档和游戏内驻营继续已分别复验。 [跨版复验](raw/rc3-resume.log) · [历史样本](raw/field-history.log)"%(rc3_history["start_tick"],rc3_history["resumed_tick"],len(rc3_history["different_keys"])),
    "",
    "## 源码、素材与复现",
    "",
    "- 候选源码 "+word_link(sha,url+"/commit/"+sha)+"，CI 实际打包提交 "+word_link(compiled,url+"/commit/"+compiled)+"。"+word_link("游戏 PR #34",url+"/pull/34")+" · "+word_link("CI 与产物",url+"/actions/runs/"+run)+" · "+word_link("RC3 可回退源码",reference),
    "- 游戏 PR 源码 "+word_link(os.environ["REVIEW_CODE_HEAD"],url+"/commit/"+os.environ["REVIEW_CODE_HEAD"])+" 已完成 "+word_link("独立的 PR 构建与回归",url+"/actions/runs/"+os.environ["REVIEW_CI"])+"。",
    "- macOS ZIP 内含可运行的 .app、中文指南及第三方许可。SHA-256 为 `"+apphash+"`。这个散列校验解开 Actions 外层归档后的 Luanshi-macOS.zip。通用 .app 采用临时签名，尚未进行 Apple 公证。",
    "- 脸部基础网格与形态来自 MakeHuman 的 CC0 数据。衣料和三张虚构面孔采用本项目生成并按衣片、五官对齐的贴图，马具、器械、动作与场景构图由本项目制作。草地与泥沙使用经调色和高度处理的 Poly Haven CC0 扫描，包内列有三位作者及来源。资产与再分发记录见 "+word_link("人物与动作",url+"/blob/"+sha+"/assets/river_gate/figures/SOURCE.md")+"、"+word_link("马匹",url+"/blob/"+sha+"/assets/art/mounts/README.md")+"、"+word_link("环境",url+"/blob/"+sha+"/assets/environment/README.md")+"。",
    "- 原始图像来自正式引擎窗口，归档时逐项校验录像、包、素材来源散列及原始 RC3 存档。 "+word_link("归档执行",url+"/actions/runs/"+os.environ["GITHUB_RUN_ID"])+" · "+word_link("可复现的核验程序",url+"/blob/"+os.environ["GITHUB_SHA"]+"/tools/collect-verified-rc4.py"),
    "- 在有 Godot 4.6.3、Xvfb、FFmpeg 和 Python/Pillow 的云端环境签出候选源码，运行 `./tools/compare-river-art.sh` 复拍十四组镜头与正常速度实战。性能与输入流程可重跑 `./tools/test-field-journey.sh` 和 `./tools/test-field-render.sh`。原生启动复验使用 CI macos-runtime 作业。",
]
(dest/"PLAYTEST.md").write_text("\n".join(doc)+"\n")
(dest/"measurements.json").write_text(json.dumps(metrics,ensure_ascii=False,indent=2)+"\n")
print("CANDIDATE_RECEIPT",json.dumps({"sha":sha,"zip_sha256":apphash,"samples":len(frames),"weapons":len(weapons),"camera_pairs":len(before),
    "media_sha256":digest(dest/"playthrough.mp4"),"normal_speed_pair_sha256":digest(dest/"before-after.mp4"),
    "long_film":line_receipt,"native":{r["label"]:[r.get("fps"),r.get("p50_ms"),r.get("p95_ms"),r.get("p99_ms"),r.get("max_rss_bytes")] for r in mac["samples"]}},ensure_ascii=False))
