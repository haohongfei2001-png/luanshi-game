# Luanshi (working title)

An experimental single-player game set in a fictional ancient Chinese dynasty.

## Vision

A character-driven war RPG with MOBA-style isometric 3D combat, soldiers who require real supplies, strategic army command, and a world that continues to evolve outside the player's view. The protagonist grows older and can die. Death concludes that playthrough; saves and major-life checkpoints allow replay.

The goal is **not** to build the full game immediately. Our first milestone is a small, testable, playable **macOS** prototype, with iPhone/iOS support considered from the start but not yet a release requirement.

## Initial prototype

- One controllable 3D character with movement, basic attack, and three skills
- Two teams of soldiers in a small battlefield (target 20 vs 20 initially)
- Basic follow / attack / retreat commands
- Actual casualties carried into a simple after-battle report
- A repeatable build and test workflow

Out of scope for the initial milestone: a nationwide map, city economies, complex NPC politics, and a million independently simulated soldiers.

## Autonomous development

**Primary developer: the user's Dot, directly on its own cloud computer.** Dot should use its cloud shell/editor and the connected GitHub repository to write, run, test, and commit game code. **Do not delegate coding to Codex by default; Codex is opt-in only with explicit user approval.** No access to the user's MacBook is required for normal cloud coding. Native Mac performance validation is a separate step.

Godot 4 and GDScript are the provisional choices. Platform: macOS first (Apple Silicon preferred for initial validation); iPhone/iOS is a future target. Keep input handling and UI layout adaptable for touch controls. Engine choice should be revisited only after a focused technical benchmark, not based on speculation.

**Canonical handoff, 2026-11-08:** [Owner's locked product decisions](docs/PRODUCT_DECISIONS.md) → [Pro final game design](docs/FINAL_GAME_DESIGN_SPEC.md) → [narrative and visual direction](docs/NARRATIVE_ART_DIRECTION.md) → [simulation architecture contracts](docs/SIMULATION_CONTRACTS.md) → [acceptance matrix](docs/ACCEPTANCE_MATRIX.md) → [Dot direct-cloud handoff](docs/DOT_HANDOFF_FINAL.md). Historical/stage references: [delivery gates](docs/DELIVERY_PLAN.md), [full vision completion](docs/FINAL_VISION_ACCEPTANCE.md), [first independent code review](docs/PRO_TECH_REVIEW_001.md), [Dot cloud bootstrap](docs/DOT_BOOTSTRAP.md), [AGENTS.md](AGENTS.md), [initial game bible](docs/PRO_DESIGN_BIBLE.md), [original game vision](docs/GAME_VISION.md).

## Status

Dot is developing the initial 3D prototype on `prototype/cloud-first-playable` ([PR #1](https://github.com/haohongfei2001-png/luanshi-game/pull/1)), with cloud headless tests and export checks reported on that branch. **macOS M5 device gameplay and final subjective quality remain unverified.** Main contains the canonical frozen design contracts.

## Licensing

No open-source license has been selected. A public repository does not itself grant a license to reuse its code or assets.
