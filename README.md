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

**Canonical handoff, 2026-11-08:** [Owner's locked product decisions](docs/PRODUCT_DECISIONS.md) → [owner's nine resolved creative decisions](docs/OWNER_CREATIVE_DECISIONS_PENDING.md) → [Pro final game design](docs/FINAL_GAME_DESIGN_SPEC.md) → [narrative and visual direction](docs/NARRATIVE_ART_DIRECTION.md) → [Tang-inspired politics and captivity narrative proposal](docs/NARRATIVE_WORLD_BIBLE_V0_2.md) → [simulation architecture contracts](docs/SIMULATION_CONTRACTS.md) → [acceptance matrix](docs/ACCEPTANCE_MATRIX.md) → [Dot direct-cloud handoff](docs/DOT_HANDOFF_FINAL.md). Historical/stage references: [delivery gates](docs/DELIVERY_PLAN.md), [full vision completion](docs/FINAL_VISION_ACCEPTANCE.md), [first independent code review](docs/PRO_TECH_REVIEW_001.md), [Dot cloud bootstrap](docs/DOT_BOOTSTRAP.md), [AGENTS.md](AGENTS.md), [initial game bible](docs/PRO_DESIGN_BIBLE.md), [original game vision](docs/GAME_VISION.md).

## Status

Godot 4.6.3 playable prototype implemented. A world-backed depot encounter now reserves actual soldiers and weapons, advances one clock and settles casualties/equipment exactly once in-process. Training remains a separate 20-vs-20 scene. Reproducible combat, world, transaction and routed scene tests are in `tools/test.sh`. See [verification](docs/VERIFICATION.md) for actual results and limitations.

### Play from source

1. Install Godot 4.6.3 (standard edition).
2. Import `project.godot`, then press F6/F5 or run `godot --path .`.
3. WASD/arrows move, mouse aims, left click or J strikes. Q performs a sweeping cut, E lunges, Space braces (75% damage reduction for 2.6 seconds).
4. 1 orders attack, 2 follow, 3 retreat. To withdraw, lead surviving troops to the green gate at the left edge. P/Esc pauses, H toggles help. R begins new training **after** it ends; in campaign combat R returns to the map without resetting casualties.

The standalone training battle has 20 friendly soldiers, 20 enemy soldiers, and one separately counted commander. The commander's death ends the encounter. Fallen soldiers remain in the casualty ledger; only a new encounter resets it.

### Reproduce tests

```sh
./tools/test.sh
```

The test script runs editor import, pure simulation tests and the full scene's scripted smoke run. Runtime logs are written to ignored `artifacts/`. No game plugins, purchased services or third-party art are required.

**macOS M5 device gameplay and final subjective quality remain unverified.**

## Licensing

No open-source license has been selected. A public repository does not itself grant a license to reuse its code or assets.

### Build and play the macOS package

Install the official matching Godot 4.6.3 export templates, then run `./tools/export.sh`.
`builds/Luanshi-macOS.zip` contains a universal `.app` with both Apple Silicon arm64 and Intel x86_64 code. The game uses Godot's built-in **ad-hoc** signature, not an Apple Developer ID certificate, and is **not notarized**.

Unzip and open the app. If macOS blocks this downloaded prototype, only approve it if you trust this project: after attempting to open it, use System Settings → Privacy & Security → Open Anyway if macOS offers that option. Do not disable Gatekeeper globally. You can instead run the source project in an official Godot editor. Actual M5 performance remains untested.

The repository's [Actions](../../actions) workflow tests and packages each prototype change. Its downloadable artifacts contain the macOS ZIP, a Linux executable, test logs, hashes and, when graphical CI succeeds, an actual rendered screenshot. GitHub may require sign-in to download Actions artifacts. This is a prototype artifact, not a public production release.

[中文试玩说明](docs/PLAYING_ZH.md) · [Current resumable project status](docs/PROJECT_STATUS.md) · [World simulation foundation](docs/WORLD_SIM.md) · [Battle transaction contract](docs/BATTLE_TRANSACTIONS.md).

Press **M** to open the three-city campaign. Travel the river route for three hours and **Assault Hequ depot** to fight a real roster: 20 of the army's 60 people (including its commander) versus 15 actual defenders. With 30 weapons in the 60-person army, the deployment contains 10 armed and 10 genuinely unarmed people; 40 remain reserves. The outcome updates the same world once, including actual time, dead people, recovered/destroyed equipment and depot ownership. Physical retreat preserves survivors. Commander death ends the campaign after settlement. **R returns to the map, not a battle restart.** Explicit New Campaign is separate from training replay. Local city production now uses actual civilian labor, farmland/workshops and stability, with continuous integer work accrual and separate civilian/military food consumption. The local map shows effective rates and siege stoppage; no remote economic truth is leaked. Persistent save/load, hunger fatigue stages and the complete narrative remain pending. This is a reversible prototype under the final design, not owner approval of all creative choices or completion of the full game.

[Population economy and 90-day verification](docs/ECONOMY.md): fixed city output is replaced by constrained production. Original rescue timelines remain covered; demographic quantities and rates are compressed provisional test values, not final historical balance.
