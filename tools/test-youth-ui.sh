#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
GODOT="${GODOT:-godot}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$PWD/.local-data}"
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$PWD/.local-config}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$PWD/.local-cache}"
mkdir -p artifacts "$XDG_DATA_HOME" "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME"
touch artifacts/.gdignore
"$GODOT" --headless --path . --fixed-fps 60 --script tests/test_youth_scene.gd 2>&1 | tee artifacts/youth-ui-tests.log
"$GODOT" --headless --path . --fixed-fps 60 --script tests/youth_visual.gd -- --validate-youth-inputs 2>&1 | tee artifacts/youth-input-tests.log
if grep -E 'SCRIPT ERROR|Parse Error|ERROR:' artifacts/youth-{ui,input}-tests.log; then exit 1; fi
grep -q 'YOUTH_SCENE_SUMMARY .*"failures":0' artifacts/youth-ui-tests.log
grep -q 'YOUTH_INPUT_VALIDATION_PASS .*"failures":0' artifacts/youth-input-tests.log
"$GODOT" --headless --path . --script tests/test_youth_presentation.gd 2>&1 | tee artifacts/youth-presentation-tests.log
grep -q 'YOUTH_PRESENTATION_SUMMARY .*"failures":0' artifacts/youth-presentation-tests.log
if grep -E 'SCRIPT ERROR|Parse Error|ERROR:' artifacts/youth-presentation-tests.log; then exit 1; fi
