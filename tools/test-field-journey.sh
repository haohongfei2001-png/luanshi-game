#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p artifacts
touch artifacts/.gdignore
movie_dir="$(mktemp -d)"
trap 'rm -rf "$movie_dir"' EXIT
export LIBGL_ALWAYS_SOFTWARE=1
timeout 240s xvfb-run -a -s '-screen 0 960x600x24' "${GODOT:-godot}" --path . --disable-vsync --resolution 960x600 --write-movie "$movie_dir/journey.avi" --fixed-fps 15 --script tests/field_playthrough.gd -- --field-size=512 2>&1 | tee artifacts/journey.log
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
for frame in artifacts/journey-0*.jpg; do
  name="$(basename "$frame" .jpg)"
  ffmpeg -nostdin -loglevel error -y -i "$frame" -vf scale=640:-2 -frames:v 1 -q:v 4 "$movie_dir/$name.jpg"
  printf 'JOURNEY_IMAGE %s ' "$name"
  base64 -w0 "$movie_dir/$name.jpg"
  printf '\n'
done
