#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
GODOT="${GODOT:-godot}"
mkdir -p builds artifacts
touch builds/.gdignore artifacts/.gdignore
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
for phase in prepare resume; do
  builds/Luanshi-linux.x86_64 --headless -- --courier-smoke-$phase --courier-smoke-id="$SMOKE_ID" 2>&1 | tee "artifacts/exported-linux-courier-$phase.log"
  marker=$(printf '%s' "$phase" | tr '[:lower:]' '[:upper:]')
  grep -q "COURIER_RUNTIME_${marker}_PASS" "artifacts/exported-linux-courier-$phase.log"
done
if grep -E 'SCRIPT ERROR|Parse Error|ERROR:' artifacts/exported-linux-courier-*.log; then exit 1; fi
for phase in prepare resume; do
  builds/Luanshi-linux.x86_64 --headless -- --appraisal-smoke-$phase --appraisal-smoke-id="$SMOKE_ID" 2>&1 | tee "artifacts/exported-linux-appraisal-$phase.log"
  marker=$(printf '%s' "$phase" | tr '[:lower:]' '[:upper:]')
  grep -q "APPRAISAL_RUNTIME_${marker}_PASS" "artifacts/exported-linux-appraisal-$phase.log"
done
if grep -E 'SCRIPT ERROR|Parse Error|ERROR:' artifacts/exported-linux-appraisal-*.log; then exit 1; fi
for phase in prepare resume; do
  builds/Luanshi-linux.x86_64 --headless -- --petition-smoke-$phase --petition-smoke-id="$SMOKE_ID" 2>&1 | tee "artifacts/exported-linux-petition-$phase.log"
  marker=$(printf '%s' "$phase" | tr '[:lower:]' '[:upper:]')
  grep -q "PETITION_RUNTIME_${marker}_PASS" "artifacts/exported-linux-petition-$phase.log"
done
if grep -E 'SCRIPT ERROR|Parse Error|ERROR:' artifacts/exported-linux-petition-*.log; then exit 1; fi
for phase in prepare resume; do
  builds/Luanshi-linux.x86_64 --headless -- --hometown-smoke-$phase --hometown-smoke-id="$SMOKE_ID" 2>&1 | tee "artifacts/exported-linux-hometown-$phase.log"
  marker=$(printf '%s' "$phase" | tr '[:lower:]' '[:upper:]')
  grep -q "HOMETOWN_RUNTIME_${marker}_PASS" "artifacts/exported-linux-hometown-$phase.log"
done
if grep -E 'SCRIPT ERROR|Parse Error|ERROR:' artifacts/exported-linux-hometown-*.log; then exit 1; fi
for phase in prepare resume; do
  builds/Luanshi-linux.x86_64 --headless -- --wounds-smoke-$phase --wounds-smoke-id="$SMOKE_ID" 2>&1 | tee "artifacts/exported-linux-wounds-$phase.log"
  marker=$(printf '%s' "$phase" | tr '[:lower:]' '[:upper:]')
  grep -q "WOUNDS_RUNTIME_${marker}_PASS" "artifacts/exported-linux-wounds-$phase.log"
done
if grep -E 'SCRIPT ERROR|Parse Error|ERROR:' artifacts/exported-linux-wounds-*.log; then exit 1; fi
python3 tools/verify_macos.py builds/Luanshi-macOS.zip
python3 - <<'PY'
import zipfile
with zipfile.ZipFile('builds/Luanshi-macOS.zip', 'a', zipfile.ZIP_DEFLATED) as bundle:
    bundle.write('builds/THIRD_PARTY_NOTICES.txt', 'THIRD_PARTY_NOTICES.txt')
    bundle.write('docs/PLAYING_ZH.md', 'README-zh.md')
PY
tar -czf builds/Luanshi-linux.tar.gz -C builds Luanshi-linux.x86_64 THIRD_PARTY_NOTICES.txt
sha256sum builds/Luanshi-macOS.zip builds/Luanshi-linux.tar.gz | tee builds/SHA256SUMS
