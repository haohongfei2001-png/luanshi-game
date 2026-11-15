#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
: "${SOURCE_DIR:?Set SOURCE_DIR to the prepared official source tree}"
: "${OUTPUT_DIR:?Set OUTPUT_DIR to a fresh output directory outside tracked source}"
PYTHON="${PYTHON:-python3}"
JOBS="${JOBS:-1}"
[[ "$JOBS" == 1 || "$JOBS" == 2 ]] || { echo 'JOBS must be 1 or 2.' >&2; exit 2; }
for command in "$PYTHON" g++ pkg-config patch; do
  command -v "$command" >/dev/null || { echo "Missing existing dependency: $command" >&2; exit 2; }
done
"$PYTHON" - "$ROOT" "$SOURCE_DIR" <<'PY'
import json, sys
from pathlib import Path
import SCons
sys.path.insert(0, sys.argv[1])
from prepare_source import COMMIT, ARCHIVE_SHA256, RECEIPT, digest
if SCons.__version__ != '4.10.1':
    raise SystemExit('SCons 4.10.1 is the tested dependency. Install/manage it separately; this script installs nothing.')
source=Path(sys.argv[2]).resolve(); root=Path(sys.argv[1])
r=json.loads((source/RECEIPT).read_text())
assert r['commit']==COMMIT and r['archive_sha256']==ARCHIVE_SHA256, 'Wrong source receipt'
expected={'surfaceless.patch'} | ({'gles3-tangent.patch'} if r.get('tangent') else set())
assert set(r['patches'])==expected, 'Unexpected patch receipt entries'
assert all(digest(root/name)==value for name,value in r['patches'].items()), 'Patch checkpoint mismatch'
PY
SOURCE_DIR="$(cd -- "$SOURCE_DIR" && pwd)"
OUTPUT_DIR="$($PYTHON -c 'import pathlib,sys; print(pathlib.Path(sys.argv[1]).resolve())' "$OUTPUT_DIR")"
export BUILD_NAME=surfaceless35e80
"$PYTHON" "$ROOT/resource_guard.py" --output-dir "$OUTPUT_DIR" --watch-path "$SOURCE_DIR" \
  --watch-path "$(dirname -- "$OUTPUT_DIR")" --cwd "$SOURCE_DIR" -- \
  "$PYTHON" -m SCons -j"$JOBS" platform=linuxbsd arch=x86_64 target=template_release optimize=size \
  debug_symbols=no lto=none use_static_cpp=no surfaceless=yes vulkan=no opengl3=yes x11=no wayland=no \
  alsa=no pulseaudio=no dbus=no speechd=no fontconfig=no udev=no sdl=no accesskit=no touch=no disable_xr=yes \
  modules_enabled_by_default=no module_gdscript_enabled=yes module_gltf_enabled=yes module_freetype_enabled=yes \
  module_text_server_fb_enabled=yes module_godot_physics_3d_enabled=yes module_godot_physics_2d_enabled=yes \
  module_jpg_enabled=yes module_webp_enabled=yes
"$PYTHON" - "$ROOT" "$SOURCE_DIR" "$OUTPUT_DIR" <<'PY'
import json, shutil, sys
from pathlib import Path
sys.path.insert(0,sys.argv[1])
from prepare_source import RECEIPT, digest
source=Path(sys.argv[2]); output=Path(sys.argv[3])
receipt=json.loads((source/RECEIPT).read_text())
name='godot-surfaceless-tangent' if receipt['tangent'] else 'godot-surfaceless-baseline'
engine=source/'bin/godot.linuxbsd.template_release.x86_64'; destination=output/name
with engine.open('rb') as src, destination.open('xb') as dst: shutil.copyfileobj(src,dst)
destination.chmod(0o755)
licenses=output/'licenses'; licenses.mkdir()
for name in ['LICENSE.txt','COPYRIGHT.txt','AUTHORS.md']:
    shutil.copyfile(source/name,licenses/name)
shutil.copyfile(source/'thirdparty/README.md',licenses/'THIRDPARTY_README.md')
for path in (source/'thirdparty').rglob('*'):
    if path.is_file() and (path.name.lower().startswith(('license','licence','copying','copyright','notice','patent','author')) or path.name.lower() in ['ftl.txt','gplv2.txt']):
        target=licenses/'thirdparty'/path.relative_to(source/'thirdparty')
        target.parent.mkdir(parents=True,exist_ok=True); shutil.copyfile(path,target)
receipt.update(binary=destination.name,binary_bytes=destination.stat().st_size,binary_sha256=digest(destination))
(output/'artifact.json').write_text(json.dumps(receipt,indent=2)+'\n')
print('Preserved binary:',destination.name,receipt['binary_sha256'])
PY
