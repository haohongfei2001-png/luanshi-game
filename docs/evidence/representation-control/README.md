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
