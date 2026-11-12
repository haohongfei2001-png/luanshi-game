#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p artifacts
touch artifacts/.gdignore
movie_dir="$(mktemp -d)"
trap 'rm -rf "$movie_dir"' EXIT
export LIBGL_ALWAYS_SOFTWARE=1
timeout 550s xvfb-run -a -s '-screen 0 960x600x24' "${GODOT:-godot}" --path . --disable-vsync --resolution 960x600 --write-movie "$movie_dir/journey.avi" --fixed-fps 15 --script tests/field_playthrough.gd -- --field-size=512 2>&1 | tee artifacts/journey.log
grep -q '^JOURNEY_PASS ' artifacts/journey.log
if grep -E 'SCRIPT ERROR|Parse Error|SHADER ERROR|ERROR:' artifacts/journey.log; then exit 1; fi
ffmpeg -nostdin -loglevel error -y -i "$movie_dir/journey.avi" -map 0:v:0 -map 0:a:0 -c:v libx264 -preset fast -crf 23 -pix_fmt yuv420p -c:a aac -b:a 112k -movflags +faststart artifacts/river-gate-journey.mp4
ffprobe -v error -show_entries stream=codec_name,channels,width,height,duration,nb_frames -of json artifacts/river-gate-journey.mp4 > artifacts/journey-media.json
ffmpeg -nostdin -hide_banner -i artifacts/river-gate-journey.mp4 -vn -af volumedetect -f null - 2> artifacts/journey-mix.log
python3 - <<'PY'
import json, pathlib, re
p = pathlib.Path('artifacts')
v,a=json.loads((p/'journey-media.json').read_text())['streams']
log=(p/'journey-mix.log').read_text()
peak=float(re.search(r'max_volume: ([-.0-9]+) dB',log).group(1))
mean=float(re.search(r'mean_volume: ([-.0-9]+) dB',log).group(1))
assert v['codec_name']=='h264' and a['codec_name']=='aac' and a['channels']==2 and min(float(a['duration']),float(v['duration']))>12 and abs(float(a['duration'])-float(v['duration']))<0.4 and -60<peak<0 and mean>-78
info=dict(streams=[v,a],peak_db=peak,mean_db=mean)
print('JOURNEY_MIX '+json.dumps(info))
(p/'journey-media.json').write_text(json.dumps(info,indent=2))
PY
# The small instant-play copy retains every frame and the real master mix.
python3 - <<'PY'
import hashlib, json, pathlib, subprocess
p=pathlib.Path('artifacts')
orig=json.loads((p/'journey-media.json').read_text())['streams']
length=float(orig[0]['duration'])
rate=max(45,min(215,int(8*1180000/length/1000)-48))
target=p/'river-gate-review.mp4'
subprocess.run(['ffmpeg','-nostdin','-loglevel','error','-y','-i',str(p/'river-gate-journey.mp4'),'-vf','scale=640:400','-c:v','libx264','-preset','fast','-crf','27','-maxrate',str(rate)+'k','-bufsize',str(rate)+'k','-c:a','aac','-b:a','40k','-movflags','+faststart',str(target)],check=True)
data=target.read_bytes()
probe=json.loads(subprocess.check_output(['ffprobe','-v','error','-show_entries','stream=codec_name,channels,duration,nb_frames','-of','json',str(target)]))['streams']
assert len(data)<1450000 and probe[0]['nb_frames']==orig[0]['nb_frames'] and probe[1]['channels']==2 and abs(float(probe[1]['duration'])-float(orig[1]['duration']))<0.10
meta=dict(bytes=len(data),sha256=hashlib.sha256(data).hexdigest(),original_sha256=hashlib.sha256((p/'river-gate-journey.mp4').read_bytes()).hexdigest(),streams=probe)
print('JOURNEY_ARCHIVE '+json.dumps(meta))
(p/'journey-archive.json').write_text(json.dumps(meta,indent=2))
PY
