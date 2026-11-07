# AI development instructions

This repository contains a **small game prototype**, not an instruction to implement the entire proposed game in one pass.

## Product constraints

Read `docs/GAME_VISION.md` before changing gameplay architecture. Do not silently replace the setting, camera, combat model, progression, world independence, or protagonist-death rule.

## Current scope and priorities

1. Produce a **playable, reproducible macOS prototype**. iPhone/iOS is a planned adaptation path, not a first-milestone delivery requirement.
2. First: one small 3D battlefield, a player-controlled isometric character, basic attack, three simple non-magical weapon skills, and 20 vs 20 tiny soldiers.
3. Make soldiers move, fight, die, and obey basic squad commands.
4. Record actual casualties and expose a simple results screen.
5. Keep a deterministic simulation harness where practical; do not add city-management or million-unit visualization until core combat is proven fun and technically feasible.

## Implementation

- Preferred provisional stack: **Godot 4 + GDScript**. Use a text-oriented project structure and placeholder geometry initially.
- Separate user actions from input devices. Implement keyboard/mouse on macOS now; do not hardcode controls in gameplay logic so that touch UI and gestures can be introduced later.
- Evaluate Godot's **Mobile renderer** early for a shared macOS/iPhone path; benchmark on actual hardware before choosing final renderer settings.
- A verified iOS build requires a macOS runner with Xcode and Apple signing configuration. Never commit certificates, provisioning profiles, credentials, or API keys. Do not claim an iOS build was verified unless it was actually built and tested.
- Preserve a clear separation between simulation data/state and visual presentation so a later world simulation can use the same state.
- Do not add dependencies, paid services, or external assets without checking their redistribution terms.
- Avoid premature complexity: prefer small modules, explicit interfaces, and clear data contracts over giant frameworks.
- Use placeholder visuals until combat mechanics are verifiable; later visual design should use small, detailed, grounded ancient Chinese clothing and equipment, not exaggerated fantasy armor.
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
