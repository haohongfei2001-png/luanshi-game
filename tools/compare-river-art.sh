#!/usr/bin/env bash
# Replay RC2 and this shipping revision on one GPU, with the same seed, camera and live orders.
set -euo pipefail
cd "$(dirname "$0")/.."
repo_dir=$PWD
baseline=71889537db0d74b9cf6f372d50c830e9e5e32278
out=$PWD/artifacts/river-art-comparison
work=$(mktemp -d)
mkdir -p "$out"
touch "$PWD/artifacts/.gdignore"
for side in before after; do
  revision=$baseline
  if [[ $side == after ]]; then revision=HEAD; fi
  mkdir -p "$work/$side"
  git archive "$revision" | tar -x -C "$work/$side"
  cp tests/river_art_capture.gd "$work/$side/tests/"
  (
    cd "$work/$side"
    export XDG_DATA_HOME="$work/$side-data" XDG_CACHE_HOME="$work/$side-cache" XDG_CONFIG_HOME="$work/$side-config"
    mkdir -p artifacts
    touch artifacts/.gdignore
    ./tools/prepare-font.sh
    godot --headless --editor --path . --import >"$out/$side-import.log" 2>&1
    if grep -E 'SCRIPT ERROR|SHADER ERROR|Parse Error|ERROR:' "$out/$side-import.log"; then exit 1; fi
    timeout 240s xvfb-run -a -s '-screen 0 1280x800x24' godot --path . --resolution 1280x800 --audio-driver Dummy --disable-vsync --fixed-fps 20 --script tests/river_art_capture.gd -- --field-size=512 2>&1 | tee "$out/$side-window.log"
    if grep -E 'SCRIPT ERROR|SHADER ERROR|Parse Error|ERROR:' "$out/$side-window.log"; then exit 1; fi
    grep -q '^RIVER_ART_PASS' "$out/$side-window.log"
    cp -a artifacts/river-art "$out/$side"
    ffmpeg -nostdin -loglevel error -y -framerate 10 -i "$out/$side/film/frame-%03d.jpg" -c:v libx264 -crf 20 -pix_fmt yuv420p -movflags +faststart "$out/$side.mp4"
  )
done
cd "$repo_dir"
python3 - "$out" <<'PY'
import base64, io, json, pathlib, sys
from PIL import Image, ImageChops, ImageStat
root=pathlib.Path(sys.argv[1])
left,right=[json.loads((root/s/"frames.json").read_text()) for s in ("before","after")]
assert len(left)==len(right)>=10
for old,new in zip(left,right):
    for key in ("label","tick","center","yaw","zoom","seed","ordinary","officers","contact","losses","gate_hp","in_frame_count","in_frame_ids_sha256","window","internal_scale","shadows"):
        assert old[key]==new[key], (key,old,new)
    assert new["shadows"] and new["internal_scale"]==1
    name=new["label"]
    l,r=[Image.open(root/s/(name+".jpg")).convert("RGB") for s in ("before","after")]
    error=sum(ImageStat.Stat(ImageChops.difference(l,r)).mean)/3
    print("RIVER_PIXEL_DELTA",name,round(error,3))
    pair=Image.new("RGB",(1600,500))
    for i,pic in enumerate((l,r)):
        pair.paste(pic.resize((800,500),Image.Resampling.LANCZOS),(i*800,0))
    pair.save(root/(name+"-pair.jpg"),quality=91)
    if name in ("hero","contact","saddle","gate","formation","camp","bowline","officer"):
        sample=io.BytesIO()
        pair.resize((1024,320),Image.Resampling.LANCZOS).save(sample,"JPEG",quality=81)
        print("RIVER_PAIR_JPEG",name,base64.b64encode(sample.getvalue()).decode())
print("RIVER_PAIR_PASS",len(left))
PY
ffmpeg -nostdin -loglevel error -y -i "$out/before.mp4" -i "$out/after.mp4" -filter_complex '[0:v]scale=768:480[l];[1:v]scale=768:480[r];[l][r]hstack=inputs=2' -c:v libx264 -crf 22 -pix_fmt yuv420p -movflags +faststart "$out/river-contact-pair.mp4"
