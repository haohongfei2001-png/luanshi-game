#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../../.."
: "${MH_SOURCE_CACHE:?Set MH_SOURCE_CACHE to a writable source cache}"
: "${UAL_GLB:?Set UAL_GLB to verified 2026-06-16 CC0 UAL1_Standard.glb}"
python3 tools/art/mh_character/fetch.py "$MH_SOURCE_CACHE" ${MH_FETCH_OFFLINE:+--offline}
blender -b --disable-autoexec --python-exit-code 1 --python tools/art/mh_character/master.py -- assets/mh_lab "$MH_SOURCE_CACHE/core" "$MH_SOURCE_CACHE/selected" "$MH_SOURCE_CACHE/selected/clothes/mindfront_kimono"
blender -b --disable-autoexec --python-exit-code 1 --python tools/art/mh_character/retarget.py -- assets/mh_lab "$UAL_GLB"
python3 tools/art/mh_character/check_retarget.py assets/mh_lab
export XDG_DATA_HOME="$PWD/.local-data" XDG_CONFIG_HOME="$PWD/.local-config" XDG_CACHE_HOME="$PWD/.local-cache"
timeout 300 godot --headless --path . --editor --import
timeout 120 godot --headless --path . --script res://tests/experimental/mh_source_ids.gd
MH_TEST=1 timeout 120 godot --headless --path . --script res://tests/experimental/mh_character_lab.gd
