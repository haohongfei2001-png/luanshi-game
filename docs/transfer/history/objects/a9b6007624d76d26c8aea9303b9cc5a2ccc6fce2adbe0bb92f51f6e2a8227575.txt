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
builds/Luanshi-linux.x86_64 --headless --fixed-fps 60 -- --smoke-scene 2>&1 | tee artifacts/exported-linux-smoke.log
grep -q SCENE_SMOKE_PASS artifacts/exported-linux-smoke.log
builds/Luanshi-linux.x86_64 --headless --fixed-fps 60 -- --campaign-smoke 2>&1 | tee artifacts/exported-linux-campaign.log
grep -q CAMPAIGN_SMOKE_PASS artifacts/exported-linux-campaign.log
if grep -E 'SCRIPT ERROR|Parse Error|ERROR:' artifacts/export-{macos,linux}.log artifacts/exported-linux-{smoke,campaign}.log; then
  exit 1
fi
python3 tools/verify_macos.py builds/Luanshi-macOS.zip
python3 - <<'PY'
import zipfile
with zipfile.ZipFile('builds/Luanshi-macOS.zip', 'a', zipfile.ZIP_DEFLATED) as bundle:
    bundle.write('builds/THIRD_PARTY_NOTICES.txt', 'THIRD_PARTY_NOTICES.txt')
    bundle.write('docs/PLAYING_ZH.md', 'README-zh.md')
PY
tar -czf builds/Luanshi-linux.tar.gz -C builds Luanshi-linux.x86_64 THIRD_PARTY_NOTICES.txt
sha256sum builds/Luanshi-macOS.zip builds/Luanshi-linux.tar.gz | tee builds/SHA256SUMS
