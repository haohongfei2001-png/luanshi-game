# Complete native garment derivation, not shell replacement

## Measured source cost

19 visible mesh objects: actual viewport depsgraph 80,163 vertices / 159,660 triangles. Enabling each original render modifier level in memory gives **947,022 vertices / 1,891,000 triangles**, excluding particle hairs. Original file unchanged. These are measured counts, not frame-rate estimates.

Render-level top alone 681,984 triangles; pants 314,368; boots 131,328. This explains why exporting low-resolution cages alone would lose the professional folds seen in the clay image. Hands are 76,608 triangles even at viewport settings. Eye objects have duplicate-looking names but must be inspected structurally, not deleted merely by name.

## Runtime boundary

Full author source remains the editable master: 308 original bones, 79 deform, bound cages, Multires detail, 23 head shape keys, source UV and constraints. Godot glTF cannot natively reproduce Blender MeshDeform / Multires / legacy particle hair / control constraints. A static evaluated GLB is NOT an animated character solution. Do not substitute guessed nearest-bone weights or flatten the master.

A runtime derivative needs independently validated skinning/baked motion and detail transfer. Preserve all original named rig interfaces in the master. Provisional production budget, NOT achieved: hero close view 40–70k triangles, normal-distance soldier 15–25k, distant 3–8k. Before reduction, compare evaluated authored silhouette and fold/normal maps at 3m and 22m; verify wrist/elbow/shoulder/knee envelopes against original deformed surfaces. No LOD is generated or accepted by this commit.

## Unified historical redesign scope

- Keep complete professionally modelled sleeve/shoulder and trouser/boot construction as a starting point, not the costume identity.
- Replace crossed chest belts and circular film/fantasy emblem with actual overlapping right-lapel structure and coherent tied waist. This requires editing connected seam/border topology, not alpha masking or recolor.
- Rework Western buckle/strap details and oversized high boot silhouette into the chosen historical ordinary-soldier clothing design; preserve proper shoe last, sole and layered ankle volumes.
- Shoulder protection must follow garment/arm movement and have an authored attachment design; no procedural plates pasted onto muscle.
- Do not adapt Lao's identifiable older face/beard as a main character. Ordinary soldier face/hair requires an independent approved design.
- Keep source modern-material migration separate from historical redesign so errors cannot be hidden behind recoloring.

## Source material correction and actual local probe

Original GuardianTop UV slots: primary diffuse also drives bump/specular-color; secondary leather drives **only bump**, not base color. Negative old norfac values -0.05 / -0.4 are preserved in source parameter JSON. Modern Principled/Bump units are not numerically equivalent. An explicitly experimental 1mm / 0.125mm sequential inverted-height probe was actually rendered and inspected; it is NOT a faithful legacy-shader conversion or accepted look. Original nodes/materials remain in the local editable diagnostic blend, source SHA unchanged. Skin/hair remain neutral unresolved, never called complete.

License basis: © copyright Blender Foundation | durian.blender.org. CC BY 3.0 https://creativecommons.org/licenses/by/3.0/ . Original r854 source https://durian.blender.org/wp-content/content/guardians_r854.zip . Official grant https://durian.blender.org/sharing/ . ZIP has no standalone LICENSE; researcher verified project-wide grant and no conflicting file-level terms. All 13 missing image references are inactive surface dependencies; do not download unverified external reference photographs. No new source binaries are published by these commits.

The exact source recovery script was also run in extraction mode to a fresh workspace directory: all 36 files verified and extracted successfully, no source scripts executed. `garment_topology.py` now measures original connected boundary components / vertex IDs of six full garment objects, retaining their exact control topology. These seam records are for planned collar/cuff/hem edits, not a claim that open clothing edges are holes or that low-resolution cages contain the rendered folds.
