# Intact rig adapter experiment, not artwork

Default OFF, no changes to `presentation.gd`, original figures, weapons, horses,
combat or shipping packages. This is the bridge for a genuinely new complete
editable character source, not another edit of the old 16-bone cut-up body.

- `native_rig_palette.gd` preserves arbitrary Skin bind ordering, original mesh
  vertices/UV/material and every imported 4/8-weight contribution. It never
  normalizes, truncates, or maps anatomy to the old 16 joints / two influences.
- 300-joint fixture (including indices 255 and 299), named binds in reverse order,
  hierarchical poses, rotations and scale: 995 Godot 4.6.3 assertions passed.
- Three float RGBA texels per bind per sample, explicit hardware texture bounds;
  original positions use the full affine transform, not a rigid approximation.
- Current texture footprint is 48 bytes per bind per frame. No realtime cost
  measured. Dynamic batching, clip sampling, state transitions, attachments and
  blend-shape animation are NOT implemented by this proof.
- A source with blend shapes is explicitly rejected unless a separately documented
  expression bake is supplied. Source files must remain editable and intact.
- Snow original face can have more than 8 influences. This adapter's claim applies
  ONLY to its imported 4/8 inputs, not all original Snow weights. The separate
  character-source audit found a worst discarded tail about 8.19%; that is a
  real unresolved adaptation problem, not an excuse to silently call it lossless.
- The GPU fixture compares native Godot Skin against palette rendering in two
  identical real viewports, retaining both unmodified PNGs and measured deltas.
  It is synthetic engineering evidence, NOT a game screenshot or art acceptance.
  Its hosted run is still pending at this checkpoint.

API contract checked against the engine's own implementation:
[Godot 4.6 Skeleton3D](https://github.com/godotengine/godot/blob/4.6-stable/scene/3d/skeleton_3d.cpp),
[MeshInstance3D bake](https://github.com/godotengine/godot/blob/4.6-stable/scene/3d/mesh_instance_3d.cpp),
[spatial shader inputs](https://docs.godotengine.org/en/4.6/tutorials/shaders/shader_reference/spatial_shader.html).

The first local packing attempt incorrectly supplied byte arrays for RGBA float
custom channels. Godot rejected the surface; no result was shipped. Corrected to
native `PackedFloat32Array`, added an explicit engine-rejection check, then the
full test exited 0. No claim of GUI/GPU parity based on this headless result.

Run:
```
godot --headless --path . --script tests/native_rig_palette.gd
xvfb-run -a godot --path . --rendering-method gl_compatibility --script tests/native_rig_gpu.gd
```

## Actual GPU failure and correction

Hosted run43604814592 reached real Godot, compiled the shader, and passed rest,
rotated and eighth-weight-tail fixtures. The nonuniform scale case FAILED: 1,919
pixels exceeded two color levels, 4.8% of visible pixels. Source and treatment
PNGs and JSON are preserved in artifact14118166362, ZIP SHA256
`4ab35c07ccebfd4e2e1064a61d1109555dadedf96a89f42857a349cf3c713825`.

Cause verified in official 4.6 GLES3 `skeleton.glsl`: native GPU uses the full
weighted affine basis for normals, unlike MeshInstance3D's CPU bake helper,
which orthonormalizes each bone. The adapter now matches the actual renderer,
shares three matrix rows for positions/normals/tangents, and halves the palette.
No tolerances were changed; rerun outcome is still pending.

## Verified GPU result

Run43605092161 caught unsupported `mix(mat4,mat4,float)` in the real shader
compiler; no result was promoted. Explicit scalar-weighted matrix arithmetic
fixed the compilation. Run43605340752 at source8caba22786c717eb001529bb0eccd8a5530a78c0
then PASSED all four unchanged pixel gates: rest, rotation, nonuniform scale and
eighth-weight-tail motion. Each original 512x512 viewport has 39,109–41,654
visible pixels; zero pixels differ by more than two 8-bit levels. Maximum
per-channel difference was one level. These are actual llvmpipe Godot renders,
not a CPU prediction. Native files, metadata and logs are in artifact14117927860;
ZIP SHA256 cc65ed5d2bfbc9cc0cceac84014e848da8cef4c7193c33c590cf4c9c50979ca7.
`passed-gpu.json` retains full figures. This is a synthetic preservation proof,
NOT final character art, a naturally moving soldier, production FPS, or M5.
