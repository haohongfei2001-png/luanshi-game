# Sprite Fright native-source adaptation, experiment 01

This is a source-conversion experiment, NOT a new battlefield candidate.
The official exact ZIP and package-specific CC BY 4.0 attribution are in SOURCE.json and ORIGINAL_README.txt. Native input is read-only; no source .blend has been saved over. The complete collection has a common procedural material family, unlike the rejected mixed R1/R2 foundation.

## Actual progression and failures

1. Independent set datablocks were readable. Switching to scene `030_0100` and querying object dimensions caused evaluated-dependency-graph memory pressure and the process exited 137. No full-set rendered preview was obtained. Preserve the original set and use author-defined library collections; do not claim full-shot loading success.
2. Appended complete `EN-bush.01` from `lib/env/bushes.blend` into an empty scene with source materials and geometry nodes intact. Actual neutral-light Cycles rendering succeeded and was inspected. This is a small natural shrub, not a mature tree or a Chinese landscape. The derivative render caps subdivision at 1; the source is unchanged. It does not reproduce the film lighting.
3. The first derived whole-mesh export accidentally included an invisible procedural distribution proxy. Its GLB imported and passed mesh-count tests but the actual image was grossly wrong. It was explicitly rejected. This demonstrates why passing import/count tests cannot establish art quality. The conversion now respects both `DepsgraphObjectInstance.show_self` and `hide_render`.
4. Visible source evaluated geometry is 90484 triangles across 291 mesh instances, not the earlier 94324/292 count that included the invisible 3840-triangle proxy. These are evaluated source counts, not runtime frame cost or source base-mesh counts.

## Real-time conversion contract

Preserve the full author collection, branch-to-leaf topology and placement. Evaluate only this admitted collection, not all set/shot instances. Keep original UV layers; add a separate atlas layer on a derived mesh. Source shaders remain on duplicated material slots of the visible evaluated surface and are sampled using Cycles diffuse-color baking. The source material graphs are not modified. The output uses one mesh/one material surface, avoiding hundreds of leaf surfaces. This does not prove one actual draw call across shadow/depth passes; actual draws require Godot profiling.

Current experimental bake: 1024 atlas, 8 samples, visible-surface self bake with 4 px dilation. The attempted 2 mm cage/10 mm ray selected-to-active version produced severe white gaps and was also rejected; it is not the successful conversion route. Object Info random values may differ after realization and must be visually reviewed. Source normal/bump and two-sided transmission conversion are NOT complete. The first prototype is not a faithful final shader replacement. No mesh decimation, counterfeit baked lighting or silent internal-resolution reduction is applied.

## Reproduction

Keep the complete native source directory structure from the exact archive. No scripts bundled in the source are executed.

```sh
blender -b --factory-startup --disable-autoexec --python-exit-code 1 -t 2 \
  --python tools/art/sprite_source/preview_native_collection.py -- \
  /path/030_0020_A/lib/env/bushes.blend EN-bush.01 /tmp/sprite-native-preview
blender -b --factory-startup --disable-autoexec --python-exit-code 1 -t 2 \
  --python tools/art/sprite_source/bake_native_collection.py -- \
  /path/030_0020_A/lib/env/bushes.blend EN-bush.01 /tmp/sprite-bush-bake
```

Use separate output directories per experiment. A report written before baking is not a successful completion receipt. `complete.json` is emitted only after bake, GLB export and derived image rendering; it contains output hashes and Linux process peak RSS. Blender internal allocator peaks printed in its log are not process RSS and must not be relabeled.

The source library is production-quality input, not proof that this conversion, a 22 m view, Chinese flora, bridge/gate architecture or a whole new map meets the owner's reference. Native Godot graphical review, complete input movies and all-battlefield performance remain required.

## Verified checkpoint

Visible-surface bake completed and its actual image was inspected: source branching, leaf arrangement and green/brown family are retained without the earlier proxy shell or white-ray gaps. This is an internal conversion checkpoint, not an art pass. Source bump/transmission and joined-object-space/random variation remain documented limitations. Actual Godot headless GLB intake: 90484 triangles, one mesh, one surface, one textured surface, two UV channels. Actual Godot graphical output/draw calls: NOT_RUN. The complete converted native shrub is not a finished region/map.

## PBR conversion follow-up

Added actual source tangent-normal and roughness baking at 1024 each. Reordered only the derived UV layers so the bake atlas is UV0 for runtime compatibility; original source UV values are preserved exactly in the secondary channel, asserted before export. The first UV reordering loop failed because removing Blender UV layers invalidated stored layer references; it exited 1, emitted no completion receipt, and was corrected by removing each live first layer. Source .blend remained unchanged.

The corrected bake rendered successfully and was personally inspected. Godot 4.6.3 headless intake additionally verifies actual normal-map and roughness texture presence, one material surface, 90484 triangles and two UV channels. `bush01-pbr-conversion.json` records hashes and process peak RSS. The original diffuse-only checkpoint remains recorded, not retroactively relabeled PBR.

Two-sided transmission, exact per-instance object/random variation, source-vs-derived measured pixel error, actual Godot graphics, runtime draw calls, normal 22 m whole-region composition and army performance are still NOT VERIFIED. This remains an isolated production conversion, not a final landscape or a reason to stop rebuilding.

## Complete native tree, shared geometry atlas checkpoint

The complete author collection `EN-tree.1` was actually rendered and personally viewed with original materials. At explicit subdivision cap 1 it evaluates to **2577644 triangles / 2690 mesh instances**. The 1500000 triangle production guard rejected this; a separate offline source-review ceiling of 6000000 was used only to inspect original quality, not to raise the realtime budget.

Measured source contributors: three oak leaf geometries each 808 triangles, repeated 1140/798/684 times; one 5084-triangle branch repeated 57 times; 123200-triangle trunk; bracket fungi. A separate derivative index-LOD experiment retains all source leaf/branch placements and reduces leaf/branch/trunk/fungus mesh indices to **185676 triangles**. Native files remain unmodified. Same-camera offline source/LOD renders were viewed; the full-frame RGB error (background-biased, eight samples) is diagnostic, not visual acceptance.

The first whole-tree baking attempt was rejected as black foliage. Looking at its actual atlas exposed the primary fault: thousands of repeated leaves were individually unwrapped into a 1K atlas with excessive island padding, leaving subpixel islands. An initial shader-closure-only diagnosis was insufficient. Do not repeat this route or reuse its black GLB.

`bake_reusable_collection.py` is the corrected whole-tree route:

* Evaluate **12 unique author geometries once**, preserve all 2690 placements, and reuse their UV tiles across repeated leaves/branches.
* 2048 shared diffuse/normal/roughness atlas, four-by-four tile layout. No duplicated per-leaf atlas allocation, no fake lighting baked into color.
* Oak front/back shader closure is view-dependent. The original `SH-TwoSidedTransimission` input color/normal/roughness chains are extracted for baking from copied materials; realtime light transmission is still NOT implemented.
* Preserve source UV values exactly in the secondary channel, shared atlas in UV0. Preserve author `collection.instance_offset` rather than lifting exposed roots by their AABB minimum. The tree is intended to meet ground at its authored origin, not at the tip of its lowest root.
* Export complete merged geometry as one mesh/one material surface, not 2690 individual runtime draw surfaces. Actual multi-pass draw-call count remains unmeasured.

The corrected actual derived image was viewed: the black foliage failure is resolved and the source crown/branch arrangement survives. Exact color/random/object-space variation is canonicalized by source type, and microscopic differences remain. This is a usable conversion checkpoint, **not an accepted Chinese battlefield**.

Verified Godot 4.6.3 headless intake: 185676 triangles, one mesh, one surface, diffuse/normal/roughness textures and two UV channels. Conversion peak process RSS: 1266560 KiB on this Linux cloud machine. This is **not game memory or FPS**. Output GLB SHA256: `4c2d42c37a3df11d9982180cfdf1c2020f77e15d2b673dbb258a38b5616c4760`.

```sh
blender -b --factory-startup --disable-autoexec --python-exit-code 1 -t 2 \
  --python tools/art/sprite_source/bake_reusable_collection.py -- \
  /path/030_0020_A/lib/env/trees.blend EN-tree.1 /tmp/sprite-tree-shared
godot --headless --path . --script tests/art_reset/sprite_gltf_intake.gd -- \
  /tmp/sprite-tree-shared/derived.glb 185676
```

Next: derive coherent ground/rock/understory from the **same production family**, author the complete river approach with correctly grounded roots and retained combat spaces, then obtain real Godot native-resolution same-camera whole-region evidence. Bridge/gate professional architecture remains unresolved. Neither one shrub nor one tree is a completion condition. No failed R1/R2 visual assets are reintroduced.
