# Continuous causeway / water / woodland terrain experiment

Status: DEFAULT OFF. Production geometry and integration work, NOT art acceptance.
The owner requires clear, natural, richly structured actual normal-camera gameplay,
not muddy/noisy texture detail, fluorescent leaves, black silhouettes or a small demo.
The latest owner-approved soldier image is a visual direction only, not game proof.

## Actual new structure

A continuous 112×96 m survey scene covers both waterways and the bridge-to-gate
approach: 42 tiles, 86016 ground triangles with matching ConcavePolygon collision,
plus 14124 water triangles clipped to the actual surveyed waterline. There is no
large rectangular water plane. The separate terrain material expresses broad road,
woodland and bank zones without photographic noise. This is not claimed to be a
finished professional material. Same-family rock research found individual rocks,
not a complete authored cliff/shore kit; a catalogue is not an accepted shoreline.

The opt-in support profile gives the approach an actual crowned causeway, shallow
wheel wear, two continuous drainage swales and wooded terraces. It is not an
image overlay. `Ground.height`, actor `deck_height`, the visible survey and its
physical collision derive from the same function. All other navigation rules,
bridge decks, gate foundations, army counts, attack rules and save schema remain.

`LUANSHI_AUTHORED_LANDFORM=1` must be present at process startup. Without it,
existing height queries are exactly the old behaviour. A loaded experimental scene
without that opt-in hides itself, disables its collision and emits an error; it
cannot silently display mismatched ground. This opt-in is NOT written into saves.

## Reproduction

```sh
LUANSHI_AUTHORED_LANDFORM=1 godot --headless --path . \
  --script tools/art/continuous_landform/build_region.gd -- /tmp/continuous.scn
godot --headless --path . --script tests/art_reset/continuous_landform_contract.gd
LUANSHI_AUTHORED_LANDFORM=1 godot --headless --path . \
  --script tests/art_reset/continuous_landform_mesh.gd -- /tmp/continuous.scn
godot --headless --path . --script tests/art_reset/surface_front_face.gd
```

Verified: 7735 support/navigation samples, 279 genuinely changed approach points,
maximum height change 3.05 m. Default behaviour, every sampled old open-field
height and blocked-route answer are exact. Bridge decks and gate foundation
anchors unchanged. New mesh check: 42 matching collision shapes, water contour
error ≤7.57 mm, route triangle interpolation error ≤16.94 mm at 0.5 m survey pitch.
These are sampled checks, not an exhaustive geometric proof or a game/art PASS.

## Real-game failures and necessary renderer corrections

Actual game source babdc0a5, run43622592649, QHD/UHD 22 m same-state imagery failed:
visible dangling tree roots, separated shadows and bright fragmented foliage.
No quality claim is carried over from the professional source package.

A real error was found in the support mesh: its triangle cross products pointed
+Y, while the engine's upward-facing PlaneMesh uses clockwise fronts with cross
products -Y. The old support faces were back-facing. `surface_front_face.gd`
compares against the actual engine PlaneMesh and checks 6144 generated faces.
The shared generator is corrected. The capture-specific support rectangle must
use the same corrected indices. Re-rendering is still required to prove the
visible symptom is resolved; do not lower trees to hide an invisible terrain.
The tree's actual transformed vertices extend to y=-1.670 m, unlike its loose
transformed AABB estimate -2.366 m. Author origin is preserved, not min-AABB lifted.

A second actual import gap: all three 2048 PBR textures created by GLTFDocument
had no mip levels although their sampler requested mip filtering. The woodland
assembler now creates shared mip chains once per family, renormalizing normals,
and uses anisotropic mip filtering. The packed scene opens/frees three times,
retaining ten instances / two shared meshes and mip levels on all PBR images.
This is proper sampling, not deliberate blur to obscure missing geometry.
Its visual result is still NOT RUN and bright leaf colour may need more work.

## Safe-core receipt compatibility

The original long-running safe-core bake began before `derived_triangles` was
added to the report schema. Its frozen receipt has 3849 vertices / 3724 polygons
and the explicit local-Y [-8,8] crop. The intake accepts only this exact legacy
shape as 7448 triangles, or a new report with explicit derived_triangles. It does
not guess for arbitrary reports. JSON numeric array comparison failed in an
initial compatibility attempt; explicit numeric element checks now pass against
the actual original receipt. Original failure and data are not relabelled.

## Remaining gates

Native same-camera actual Godot comparison of the corrected whole region;
normal-input movement/attack/defence/hit/riding and offscreen battle proof;
separate no-readback performance with required troop counts; source/world-state
metadata and source-rebuild checks. M5 hardware NOT RUN. Owner art approval remains
required. The safe-core patch is not the whole terrain and the new continuous
survey is not a finished game merely because tests pass.

## Latest owner camera/quality rule supersedes the old 22 m art constraint

Wild Rift is the primary camera/screen-scale reference; League of Legends and
Honor of Kings are supporting references. Human-sized characters must have a
natural, readable screen presence. The old 22 m views remain historical technical
comparisons only, NOT the required new art framing. Do not shrink people or widen
the camera merely to put every soldier on screen. Total 512 per side and genuine
offscreen simulation remain; visible population follows the actual viewport.
New landforms must compose readable playable spaces at the new MOBA-style scale,
not squeeze the entire bridge/gate/army into one screenshot. The approved concept
image is direction, not proof that any current game asset has passed.

Failed images remain internal evidence. They must not be proactively delivered
to the owner as candidate-quality results. No rejected art may be marked passed
or released as a qualified version. All work here remains an isolated OFF
experiment until real game evidence meets the owner's visual acceptance.

Campaign save regression ran both with default OFF and with explicit opt-in:
1467 assertions, zero failures in each process. This does not substitute for
battle/action/art/performance acceptance.

## Independent water-contour intake for current game support

`tools/art/continuous_landform/water_contours.gd` also exposes a pure
`mesh(origin, extent, step)` helper. It reads the currently active Ground survey
without enabling the new landform. A capture can replace its rectangular water
plane with this true contour mesh without changing battle state or support
heights. The default-OFF helper removes two sub-square-millimetre slivers from the
unfiltered 14124 triangles. Its first hardcoded count check failed before this
difference was recorded; the gate now checks 14122 retained triangles and exactly
two discarded slivers. The default-OFF test covers those upward-facing water triangles across
112×96 m and checks waterline/terrain agreement. The full new terrain scene still
requires its explicit opt-in; this helper does not turn it on implicitly.

Owner's latest whole-scene concept feedback is conditional, not an approved oil-
painting style: the clean soldier/white-horse inset presentation takes priority.
Prefer simple clean surfaces over smeared colour, dirt noise or painted-looking
mixed patches. New broad material zones are a structural starting point; they
still need actual normal-pixel game inspection, not approval by source pedigree.

## Same-family rock candidates rejected after actual source renders

The source collections ENV-rock_smooth.medium.02 and .05 were actually opened
and rendered with their original materials, then personally inspected. Both
remain rounded low-profile boulders with mottled microtexture, not a mature
stratified shoreline assembly. They are rejected as the primary bank/cliff
silhouette; no row of these pebbles will be used as a substitute for authored
shore structure. Their previews are internal non-game diagnostics. Source
rocks.blend SHA256 ee7e7194fb547f58797a98fc989c038e4ad9536c73b05d774879b89b891c467d
belongs to the same already licensed Sprite Fright package. No extra asset
purchase/account/source has been introduced. The continuous landform and
waterline production does not wait on a nonexistent complete cliff kit.

## Whole-surface metric earth experiment, not accepted art

The latest owner-approved *direction* is the full scene `exec-3bebef23-c990-4b69-ba78-81924b6cdb61.png`: naturally aged matte earth/wood/stone, legible intermediate-scale form and comfortable human proportions. It is concept art, not Godot evidence. Wild Rift-style human screen scale supersedes the historical 22 m art gate. No glossy brightening, painterly smear or noisy detail-count substitute.

A single optional CC0 Poly Haven `dirt` source by Charlotte Baglioni is now restored by exact SHA256 from official URLs (`tools/art/continuous_landform/earth_source.json`). Official source https://polyhaven.com/a/dirt and license https://polyhaven.com/license permit raw redistribution under CC0. Website preview/text is not republished. The downloaded diffuse was inspected at its actual 2048×2048 resolution: compacted earth with fine granular inclusions, not a moss painting. This is a candidate material, **not a finding that its repetition/noise at normal game pixels passes**.

```sh
python tools/art/continuous_landform/fetch_earth.py /tmp/earth-source
LUANSHI_AUTHORED_LANDFORM=1 godot --headless --path . \
  --script tools/art/continuous_landform/build_region.gd -- /tmp/continuous-earth.scn /tmp/earth-source
LUANSHI_AUTHORED_LANDFORM=1 godot --headless --path . \
  --script tests/art_reset/earth_material.gd -- /tmp/continuous-earth.scn
LUANSHI_AUTHORED_LANDFORM=1 godot --headless --path . \
  --script tests/art_reset/continuous_landform_mesh.gd -- /tmp/continuous-earth.scn
```

The optional second builder argument uses the original diffuse/OpenGL normal/roughness maps at a 2 m repeat, generated 11-level mip chains, anisotropic sampling and a real mesh tangent basis. No source recoloring/blur/sharpening/baked shadows. A small explicitly authored woodland tint remains; roughness has a .82 floor and specular .12. Normal depth .45 is a declared adaptation, not claimed preservation. Material is shared across all 42 tiles. Texture source is restored rather than copying 32.8 MB of raw data into Git.

Verified locally: build 86,016 terrain triangles / 14,124 contour-water triangles; 3 packed-scene instantiate/free cycles, 137,214 normal/tangent pairs, maximum orthogonality error 0.000130677; all three texture images retained native resolution and full mip chains. Physical mesh regression remains unchanged. **Real graphics/shader compilation, normal-pixel repetition/noise review, whole scene integration and runtime cost NOT_RUN for this material.** No whole-terrain art pass, release or M5 claim. Existing failed game captures remain failures.
