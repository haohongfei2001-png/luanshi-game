# Sintel Guardians r854: native structure review, not accepted game art

Status: local source evaluation only. No source models/textures/renders are included in this commit; redistribution basis is now confirmed by the source researcher: official project-wide CC BY 3.0 grant, not a license inside the ZIP. No shipping integration or character replacement.

Actual Blender 4.3.2 evaluation with `--disable-autoexec`, no embedded UI Python executed, source SHA checked unchanged:
- Original main rig: 308 bones, 79 deform, 246 pose constraints; 70 driver records valid. This does not prove all legacy controls or animation work.
- Original bound MeshDeform cage and Multires modifiers were retained. Top, pants, boots, head and crossed belts all evaluated to finite geometry in native assembly positions.
- Two original-pose clay renders and one primary garment-diffuse diagnostic completed and were personally viewed. Genuine folded long sleeves, overlapping collar, waist layering, loose trousers and shoe lasts are substantially better structured than the rejected body shells/bathrobe.
- This is an early fantasy/European design with crossed chest belts, large medallion and buckled boots. It is NOT a Chinese soldier, film-final asset, or approved face/costume.
- Diffuse references come from the original Blender 2.50 binary material slots recovered separately, not guessed filenames. Old source materials remain as datablocks. Constant roughness and neutral unresolved skin/hair are explicit diagnostic substitutions, not original-shader equivalence. GuardianTop secondary leather is now confirmed height-only, not a color blend. Primary diffuse looks pale/noisy; do not darken it by mixing the height texture into color.

Reproduce with the locally acquired original package (never overwrite it):

```sh
SRC=/path/to/guardians_r854/guardian_lao_tseu.blend
MAP=/path/to/guardian-lao-legacy-materials.json
blender --background --disable-autoexec --python-exit-code 1 --python tools/art/sintel_guard/inspect_master.py -- "$SRC" /path/to/review
blender --background --disable-autoexec --python-exit-code 1 --python tools/art/sintel_guard/clay_review.py -- "$SRC" /path/to/clay
blender --background --disable-autoexec --python-exit-code 1 --python tools/art/sintel_guard/material_review.py -- "$SRC" "$MAP" /path/to/diffuse
```

Next: retain the complete editable source and original author rig; validate actual native controls/cage deformation before adaptation. Restore legacy height/skin semantics with explicitly measured modern-renderer differences. Costume redesign must change actual fantasy cut/accessories into a coherent historical silhouette, not recolor this render. Do not rebind to MH/65 bones, flatten Multires, reduce to old 16 bones, or claim Godot/native 2K/4K performance from these Blender diagnostics.

## Actual native FK probe

`clay_review.py ... /path/to/fk-probe --fk-probe` was run successfully. It changes only original hand IK custom properties and original upper-arm/forearm FK rotations; original cage/Multires structure remains intact. Both full-body and torso images were generated; the full-body image was personally inspected. Sleeves and layered forearm wraps follow the original rig, unlike disconnected static attachments. This synthetic single pose is not a donor animation, cycle validation, contact/collision test or combat hold. No original embedded UI script ran; source SHA unchanged. Store the renders locally until redistribution/attribution is cleared.
