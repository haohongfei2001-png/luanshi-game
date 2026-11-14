# Production-v2: authored map, real existing battle

The entire previous visual foundation was rejected. Regional06 is archived as
SUPERSEDED/ART_FAIL, not the next art candidate. Production-v2 starts from one
complete mother scene determining terrain, road, bridge, fortress and topology.
Do not constrain that scene to old Ground rectangles or declare visual acceptance
from these engineering checks. No official narrative content is added.

## Actual dependency inventory

`MAP_RUNTIME_GROUND_DEPENDENCIES.json` is a source scan with exact file/line sites:
44 distinct Ground symbols in field scripts, not "only19 replacements". The
following19 work categories separate genuine gameplay dependencies from old
visual builders that must not be carried into the new mother scene.

| Category | Existing dependency / boundary |
|---|---|
|1 Terrain support|height/deck_height/unit_point; explicit tagged support surfaces, not highest roof ray|
|2 Bridge support|MOAT_DECK and deck logic; surface ID and explicit portal transition|
|3 River/water|RIVER_X/CROSSINGS/moat constants; semantic impassable water volumes|
|4 Obstacles|blocked/can_step; author solids and agent clearance|
|5 Crossings|crossing/moat_waypoint/needs_moat_crossing; authored links, no guessed X axis|
|6 Movement|travel/pace; actual legal movement remains Battle controlled|
|7 Routing/retreat|waypoint/retreat_waypoint; authored navigation and exit regions|
|8 Line of sight|clear_shot/parapet; height-aware solids, no old rectangular fort assumption|
|9 Muster|muster_ground/restore_bank_position; validate new spawn capacity, do not shrink/delete troops|
|10 Deployment|Battle.setup company homes/stations and initial player/ram locations|
|11 Objectives|GATE/COURT/CAMP/GROVE and capture/escort markers; semantic goal IDs|
|12 Siege|gate HP, gate blocker, ram road and wall posts; stable dynamic gate IDs|
|13 Riding/vehicles|width, overhead clearance and support selection for real horses/chariots|
|14 Pointer aim|Controller._aim_point and attack aiming; current map surface, actual input preserved|
|15 Camera|LIMIT/BRIDGE_VIEW/support height; same normal body pixel scope, no whole-gate fit requirement|
|16 Scene/render|old landscape geometry dimensions are legacy-only, not new scene creation constraints|
|17 HUD/audio|map landmarks in objectives/markers/cues, including Battle.Ground.GATE references|
|18 Save/load|map identity before setup; legacy no-map-ID exact old path, unknown topology fails closed|
|19 Review/tests|actor binding/contact planners currently reference Battle.Ground statically; migrate explicitly|

## Identity and compatibility

Map save identity is map_id + topology_revision + topology_sha256. Visual revision
and full editable source SHA are separate provenance, not reasons to reject an
otherwise compatible save when only materials/visual content change. A topology
hash must ultimately be generated from canonical traversal/support/obstacle and
semantic placement data, not arbitrary GLB bytes. Navigation and scene payloads
have exact hashes and source-derivation provenance. A save for production-v2 must
use a new format version unsupported by old engines; do not let old loaders
silently load it on legacy terrain. Do not automatically migrate old positions.
Unknown topology keeps the original file untouched and reports an unavailable map.

Runtime instances belong to each Battle, never a global process-wide map switch.
LegacyMapRuntime is a thin delegation to existing Ground with per-instance
bridgehead context. It does not rewrite Ground, old spawn positions or old saves.
Production-v2 scene, controller, actor rendering and route diagnostics must all
read the same instance; adding a new Physics scene alone is not integration.

## First mother-scene agreement (not an art result)

Godot metres, Y up, XZ planar coordinates. Bridge centre(0,1,0), length14m,
clear width7.2m. Gate entry(27,1.2,3), exit(33,1.2,3), dynamic gate atX30,
clear width6.4m/height5.4m. These are author-scene proposals, not immortal runtime
constants. Bridge underside is water and not traversable in the first slice.
Roof/wall-top geometry is not walkable unless explicitly tagged; the gate floor
under its roof is walkable. Surface identity must permit future layered routes.

## Verified so far / not verified

Official Godot4.6.3 headless identity/catalog test passed immutable snapshots,
visual-only revision compatibility, unknown/corrupt topology rejection, separate
catalog isolation and byte-unchanged old input dictionaries. Exact legacy
wrapper parity passed5236 checks alternating open field/bridgehead contexts.
These are unit-level adapters; Battle/Controller/Save are NOT yet switched to
MapRuntime. No new scene GPU, newmap512 spawn capacity, combat performance,
mounted traversal, actual saved-game restart or art acceptance is claimed.

AuthoredSupport now indexes explicit walkable triangles by spatial cell and
requires surface identity for overlapping supports. Actual JSON roundtrip tests
cover numeric indices/revisions, a tagged gate floor beneath a nonwalkable roof,
separate bridge/ground layers, malformed triangles and map-instance isolation.
This module does not yet provide obstacle clearance, portal routes or Battle
binding; the tiny test triangles are not game art. Next consume the real mother
scene sidecar and validate support/spawn capacity before any newmap play claim.
