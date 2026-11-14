# Native representation matrix preparation, not a new graphics result

`RepresentationBattleControl` is now a normal SceneTree MainLoop entry, rather
than relying on --script which the protected Mac release template clears. Use
`entry_config.project_config` on an isolated review copy and restore original
project/export configuration in finally. Inert bootstrap entry.tscn is included.
No default project or workflow has changed, no new CI has been requested.

`COMPARE_VALIDATE_PACK=1` verifies original opaque source hash (when exporting,
retain exact original GLB as assets/ubc_lab/ubc-source.glb.bin) plus imported
skeleton presence. This is ONLY source closure, not the complete battlefield,
atlas payload, runtime derivatives or actual Metal graphics. Source identity is
explicitly distinct from importer-derived resource identity. The existing native
export/empty-directory protocol must also cover all environment/atlas dependencies.
`COMPARE_REQUIRE_METAL=1` rejects any silent non-Mobile/non-Metal runtime.

Release-stripped assertions were replaced with explicit nonzero errors for atlas
identity/bytes/array shape, simulation snapshot parity and final independent
Battle oracle. Shared-source material/palette/LOD preparation returns Error.
A recorded failure cannot later be overwritten by successful finish. Existing
external clean-log and exact-matrix gates remain mandatory, not optional.

Actual local checks: normal MainLoop entry reached SOURCE_CLOSURE_PASS with
exit0, original project.godot restored byte-for-byte;168 explicit LOD invariants,
6 log fault fixtures,5 matrix fixtures,2 entry config fixtures passed. First
editor import used unwritable default config directory; that log is preserved,
then rerun with writable XDG_CONFIG_HOME. These are not actual Metal images or
performance data. Existing 3D/sprite/hybrid comparison remains incomplete.

Next bounded native run should reuse the already successful Metal engine and
shared original UBC atlas, not rebuild engines or rebake all sprites. First verify
one same-scale matched capture per representation and compressed-array support,
then the four real Battle scales without screenshot readback. Explicit LOD must
first meet same-screen error limits; giant batch AABB is not reliable automatic
LOD. The capture matrix's prior16/22camera values are historical technical
controls; record actual adult body height and align camera pitch with atlas bake.
No claim of exact destination26 correspondence with the old fixed-pitch atlas.

Remaining artistic/control limitations: UBC is an unclothed technical control,
not Chinese infantry; no weapons/armor/mounts. Material inputs must match across
all representations. The current Chinese43mesh oracle has incomplete material
channels and is not the quality ceiling of the editable mother. The existing
comparison attack mapping repeats a full sword clip in WINDUP/RECOVER and is
not accepted contact timing. Flat-plane sprite depth/shadow, quantization,
compression/mipmap/scissor boundaries and LDR material response need actual
review. Cropped8-way/16-way atlases are large shared resources, not per-soldier
copies or an automatic win. No final route selection, art/M5/army performance
acceptance or source/default/RC promotion follows from these changes.

## Authorized bounded hosted-Mac smoke

`representation-metal-smoke.yml` uses only existing pinned source atlas14126743401,
source bundle14129705496 and already built Metal template14108148499. No new render
bake or engine build. Lossless crop plus8way-only offline compression retains source
pixels and original root anchors;15 external compressed pages308134592B are checked
against hashes. Exact old CC0 license files and NOTICE are preserved with evidence.
Normal MainLoop PCK is tested from an empty cwd, loading the complete environment,
source mesh/palette/explicitLOD1 and all atlas page bytes before real graphics.

Only20-per-side, same seed61112, camera12 at original atlas pitch, source/material,
and real Battle is compared: shared3D explicitLOD1 (7158tri) versus8way sprites.
Two2K actual captures tick300, then separate no-readback windows tick300→620. Local
simulation verified the20-per-side fight ends at675, so the planned measured window
remains real battle rather than padding idle post-result frames. All modes must match
an independent simulation oracle and each other's start/end state and camera.
Existing minimum120 intervals/10seconds is retained from native reliability19e6422;
raw intervals independently produce mean/P50/P95/P99, with finite-positive checks.
P99 remains descriptive, not stable-tail/device qualification. Per-case RSS is from
macOS time-l, Godot counters explicitly do not establish actual driver residency.

Each case is bounded180seconds, workflow25minutes. No automatic escalation to larger
armies, no retry loop, no engine rebuild fallback. Failure artifacts remain; current
Metal/alpha/occlusion/pixel quality is unproven until the actual results are reviewed.
The normal source-scene closure check passed locally with all15 atlas pages; this is
not yet an exported Mac PCK test. First synthetic color-noise test fixture was too flat
for the nonempty-image gate, fixed to deterministic RGB coordinate pattern; gate not
relaxed. Synthetic short-window, changed-state and magenta-image fixtures all fail.
