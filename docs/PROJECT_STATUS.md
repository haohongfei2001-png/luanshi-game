# Project status / resumable handoff

## Current objective

Continue autonomous implementation toward `FINAL_VISION_ACCEPTANCE.md`, using the existing Godot prototype. A first playable or first short campaign is not the full project. Preserve the last passing build; no paid services, extra accounts, user computer, Codex tasks or formal release without authorization.

## Current branch and source

- Working branch: `prototype/cloud-first-playable`, PR #1.
- First playable: `98576db`; exports/scene tests: `5426efa`; camera/input/visual-CI repair: `8109761`.
- Main design contracts through `65a46ce` are merged into this branch, retaining code and resolving only the README status paragraph in favor of the more recent factual implementation record.
- Primary work directory: repository root. Commands: `./tools/test.sh`, `./tools/export.sh` with matching Godot 4.6.3 templates.

## Passed and pending

- Passed: Godot 4.6.3 import; 33 simulation + 35 scene/input/camera assertions; deterministic army battle; real scene scripted battle; macOS universal ZIP export/static arm64+x86_64 inspection; exported Linux headless run.
- A real Ubuntu/Xvfb/llvmpipe render and screenshot were inspected. This exposed a HUD-covered field edge and excess brightness; corrected in `8109761`, awaiting repeated graphical CI verification.
- CI's first graphical run completed combat but failed on absent audio hardware. Test-only Dummy audio is configured for the rerun.
- Native macOS CI and corrected graphical artifact: pending. User M5 device performance, manual gameplay feel and owner approval: unverified. No Developer ID signing/notarization or production release.
- The 20v20 simulation remains O(n²); no large-army performance claim.

## Next executable milestones

1. Complete corrected graphical CI and packaged macOS CI. Inspect the actual image and log, repair failures, update the downloadable prototype and this record.
2. Implement pure `WorldSim`: three cities, two factions, hourly clock, inventories, siege food depletion, army marching, delayed intelligence and three deterministic relief/supply scenarios. Keep the existing battle scene intact.
3. Add a playable strategic interface and an explicit battle-to-world transaction with exactly-once casualty/equipment accounting; then saves and short narrative progression.

## Continuation procedure

At each wake, first fetch current GitHub state and read this file plus latest `AGENTS.md` and design contracts. Check active work, uncommitted changes, PR head and exact-commit CI before starting another worker. Continue the smallest unfinished milestone. Run tests, commit verified changes and record concrete results. Do not blindly re-run an uncertain publication or overwrite concurrent design edits. If a tool/session limit stops work, commit safe progress and leave the exact next command and blocker here. Routine user review is optional and does not halt development.

This repository preserves resumable state; it cannot guarantee uninterrupted compute or remove platform limits. The parent conversation owns any supported scheduled continuation.
