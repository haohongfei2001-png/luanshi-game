# Ground and evaluated-instance conversion checkpoint

Status: PRODUCTION EXPERIMENT, ART FAIL / GODOT GRAPHICS NOT RUN.

The source package and licence are pinned in SOURCE.json and ORIGINAL_README.txt.
`bake_ground_base.py` appends only `GEO-grove_ground.base` from
`lib/sets/mushroom_grove/mushroom_grove.blend`. This is the author's hidden
5070-vertex base, NOT the film render/highres. The original file is never saved.
The derivative explicitly unhides the object. Original named UVs,
`ground_blend` and moss-mask image remain in the material evaluation.
The original active UV remains the source shader default; the bake operator
explicitly selects GroundRuntimeAtlas as its target. This avoids silently
changing the original default-UV material when creating a runtime atlas.

Run `export_ground_survey.gd` headless with one output JSON argument. Then run
Blender with `--factory-startup --disable-autoexec --python-exit-code 1 -t 2
--python tools/art/sprite_source/bake_ground_base.py -- SOURCE_BLEND SURVEY_JSON
OUTPUT_DIRECTORY`. Use a fresh directory for each attempt. `complete.json`
exists only after all bakes/export/review render finish. The proposed imported
support test is `tests/art_reset/sprite_ground_intake.gd -- DERIVED_GLB`.
It checks vertices against shared gameplay heights; triangle-interior support
and route coverage are NOT yet validated. The grove is an irregular authored
patch, not a rectangular complete battlefield. No complete scene claim.

Observed failures retained outside the repository: initial bake poll failed
on hidden base flags; the second source preview was empty due to a stale
object matrix before view-layer update. Third preview genuinely shows the
source moss/dirt masks; edge texture stretches are visible and are NOT accepted
as final ground. Third bake was still running at this checkpoint; no complete
GLB or passed ground-intake result is claimed.

`bake_reusable_collection.py` now keys evaluated geometry by vertices, topology,
UV, attributes and material identity, not original object name alone. Actual
fern inspection found two GeometryNodes instances with the same original name
but different evaluated geometry. It also exposed a visible CURVE stem that
the old mesh-only filter omitted. Conversion now fails closed for unsupported
visible geometry rather than silently delivering incomplete plants. The fern
repair remains incomplete and its previous displaced-leaf GLB is rejected.
The new signature path has not yet been validated for a complete tree bake.
The previously frozen tree GLB remains the known offline comparison baseline.

The shared-tree intake rerun after deferring SceneTree initialization passes:
185676 triangles, one mesh/surface, two UV channels, color/normal/roughness
textures. Bounds are (-3.865013,-2.366305,-3.735504), size
(7.172149,7.005995,8.130166). This is import data, not real draw calls or art.
All normals baked so far are source material normals on the derived geometry,
NOT high-poly geometric detail projected to low-poly meshes.

## Woodland region 01

`assemble_woodland_region.gd -- TREE_GLB BUSH_GLB OUTPUT_SCN` now creates a
whole edge composition of five complete trees and five complete bushes, not
random points. Three northern crowns connect behind the action lane; two
southern crowns form a sparse near frame. Root origin is preserved at shared
terrain height, so the original exaggerated underground roots are not raised
by bounding-box normalization. No army/simulation/collision writes occur.

Inputs are the frozen tree `4c2d42c37a3df11d9982180cfdf1c2020f77e15d2b673dbb258a38b5616c4760`
and PBR bush from PRODUCTION.md. Output stores each input SHA256. Generated
binary is not committed; restore with the production bake commands. Nominal
instanced triangles: 1,380,800, NOT measured submitted primitives/draw calls.
The engine lifecycle test opens and frees this packed scene three times and
verifies ten instances share only two mesh resources. Graphical composition,
material appearance, shadows, branch visibility and performance are NOT RUN.
The assembly is a woodland component, not a complete playable environment.

## Explicit road-wear material derivation (not yet game-reviewed)

Static source inspection confirms `ground_blend` is a BYTE_COLOR/CORNER author
attribute, but `ground.grove` does not read it. The effective source chain is
moss-mask + procedural noise/cracks -> ColorRamp.003 -> Mix Shader.Fac.
Mix input 1 is the original Dirt BSDF and input 2 the original Moss BSDF.
`--road-wear` inserts only a multiplicative road factor after that ramp,
retaining both complete shader families. The protected lane is dirt; a smooth
3.9-to-6.1 m shoulder restores the original moss mix. This is explicitly new
authored wear, not original film content and not geometric wheel ruts.
`--preview-only` stops after an actual Blender material render, without bakes,
GLB export or a completion receipt. It is NOT Godot/game evidence.

Observed source edge streaks remain rejected. Their cause is not established:
the source image node uses REPEAT (not CLAMP) and its original named UV range
is within 0..1. A visual streak alone does not identify the sampling fault.

## Full-base result and safe-core follow-up

The full-base PBR conversion completed (9856 triangles, peak RSS 1018388 KiB),
with all three 2048 maps and GLB. Godot imported it and the protected-route
check found zero holes across 495 samples, worst interpolated height error
6.3004 mm; max vertex-height error 3.5148 mm. Its ART status remains REJECTED,
not passed: source edge UVs collapse/repeat. The complete receipt is preserved
in ground-full-base-REJECTED.json. Actual game graphics NOT RUN.

A static source audit found 185 nonzero-area faces with near-zero UV area and
659 faces sharing quantized UV footprints. The central local-Y [-8,8] region
has no corresponding density/anisotropy outliers. The original render-object
UV array is identical, so selecting it would not cure the problem.

`--safe-core` now bisects a copied mesh at local Y=-8,+8, interpolating existing
per-corner UVs at the actual new edges. It does not merely remove boundary
faces by centroid. The original complete source file is unchanged. This
explicit derivative maps to x29.6..46.6,z-12..12, not the previous 48m width;
outer forest terrain still needs authoring. Combined with `--road-wear`, the
protected lane uses the original Dirt shader with soft original-Moss shoulders.
This follow-up bake is RUNNING, not yet a successful exported/game result.
