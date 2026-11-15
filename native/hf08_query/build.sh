#!/usr/bin/env bash
set -euo pipefail
ROOT=$(cd "$(dirname "$0")" && pwd)
python3 -c 'import SCons; assert SCons.__version__ == "4.10.1", "Use official SCons 4.10.1"'
VERSION=10.0.0-stable
ARCHIVE_SHA=ebbf64f0f8f8b8b66bc4bc4d3797db97f95b19cf0dfb5b3f8cf56683d9df7db4
if [[ ! -f "$ROOT/vendor/godot-cpp-$VERSION/SConstruct" ]]; then
  mkdir -p "$ROOT/vendor"
  archive="$ROOT/vendor/godot-cpp-$VERSION.tar.gz"
  curl -fL "https://codeload.github.com/godotengine/godot-cpp/tar.gz/refs/tags/$VERSION" -o "$archive"
  printf '%s  %s\n' "$ARCHIVE_SHA" "$archive" | sha256sum -c -
  tar -xzf "$archive" -C "$ROOT/vendor"
fi
python3 -m SCons -C "$ROOT" platform=linux arch=x86_64 target=template_release precision=single \
  build_profile=build_profile.json debug_symbols=no optimize=speed -j"${JOBS:-2}"
