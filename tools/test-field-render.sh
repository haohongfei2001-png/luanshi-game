#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p artifacts
touch artifacts/.gdignore
export LIBGL_ALWAYS_SOFTWARE=1
GODOT="${GODOT:-godot}"
for mode in benchmark film; do
  args=(--disable-vsync --resolution 1280x800 --audio-driver Dummy)
  user_args=(--field-size=20)
  if [[ "$mode" == film ]]; then
    args+=(--fixed-fps 30)
    user_args=(--field-size=512 --field-film)
  fi
  timeout 150s xvfb-run -a -s '-screen 0 1280x800x24' "$GODOT" --path . "${args[@]}" --script tests/field_render.gd -- "${user_args[@]}" 2>&1 | tee "artifacts/field-$mode.log"
  if grep -E 'SCRIPT ERROR|Parse Error|SHADER ERROR|ERROR:' "artifacts/field-$mode.log"; then exit 1; fi
done
timeout 120s xvfb-run -a -s '-screen 0 1280x800x24' "$GODOT" --path . --disable-vsync --resolution 1280x800 --audio-driver Dummy --fixed-fps 30 --script tests/field_controls.gd -- --field-size=20 2>&1 | tee artifacts/field-controls.log
grep -q '^FIELD_CONTROLS_PASS' artifacts/field-controls.log
if grep -E 'SCRIPT ERROR|Parse Error|SHADER ERROR|ERROR:' artifacts/field-controls.log; then exit 1; fi
ffmpeg -nostdin -loglevel error -y -framerate 10 -i artifacts/kit-film/frame-%03d.jpg -c:v libx264 -pix_fmt yuv420p -movflags +faststart artifacts/player-nine-weapons.mp4
grep -q '^FIELD_RENDER_PASS' artifacts/field-benchmark.log
grep -q '^FIELD_FILM_PASS' artifacts/field-film.log
ffmpeg -nostdin -loglevel error -y -framerate 15 -i artifacts/field-film/frame-%03d.jpg -c:v libx264 -pix_fmt yuv420p -movflags +faststart artifacts/river-gate-512.mp4
# A single small inspection frame can be viewed directly from the hosted job log.
ffmpeg -nostdin -loglevel error -y -i artifacts/field-512.png -vf scale=640:-2 -frames:v 1 artifacts/river-gate-preview.jpg
printf 'FIELD_PREVIEW_JPEG '
base64 -w0 artifacts/river-gate-preview.jpg
printf '\n'
printf 'FIELD_CLOSE_JPEG '
base64 -w0 artifacts/field-close.jpg
printf '\n'
