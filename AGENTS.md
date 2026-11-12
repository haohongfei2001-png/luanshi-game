# AI development instructions

This repository currently contains an early battle prototype, but the **long-term assignment is a complete single-player game** under docs/FINAL_VISION_ACCEPTANCE.md. Implement incrementally; do not mistake the first prototype for project completion.

## Owner performance decision: share ordinary soldier stats by batch and formation

Read `PRODUCT_DECISIONS.md §1O`, `SIMULATION_CONTRACTS.md §9G`, and `ACCEPTANCE_MATRIX.md §7F-H`. Ordinary soldiers do **not** each need unique attack, defense, morale or combat-compulsion values. Same troop/equipment/training batch shares static combat templates; squads/companies/armies share morale, compulsion, formation, orders and objectives. Keep unique soldier ID, position, movement/animation, actual wounds/death/capture/rout and genuinely different equipment/ammo. Use sparse overrides only for exceptional individuals. Important officers/heroes may be independent. Preserve individual visible movement and casualty causality; do not collapse the army into a fake aggregate count. Prefer template references, compact arrays and event-driven formation updates over per-soldier repeated dictionaries/psychology. Profile actual savings at 1k/3k/5k/10k.

## 2026-11-12 Owner decision: shared combat profiles and formation-level morale

Read `docs/PRODUCT_DECISIONS.md §1O`, `docs/SIMULATION_CONTRACTS.md §9G`, and `docs/ACCEPTANCE_MATRIX.md §7F-H`. **Do not give each ordinary soldier separate attack, defense, armor or morale values when a batch shares the same type/equipment/training.** Use shared troop/equipment CombatProfile references for static stats; Army shares authority/discipline/mission/compulsion and baseline morale; Company/Detachment shares current morale, cohesion, fatigue and local pressure. Aggregate army morale from formations. A soldier keeps only necessary unique identity, position/facing, action, current HP/wound/death/capture/rout, and genuinely different equipment/ammo. Shared stats do not mean a shared health bar: visible soldiers still take individual hits and die. No random per-soldier morale initialization or per-hit morale decrement; no copying the same static stats into thousands of Unit objects. Profile/group design should reduce CPU and memory; no mandatory ECS. Current `battle.gd` per-unit morale is a migration target after the visual P0, not a reason to interrupt the current art integration.

## 2026-11-12 Owner decision: morale, combat compulsion and distinct battle endings

Read `docs/PRODUCT_DECISIONS.md §1N`, `docs/BATTLE_MORALE_COMBAT_COMMITMENT_AND_OUTCOMES_V1.md`, `docs/SIMULATION_CONTRACTS.md §9F`, and `docs/ACCEPTANCE_MATRIX.md §7F-G`.

Battles can end through **annihilation, disorganized rout (with player pursuit/stop choice), organized strategic withdrawal, or surrender**, while existing objective wins (capture/hold/escort/rescue/breakout) remain possible with surviving enemies. Keep casualties, captives, surrendered, routed, withdrawn and surviving forces separate.

Two separate force/formation metrics:
- **Morale** changes combat effectiveness, formation cohesion, order obedience and gradually loyalty/desertion; losses, officer deaths, surprise, outnumbering, encirclement, lost objectives/retreat routes reduce it; rally, reinforcements, successful succession and secured goals can restore it. Zero morale triggers flight/disorganization attempts, not a magical all-army one-frame rout.
- **Combat compulsion** reflects authority/legitimacy (including local capital/regime prestige), discipline, mission necessity, command continuity/succession, and real retreat/surrender choices. It determines whether low-morale units hold, obey, resist or withdraw; it is not damage or a morale synonym.
A dead commander does not automatically win or rout an army: high local regime prestige and recognized deputy succession may preserve command; no successor + weak authority + low morale + encirclement may cause rout/surrender. After rout offer one simple pursue/halt choice. Ordinary soldiers remain cheap FSM; no player micro-management. Extend existing morale, objectives and officer-corps systems incrementally, never claim implemented without replayable tests and persistent settlement.

## 2026-11-12 Owner priority correction: VISUAL QUALITY P0

The owner says the current game still looks too rough; **visual foundations must be addressed before minor combat-readability and performance tuning**. Read `docs/VISUAL_QUALITY_TARGET_V1.md` and the latest `docs/CODEX_MASTER_EXECUTION_MANDATE_20261112.md`. Current characters/environment are largely procedural primitives in `scripts/field/figures.gd` and `scripts/field/landscape.gd`; this is a foundational asset-quality gap, not merely a lighting bug.

Build a high-quality **integrated in-game vertical slice** first: player, common soldier, archer, elite/challenger, horse, several true weapon grips/actions and one coherent river-gate environment. Improve model proportions, faces/hands, clothing/armor, materials, weapons, rig/animation, terrain/building/vegetation and lighting at normal gameplay camera distances. Use legitimate original/redistributable assets and actual Godot integration; static concept/Blender renders do not count. Preserve small-scale restrained realism, MultiMesh, near/mid/far LOD, soft crowd density and performance. Once the visual slice is genuinely good, propagate its quality standard across troop types/scene. Do not ask the owner to approve every ordinary art decision.

## 2026-11-12 MASTER EXECUTION MANDATE — read before development

**Primary task: [docs/CODEX_MASTER_EXECUTION_MANDATE_20261112.md](docs/CODEX_MASTER_EXECUTION_MANDATE_20261112.md).** The owner does **not** want to relay messages between ChatGPT and Codex after each PR. Continue autonomously within the actual execution runtime: integrate current river-gate playable candidate and validated PR chain, repair remaining quality/performance, finish nine weapons, bilateral strong generals, realistic military outcomes and one polished easy-to-play 512v512 battle, validate Linux/macOS, archive evidence, deliver an installable candidate. Do not stop at each phase to ask for another user message. Historical wars are optional inspiration, not a checklist. Formal literary plot stays blank. Actual M5 hardware access is a separate gated permission; mark unverified and do everything else.

The mandate does **not** authorize unlimited background execution. Before session cutoff commit/push tested progress and write exact next action to `docs/CODEX_CONTINUATION.md` or the principal GitHub issue. Older overlapping execution queues/issue fragments are subordinated to this mandate and newer owner decisions.

## 2026-11-12 Owner addendum: no arbitrary battlefield area or force-count cap

`docs/PRODUCT_DECISIONS.md §1L` supersedes any earlier text prescribing **a fixed MOBA-sized battlefield or exactly 512 vs 512 soldiers in every battle**. Geography/area must suit the war (small encounters, larger fields, multiple sectors), and real soldier counts must follow army rosters and deployments. **512v512 remains an important standardized capacity and M5 60 FPS benchmark** proving that 1024 ordinary soldiers (excluding officers/player) can simultaneously exist in a single active battle instance; it is NOT a gameplay cap, per-battle fixed roster, or same-screen/same-time-melee requirement. Offscreen/larger areas may stream and use squad-level cheaper simulation, but preserve each combatant's identity, state, time, wounds, orders and auditable casualty accounting. Do not claim literal infinite hardware support. Do not restart the river-gate project; adjust any rigid count/map assumptions incrementally. Simplicity and actual playability remain priorities.

## 2026-11-12 Owner final correction: crowd density SOFT, no strict full-body collision

The owner's **precise** concern is large crowds of soldiers artificially stacked at the same tiny coordinate, **not every pair of soldier meshes or feet being required never to overlap**. Read `docs/PRODUCT_DECISIONS.md §1M` v4.2, `docs/BATTLE_FIRST_V1_OWNER_SPEC_20261112.md §0.2`, `docs/ACCEPTANCE_MATRIX.md §7F-F`. Allow adjacent/near-overlapping feet (within visual tolerance), partial model/sprite overlap in isometric perspective, shoulder-to-shoulder troops and 2–5 soldiers brawling extremely close. **Do not impose costly rigid pairwise body collision, one-soldier-per-cell or oversized personal-space radii** that prevent melee or formation density.

Use current spatial hash/neighbor sampling plus **soft local density / occupancy budget** and gentle position/velocity/queue feedback that increases as a local area becomes congested. The goal: a large army has **plausible width and depth**, never 50–1000 persistent soldiers on one point; chokepoints create natural density/throughput without freezing, blasting troops apart, teleporting or cheating casualties. Heavier cavalry/ram/cart can have larger effective occupancy. If a compact map cannot accommodate the mass with believable local density, broaden staging/field area or stagger engagement. Maintain true 512v512 test and M5 quality, don't reduce global roster. Compare real game footage, max hotspot occupancy, formation depth, battle hits, objective progression and P95/P99. Maintain owner simplicity and master autonomous mandate; do not build a heavy physics system.

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
2. Produce **one** carefully crafted isometric 3D battlefield as an initial quality reference, with area adjustable to geography; including a real siege/city/gate and terrain roles. Every visible nearby unit actually fights; offscreen units maintain causal state, even during camera pans.
3. **Initial capacity/performance benchmark: 512 vs 512 = 1024 concurrent independent combat soldiers, not a fixed roster or maximum** (excluding player/commanders/mounts), distinct troop types/gear, command hierarchy, prebattle missions, flags/horns/couriers, and non-annihilation outcomes.
4. Nine distinct player weapon kits: sword, dao, staff, spear, long blade, bow, crossbow, sword+shield, dual swords; plus horse combat, chariots and siege gear. Real weapon strikes, skill animations and appropriate counters, not reskins.
5. Visible face/hand/weapon/clothing detail at near camera; legible formations and equipment at wide camera. Target real **MacBook Air M5 sustained 60 FPS** at 512v512 with recorded graphic settings and frame times. Never claim device PASS without running on the target.
6. **No authored plot writing now.** One military opening/root and systemic objective templates only; owner will write all formal story later. Preserve future life/history architecture without implementing narrative branches prematurely.
7. Grow from 20v20 → 100v100 → 250v250 → 512v512 as benchmark gates, but smaller scales are not a substitute for the target. Record genuine gameplay, performance and Mac build evidence.

## 2026-11-12 Owner addendum: simpler individual soldiers are APPROVED

See `PRODUCT_DECISIONS.md §1G` and `BATTLE_FIRST_V1_OWNER_SPEC_20261112.md §1.1B`. The owner permits reducing **individual soldier intelligence** to minimal attack, defense, health, morale, weapon, position and basic state machines. Group tactics, orders, routes and adjustments should mainly be managed by officers/squads. Keep real hit/animation/casualty continuity, near-camera recognizable people and weapons, and the 512v512 target. Prioritize simplifying individual AI/physics/update rates over secretly shrinking army sizes or showing fake combat animation. Maintain real Mac M5 performance target; untested remains NOT_RUN.

## 2026-11-12 Owner addendum: powerful generals on BOTH sides and causal battle outcomes

Read `docs/PRODUCT_DECISIONS.md §1H` and `docs/BATTLE_FIRST_V1_OWNER_SPEC_20261112.md §4.3/5.1` BEFORE modifying the current field battlefield or commander systems. There are combat-capable senior officers, battlefield commanders and potentially off-field supreme commanders on **both teams**. Ordinary soldiers may have inexpensive FSMs, but elite enemy/friendly officers must independently fight, threaten the player's formations, order troops, protect/evacuate commanders and engage the player in fair timing/position/weapon-based action combat. The player can plausibly kill dozens of ordinary troops, while opposing generals can do comparable harm to friendly troops; no free invincibility or automatic boss teleporting to player.

**Decapitation is NOT a win button**: commanders can be wounded, rescued, evacuated, captured or killed; orders can survive through delegates, or brittle armies may genuinely break. Evaluate actual bilateral force, morale, reserves, logistics, terrain, missions, command continuity and retreat/relief before settling battles. Killing all enemy generals without loss of resistance or objectives does NOT immediately end the war; a battle can end without killing any leader. Player death ends the player's life, not automatically every friendly army's campaign. Acceptance: `ACCEPTANCE_MATRIX.md §7F-B`, specifically BF-GENERAL-01 through BF-GENERAL-12; keep these marked NOT_RUN until actual tests and code demonstrate them. Preserve separate 512+512 ordinary troops, true M5 60fps validation status, story blank, existing v0.6/PRs and saves.

## 2026-11-12 Owner addendum: diverse battlefield theaters, logistics and ranked combatants

**READ** `PRODUCT_DECISIONS.md §1I/§1K`, `docs/BATTLEFIELD_VARIETY_AND_FORCE_ROLES_20261112.md`, `docs/ACCEPTANCE_MATRIX.md §7F-C`. Enemy and friendly orders of battle include **vanguard officers, champion-like challengers superior to common soldiers, elite guards and troops, senior field generals and potentially absent supreme commanders**. The challenger can issue a battlefield challenge but cannot force the player into a boss arena or immediately end the battle on death. Role distinctions must affect real personal fighting, missions and troop command.

Optional historical theater inspiration includes: flat frontal battle; river/bridge/hills/frontally contested varied terrain; night raid, ambush and encirclement/breakout; defense, multi-point capture, siege/fortification and attacks on different cities via detours; mountain/forest combat; grain-store/transport/road/bridge/water-source supply competition; fire attacks, siege catapults, mechanical traps and countermeasures; **river fighting, naval campaigns and artillery**. Make terrain, supplies, time-of-day/visibility, command, troop mix and military objectives truly change outcomes; never reduce them to fake choice screens. An intercepted supply route drains **actual existing inventory over time**, not instant-deaths the enemy. Opposing commanders keep independent goals and do not freeze off-camera.

These are full-product requirements. **First deepen the existing battle-first prototype** using reuse of its current map, troop, objective and supplies systems, then expand theaters with shared modules and honest status. Artillery and advanced naval technology must be **era/production/industry gated**; do not insert late-era guns into the Tang-like opening. River/boat fighting can start earlier. No new literary story, fabricated character arcs or unlicensed assets. Keep 512v512 real soldiers, good camera/figures/weapon actions, M5 60fps goal and existing proven save/CI behavior.

## 2026-11-12 Owner addendum: historical battles from late Tang to Qing are a mandatory design research corpus

Read `docs/PRODUCT_DECISIONS.md §1J`, `docs/HISTORICAL_BATTLES_TANG_TO_QING_RESEARCH_20261112.md` and `docs/ACCEPTANCE_MATRIX.md §7F-D`. Research actual battles from late Tang/Five Dynasties through Song/Liao/Xia/Jin/Yuan, Ming and Qing (including the late Qing) to select **battlefield geography, tactics, distinct troop types, arms/armor, siege machinery, river/naval and logistics systems** worth converting into reusable, player-observable warfare mechanics. Do not hardcode historical winners or write fixed story plots; the owner will author literature. Distinguish documented history, gameplay transformations and alternate-history mechanics.

**Historical technology correction:** Song already used gunpowder weapons; early fire lances, bombs and primitive guns developed before Ming; Ming–Qing warfare included muskets and cannon. Late Qing industrial naval guns, steam/ironclad fleets are different high-prerequisite technologies, not the first time artillery existed. Stone-throwing siege engines are not gunpowder cannon. Equipment adoption depends on regional invention/diffusion, workshops, stock, skilled troops and logistics, not a binary 'era reached' button. Pick highly reusable scenario templates and deliver actual code/test evidence as phases allow, **without delaying the currently active real 512v512 battle, existing PRs, nine weapons, Mac M5 benchmark and save compatibility**. No unlicensed museum image reproduction, no new unauthorized spending.

## 2026-11-12 Owner addendum: simplicity and actual playability OVERRIDE history feature checklists

**Read `docs/PRODUCT_DECISIONS.md §1K` first.** The Tang-to-Qing battles, formations, equipment, fire attacks, water/naval battles, artillery and all historical theater lists are a **selective reference pool**, NOT a promise to implement every possible element or recreate each historical battle. The owner specifically wants the game **not overly complex**. Historical depth must make fighting, command and battle outcomes more varied and fun, not impose busywork.

- Focus on the existing core: polished 512v512 field combat, satisfying nine weapon controls, strong officers on both teams, a small number of easily understood squad orders, legible battle goals, real casualties, and M5 performance.
- Keep 90% of complicated mechanics behind AI/autonomous commanders and plausible simplified logistics. Do not require the player to manage each soldier, water unit, ammunition box, siege engine, naval subsystem, industrial factory or several nested dashboards.
- Select/add a historical mechanic only if it brings distinct gameplay value, the player can understand its effect, and it is worth art/code/performance/UI cost. Defer, merge or omit redundant elements.
- BF-THEATER/BF-HIST tests apply to **mechanics actually chosen for implementation**; unchosen references are `REFERENCE_ONLY / NOT_SELECTED`, not release blockers. The already-approved core battle V1 targets are not waived. Formal story remains owner-written.

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
