# River-pass master: first whole-scene replacement checkpoint

Status: structural/gameplay validation only. VISUAL NOT RUN; NOT art acceptance. Previous R1/R2 actual images failed and R3 was archived at ca14ca0, not promoted. This branch starts from RC25 d1c1895221c33386d471922807ed590a6987dbe1.

## Substantive replacement
The bridgehead battle entry now loads an offline-authored editable Godot scene, not the old runtime landscape construction. Thirteen named spatial groups organize the complete pass: eighty matching-edge terrain tiles, shared twelve-mass topography, four physical crossings, foreground riparian stands, middle terrace woodland, ridge forest, shore groups, rear settlement and peripheral road pavilions. Native assets preserve original mesh, UV and material boundaries. The 436 instances are an inventory, NOT evidence of quality.

The old active military fort modules and intact bridge spans remain as lawful functional foundations; this does **not** claim a newly acquired complete Chinese military castle. Gate collapse, siege ram and roof visibility contracts remain connected. New complete pavilion architecture is outside the active combat bounds, not an invisible obstacle. Trees are visual vegetation, not new navigation blockers. Core gameplay, force counts and casualty systems are unchanged; the changed terrain can change deterministic combat outcomes. Ordinary legacy open-field Ground height is unchanged.

## Licenses
Nature models: seventeen selected complete models and dependencies from the exact Quaternius Standard CC0 archive, 104088529 bytes, SHA256 298f6732b872e4cf7b30e6e7abf9641c7f6dc6b326df37ac089533ed7e3d58c9. Download https://store.godotengine.org/asset/quaternius/stylized-nature-megakit/download/31/ . Package License_Standard.txt, July 2024 file dates and per-member hashes are retained under assets/river_pass/nature. Publisher listing https://store.godotengine.org/asset/quaternius/stylized-nature-megakit/ identifies Standard 1.0 as CC0. This precise historic grant is not a claim that later QAL releases or paid editions are CC0.

Pavilion: VVayToyek's complete CC0 four-corner pavilion, source FBX and converted GLB plus source hash and author-page evidence under assets/river_pass/pavilion. Original https://vvaytoyek.itch.io/chinese-four-corner-pavilion-free . No paid assets or new accounts. Existing fort/bridge/terrain licenses remain in their original asset directories. Pavilion is a stylistic roadside prototype, not an assertion of exact period archaeology.

## Recovery and validation
```
export XDG_DATA_HOME=/tmp/luanshi-environment-xdg XDG_CACHE_HOME=/tmp/luanshi-environment-xdg XDG_CONFIG_HOME=/tmp/luanshi-environment-xdg
godot --headless --editor --path . --quit
godot --headless --path . --script tools/art/build_river_pass_master.gd
godot --headless --path . --script tests/river_pass_master.gd
godot --headless --path . --script tests/world_terrain_compat.gd
godot --headless --path . --script tests/field_bridgehead.gd
godot --headless --path . --script tests/field_bridgehead_outcome.gd
```
Logs in this folder reflect this checkpoint. Baked vertex support parity is not animated sole/ankle contact. Headless dummy renderer reports cleanup resource warnings after scene-test completion, retained in the raw log. Local display initialization is blocked; genuine same-seed/time/22m native 2K/4K Godot images and normal-speed footage are pending parent CI. No FPS, actual internal rendering resolution, MacBook Air M5 or visual acceptance is claimed. Existing world_master_review's old library inventory does not describe this replacement; use composition_audit for the new scene inventory.
