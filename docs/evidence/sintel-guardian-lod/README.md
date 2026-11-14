# Whole top LOD experiment, static only

Actual Blender source render4 top: 681,984 triangles. Complete authored level1 top: 10,656 triangles / 5,412 vertices, all original UV and garment boundary structure retained. Selected-to-active tangent-normal bake (1024²) completed. Separate local editable diagnostic blend retains original complete source rig/cage; no bone reduction, body slicing or guessed skin transfer.

Personally viewed same-camera high/low close clay renders: most broad cloth folds remain visible in the low+bake version. The left sleeve outer silhouette loses some fold depth and the inner cuff/neck needs close inspection. This is a promising static detail-transfer candidate, NOT accepted costume or runtime deformation. Four full-resolution static Blender captures were also generated at 3m native3840×2160 and22m native2560×1440; actual render percentage100, horizontal FOV50°. The low22m frame was inspected: entire isolated top is small and broad folds read, but no whole soldier/environment/game performance is demonstrated. Full-resolution3m images are preserved for further review, not yet declared inspected.

Native cage reference captures rest plus three original FK upper-arm/forearm poses. All 5,412 corresponding vertices, original polygon loops and loop UV remain exactly indexed. Original308/79 rig intact. Runtime armature approximation has NOT been implemented/measured. Do not infer animated parity from the identical deform-bone count.

First strict triangle-index test failed: Blender tessellation chooses different quad diagonals under deformation. Failure log retained. Correct reference now stores original invariant polygon-loop/UV signature and each pose's evaluated triangles separately, plus frozen rest triangles. This is not a topology mismatch silently ignored.

Reproduce:
```
blender --background --disable-autoexec --python-exit-code 1 --python tools/art/sintel_guard/top_lod_probe.py -- SOURCE.blend OUT
blender --background --disable-autoexec --python-exit-code 1 --python tools/art/sintel_guard/top_lod_capture.py -- OUT/whole-top-lod-diagnostic.blend OUT/native
blender --background --disable-autoexec --python-exit-code 1 --python tools/art/sintel_guard/native_pose_reference.py -- SOURCE.blend REFERENCE_OUT
```
Source recovery/CC BY3 attribution: `tools/art/sintel_guard/NOTICE.md`. No generated binaries included here. Generated Blender images must never be labelled actual Godot footage. No default game path changed.

## Native cage affine-law experiment

`cage_linearity_probe.py` actually evaluated all three FK poses at Multires0 and1. The566-point cage has only an Armature modifier; MeshDeform bound=true/dynamic_bind=false. Replaying each actual posed cage directly with its Armature temporarily disabled reproduced garment vertex positions exactly at both levels. Source file remains unchanged.

Midpoint cage blend vs midpoint garment surface: level0 max residual0.108µm, level1 max residual0.820/2.063/2.889mm for elbow/shoulder/combined. Thus base cage deformation is consistent with a fixed linear representation in these tests, but added sculpted Multires displacement is NOT perfectly affine. Bone-specific bind positions may reproduce the base cage response; they cannot automatically preserve nonlinear sculpt detail/normals. No ordinary LBS weights were transferred, no runtime implementation or quality pass is claimed. Keep this measured boundary when choosing corrective shapes or other runtime deformation.

A single bounded basis-recovery experiment also completed: 566 native cage-X perturbations recover1373×566 coefficients. Independent native FK validation, including an extra held-out pose, has worst17.03µm base-surface error. Original file remains unchanged. This is finite-difference evidence, not exact algebra or a production GPU implementation; there is no reason to chase float-zero here. Subsequent work should prioritize visible3m/22m animated garment quality and full-character integration. The measured Multires nonlinearity remains separately recorded, not erased by this base result.
