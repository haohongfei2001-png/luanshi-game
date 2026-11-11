#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
GODOT="${GODOT:-godot}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$PWD/.local-data}"
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$PWD/.local-config}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$PWD/.local-cache}"
mkdir -p artifacts "$XDG_DATA_HOME" "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME"
touch artifacts/.gdignore
ID="source_$(date +%s)_${RANDOM}"
for phase in prepare resume; do
  "$GODOT" --headless --path . -- --youth-smoke-$phase --youth-smoke-id="$ID" 2>&1 | tee "artifacts/youth-runtime-$phase.log"
  marker=$(printf '%s' "$phase" | tr '[:lower:]' '[:upper:]')
  grep -q "YOUTH_RUNTIME_${marker}_PASS" "artifacts/youth-runtime-$phase.log"
  if grep -E 'SCRIPT ERROR|Parse Error|ERROR:' "artifacts/youth-runtime-$phase.log"; then exit 1; fi
done
