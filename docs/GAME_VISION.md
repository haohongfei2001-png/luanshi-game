# Game vision — working design constraints (v0.1)

## Confirmed direction

- **Setting:** fictional ancient Chinese dynasty, informed by real historical logistics, society, equipment, and warfare; no fixed historical outcome.
- **Genre:** single-player story-driven RPG plus freely evolving war simulation.
- **Presentation:** small, visually detailed, MOBA-sized **3D** characters in an oblique / isometric top-down camera. Dialogue can use portraits, brief animations, and story illustrations.
- **Player action:** movement, simple basic attack, a few active weapon skills, equipment and attribute/skill upgrades; capable of defeating many weaker opponents through skill but not invulnerable.
- **Army:** recruit, win over, organize, equip, command, and fight alongside soldiers. Real casualties, injury, morale, retreat, and surrender matter.
- **Economy:** material scarcity. Food, weapons, armor, animals, and manpower have locations, owners, sources and costs. Supplies can be acquired by control of settlements, taking spoils, requisition, or plunder. Settlements produce resources over time; war can destroy production.
- **Time and mortality:** the protagonist ages, suffers injuries and illness, and can die in battle or from age and disease. Death **ends the run**, with a limited epilogue constrained by what could be known. Players may restart or load a prior save / major-life checkpoint.
- **World autonomy:** off-screen cities, generals, factions, armies, and events continue to develop; no plot armor and no teleporting resources.
- **Knowledge:** separate objective world state from what the player and NPCs know. Scouting and messengers have delay, uncertainty, and fallibility.
- **NPCs:** meaningful characters act from perceived interests, relationships, ethics, risks, and limited knowledge. Betrayal and surrender are not one-number loyalty dice rolls.
- **Narrative:** authored characters/conflicts and conditional dramatic events, while military results and character fates follow simulation and player choices. Hard choices, frequently costly victories, and uncertain outcomes; not mandatory scripted tragedy.
- **Scale:** begin with a few soldiers and small battles. Larger armies later if story, military authority, performance, and clarity justify them. Strategic totals in the hundreds of thousands or millions do **not** mean each soldier is a fully simulated visible 3D entity.

## Provisional product decisions (reversible)

- **macOS desktop first** (MacBook Air M5 is the reference test device); **iPhone/iOS is a future platform candidate**. Maintain device-independent game actions and layout flexibility from the first prototype. A native iOS build needs macOS/Xcode/signing and must not be claimed as verified unless actually tested.
- **Execution model:** Dot directly writes, builds, and tests via its own cloud computer and connected GitHub. Codex is not part of the default workflow and must not be delegated to without explicit user authorization. Do not require access to the user's MacBook for ordinary implementation.
- Godot 4 + GDScript first, unless a short empirical benchmark demonstrates an important limitation.
- Real-time close combat and local orders; larger formations receive orders through commanders and simplified simulation.
- One unified clock; different simulation granularity for battle, travel, logistics, and seasonal production.
- One authoritative world state. Real-time battle uses snapshots/instances sourced from real army records and commits losses and spoils back after battle.
- Save files capture world state, delayed intelligence, event queues, important persons, and random generation state sufficiently to preserve causal consistency.

## First playable milestone

**Not** the full game. Produce a demonstrable **macOS** top-down 3D combat prototype: a player character, basic attack, three simple skills, 20 friendly and 20 enemy soldiers, basic squad commands, health/death, and a casualty report. Use placeholders at first.

Later experimental slice: three cities, two factions, 4–6 decision-making NPCs, actual inventories and supplies, delayed scouting, and a relief mission where the city can fall before the player arrives.

## Explicitly deferred

Nationwide maps, deep bureaucracy, thousands of individual full NPC simulations, full city industrial supply chains, extensive skill trees, dynastic succession, procedural infinite story, and promises of one million separately simulated on-screen soldiers.

## Design quality bar

Each feature should enhance at least one of: (1) tactile combat, (2) causal world consistency, (3) meaningful human behavior, or (4) consequences of the player's choices. Otherwise defer it.
