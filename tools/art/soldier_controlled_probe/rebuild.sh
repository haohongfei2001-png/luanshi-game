#!/usr/bin/env bash
set -euo pipefail
: "${SOLDIER_WORK:?Writable derived source directory required}"
mkdir -p "$SOLDIER_WORK" evidence
# Locked separately published source builders. Not branch-latest or an unknown download.
git fetch --depth=1 origin b778bc0f016a7d339fcd8459e6b622387ad3a755
git archive b778bc0f016a7d339fcd8459e6b622387ad3a755 tools/art/mh_character | tar -x
python tools/art/mh_character/fetch.py "$SOLDIER_WORK/mh-source" 2>&1 | tee evidence/mh-fetch.log
blender -b --disable-autoexec --python-exit-code 1 --python tools/art/mh_character/master.py -- "$SOLDIER_WORK/mh" "$SOLDIER_WORK/mh-source/core" "$SOLDIER_WORK/mh-source/selected" "$SOLDIER_WORK/mh-source/selected/clothes/mindfront_kimono" --official-axes 2>&1 | tee evidence/mh-master.log
python tools/art/sintel_guard/fetch_source.py --output "$SOLDIER_WORK/guardian-source" 2>&1 | tee evidence/guardian-fetch.log
SOURCE="$SOLDIER_WORK/guardian-source/guardians_r854/guardian_lao_tseu.blend"
blender -b --disable-autoexec --python-exit-code 1 --python tools/art/sintel_guard/recut_front.py -- "$SOURCE" "$SOLDIER_WORK/recut" 2>&1 | tee evidence/recut.log
# Retains the existing exact head/helmet provenance. The rejected intermediate
# kit is removed in full by the following stable carrier replacement.
blender -b --disable-autoexec --python-exit-code 1 --python tools/art/sintel_guard/approved_spearman_kit.py -- "$SOLDIER_WORK/recut/recut-editable.blend" "$SOLDIER_WORK/kit-intermediate" 2>&1 | tee evidence/intermediate.log
blender -b --disable-autoexec --python-exit-code 1 --python tools/art/sintel_guard/young_head_module.py -- "$SOLDIER_WORK/kit-intermediate/spearman-kit-editable.blend" "$SOLDIER_WORK/mh/source/mh_natural_editable.blend" "$SOLDIER_WORK/face" 2>&1 | tee evidence/face.log
blender -b --disable-autoexec --python-exit-code 1 --python tools/art/sintel_guard/spearman_helmet.py -- "$SOLDIER_WORK/face/young-face-kit-editable.blend" "$SOLDIER_WORK/helmet" 2>&1 | tee evidence/helmet.log
# Latest ray-projected shoulders are rejected. Stable earlier source is selected
# EXPLICITLY, not misrepresented as the latest failed geometry or art acceptance.
git fetch --depth=1 origin 53c08673c47191650315fddb7dfe0ef2a34f2c83
git show 53c08673c47191650315fddb7dfe0ef2a34f2c83:tools/art/sintel_guard/spearman_carrier_rebuild.py > "$SOLDIER_WORK/carrier-baseline.py"
blender -b --disable-autoexec --python-exit-code 1 --python "$SOLDIER_WORK/carrier-baseline.py" -- "$SOLDIER_WORK/helmet/helmet-kit-editable.blend" "$SOLDIER_WORK/carrier" 2>&1 | tee evidence/carrier.log
blender -b --disable-autoexec --python-exit-code 1 --python tools/art/sintel_guard/spearman_grip_study.py -- "$SOLDIER_WORK/carrier/soldier-carrier-editable.blend" "$SOLDIER_WORK/grip" 2>&1 | tee evidence/grip.log
blender -b --disable-autoexec --python-exit-code 1 --python tools/art/sintel_guard/spearman_controlled_walk.py -- "$SOLDIER_WORK/grip/soldier-grip-editable.blend" assets/ubc_lab/source/UAL1_Standard.glb "$SOLDIER_WORK/walk" 2>&1 | tee evidence/walk.log
blender -b --disable-autoexec --python-exit-code 1 --python tools/art/sintel_guard/spearman_single_thrust.py -- "$SOLDIER_WORK/grip/soldier-grip-editable.blend" "$SOLDIER_WORK/thrust" 2>&1 | tee evidence/thrust.log
blender -b --disable-autoexec --python-exit-code 1 --python tools/art/soldier_controlled_probe/export.py -- "$SOLDIER_WORK/walk/soldier-controlled-walk.blend" "$SOLDIER_WORK/thrust/soldier-single-thrust.blend" "$SOLDIER_WORK/cache" 2>&1 | tee evidence/cache-export.log
blender -b --disable-autoexec --python-exit-code 1 --python tools/art/soldier_controlled_probe/boot_contact.py -- "$SOLDIER_WORK/walk/soldier-controlled-walk.blend" "$SOLDIER_WORK/thrust/soldier-single-thrust.blend" evidence/boot-contact.json 2>&1 | tee evidence/boot-contact.log
cp "$SOLDIER_WORK/walk/report.json" evidence/author-walk.json
cp "$SOLDIER_WORK/thrust/report.json" evidence/author-thrust.json
python - "$SOLDIER_WORK/cache/character.json" <<'PY'
import json,sys,pathlib
r=json.load(open(sys.argv[1]));r['meshes']=[{k:v for k,v in m.items() if k not in ['uv','surfaces']} for m in r['meshes']]
pathlib.Path('evidence/source-cache-summary.json').write_text(json.dumps(r,indent=2))
PY
