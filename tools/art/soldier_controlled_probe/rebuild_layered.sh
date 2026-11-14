#!/usr/bin/env bash
set -euo pipefail
: "${SOLDIER_WORK:?Required isolated authoring workspace}"
# Recover exact unchanged current legal source and baseline. Keep baseline cache;
# new geometry is a distinct oracle, never overwrite945's evidence or main.
bash tools/art/soldier_controlled_probe/rebuild.sh
SOURCE="$SOLDIER_WORK/guardian-source/guardians_r854/guardian_lao_tseu.blend"
B=(blender -b --disable-autoexec --python-exit-code 1 --python)
"${B[@]}" tools/art/sintel_guard/soldier_whole_layer_system.py -- "$SOLDIER_WORK/helmet/helmet-kit-editable.blend" "$SOLDIER_WORK/layered-base" 2>&1 | tee evidence/layered-base.log
"${B[@]}" tools/art/sintel_guard/crosscollar_recut.py -- "$SOURCE" "$SOLDIER_WORK/full-sleeves" 2>&1 | tee evidence/full-sleeves.log
"${B[@]}" tools/art/sintel_guard/whole_garment_assembly.py -- "$SOLDIER_WORK/layered-base/soldier-carrier-editable.blend" "$SOLDIER_WORK/full-sleeves/recut-editable.blend" "$SOLDIER_WORK/garment-assembly" 2>&1 | tee evidence/garment-assembly.log
"${B[@]}" tools/art/sintel_guard/cloth_shoe_puttee.py -- "$SOLDIER_WORK/garment-assembly/whole-garment-editable.blend" "$SOLDIER_WORK/cloth-lower" 2>&1 | tee evidence/cloth-lower.log
"${B[@]}" tools/art/sintel_guard/articulated_cuirass.py -- "$SOLDIER_WORK/cloth-lower/whole-shoe-puttee-editable.blend" "$SOLDIER_WORK/cuirass" --no-shoulders 2>&1 | tee evidence/cuirass.log
"${B[@]}" tools/art/sintel_guard/shoulder_pattern_retopology.py -- "$SOLDIER_WORK/cuirass/soldier-carrier-editable.blend" "$SOLDIER_WORK/shoulder-pattern" 2>&1 | tee evidence/shoulder-pattern.log
"${B[@]}" tools/art/sintel_guard/spearman_grip_study.py -- "$SOLDIER_WORK/shoulder-pattern/whole-shoulder-pattern.blend" "$SOLDIER_WORK/layered-grip" 2>&1 | tee evidence/layered-grip.log
"${B[@]}" tools/art/sintel_guard/spearman_controlled_walk.py -- "$SOLDIER_WORK/layered-grip/soldier-grip-editable.blend" assets/ubc_lab/source/UAL1_Standard.glb "$SOLDIER_WORK/layered-walk" 2>&1 | tee evidence/layered-walk.log
"${B[@]}" tools/art/sintel_guard/spearman_single_thrust.py -- "$SOLDIER_WORK/layered-grip/soldier-grip-editable.blend" "$SOLDIER_WORK/layered-thrust" 2>&1 | tee evidence/layered-thrust.log
"${B[@]}" tools/art/sintel_guard/spearman_braced_hit.py -- "$SOLDIER_WORK/layered-grip/soldier-grip-editable.blend" assets/ubc_lab/source/UAL1_Standard.glb "$SOLDIER_WORK/layered-hit" 2>&1 | tee evidence/layered-hit.log
SOLDIER_HIT_SOURCE="$SOLDIER_WORK/layered-hit/soldier-controlled-walk.blend" "${B[@]}" tools/art/soldier_controlled_probe/export.py -- "$SOLDIER_WORK/layered-walk/soldier-controlled-walk.blend" "$SOLDIER_WORK/layered-thrust/soldier-single-thrust.blend" "$SOLDIER_WORK/layered-cache" 2>&1 | tee evidence/layered-export.log
# Explicitly retain the complete new editable masters together with the cache.
# Pose, grip and contact failures remain visible; this is not shipping acceptance.
mkdir -p "$SOLDIER_WORK/layered-cache/editable"
cp "$SOLDIER_WORK/layered-walk/soldier-controlled-walk.blend" "$SOLDIER_WORK/layered-cache/editable/walk.blend"
cp "$SOLDIER_WORK/layered-thrust/soldier-single-thrust.blend" "$SOLDIER_WORK/layered-cache/editable/thrust.blend"
cp "$SOLDIER_WORK/layered-hit/soldier-controlled-walk.blend" "$SOLDIER_WORK/layered-cache/editable/hit-braced.blend"

# These are NEW-source contact measurements, separate from baseline boot-contact.
"${B[@]}" tools/art/soldier_controlled_probe/boot_contact.py -- "$SOLDIER_WORK/layered-walk/soldier-controlled-walk.blend" "$SOLDIER_WORK/layered-thrust/soldier-single-thrust.blend" evidence/layered-boot-contact.json 2>&1 | tee evidence/layered-boot-contact.log
cp "$SOLDIER_WORK/layered-walk/report.json" evidence/layered-author-walk.json
cp "$SOLDIER_WORK/layered-thrust/report.json" evidence/layered-author-thrust.json
cp "$SOLDIER_WORK/layered-hit/report.json" evidence/layered-author-hit-braced.json
python - "$SOLDIER_WORK/layered-cache/character.json" <<'JSONSUMMARY'
import json,sys,pathlib
r=json.load(open(sys.argv[1]));r['meshes']=[{k:v for k,v in m.items() if k not in ['uv','surfaces']} for m in r['meshes']]
pathlib.Path('evidence/layered-source-cache-summary.json').write_text(json.dumps(r,indent=2))
JSONSUMMARY
