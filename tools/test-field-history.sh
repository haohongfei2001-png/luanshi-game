#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
GODOT="${GODOT:-godot}"
previous=77ad69619972975a015fa2890a75d5993e87e68c
historical_dir="$(mktemp -d)"
trap 'rm -rf "$historical_dir"' EXIT
git archive "$previous" scripts | tar -x -C "$historical_dir"
cp tests/field_history_probe.gd "$historical_dir/probe.gd"
printf 'config_version=5\n[application]\nconfig/name="River gate historical reader"\n' > "$historical_dir/project.godot"
export LUANSHI_HISTORY_DIR="$historical_dir"
"$GODOT" --headless --path "$historical_dir" --script res://probe.gd -- --write-original
"$GODOT" --headless --path . --script tests/field_history_probe.gd
