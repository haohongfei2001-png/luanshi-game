#!/usr/bin/env bash
# Render real Godot asset evidence. No campaign/battle code is invoked.
set -euo pipefail
repo_dir="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$repo_dir"
view="${1:-army}"
output="${2:?Usage: capture_review.sh VIEW /absolute/output.png [FRAMES] [extra --art-* options]}"
frames="${3:-45}"
if [[ "$output" != /* ]]; then
  printf '%s\n' 'Output must be an absolute PNG path.' >&2
  exit 2
fi
case "$view" in army|portrait|equipment|map|crowd) ;; *) printf 'Unknown view: %s\n' "$view" >&2; exit 2 ;; esac
if [[ $# -ge 3 ]]; then shift 3; else shift "$#"; fi
godot_bin="${GODOT:-godot}"
if ! command -v "$godot_bin" >/dev/null 2>&1; then
  printf '%s\n' 'Godot 4.6+ is required. Set GODOT to its executable path.' >&2
  exit 2
fi
mkdir -p artifacts "$(dirname "$output")"
touch artifacts/.gdignore
task_tmp="$(mktemp -d "$repo_dir/artifacts/art-review.XXXXXX")"
x_pid=''
cleanup() {
  if [[ -n "$x_pid" ]]; then kill "$x_pid" 2>/dev/null || true; wait "$x_pid" 2>/dev/null || true; fi
  rm -rf "$task_tmp"
}
trap cleanup EXIT
export LIBGL_ALWAYS_SOFTWARE="${LIBGL_ALWAYS_SOFTWARE:-1}"
if [[ -z "${DISPLAY:-}" ]]; then
  if ! command -v Xorg >/dev/null || ! command -v xauth >/dev/null; then
    printf '%s\n' 'No display available: install Xorg dummy + xauth, or provide DISPLAY.' >&2
    exit 2
  fi
  display_number=98
  while [[ -e "/tmp/.X${display_number}-lock" ]]; do display_number=$((display_number + 1)); done
  export DISPLAY=":$display_number"
  export XAUTHORITY="$task_tmp/xauthority"
  touch "$XAUTHORITY"
  auth_cookie="$(python3 -c 'import secrets; print(secrets.token_hex(16))')"
  xauth -f "$XAUTHORITY" add "$DISPLAY" MIT-MAGIC-COOKIE-1 "$auth_cookie"
  cat > "$task_tmp/xorg.conf" <<'CONF'
Section "ServerFlags"
  Option "AutoAddDevices" "false"
  Option "AutoEnableDevices" "false"
EndSection
Section "Device"
  Identifier "ArtReviewDummy"
  Driver "dummy"
  VideoRam 256000
EndSection
Section "Monitor"
  Identifier "ArtReviewMonitor"
  HorizSync 5.0-1000.0
  VertRefresh 5.0-200.0
  Modeline "1600x1000" 138.5 1600 1648 1680 1760 1000 1003 1009 1050
EndSection
Section "Screen"
  Identifier "ArtReviewScreen"
  Device "ArtReviewDummy"
  Monitor "ArtReviewMonitor"
  DefaultDepth 24
  SubSection "Display"
    Depth 24
    Modes "1600x1000"
    Virtual 1600 1000
  EndSubSection
EndSection
CONF
  Xorg "$DISPLAY" -config "$task_tmp/xorg.conf" -logfile "$task_tmp/xorg.log" -auth "$XAUTHORITY" -nolisten tcp -noreset > "$task_tmp/xorg-start.log" 2>&1 &
  x_pid=$!
  # A short bounded wait for the display socket; no unauthenticated server.
  for attempt in {1..40}; do
    if [[ -S "/tmp/.X11-unix/X$display_number" ]]; then break; fi
    if ! kill -0 "$x_pid" 2>/dev/null; then cat "$task_tmp/xorg-start.log" >&2; cat "$task_tmp/xorg.log" >&2; exit 2; fi
    sleep 0.1
  done
fi
timeout 240s "$godot_bin" --path . --rendering-method gl_compatibility --rendering-driver opengl3 \
  --resolution 1600x1000 --audio-driver Dummy --disable-vsync --fixed-fps 30 \
  scenes/art_review/river_gate_review.tscn -- \
  "--art-shot=$view" "--art-output=$output" "--art-frames=$frames" "$@" \
  2>&1 | tee "${output%.png}.log"
if ! rg -q '^ART_REVIEW_CAPTURED ' "${output%.png}.log"; then exit 1; fi
if rg -n 'SCRIPT ERROR|Parse Error|SHADER ERROR|^ERROR:' "${output%.png}.log"; then exit 1; fi
