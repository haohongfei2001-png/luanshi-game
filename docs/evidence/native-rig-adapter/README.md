# Intact rig adapter experiment, not artwork

Default OFF, no changes to `presentation.gd`, original figures, weapons, horses,
combat or shipping packages. This is the bridge for a genuinely new complete
editable character source, not another edit of the old 16-bone cut-up body.

- `native_rig_palette.gd` preserves arbitrary Skin bind ordering, original mesh
  vertices/UV/material and every imported 4/8-weight contribution. It never
  normalizes, truncates, or maps anatomy to the old 16 joints / two influences.
- 300-joint fixture (including indices 255 and 299), named binds in reverse order,
  hierarchical poses, rotations and scale: 995 Godot 4.6.3 assertions passed.
- Six float RGBA texels per bind per sample, explicit hardware texture bounds;
  original positions use the full affine transform, not a rigid approximation.
- Current texture footprint is 96 bytes per bind per frame. No realtime cost
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
