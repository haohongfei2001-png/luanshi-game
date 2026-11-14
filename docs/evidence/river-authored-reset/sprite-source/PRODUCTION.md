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
