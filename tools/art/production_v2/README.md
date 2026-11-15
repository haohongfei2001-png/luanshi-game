# Production-v2 complete gateway collection

AUTHORING, NOT DEFAULT, NOT ART ACCEPTED. Replaces the old-layout candidate route,
not old saves or frozen RC/60083 assets. One coherent collection is integrated
by the environment owner into the complete production-v2 mother scene before
native visual review. Do not deliver its offline preview as a game screenshot.

## Inputs and reproduction

`build_gateway.py -- FROZEN_PROFESSIONAL_MOTHER.blend SCENE_LAYOUT.json OUTPUT_DIR`
via Blender4.3.2, background, disable-autoexec, python-exit-code1. The professional
mother is architecture07; its exact source SHA256 is recorded in each generated
architecture-contract.json. It can be regenerated with gate_structure/build_architecture.py using original
pavilion FBX, original modular_wooden_pier source, hash-locked surface source,
`--native-roof-band --complete-gate-masonry --complete-portal --no-preview`.
No complete-fort flag. Gate_structure dependencies and licenses remain required.

The new builder selects professional roof/native frame and professional deck
objects before deleting old containers. It imports NO old curtain walls, pier
slots, old Ground constants or whole rectangular layout. The roof and connected
frame are rigidly translated to the new hall rather than flattened to fit camera.
Native deck geometry/UV is retained and laid over the14m new span. Whole gateway,
load-bearing depth, mountain-following defenses, retreat opening and bridge
support are authored in one metre-scale scene.

All coordinates follow the shared scene_layout map_id. Godot XZ/Yup construction
maps to Blender (x,-z,y) once and exports once to glTF Yup. The output copies the
layout snapshot, records its hash, and emits actual support/solid/walk/gate data.
Source solid polygons may refine the initial terrain anchors. Environment must
blend final foundation profiles, not move actors or shrink people to compensate.

## Legal editable source and palette

- VVayToyek pavilion CC0: original roof, curved rafters and connected frame.
- Rico Cilliers / Poly Haven modular wooden pier CC0: original board geometry/UV.
- Rob Tuytel / Poly Haven masonry and wood CC0: original PBR source preserved.
- New geometry and material derivation are recorded project contributions.
Original authors, source URLs, hashes and notices remain in the repository's
existing asset/source manifests. Do not substitute a generic website license.

Structural timber is a declared new consistent palette, not a global exposure
fix. Decode source sRGB pixels, apply linear-channel power .66 and saturation .65
about Rec709 luminance, then re-encode sRGB. This preserves grain and unmodified
normal/roughness/AO sources, keeps original images immutable, and produces a new
runtime derivative. Original-byte-identity is not claimed for derived albedo.
Actual build03 derivative linear luminance P5/P50/P95 .0754/.1052/.1394. These are
measurements, not visual approval. No fake global AO is multiplied into albedo.

## Integration / validation

`architecture-contract.json` defines explicit ground-level walk surfaces, thick
wall obstacles, terrain support footprints, GateDoor stable gate_main identifier,
closed blocker, open portal, and rear retreat. Upper walls/hall are NOT walkable.
Bridge below-water route is forbidden. Gate state toggles only its blocker/link
and visual group; never reassign all navigation or reset unit identities.
Godot4.6.3 imports glTF extras nested under `node.get_meta('extras', {})`, not as
individual top-level metadata keys. Gate pivot is (30,1.2,3). Old x48 HP test is
not the new map adapter. Native owner must bind existing combat/HP and saves.

Run audit_gateway.py against actual editable mother and contract; run
`test_architecture_import.gd -- architecture.glb` in official Godot4.6.3.
Tests cover finite mesh rays, explicit surfaces and actual PBR import. They do
NOT cover full siege, troop muster, GPU performance or actual-game art quality.
512 per side remains a real muster target, not a passed test or reduced count.

## Rejected local iterations retained

01 builder helper signature mismatch, no finished asset.
02 source-parent deletion order omitted professional bridge boards; a mistaken
image-buffer linear assumption made derived timber too pale. Gate edge stone
also intruded .15m into claimed opening. Rejected before integrated rendering.
03 selects all source objects first, explicitly decodes sRGB, moves stone trim
outside clear opening. Actual mother35 gate rays and35 bridge/headroom samples
pass; board top .973..1m. First Godot test falsely read extras as top-level keys;
correct nested import check passes, retained failing log is not hidden.
04 changes only conservative gate obstacle envelope to include projecting edge
stone, without narrowing the6.4m aperture. Use its final contract over03.
