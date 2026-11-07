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
- Native macOS arm64 headless runtime: **passed** on the standard hosted macOS 26.7.2 arm64 runner. `codesign --verify --deep --strict` also passed for the built-in ad-hoc signature. Apple Developer ID signing, notarization, graphical Mac gameplay and the user's M5 performance remain **unverified**.
- macOS export: **passed**, universal ZIP with arm64 and x86_64 slices, valid Info.plist, packed game and executable permissions confirmed. Built-in ad-hoc code signing completed; no Developer ID signing or notarization. Official 4.6.3 export templates SHA-512 verified.
- Linux export: **passed**; exported binary independently ran the same headless scene and reached the same victory result.
- CI rendered the real scene with Mesa llvmpipe on Ubuntu and produced an actual screenshot. Inspection exposed a HUD-covered southern edge and over-bright ground; the camera and lighting were corrected, with eight new projection assertions. The first visual job logged a missing audio-device error after completing the battle; automated rendering now explicitly selects the Dummy audio driver. The corrected graphical rerun passed; native macOS CI also passed after replacing the unsupported macos-14 runner configuration with the supported standard macos-latest image.
- iPhone/Xcode/signing: deferred, not claimed.

## Technical tradeoffs / next executable step

Compatibility rendering is the initial conservative desktop default. Mobile rendering must be evaluated separately; the lack of an authorized graphical display prevents an honest cloud visual/performance comparison. Inputs and authoritative simulation remain independent of presentation and device bindings.

Export command: `XDG_DATA_HOME=/workspace/shared/godot-data XDG_CONFIG_HOME=/workspace/shared/godot-config XDG_CACHE_HOME=/workspace/shared/godot-cache ./tools/export.sh`. Both platform exports, exported Linux smoke and static macOS archive verification exited 0.

The first export exposed a real configuration failure (arm64 requires ETC2/ASTC import); this was fixed by enabling that setting before the passing rerun. A new scene integration test initially exposed a GDScript inferred-type parse issue in the test itself; an explicit Node type fixed it and all 68 assertions then passed.

Next: inspect CI evidence and fix any issues; then request a ten-minute hands-on review of movement, skills and orders. Native Mac playtesting and graphical frame-time measurements remain separate acceptance levels.

## Verified hosted rendering and native macOS

Successful complete run: https://github.com/haohongfei2001-png/luanshi-game/actions/runs/42417350572 (source head `bf2052f`, same gameplay as `8109761`; design contracts preserved by merge `7d8ea81`).

- Ubuntu software OpenGL/Xvfb real scene: passed and actual screenshot inspected. 390 measured rendered frame intervals after startup: mean 83.48 ms, p50 81.57 ms, p95 99.59 ms (about 12 FPS on **llvmpipe CPU rendering**, not a GPU/M5 benchmark). The full scripted sequence took approximately 35 seconds of rendering for 6.87 simulated seconds with fixed-delta automation.
- macOS 26.7.2 arm64: self-contained app signature verification and actual headless execution passed, victory at 6.87 seconds. This is not evidence of M5 device gameplay or macOS rendered performance.
- Actual logs are in `docs/evidence/visual-smoke.log` and `docs/evidence/native-macos.log`.
- The package now also carries engine/dependency redistribution notices generated by Godot's built-in license APIs; no game open-source license has been selected.

## Gate 2 foundation (not yet a playable campaign)

`godot --headless --path . --script tests/test_world.gd`: **526 assertions, 0 failures**. Combined local suite: **594 assertions, 0 failures** plus scene smoke. WorldSim has three cities, two factions, 60 relief troops with only 30 weapons, real production/consumption/inventory transfers, hourly marches, 5-hour supply convoys and returns, off-screen siege, delayed frozen intelligence and local-only visibility.

- Direct relief arrives h6: city saved, 7 relief soldiers lost and 36 food consumed.
- Waiting 10h then taking the same route: city falls off-screen h15; arrival h16 cannot rewrite it.
- Taking the river and seizing the depot h3 costs 4 soldiers. Convoys already in transit still arrive; later exhaustion forces the besiegers to withdraw h10.
- Tests also prove slow-route and unarmed failures, no route-name automatic victory, in-transit resource conservation, source/timestamp-aware reports, deterministic replay and 96h progression.

See `docs/WORLD_SIM.md` for interfaces and known model limits. No strategic UI, campaign save/load or exactly-once battle-to-world casualty settlement is claimed yet. These are the next implementation tasks, not a reason to stop the long-term project.

## v0.2 playable strategic sandbox

`godot --headless --path . --fixed-fps 60 --script tests/test_strategy.gd`: **37 assertions, 0 failures**, via synthetic keyboard and mouse events through the real Viewport. All local suites now total **631 assertions, 0 failures**. M/click entry opens the strategic UI without resetting the battle, preserves pause state and casualties, and blocks combat actions while open. Routes, hour advances, local observation, food/weapons transfers, depot seizure and independent reset call actual WorldSim commands. Only `player_view()` reaches the UI.

A separate graphical CI script (`tests/strategy_visual.gd`) exercises the route/arrival/depot/observation flow and captures the actual interface. That current-head graphical check is pending, not inferred from headless success. The interface explicitly states that it is an independent scenario and that battle-world settlement/saves are not implemented yet.

## v0.2 strategic interface verification

Source `e476d0feef5d4c106bb0898bc0a034522421f414`, [CI run 42418269168](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/42418269168): all 631 assertions, real Xvfb/llvmpipe battle and strategic scene renders, universal macOS packaging and native macOS 26.7.2 arm64 headless runtime passed. Strict built-in ad-hoc signature verified. Actual strategy screenshot inspected after routing to Hequ, seizing the depot and observing at hour3. This is not a Mac M5 graphical performance or human gameplay-feel test. Strategic scenario is still separate from battle in this version. Local v0.2 macOS ZIP SHA256: `de28a379e92680fdcb71abb769da6f7882a067cac7b1d8bdc2581823de117c80`.

## v0.3 world-backed battle: local verification

Cloud Linux, Godot 4.6.3, `./tools/test.sh` with matching shared XDG template/cache paths: 33 combat + 526 WorldSim + 293 transaction + 35 scene + 36 strategy + 63 campaign assertions = **986 passed, zero failures**. Both standalone and world-backed real scene smoke passed; neither smoke injects deaths. Campaign smoke result: 396 steps, 6.6 simulated seconds, 19 regular survivors plus commander, 15 actual enemy dead, commander 202.5 HP, relief 60 people/45  weapons/102 food, world time 10806.6 seconds; enemy 15 weapons transferred from the depot, no duplicate settlement mutation.

Independent review reproduced and fixed two defects before publication: fractional battle time shortened later marches/reports; aggregate starvation could exhaust all 60 people without ending the counted commander's life. Added regressions for exact deadlines, precise GUI ETA, within-hour intelligence freshness, final-survivor death, world autonomy after death, and atomic rollback. Reviewer reran all 986 assertions successfully.

Artifacts: `docs/evidence/transaction-tests.log`, `campaign-tests.log`, `campaign-smoke.log`. Graphical campaign render and this version's native macOS runtime remain pending until CI is linked below. In-process transaction success does not imply save/reload acceptance; persistence, ordinary soldier wounds, full economy and NPC/story systems are still pending.

## v0.3 actual graphical and native evidence

Source `0383e85f1fea6c9fb2db3bd0a4f77a00423d83b5`: [CI 42419804675](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/42419804675) passed Ubuntu and macOS jobs. Three actual screenshots inspected: deployed 20-vs-15 roster with 10 empty-handed allies, live combat, and physical retreat back into the same strategic world at 10804.1833 seconds. Controls, counts, equipment, history timestamps and result feedback are readable without HUD obstruction. Placeholder art is not final-art acceptance.

Actual X11/llvmpipe combat frame sample: 374 frames after warmup, mean 61.964 ms, p50 60.680 ms, p95 67.398 ms (about 16 FPS on CPU software rendering). This is neither a GPU nor Mac M5 performance measurement. macOS 26.7.2 arm64 CI verified strict ad-hoc signature and ran both exported training and real campaign headlessly; campaign outcome matches Linux. No Developer ID, notarization, user-device access or formal release.

Local exported universal v0.3 ZIP SHA256: `43661e6f89ae36f72dc73aaaac1bfac54fdf83b45779228846ceac80c0ecbc35`. Native evidence: `docs/evidence/campaign-native-macos.log`; graphics: `docs/evidence/campaign-visual.log`. Still pending: durable saves, full G2 economy/hunger, NPC/narrative, M5 sustained graphics/thermals and human feel.

## v0.4 population economy: source verification

Cloud Linux, Godot 4.6.3, full `./tools/test.sh`: **1,534 functional assertions passed**, plus the persisted independent property script `tests/test_economy_properties.gd` (36 seeded parameter/horizon scenarios, one partial-hour city capture, 52,194 per-event/invariant checks). Both actual-combat smoke runs pass unchanged. Exact functional suites: 33 combat, 526 world, 527 economy, 293 transactions, 35 scene, 57 strategic UI, 63 campaign scene.

The economy run covers 90 days with ledger/event reconstruction: 12,960 food produced, 13,828 consumed, 269 weapons produced, final 500 food/50 civilians. No original causal-rescue assertion was weakened. Invalid shapes, noninteger/negative fields, excessive rate inputs, maximum stock/ledger headroom and fractional clocks are covered. An independently reproduced cap defect was fixed before publication.

GUI checks prove only local population/production is displayed, clear it in transit, show genuine siege stoppage and resumed production, keep precise fractional output, preserve readable minimum controls and provide scrolling. Actual graphical/native evidence for this version is pending until recorded. Rates and initial demographic scale are PROVISIONAL, not final design approval.

To avoid repeatedly rebuilding identical executables for proof-only changes, CI ignores changes confined to docs, README and AGENTS. Source/config/workflow changes still run the full test/graphics/export/native pipeline. A documentation-only evidence commit can reference its tested code ancestor only after its diff is verified to contain no game/build change.
