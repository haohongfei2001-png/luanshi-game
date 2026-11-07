# First playable verification

## Environment and tested stage

- Own Linux x86_64 cloud computer; Godot `4.6.3.stable.official.7d41c59c4`.
- No Codex coding task, no access to the user's Mac, no paid resources.
- Source: Godot 3D scene, pure seeded simulation, device-action adapter, placeholder unit geometry and interactive HUD.
- 20 friendly soldiers + 20 enemies + 1 player commander. Movement, directional strike, sweeping cut, spear lunge, brace, attack/follow/retreat, death, extraction and results implemented.

## Actual commands and results

`XDG_DATA_HOME=/workspace/shared/godot-data XDG_CONFIG_HOME=/workspace/shared/godot-config XDG_CACHE_HOME=/workspace/shared/godot-cache ./tools/test.sh`

All commands exited 0 with no Godot script errors:

1. `godot --headless --path . --editor --import`: passed.
2. `godot --headless --path . --script tests/test_battle.gd`: **33 assertions, 0 failures**. Includes movement/bounds, attack facing, cooldowns, all three skills, order effects, retreat/extraction, casualty accounting, protagonist death, reset, deterministic replay and battle completion.
3. `godot --headless --path . --fixed-fps 60 --script tests/test_scene.gd`: **35 assertions, 0 failures**. Tests live action binding, movement, synthetic keyboard and mouse events routed through the Viewport, pause/no casting while paused, button layout non-overlap, all battlefield corners/heads staying outside the HUD, death/results and restart cleanup.
4. `godot --headless --path . --fixed-fps 60 -- --smoke-scene`: real scene initialized, all 41 unit views and HUD instantiated, basic strike + three skills and attack/follow commands exercised. Scripted victory at 6.87 simulated seconds: friendly 20 survivors / 0 fallen, enemy 0 survivors / 20 fallen, commander 131.45 HP. This is scripted integration coverage, not a human playtest.

Seed 184, armies fighting while the commander initially stays away: 37.35 simulated seconds; friendly 0 survivors / 20 fallen, enemy 5 survivors / 15 fallen. The survivors then killed the commander. The encounter correctly ended the run. Two repeats produced identical result dictionaries.

Measured CPU simulation cost: approximately 0.64 ms per fixed step in the army test; 1.62 ms per step inside the scripted scene. These values are cloud CPU timings, **not rendered frame rates or MacBook Air performance**.

## Verification boundaries

- Code written: yes.
- Headless editor import / simulation / scene lifecycle: passed.
- Local visual gameplay exercised: **no**. The environment has no display. Official Debian Xvfb was obtained, but X11 cannot create its Unix socket (`EPERM`), including with the supported elevated execution attempt. No security restriction was bypassed.
- Native macOS runtime, Apple M5 performance, signing and notarization: **not tested**.
- macOS export: **passed**, universal ZIP with arm64 and x86_64 slices, valid Info.plist, packed game and executable permissions confirmed. Built-in ad-hoc code signing completed; no Developer ID signing or notarization. Official 4.6.3 export templates SHA-512 verified.
- Linux export: **passed**; exported binary independently ran the same headless scene and reached the same victory result.
- CI rendered the real scene with Mesa llvmpipe on Ubuntu and produced an actual screenshot. Inspection exposed a HUD-covered southern edge and over-bright ground; the camera and lighting were corrected, with eight new projection assertions. The first visual job logged a missing audio-device error after completing the battle; automated rendering now explicitly selects the Dummy audio driver. The corrected graphical rerun and native macOS CI are pending, not assumed passed.
- iPhone/Xcode/signing: deferred, not claimed.

## Technical tradeoffs / next executable step

Compatibility rendering is the initial conservative desktop default. Mobile rendering must be evaluated separately; the lack of an authorized graphical display prevents an honest cloud visual/performance comparison. Inputs and authoritative simulation remain independent of presentation and device bindings.

Export command: `XDG_DATA_HOME=/workspace/shared/godot-data XDG_CONFIG_HOME=/workspace/shared/godot-config XDG_CACHE_HOME=/workspace/shared/godot-cache ./tools/export.sh`. Both platform exports, exported Linux smoke and static macOS archive verification exited 0.

The first export exposed a real configuration failure (arm64 requires ETC2/ASTC import); this was fixed by enabling that setting before the passing rerun. A new scene integration test initially exposed a GDScript inferred-type parse issue in the test itself; an explicit Node type fixed it and all 68 assertions then passed.

Next: inspect CI evidence and fix any issues; then request a ten-minute hands-on review of movement, skills and orders. Native Mac playtesting and graphical frame-time measurements remain separate acceptance levels.
