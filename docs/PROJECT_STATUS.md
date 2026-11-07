# Project status / resumable handoff

## Current objective

Continue autonomous implementation toward `FINAL_VISION_ACCEPTANCE.md`, using the existing Godot prototype. A first playable or first short campaign is not the full project. Preserve the last passing build; no paid services, extra accounts, user computer, Codex tasks or formal release without authorization.

## Current branch and source

- Working branch: `prototype/cloud-first-playable`, PR #1.
- First playable: `98576db`; exports/scene tests: `5426efa`; camera/input/visual-CI repair: `8109761`; design merge: `7d8ea81`; supported native macOS runner: `bf2052f`.
- Main design contracts through `65a46ce` are merged into this branch, retaining code and resolving only the README status paragraph in favor of the more recent factual implementation record.
- Primary work directory: repository root. Commands: `./tools/test.sh`, `./tools/export.sh` with matching Godot 4.6.3 templates.

## Passed and pending

- Passed: Godot 4.6.3 import; 33 combat + 35 scene/input/camera + 526 WorldSim assertions (594 total); deterministic army battle; real scene scripted battle; macOS universal ZIP export/static arm64+x86_64 inspection; exported Linux headless run.
- A real Ubuntu/Xvfb/llvmpipe render and screenshot were inspected. This exposed a HUD-covered field edge and excess brightness; corrected in `8109761`, awaiting repeated graphical CI verification.
- CI's first graphical run failed on absent audio hardware; the test-only Dummy audio fix passed.
- Native macOS 26.7.2 arm64 CI and strict ad-hoc signature verification passed in run 42417350572. User M5 device performance, manual gameplay feel and owner approval remain unverified. No Developer ID signing/notarization or production release.
- WorldSim foundation implemented with three causal scenarios, resource/in-transit convoy conservation, delayed intelligence and 96h test coverage. It remains separate from the playable battle scene.
- The 20v20 simulation remains O(n²); no large-army performance claim.

## Next executable milestones

1. Finish the current WorldSim foundation commit and check CI for that exact head; preserve the standalone battle artifact.
2. Add a playable three-city strategic interface reading only `WorldSim.player_view()`, with route, wait, resupply, scout and local depot actions. Keep the existing battle scene available.
3. Add explicit army-to-battle roster creation and exactly-once casualty/equipment settlement, then versioned save/load and short narrative progression.
4. Evaluate Mobile rendering on a supported graphical runner before claiming anything about iPhone/GPU performance. Do not optimize to unmeasured army sizes.

## Continuation procedure

At each wake, first fetch current GitHub state and read this file plus latest `AGENTS.md` and design contracts. Check active work, uncommitted changes, PR head and exact-commit CI before starting another worker. Continue the smallest unfinished milestone. Run tests, commit verified changes and record concrete results. Do not blindly re-run an uncertain publication or overwrite concurrent design edits. If a tool/session limit stops work, commit safe progress and leave the exact next command and blocker here. Routine user review is optional and does not halt development.

This repository preserves resumable state; it cannot guarantee uninterrupted compute or remove platform limits. The parent conversation owns any supported scheduled continuation.
