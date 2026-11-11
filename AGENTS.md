# AI development instructions

This repository currently contains an early battle prototype, but the **long-term assignment is a complete single-player game** under docs/FINAL_VISION_ACCEPTANCE.md. Implement incrementally; do not mistake the first prototype for project completion.

## Execution mode — Codex primary, Dot optional coordination (Owner override 2026-11-12)

- The **primary implementer is now Codex**, explicitly authorized by the owner on 2026-11-12. Dot may help coordinate and track work but is **no longer the sole programmer**. Codex may independently edit, test, optimize and submit changes in already authorized repo/cloud development environments. Neither may access the user's Mac, spend money, publish a product, or modify licenses without separate approval. Avoid overlapping writes to the same working branch.
- Work through the cloud machine's available terminal, browser/editor and connected GitHub permissions: check out the repository, install or run Godot 4 if supported, modify project files, run headless tests, and commit/push the results.
- Do not request access to the user's MacBook for routine development. The MacBook Air M5 is a **target test device**, not the development host.
- If a development environment lacks editor, shell, network, GitHub write permission or a Godot runtime, record the exact blocker and choose an authorized Codex cloud environment; do **not** claim a task has been executed and do not silently switch to the user's local machine.
- Cloud code/test verification, visual gameplay verification, macOS export, and testing on a real Mac are distinct acceptance levels. A Linux cloud can run Godot headless tests and may export a macOS build with official templates, but **must not claim the Mac app has run on the user's machine**.
- Prefer a small, inspectable GitHub PR or commit series, a reproducible test log, and a downloadable build artifact when possible. Consider an optional browser-playable build if practical, without changing the primary macOS target.

## Product constraints

**Canonical current design and workflow:** recognize that OWNER-01..09 have now been directly answered by the user in `docs/PRODUCT_DECISIONS.md` section 1B and the historical tracker `docs/OWNER_CREATIVE_DECISIONS_PENDING.md` is resolved. Continue autonomously; do not ask the owner to choose those again. Implement high-attack but limited-HP hero progression, interceptable courier orders, time primarily via rest/travel/wait/story, non-optional war-era background with mutable battles, non-grindy changing world and free saves. Read `docs/PRODUCT_DECISIONS.md`, `docs/FINAL_GAME_DESIGN_SPEC.md`, `docs/NARRATIVE_ART_DIRECTION.md`, `docs/NARRATIVE_WORLD_BIBLE_V0_2.md`, `docs/ACCEPTANCE_MATRIX.md` and `docs/DOT_HANDOFF_FINAL.md` first. For world-time, inventories, delayed reports and battle-to-world integration, also read `docs/SIMULATION_CONTRACTS.md`. Older docs (`PRO_DESIGN_BIBLE.md`, `GAME_VISION.md`, `DOT_CONTINUOUS_DELIVERY.md`, `DELIVERY_PLAN.md`) are background or stage details; user decisions and current final spec take precedence. Preserve the existing Dot first-prototype work on `prototype/cloud-first-playable` rather than restarting from scratch. Read `docs/PRO_TECH_REVIEW_001.md` for early review findings.

Read `docs/GAME_VISION.md` before changing gameplay architecture. Do not silently replace the setting, camera, combat model, progression, world independence, or protagonist-death rule.

## Current scope and priorities — OWNER LOCKED 2026-11-12

**READ FIRST** `docs/BATTLE_FIRST_V1_OWNER_SPEC_20261112.md` and `docs/CODEX_BATTLE_FIRST_EXECUTION_HANDOFF.md`, then `docs/PRODUCT_DECISIONS.md §1F`. Existing 20v20 and three-city work is a **preserved engineering regression baseline**, not the accepted full first-release size.
1. Preserve v0.6 and current open PR #10, fix actual font/CI, save migration and macOS runtime issues before merging. Never restart Godot from scratch.
2. Produce **one** carefully crafted MOBA-scale isometric 3D battlefield, including a real siege/city/gate and terrain roles. Every visible nearby unit actually fights; offscreen units maintain causal state, even during camera pans.
3. **Initial release target: 512 vs 512 = 1024 independent combat soldiers** (excluding player/commanders/mounts), distinct troop types/gear, command hierarchy, prebattle missions, flags/horns/couriers, and non-annihilation outcomes.
4. Nine distinct player weapon kits: sword, dao, staff, spear, long blade, bow, crossbow, sword+shield, dual swords; plus horse combat, chariots and siege gear. Real weapon strikes, skill animations and appropriate counters, not reskins.
5. Visible face/hand/weapon/clothing detail at near camera; legible formations and equipment at wide camera. Target real **MacBook Air M5 sustained 60 FPS** at 512v512 with recorded graphic settings and frame times. Never claim device PASS without running on the target.
6. **No authored plot writing now.** One military opening/root and systemic objective templates only; owner will write all formal story later. Preserve future life/history architecture without implementing narrative branches prematurely.
7. Grow from 20v20 → 100v100 → 250v250 → 512v512 as benchmark gates, but smaller scales are not a substitute for the target. Record genuine gameplay, performance and Mac build evidence.

## 2026-11-12 Owner addendum: simpler individual soldiers are APPROVED

See `PRODUCT_DECISIONS.md §1G` and `BATTLE_FIRST_V1_OWNER_SPEC_20261112.md §1.1B`. The owner permits reducing **individual soldier intelligence** to minimal attack, defense, health, morale, weapon, position and basic state machines. Group tactics, orders, routes and adjustments should mainly be managed by officers/squads. Keep real hit/animation/casualty continuity, near-camera recognizable people and weapons, and the 512v512 target. Prioritize simplifying individual AI/physics/update rates over secretly shrinking army sizes or showing fake combat animation. Maintain real Mac M5 performance target; untested remains NOT_RUN.

## Implementation

- Preferred provisional stack: **Godot 4 + GDScript**. Use a text-oriented project structure and placeholder geometry initially.
- **User-confirmed controls:** WASD moves the character, the mouse aims attacks and skills, and keyboard skill shortcuts trigger abilities. Use device-independent action semantics so future iPhone touch UI can reuse gameplay logic. The recommended prototype mapping is left click/J basic attack, Q/E/Space for three skills, and 1/2/3 for local orders; allow rebinding without changing the locked movement paradigm.
- Evaluate Godot's **Mobile renderer** early for a shared macOS/iPhone path; benchmark on actual hardware before choosing final renderer settings.
- A verified iOS build requires a macOS runner with Xcode and Apple signing configuration. Never commit certificates, provisioning profiles, credentials, or API keys. Do not claim an iOS build was verified unless it was actually built and tested.
- Preserve a clear separation between simulation data/state and visual presentation so a later world simulation can use the same state.
- Do not add dependencies, paid services, or external assets without checking their redistribution terms.
- Avoid premature complexity: prefer small modules, explicit interfaces, and clear data contracts over giant frameworks.
- The **three equally important final player experiences** are (1) personal realtime combat, (2) army command, and (3) autonomous world simulation. Phase work sequentially but do not omit any from final gameplay.
- **Locked art:** restrained realism in small detailed 3D figures, **now informed by mid/late Tang material culture and late-Tang provincial armies** (the earlier Han-Wei default has been superseded), historically grounded scarcity, readable equipment silhouettes, not flashy armor. Use placeholders until mechanics are verified.
- **Future owner-authored narrative constraints (NOT current Codex content task):** the future story may begin around age fifteen, with military injustice, a company, command, alliances and family. All authoritative literary plotting/dialogue is reserved to the owner and **must remain blank in the current battle-first implementation**; see `docs/NARRATIVE_LIFE_ARC_V0_3.md` for future system compatibility only. Court can be militarily strong or weakened by actual wars; factions and frontier powers are morally complex; **rare capture while alive does not end the run**; reception by court after return depends on evidence and politics; important friends can become subordinates, rivals, enemies or reconcile based on their own interests and experiences. Canonical details in `docs/PRODUCT_DECISIONS.md` §1C. Main character names and particular fixed story beats in `docs/NARRATIVE_WORLD_BIBLE_V0_2.md` are creative proposals, not owner-approved final script.
- **Locked difficulty:** hard but fair and explainable; no hidden scripted cheats, forced battlefield loss, magically arriving troops, or unjustified information leaks.
- Never commit credentials, account data, API keys, or unlicensed assets. This repository is **public**.
- Keep commits small and purposeful; use branches and pull requests for major changes.
- Do not represent an untested system as complete. Distinguish: written code, editor-loadable, successfully built, and gameplay-tested.

## Long-term owner vision: compressed millennial wars in one lifetime

The owner added `docs/PRODUCT_DECISIONS.md` §1E and `docs/CENTURY_WAR_ERA_CAMPAIGN_V0_1.md` (2026-11-12). A strong/surviving **single** protagonist may experience Tang-style provincial wars and collapse, unification, northern rivals, half-country defense or counteroffensive, capital/tax/peasant-revolt/frontier double crises, and even an Opium-War-style industrial naval challenge in one naturally limited life. These are **conditional historical pressure archetypes, not forced outcomes or guaranteed defeat**.
- No instant dynasty/technology upgrades, forced Li-Zicheng events from tax toggles, magical revival of defeated northern enemies or political continuity between unrelated states without actual faction history.
- Beijing/Nanjing-style capital risk and tax/army-pay crisis must arise from geographically meaningful logistics/finance/politics.
- External technology evolves autonomously. An openness/technology-oriented player can gain some historically Qing-era comparative advantages, but cannot cheaply skip industrial and military prerequisites.
- All comprehensive `ERA-*` tests are **future expansion targets**. **Do not stop current G2/G3 youth-combat-world economy/save work** to implement sea warfare, steam engines or 1000-year scripts now. Preserve source/CI. The user writes the main literary plot.

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
