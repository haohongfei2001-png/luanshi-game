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
