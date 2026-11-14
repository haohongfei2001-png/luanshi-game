# Whole master R2: model-composition preflight, NOT game acceptance

Previous actual Godot source735143aa and its white-stone/red-lime foliage failure remain preserved. This revision changes the whole authored forest/shore arrangement, not the battle or save schema.

Removed every compound RockPath instance from banks/landings. Complete individual Rock_Medium native meshes are now dimensioned by horizontal footprint, not shallow source height. Twelve sparse shore anchors and four small abutment rocks per bridge leave continuous water open. Structural test forbids RockPath in the shore group and checks each world-space bank-rock AABB under2.8m. No gameplay obstacle, crossing coordinate, gate opening, force count or authoritative Ground height was changed. Existing shore collision stations therefore remain a possible visual/physical contact mismatch that needs real traversal review.

Reauthored all twelve forest stands as larger continuous fore/mid/background canopy masses rather than scattered small red/green display trees, with denser complete shrubs/ferns. Removed the red TwistedTree/Bush_Common art from the live scene. Added the complete Bush_Common_Flowers native asset from the same archived CC0 Standard ZIP; its source files/hashes were added to SOURCE.json. Original models/UVs remain editable. Existing original assets are retained in the repository. Runtime now respects authored per-instance material overrides rather than silently replacing them with the mesh's original material.

Native scene now has643 complete instances in13 groups and80 unchanged shared-height terrain tiles. These counts are inventory, not quality approval. Three load/unload cycles return1571 nodes to1 with zero orphan nodes. Normal game entry135tick512v512 still records185/231 hits. No gameplay balance adjustment was used to produce the composition.

## Explicitly non-game preflight

The two PNGs are actual Blender Cycles renders of the exported authored scene geometry, not Godot screenshots and not painted concepts. 22m view follows game yaw-33deg and approximately50.8deg pitch; whole view is115m. No actors are included. Godot custom ground/water shaders cannot export faithfully to glTF: the preflight uses plain labeled ground/water approximations and one anonymous moat water mesh retains a white fallback. Cycles leaf lighting is also darker than the game and cannot certify final color. Consequently these images are for scene footprint/overlap/composition only, not renderer/material/character acceptance.

Self-review: the stone carpet is absent and forest silhouettes now form larger masses. However the ground remains visually underdeveloped in this shader-free preflight, old bridge/gate proportions remain and mature military architecture replacement has not been completed. Do not call it a finished environment or reference-quality scene. Next: actual Godot same seed/tick/22m native2K/4K review with per-frame master identity+packed-scene hash, followed by continued structural/material rework against those frames.

Reproduce model-only check:
```
godot --headless --path . --script tools/art/build_river_pass_master.gd
godot --headless --path . --script tools/art/export_master_preflight.gd
blender -b --python tools/art/blender_master_preflight.py
```
No visual PASS, performance PASS or M5 result is claimed.
