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

## Tooling

Godot 4 and GDScript are the provisional choices. Platform: macOS first (Apple Silicon preferred for initial validation); iPhone/iOS is a future target. Keep input handling and UI layout adaptable for touch controls. Engine choice should be revisited only after a focused technical benchmark, not based on speculation.

AI development rules: see [AGENTS.md](AGENTS.md). Product constraints: see [docs/GAME_VISION.md](docs/GAME_VISION.md).

## Status

Repository initialized; game prototype not yet implemented.

## Licensing

No open-source license has been selected. A public repository does not itself grant a license to reuse its code or assets.
