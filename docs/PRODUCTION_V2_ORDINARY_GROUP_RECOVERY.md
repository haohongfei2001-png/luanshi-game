# Opt-in real ordinary spear presentation

This is an interface milestone, not art acceptance. Mother source is not frozen;
terrain004 remains a CPU functional fixture and must not be presented as new art.
Default production/menu map and all existing actors remain unchanged.

## Exact scope

`production_v2_entry.gd` accepts optional `ordinary_spearmen_per_team` (integer 0..3,
default 0). It selects actual living foot SPEAR units, excluding hero, officers,
and mounted units. Each owns a Skeleton and binding; mesh/material resources are
shared. Only IDs whose first binding succeeds are hidden in the diagnostic old
renderer. Other kits remain explicitly labelled old diagnostics. No Battle HP,
position, damage, roster, or simulation edits occur in presentation.

Actor source: `dot/mh-spear-production-v2` binding `951316f9c786ae3ba70e8bd1e0241ed947c586dd`
(document successor `cf6dbed9abc3e5f9c61f7ef038e15522527dabf3`).
Source18 GLB SHA256 `afb966396bf5ad656b3cb0cd2edc388fc6fa02eba59df8b81d9a23ac53f3be8b`;
timing SHA256 `ae7094c96039fea428a310330e25a1fe501aca18f6a6461f6abdc2f843f5c2ab`.
163 bones, 14 clips, 35 surfaces. WIP ART_FAIL, not thousand-unit architecture.
Source15 and missing-tangent18 export remain rejected; do not substitute them.

## Verified CPU evidence

Actual Controller runs source004/seed61112/20 ordinary per side. IDs 1,2,4 and
21,22,24 use the new source18 shared model. Natural army combat ends at tick460
with the actual result `守军溃退`; IDs 1,4,21,24 naturally die and complete Death01
at 2.4 seconds / phase1. IDs2/22 survive injured. All six have actual walk and
stagger records; five have ordinary thrust records. Unsupported retreat/strafe
stays explicitly UNSUPPORTED, not falsely relabelled. Full Save snapshots before
and after presentation, including every death-tail frame, are unchanged.

First army run exposed stale interpolation after simulation stopped: one corpse
was ~0.1425m behind actual final position. Preserved first evidence is NOT final
position proof. Controller now resolves interpolation alpha=1 when paused or
battle has ended; final repeated run asserts all six final transforms equal
actual map support to 1e-5m. This verifies transforms, not visible foot contact.

The earlier contact-group test used real input and ended in hero death at tick279,
with 2 actual hero hits and 4 received. It did not contain ordinary deaths.
Army fixture deliberately keeps hero idle and manually steps the actual Controller;
it is NOT a normal-speed film, GPU result, FPS test, or proof of art quality.

Evidence summary: `docs/evidence/production-v2/ordinary18-cpu-summary.json`.
Full raw logs/JSON are retained in shared workspace as
`map-v2-controller-{group18-first,army18,army18-final}.{json,log}`.

## Reproduce

Use official Godot4.6.3 `--headless --path . --script
 tests/map_runtime/controller_skeleton_fixture.gd -- SOURCE004_JSON LAYOUT_JSON
 VERIFIED_SOURCE18_GLB TIMING18_JSON OUTPUT_JSON army-group`.
`contact-group` instead exercises the real input-only pilot. Invalid group/duplicate
IDs are rejected before changes; actor meshes share resources and skeletons differ.
The fixture uses a deliberately empty author-identity scene, never a visual substitute.

Before GPU, require final mother scene/topology closure, standard exported resource
closure (including external imported textures/UID table), actual native resolution,
and whole-scene review. M5 and new whole scene GPU are NOT_TESTED.
