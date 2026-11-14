"""Encode every source frame of the normal Godot window, preserving capture time and audio."""
from pathlib import Path
import hashlib
import json
import os
import re
import subprocess
import sys

root = Path(sys.argv[1])
directory = Path(sys.argv[2])
game_sha = sys.argv[3]
facts = json.loads((directory/"input-and-camera.json").read_bytes())
frames = sorted(root.glob("frame*.png"))
number = re.search(r"(\d+)\.png$", frames[0].name)
first = int(number[1])
digits = len(number[1])
assert all(int(re.search(r"(\d+)\.png$",p.name)[1])==first+i for i,p in enumerate(frames))
fps = 24
assert all(row["both_landmarks"] and abs(row["zoom"]-22.)<.001 for row in facts["frames"])
assert all(abs(row["center"][0]-34.2)<.35 and abs(row["center"][1]-1.)<.35 for row in facts["frames"])
duration = len(frames)/fps
battle_seconds = (facts["last"]["tick"]-facts["frames"][0]["tick"])/20.
assert abs(battle_seconds - (len(frames)-facts["first_game_frame"])/fps)<.4,(battle_seconds,duration,facts["first_game_frame"])
def run(cmd,**kw):
    return subprocess.run(cmd,check=True,**kw)
def sha(p):
    return hashlib.sha256(p.read_bytes()).hexdigest()
pattern = frames[0].name[:number.start(1)]+"%0"+str(digits)+"d.png"
movie = directory/"river-gate-bridgehead.mp4"
run(["ffmpeg","-nostdin","-loglevel","error","-y","-framerate",str(fps),"-start_number",str(first),"-i",str(root/pattern),
     "-i",str(root/"frame.wav"),"-map","0:v:0","-map","1:a:0","-c:v","libx264","-preset","fast","-crf","22",
     "-pix_fmt","yuv420p","-c:a","aac","-b:a","128k","-movflags","+faststart",str(movie)])
streams = json.loads(run(["ffprobe","-v","error","-show_entries","stream=codec_name,width,height,avg_frame_rate,channels,duration,nb_frames",
                          "-of","json",str(movie)],capture_output=True,text=True).stdout)["streams"]
assert streams[0]["codec_name"]=="h264" and streams[0]["avg_frame_rate"]=="24/1" and int(streams[0]["nb_frames"])==len(frames)
# Canvas stretch reports its logical size through Window.size. The image read
# from this same viewport is in actual capture pixels, as is the video stream.
from PIL import Image
with Image.open(next(directory.glob("view-*.jpg"))) as source_still:
    physical=list(source_still.size)
assert [streams[0]["width"],streams[0]["height"]]==physical==[2560,1440] and facts["internal"]==1,(physical,streams[0],facts["resolution"])
assert streams[1]["channels"]==2 and abs(float(streams[1]["duration"])-duration)<.12
vol=run(["ffmpeg","-hide_banner","-i",str(movie),"-vn","-af","volumedetect","-f","null","-"],capture_output=True,text=True).stderr
peak=float(re.search(r"max_volume: ([-.0-9]+) dB",vol)[1])
assert -60<peak<=0,vol[-500:]
for name,i in [("approach",max(3,int(fps*2))),("gate",min(len(frames)-1,int(fps*12))),
               ("first-contact" if facts["first_player_strike"]>=0 else "east-bank",min(len(frames)-1,facts["first_game_frame"]+round((facts["first_player_strike"] if facts["first_player_strike"]>=0 else facts["last"]["tick"]*.78)*fps/20)))]:
    with Image.open(frames[i]) as image:
        image.convert("RGB").save(directory/(name+".jpg"),quality=96,subsampling=0)
        thumb=image.copy();thumb.thumbnail((1440,810));thumb.convert("RGB").save(directory/(name+"-preview.jpg"),quality=92,subsampling=0)
# Show six untouched, time-ordered moments without altering the playable video.
tile=Image.new("RGB",(960,421),(29,35,31))
for slot,frac in enumerate((.08,.17,.24,.34,.62,.89)):
    index=min(len(frames)-1,int(len(frames)*frac))
    with Image.open(frames[index]) as image:
        tile.paste(image.convert("RGB").resize((320,200),Image.Resampling.LANCZOS),(320*(slot%3),210*(slot//3)))
tile.save(directory/"sequence.jpg",quality=93,subsampling=0)
receipt={"game_source":game_sha,"capture_source":os.environ.get("GITHUB_SHA"),"capture_run":os.environ.get("GITHUB_RUN_ID"),"mode":"Godot Movie Maker 24 successive game frames per simulated second; physical keyboard and pointer input; no game-state writes",
         "fps":fps,"physical_capture_px":physical,"logical_root":facts["resolution"],"seconds":duration,"simulated_battle_seconds":battle_seconds,"source_frame_count":len(frames),"streams":streams,
         "source_frame_range":[first,first+len(frames)-1],"max_signal_db":peak,"sha256":sha(movie),"bytes":movie.stat().st_size,
         "summary":{k:v for k,v in facts.items() if k!="frames"},"device_framerate_measurement":False,"gameplay_review_pass":bool(facts["sampled_ticks"]>200 and facts["last"]["hero_impacts"]>0 and facts["last"]["soldier_shield_contacts"]>0 and duration>=30)}
(directory/"recording.json").write_text(json.dumps(receipt,indent=2,ensure_ascii=False)+"\n")
print("BRIDGE_FILM",json.dumps({k:v for k,v in receipt.items() if k!="summary"},ensure_ascii=False))
assert receipt["gameplay_review_pass"], "The intact recorded attempt is archived; one or more actual combat acceptance checks failed."
