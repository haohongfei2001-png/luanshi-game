# Repeatable whole-mother placement

Source branch: `dot/production-v2-fortress-mass`. The older
`dot/production-v2-gateway` intentionally remains66c3bf79 and is NOT the current
structural branch. Structural baseline before this interface is full SHA
f11c7c6fcce3311d4ec3f6a5e2c3e31c732f07ff.

## One transform, no independent dragging

Use immutable unplaced editable mother and its matching author-local sidecar.
Run under the shared heavy-art lock, without GPU or rendering:

```
blender -b --factory-startup --disable-autoexec --python-exit-code 1 -t 2 \
  --python tools/art/production_v2/place_architecture.py -- \
  AUTHOR_MOTHER.blend AUTHOR_CONTRACT.json OUTPUT \
  --yaw-degrees YAW --translation X Y Z
```

Only the single `ProductionV2Architecture` parent receives a transform. No mesh,
child door, bridge, marker or source vertex is independently shifted. No scale,
roll or pitch is accepted. This permits the whole fortress to follow the selected
professional natural set without shrinking humans or obeying stale map anchors.

The pure `placement_contract.py` uses the same Godot Y-up rigid4×4 matrix for:
- every obstacle/walk/support polygon and absolute elevation;
- support axis endpoints and top elevations;
- gate pivot, closed blocker, entry/exit and rear retreat portal;
- embedded world-space walk-marker JSON as well as the external sidecar.
Relative clearances, width, foundation embed depth and unit counts stay unchanged.
Blender uses exact basis conjugation `B*M*inverse(B)` whereB(x,y,z)=(x,-z,y).
Visual glTF coordinates convert back to Y-up once through the exporter.

The output keeps the untouched author-local contract, records both source hashes,
records the full matrix and emits compressed editable mother, GLB and placed
sidecar. Already-placed source roots/contracts are rejected to prevent accidental
double transforms. New semantic field types need an explicit transform handler
and test; this interface supports the current architecture contract, not unknown
future arbitrary dictionaries. New placement requires new map-profile/muster
validation. It does not automatically move old saves or other scene sources.

## Actual verification

- Three pure-Python tests cover known90° landmark, Blender/Godot basis agreement
  at0/13/90/-90/180°, preservation of relative quantities and source input, and
  rejection of nonfinite/double-transform input.
- One full source mother was actually placed at yaw37°, translation(11,3,-7).
  This is a diagnostic pose, NOT a selected scene location or art proposal.
- Official Godot4.6.3 headless imported both original and placed GLB. All15 actual
  mesh-surface world bounds match the one matrix; maximum error0.0000078642m.
  Four actual door/portal world positions and embedded walk contracts match the
  sidecar. No GPU, screenshot, new material, gameplay or visual pass is claimed.

Recheck actual placement with:
`test_placement_import.gd -- AUTHOR.glb PLACED.glb PLACED_CONTRACT.json`.
The normal source audit is not used blindly on rotated world-space axes.
