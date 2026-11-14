#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../../.."
: "${MH_SOURCE_CACHE:?Set MH_SOURCE_CACHE to a writable source cache}"
: "${UAL_GLB:?Set UAL_GLB to verified 2026-06-16 CC0 UAL1_Standard.glb}"
python3 tools/art/mh_character/fetch.py "$MH_SOURCE_CACHE" ${MH_FETCH_OFFLINE:+--offline}
blender -b --disable-autoexec --python-exit-code 1 --python tools/art/mh_character/master.py -- assets/mh_official_axes_lab "$MH_SOURCE_CACHE/core" "$MH_SOURCE_CACHE/selected" "$MH_SOURCE_CACHE/selected/clothes/mindfront_kimono" --official-axes
blender -b --disable-autoexec --python-exit-code 1 --python tools/art/mh_character/retarget.py -- assets/mh_official_axes_lab "$UAL_GLB"
python3 tools/art/mh_character/check_retarget.py assets/mh_official_axes_lab
blender -b --disable-autoexec --python-exit-code 1 --python tools/art/mh_character/source_axis_audit.py -- assets/mh_official_axes_lab/source/mh_natural_editable.blend "$MH_SOURCE_CACHE/core" assets/mh_official_axes_lab/source-axis-audit.json
export XDG_DATA_HOME="$PWD/.local-data" XDG_CONFIG_HOME="$PWD/.local-config" XDG_CACHE_HOME="$PWD/.local-cache"
timeout 300 godot --headless --path . --editor --import
MH_STATIC_PATH=res://assets/mh_official_axes_lab/mh_natural_fullweights.glb MH_SIDECAR_PATH=res://assets/mh_official_axes_lab/full-influences.json timeout 120 godot --headless --path . --script res://tests/experimental/mh_source_ids.gd
MH_MODEL_PATH=res://assets/mh_official_axes_lab/mh_natural_animated_full.glb MH_TEST=1 timeout 120 godot --headless --path . --script res://tests/experimental/mh_character_lab.gd
