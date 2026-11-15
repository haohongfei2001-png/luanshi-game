# Production-v2 resource identity preparation

After the official Godot editor has imported the final source on the **same host
and renderer platform used for export**, run:

```sh
Godot --headless --path PROJECT --script tools/production_v2/collect_resource_identities.gd -- INPUT_MANIFEST NEW_OUTPUT_MANIFEST
```

Input pins `scene.path/sha256`, `navigation.path/sha256`, and
`actor.path/sha256/timing_path/timing_sha256`. Paths are `res://` resources.
The tool independently discovers the complete transitive dependency set, requires
original bytes at preparation time, verifies pinned roots, then records both
original source SHA256 and actual imported-resource path/SHA256. It never turns
a packed hash into a fabricated original identity. Output must not already exist.

This only prepares identities. It does not prove source licenses, art quality,
valid map topology, or exported-PCK closure. The normal editor exporter must
include the JSON/timing/notices and UID table. Afterwards run the actual
`DotProductionV2Entry --validate-setup` in an independent empty cwd using the
exported PCK, without checkout fallback. Every dependency and packed byte hash
is then checked by the entry. Never reuse another platform's imported hashes.

Tests: `tests/map_runtime/resource_identity_preparation.gd` checks valid direct
resources, wrong root pin, unsafe path, missing timing identity, and no input
mutation. Actual imported architecture GLB plus seven texture dependencies and
one raw JSON (9 resources total) also passed the collector locally. This used
architecture as a resource-closure fixture, not a valid actor/map manifest or
new scene/GPU evidence. Earlier source11 actual 9-resource PCK positive/negative
fixtures remain the exported-resource validation evidence; a final new mother
PCK is still pending.
