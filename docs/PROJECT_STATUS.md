# Project status / resumable handoff

## Current objective

Continue autonomous implementation toward `FINAL_VISION_ACCEPTANCE.md`, using the existing Godot prototype. A first playable or first short campaign is not the full project. Preserve the last passing build; no paid services, extra accounts, user computer, Codex tasks or formal release without authorization.

## Current branch and source

- Working branch: `prototype/cloud-first-playable`, PR #1.
- First playable: `98576db`; exports/scene tests: `5426efa`; camera/input/visual-CI repair: `8109761`; design merge: `7d8ea81`; supported native macOS runner: `bf2052f`; WorldSim foundation: `50dc3be` (CI 42417682607 passed both jobs).
- Main design contracts through `69f309b` are merged into this branch, retaining code and resolving only the README status paragraph in favor of the more recent factual implementation record.
- Primary work directory: repository root. Commands: `./tools/test.sh`, `./tools/export.sh` with matching Godot 4.6.3 templates.

## Passed and pending

- Passed: Godot 4.6.3 import; 33 combat + 35 scene/input/camera + 37 strategic UI + 526 WorldSim assertions (631 total); deterministic army battle; real scene scripted battle; macOS universal ZIP export/static arm64+x86_64 inspection; exported Linux headless run.
- A real Ubuntu/Xvfb/llvmpipe render and screenshot were inspected. This exposed a HUD-covered field edge and excess brightness; corrected in `8109761`, awaiting repeated graphical CI verification.
- CI's first graphical run failed on absent audio hardware; the test-only Dummy audio fix passed.
- Native macOS 26.7.2 arm64 CI and strict ad-hoc signature verification passed in run 42417350572. User M5 device performance, manual gameplay feel and owner approval remain unverified. No Developer ID signing/notarization or production release.
- WorldSim foundation implemented with three causal scenarios, resource/in-transit convoy conservation, delayed intelligence and 96h test coverage. A playable M-key strategic sandbox now exposes routes, waiting, local observation, inventory transfers and depot capture. It explicitly remains a separate scenario from battle until settlement integration.
- The 20v20 simulation remains O(n²); no large-army performance claim.

## Next executable milestones

1. Verify the current v0.2 strategic UI CI screenshot and native macOS package, repair issues and preserve the latest tested artifact.
2. Add explicit army-to-battle roster creation and exactly-once casualty/equipment settlement, then versioned save/load and short narrative progression.
3. Complete ECO-03 population/land production and ECO-04 visible fatigue/morale stages before calling the final-matrix G2 fully passed.
4. Evaluate Mobile rendering on a supported graphical runner before claiming anything about iPhone/GPU performance. Do not optimize to unmeasured army sizes.

## Continuation procedure

At each wake, first fetch current GitHub state and read this file plus latest `AGENTS.md` and design contracts. Check active work, uncommitted changes, PR head and exact-commit CI before starting another worker. Continue the smallest unfinished milestone. Run tests, commit verified changes and record concrete results. Do not blindly re-run an uncertain publication or overwrite concurrent design edits. If a tool/session limit stops work, commit safe progress and leave the exact next command and blocker here. Routine user review is optional and does not halt development.

This repository preserves resumable state; it cannot guarantee uninterrupted compute or remove platform limits. The parent conversation owns any supported scheduled continuation.

## Current final-spec acceptance alignment

Canonical design authority is now PRODUCT_DECISIONS v2 → FINAL_GAME_DESIGN_SPEC → NARRATIVE_ART_DIRECTION / ACCEPTANCE_MATRIX → DOT_HANDOFF_FINAL. The new main documents were merged without replacing implementation. Three equal pillars, WASD/mouse controls, restrained realism and hard-but-fair outcomes are preserved.

- COM-01..05 / TECH-01..02: automated and rendered evidence exists; manual gameplay quality remains pending, not owner-approved.
- ECO-01: state-level weapon scarcity/transfer tests passed; world-sourced visible unarmed units still pending integration.
- ECO-02 / WRL-01..04 / FAIR-01: tested inventory transport, off-screen state and causal scenarios; timings currently use a compressed hourly test scenario.
- ECO-03: PARTIAL. Production is ledgered but fixed-rate; population/land-dependent production and multi-month coverage remain next work.
- ECO-04: PARTIAL. Hunger clocks and eventual attrition exist; explicit fatigue/morale warning stages remain next work.
- WRL-07 / TECH-03: NOT RUN. Exactly-once real army/battle settlement is not yet implemented.
- G2 is therefore a tested foundation, not a claim that all final-matrix G2 acceptance is complete.
- Strategic sandbox UI is implemented with 37 synthetic input assertions: opening/closing preserves battle time, HP and casualties; only player_view data is rendered; world reset does not reset battle. Current graphical CI screenshot review remains pending until recorded.
