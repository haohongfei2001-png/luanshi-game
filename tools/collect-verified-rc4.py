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
    assert b"MakeHuman" in z.read("THIRD_PARTY_NOTICES.txt")
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
assert len(before)==len(after)==12
for name in ("hero","officer","bowline","contact","formation","ranks","gate","siege","ford","camp","saddle","cart"):
    save(plate/(name+"-pair.jpg"),dest/(name+"-pair.jpg"))
for name in ("hero","officer","saddle","contact","gate","ranks","ford","camp"):
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
def word_link(title, path):
    return "["+title+"]("+path+")"
def millisecond(x):
    return f"{x:.2f}"
native=mac["shipping_window"]
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
    "[34 秒连续实战](battlefield-motion.mp4) · [同输入脚步对照](footwork-pair.mp4) · [从布阵到行军](playthrough.mp4) · [九种武器](nine-weapons.mp4) · "+word_link("macOS 候选包",package_artifact),
    "",
    "![真实战斗片段](contact-loop.webp)",
    "",
    "## 镜头里能看到什么",
    "",
    "- 对照左为 RC3，右为 RC4。在两版正式 Godot 场景重放同一批 512+512 名普通兵、32 名军官与主角。十二组截图的随机种子、模拟时刻、镜头中心、角度、缩放、画内单位、伤亡与城门状态一一对应。1280×800，内部缩放 1，阴影开启。 [主角](hero-pair.jpg) · [对阵](contact-pair.jpg) · [箭线](bowline-pair.jpg) · [军官](officer-pair.jpg) · [城门](gate-pair.jpg) · [坐骑](saddle-pair.jpg) · [战车](cart-pair.jpg) · [渡口](ford-pair.jpg) · [军营](camp-pair.jpg) · [远阵](formation-pair.jpg)",
    "- 贴地的步伐、侧身移步、胯肩反向承重、抬手预备、击后收势都采样自正式输入与动画。第一次等输入回放发现起始镜头不同，最终镜头统一。持枪主角近身前走了 %.2f 米，命中 %d 次、承受 %d 次打击后倒下。两版均记录到模拟第 %d 步。 [连续动作分帧](motion-steps.jpg) · [两版数据](raw/after-motion.log)"%(center["distance_m"],center["hero_hits"],center["hero_received"],center["end_tick"]),
    "- 弓手连续实录 %d 帧，主角命中 %d 次，镜头随后沿交战线移向冲车。两军累计有效命中 %d / %d 次，累计伤亡 %d / %d。此片按正常 30 帧时基录制，设备性能见实测表。 [原始日志](raw/battlefield-motion.log)"%(line_receipt["frames"],line_receipt["hero_hits"],*line_receipt["hits"],*line_receipt["losses"]),
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
    "八次独立进程均以空游戏数据启动，覆盖兼容后端、Metal、焦点控制与默认窗口。系统图形驱动和 WindowServer 缓存按实际宿主状态保留。兼容后端第一次首帧 %.2f 秒，第二次 %.2f 秒。每次记录首帧、前台、部署、首次模拟和命中。 [原始时序和启动日志](raw/renderer-comparison.json)"%(mac["samples"][0]["launch_milestones_ms"]["first_post_draw"]/1000,mac["samples"][-1]["launch_milestones_ms"]["first_post_draw"]/1000),
    "",
    "## 战役与存档回归",
    "",
    "- 实际输入覆盖%s，并覆盖骑乘、下马、战车、部署、号令、敌我军官、救援、继任、护送与战后结算。主流程经过 %d 个可交互阶段，从营地读档并推进 %d 小时。 [武器与载具](raw/field-controls.log) · [将领](raw/field-officers.log) · [军令与战报](raw/journey.log) · [护送](raw/field-escort-gui.log) · [胜负分支](raw/field-outcomes.log)"%("、".join(r["weapon"] for r in weapons),len(journey["screens"]),journey["camp_hours"]),
    "- 原始 RC3 写出的破门存档从第 %d 步继续至第 %d 步。逐字段差异数 %d。历史 v3、v4 存档和游戏内驻营继续已分别复验。 [跨版复验](raw/rc3-resume.log) · [历史样本](raw/field-history.log)"%(rc3_history["start_tick"],rc3_history["resumed_tick"],len(rc3_history["different_keys"])),
    "",
    "## 源码、素材与复现",
    "",
    "- 候选源码 "+word_link(sha,url+"/commit/"+sha)+"，CI 实际导出的合并树提交 "+word_link(compiled,url+"/commit/"+compiled)+"。"+word_link("游戏 PR #34",url+"/pull/34")+" · "+word_link("CI 与产物",url+"/actions/runs/"+run)+" · "+word_link("RC3 可回退源码",reference),
    "- macOS ZIP 内含可运行的 .app、中文指南及第三方许可。SHA-256 为 `"+apphash+"`。这个散列校验解开 Actions 外层归档后的 Luanshi-macOS.zip。",
    "- 脸部基础网格与形态来自 MakeHuman 的 CC0 数据，衣甲、马具、器械、动作与场景由本项目制作。资产与再分发记录见 "+word_link("人物与动作",url+"/blob/"+sha+"/assets/river_gate/figures/SOURCE.md")+"、"+word_link("马匹",url+"/blob/"+sha+"/assets/art/mounts/README.md")+"、"+word_link("环境",url+"/blob/"+sha+"/assets/environment/README.md")+"。",
    "- 在有 Godot 4.6.3、Xvfb、FFmpeg 和 Python/Pillow 的云端环境签出候选源码，运行 `./tools/compare-river-art.sh` 复拍十二组镜头与正常速度实战。性能与输入流程可重跑 `./tools/test-field-journey.sh` 和 `./tools/test-field-render.sh`。原生启动复验使用 CI macos-runtime 作业。",
]
(dest/"PLAYTEST.md").write_text("\n".join(doc)+"\n")
(dest/"measurements.json").write_text(json.dumps(metrics,ensure_ascii=False,indent=2)+"\n")
print("CANDIDATE_RECEIPT",json.dumps({"sha":sha,"zip_sha256":apphash,"samples":len(frames),"weapons":len(weapons),"camera_pairs":len(before),
    "media_sha256":digest(dest/"playthrough.mp4"),"normal_speed_pair_sha256":digest(dest/"before-after.mp4"),
    "long_film":line_receipt,"native":{r["label"]:[r.get("fps"),r.get("p50_ms"),r.get("p95_ms"),r.get("p99_ms"),r.get("max_rss_bytes")] for r in mac["samples"]}},ensure_ascii=False))
