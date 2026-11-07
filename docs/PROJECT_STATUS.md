# Project status / resumable handoff

## Current objective

Continue autonomous implementation toward `FINAL_VISION_ACCEPTANCE.md`, using the existing Godot prototype. A first playable or first short campaign is not the full project. Preserve the last passing build; no paid services, extra accounts, user computer, Codex tasks or formal release without authorization.

## Current branch and source

- Working branch: `feature/hunger-progression`, following merged PR #4 (main `ca3f21a`). The original playable/strategic foundation is preserved in `bfb028a`; real campaign transactions and their evidence in `0be9e51`.
- First playable: `98576db`; exports/scene tests: `5426efa`; camera/input/visual-CI repair: `8109761`; design merge: `7d8ea81`; supported native macOS runner: `bf2052f`; WorldSim foundation: `50dc3be` (CI 42417682607 passed both jobs).
- Main design contracts through `99d8ef0` are merged, including Tang-inspired political/material culture, live captivity, causal court/friend behavior and the explicit provisional status of major cast/story proposals. Existing code is preserved.
- Primary work directory: repository root. Commands: `./tools/test.sh`, `./tools/export.sh` with matching Godot 4.6.3 templates.

## Passed and pending

- Passed: Godot 4.6.3 import; 33 combat + 35 scene/input/camera + 94 strategic UI + 526 WorldSim + 527 economy + 337 military-condition + 293 transaction + 63 campaign scene assertions (1,908 total), plus 36 independently seeded economy property scenarios/partial-hour capture continuity and 2,689 independent military-condition oracle checks; deterministic army battle; real scene scripted battle; macOS universal ZIP export/static arm64+x86_64 inspection; exported Linux headless run.
- A real Ubuntu/Xvfb/llvmpipe render and screenshot were inspected. This exposed a HUD-covered field edge and excess brightness; corrected in `8109761`, repeated graphical CI passed in run 42418269168.
- CI's first graphical run failed on absent audio hardware; the test-only Dummy audio fix passed.
- Native macOS 26.7.2 arm64 CI and strict ad-hoc signature verification passed in run 42417350572. User M5 device performance, manual gameplay feel and owner approval remain unverified. No Developer ID signing/notarization or production release.
- WorldSim foundation has causal scenarios, physical convoy conservation, delayed intelligence and 96h coverage. The M-key campaign now uses real reserved roster/equipment for depot combat, fractional time, persistent commander HP and in-process exactly-once settlement. Separate training is clearly labeled. Save/load is still pending.
- The 20v20 simulation remains O(n²); no large-army performance claim.

## Next executable milestones

1. v0.3 real roster/equipment, exact clock and once-only settlement: all 986 source/scene assertions and both actual-combat smoke runs pass. Source `0383e85` passed full CI run 42419804675: actual campaign launch/combat/retreat/map screenshots inspected, Linux exported runs, native macOS 26.7.2 arm64 training and campaign runs, strict ad-hoc signature. Local v0.3 macOS SHA256 `43661e6f89ae36f72dc73aaaac1bfac54fdf83b45779228846ceac80c0ecbc35`.
2. v0.4 ECO-03 is merged in PR #4 / `ca3f21a`. Source `0c8e240` passed CI 42422010645: actual rendered local-economy controls inspected, Linux exports and native macOS arm64 headless training/campaign plus strict ad-hoc signature passed. See VERIFICATION.md. Last passing artifact remains available while ECO-04 is developed.
3. ECO-04 core and three-line own-army UI are implemented. Independent review passed; 337 condition assertions plus 2,689 independent checks prove genuine safe recovery and bounded progressive loss. The UI has 94 assertions, including visible warnings before loss and full initial controls. Next: exact-source graphical warning screenshot, export/native CI, then retain artifact and merge.
4. Then add versioned campaign save/load, including pending events and battle receipts/session state, before claiming WRL-07/LIF-02/TECH-03 across process restart. Continue to knowledge-driven NPC and short narrative progression.
5. Evaluate Mobile rendering on a supported graphical runner before claiming anything about iPhone/GPU performance. Do not optimize to unmeasured army sizes.

## Continuation procedure

At each wake, first fetch current GitHub state and read this file plus latest `AGENTS.md` and design contracts. Check active work, uncommitted changes, PR head and exact-commit CI before starting another worker. Continue the smallest unfinished milestone. Run tests, commit verified changes and record concrete results. Do not blindly re-run an uncertain publication or overwrite concurrent design edits. If a tool/session limit stops work, commit safe progress and leave the exact next command and blocker here. Routine user review is optional and does not halt development.

This repository preserves resumable state; it cannot guarantee uninterrupted compute or remove platform limits. The parent conversation owns any supported scheduled continuation.

## Current final-spec acceptance alignment

Canonical design authority is now PRODUCT_DECISIONS v3.1 → FINAL_GAME_DESIGN_SPEC → NARRATIVE_ART_DIRECTION / NARRATIVE_WORLD_BIBLE_V0_2 (proposals distinguished) / SIMULATION_CONTRACTS / ACCEPTANCE_MATRIX → DOT_HANDOFF_FINAL. The new main documents were merged without replacing implementation. Three equal pillars, WASD/mouse controls, restrained realism and hard-but-fair outcomes are preserved.

- COM-01..05 / TECH-01..02: automated and rendered evidence exists; manual gameplay quality remains pending, not owner-approved.
- ECO-01: inventory scarcity/transfer and world-sourced visible unarmed units are implemented and regression-tested. Campaign 60 includes commander; 20 deploy with 10 weapons, 40 remain reserve.
- ECO-02 / WRL-01..04 / FAIR-01: tested inventory transport, off-screen state and causal scenarios; timings currently use a compressed hourly test scenario.
- ECO-03: deterministic implementation PASS. Shared labor, farmland/workshops, stability/siege and integer monthly-rate accrual drive physical stocks. 90-day conservation and UI local-only rates pass; graphical/export/native evidence passed for `0c8e240` in CI 42422010645. Fixed population, compressed provisional rates and absent industrial inputs remain explicit limits.
- ECO-04: simulation/scene PASS, graphical/native evidence pending for this source. Proportional shortages, bounded fatigue/morale and delayed casualties, full safe-hour recovery, faction/garrison symmetry and detached visible condition are implemented. Long-battle modifiers are entry snapshots; individual physiology/desertion is future work. No live-force duplicate starvation deaths.
- WRL-07 / TECH-03: PARTIAL. Real army/battle transaction, locks, authoritative result validation, rollback, casualty/equipment audit and duplicate rejection pass in-process. Durable save/reload of transaction state is not implemented, so full acceptance remains pending.
- G2 is therefore a tested foundation, not a claim that all final-matrix G2 acceptance is complete.
- Strategic UI is implemented with 36 synthetic input assertions plus 63 campaign lifecycle assertions: opening/closing preserves battle time, HP and casualties; only player_view data is rendered; world reset does not reset battle. Actual graphical screenshot reviewed from run 42418269168: readable 1280×800 layout, route and supply actions visible, historical intelligence distinct from local observation.

## Latest handoff received

The final PR #1 comment (6713522579) and latest merged main `bfb028a` were read, including the concurrent `OWNER_CREATIVE_DECISIONS_PENDING.md` additions. Those previously pending high-level choices were subsequently resolved in main `82df117`; only implementation parameters remain provisional. The simulation transaction contracts now guide the next change. User asks for quiet autonomous work: routine progress belongs in this repository; contact only for reserved permissions or unavoidable blockers. No claim that the full game is finished.

## v0.3 review fixes

Independent review found and repaired fractional route/report deadlines (a battle must not shorten later travel) and commander life consistency when coarse starvation removes the final person. Regression coverage includes exact deadlines, second-resolution intelligence freshness, autonomous world ticking after death with player commands blocked, and post-apply settlement rollback. No known high/medium transaction defect remains after review; CI/render/build proof for this new source is recorded separately when complete.

## v0.4 economy scope and review

Production and civilian/military consumption now carry timestamped source events. Ninety days: 12,960 food produced, 13,828 eaten, 269 weapons produced, 500 food and 50 civilians remain. Existing relief/late/supply-interception scenarios still pass unchanged. Independent review fixed malformed economic schema, unsafe rate bounds and accepted numeric-cap advances that could otherwise leave invalid state. Headroom preflight rejects before mutation, including battle clocks and transfers. ECO-04 hunger/fatigue/morale is the current bounded code task.

## Owner decisions synchronized from main 82df117 / Issue #3

All nine high-level decisions are now recorded as resolved in PRODUCT_DECISIONS v3 section 1B and the historical PENDING filename. They do not require another user choice. Precision balance, demographics and rate values remain testable provisional parameters. Preserve the existing pipeline; finish G2 production and staged hunger first.

New acceptance tracking: OWNER-TIME-01 has current no-extra-time menu/reading and resource-conservation coverage; OWNER-HISTORY-01/02 have tested offscreen siege and route-dependent outcomes. These are partial evidence, not completion of all associated narrative behavior. OWNER-COMBAT-01 is NOT RUN: current strong commander profile is a legacy combat fixture, not proof of the approved early 1-vs-2 balance; introduce explicit early/late profiles and 1/2/5 enemy tests after G2. OWNER-ORDER-01..03 are NOT RUN: local order shortcuts exist, but physical remote couriers/interception/uncertain acknowledgment are not implemented. OWNER-SAVE-01 is NOT RUN. Continuous unpaused strategic clock, multi-month rest/story advancement, politics, aging, conditional major narrative nodes and later-scale acceptance remain pending. Keep Issue #3 open until its behavior has real code evidence.

## Latest narrative handoff / continuation

Read main `99d8ef0` before merging PR #4. Tang-inspired material culture replaces the earlier Han-Wei baseline. Court military/financial capacity may improve or decline through real events; living captivity must continue the run; friends have independent interests, knowledge and geographically valid reunions. These are implementation constraints, not permission to treat proposed emperors, cast or fixed story beats as finalized. The Anping fixture remains a mechanism test. New NAR-* acceptance rows are NOT RUN. No need to block G2 or ask routine questions while reusable systems are unfinished.

Current next work: run ECO-04 exact-source graphical/native CI, inspect warning screenshot, retain passing build and merge. Versioned campaign save core is already under implementation in an isolated successor branch; integrate only after deterministic resume and invalid-load review. Preserve owner decision Issue #3 until its behavior is genuinely covered.
