# Bounded representation control, NOT accepted game art

Latest owner authority remains main's
`docs/OWNER_MOBA_CAMERA_AND_ART_AUTHORITY_20261114.md`: Wild Rift-like screen
scale is the direction; size22 is only a historical baseline, not a physical
22m distance or an instruction to cram1024 units onto one screen. Clean means
clear structure and natural matte surface, not shiny plastic or smeared oilpaint.
Ordinary spears have no red tassel. The approved AI directions are not game
screenshots; no formal protagonist/plot is fixed by this experiment.

## Scope and fairness

The immediate control uses intact licensed UBC+UAL, shared mesh/65-bone full
weights/original textures and five original clips. It is **unclothed** and has
no held weapon, armor or horse. It cannot answer the owner's armor/hand-grip
quality requirement or select the final artistic representation. Guardian motion
work and the character-art thread remain separate, without blocking this control.

Modes: shared3D,8-direction sprites,16-direction sprites, and a hybrid with
hero/officers3D. The same source rig poses produce every frame. Sprites are
rendered by actual Godot, then8-direction data is an exact subset of16.
Ordinary units share one asset; per-person duplicate meshes/atlases are not used.
The initial shared3D mesh retains the imported LODs, but a large batch AABB may
prevent useful automatic LOD selection. This first control is NOT an optimized
3D opponent or final route comparison; screen-error-verified explicit LOD is
required before declaring an optimum or winner.

Atlas full-pose/all-angle bounds come from complete original weights and the
same bind matrices, not cropping. Tiles sample256pixels per world meter and
have explicit margins. Large death/attack bounds are paged, never cropped to
fit a texture. Actual alpha bounds are recorded from renderer images. Format,
mips, texture arrays and byte sizes are measured after offline compression.
CPU bounds are conservative; tighter packing is a future optimization, not a
claim that this first page layout is minimal possible sprite memory.

Lighting uses the same sun/ambient values as the field. The transparent bake
uses LINEAR tonemap to avoid applying scene FILMIC twice. It remains an LDR
bake: clipped HDR response, missing normal/depth atlas, directional quantization,
alpha scissor/mipmap bleed, silhouette shrinkage and flat alpha-plane shadows
need actual-image review and must not be called equivalent source material.
No blur/sharpening is applied to disguise those failures.

Pure sprite runs now load only atlas metadata and textures, not the original3D
mesh/palette/influence textures. Hybrid intentionally pays for both. Godot
allocation counters are not driver-resident VRAM; Linux RSS/HWM and engine
static-memory values are reported separately. Software rendering is not M5.

## Combat and measurement contract

Real Battle20/100/250/512 per side remains authoritative, with attacks, defense,
casualties, RNG and offscreen advance. Each run compares its final snapshot to
an independent simulation-only oracle; mode comparisons require equal state,
hits and casualties. Presentation does not force outcomes or turn troops into
decorative actors. Mounted/class visuals remain explicitly unsupported in the
UBC control, although their real combat continues.

Capture runs and screenshot-free performance runs are separate. Capture matrix:
2K/4K × size22/16 × four modes,100 per side at tick300. Size16 is an experimental
larger screen-scale candidate, NOT a sourced Riot camera specification. It keeps
the same elevation as size22 so the atlas comparison uses the same viewpoint.
Performance:2K,size16 × four modes × four army sizes,ticks300→500, no screenshot
readbacks. Per-mode view/input, seed, resolution, camera, shader clock and actual
internal scale are recorded. The exact unique experiment matrix is validated,
not merely the total file count. Environment shader TIME is replaced only in
this isolated runtime by the actual Battle tick clock; default files stay intact.

## Failure history

Run43624868764 reached actual Godot atlas drawing, then failed S3TC packing:
retained template_debug engine35e80 has no editor-only BC compressor
(`_image_compress_bc_func` null). Artifact14125009130 preserves the logs.
No full combat performance runs occurred and no sprite quality win is claimed.
Recovery separates patched-engine real rendering from official7d41 editor
headless offline compression. The latter's Image.compress and Texture2DArray
save were locally verified with an actual small fixture; that is not yet the
full atlas/combat result. Engine revision distinction is retained, no rebuild.

No default scene, main branch, RC24/Mac candidate or art acceptance changed.
All generated failures remain internal; they are not unsolicited owner-facing
"finished" screenshots or candidate releases.

## Local validator failure injection

`python tools/representation_compare/test_matrix_validator.py` checks a synthetic
complete matrix is accepted, then independently removes one result, duplicates
one result, changes a simulation hash, and substitutes a wrong native resolution.
All four malformed matrices must fail. These are validator unit tests, NOT
actual graphics/performance evidence. No art/FPS threshold is inferred.

Riot's official [Clarity in League](https://www.leagueoflegends.com/en-us/news/dev/clarity-in-league/)
explains silhouette recognition, readable facing, visual importance hierarchy,
and avoiding noise. Those are useful review criteria, not a source for our
candidate camera numeric parameters. The owner's newer matte, restrained,
slightly rough material direction does not mean glossy plastic or blurred detail.

## Explicit same-source LOD preparation (not yet rendered)

The importer provides 18 original LOD index buffers. A version-scoped helper
selects those indices without deleting vertices, truncating weights, editing
materials or re-encoding packed UV/normal/tangent attributes. Actual headless
checks of tiers 0/1/2/3 passed 168 invariants, including byte-equal decoded
non-index arrays and identical material resources. Total triangles are
14318 / 7158 / 3578 / 1818 respectively. This does not establish screen-space
quality or vertex-shader speed: unchanged vertex buffers and weight tables
remain allocated. The first arrays-to-mesh implementation was rejected because
normal re-encoding was not byte identical; direct 4.6.3 packed surface
serialization preserves the source instead. No LOD is enabled by this evidence.

## Action mapping / coverage limits

The first control updates rendered positions and walk phase at Battle ticks,
without fractional-tick interpolation. WINDUP and RECOVER each map their local
phase onto the full Sword_Attack clip, so they can visually repeat a swing.
This is equal between representation modes, NOT accepted natural locomotion,
contact-synchronized attacks, two-handed spear use, or a complete art animation.
Later production mapping must align one attack timeline, contact and recovery,
plus ground-relative foot speed and frame-to-frame turning.

A separate local 7d41 simulation-only oracle reaches tick500 with the actual
seed61112 and gives hits/losses:20 per side [36,0]/[0,9];100 [245,151]/[30,62];
250 [305,541]/[132,82];512 [631,648]/[159,163]. Thus the20 troop window does NOT
cover enemy hits. These are not graphics tests and are not presumed to equal
another engine revision; the GPU run checks its own independent same-run oracle.

## First full graphics run43625844890: FAILED, retained evidence

Source4fc9708 completed actual atlas rendering/compression and16 native captures,
then produced only20-per-side timing reports before100/shared3D exceeded its
180-second case timeout. Every sprite/hybrid case logged `img.is_null()` loading
Texture2DArray and showed missing-texture magenta rectangles. Their images and
performance are INVALID, not evidence that sprite drawing is faster. The
headless offline editor had saved GPU-backed Texture2DArray through a dummy
renderer; its serialized Image layers were null. Recovery writes compressed
Image CPU bytes plus hashes and constructs arrays in the actual renderer.

Artifact14127007730 (133775177B) SHA256
`d9a76e4e54a8f2514d9d2d3ae9ee4fdc847409485739fe4cba5446d848116955`.
Exact source PNG artifact14126743401 (136197843B), SHA256
`1e817b66e1c649db59b875f14655f8638b51f6a2f4c2313dc1d8c9462a45ab3e`.
The recovery smoke reuses these original PNGs rather than rerendering them.
Actual compressed payload8-way488753152B /16-way918280448B is retained honestly.
This conservative layout is not a final memory-optimal sprite representation.

The valid20/shared3D short control had76 frames in128.950341wall seconds,
0.589374FPS,P95=1769.115ms,P99=1774.662ms on llvmpipe. It is not a meaningful
stable-tail/device result or evidence against3D onM5. Engine-clamped delta means
10simulation seconds took129wall seconds; later real-time measurement must
explicitly handle and disclose this, not silently call it10wall seconds.
Native100+/four-size performance remains incomplete. No route winner exists.

True alpha bounds at the fixed pitch show UBC Idle size16 is only112–135px body
height at2K. Size12 predicts149–180px (10.35–12.5%screen height), so the bounded
recovery smoke uses size12, not an invented official Wild Rift size.
