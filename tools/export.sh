#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
GODOT="${GODOT:-godot}"
mkdir -p builds artifacts
touch builds/.gdignore artifacts/.gdignore
./tools/prepare-font.sh
git rev-parse HEAD > assets/build-revision.txt
"$GODOT" --headless --editor --path . --import
"$GODOT" --headless --path . --script tools/write_notices.gd
"$GODOT" --headless --path . --export-release macOS builds/Luanshi-macOS.zip 2>&1 | tee artifacts/export-macos.log
"$GODOT" --headless --path . --export-release Linux builds/Luanshi-linux.x86_64 2>&1 | tee artifacts/export-linux.log
chmod +x builds/Luanshi-linux.x86_64
SMOKE_ID="export_$(date +%s)_${RANDOM}_${RANDOM}"
builds/Luanshi-linux.x86_64 --headless --fixed-fps 60 -- --smoke-scene --campaign-save-id="$SMOKE_ID" 2>&1 | tee artifacts/exported-linux-smoke.log
grep -q SCENE_SMOKE_PASS artifacts/exported-linux-smoke.log
builds/Luanshi-linux.x86_64 --headless --fixed-fps 60 -- --campaign-smoke --campaign-save-id="$SMOKE_ID" 2>&1 | tee artifacts/exported-linux-campaign.log
grep -q CAMPAIGN_SMOKE_PASS artifacts/exported-linux-campaign.log
for phase in prepare resume; do
  builds/Luanshi-linux.x86_64 --headless -- --persistence-smoke-$phase --persistence-smoke-id="$SMOKE_ID" 2>&1 | tee "artifacts/exported-linux-persistence-$phase.log"
done
grep -q PERSISTENCE_SMOKE_PREPARE_PASS artifacts/exported-linux-persistence-prepare.log
grep -q PERSISTENCE_SMOKE_RESUME_PASS artifacts/exported-linux-persistence-resume.log
for phase in prepare resume; do
  builds/Luanshi-linux.x86_64 --headless -- --youth-smoke-$phase --youth-smoke-id="$SMOKE_ID" 2>&1 | tee "artifacts/exported-linux-youth-$phase.log"
  marker=$(printf '%s' "$phase" | tr '[:lower:]' '[:upper:]')
  grep -q "YOUTH_RUNTIME_${marker}_PASS" "artifacts/exported-linux-youth-$phase.log"
done
if grep -E 'SCRIPT ERROR|Parse Error|ERROR:' artifacts/export-{macos,linux}.log artifacts/exported-linux-{smoke,campaign,persistence-prepare,persistence-resume}.log; then
  exit 1
fi
if grep -E 'SCRIPT ERROR|Parse Error|ERROR:' artifacts/exported-linux-youth-*.log; then exit 1; fi
builds/Luanshi-linux.x86_64 --headless --fixed-fps 60 -- --field-check 2>&1 | tee artifacts/exported-field.log
grep -q '^FIELD_PACKAGE_PASS' artifacts/exported-field.log
if grep -E 'SCRIPT ERROR|Parse Error|ERROR:' artifacts/exported-field.log; then exit 1; fi
python3 tools/verify_macos.py builds/Luanshi-macOS.zip
python3 - <<'PY'
import zipfile
with zipfile.ZipFile('builds/Luanshi-macOS.zip', 'a', zipfile.ZIP_DEFLATED) as bundle:
    bundle.write('builds/THIRD_PARTY_NOTICES.txt', 'THIRD_PARTY_NOTICES.txt')
    bundle.write('docs/PLAYING_ZH.md', 'README-zh.md')
PY
tar -czf builds/Luanshi-linux.tar.gz -C builds Luanshi-linux.x86_64 THIRD_PARTY_NOTICES.txt -C ../docs PLAYING_ZH.md
sha256sum builds/Luanshi-macOS.zip builds/Luanshi-linux.tar.gz | tee builds/SHA256SUMS
