"""Verify and index the already encoded Movie Maker file without recoding a single frame."""
from pathlib import Path
import hashlib, json, math, os, re, subprocess, sys
from PIL import Image
folder=Path(sys.argv[1])
def run(args,**kw): return subprocess.run(args,check=True,**kw)
def sha(path): return hashlib.sha256(path.read_bytes()).hexdigest()
facts=json.loads((folder/"input-and-camera.json").read_bytes())
video=folder/"river-gate-bridgehead.mp4"
metadata=json.loads(run(["ffprobe","-v","error","-show_entries","stream=codec_name,width,height,avg_frame_rate,channels,duration,nb_frames","-of","json",str(video)],capture_output=True,text=True).stdout)
v,a=metadata["streams"]
caplog=(folder/"window.log").read_text()
n,fps=map(int,re.search(r"(\d+) frames at (\d+) FPS \(movie length",caplog).groups())
duration=float(v["duration"])
stills=sorted(folder.glob("view-*.jpg"))
image_size=list(Image.open(stills[0]).size)
assert [v["width"],v["height"]]==image_size==[1600,1000],(image_size,v,facts["resolution"])
assert v["codec_name"]=="h264" and int(v["nb_frames"])==n and fps==24 and v["avg_frame_rate"]=="24/1"
assert facts["internal"]==1. and len(facts["frames"])>570 and facts["ordinary"]==[512,512]
assert a["codec_name"]=="aac" and a["channels"]==2 and abs(float(a["duration"])-duration)<.12
assert abs(duration-n/fps)<.001 and 30<=duration<=45
battle_seconds=(facts["last"]["tick"]-facts["frames"][0]["tick"])/20.
assert abs((n-facts["first_game_frame"])/fps-battle_seconds)<.4,(n,battle_seconds)
assert all(r["both_landmarks"] and abs(r["center"][0]-34.2)<.01 and abs(r["center"][1]-1.)<.01 and abs(r["zoom"]-22)<.001 and r["feet_in_deep_water"]==0 for r in facts["frames"])
assert "BRIDGE_WINDOW true" in caplog and facts["world_audit"] and facts["first_player_strike"]>0 and len(facts["shield_contacts"])>0
stats=run(["ffmpeg","-hide_banner","-i",str(video),"-vn","-af","volumedetect","-f","null","-"],capture_output=True,text=True).stderr
peak=float(re.search(r"max_volume: ([-.0-9]+) dB",stats)[1])
assert -60<peak<=0
for name,tick in [("approach",50),("first-contact",facts["first_player_strike"]),("gate",355)]:
    p=min(stills,key=lambda x:abs(int(x.stem.split("-")[1])-tick))
    with Image.open(p) as im:
        im.thumbnail((1152,720));im.save(folder/(name+"-preview.jpg"),quality=94,subsampling=0)
run(["ffmpeg","-nostdin","-loglevel","error","-y","-i",str(video),"-vf",r"select=eq(n\,48)+eq(n\,132)+eq(n\,178)+eq(n\,280)+eq(n\,470)+eq(n\,705),scale=320:200,tile=3x2:padding=2","-frames:v","1",str(folder/"sequence.jpg")])
stamp={"game_source":sys.argv[2],"capture_run":sys.argv[3],"export_candidate":sys.argv[4],"file":video.name,"sha256":sha(video),"bytes":video.stat().st_size,
       "fps":fps,"frames":n,"seconds":duration,"battle_seconds":battle_seconds,"physical_capture_pixels":image_size,"logical_root_size":facts["resolution"],
       "original_audio":{"channels":a["channels"],"peak_db":peak,"seconds":float(a["duration"])},"encoded":metadata,"held_camera_frames_sampled":len(facts["frames"]),"camera_metres":22,
       "pitch_deg":math.degrees(facts["last"]["pitch"]),"yaw_deg":math.degrees(facts["last"]["yaw"]),"seed":facts["seed"],"first_player_contact_seconds":facts["first_player_strike"]/20.,
       "rank_spear_hits_observed":len(facts["rank_spear_contacts"]),"rank_shield_hits_observed":len(facts["shield_contacts"]),"ordinary":facts["ordinary"],"officers":facts["officers"],"last":facts["last"],
       "real_input":"Regular deployment menu, native X11 click, WASD, pointer aim, skill and order keys. Original stereo. Fixed Godot simulation speed.","device_framerate_measurement":False}
(folder/"recording.json").write_text(json.dumps(stamp,indent=2,ensure_ascii=False)+"\n")
files=[video,folder/"recording.json",folder/"input-and-camera.json",*sorted(folder.glob("*-preview.jpg"))]
(folder/"SHA256SUMS").write_text("".join(sha(p)+"  "+p.name+"\n" for p in files))
print("ORIGINAL_BRIDGEHEAD",json.dumps(stamp,ensure_ascii=False))
