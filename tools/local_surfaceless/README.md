# Local Godot EGL surfaceless tooling

This **code-only experimental tooling checkpoint** adds a Linux software-rendering display backend. It is not a game-art release, remote renderer or substitute game. This folder contains patches, small scripts and a synthetic fixture only. Do not add engine source archives, binaries, screenshots, logs, runtime reports, game assets or asset manifests to it.

## What was verified, and what was not

Local validation on 2026-11-15 demonstrated actual Godot SceneTree/Viewport rendering through GLES3 Compatibility and Mesa llvmpipe: lit meshes, shadows, UI, visible object motion, synthetic Input press/release with actual callbacks, and same-process 768×432 → 1280×720 → 2560×1440 → 3840×2160 resizing. Queried EGL pbuffer, root viewport and PNG dimensions matched; 3D scale was 1.0. Both the baseline backend and the separately tangent-patched engine passed this primitive fixture.

A separate complete HF08 scene has also run locally, using `local-prepared-6c45ebd2` (based on public source-preparation baseline `a2d39`). That is an engineering execution result, **not visual acceptance: all art acceptance remains FAIL**. None of that scene's files or evidence is included here. This checkpoint does not establish normal-speed gameplay/video acceptance, source18 asset correctness, 512v512 capacity, M5/device performance, FPS targets or a formal release. It grants no permission to publish game data.

The portable scripts were checked with static checks, small process fixtures, exact upstream patch application and existing primitive-image fixtures. The portable workflow was **not** used to repeat a full engine compilation during checkpoint preparation. Reproduction is only a pass after its own commands and checks succeed.

## Exact upstream and independent patches

- Official repository: <https://github.com/godotengine/godot>
- Tag: `4.6.3-stable`
- Resolved source commit: `35e80b3a8822a9df9be390814b62f44c0a9c69e8`
- Official tag archive: <https://github.com/godotengine/godot/archive/refs/tags/4.6.3-stable.tar.gz>
- Exact archive length: **66,058,610 bytes**
- SHA256: `fa22b5f974125057087c9ef725eae582dbc5e39385dc377e8d5dbc295b367e1c`
- `surfaceless.patch`: dedicated backend and build registration only.
- `gles3-tangent.patch`: separate octahedral normal/tangent skinning correction.

The installed official editor used for other local work reported `4.6.3.stable.official.7d41c59c4`. Matching “4.6.3” strings do not mean identical code. These builds use the pinned `35e80b3a` archive plus the stated patches. A changed tag/archive fails verification; never silently substitute it.

## Backend boundaries

The opt-in `surfaceless=yes` build exposes `--display-driver surfaceless` with `opengl3`. It creates an explicit EGL 1.5 `EGL_PLATFORM_SURFACELESS_MESA` display and a memory pbuffer, selects llvmpipe process-locally, and uses `RasterizerGLES3`, not RasterizerDummy. The already initialized explicit display is passed to GLAD, avoiding its default-display branch.

Headless inheritance supplies no-desktop window/input plumbing, not the Dummy renderer factory. Main-window size/draw availability, lazy pbuffer resize, EGL context binding/release and GL flush are implemented. Failed bind/resize marks the window nondrawable. Successful resizing is tested; deliberate EGL failure/recovery, separate rendering threads and multiple windows are not certified.

No X11, Wayland, GBM, native-window or default-display fallback is implemented. The build excludes X11/Wayland/Vulkan/D-Bus/SDL/udev. No display/network socket probe or system/security-setting change is part of these scripts. Physical OS keyboard/mouse, desktop focus, clipboard and screen capture are not supported. `FEATURE_MOUSE=false` intentionally leaves Viewport mouse position on Godot's synthetic Input path.

**Do not pass `--headless` for graphics proof.** It selects the upstream Dummy renderer. Use the explicit surfaceless arguments recorded by `run_proof.py`.

## Existing dependencies only

Linux x86_64; Python 3.10+; installed **SCons 4.10.1**; GCC/G++; GNU patch; pkg-config; installed EGL 1.5 and Mesa llvmpipe. Pixel QA additionally requires installed Pillow and NumPy. The original compiler was GCC 14.2. No script installs packages, creates accounts, changes system configuration or fetches remote jobs. `PYTHONPATH` may point to an already installed isolated SCons package. `PYTHON` may choose the existing interpreter.

The archive supplies bundled GLAD headers, so EGL development headers are not needed for this backend. Runtime Mesa libraries still must exist. This narrow release runtime includes GDScript, glTF, FreeType/fallback text, Godot 2D/3D physics, JPEG and WebP; core PNG remains enabled. It is **not an editor/importer**. Navigation modules are omitted, yielding dummy-navigation warnings, unrelated to actual GLES3 rendering. Runtime dependencies for a real project must be checked rather than silently changing gameplay settings.

## Reproduce locally

Run from a repository root containing this folder. Put `WORK` outside tracked source and retain outputs privately. The only network operation below is an explicit download of official Godot source; the Python/shell tooling itself does not download anything.

```bash
ROOT="$PWD/tools/local_surfaceless"
WORK="$(mktemp -d)"
ARCHIVE="$WORK/godot-4.6.3-stable.tar.gz"
curl --fail --location --proto '=https' --proto-redir '=https' \
  --connect-timeout 15 --max-time 180 --max-filesize 70000000 \
  'https://github.com/godotengine/godot/archive/refs/tags/4.6.3-stable.tar.gz' \
  --output "$ARCHIVE"
python3 "$ROOT/prepare_source.py" --archive "$ARCHIVE" --check-only
python3 "$ROOT/test_tools.py" --archive "$ARCHIVE"
SOURCE_DIR="$WORK/source"
python3 "$ROOT/prepare_source.py" --archive "$ARCHIVE" --destination "$SOURCE_DIR"
SOURCE_DIR="$SOURCE_DIR" OUTPUT_DIR="$WORK/build-baseline" bash "$ROOT/build.sh"
python3 "$ROOT/run_proof.py" \
  --engine "$WORK/build-baseline/godot-surfaceless-baseline" \
  --output-dir "$WORK/proof-baseline"
```

To add the independent tangent patch without losing baseline bytes:

```bash
python3 "$ROOT/prepare_source.py" --apply-tangent "$SOURCE_DIR"
SOURCE_DIR="$SOURCE_DIR" OUTPUT_DIR="$WORK/build-tangent" bash "$ROOT/build.sh"
python3 "$ROOT/run_proof.py" \
  --engine "$WORK/build-tangent/godot-surfaceless-tangent" \
  --output-dir "$WORK/proof-tangent"
```

`prepare_source.py` refuses an existing extraction destination and records the exact upstream/patch identities. An interrupted tangent application is checked before retry, never blindly repeated. `build.sh` requires that receipt and the tested SCons version. Outputs must be fresh directories. It preserves separate copies of finished binaries, rather than overwriting a baseline hardlink. Release templates retain `disable_path_overrides=yes`: the runner places a normal `main.tscn` project next to a fresh copied executable, not `--script` or `--path` overrides.

`JOBS=1` is the default; only 1 or 2 are accepted. The guard checks available memory (and a visible cgroup-v2 cap), source/output filesystem free space, timeout and a local `STOP` file. Defaults are at least 2 GiB available memory and 700 MiB free storage. It records samples locally and stops the process group on a breach. These are conservative checks, not an OOM guarantee on every host. Source preparation separately requires 1 GiB free. Original full-build observations were approximately 29 minutes at one compiler job with ample memory; do not treat those figures as portable speed guarantees.

To request a stop, create `STOP` inside the current guard output directory. SIGINT is sent first so SCons can finish active work; bounded SIGTERM/SIGKILL escalation follows for any live members of this invocation’s process group, even if its leader already exited. Normal leader exit with residual live work is reported as ORPHAN_CLEANUP, not PASS; monitoring exceptions use the same cleanup. Keep stopped outputs and inspect the result before selecting a fresh output directory for a retry. Source objects remain available for incremental recovery.

## Proof and QA meaning

`run_proof.py --engine ENGINE --check-only` checks installed dependencies without launching the engine. A real run sets HOME to its fresh output's `xdg/home` directory and supplies task-local XDG data/config/cache directories, unsets DISPLAY/WAYLAND_DISPLAY/XAUTHORITY, limits llvmpipe workers to two, captures output under the fresh run directory and runs `pixel_qa.py`. The caller's HOME and global settings are not changed.

The fixture defines **no `class_name` scripts**, so its empty global-class cache is truthful. A real game must have its complete cache generated by its proper editor/import workflow; never transplant this empty fixture cache.

QA requires the expected real renderer identity, zero engine/runtime errors, advancing process timestamps, actual draw counters, exact requested/root/EGL/PNG dimensions at scale 1.0, and both injected input states with observed coordinates/callbacks. Geometry checks use distinct colors and object-area-normalized changed pixels plus >5-pixel measured centroid motion. High-resolution color checks account for stride-8 sampling. These are primitive-fixture validity checks, **not the user's art-quality thresholds**. An earlier local fixture iteration failed for a missing empty class cache and scale-dependent whole-background/sampling checks; those failures were retained separately, not erased or relabeled as artistic acceptance.

Synthetic Input events are not OS input. Release-template observations are not a replacement for debug/editor assertions. This unskinned fixture cannot validate a particular skinned model's tangent correctness.

## Licensing and publication boundary

`LICENSE.txt` is Godot's MIT license; the patches and accompanying tooling use that license. Upstream `COPYRIGHT.txt` retains third-party attribution and license texts. Each successful build also collects upstream LICENSE/AUTHORS/COPYRIGHT and third-party license/notice files into its **local output artifact**, with binary/source identities. Keep those notices with any binary delivery.

No binary/source archive, PNG, game geometry, asset manifest, private report, log or environment-specific path is included in this code-only checkpoint. Nothing here publishes files, modifies GitHub/CI or broadens approval to publish HF08/source18 assets. Review the actual public tree and its existing CI separately before publishing this folder.
