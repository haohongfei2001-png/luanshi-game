# AI development instructions

This repository currently contains an early battle prototype, but the **long-term assignment is a complete single-player game** under docs/FINAL_VISION_ACCEPTANCE.md. Implement incrementally; do not mistake the first prototype for project completion.

## Execution mode — Dot cloud only

- The **primary implementer is the user's Dot itself**, working directly in its own cloud computer. Do not create or delegate coding tasks to Codex by default. Only use Codex after the user explicitly opts in.
- Work through the cloud machine's available terminal, browser/editor and connected GitHub permissions: check out the repository, install or run Godot 4 if supported, modify project files, run headless tests, and commit/push the results.
- Do not request access to the user's MacBook for routine development. The MacBook Air M5 is a **target test device**, not the development host.
- If the cloud environment lacks an editor, shell, network access, GitHub write permission, or the required Godot runtime, report the exact blocker and which approval/capability is needed; do **not** silently switch to Codex or local execution.
- Cloud code/test verification, visual gameplay verification, macOS export, and testing on a real Mac are distinct acceptance levels. A Linux cloud can run Godot headless tests and may export a macOS build with official templates, but **must not claim the Mac app has run on the user's machine**.
- Prefer a small, inspectable GitHub PR or commit series, a reproducible test log, and a downloadable build artifact when possible. Consider an optional browser-playable build if practical, without changing the primary macOS target.

## Product constraints

**Canonical current design and workflow:** read `docs/PRODUCT_DECISIONS.md`, `docs/FINAL_GAME_DESIGN_SPEC.md`, `docs/NARRATIVE_ART_DIRECTION.md`, `docs/ACCEPTANCE_MATRIX.md` and `docs/DOT_HANDOFF_FINAL.md` first. Older docs (`PRO_DESIGN_BIBLE.md`, `GAME_VISION.md`, `DOT_CONTINUOUS_DELIVERY.md`, `DELIVERY_PLAN.md`) are background or stage details; user decisions and current final spec take precedence. Preserve the existing Dot first-prototype work on `prototype/cloud-first-playable` rather than restarting from scratch. Read `docs/PRO_TECH_REVIEW_001.md` for early review findings.

Read `docs/GAME_VISION.md` before changing gameplay architecture. Do not silently replace the setting, camera, combat model, progression, world independence, or protagonist-death rule.

## Current scope and priorities

1. Produce a **playable, reproducible macOS prototype**. iPhone/iOS is a planned adaptation path, not a first-milestone delivery requirement.
2. First: one small 3D battlefield, a player-controlled isometric character, basic attack, three simple non-magical weapon skills, and 20 vs 20 tiny soldiers.
3. Make soldiers move, fight, die, and obey basic squad commands.
4. Record actual casualties and expose a simple results screen.
5. Keep a deterministic simulation harness where practical; do not add city-management or million-unit visualization until core combat is proven fun and technically feasible.

## Implementation

- Preferred provisional stack: **Godot 4 + GDScript**. Use a text-oriented project structure and placeholder geometry initially.
- **User-confirmed controls:** WASD moves the character, the mouse aims attacks and skills, and keyboard skill shortcuts trigger abilities. Use device-independent action semantics so future iPhone touch UI can reuse gameplay logic. The recommended prototype mapping is left click/J basic attack, Q/E/Space for three skills, and 1/2/3 for local orders; allow rebinding without changing the locked movement paradigm.
- Evaluate Godot's **Mobile renderer** early for a shared macOS/iPhone path; benchmark on actual hardware before choosing final renderer settings.
- A verified iOS build requires a macOS runner with Xcode and Apple signing configuration. Never commit certificates, provisioning profiles, credentials, or API keys. Do not claim an iOS build was verified unless it was actually built and tested.
- Preserve a clear separation between simulation data/state and visual presentation so a later world simulation can use the same state.
- Do not add dependencies, paid services, or external assets without checking their redistribution terms.
- Avoid premature complexity: prefer small modules, explicit interfaces, and clear data contracts over giant frameworks.
- The **three equally important final player experiences** are (1) personal realtime combat, (2) army command, and (3) autonomous world simulation. Phase work sequentially but do not omit any from final gameplay.
- **Locked art:** restrained realism in small detailed 3D figures, historically grounded material scarcity, readable equipment silhouettes, not flashy armor. Use placeholders until mechanics are verified.
- **Locked difficulty:** hard but fair and explainable; no hidden scripted cheats, forced battlefield loss, magically arriving troops, or unjustified information leaks.
- Never commit credentials, account data, API keys, or unlicensed assets. This repository is **public**.
- Keep commits small and purposeful; use branches and pull requests for major changes.
- Do not represent an untested system as complete. Distinguish: written code, editor-loadable, successfully built, and gameplay-tested.

## Reference test hardware

- Primary local reference: **MacBook Air with Apple M5** (Apple Silicon, fanless). Do **not** assume a particular RAM configuration; the M5 Air exists in multiple memory and GPU configurations.
- The first build must be playable on this Mac; verify arm64 macOS export and report whether it was tested on real hardware or only in an automated environment.
- Benchmark 20-vs-20 first. Record frame rate and frame time during a sustained gameplay session; avoid high-cost effects and expensive per-unit AI/physics unless measured. Prefer conservative graphics and scalable settings due to the fanless chassis.
- Keep input actions platform-independent for a later iPhone version. iOS export / signing requires a macOS machine with Xcode and suitable Apple credentials; don't commit credentials or claim iOS has been tested before device verification.

## Verification after each meaningful change

- State the exact command and environment used to run any automated test or export.
- Add tests for pure simulation logic where feasible.
- Report what was **actually verified** (including failures), what was not verified, and the next concrete action.
- Maintain concise instructions for running the game in the README once a runnable project exists.

## Acceptance criteria for the first prototype

A fresh checkout can launch a 3D combat scene. The user can move, basic-attack, and use three skills. Two small soldier teams can fight each other. The player can issue a minimal set of squad commands. Units have health, casualties persist through the encounter, and the results screen reports survivors and casualties. A minimal performance measurement and reproducible test/build report are included.

**Not accepted:** mock screenshots only, unconnected scripts, an untested project, or prose claiming a complete game without a playable artifact.
