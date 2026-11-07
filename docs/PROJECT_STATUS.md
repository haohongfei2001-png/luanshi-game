# Project status / resumable handoff

## Current objective

Continue autonomous implementation toward `FINAL_VISION_ACCEPTANCE.md`, using the existing Godot prototype. A first playable or first short campaign is not the full project. Preserve the last passing build; no paid services, extra accounts, user computer, Codex tasks or formal release without authorization.

## Current branch and source

- Working branch: `feature/world-battle-transactions`, PR #2, following merged PR #1. The original playable and strategic foundation are preserved in main merge `bfb028a`.
- First playable: `98576db`; exports/scene tests: `5426efa`; camera/input/visual-CI repair: `8109761`; design merge: `7d8ea81`; supported native macOS runner: `bf2052f`; WorldSim foundation: `50dc3be` (CI 42417682607 passed both jobs).
- Main design contracts and pending creative-decision caveats through `bfb028a` are merged into this branch, retaining code and resolving only the README status paragraph in favor of the more recent factual implementation record.
- Primary work directory: repository root. Commands: `./tools/test.sh`, `./tools/export.sh` with matching Godot 4.6.3 templates.

## Passed and pending

- Passed: Godot 4.6.3 import; 33 combat + 35 scene/input/camera + 36 strategic UI + 526 WorldSim + 293 transaction + 63 campaign scene assertions (986 total); deterministic army battle; real scene scripted battle; macOS universal ZIP export/static arm64+x86_64 inspection; exported Linux headless run.
- A real Ubuntu/Xvfb/llvmpipe render and screenshot were inspected. This exposed a HUD-covered field edge and excess brightness; corrected in `8109761`, repeated graphical CI passed in run 42418269168.
- CI's first graphical run failed on absent audio hardware; the test-only Dummy audio fix passed.
- Native macOS 26.7.2 arm64 CI and strict ad-hoc signature verification passed in run 42417350572. User M5 device performance, manual gameplay feel and owner approval remain unverified. No Developer ID signing/notarization or production release.
- WorldSim foundation has causal scenarios, physical convoy conservation, delayed intelligence and 96h coverage. The M-key campaign now uses real reserved roster/equipment for depot combat, fractional time, persistent commander HP and in-process exactly-once settlement. Separate training is clearly labeled. Save/load is still pending.
- The 20v20 simulation remains O(n²); no large-army performance claim.

## Next executable milestones

1. v0.3 real roster/equipment, exact clock and once-only settlement: all 986 source/scene assertions and both actual-combat smoke runs pass. Source `0383e85` passed full CI run 42419804675: actual campaign launch/combat/retreat/map screenshots inspected, Linux exported runs, native macOS 26.7.2 arm64 training and campaign runs, strict ad-hoc signature. Local v0.3 macOS SHA256 `43661e6f89ae36f72dc73aaaac1bfac54fdf83b45779228846ceac80c0ecbc35`.
2. Next smallest G2 gap: replace fixed food production with population/workable-land/state-limited production and multi-month conservation tests (ECO-03).
3. Add visible shortage → fatigue/morale → attrition progression for marching forces with deterministic tests (ECO-04). Do not call G2 fully passed before both gaps are demonstrated.
4. Then add versioned campaign save/load, including pending events and battle receipts/session state, before claiming WRL-07/LIF-02/TECH-03 across process restart. Continue to knowledge-driven NPC and short narrative progression.
5. Evaluate Mobile rendering on a supported graphical runner before claiming anything about iPhone/GPU performance. Do not optimize to unmeasured army sizes.

## Continuation procedure

At each wake, first fetch current GitHub state and read this file plus latest `AGENTS.md` and design contracts. Check active work, uncommitted changes, PR head and exact-commit CI before starting another worker. Continue the smallest unfinished milestone. Run tests, commit verified changes and record concrete results. Do not blindly re-run an uncertain publication or overwrite concurrent design edits. If a tool/session limit stops work, commit safe progress and leave the exact next command and blocker here. Routine user review is optional and does not halt development.

This repository preserves resumable state; it cannot guarantee uninterrupted compute or remove platform limits. The parent conversation owns any supported scheduled continuation.

## Current final-spec acceptance alignment

Canonical design authority is now PRODUCT_DECISIONS v2 → FINAL_GAME_DESIGN_SPEC → NARRATIVE_ART_DIRECTION / SIMULATION_CONTRACTS / ACCEPTANCE_MATRIX → DOT_HANDOFF_FINAL. The new main documents were merged without replacing implementation. Three equal pillars, WASD/mouse controls, restrained realism and hard-but-fair outcomes are preserved.

- COM-01..05 / TECH-01..02: automated and rendered evidence exists; manual gameplay quality remains pending, not owner-approved.
- ECO-01: inventory scarcity/transfer and world-sourced visible unarmed units are implemented and regression-tested. Campaign 60 includes commander; 20 deploy with 10 weapons, 40 remain reserve.
- ECO-02 / WRL-01..04 / FAIR-01: tested inventory transport, off-screen state and causal scenarios; timings currently use a compressed hourly test scenario.
- ECO-03: PARTIAL. Production is ledgered but fixed-rate; population/land-dependent production and multi-month coverage remain next work.
- ECO-04: PARTIAL. Hunger clocks and eventual attrition exist; explicit fatigue/morale warning stages remain next work.
- WRL-07 / TECH-03: PARTIAL. Real army/battle transaction, locks, authoritative result validation, rollback, casualty/equipment audit and duplicate rejection pass in-process. Durable save/reload of transaction state is not implemented, so full acceptance remains pending.
- G2 is therefore a tested foundation, not a claim that all final-matrix G2 acceptance is complete.
- Strategic UI is implemented with 36 synthetic input assertions plus 63 campaign lifecycle assertions: opening/closing preserves battle time, HP and casualties; only player_view data is rendered; world reset does not reset battle. Actual graphical screenshot reviewed from run 42418269168: readable 1280×800 layout, route and supply actions visible, historical intelligence distinct from local observation.

## Latest handoff received

The final PR #1 comment (6713522579) and latest merged main `bfb028a` were read, including the concurrent `OWNER_CREATIVE_DECISIONS_PENDING.md` additions. Pro defaults for high-level creative questions remain PROVISIONAL; they are not owner sign-off. The simulation transaction contracts now guide the next change. User asks for quiet autonomous work: routine progress belongs in this repository; contact only for reserved permissions or unavoidable blockers. No claim that the full game is finished.

## v0.3 review fixes

Independent review found and repaired fractional route/report deadlines (a battle must not shorten later travel) and commander life consistency when coarse starvation removes the final person. Regression coverage includes exact deadlines, second-resolution intelligence freshness, autonomous world ticking after death with player commands blocked, and post-apply settlement rollback. No known high/medium transaction defect remains after review; CI/render/build proof for this new source is recorded separately when complete.
