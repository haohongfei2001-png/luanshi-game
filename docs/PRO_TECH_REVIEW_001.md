# Pro independent review 001 — first cloud prototype
Date: 2026-11-08
Reviewed: `prototype/cloud-first-playable` at `98576dba`, including `scripts/battle_sim.gd`, `scripts/battle.gd`, `scripts/input_actions.gd`, `tests/test_battle.gd`, and `docs/VERIFICATION.md`.

## Verdict
**Good early engineering basis; not yet a visually confirmed playable product.** Keep and iterate on the existing prototype. Do not rewrite the engine or promise large armies based on 20v20 CPU tests.

### Verified from code/reported logs
- Simulation is separate from scene, input and presentation. This is the correct seam for future strategy-world integration.
- Protagonist and two 20-soldier rosters, directional melee, cooldowns, three skills, commands, health/death, and deterministic seeded simulation tests exist.
- Author reported 33 passing assertions and headless Godot 4.6.3 scene startup. These were **reported by the developer**; this independent document review did not re-run Godot.
- Public PR #1 and a branch commit are present. macOS visual runtime, native M5 performance, interactive feel, app signing and iPhone are **not verified**.

### Engineering risks to resolve progressively
1. **Scaling is not demonstrated.** `_nearest_enemy` scans all units per unit and separation loops all unit pairs; both are quadratic. Fine for 40 soldiers, but measure before 100s; introduce spatial partitioning (uniform grid or similar) when benchmarks justify it.
2. **A scripted smoke pass is not a gameplay pass.** The script dispatches automated combat actions and runs headlessly; it does not prove controls, camera framing, character readability, animation timing, or visible FPS. Do not label those verified.
3. **The battle is standalone.** City resources, actual inventories, world clock, NPC intelligence, saves and continuous campaign state are not implemented. Do not prematurely declare the RPG/world loop complete.
4. **Casualty counts currently come from one fixed-size battle roster.** Future world integration must source roster composition and armament from actual army records and commit survivors, injuries, lost/recovered equipment, and spoils exactly once.
5. **Risk of art polish outpacing mechanics.** Keep placeholder geometry until one visually witnessed playtest shows that movement, strike, skills and commands are legible and controllable.
6. **Visual testing environment limitation is real.** Cloud has no working display socket (per developer log). Continue headless test/export work, explore supported browser-render or hosted demo paths if allowed, and keep device-runtime checks separate.

### Recommended next autonomous actions
- Confirm a stable export and artifact procedure; produce a Mac-targeted unsigned test bundle and a reproducible Linux headless run for regression verification.
- Update first-run instructions and verify the user's target device doesn't require manual engine installation to launch the app, if a self-contained bundle can be created.
- Add battle input/action telemetry and small combat KPI logging without overly constraining gameplay (time to first hit, command latency, surviving units, frame-time when rendered).
- After packaging, develop the simplest true WorldSim state and off-screen city-fall scenario, **without replacing the existing combat prototype**.
- Update branch with latest design contracts from `main` before expanding further. Preserve user's policy: Dot direct development, no Codex by default.

## Gate status
- Gate 0 (cloud coding and automated tests): evidence exists; **partially met** for deliverable verification pending a self-contained artifact.
- Gate 1 (combat): functionality coded and headless tested; **visual/gameplay acceptance pending**.
- Gate 2+ (world narrative): not implemented.

This review is advisory and does not replace a human gameplay evaluation or Godot execution.
