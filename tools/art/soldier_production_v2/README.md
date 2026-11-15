# Production-v2 complete natural character (WIP, not accepted)

Current entry `fit_full_coat.py` reads the complete editable professional recut
coat and official natural MakeHuman adult source. It uses actual posed source
joint landmarks, transfers the entire cloth UV mesh to the natural body, and
transfers all source skin influences by nearest-triangle barycentric weights.
It never modifies either input. New output is an editable `.blend` derivative.

This is **not a finished soldier or a game-tested asset**. First fit had exposed
underarm/torso and was rejected by direct Blender shape inspection. Fit02 tests
corrected torso/sleeve blending. Neither fit is art acceptance. Material baking,
runtime LOD, silhouette refinement, clothing penetration over all actions,
armor treatment, hands/weapon, and new-world Godot evidence remain outstanding.
Do not return to floating barrel chest plate construction. Original source rig,
UV/material detail can be preserved independently while runtime derivatives
are altered to match the owner's complete natural spearman direction.

Rig contract: `MH163`; available clips Idle_Loop, Walk_Loop, Jog_Fwd_Loop,
Sprint_Loop, Hit_Chest, Hit_Head, Death01, Sword_Idle, Sword_Attack. Ordinary
spear is NOT yet among these clips. Runtime worker owns its separate MH163
spear derivative. Target format is shared skinned GLB with complete UV/material
maps and OpenGL +Y tangent normals, not per-pose geometry JSON.

Licenses remain those of sources: Sintel professional coat CC BY 3.0 (see
`../sintel_guard/NOTICE.md`), MakeHuman official core CC0, source garments per
existing source notices. AI approved reference is project-authorized AI work,
not an external CC0 asset. Never publish the rejected conflicting Viking sources.

## Actual checkpoint: complete uniform05

Independent remote recovery branch `dot/soldier-production-v2`; no default scene
or old visual CI changes. The complete uniform uses continuous weighted surfaces,
not individual plate geometry. Complete coat surface relief is baked from the
professional source; lamellar structural maps are newly authored project work
and must not be represented as a third-party professional scan or CC0 download.

`assemble_uniform.py LOD.blend MAPS_DIR OUTPUT_DIR MH_ANIMATED.blend` explicitly
loads all nine source Actions and retains them. Appending objects alone discarded
unassigned Actions in the earlier runtime04 attempt; runtime04 had zero exported
animations and is rejected. Runtime05 actually contains one skin / 163 joints /
30 meshes / 12 materials / 9 animations. Source inputs remain unchanged.

`export_runtime.py SOURCE.blend OUTPUT_DIR` explicitly normalizes at most eight
runtime influences, reporting discarded weight; the full editable source keeps
all weights. Godot 4.6.3 cold import and `check_import.gd` passed for runtime05:
163 bones, nine animations, 30 surfaces, 16 normal-map material instances, finite
transforms after advancing idle/walk/jog/sprint/hit/death. Godot removes `_Loop`
from imported clip names; this naming behavior initially failed the assertion,
then the explicit runtime aliases were tested. This is HEADLESS technical QA,
not graphics performance or visual acceptance. No GPU test has been run.

Blender full-body idle/walk/jog/hit/death views were inspected. The integrated
figure is still visually inadequate: coarse armor/helmet material treatment,
shoulder/collar suspension, leg-wrap silhouette, and death-pose skirt behavior
need further whole-character work. Never label this a finished army asset.
Ordinary spear is independently authored on the exact MH163 source by the
runtime worker and is not included in the nine source clips listed above.
