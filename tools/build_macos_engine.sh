#!/usr/bin/env bash
# Rebuild the exact source/ANGLE recipe when the verified CI artifact expires.
set -euo pipefail
out_dir="${1:?Usage: build_macos_engine.sh OUTPUT_DIRECTORY}"
mkdir -p "$out_dir"
out_dir="$(cd "$out_dir" && pwd)"
engine_work="$(mktemp -d "${RUNNER_TEMP:-/tmp}/luanshi-engine.XXXXXX")"
script_dir="$(cd "$(dirname "$0")" && pwd)"
git clone --filter=blob:none --no-checkout https://github.com/godotengine/godot.git "$engine_work/source"
git -C "$engine_work/source" checkout --detach 35e80b3a8822a9df9be390814b62f44c0a9c69e8
python3 "$script_dir/backport_mobile_mutex.py" "$engine_work/source" > "$out_dir/actual.patch"
curl -fL --retry 2 'https://github.com/godotengine/godot-angle-static/releases/download/chromium/7578/godot-angle-static-arm64-macos-release.zip' -o "$engine_work/angle.zip"
echo "9eadd2055f66507e9d74655e7683e068e7e4a9dade5a84bc03d3f5affdfb7b9d  $engine_work/angle.zip" | shasum -a 256 -c -
unzip -q "$engine_work/angle.zip" -d "$engine_work/angle"
angle_library="$(find "$engine_work/angle" -name 'libANGLE.macos.arm64.a' -print -quit)"
test -n "$angle_library"
angle_directory="$(dirname "$angle_library")"
python3 -m venv "$engine_work/compiler"
"$engine_work/compiler/bin/python" -m pip install 'scons==4.9.1'
(
  cd "$engine_work/source"
  "$engine_work/compiler/bin/scons" platform=macos arch=arm64 target=template_release production=yes debug_symbols=no lto=none module_mono_enabled=no vulkan=no metal=yes angle_libs="$angle_directory" -j3
) 2>&1 | tee "$out_dir/build.log"
cp "$engine_work/source/bin/godot.macos.template_release.arm64" "$out_dir/"
cp "$engine_work/source/LICENSE.txt" "$out_dir/GODOT-MIT-LICENSE.txt"
cp "$engine_work/source/COPYRIGHT.txt" "$out_dir/GODOT-COPYRIGHT.txt"
cp "$engine_work/source/thirdparty/angle/LICENSE" "$out_dir/ANGLE-BSD-LICENSE.txt"
cp "$script_dir/licenses/ANGLE-BUILD-LICENSE.txt" "$out_dir/ANGLE-BUILD-LICENSE.txt"
"$out_dir/godot.macos.template_release.arm64" --version > "$out_dir/engine-version.txt"
python3 - "$out_dir" <<'PY'
from pathlib import Path
import hashlib,json,sys
out=Path(sys.argv[1])
data={
    "engine_source":"35e80b3a8822a9df9be390814b62f44c0a9c69e8",
    "upstream_fix":"https://github.com/godotengine/godot/pull/123312",
    "role":"complete arm64 template with Mobile mutex fix and static ANGLE",
    "angle_release":"chromium/7578",
    "angle_source":"aaebda1c5a40c15340d7a01a935a7c5398443272",
    "angle_archive_sha256":"9eadd2055f66507e9d74655e7683e068e7e4a9dade5a84bc03d3f5affdfb7b9d",
    "patched_binary_sha256":hashlib.sha256((out/"godot.macos.template_release.arm64").read_bytes()).hexdigest(),
    "actual_patch_sha256":hashlib.sha256((out/"actual.patch").read_bytes()).hexdigest(),
    "compiler":"scons 4.9.1, host Xcode clang, arm64 template_release, production, static ANGLE, Metal, no Vulkan, no LTO"
}
(out/"provenance.json").write_text(json.dumps(data,indent=2)+"\n")
print("ENGINE_REBUILD",json.dumps(data))
PY
