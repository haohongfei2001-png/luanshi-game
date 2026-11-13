"""Record the unmodified exported game's foreground window using ordinary X11 inputs."""
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import time

out, seq = (Path(v).resolve() for v in sys.argv[1:3])
binary = Path(sys.argv[3]).resolve()
for folder in (out, seq, seq / "xdg"):
    folder.mkdir(parents=True, exist_ok=True)
env = dict(os.environ, XDG_DATA_HOME=str(seq/"xdg"), XDG_CONFIG_HOME=str(seq/"config"), XDG_CACHE_HOME=str(seq/"cache"), LIBGL_ALWAYS_SOFTWARE="1")
def run(cmd, **kw):
    return subprocess.run(cmd, check=True, **kw)
def xd(*args):
    run(["xdotool", *map(str, args)])
def tap(key):
    xd("keydown", key)
    time.sleep(.15)
    xd("keyup", key)
def play(frame, label, *events):
    for event in events:
        if isinstance(event, str):
            tap(event)
        else:
            xd(*event)
    timeline.append({"movie_frame":frame, "input":label})
    print("PACKAGE_CONTROL", frame, label, flush=True)
def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

timeline = []
# Frame numbers are movie frames, independent of hosted GPU rendering speed.
schedule = [
    (7, "准备时选择弓", [("mousemove",210,301),("click","1"),("key","Home"),("key","--repeat","5","--delay","90","Down"),"Return"]),
    (17, "将各队设为协同攻门", [("mousemove",210,264),("click","1"),("key","Home"),"Down","Return"]),
    (30, "从军议按钮开战", [("mousemove",148,444),("click","1"),("mousemove",858,375)]),
    (48, "向前短行", [("keydown","d")]),
    (55, "停步，瞄向阵前", [("keyup","d"),("mousemove",883,351),("keydown","j")]),
    (95, "发出前压军令", ["1"]),
    (139, "抬弓发动技能", ["q"]),
    (184, "松开普通攻击", [("keyup","j")]),
    (212, "使用第二项技能", ["e"]),
    (255, "观察两翼队列", [("mousemove",770,410),("click","--repeat","3","5")]),
    (347, "拉回主角", ["c",("click","--repeat","3","4")]),
    (385, "前锋集结", ["2"]),
    (462, "在小地图观察城门", [("mousemove",1212,102),("click","1"),("mousemove",805,377)]),
    (558, "拉远看城门", [("click","--repeat","2","5")]),
    (665, "回到操作者", ["c",("click","--repeat","2","4")]),
    (735, "瞄向交战方向", [("mousemove",831,388),"e"]),
    (805, "观察城内目标", [("mousemove",1212,102),("click","1"),("mousemove",805,377)]),
]
total = 960
cmd = [str(binary), "--display-driver","x11","--resolution","1280x800","--disable-vsync","--write-movie",str(seq/"field.png"),"--fixed-fps","24","--quit-after",str(total),"--","--field-profile"]
with (out/"export-window.log").open("w") as log:
    p = subprocess.Popen(cmd, cwd=binary.parent, env=env, stdout=log, stderr=subprocess.STDOUT)
    focused = False
    prev, last = 0, time.monotonic()
    checkpoint = 0
    try:
        while p.poll() is None:
            count = sum(1 for _ in seq.glob("field*.png"))
            if count > prev:
                prev, last = count, time.monotonic()
            # The hosted software renderer can take more than a second per movie frame.
            # The job bounds wall time. Here the failure condition is lack of new frames.
            if count >= checkpoint + 96:
                checkpoint = count
                captures = sorted(seq.glob("field*.png"))
                shutil.copyfile(captures[-2], out/"last-progress.png")
                state = {"frames": count, "expected": total, "inputs": timeline}
                (out/"capture-progress.json").write_text(json.dumps(state, ensure_ascii=False)+"\n")
                print("PACKAGE_FRAMES", count, "of", total, flush=True)
            if time.monotonic() - last > 115:
                raise RuntimeError(f"No new movie frame for 115 seconds (last {count}): {(out/'export-window.log').read_text()[-2500:]}")
            if count>=3 and not focused:
                matches = subprocess.run(["xdotool","search","--onlyvisible","--pid",str(p.pid)],capture_output=True,text=True).stdout.split()
                if matches:
                    xd("windowfocus","--sync",matches[-1])
                    focused = True
            if focused:
                while schedule and count>=schedule[0][0]:
                    at, label, events=schedule.pop(0)
                    play(count, label, *events)
            time.sleep(.15)
        if p.returncode or not focused or schedule:
            raise RuntimeError(f"Package exited {p.returncode}, focused {focused}, pending {len(schedule)}: {(out/'export-window.log').read_text()[-2600:]}")
    finally:
        if p.poll() is None:
            p.terminate()
            p.wait(timeout=20)
pictures=sorted(seq.glob("field*.png"))
assert total-1<=len(pictures)<=total+1, len(pictures)
scene_json=next((seq/"xdg").rglob("river-gate-*.jsonl"))
facts=[json.loads(s) for s in scene_json.read_text().splitlines() if s.strip()]
fight=[s for s in facts if s["kind"]=="frames"]
assert fight and all(s["ordinary_rosters"]==[512,512] for s in fight), [s["kind"] for s in facts]
assert sum(s["hits_in_window"] for s in fight)>20 and any(s["visible_combat_poses"]>0 for s in fight), fight
assert any(s["camera_travel"]>0.1 for s in fight), "Camera movement not recorded"
assert max(s["end_tick"] for s in fight)>=570, "Only a short burst of live battle was recorded"
host=next(s for s in facts if s["kind"]=="host")
assert host["platform"]=="Linux" and host["revision"]==os.environ["EXPECTED_EXPORT"],host
assert all(s["estimated_internal_px"]==[1280,800] and s["internal_scale"]==1 for s in fight)
match=re.search(r"(\d+)\.png$", pictures[0].name)
assert match, pictures[0].name
pattern=pictures[0].name[:match.start(1)]+"%0"+str(len(match.group(1)))+"d.png"
video=out/"combat-normal-speed.mp4"
run(["ffmpeg","-nostdin","-loglevel","error","-y","-framerate","24","-start_number",str(int(match.group(1))),"-i",str(seq/pattern),"-i",str(seq/"field.wav"),"-map","0:v:0","-map","1:a:0","-c:v","libx264","-preset","fast","-crf","23","-pix_fmt","yuv420p","-c:a","aac","-b:a","112k","-movflags","+faststart",str(video)])
streams=json.loads(run(["ffprobe","-v","error","-show_entries","stream=codec_name,channels,width,height,duration,nb_frames,avg_frame_rate","-of","json",str(video)],capture_output=True,text=True).stdout)["streams"]
mix=run(["ffmpeg","-nostdin","-hide_banner","-i",str(video),"-vn","-af","volumedetect","-f","null","-"],capture_output=True,text=True).stderr
peak=float(re.search(r"max_volume: ([-.0-9]+) dB",mix).group(1))
mean=float(re.search(r"mean_volume: ([-.0-9]+) dB",mix).group(1))
assert streams[0]["avg_frame_rate"]=="24/1" and int(streams[0]["nb_frames"])==len(pictures) and streams[1]["channels"]==2
assert 39<=float(streams[0]["duration"])<=41 and abs(float(streams[0]["duration"])-float(streams[1]["duration"]))<.2
assert -60<peak<=0 and mean>-78, (peak,mean)
run(["ffmpeg","-nostdin","-loglevel","error","-y","-i",str(video),"-vf",r"select=not(mod(n\,96)),scale=384:-2,tile=2x5:padding=2","-frames:v","1",str(out/"export-sequence.jpg")])
report={"export":host["revision"],"host":host,"movie_sha256":sha(video),"binary_sha256":sha(binary),"package_sha256":os.environ["PACKAGE_HASH"],"streams":streams,"mix":{"mean_db":mean,"peak_db":peak},"inputs":timeline,"samples":[{k:r[k] for k in ("start_tick","end_tick","per_side","visible_combat_poses","hits_in_window","losses","gate_hp","estimated_internal_px","camera_size","camera_travel")} for r in fight],"accepted_actions":[r for r in facts if r["kind"]=="accepted_action_to_frame_post_draw"],"performance_use":False}
(out/"export-recording.json").write_text(json.dumps(report,indent=2,ensure_ascii=False)+"\n")
print("EXPORTED_WINDOW_PASS",json.dumps({k:report[k] for k in ("movie_sha256","streams","mix","samples")}),flush=True)
