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
`NOTICE.md`), MakeHuman official core CC0, source garments per
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

## Whole costume reconstruction after parent visual review

`retailor_long_uniform.py FIT_SOURCE.blend OUTPUT_DIR` extends the complete
professional inner garment and retapers its sleeve ends, makes actual lower
walking slits, and transfers lower weights to the real natural thighs. Run
`bake_coat_lod.py` again afterward; do NOT reuse the previous short-coat normal.
Then run `assemble_uniform.py` with the resulting long-coat LOD. The shoulder
mantle is continuous from clavicle to upper arm; the collar has overlapping
inner/outer facings, and skirt gores now extend near the knee. Each source image
is still self-reviewed and failed variants retained, never shown as acceptance.

Known exporter warnings on runtime05: one armature-parent lookup warning and
four multi-image sampler notices (present before the new spear was added).
Godot cold import produced no warning/error and the recorded focused tests
passed, but this does not establish render material equivalence or explain
away the exporter warnings. The missing optional Draco library message is not
compression success; the exported GLB is uncompressed.

## Serialized-runtime corrections and actual runtime10 checks

The source MH actions are 120 FPS. A Blender scene inherited from the old coat
was 24 FPS, making runtime05 five times too slow despite finite bone matrices.
All three production stages now explicitly set 120 FPS / base 1.0. The Godot
check verifies real durations (Idle 2.5 s, Walk 1.3333 s, Sprint .6667 s, Death
2.4 s); `check_glb_contract.py` independently reads serialized animation inputs.
The old focused PASS did not test timing and is not a correct-motion verdict.

The AI color atlas has eight columns/four rows; its UV scale must be .125/.25.
A generic VectorMath node appeared correct in Blender but was dropped by glTF.
The candidate now uses a standard Mapping node; runtime10 actually contains
KHR_texture_transform with that scale. This check is mandatory before calling
its material layout preserved. Normal-map source remains independently authored.

Actual runtime10: 163 bones, nine animations, 26 surfaces, 10 normal-map material
instances. Serialized clip durations + AI UV transform PASS; actual Godot 4.6.3
headless import, animation duration assertions, bone finiteness and normal-map
presence PASS. GPU/visual acceptance NOT RUN. Full-body Blender action review
still revealed skirt/leg-layer penetration. The next whole-uniform skin derives
armor from the exact underlying coat and puttees from exact underlying trousers,
not independently nearest-body weights that drift apart under articulation.

## Supported outfit 12–15: blocked on full-motion fault

`derive_structural_uniform.py` derives actual cut source cloth topology, gives
chest/shoulder groups stable supports, preserves flexible joint cloth, binds
puttees to their real trouser topology and shin support, and recuts ankle shoes.
No new limb removal or barrel enlargement is used. Source originals remain.

The complete 15 candidate was rendered at Idle/Walk/Jog/Hit/Death. Idle/Walk
removed earlier large layer holes and soft waist deformation, but **Jog/Death
expose long needle-like geometry**. Therefore 15 is blocked: do not put it into
a GPU evidence candidate, internal playable package or default army. The exact
fault is being measured by object/POSE, longest edge relative to rest and separate
Bevel/Solidify disable comparisons. Finite bone matrices and an Idle screenshot
are not sufficient validation. Every corrected candidate needs representative
idle/walk/jog/sprint/spear/hit/death frames and actual animated bounds checks.

`review_normal_pixels.py` uses a fixed 32-degree camera, 512×512 authoring canvas,
and nominal 180px body sizing, explicitly reporting projected geometry bounds.
Actual 15 sample heights were 195.09px Idle and 177.15px Walk at identical camera.
These are Blender source diagnostics, NOT actual game evidence or art acceptance.

## Motion repair 16–18 (WIP, not visual acceptance)

`validate_supported_motion.py` identifies actual evaluated edges, their exact
rest counterparts and world bounds over 129 sampled poses from all 14 actions.
The gate is unchanged: edge >12cm AND >4x rest, stable topology, finite geometry,
known positive source weights and <=3m actor extent. It is not an exhaustive
continuous collision test. Candidate 16 failed 180 records; 17 failed 55; 18
passed these same sampled checks with zero failures. See MOTION_REPAIR_REPORT.json.

The shoulder needle root cause was isolated to live micro-Bevel, not missing
limbs; thin Solidify remains. `repair_support_transitions.py` creates real inner
cloth seams and smooth full-length skirt support, locally smooths inherited
trouser crotch weights, and gives rigid shoulder groups consistent support.
`smooth_inner_cloth_support.py` fixes the remaining waist/armpit/seam weight
jumps on soft undercloth only. It does not alter UV, positions, body or hard armor.
Four actual Blender poses (Jog, Death, Thrust31, spear Sprint) were reviewed.
Long needles are absent, but garment coverage and helmet/shoe material remain
below target. Source18 has all 14 actions at120fps, no weapon object; runtime
adds the true wrist-bound spear without duplicating clips. No new GPU evidence
or art acceptance is claimed. This is an integration WIP, not default artwork.
