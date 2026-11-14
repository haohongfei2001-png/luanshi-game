# River valley landscape06: complete composition study, NOT visually accepted

This work follows personally viewing actual04 Metal destination26 and the owner's
whole-scene reference.04 remains a bare bowl with two isolated trees and a striped
water sheet. A professional asset alone is not a complete landscape. No accepted
art or real game frame is claimed for06 until the unified runtime review.

## One continuous landscape design, not a material patch list

The existing military approach remains a clear centre. Both river margins become
connected low meadow cover with grouped mature canopy edges; the far inner valley
receives a staggered secondary tree line. One authored ecological field drives
both the continuous ground-cover material mask and actual native five-blade grass.
This replaces eight isolated sparse shoulder patches rather than adding noise to
old empty ground. All16 tree origins retain original full body/branch/leaf shape,
UVs and original PBR sets. Shapes are not inflated to pretend larger crowns.

The plan is project-authored, not a recovered film layout. Mature island_tree_01
source is the previously verified11-file CC0 Poly Haven master; grass is the
existing legally recorded Sprite Fright native derivative. There is no new paid
service, account, source download or licence assumption. SourceLOD generation
checks all11 hashes before processing. The complete original mesh is kept as
LOD0; Godot ImporterMesh builds lower index levels retaining the source channels.
Actual screen selection, silhouette quality and GPU cost are NOT_RUN. The 16-tree
base geometry is about25.6M triangles before LOD; do not mistake the generated LOD
counts for measured performance or silently use a high error threshold.

Water06 replaces three dominant fixed wave directions with12 non-collinear
wavelengths, gravity-consistent phase speeds, depth damping and screen-derivative
filtering. No displacement changes the physical water level or crossing. This is
an actual shader replacement, but shader compilation/appearance in the full GPU
scene still requires testing. It is not labelled realistic water from a headless
resource check.

## Real tests and rejected attempts

First18-tree layout was rejected: roots crossed2.14m of slope, a muster position
was inside wood, and routes near the moat/wall did not finish. The entire group
layout was revised to16 placements with original local wood footprints. No unit
was moved, deleted, made invulnerable or hidden to accommodate trees. Existing
battle-save units that may occupy a newly enabled tree remain a separate NOT_RUN
migration case; default-off saves are unchanged.

The final layout passes48 real Ground.waypoint/travel routes,7600 steps,maximum202
steps and all1826 actual muster positions across20/100/250/512-per-side. Tests
exclude goals/starts already blocked by existing walls, water or another tree,
not just water. Blocked destinations are not legitimate tree-bypass routes.
The first synthetic routes inside adjacent trunks or ending at the existing fort
wall were explicitly diagnosed; thresholds were not loosened. The protected
central road stays clear. A real512-per-side400tick simulation gives295 crossings,
484/550 hits and136/133 casualties, passing its existing checks. These outcomes
are actual simulation results, not performance measurements or historical-save
rewrites. The new obstacles legitimately alter the experimental battle trajectory.

7735 support/navigation samples prove default-off and original open field remain
exact. The visible06 terrain keeps all26605 collision tiles byte-identical. Grass
origins are sampled from the same real support function and excluded from blocked
footprints. Full trees are grounded with an explicit8cm root insertion; maximum
height range under the conservative root polygon is0.396m, not2.14m. This geometric
check is not a claim that every visual root contact is perfect; inspect actual
normal-camera pixels before accepting it.

A PackedScene roundtrip exposed duplicated nested scene children/resources in the
first serializer. It was rejected and corrected by explicitly flattening nested
scene paths and sharing one source mesh. The final test requires exactly16 mesh
nodes, one shared tree mesh,3 repeated reloads, accurate grass support and exact
266 original collision meshes. Do not restore the failed serializer.

## Frozen05 remains separate

05@8feab2d, its4 outputs, the current native CI and old game defaults are untouched.
06 is additive source on a separate branch. It uses05 physical support and05 sky,
adds LUANSHI_REGIONAL_LANDSCAPE=1 in addition to the authored/native/sky flags, and
replaces the terrain/woodland/grass runtime resources together. The dedicated scene
guard hides these resources without the corresponding real navigation opt-in.
Do not combine06 woodland with old navigation, or06 grass with old sparse grass.

Build source LOD with tools/art/native_woodland/build_source_lods.gd, then run
 tools/art/river_valley06/build_landscape.gd with arguments:
 tree-source-lods06.scn native-low-grass.glb exact-terrain05.scn output-directory.
Validate with tests/art_reset/regional_landscape06.gd and
 tests/art_reset/native_woodland_navigation.gd under the corresponding flags.
The source receipt and emitted-resource SHA must be checked before integration.

The next gate is actual normal-camera full-scene review alongside the castle,
actors and05 HDR sky, including moving water, grass readability, shadows, tree
LOD transitions, measured memory/FPS and camera occlusion. This study does not
complete rocky shore structure or guarantee that the original island tree is the
right final Chinese river-valley species. Reject or revise based on the whole
scene rather than asking the owner to choose through failed drafts.
