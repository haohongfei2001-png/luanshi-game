# Minimal native Skin vs complete-weight Metal oracle (NOT RUN on Metal yet)

This is a read-only isolated renderer check, not a new engine build or a game
replacement. Common palette/material/shader code is byte-identical to the
reviewed Linux oracle. The four native full-material poses and strict threshold
remain unchanged: >1000 visible pixels, mean RGB error<.001, and <2% of visible
pixels exceeding2/255. No diagnostic material override is accepted by the primary
Metal gate. No art, full motion, armor, full-battle performance or M5 acceptance.

## Source and minimal dependencies

Source model from immutable `bf520c13aa393c2fdc4b5c2596cfe5cbdb0bd7d9`:
`assets/ubc_lab/ubc_animated.glb`,16003500bytes,SHA256
`64705ebc4a20650b79f863bae4b6ec47df06dfefe0ed451fe73a04ebc46295c0`.
`prepare.py` copies only this GLB, its seven extracted material images and import
settings, exact original CC0 license notices, four shared helper files, and three
test scripts.31MB total source rather than the entire field project. No Python
packages beyond standard library needed. Import creates its own GPU resources.
The manifest contains every copied file's exact bytes/hash. Author editable
source remains preserved in the repository; the test does not alter it.

The native oracle came from reviewed `dot/godot-native-tangent-fix`5c59b736 and
local matching0fce27c. Original test SHA256:
`4ac902992d22e900c820bd0dc024b9986784e0b2c44bbd29c91753b53998eb48`.
Only normal-export entry class names, output paths, runtime backend guard and engine/driver telemetry changed.
Common source hashes:
- native_rig_palette.gd:7f359343afd1b291e139b49aef48b971b382251dd886e958b4481f72f3cb75c0
- native_rig_material.gd:d6a52f9e32804dde3dbd8eaeeb294ef863076abacb7120e956b73e4bd3259da9
- textured_native_rig.gdshader:62e199d8c1e88709e29f99c630d1567359123e178454ec3c125709c14a82289f
- full_weight_reference.gd:da05dcd071dcfa54d440e7cd17cc61db74a31825723ff358978fae941687968b

## Existing verified Mac runner integration

1. `python tools/metal_character_oracle/prepare.py /path/to/small-project`
2. Use the runner's already-verified official Godot editor to import that project.
3. Preserve editor version/hash, actual Mac model/OS, and packaged resource SHA.
4. The generated project sets `application/run/main_loop_type=MetalCharacterOracleGPU`
   and a minimal empty-Node main scene (required by startup validation). Import/export normally so the global class cache is
   packaged. Use the existing normal adjacent-PCK/bundle launch, with:

```sh
INTACT_REQUIRE_METAL=1 INTACT_PARITY_FULL_MESH=1 \
INTACT_OUTPUT=/absolute/writable/evidence/metal-gpu \
GODOT --rendering-method mobile --rendering-driver metal
```

**Do not rely on `--script`, `--path`, or CLI main-loop overrides in the native
release template.** Without OVERRIDE_PATH_ENABLED they are silently cleared by
35e80 main/main.cpp. This oracle is a normal exported MainLoop, not a bypass of
that engine protection. Parent's verified adjacent-PCK placement still applies.
No gameplay resources are included in the minimal project.

Keep `INTACT_OUTPUT` outside the PCK. Do not use `--headless` for GPU evidence.
The entry rejects silent non-Metal/non-Mobile fallback. It saves eight512²
native/batch images plus parity.json and exits nonzero on original gate failure.
`prepare.py --entry cpu` or `--entry weights` creates the matching normal-export
MainLoop configuration for a separate diagnostic PCK. CPU JSON goes to
INTACT_OUTPUT/cpu.json. Headless CPU success is not Metal graphics success.

The earlier tangent patch affected only GLES3 `storage/mesh_storage.cpp` and
`shaders/skeleton.glsl`. It is NOT presumed necessary for Metal and its Linux
failures are NOT automatically attributed to Metal. Official release7d41 and
same-tag source35e80 are distinct revisions; record actual engine, never spoof.

Local minimal-project import, CPU and weight tests are checked separately. The
actual Metal images/gate remain NOT_RUN until the native Mac job produces them.

## Release-template assertion safety

Do not trust GDScript `assert` or exit0 alone in template_release. After actual
Mac graphics, run the external Python/Pillow gate (without `python -O`):

```sh
python tools/metal_character_oracle/check_gpu_result.py /evidence/metal-gpu \
  --log /evidence/metal-gpu.log --fixture-manifest /small-project/fixture-manifest.json \
  --cpu-json /evidence/metal-cpu/cpu.json
```

It requires real Mobile/Metal telemetry, no diagnostic substitutions, exact
source model/shared adapter hashes, all four unique poses and eight valid512²
PNGs. It independently recomputes the original2-level/2% and MAE threshold from
PNG pixels, checks the optional complete68047 CPU assertions, and rejects any
actual SCRIPT/SHADER/ERROR marker. PNG/global-mode metadata alone is not a pass.
Pillow is the only external checker dependency; no original asset rewriting.
