# Delivery plan: from prototype to complete small game (v0.1)

This document contains historical milestone definitions. **Latest Owner override (2026-11-12): Codex is authorized and is now the primary developer.** The present first-release target is `docs/BATTLE_FIRST_V1_OWNER_SPEC_20261112.md`, with B0–B4 in `docs/CODEX_BATTLE_FIRST_EXECUTION_HANDOFF.md`; old 20v20 / story-first gates remain regression/history only. Codex authorization does not grant new spending, personal Mac control, extra accounts, formal release or publishing license changes.

## Definition of success

Success at the **new Owner-defined combat V1** is an actually playable, clear and compelling macOS war game with a MOBA-scale map, 512v512 true fighting units, weapon/horse/chariot/siege/command/mission systems and real M5 60fps performance evidence. A fully written story and nationwide/modern history are **not** prerequisites to this battle-first V1. Prior low-scope prototypes remain useful regression stages, not the new release acceptance.

Primary target: macOS on Apple Silicon (reference: M5 MacBook Air). iPhone is a possible future port. Do not require the user's Mac as a routine development machine.

## Current active B0–B4 plan — battle first, NO authored story

**The following now overrides the milestone order below, which remains a historical reference.**
- **B0**: inherit old code/PR #10, repair actual macOS font/CI and keep v0.6 saves; start 512v512 stress test and CPU/GPU profiling immediately.
- **B1**: mature 3D character with visible face/hands/clothes/weapons; nine distinct weapon movesets and hit timing; horse/chariot foundations; real playable combat feel.
- **B2**: 512v512 persistent combat soldiers, formations, specialized troop types, interpolation/navigation/animation LOD/instance optimizations without freezing offscreen casualties; 100/250/512 per side are increasing benchmarks.
- **B3**: one highly polished map with terrain/fortifications, prebattle commander tasks, flag/horn/courier orders, autonomous commanders, siege and non-annihilation objective conditions.
- **B4**: complete original/legally licensed art and sound, tested native macOS export, ≥20-minute M5 512v512 battle performance aiming 60 FPS, actual gameplay recording and truthful QA. **No fiction plot production until Owner authors it.**
- All B* criteria are bound to `docs/BATTLE_FIRST_V1_OWNER_SPEC_20261112.md §8` and `docs/ACCEPTANCE_MATRIX.md §7F`; smaller prototypes and CI alone cannot be labeled the final current V1.
- This game remains ambitious and may require extensive optimization; **do not quietly lower the target**. Record true partial progress and any device blocker and continue the maximum feasible engineering work.

## Project stages and strict gates

### Gate 0 — Confirm real autonomous execution
- Verify the Dot cloud machine's actual shell, git, write permissions, and Godot 4 runtime.
- Create and commit a minimal Godot project, with instructions and automated smoke-test command.
- Distinguish import/headless execution, visual runtime, macOS export, and device testing. Do not claim unperformed tests.
- **Pass:** a fresh checkout can import the project and execute the documented smoke test, with an actual commit and log.
- **Fail/blocked:** explain the exact missing capability, not a conceptual plan. Do not silently hand coding to Codex.

### Gate 1 — A fun combat core
- Small 3D oblique/top-down scene, move player, basic attack, three nonmagical skills.
- 20 allied vs 20 enemy soldiers can find, approach, attack, die; basic follow/attack/retreat squad orders.
- Display battle results including survivors and casualties.
- Test 20v20 for frame time, pathing, stability; placeholders are acceptable.
- **Pass:** reproducible gameplay build (or clearly documented export limitation), actual gameplay evidence where the cloud environment permits, tests, and an optional demo for the owner. If human visual feedback isn't yet available, mark it pending, continue autonomously with measurable work, and do not claim gameplay feel is user-approved.
- **Do not expand** to cities, aging, or rich art until combat control and orders function.

### Gate 2 — Small consistent world
- Three cities, two factions, one unified clock, marching routes, food, weapons, troops, one siege or interception scenario.
- World advances off-screen; city can fall before a relief force arrives.
- Simulated truth and NPC/player information are separate; delayed reports reflect real events.
- Deterministic test seeds demonstrate different outcomes caused by altered action/arrival timing.
- **Pass:** at least three reproducible scenarios with logs: timely relief, late relief, and a different supply/route decision. Inventory and casualty accounting remain consistent.

### Historical Gate 3 — Connected 30–60-minute vertical slice (deferred authored story; NOT current combat-first acceptance)
- Recruitment, equipment allocation, supplies, marching, combat, casualties/spoils, post-battle status, return to strategic view.
- 4–6 meaningful named NPCs, condition-triggered dialogue/portraits, one crisis with at least two meaningfully different outcomes.
- Protagonist mortality, run-ending epilogue, load a previous save/checkpoint. Aging may initially be simplified if 30–60-minute slice cannot demonstrate a full lifespan.
- **Pass:** a complete 30–60-minute replayable path from introduction to conclusion; a new user can play without reading developer documentation.

### Historical Gate 4 — First complete small game (shipping candidate; superseded by current battle V1)
- Target a compact **1–3-hour** narrative campaign rather than an enormous open world.
- Suggested scope ceilings (not mandatory targets): 3–6 strategic settlements; roughly 6–12 named characters; two usable weapon archetypes; a few infantry types; a handful of major battles.
- Gameplay must include at least one meaningful decision each involving battle tactics, logistics, uncertain intelligence, and a person's interests.
- User interface, tutorial/onboarding, volume/options, saving/loading, accessibility basics, crash handling, error logs, clear credits/licenses.
- macOS distributable, versioned release, legally licensed/owned art/audio, QA checklist and regression tests.
- **Pass:** the game can be installed/run on reference Mac, played from start to finish, saved/loaded, and restarted; known critical defects are resolved. Explicitly distinguish developer-tested from owner-approved. Public launch and any paid distribution require owner approval.

### Gate 5 — Expansion toward the originally envisioned larger game (after Gate 4; continue autonomously unless authorization is required)
- Benchmark larger formations and command hierarchy; decide whether visible numbers scale to 100v100, 500+, etc.
- Expand political/aging/economic systems only where the small game proves they improve decisions and storytelling.
- Evaluate iPhone touch UI, performance, Xcode/signing requirements **as a separate port milestone**.
- Million-scale armies may exist as aggregate strategic records; do not promise a million independent onscreen 3D soldiers.

### Gate 6 — One-life compressed historical wars (new long-term owner target)

After the core action/army/world game and initial rich-life narrative are actually playable, add conditional epoch pressures as specified in `CENTURY_WAR_ERA_CAMPAIGN_V0_1.md`: Tang-like provincial collapse → unification → northern rivals → territorial halving/naval last stand or reconquest → capital choice/central-local power → taxation, peasant rebellion and northern invasion → foreign steam/naval shock.

- Do **not** require all players to reach every stage. A reproducible **high-success same-protagonist** route must eventually be achievable within ordinary old age, without invulnerability or inheritance control.
- Do **not** force every historical defeat or rebuild an old enemy without political/army continuity. A conquered polity may fall while the surviving player continues a human life.
- Introduce separate capital/fiscal/logistics and multi-dimensional research/manufacture/equipment systems with real costs; an open/technology-focused polity can outperform a Qing-like baseline somewhat, not instantly become a fully industrial 20th-century empire.
- Sea battles and large armies require their own real benchmarks, assets, controls and tests; early world-only abstract simulations are permitted pending graphics implementation.
- **Pass**: objective evidence for the `ERA-01..12` acceptance cases, including at least one valid from-age-15-to-modern-threat career replay. Not a requirement for Gate 1–4 and not a reason to interrupt Dot's current coding.

## Non-negotiable discipline

- One authoritative simulation state; scene visuals cannot invent soldiers, food, weapons, or battle outcomes.
- No fixed-script overrides of honest simulation results solely to force tragedy.
- Player/NPC actions may use incomplete information, while the world state remains causally consistent.
- Record a test command and result on each feature branch / milestone.
- Preserve usable saved builds and avoid breaking the last passing milestone.
- Use GitHub issues/PRs or a simple status file to track blockers, acceptance criteria, and next action. No need to create many labels or complex project boards.
- Keep cloud costs, third-party assets, credentials, and public releases subject to user approval.

## Minimum human involvement

Continue from one passed gate to the next without waiting for routine owner sign-off. Offer playable artifacts for voluntary user review, but do not block normal development merely because the user hasn't reviewed yet. Mark subjective gameplay/user approval as pending until actually obtained. Ask the owner only for new spending or accounts, extra device access/Codex delegation, fundamental product changes, publishing/signing, and a genuinely unavoidable blocker. Supply a default recommendation with the smallest required action. Refer to PRODUCT_DECISIONS.md for the exact escalation policy.

## Progress update schema

- Gate / version:
- Commit or PR:
- Exact commands/tests and actual results:
- Artifact / video link (if available):
- What remains unverified:
- Smallest next step:

## Scope-change rule

New requested features go into a backlog. Only change the current gate if they resolve a verified blocker or materially improve the core game loop. Ask for user decision when a change alters camera, platform, genre, mortality, simulation truth, or material system boundaries.
