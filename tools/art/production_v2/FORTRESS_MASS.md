# Whole fortress mass revision

NOT DEFAULT / NOT ART ACCEPTED. The prior same-envelope surface-system was
rejected: a different large material panel on a coarse wall was not a new
architectural solution. This revision changes the actual full structural form.

## Structural authoring

- Continuous mitered foundation/cross-sections join each defense reach. They
  replace disconnected straight boxes and isolated shoulder towers.
- Footings batter from2.8m halfwidth toward a stepped loadbearing body; major
  shoulders widen to4m halfwidth and3.2m upper halfwidth as integrated defensive
  platforms. Wall heights respond to their ground stations rather than repeat
  a constant giant facade. Copings, outer defenses and inner walk guards form
  a complete thick rampart. Upper routes remain nonwalkable in this first map.
- The gate has continuous battered plinths and a real thick loadbearing podium.
  The route now runs X25.7..34.3, not27..33. Clear opening remains6.4×5.4m from
  ground1.2m; dynamic door retains gate_main and pivot(30,1.2,3).
- Complete original roof, connected columns, curved rafters and cross frames
  survive. Infill consists of actual continuous plaster panels between frames,
  not narrow boards colored white. The14m professional bridge remains intact.
- Masonry uses the verified original2m source convention and wall-local axes.
  Original source/licensing remains. No global exposure or painted AO change.

## New contract, not frozen old arrays

The generator emits14 solids/support profiles, with expanded podium and shoulder
footprints. Environment must reshape support from this data; native must rebuild
its actual profile and512-per-side muster. Do not reuse build04 obstacle hashes.
Both embedded walk-marker JSON and the external sidecar describe the extended
real gate tunnel. Godot importer test compares them, not merely node names.

Current coordinates are author-local metre coordinates, not visual shackles on
selection of the complete professional natural set. The environment lead can
rigidly place the whole collection with yaw+translation. Transform the sidecar
and landmarks by the same matrix. No arbitrary scale reduction to fit troops.
If relative bridge/gate position changes, revise the source and contract together
before assembly rather than independently dragging a runtime asset.

## Rebuild and inspect

Run Blender4.3.2:
`build_fortress_mass.py -- BUILD04_MOTHER.blend BUILD04_CONTRACT.json LAYOUT.json OUT`
Source build04 comes from build_gateway.py and its original professional mother.
Inputs remain editable/traceable, not an imported screenshot or opaque baked scene.
Heavy Blender runs must be serialized with:
`flock /workspace/shared/luanshi-heavy-art.lock ...`
Future saves request Blender compression; compression is storage, not geometry.

Run `audit_gateway.py -- OUT/architecture-mother.blend OUT/architecture-contract.json
OUT/source-audit.json`, then official Godot4.6.3
`test_architecture_import.gd -- OUT/architecture.glb OUT/architecture-contract.json`.
The ray test uses the current actual portal endpoints, not the old route length.

## Actual results and limits

Mass01 changed whole geometry and passed35 gate-clear rays /35 bridge-face and
headroom samples. Offline whole-collection self-review shows connected battered
mass and top-path structure, but is NOT in-game evidence or art acceptance.
Mass02 updates embedded walk-marker JSON to the same new sidecar geometry, and
passes these tests again plus actual Godot import8meshes/15surfaces/506152vertices.
These are imported mesh counts, NOT GPU drawcalls or performance measurements.
New complete native scene, gameplay siege, full-map topology,512 muster and owner
visual acceptance remain NOT_RUN. Wait for the whole original environment-set
composition to judge the complete image. Do not ask the owner to filter drafts.
