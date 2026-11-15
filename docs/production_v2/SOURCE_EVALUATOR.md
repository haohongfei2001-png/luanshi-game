# Complete native environment source evaluation

These are source-authoring tools, not a shipped map or accepted artwork.

## Why the original evaluator is pinned

The licensed Sprite Fright production set was saved in Blender3.1.2. Its complete
canopy groups use legacy Point Distribute/Point Instance/Attribute nodes. Actual
Blender4.3 inspection loaded these as NodeUndefined and rendered naked branches,
even though the canopy collections and camera visibility were enabled.
[Blender3.2 release notes](https://developer.blender.org/docs/release_notes/3.2/nodes_physics/)
confirm removal of these legacy nodes. A later Blender is not a valid silent fallback.

The complete original source collection is CC BY4.0, Blender Studio / Blender
Foundation: https://download.blender.org/demo/sprite_fright_030_0020_A.zip .
Keep its readme, attribution, license link and actual modification notices when
redistributing derived art. Professional provenance is not visual acceptance.

## Reproducible evaluator

Official portable Linux Blender3.1.2 archive:
https://download.blender.org/release/Blender3.1/blender-3.1.2-linux-x64.tar.xz

Size187294308bytes. SHA256:
`c1d345b25c6f83708b2681d354d70a3e6023c04bb73cc7943366c0c19e542958`

[Official checksum list](https://download.blender.org/release/Blender3.1/blender-3.1.2.sha256).
The fetcher checks free space, archive bytes/hash, safe extraction and executable
version. It never replaces the system Blender or installs plugins/accounts.

```sh
python3 tools/art/production_v2/fetch_source_blender.py --cache "$ART_TOOLS_CACHE"
flock "$ART_BUILD_LOCK" python3 tools/art/production_v2/measure_process.py \
  --timeout 240 --json "$ART_REVIEW_OUT/process.json" -- \
  "$ART_TOOLS_CACHE/blender-3.1.2-linux-x64/blender" \
  --background --factory-startup --disable-autoexec --threads 4 \
  --python tools/art/production_v2/review_complete_native_set.py -- \
  --source "$SPRITE_SOURCE/lib/sets/sprite_village/sprite_village.blend" \
  --out "$ART_REVIEW_OUT" --audit-only
```

Remove `--audit-only` for the original-set authoring render. Both the exact source
version and zero undefined nodes are hard requirements. Never turn a missing
canopy into a passing build by silently ignoring unsupported nodes.

## Verified scope and limits

The3.1.2 audit completed on the original535-object030_0100 scene with zero undefined
nodes. An original-density render was killed(exit137); do not infer a completed
frame or an exact cause from its final internal log line.

A complete-set diagnostic image did finish with these explicit reductions:
20% tree/branch-leaf density,0.5% other micro-scatter,2% child particles, subdivision
cap1, and omitted film-only tree-surface moss geometry. Original layout, canopy
systems and bark body/material were retained. The script records original and
changed values. This diagnostic took63.897s with peak child RSS7063856KiB on the
cloud Linux machine, measured by a fresh parent using RUSAGE_CHILDREN. It is NOT
original-density success, Godot FPS, a MacBook Air M5 result, or accepted art.

The original set's fairy-world hollow trees and dense small paths are not an
accepted historical battlefield. Select/adapt a coherent authored fragment or
reject the source; do not call a collection of isolated assets a finished scene.
No legacy map, default scene, saved casualty, formal story or shipping package is
changed by these tools.
