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
