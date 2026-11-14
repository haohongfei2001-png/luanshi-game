# Independent tree source reconstruction, NOT GAME ART ACCEPTANCE

Latest accepted direction: natural adult tree and readable whole crown, subordinate to the road/fortress composition. The existing fairy source tree, fungi and fine bright leaf noise are not an accepted foundation, even after correct ground winding/mips. Five trees plus five bushes at 1.38 M triangles remain an expensive conversion prototype, not the final large-battle budget.

Actual isolated original-material previews were rendered (subdivision cap 1, no denoising; NOT Godot):
- `EN-oak_trunk.4`: rejected as main field tree foundation. The actual result remains squat, with giant root claws and blunt branch stubs. A static inventory recommendation is not a quality finding.
- Complete `EN-tree_branch_medium.05`: 38,358 evaluated triangles / 118 mesh instances. Continuous naturally tapering branch hierarchy and thinner roots offer a structural production input. It is a branch system, not an already complete mature tree.
- `EN-branch1`: 42,252 evaluated triangles / 47 instances. A complete original leaf spray, not an adult trunk. Preserves source leaf outlines and original material family.

`tools/art/sprite_source/author_field_oak.py` now makes an independent editable tree study from these latter two complete structures. It does not modify the original movie libraries, object mesh topology, UVs, materials or nested parent inverses. Crown attachments use evaluated twig transforms and real terminal points, not a scatter over a sphere. The complete medium branch system is explicitly repurposed as a young field-tree skeleton; that adaptation is not claimed as original movie layout or botanic validation. Pink fungi and giant roots are absent because they are not imported, not hidden by light.

```sh
blender -b --factory-startup --disable-autoexec --python-exit-code 1 -t 2 \
 --python tools/art/sprite_source/author_field_oak.py -- "$SPRITE_ROOT" /tmp/field-oak .20 96 1.0
blender -b --factory-startup --disable-autoexec --python-exit-code 1 -t 2 \
 --python tools/art/sprite_source/preview_native_collection.py -- \
 /tmp/field-oak/field-oak-source-study.blend FIELD-oak-source-study-01 /tmp/field-oak/preview 4500000
```

Sparse first study (`.55 40 1.4`) produced 32 sprays, 1,390,422 triangles / 1,622 instances. Actual preview was too fragmented and see-through; retained as a rejected source study. Second (`.20 96 1.0`) selected 88 actual sockets. It produces a more continuous narrow, asymmetric young-tree crown, but does not yet provide a mature broad overstory canopy or prove normal-pixel game readability. No tree is enabled in game by this script. More source triangles are NOT a performance solution.

Next representation must preserve crown grouping and branch taper while testing practical leaves/branch LOD or baked leaf-spray representations in real Godot at the new MOBA camera scale. Do not just decimate everything into a dark lump. Source/derived paired views, UV/mask preservation, actual surface/draw count, triangle and memory cost remain required. No transmission/animation/shadow stability or performance acceptance is claimed.

Source remains the fixed official Sprite Fright ZIP SHA256 `21ee25dfffc76030770b644de5fe897559aead064b384fba77166b71a9337791`, Blender Studio, CC BY 4.0. The existing package readme/provenance applies. Each authored output records exact input library hashes and selected socket locations in `assembly.json`; original movie files are never saved. Local study previews are internal, not user-deliverable screenshots.

## Real conversion and cost bottleneck

The 88-spray tree was actually baked/exported and inspected, not merely planned: first derivative 158,288 triangles, 4,254 original mesh placements, 21 unique evaluated geometries, one final mesh/surface, original UV plus atlas UV, 2048 diffuse/normal/roughness. Godot headless GLTF intake exited 0. Source/derived full-tree offline images were personally reviewed. This still is not a broad mature overstory or actual normal-camera approval.

Measured geometry breakdown revealed the hidden expense: 88 leaf-spray **micro-branches** (`GEO-branch.1`) consumed 111,760 triangles, 71% of total; leaves consumed 32,384, full supporting branch system roughly 14k. A second isolated policy therefore lowers those micro-branches, retaining the exact leaf and main-limb policy. It does not remove trees, shrink resolution or reduce gameplay. Results must be viewed before enabling.

The first bake crashed with a Blender native SIGSEGV at the old cached UV-layer reference following edit-mode unwrap. The failed log/backtrace are retained locally. Reacquiring `obj.data.uv_layers['LuanshiSharedAtlas']` after returning to object mode fixed this run; the complete subsequent bake/export/preview exited 0. This was not reported as an OOM. The frozen old CI converter is not rewritten.

The reusable converter now accepts an optional explicit LOD JSON policy and records actual per-geometry instance/triangle cost. Without that argument its original ratios remain unchanged. `assemble_woodland_region.gd` now calculates actual imported triangle/surface/node costs instead of hard-coding 185,676 triangles for any tree supplied. Existing original-family run still measures 1,380,800 triangles; a nonindexed shared-mesh unit test verifies instance accounting. Surface count remains distinct from actual draw calls, which are NOT_MEASURED.

Second actual conversion finished: **55,328 triangles**, same 4,254 source placements and 21 unique geometries, same source/derived bounds, original UV + 2048 PBR atlas. Lowering only micro-branch complexity removed 102,960 triangles (65.0% of the first derivative); leaf and main-branch policies were unchanged. Both derivative offline previews use identical bounds/camera and were personally compared: canopy outline/branch organization are retained at that preview size; fine twig error still needs actual game pixels/shadows. Source-vs-derived previews use their own evaluated bounds, so they are not advertised as pixel-registered comparisons.

Godot headless intake of the 55,328-triangle GLB exited 0. Reassembling five new tree prototypes plus the five original bushes under new shared-height opt-in gives **729,060 nominal triangles** (old 1,380,800); this is geometry accounting, not FPS, draw calls or a final approved army budget. Bushes now dominate this experimental family. New prototype GLB SHA256 `bda5c9256a25f08952bf46461343eab281e885a943cae5679000bf173ed269f1`. Linux converter peak RSS 1,048,872 KiB, not game memory. It is a narrow-crown field-tree production study, not yet the complete mature forest.

Reproduce after the source authoring command above:
```sh
blender -b --factory-startup --disable-autoexec --python-exit-code 1 -t 2 \
 --python tools/art/sprite_source/bake_reusable_collection.py -- \
 /tmp/field-oak/field-oak-source-study.blend FIELD-oak-source-study-01 /tmp/field-oak/realtime \
 tools/art/sprite_source/field_oak_lod_study.json
```

**Do not replace the frozen scene being captured or mark art passed.** A separate next full-scene Godot capture must establish root contact, crown scale/readability, materials, shadows and genuine runtime performance before accepting this prototype.

Metric clarification: converter `derived_world_bounds_error=0` verifies flattening against its **already LOD-evaluated instance geometry**, not fidelity to original high-resolution source. The receipt now states this explicitly; original-to-LOD geometric error is NOT_QUANTIFIED. It must not be cited as lossless source reconstruction. The two 158k/55k derivative bounds match each other; native high-resolution bounds differ.
