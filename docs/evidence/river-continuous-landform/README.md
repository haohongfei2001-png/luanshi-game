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

Additional shared-height regression: `LUANSHI_AUTHORED_LANDFORM=1 godot --headless --path . --script tests/field_bridgehead.gd` exited 0. Original 512-per-side scenario at tick 400 reported 299 crossings, hits [514,558], deaths [135,139], pass=true. These are actual normal battle rules, not forced losses or fewer soldiers. This is not a graphics/performance sample, and does not prove bank art/collision readability.

## Actual ee5d138 full-scene review: FAIL, new shore work isolated

The actual native QHD frame and an unscaled crop of its 3840×2160 counterpart were inspected from source `ee5d1389944a4e3a3a13487856066e0631f8ca25`, run 43627776697. Support/foot shadows are present but art remains **FAIL**: bare uniformly granular earth, weak road/shoulder hierarchy, smooth cut bank, flat cyan water, old fluorescent fairy foliage/root claws, huge plain architecture and old characters. Size22 is a historical technical view, not the new owner MOBA camera gate. Failed images are internal evidence, not a qualified release.

Next isolated production combines actual bank backing, complete scan ledges, and surveyed water depth, rather than changing earth color/exposure:
- Reuse **the complete already licensed** Rob Tuytel / Poly Haven `coastal_cliff_02` derivative, not a new source claim. Existing SOURCE/NOTICE and original matched UV/albedo stay intact. Two whole uniformly quarter-scale scan units, each about10.2m long, form two shore sections; not normalized stones scattered in water. Source original943,284tri, existing derivative89,999tri; pair179,998tri. This remains a candidate requiring full-scene graphics review.
- `authored_landform_profile.gd` adds real backing soil only in x26..33, abs(z)7.4..19.4. Bridge lane, gate sill, open-field saves and nav-blocking functions stay unchanged. Profile VERSION and packed-scene metadata guard against mixing new native shelves with the wrong support profile.
- Native shelf placement tests rejected early floating/unbacked placements and several reachable visual-only edges. Final tested anchors (27.4,-1.65,+/-13.7), uniformscale.25, Yrotation−90°. All102,956 vertices and179,998 face centroids were sampled: zero reachable exposed vertices/centroids;5,954 vertices lie in backing soil. Complete scan meshes generate their own matching static collision. This is sampled support consistency, not mathematical proof for every point or art acceptance.
- Water stays at physical level−1.48m. Vertex color encodes actual bed depth, with a full measured range0..2.32m; shader provides depth absorption and small metre-scale normal slopes. No vertex displacement, SSR, foam, screen blur or fluid-simulation claim. TIME must be frozen/recorded by matched-capture tooling. This layer needs actual graphics verification and is not a claimed visual pass.

```sh
# Rebuild BOTH with the same updated profile, never reuse an old ground scene.
LUANSHI_AUTHORED_LANDFORM=1 godot --headless --path . --script tools/art/continuous_landform/build_region.gd -- /tmp/new-ground.scn /tmp/earth-source
LUANSHI_AUTHORED_LANDFORM=1 godot --headless --path . --script tools/art/continuous_landform/build_native_shore.gd -- /tmp/new-shore.scn
# Instantiate both at identity. New shore is additional to new terrain,
# not an additional flat support plane or replacement for bridge geometry.
LUANSHI_AUTHORED_LANDFORM=1 godot --headless --path . --script tests/art_reset/surveyed_water_depth.gd -- /tmp/new-ground.scn
```

New terrain still86,016tri/42matching collision tiles, water13,980tri. Water test41,940 vertices,3,549 shallow vertices, encoded-depth maximum quantization error.015685m, no water-level shift. Updated default-OFF/open-field/nav-domain test7,735samples passes,291 changed support samples confined to explicit approach+backing domains. Existing route interpolation error remains.01694m. Graphics/render cost and whole scene quality remain NOT_RUN for this new bank/water variant.

### Lower-view geometry revision and real low-grass source

Actual `camera-9c214ca` perspective road65 view was inspected. It makes the old3m grove platforms look like oversized bare mounds. The new isolated geometry therefore lowers the northern/southern approach terraces to1.45/1.15m while retaining bridge/gate support and the native shelf backing. This is a support-mesh change, not an exposure/color adjustment. All packed terrain/shore/vegetation must be regenerated together under the same versioned Ground flag.

One complete five-blade `GEO-leaf.grass.007` source tuft from Sprite Fright plants.blend was isolated with original mesh/UV/material/modifiers intact, removing only the library inventory translation. SourceSHA256 `3ade1b32e300a35a5d0f9aa0599d21b5f5dfe7b711dab88cbe3f706017bd3320`, CC BY4.0 via the existing package. The empty `EN-grass.short` and broken legacy grass-generator GN are not used or described as acquired ground cover.

Original-material and derived offline tuft previews were inspected. The91-triangle/512PBR derivative is visibly more faceted and lighter than the native source; source random material variation/two-sided transmission are not exactly reproduced. It is an explicit tiny-grass rendering candidate, not faithful film-material or artistic acceptance. It must be judged at actual game pixels. Fixed runtime GLB SHA256 `7ad7169680865f2bfbf921327a5256751cc42f283b487d8963d8bc4fd81e4fae`.

```sh
blender -b --factory-startup --disable-autoexec --python-exit-code 1 -t 2 --python tools/art/sprite_source/author_low_grass_source.py -- "$SPRITE_ROOT" /tmp/low-grass
blender -b --factory-startup --disable-autoexec --python-exit-code 1 -t 2 --python tools/art/sprite_source/bake_reusable_collection.py -- /tmp/low-grass/low-grass-source.blend FIELD-five-blade-low-grass /tmp/low-grass/realtime tools/art/sprite_source/low_grass_lod_study.json
LUANSHI_AUTHORED_LANDFORM=1 godot --headless --path . --script tools/art/continuous_landform/build_grass_shoulders.gd -- /tmp/low-grass/realtime/derived.glb /tmp/road-shoulders.scn
LUANSHI_AUTHORED_LANDFORM=1 godot --headless --path . --script tests/art_reset/grass_shoulder_support.gd -- /tmp/road-shoulders.scn
```

Eight explicit connected road-shoulder/shore-back density fields, not arbitrary whole-map scatter, generate591 clumps/53,781 nominal triangles in one MultiMesh resource. Grass remains outside abs(z)4.25m, outside blocked/wet/steep ground, with native roots and tilt attached to the shared survey. Explicit metric scale gives maximumheight.173m; author BU was not silently assumed to equal metres. Game draw calls and final full-scene readability NOT_MEASURED/NOT_RUN. Actual authored distribution belongs to this project, not the original film. This does not complete the missing mature forest, bridge abutment and city-wall material work.

Final lower-terrace build generates598 grass clumps/54,418 triangles (the prior591 result was the taller support revision). A real persistence bug was caught: setting MultiMesh transforms in the dummy headless server and saving the resource produced identity/zero placement on reload. The failed root/net-lane test is retained locally. Grass now explicitly serializes authored Transform3D values plus the mesh on CPU and reconstructs the MultiMesh in `_ready`; it does not trust dummy GPU-state serialization. Three packed-scene reloads now verify all598 roots/tilts, protected lane and mip textures. `tests/art_reset/grass_gpu_layout.gd` separately verifies actual RenderingServer placement on a real display and exits77/NOT_RUN under headless. That GPU test has not yet run locally. No fake graphics PASS is inferred from CPU metadata.


### Continuous basin closure for the new perspective view

The real road65 frame exposed missing land beyond x64. The new single survey extends to x[-144,160], z[-112,112], at the same .5m sampling: 266 nonoverlapping tiles and matching collision shapes, 544,768 terrain triangles and 29,532 contour-water triangles. This replaces the earlier 42-tile terrain; it is not a second overlapping background plane, fog wall or camera crop. Rear forest composition remains incomplete and this extension alone is not an art pass.

Actual full-basin build: exit0,16.175s,307,496KiB Linux peak RSS, **offline builder only, not game performance**. Full mesh test passed266 tiles/shapes, route interpolation maximum.0169378m and water contour error.00756647m. Water depth test passed88,596 vertices with6,862 shallow vertices, maximum encoded-depth quantization error.01568475m. Exact vertex/collision height is shared; interpolated triangle interior is not falsely described as analytically identical at every point. Latest original512-per-side tick400 battle passed299 crossings, hits[512,559], deaths[135,138]. No battle results were forced. Real graphics, new water shader compilation, actual grass RenderingServer poses, total draw calls/performance and art quality remain NOT_RUN for this new full closure.

The first full-basin timing attempt never invoked Godot because /usr/bin/time was absent; its exit127 and subsequent missing-scene test log are retained locally. A Python subprocess/resource wrapper performed the successful build above. No failed execution is counted as evidence.

### Expanded support diagnostic, after frozen 018372b

An additional exhaustive face-centre sample within actual Ground.LIMIT (±118,±64), excluding blocked cells and elevated bridge/parapet decks, found220,144 accessible terrain samples. Maximum analytic support versus triangle interpolation error is **.108443m** at(-23.333334,8.166667), on the original main-river bank. The earlier .016938m finding applies only to the central bridge-to-gate road, not the entire playable region. This is a real remaining support-fidelity defect; the scene is not a full feet-contact pass. Outside gameplay bounds the broad background maximum was.295925m; do not describe those outside-bound samples as reachable. The test now records both the protected-route threshold and expanded diagnostic. Next production step is crack-free error-driven surface sampling, not changing battle rules or hiding floating feet. Frozen018372b remains unchanged for reproducible actual graphics review.

### Edge-conforming adaptive sampling, separate from frozen018372b

`adaptive_surface.gd` subdivides only .5m cells whose sampled geometric error exceeds .008m, up to8 subdivisions per side (.0625m). It tests original triangle centroids and edge midpoints. Neighbor cells agree on the maximum edge subdivision; transition subcells triangulate a shared boundary ring around their actual support-height centre. This makes tile boundaries and internal transitions conforming without changing Ground.height/travel, navigation, saves, anchors or the material UV system. Background-only cells retain the original grid. The builder may cache neighboring cells just outside output bounds; its resolution histogram includes these queries, not only emitted cells.

Actual output is771,266 terrain triangles (+41.58% from544,768, not global4×/16× refinement),266 matching collision tiles and105,079 contour-water triangles. The water increase is disclosed, not hidden in a terrain-only budget. All mesh interior edges have two incident faces; every tile boundary segment pairs exactly with its neighbor, except2,112 outside perimeter segments. This tests topology rather than merely equal AABBs.

Expanded playable-domain face-centre audit:357,829 samples, maximum error.0097508m (previous.108443m); protected central route.00728087m (previous.0169378m). The midpoint/centroid target is a sample target, **not a mathematical continuous-surface error bound**; transition fans can modestly exceed.008m. The expanded mesh test explicitly gates sampled reachable error below.012m.

Actual headless PhysicsServer ray queries against the packed triangle colliders followed existing Ground.travel on three routes (including the failed old river-bank location):360 travel steps,25.9301m, maximum support/collider gap.00702159m. This is actual collision geometry and existing movement rules, not a second mock height calculation. It is **not animated graphical gameplay or final feet-animation acceptance**. Original frozen018372b remains available for independent art review; new adaptive scene is a separate derivative.

```sh
# Same build command now selects error-driven, edge-conforming production sampling.
LUANSHI_AUTHORED_LANDFORM=1 godot --headless --path . --script tools/art/continuous_landform/build_region.gd -- /tmp/adaptive-ground.scn /tmp/earth-source
LUANSHI_AUTHORED_LANDFORM=1 godot --headless --path . --script tests/art_reset/continuous_landform_mesh.gd -- /tmp/adaptive-ground.scn
LUANSHI_AUTHORED_LANDFORM=1 godot --headless --path . --script tests/art_reset/adaptive_surface_seams.gd -- /tmp/adaptive-ground.scn
LUANSHI_AUTHORED_LANDFORM=1 godot --headless --path . --script tests/art_reset/adaptive_surface_walk_collision.gd -- /tmp/adaptive-ground.scn
```

Final regressions: original512-per-side400-tick bridgehead simulation again returned299 crossings, hits[512,559], deaths[135,138], pass=true. Three PBR packed-scene roundtrips checked1,212,123 normal/tangent pairs, maxdot.000141017. Default-OFF/open-field/nav compatibility passed7,735 samples. Its first invocation incorrectly inherited the opt-in environment and correctly rejected it; the failed assertion log and corrected `env -u LUANSHI_AUTHORED_LANDFORM` run are both retained. No graphical performance or MacBook Air M5 test is claimed.

### Frozen real-camera coverage preparation (not an art rewrite)

`audit_camera_coverage.gd` replays the exact projection matrix and basis/origin from real9c214ca QHD/UHD receipts against actual terrain PhysicsServer colliders. At33×19 normalized screen rays, the old112×96m extent yields562/627 terrain hits for road65 and561/627 for road75; the new304×224m basin yields622/627 and627/627. In the top three rows old coverage is37/99 and33/99, versus new94/99 and99/99. The five missing new road65 rays are on the top-right screen edge; sky can be legitimate. This is **terrain-only geometric coverage**, not a rendered image or proof of attractive background, tree/wall/water occlusion or final camera choice. The old-extent scene here uses the same lowered support profile, so this diagnoses extent, not an exact recreation of old9c214ca pixels. Original capture receipt and both terrain hashes/results are preserved in `camera-coverage/`.

```sh
LUANSHI_AUTHORED_LANDFORM=1 godot --headless --path . --script tools/art/continuous_landform/audit_camera_coverage.gd -- /tmp/adaptive-ground.scn docs/evidence/river-continuous-landform/camera-coverage/source-9c214ca-receipt.json /tmp/coverage.json
```

Material audit before the next real image: with `earth_enabled`, the current land shader replaces the preceding road/bank/drain colour calculation with source PBR albedo, retaining only a restrained woodland tint. Accordingly the current road/drain readability is predominantly actual geometry, **not a completed distinct worn-road/wet-bank material family**. No blind recolouring or exposure change was made while the frozen full-scene capture runs. The water shader has TIME; matched capture must freeze/report it while realtime traversal must restore real TIME. The new mature forest, material hierarchy and full architecture relationship remain unaccepted.

Next live traversal must use the current integration's normal-input controller, preserve actual battle/death and frame timestamps, and name river-bank support diagnosis separately from full combat acceptance. The implemented PhysicsServer route test uses starts/deltas (-23.3,8.16)+(3,2), (30,0)+(16,0), (34,8)+(6,2),120 Ground.travel increments each. These are collision diagnoses, not permission to teleport the hero during live footage. A graphical follow-input run must approach the points naturally or explicitly disclose a separate initial fixture; no concealed position overwrite.

## Road-section03 after actual67700146 rejection

Personally inspected the real native QHD road65 frame and the owner's exec3beb reference again. The full basin closes the empty background, but art remains **FAIL**: uniformly bare dune-like earth, two isolated vertical scan slices, weak military-road/shoulder relation, a flat green water impression and sparse narrow crowns. The598 GPU grass instances were verified by the capture producer, but that does not make them a natural material system. No failed frame is relabeled accepted.

New independent shared profile `continuous-military-road-and-eroded-moat-03` replaces the isolated scan-support shelves and round approach hummocks with one full causeway/shoulder/drainage/bank cross-section. Domain x0..46.6,abs(z)<38, smoothly bounded: slight road crown and actual wheel wear, depressed road drainage, low elongated shoulders, continuous upper moat bench, erosion slope and submerged toe around the moat. Original bridge ground footprint and gate foundation are retained; Ground still subtracts moat depth exactly once. No new nav/collision exceptions or save schema. The two scan shelves are retired for this profile, not deleted from history; **do not attach NativeShoreShelf to03**. Its builder explicitly rejects03. The same version guard requires all terrain/vegetation to be rebuilt, not mixed with frozen02 scenes.

The material system now actually uses road, drainage, water-height and low-cover vertex channels instead of overwriting them with one dirt map. Original2m dirt source remains the packed route; explicitly reused, previously licensed CC0 Poly Haven `leafy_grass` (Charlotte Baglioni,2m) and `brown_mud_dry` (Rob Tuytel,1.3m) provide native albedo+OpenGL normals for cover and sediment. Original maps were inspected, exact hashes frozen in road_material_sources.json, and original SOURCE/NOTICE retained. This does **not** restore the old scene, shader or layout or claim new acquisitions. Blended normals retain native metric widths; roughness response is explicitly authored, not a claimed source roughness map. No texture recolouring/blur/sharpening, added random blotches or extra scattered grass/rock instances. These textures can still be too busy at actual pixels; source legality and headless channel checks are not visual acceptance. Mature trees, stone strata, water detail and architecture remain unresolved.

Actual03 output:855,202 terrain triangles,145,622 water triangles,266 matching collision tiles. Playable support sample maximum.00973708m; central route.00743916m; all mesh and tile edges paired without hanging segments. Actual PhysicsServer movement test360 steps/25.9301m max collider gap.00466394m. Native2048 seven-map mip loading and four region channels passed. Default-OFF/open-field/nav compatibility7,735 samples passed,775 changed support samples in the explicit new domain. Original512-per-side tick400 battle passed with293 crossings,hits[494,559],deaths[135,134]. These counts differ from02 because actual changed terrain feeds existing pace/support behavior; this is not a same-state visual A/B claim and no results were forced. Logs are in road-section03/.

The first03 builder used a res:// raw image load and emitted an export warning, although its packed image build succeeded. The offline loader now globalizes its source path and packs ImageTextures; a final independent seven-map load test exits0 without that warning. Source JPEGs are not read at gameplay runtime. Shader compilation on a real graphics backend, actual03 normal-input footage/performance and art acceptance remain **NOT_RUN**. Restore/build with the same commands as98ef, but omit the retired native-shore scene and regenerate vegetation against03; profile/version and asset hashes must be present in capture receipts.
