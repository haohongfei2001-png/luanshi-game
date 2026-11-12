#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
GODOT="${GODOT:-godot}"
historical_dir="$(mktemp -d)"
trap 'rm -rf "$historical_dir"' EXIT

replay() {
  local source_sha="$1"
  shift
  local previous_dir="$historical_dir/$source_sha"
  mkdir -p "$previous_dir"
  git archive "$source_sha" scripts | tar -x -C "$previous_dir"
  cp tests/field_history_probe.gd "$previous_dir/probe.gd"
  printf 'config_version=5\n[application]\nconfig/name="River gate historical reader"\n' > "$previous_dir/project.godot"
  LUANSHI_HISTORY_DIR="$previous_dir" "$GODOT" --headless --path "$previous_dir" --script res://probe.gd -- --write-original "$@"
  LUANSHI_HISTORY_DIR="$previous_dir" "$GODOT" --headless --path . --script tests/field_history_probe.gd -- "$@"
}

replay 77ad69619972975a015fa2890a75d5993e87e68c
replay efcd91533e7cd50309375d1ab90138a041e7f674 --gate-replay
