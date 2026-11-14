#!/usr/bin/env bash
set -euo pipefail
: "${HEAD_BUILD:?}" "${SOURCE_REPO:?}" "${ORACLE_REPO:?}"
mkdir -p "$HEAD_BUILD" "$ORACLE_REPO/evidence"
cd "$SOURCE_REPO"
test "$(git rev-parse HEAD)" = 945b2c676705460f97ba0d9e5c9d892f2a64390d
git fetch --depth=1 origin b778bc0f016a7d339fcd8459e6b622387ad3a755
git archive b778bc0f016a7d339fcd8459e6b622387ad3a755 tools/art/mh_character | tar -x
python tools/art/mh_character/fetch.py "$HEAD_BUILD/mh-source"
python tools/art/sintel_guard/fetch_source.py --output "$HEAD_BUILD/guardian-source"
function saved_stage() {
 local name=$1; local builder=$2; shift 2
 blender --background --disable-autoexec --python-exit-code 1 --python "$ORACLE_REPO/tools/art/soldier_runtime/run_save_stage.py" -- "$builder" "$ORACLE_REPO/evidence/$name-builder.json" "$@"
}
PINNED_BUILDER_COMMIT=b778bc0f016a7d339fcd8459e6b622387ad3a755 saved_stage mh tools/art/mh_character/master.py "$HEAD_BUILD/mh" "$HEAD_BUILD/mh-source/core" "$HEAD_BUILD/mh-source/selected" "$HEAD_BUILD/mh-source/selected/clothes/mindfront_kimono" --official-axes
saved_stage recut tools/art/sintel_guard/recut_front.py "$HEAD_BUILD/guardian-source/guardians_r854/guardian_lao_tseu.blend" "$HEAD_BUILD/recut"
saved_stage kit tools/art/sintel_guard/approved_spearman_kit.py "$HEAD_BUILD/recut/recut-editable.blend" "$HEAD_BUILD/kit"
saved_stage face tools/art/sintel_guard/young_head_module.py "$HEAD_BUILD/kit/spearman-kit-editable.blend" "$HEAD_BUILD/mh/source/mh_natural_editable.blend" "$HEAD_BUILD/face"
saved_stage helmet tools/art/sintel_guard/spearman_helmet.py "$HEAD_BUILD/face/young-face-kit-editable.blend" "$HEAD_BUILD/helmet"
saved_stage carrier tools/art/sintel_guard/spearman_layered_carrier.py "$HEAD_BUILD/helmet/helmet-kit-editable.blend" "$HEAD_BUILD/carrier"
saved_stage grip tools/art/sintel_guard/spearman_grip_study.py "$HEAD_BUILD/carrier/soldier-carrier-editable.blend" "$HEAD_BUILD/grip"
saved_stage walk tools/art/sintel_guard/spearman_controlled_walk.py "$HEAD_BUILD/grip/soldier-grip-editable.blend" assets/ubc_lab/source/UAL1_Standard.glb "$HEAD_BUILD/walk"
SOURCE="$HEAD_BUILD/walk/soldier-controlled-walk.blend"
HASH=$(sha256sum "$SOURCE" | cut -d' ' -f1)
blender --background --disable-autoexec --python-exit-code 1 --python "$ORACLE_REPO/tools/art/soldier_runtime/audit_direct_skin.py" -- "$SOURCE" "$HASH" "$ORACLE_REPO/evidence/source-audit"
blender --background --disable-autoexec --python-exit-code 1 --python "$ORACLE_REPO/tools/art/soldier_runtime/export_head_oracle.py" -- "$SOURCE" "$HASH" "$HEAD_BUILD/head"
python "$ORACLE_REPO/tools/art/soldier_runtime/prepare.py" "$HEAD_BUILD/head" "$HEAD_BUILD/project"
cp tools/art/sintel_guard/{NOTICE.md,license-evidence.json} "$HEAD_BUILD/project/"
mkdir -p "$HEAD_BUILD/attribution"
cp tools/art/sintel_guard/NOTICE.md "$HEAD_BUILD/attribution/Guardian-NOTICE.md"
cp tools/art/sintel_guard/license-evidence.json "$HEAD_BUILD/attribution/Guardian-license-evidence.json"
cp tools/art/mh_character/NOTICE.md "$HEAD_BUILD/attribution/MakeHuman-NOTICE.md"
cp tools/art/mh_character/sources.json "$HEAD_BUILD/attribution/MakeHuman-exact-sources.json"
cp assets/ubc_lab/source/ual-standard-current-LICENSE.txt "$HEAD_BUILD/attribution/UAL-CC0.txt"
cp -r "$HEAD_BUILD/attribution" "$HEAD_BUILD/project/attribution"
cp -r "$HEAD_BUILD/attribution" "$ORACLE_REPO/evidence/attribution"
# Both complete editable mothers preserved once, never one copy per actor.
tar -czf "$ORACLE_REPO/evidence/head-editable-mothers.tar.gz" -C "$HEAD_BUILD" walk/soldier-controlled-walk.blend mh/source/mh_natural_editable.blend attribution
sha256sum "$ORACLE_REPO/evidence/head-editable-mothers.tar.gz" > "$ORACLE_REPO/evidence/head-editable-mothers.sha256"
tar --exclude=.godot -czf "$ORACLE_REPO/evidence/head-project.tar.gz" -C "$HEAD_BUILD/project" .
sha256sum "$ORACLE_REPO/evidence/head-project.tar.gz" > "$ORACLE_REPO/evidence/head-project.sha256"
