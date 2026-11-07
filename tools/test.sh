#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
GODOT="${GODOT:-godot}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$PWD/.local-data}"
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$PWD/.local-config}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$PWD/.local-cache}"
mkdir -p "$XDG_DATA_HOME" "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME" artifacts
"$GODOT" --version | tee artifacts/engine-version.log
"$GODOT" --headless --path . --editor --import 2>&1 | tee artifacts/import.log
"$GODOT" --headless --path . --script tests/test_battle.gd 2>&1 | tee artifacts/simulation-tests.log
"$GODOT" --headless --path . --fixed-fps 60 -- --smoke-scene 2>&1 | tee artifacts/scene-smoke.log
if grep -E 'SCRIPT ERROR|Parse Error|ERROR:' artifacts/{import,simulation-tests,scene-smoke}.log; then
  echo 'Godot logged an error despite process exit code.' >&2
  exit 1
fi
grep -q '"failures":0' artifacts/simulation-tests.log
grep -q SCENE_SMOKE_PASS artifacts/scene-smoke.log
