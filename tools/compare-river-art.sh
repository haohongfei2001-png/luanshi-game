#!/usr/bin/env bash
# Replay RC12 and this shipping revision on one GPU, with the same seed, camera and live orders.
set -euo pipefail
cd "$(dirname "$0")/.."
repo_dir=$PWD
baseline=e627086d985f0e458f187f4d691e816471574912
out=$PWD/artifacts/river-art-comparison
work=$(mktemp -d)
mkdir -p "$out"
touch "$PWD/artifacts/.gdignore"
for side in before after; do
  revision=$baseline
  if [[ $side == after ]]; then revision=HEAD; fi
  mkdir -p "$work/$side"
  git archive "$revision" | tar -x -C "$work/$side"
  cp tests/river_art_capture.gd tests/field_motion_review.gd tests/field_contact_window.gd "$work/$side/tests/"
  (
    cd "$work/$side"
    export XDG_DATA_HOME="$work/$side-data" XDG_CACHE_HOME="$work/$side-cache" XDG_CONFIG_HOME="$work/$side-config"
    mkdir -p artifacts
    touch artifacts/.gdignore
    ./tools/prepare-font.sh
    godot --headless --editor --path . --import >"$out/$side-import.log" 2>&1
    if grep -E 'SCRIPT ERROR|SHADER ERROR|Parse Error|ERROR:' "$out/$side-import.log"; then exit 1; fi
    timeout 270s xvfb-run -a -s '-screen 0 1920x1200x24' godot --path . --resolution 1920x1200 --audio-driver Dummy --disable-vsync --fixed-fps 20 --script tests/river_art_capture.gd -- --field-size=512 2>&1 | tee "$out/$side-window.log"
    if grep -E 'SCRIPT ERROR|SHADER ERROR|Parse Error|ERROR:' "$out/$side-window.log"; then exit 1; fi
    grep -q '^RIVER_ART_PASS' "$out/$side-window.log"
    cp -a artifacts/river-art "$out/$side"
    cp "$repo_dir/tests/river_contact_seed61112.json" artifacts/contact-plan.json
    timeout 190s xvfb-run -a -s '-screen 0 1920x1200x24' godot --path . --resolution 1920x1200 --audio-driver Dummy --disable-vsync --fixed-fps 20 --script tests/field_contact_window.gd -- --field-size=512 2>&1 | tee "$out/$side-contact.log"
    grep -q '^FIELD_CONTACT_WINDOW true' "$out/$side-contact.log"
    if grep -E 'SCRIPT ERROR|SHADER ERROR|Parse Error|ERROR:' "$out/$side-contact.log"; then exit 1; fi
    cp -a artifacts/contact-window "$out/$side/melee"
    for action in shield stagger; do
      ffmpeg -nostdin -loglevel error -y -framerate 20 -i "$out/$side/melee/$action-%02d.jpg" -c:v libx264 -crf 19 -pix_fmt yuv420p -movflags +faststart "$out/$side/melee/$action.mp4"
    done
    timeout 340s xvfb-run -a -s '-screen 0 1280x800x24' godot --path . --resolution 1280x800 --disable-vsync --write-movie "$work/$side-motion.avi" --fixed-fps 30 --script tests/field_motion_review.gd -- --field-size=512 2>&1 | tee "$out/$side-motion.log"
    if grep -E 'SCRIPT ERROR|SHADER ERROR|Parse Error|ERROR:' "$out/$side-motion.log"; then exit 1; fi
    grep -q '^FIELD_MOTION_RECEIPT ' "$out/$side-motion.log"
    ffmpeg -nostdin -loglevel error -y -i "$work/$side-motion.avi" -map 0:v:0 -map 0:a:0 -c:v libx264 -crf 21 -pix_fmt yuv420p -c:a aac -movflags +faststart "$out/$side-motion.mp4"
    if [[ $side == after ]]; then
      # The full scene above is a theatre tour. Also archive a real landed hit
      # on the ordinary follow camera, without changing troop positions or HP.
      timeout 240s xvfb-run -a -s '-screen 0 1920x1200x24' godot --path . --resolution 1920x1200 --audio-driver Dummy --disable-vsync --fixed-fps 30 --script tests/rc7_personal_contact.gd -- --field-size=512 2>&1 | tee "$out/after-personal.log"
      grep -q '^RC7_PERSONAL_PASS' "$out/after-personal.log"
      if grep -E 'SCRIPT ERROR|SHADER ERROR|Parse Error|ERROR:' "$out/after-personal.log"; then exit 1; fi
      python3 tools/check_playfield.py artifacts/personal-contact/personal-{windup,contact}.png
      cp -a artifacts/personal-contact "$out/normal-22m"
      python3 - "$out/normal-22m" <<'PY'
import base64, hashlib, os.path, sys
from pathlib import Path
from PIL import Image
folder=Path(sys.argv[1])
for name,width,quality in (("normal-review",1280,88),("normal-full",1920,91)):
    im=Image.open(folder/"personal-contact.png").convert("RGB")
    if im.width!=width: im=im.resize((width,round(im.height*width/im.width)),Image.Resampling.LANCZOS)
    target=folder/(name+".jpg"); im.save(target,quality=quality,subsampling=0)
    data=target.read_bytes(); encoded=base64.b64encode(data).decode()
    print("RC8_WINDOW_INFO",name,len(data),hashlib.sha256(data).hexdigest(),len(encoded),flush=True)
    for at in range(0,len(encoded),16000): print("RC8_WINDOW_PART",name,at,encoded[at:at+16000],flush=True)
PY
      python3 tools/watch_field_film.py xvfb-run -a -s '-screen 0 1280x800x24' godot --path . --resolution 1280x800 --disable-vsync --write-movie "$work/line.avi" --fixed-fps 30 --script tests/field_motion_review.gd -- --field-size=512 --field-line-film 2>&1 | tee "$out/battlefield-motion.log"
      grep -q '^FIELD_LINE_FILM ' "$out/battlefield-motion.log"
      if grep -E 'SCRIPT ERROR|SHADER ERROR|Parse Error|ERROR:' "$out/battlefield-motion.log"; then exit 1; fi
      ffmpeg -nostdin -loglevel error -y -i "$work/line.avi" -map 0:v:0 -map 0:a:0 -c:v libx264 -crf 21 -pix_fmt yuv420p -c:a aac -b:a 112k -movflags +faststart "$out/battlefield-motion.mp4"
    fi
    ffmpeg -nostdin -loglevel error -y -framerate 10 -i "$out/$side/film/frame-%03d.jpg" -c:v libx264 -crf 20 -pix_fmt yuv420p -movflags +faststart "$out/$side.mp4"
  )
done
cd "$repo_dir"
python3 - "$out" <<'PY'
import base64, hashlib, io, json, pathlib, sys
from PIL import Image, ImageChops, ImageStat
root=pathlib.Path(sys.argv[1])
left,right=[json.loads((root/s/"frames.json").read_text()) for s in ("before","after")]
assert len(left)==len(right)>=10
before,after=[json.loads((root/s/"melee/states.json").read_text()) for s in ("before","after")]
assert before==after and len(after)==36
events=json.loads(pathlib.Path("tests/river_contact_seed61112.json").read_text())
for e in events:
    subject=[r for r in after if r["kind"]==e["kind"]]
    prior,impact=[next(r for r in subject if r["tick"]==t) for t in (e["tick"]-1,e["tick"])]
    assert impact["hp"]<prior["hp"] and impact["received"]>prior["received"]
    if e["kind"]=="shield": assert impact["blocked"]>prior["blocked"]
    print("MELEE_CONTACT",json.dumps({"event":e,"prior":prior,"impact":impact},separators=(",",":")))
    sheet=Image.new("RGB",(1440,636))
    for row,side in enumerate(("before","after")):
        for col,key in enumerate((4,7,9)):
            pic=Image.open(root/side/"melee"/("%s-native-%02d.png"%(e["kind"],key))).convert("RGB")
            assert pic.size==(1920,1200)
            sheet.paste(pic.crop((720,400,1200,718)),(col*480,row*318))
    target=root/(e["kind"]+"-response.jpg"); sheet.save(target,quality=91,subsampling=0)
    raw=target.read_bytes(); wire=base64.b64encode(raw).decode()
    print("RC8_WINDOW_INFO",e["kind"]+"-response",len(raw),hashlib.sha256(raw).hexdigest(),len(wire))
    for i in range(0,len(wire),16000): print("RC8_WINDOW_PART",e["kind"]+"-response",i,wire[i:i+16000])
for old,new in zip(left,right):
    for key in ("label","tick","hero_state","hero_kit","hero_slot","center","yaw","zoom","seed","ordinary","officers","contact","losses","gate_hp","in_frame_count","in_frame_ids_sha256","window","internal_scale","msaa_3d","screen_space_aa","shadows"):
        assert old[key]==new[key], (key,old,new)
    assert new["shadows"] and new["internal_scale"]==1
    name=new["label"]
    l,r=[Image.open(root/s/(name+".png")).convert("RGB") for s in ("before","after")]
    assert l.size==r.size==(1920,1200), (name,l.size,r.size)
    if name in ("hero","officer","contact","formation","player-action"):
        # Equal coordinates on the delivered PNG. Never interpolate the comparison of fine edges.
        w,h=l.size
        box=(w//2-258,h//2-247,w//2+258,h//2+176)
        crop=Image.new("RGB",(2*(box[2]-box[0]),box[3]-box[1]))
        for i,pic in enumerate((l,r)):
            crop.paste(pic.crop(box),(i*(box[2]-box[0]),0))
        crop.save(root/(name+"-native-pair.png"))
    error=sum(ImageStat.Stat(ImageChops.difference(l,r)).mean)/3
    print("RIVER_PIXEL_DELTA",name,round(error,3))
    pair=Image.new("RGB",(1600,500))
    for i,pic in enumerate((l,r)):
        pair.paste(pic.resize((800,500),Image.Resampling.LANCZOS),(i*800,0))
    pair.save(root/(name+"-pair.jpg"),quality=91)
    if name in ("hero","contact","saddle","gate","formation","camp","bowline","officer","bank","player-action"):
        sample=io.BytesIO()
        pair.resize((1024,320),Image.Resampling.LANCZOS).save(sample,"JPEG",quality=81)
        print("RIVER_PAIR_JPEG",name,base64.b64encode(sample.getvalue()).decode())
    if name in ("player-action","formation","gate"):
        # One normal-view frame at the captured dimensions, easy to inspect outside the ZIP.
        sample=io.BytesIO()
        r.save(sample,"JPEG",quality=89,subsampling=0)
        print("RIVER_WINDOW_JPEG",name,base64.b64encode(sample.getvalue()).decode())
print("RIVER_PAIR_PASS",len(left))
PY
ffmpeg -nostdin -loglevel error -y -i "$out/before.mp4" -i "$out/after.mp4" -filter_complex '[0:v]scale=768:480[l];[1:v]scale=768:480[r];[l][r]hstack=inputs=2' -c:v libx264 -crf 22 -pix_fmt yuv420p -movflags +faststart "$out/river-contact-pair.mp4"
ffmpeg -nostdin -loglevel error -y -i "$out/before-motion.mp4" -i "$out/after-motion.mp4" -filter_complex '[0:v]scale=768:480[l];[1:v]scale=768:480[r];[l][r]hstack=inputs=2[v]' -map '[v]' -map 1:a:0 -c:v libx264 -crf 21 -pix_fmt yuv420p -c:a copy -movflags +faststart "$out/footwork-pair.mp4"
