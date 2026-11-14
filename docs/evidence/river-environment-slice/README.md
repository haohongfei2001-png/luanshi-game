# Dot river environment slice — engineering checkpoint

Baseline: RC25 `d1c1895221c33386d471922807ed590a6987dbe1`.
The `codex/river-biome-rebuild` experiment was reviewed and **not merged**.
Only its existing licensed woodland source library and importer were reused from
`814417f12092d95d0086d59b5e90ce8db00964cb`; no experimental Ground changes,
bright bank shader, screenshots or art-acceptance claims were imported.

## Actual replacement

- Replace generated pendant-leaf willows with the complete Wildfire Games
  authored green willow, preserving topology, UV opacity and bark surfaces.
- Replace the repeated two-oak canopy with full broad oak, elm and maple masters.
  Eight asymmetrical approach groups join low native brush/fern to taller crowns.
  The bridge-to-gate tall-canopy corridor remains open.
- Remove the continuous boulder necklace. Retain the existing collision-defining
  whole outcrops and assemble 69 buried, decreasing-size talus pieces around their
  toes; exposed earth separates the clusters.
- Sculpt shallow silt shelves only within the already blocked channel. Every
  sampled walkable surface remains identical to the authoritative actor height.
- Add 49 whole native grass clumps at sheltered shore coves, outside crossing
  approaches. Native UV/value structure remains; a bounded foliage palette avoids
  the rejected white and acid-yellow crowns. This still requires actual rendering.

## Rights

Wildfire Games complete tree/brush/grass masters: CC BY-SA 3.0. Exact upstream
revision, source blob hashes, actor pairings and retained license are in
`assets/river_gate/world/woodland/SOURCE.json` and `NOTICE.txt`. The Y-up derivative
library retains the same license. Imported unchanged from the existing experiment;
no new source downloads or purchases. Rock Moss scans remain the repository's
existing Poly Haven CC0 assets; geometry and UVs are retained. No commercial-game
resources or restricted paid source files are used.

## Verification and limits

Linux cloud, Godot 4.6.3 official `7d41c59c4`, headless editor import completed.
`tests/river_environment_structure.gd`: PASS; 7,132 walkable height samples,
138 native crowns, eight native willows, 69 talus parts, 49 grass clumps.
`tests/world_terrain_compat.gd`: PASS.
Integrated source `70cdb716585d3a0ac0cdd75ab5a1c670d8e3768b`: full
`./tools/test.sh` aggregate PASS after environment integration; unedited log in
`aggregate.log`. This includes combat, field orders, old saves, world/economy,
youth-system preservation and real subprocess watchdog tests.
`tests/field_bridgehead.gd`: PASS; 512 per side, tick 400, 300 crossed,
hits 522/558, deaths 135/144. Simulation, Ground, roster, damage, bridge width,
orders and casualty accounting were not changed.

`tests/field_bridgehead_outcome.gd` initially failed to parse the existing inferred
`ok` declaration under Godot 4.6.3. The declaration is now explicitly bool; no
assertion or success criterion was changed. Re-run PASS at tick 2100: natural
守城成功, gate breached at 439, losses 309/329, campaign audits, camp, wait,
march and save restoration all true. See `bridgehead-outcome.log`.

**Visual: NOT_RUN. Owner art: ART_REVIEW_REQUIRED (prior overall rejection remains).
M5: DEVICE_NOT_RUN. Performance, 2K/4K and original-speed action video: NOT_RUN.**
The parent is arranging standard hosted actual Godot capture because local X
server startup could not establish listening sockets. Headless success is not
visual approval. Do not replace RC24/RC25 rollback packages with this checkpoint.

Resume: run the structure and terrain tests, then actual `world_master_review.gd`
at native 2560x1440/internal 1.0 and its 3840x2160 capture. Compare seed 61112,
ticks 50/135, 22 m camera, 512 per side against the same RC25 baseline. Reject or
revise canopy occlusion, shore contact and palette before candidate acceptance.
