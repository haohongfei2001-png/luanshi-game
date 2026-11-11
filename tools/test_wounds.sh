#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
GODOT="${GODOT:-godot}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$PWD/.local-data}"
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$PWD/.local-config}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$PWD/.local-cache}"
mkdir -p artifacts; touch artifacts/.gdignore
for name in wounds wounds_ui; do
  "$GODOT" --headless --path . --script "tests/test_${name}.gd" 2>&1 | tee "artifacts/${name}.log"
  grep -q '"failures":\[\]' "artifacts/${name}.log"
  if grep -E 'SCRIPT ERROR|Parse Error|ERROR:' "artifacts/${name}.log"; then exit 1; fi
done
ID="wounds_restart_$(date +%s)_${RANDOM}"
for phase in prepare resume; do
  "$GODOT" --headless --path . --script tests/test_wounds_restart.gd -- "$phase" "$ID" 2>&1 | tee "artifacts/wounds-restart-${phase}.log"
  grep -q '\"failures\":\[\]' "artifacts/wounds-restart-${phase}.log"
  if grep -E 'SCRIPT ERROR|Parse Error|ERROR:' "artifacts/wounds-restart-${phase}.log"; then exit 1; fi
done
