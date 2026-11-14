# One-angle whole-actor engine comparison, default OFF

This candidate is not a new scene background, a new animation set, or a source-equivalent performance test. Keep the current accepted gameplay/default presentation unchanged.

Required files:
- `scripts/field/experimental/owner_static_spearman.gd`
- this directory's unchanged `spearman-elevated.png` and `.png.import`
- provenance and NOTICE

1. Record the real battle snapshot, frozen tick/time, camera transform/projection and current 3D actor's actual projected helmet/sole body height. Do not include spear/plume in the body measurement.
2. Add `preload("res://scripts/field/experimental/owner_static_spearman.gd").new()` to the existing field.
3. Call `configure(camera, Ground.unit_point(unit.pos, battle.bridgehead), body_height_logical_pixels)`. Require `OK`. The sprite remains at that exact ground anchor with no upward lift. The caller must not move the camera, alter simulation, change force count, or shrink the unit to make the image fit.
4. Save the 3D baseline first. For the one fixed-view comparison only, hide that same 3D actor's visual and show the sprite. Preserve the existing per-unit visual-hide ID; never hide another unit or change Battle state. Verify the battle snapshot hash is identical afterwards.
5. Save `receipt(camera)` with both actual original-resolution engine images. Restore the old visual afterwards, including on capture failure.

The PNG has no animation and one fixed painted heading. It must NOT be connected to movement/attack as though it has correct animation or facing. It can be used to assess normal-size appearance and alpha behavior only. A difference versus the old 3D source is not a fair same-source 3D-vs-sprite benchmark.

The source helmet-top Y=174 and lowest-sole anchor (590,1244) are manually annotated pixels. The calibrated 3D billboard footprint is NOT anatomical per-pixel depth or proof that both feet contact terrain. Normal depth testing is enabled, `fixed_size=false`, no `no_depth_test` or render-priority bias. The plane may still intersect/clip with ground and other geometry. Test it against light earth, dark soil, real foliage, front and rear occluders; preserve failures. Shadows are deliberately OFF, explicitly not dynamic-shadow equivalence. A plane-shaped shadow is not a substitute.

The import uses lossless mode, `fix_alpha_border=true`, generated mipmaps and straight (not premultiplied) alpha. The original PNG remains unchanged. Do not interpret headless contract checks as actual pixel/alpha/occlusion PASS. Headless test command: `godot --headless --path . --script tests/owner_static_spearman_test.gd`. Real engine comparison remains required.
