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
3. `godot --headless --path . --fixed-fps 60 -- --smoke-scene`: real scene initialized, all 41 unit views and HUD instantiated, basic strike + three skills and attack/follow commands exercised. Scripted victory at 6.87 simulated seconds: friendly 20 survivors / 0 fallen, enemy 0 survivors / 20 fallen, commander 131.45 HP. This is scripted integration coverage, not a human playtest.

Seed 184, armies fighting while the commander initially stays away: 37.35 simulated seconds; friendly 0 survivors / 20 fallen, enemy 5 survivors / 15 fallen. The survivors then killed the commander. The encounter correctly ended the run. Two repeats produced identical result dictionaries.

Measured CPU simulation cost: approximately 0.64 ms per fixed step in the army test; 1.62 ms per step inside the scripted scene. These values are cloud CPU timings, **not rendered frame rates or MacBook Air performance**.

## Verification boundaries

- Code written: yes.
- Headless editor import / simulation / scene lifecycle: passed.
- Visual gameplay exercised: **no**. The environment has no display. Official Debian Xvfb was obtained, but X11 cannot create its Unix socket (`EPERM`), including with the supported elevated execution attempt. No security restriction was bypassed.
- Native macOS runtime, Apple M5 performance, signing and notarization: **not tested**.
- macOS export: preparation in progress; official 4.6.3 export templates downloaded and their SHA-512 verified.
- iPhone/Xcode/signing: deferred, not claimed.

## Technical tradeoffs / next executable step

Compatibility rendering is the initial conservative desktop default. Mobile rendering must be evaluated separately; the lack of an authorized graphical display prevents an honest cloud visual/performance comparison. Inputs and authoritative simulation remain independent of presentation and device bindings.

Next: export unsigned macOS universal ZIP and Linux binary; run the exported Linux binary headlessly; add reproducible export checks. Native Mac playtesting and graphical frame-time measurements remain separate acceptance levels.
