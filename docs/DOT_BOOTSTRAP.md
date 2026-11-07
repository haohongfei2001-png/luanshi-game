# Dot autonomous cloud-development bootstrap (initial milestone archive)

**Dot has already started developing PR #1. For ongoing work, use docs/DOT_HANDOFF_FINAL.md and docs/PRODUCT_DECISIONS.md first, not the old first-task checklist below.**

> This file is an instruction for the user's **Dot**, not a request to create Codex tasks.

## Operating mode

- **Own the implementation directly on your own cloud computer.** Use your available cloud shell/editor, Godot runtime, and connected GitHub plugin or git workflow.
- **Do not delegate work to Codex**, Work coding tasks, or the user's Mac by default. Request the user's approval before changing this constraint.
- Repository: `https://github.com/haohongfei2001-png/luanshi-game` (public). Read `README.md`, `AGENTS.md`, and `docs/GAME_VISION.md` first.
- Keep project files, instructions, and progress in the repository. Commit tested changes in small steps. Avoid secrets, private data, and unlicensed assets.
- Do not purchase anything, register paid services, or publish binaries outside the agreed GitHub project without the user's authorization.

## First assignment: prove the cloud development loop

1. Inspect what development tools are available in **your own cloud machine** (terminal, git, download/network permission, display/GPU availability). Report actual capabilities; do not assume.
2. Install or run a compatible **Godot 4** editor/runtime and its export templates if feasible. Prefer a plain text-oriented **GDScript** project.
3. Create a minimal 3D project with an oblique/top-down camera. Make it runnable in Godot; use placeholders and a simple ground plane initially.
4. Add a controllable player character with movement, basic attack, and three small nonmagical skills.
5. Add two soldier squads and a 20-vs-20 combat demonstration. Units should acquire targets, approach, attack, lose health, die, and follow basic attack/follow/retreat commands. Report the survivors after a battle.
6. Add basic repeatable smoke tests, a headless project import/run check, and documented execution commands. For gameplay requiring a display, use your cloud desktop if available; if not, clearly label it **not visually verified**.
7. Push code to GitHub. Provide the commit/PR, actual test results, and an artifact or tested build whenever possible.
8. Try a macOS export using official Godot templates when feasible. If exporting from Linux, prefer a portable `.zip` where supported. **Do not claim native macOS runtime verification, signing, notarization, or on-device performance without actual tests**.
9. Keep iPhone touch controls as a future adaptation: separate input actions from device-specific mappings; do not attempt iOS/Xcode signing during the initial prototype.

## Acceptance criteria

- Source-controlled Godot project that a new checkout can load.
- Verified startup/import with concrete commands and exit codes.
- An interactable battle scene or an explicit blocker explaining why it could not be run.
- One player, basic attack, three skills, two small armies, basic orders, casualties and a results display.
- Clear distinction between **code written**, **headless tests passed**, **visual gameplay exercised**, **export completed**, and **run on Mac tested**.
- No promises of a million individually simulated units, full campaign, or complete game yet.

## Reporting format

Update the repository (short commit notes or status document) after completed milestones. Send the user a compact progress summary with:
- What changed
- Evidence (commit/PR, build, tests, optional video/screenshots)
- What failed or remains unverified
- Next smallest executable task

When a required permission or cloud tool is unavailable, ask for that **specific approval** instead of switching to Codex or local development.
