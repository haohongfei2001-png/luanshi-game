#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
GODOT="${GODOT:-godot}"
mkdir -p builds artifacts
"$GODOT" --headless --path . --export-release macOS builds/Luanshi-macOS.zip 2>&1 | tee artifacts/export-macos.log
"$GODOT" --headless --path . --export-release Linux builds/Luanshi-linux.x86_64 2>&1 | tee artifacts/export-linux.log
chmod +x builds/Luanshi-linux.x86_64
builds/Luanshi-linux.x86_64 --headless --fixed-fps 60 -- --smoke-scene 2>&1 | tee artifacts/exported-linux-smoke.log
grep -q SCENE_SMOKE_PASS artifacts/exported-linux-smoke.log
if grep -E 'SCRIPT ERROR|Parse Error|ERROR:' artifacts/export-{macos,linux}.log artifacts/exported-linux-smoke.log; then
  exit 1
fi
python3 tools/verify_macos.py builds/Luanshi-macOS.zip
sha256sum builds/Luanshi-macOS.zip builds/Luanshi-linux.x86_64 | tee builds/SHA256SUMS
