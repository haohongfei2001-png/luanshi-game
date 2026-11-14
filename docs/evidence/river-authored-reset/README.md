# Full visual reset: production design 01, NOT a game candidate

R1 and R2 are rejected **as whole images**, not nearly approved scenes with a few bad props. Source a3ef6216d3b55ebd141d983bf1851715410a922f and its actual screenshots remain reproducible failure evidence. Nothing in this experiment promotes that mixed asset foundation.

## Changed production method

Choose one coherent environment craft benchmark: [Age of Empires IV, Chinese, official actual game image](https://cdn.ageofempires.com/aoe/wp-content/uploads/2021/06/bg-civ-chi-2-desk.webp), reached from the [official civilization page](https://www.ageofempires.com/games/age-of-empires-iv/civilizations/chinese/). Inspected original image, not just prose. Its useful transferable qualities are connected road/courtyard/wall hierarchy, coherent construction scale, bounded foliage and a common material language. Its bright team bands, later-era structures, gunpowder, compressed RTS buildings and exact designs are NOT imported. No pixels or assets from this commercial game are redistributed here. The owner's battle-view image remains the minimum visual quality line, not the benchmark game's age or stylization.

Old approach selected individual legal assets and attempted to make them belong through placement and tinting. New approach authors the entire scene's spatial/material contract before selecting any asset. A candidate must satisfy that whole-scene contract, retain professional editable structure and lawful source redistribution, and survive normal-camera Godot review. Repeated parts cannot substitute for an authored composition.

`tools/art/authored_reset/layout.json` defines all thirteen connected assemblies, six material families, human/bridge/gate dimensions and four protected combat routes. The Blender builder creates a whole-scene editable **volume design**, not game art. This is intentionally not another primitive-mesh bridge/gate/forest presented as a finished candidate. It is not connected to gameplay and cannot overwrite the frozen scene.

## First concrete design decisions

* The common structural system spans both bridges, abutments, wall base, gate and drain edges. Timber scale and masonry scale cannot change between vendors.
* The gate keeps the existing 8 m opening and its real approach, but uses a restrained 8.2 m total silhouette rather than selecting a roof first and stretching it over the battlefield.
* Woods are four bounded landscape masses connected to banks and slopes, not random individual trees. Near trees must be modeled inside their crown envelopes and reviewed for screen-space obstruction, not simply moved offscreen.
* Bridge decks retain existing width and elevation; rail/support modeling must not obstruct the 7.4 m military lane. These dimensions preserve gameplay anchors, not the rejected deck's art.
* Earth is one continuous authored land surface with worn road lanes, graded shoulders, banks and drainage. Six material-family colors here are design swatches, NOT a proposed tint-only solution.
* The fixed 22 m review remains at (34.2, 0.6, 1). The main river at x=-32 is not visible in this frame; the visible crossing is the moat at x=24. No camera switch will hide this constraint. Whole-map review separately covers all river crossings.

## State and next production work

Executed four design tests: protected route/tree overlap is rejected; changing normal camera distance is rejected; falsely relabeling design as accepted art is rejected; valid layout passes. These are mechanical design checks only, not silhouette/beauty/occlusion acceptance.

Professional unified source selection is **PENDING**. No full high-quality free redistributable Chinese military landscape kit has yet been verified. Do not quietly substitute the failed Quaternius + old 0AD + old ground combination. Original assembly modeling and legitimate compatible professional source adaptation remain available, but must deliver actual quality, not inflate mesh counts. Asset research is checking whole-kit availability in parallel.

Run:

```sh
python tools/art/authored_reset/design_check.py
python -m unittest discover -s tests/art_reset
blender -b -t 2 --python tools/art/authored_reset/build_design_blend.py -- /tmp/river-authored-design
```

Generated .blend and images are explicitly DESIGN NOT GAME. Actual new game visuals, animation, performance and owner art approval: NOT RUN / NOT ACCEPTED. Gameplay, saves, combat and existing visual assets are unchanged by this design commit.

## Production preparation after the design checkpoint

Implemented and ran real Godot headless production tools, without substituting generated blocks for professional art:

* `surface_authoring.gd`: one shared metric support sampler produces connected terrain/road/bank mesh tiles, world-metre UVs, globally consistent normals, continuous road/bank/wetness vertex masks. It reads **only the existing gameplay height contract** so actors do not float when replacing the visual layer. This is not reuse of the rejected old ground shader/material/asset, and it is not a newly accepted sculpt. No bridge deck is flattened into the riverbed; complete bridge geometry belongs on separate surveyed sockets.
* `bake_support_scene.gd`: writes an actual editable 72-tile, 147456-triangle Godot production-support scene and seven bridge/gate/wall sockets to `user://authored-reset-support.scn`, never over the existing game master. There is no old fort/tree/rock visual dependency. The current flat diagnostic material is explicitly temporary, not final visual output.
* `asset_contract.gd`: admits future professional PackedScenes only by exact file hash, local license evidence, positive uniform metre scale and explicit triangle/surface budgets. It retains source topology, UVs, material surfaces, node hierarchy and native LOD resources. It rejects the failed mixed-foundation paths instead of silently falling back. Inspection records base triangles/surfaces/UV and existing LOD coverage; counts are production budgets, not measured GPU frame cost. It never creates automatic decimated runtime replacements.
* Admission tests exercised source-hash failure, missing-entry failure, budget failure, UV retention and centimetre-to-metre uniform scaling on a clearly synthetic fixture. Surface tests verified shared tile vertex/normal/UV/material-mask seams, exact gameplay height parity and triangle count. Neither test proves animated foot contact or final visual quality.

Commands:

```sh
godot --headless --path . --script tests/art_reset/asset_contract.gd
godot --headless --path . --script tests/art_reset/surface_authoring.gd
godot --headless --path . --script tools/art/authored_reset/bake_support_scene.gd
```

No new actual-game rendering or full regression is claimed: normal-game code and save data were not modified. The production support surface and asset admission pipeline are usable now; professional gate load paths, complete bridge construction, authored canopy topology, finished ground materials and whole-scene visual acceptance remain unsatisfied. Do not promote support meshes or the synthetic unit-test box to a playable art release.
