#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p artifacts
touch artifacts/.gdignore
export LIBGL_ALWAYS_SOFTWARE=1
GODOT="${GODOT:-godot}"
timeout 100s xvfb-run -a -s '-screen 0 800x500x24' "$GODOT" --path . --resolution 800x500 --disable-vsync --audio-driver Dummy --fixed-fps 10 --script tests/field_alternate_outcomes.gd -- --field-size=20 2>&1 | tee artifacts/field-outcomes.log
grep -q '^FIELD_ENDINGS_PASS' artifacts/field-outcomes.log
if grep -E 'SCRIPT ERROR|Parse Error|SHADER ERROR|ERROR:' artifacts/field-outcomes.log; then exit 1; fi
# This driver plays two complete orders of battle without quitting the shipping shell.
# With 4x MSAA on llvmpipe, the first 724-tick route alone took 295 s. The driver
# reports progress and rejects a stalled simulation independently of this process guard.
timeout 15m xvfb-run -a -s '-screen 0 960x600x24' "$GODOT" --path . --resolution 960x600 --disable-vsync --audio-driver Dummy --fixed-fps 10 --script tests/field_escort_gui.gd -- --field-size=512 2>&1 | tee artifacts/field-escort-gui.log
grep -q '^FIELD_ESCORT_GUI_PASS' artifacts/field-escort-gui.log
if grep -E 'SCRIPT ERROR|Parse Error|SHADER ERROR|ERROR:' artifacts/field-escort-gui.log; then exit 1; fi
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
timeout 200s xvfb-run -a -s '-screen 0 1280x800x24' "$GODOT" --path . --disable-vsync --resolution 1280x800 --audio-driver Dummy --fixed-fps 30 --script tests/field_controls.gd -- --field-size=20 2>&1 | tee artifacts/field-controls.log
grep -q '^FIELD_CONTROLS_PASS' artifacts/field-controls.log
if grep -E 'SCRIPT ERROR|Parse Error|SHADER ERROR|ERROR:' artifacts/field-controls.log; then exit 1; fi
ffmpeg -nostdin -loglevel error -y -framerate 10 -i artifacts/kit-film/frame-%03d.jpg -c:v libx264 -pix_fmt yuv420p -movflags +faststart artifacts/player-nine-weapons.mp4
timeout 425s xvfb-run -a -s '-screen 0 960x600x24' "$GODOT" --path . --disable-vsync --audio-driver Dummy --resolution 960x600 --fixed-fps 10 --script tests/field_siege_film.gd -- --field-size=512 2>&1 | tee artifacts/natural-siege.log
grep -q '^FIELD_SIEGE_FILM_PASS' artifacts/natural-siege.log
if grep -E 'SCRIPT ERROR|Parse Error|SHADER ERROR|ERROR:' artifacts/natural-siege.log; then exit 1; fi
ffmpeg -nostdin -loglevel error -y -framerate 10 -i artifacts/siege-film/frame-%04d.jpg -c:v libx264 -pix_fmt yuv420p -movflags +faststart artifacts/river-gate-full-siege.mp4
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
printf 'FIELD_GATE_JPEG '
base64 -w0 artifacts/field-gate.jpg
printf '\n'
