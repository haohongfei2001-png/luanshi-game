# River-valley authored environment, internal high-fidelity work

This is an actual new editable authoring pipeline for the near-bank military road,
bridge, short stone landing, thick gateway, wooded shoulders and real rear muster
space. It does not modify Battle, the native map/controller, main, or RC24/25.
It is **not art accepted and not a shipping scene**.

## What is genuinely different

- A single metre-space landform field drives terrain vertices, land use, wet bank,
  worn road and the world-space material atlas. There is no old Ground fallback.
- Structural bridge joinery uses actual CC0 worn board contours and original UVs.
- The thick gate and flanking defenses are built in dressed stone courses. Only
  usable structural timber-frame components survive from the earlier architectural source.
  The continuous inherited blue roof strips are replaced by original overlapping
  clay tiles and ridge/hip covers.
  The rejected octagonal fortress silhouette is not retained.
- Native rocks, full native tree crowns and woody understory are embedded/rooted
  on the same ground. Large scan capture plates are not accepted as terrain.
- Exact walk triangles, solid footprints, portals, closed gate leaf, spawn and
  retreat regions share the source geometry. The new topology is not the earlier
  functional fixture and must undergo its own native muster/path test.
- Static stone/wood construction is batched before GLB export; native canopies
  share mesh resources. Every normal-mapped exported primitive has tangents.
- The author supplies one Sun and a native WorldEnvironment wrapper. The unitless
  COMPAT light contract deliberately avoids the Blender glTF 683x light mismatch.

## Inputs and commands

Use existing licensed caches. No automatic download, purchase, new account,
paid tool, or local user-computer action is part of this workflow.

Set `LUANSHI_WORKSPACE_ROOT` to the workspace containing the existing
`luanshi-environment-rebuild` and `sprite-production` source caches. Set
`LUANSHI_PRODUCTION_ROOT` to the existing shared production artifact directory.
The generated source manifest records every consumed source SHA and its purpose.
Do not overwrite older output directories.

```
python build_materials.py OUTPUT/textures
flock "$LUANSHI_PRODUCTION_ROOT/luanshi-heavy-art.lock" \
  blender -b --factory-startup --disable-autoexec --threads 4 \
  --python-exit-code 1 --python build_valley.py -- OUTPUT --build-only
python wrap_native.py OUTPUT res://assets/production_v2/valley_hf08
python validate_source.py OUTPUT
flock "$LUANSHI_PRODUCTION_ROOT/luanshi-heavy-art.lock" \
  blender -b --factory-startup --disable-autoexec --threads 4 \
  --python-exit-code 1 --python review_export.py -- OUTPUT REVIEW_OUTPUT
```

The review imports the **actual GLB** again. A static posed WIP18 actor is loaded
only after export for scale review; actor proxies are forbidden inside the mother
GLB. All offline image filenames say `NOT_GAME`. `--yaw -40 --view bridge` produces
an explicitly separate camera candidate at the same distance/FOV, not a claim of
better asset quality. Native images and normal-speed combat remain required.

## Verification boundaries and known failures

`validate_source.py` checks source input hashes, GLB identity, source topology hash,
unique gate/light, no actor proxies/skin/animations, and normal/tangent/UV closure.
This is **AUTHOR_SOURCE_STRUCTURE_PASS**, never an artistic/performance pass.
The native owner separately validates 512 per team, paths, actual ordinary actor
bindings, scene/environment closure, camera pixels and real 2K/4K gameplay.
M5 remains DEVICE_NOT_RUN. Core literature and a fixed protagonist remain unset.

Earlier internal outputs remain preserved:
- HF01: stopped a slow global-modifier build before any scene export. Replaced
  it with local mesh operations and static batches, rather than waiting forever.
- HF02: real GLB exported, but rejected paving had inward closed-solid normals and
  ground penetrated its top. Native headless import also exposed Sun energy1844.1.
- HF03: corrected stone interfaces and energy2.7, but a full native cliff crossed
  the road. Rejected, not frozen for artistic review. Its author-source render also
  showed a dark bridge, requiring reimported-GLB review rather than guessing.
- HF04: constrained geological section buried by the authored shoulder, staggered
  paving, full input closure and separate camera audit. Native/art results must be
  read from the dated artifact receipts; the number itself implies no maturity.

## Rights

Terrain mineral/soil/wood, native rock/tree/understory and worn pier inputs are
Poly Haven CC0 resources already acquired for this project. Their original source
receipts are retained. Mature Chinese roof/frame provenance remains the earlier
architecture source receipt. Do not infer rights for any unacquired third-party
model. No owner reference pixels are projected or copied into game textures.

### HF05 native-scan bank derivation

Run `bake_native_bank.py OUTPUT/bank-field` first and set
`LUANSHI_BANK_FIELD=OUTPUT/bank-field/native-bank-field.npz` before material and
scene generation. It projects original `coast_rocks_03` triangles with original
UVs at native metre scale. The same field is blended into the continuous terrain
and albedo using buried, feathered geological footprints. No full scan capture
plate remains. HF05 passed structural validation and actual GLB reimport, but the
road/water/ecology image still fails the visual target. It is a frozen runtime
contract checkpoint, not the chosen final artistic result.

HF05a is an immutable gate-landmark amendment of HF05. The exact doorway ground
anchor is `[14.8, 1.2, 0]`; it is **not** either leaf's rotation axis. The two
physical hinge axes are recorded separately. `repair_gate_anchor.py` preserves
the GLB BIN payload and changes root identity plus the corrected sidecar. The
canonical topology digest includes this runtime-consumed anchor. Independent
native tests on HF05a, not the old terrain fixture, found valid muster for512 per
team (1057 actors including hero/officers), zero illegal source spawn positions,
and both cross-river and retreat paths. This is not a combat FPS or art result.

HF06 preserves native soil luminance structure that earlier processing had
flattened, adds original periodic physical water-normal slopes, uses a C1 shore
curve, and embeds irregular older approach courses into the military road. Its
source/normal/tangent closure is checked independently; do not reuse HF05a's
navigation results for HF06. All render evidence is still explicitly offline.


### HF07 / HF08 whole-source checkpoint

The river span is now10m, not14m; it was physically rebuilt rather than achieved
by zoom. Both bridgehead supports and all portals moved with it. The eastern
4.7m stone landing leads directly to the5.8m thick gateway. The courtyard and
retreat remain actual terrain, outside the close action view. Wall-side water
now meets the defense foundation rather than a broad grass shelf.

Overlapping fired-clay roof courses and ridge/hip caps are newly authored solid
geometry. Only the acquired source's useful structural frame remains. Native
scan rocks use the convex hull of their actually placed exposed vertices for
obstacles, not guessed circles. Source-object iteration is sorted for recovery.
The terrain atlas area-prefilters source materials to its real texel density,
rather than point-sampling a2K input into an80px repeat and creating false grain.

Raw Godot inspection of HF05a exposed `shadow_enabled=false` despite its correct
Sun energy. HF08 declares the existing Sun's enabled shadows,4-split mode,80m
range,0.1 bias and0.6 normal bias in the author-world contract and wrapper. It
must be verified in Godot as one changed Sun, never a second light or a runtime
relighting override. A Cycles shadow is not evidence of Godot shadows.

Public runtime manifests use stable logical source URIs. The separate
`local-source-map.PRIVATE.json` resolves those inputs for local validation and
must never be included in a public runtime package. Likewise, the private
recovery command file is not a public artifact.

The chosen review camera locations changed with the physically shorter bridge.
HF05/HF06 vs HF07/HF08 images are therefore **not** a strict same-location A/B.
The original-65 yaw and separate-40 yaw candidate use the same distance/FOV;
actual matrices and posed body pixels are saved. Neither is owner-approved.

All current author renders remain ART FAIL / NOT_GAME. Stronger technical source
closure and a roof with real overlaps do not prove modern-game visual quality,
normal-speed action, export-import closure or GPU/device performance.

HF08 independent Godot4.6.3 verification is recorded by the runtime owner at
`dot/production-v2-map-runtime@b8c8cf02c12433265d0642fdae88104b5fb44f39`:
unique Sun and World, exact enabled shadow properties,8882 navigation nodes,
33862 support triangles,62 solids,1057 actual roster entries with zero illegal
spawn positions, all four semantic paths, and100 actual Controller ticks with
six source18 ordinary actors (70 walking and30 idle). This is neither a combat
hit/death test nor a frame-rate/GPU result. The-65 native camera was not replaced.
