# Luanshi (working title)

An experimental single-player game set in a fictional ancient Chinese dynasty.

## Play the river gate candidate

Download the macOS or Linux build and gameplay footage from [the battlefield pull request](https://github.com/haohongfei2001-png/luanshi-game/pull/18). The default opening deploys 512 ordinary soldiers on each side. Select a weapon and company tasks, then press Enter. From source, run `./tools/prepare-font.sh` and `godot --path .` with Godot 4.6.3. The upper-right campaign button opens the earlier three-city game and its saves. [Controls in Chinese](docs/PLAYING_ZH.md) · [Verification history](docs/PROJECT_STATUS.md).

## Vision

A character-driven war RPG with MOBA-style isometric 3D combat, soldiers who require real supplies, strategic army command, and a world that continues to evolve outside the player's view. The protagonist grows older and can die. Death concludes that playthrough; saves and major-life checkpoints allow replay.

**Long-term campaign expansion (2026-11-12):** A capable long-lived protagonist can potentially experience a compressed historical arc from Tang-style warlord fragmentation and reunification through competing northern powers, divided-state defense, capital and fiscal crises, and eventual foreign advanced naval warfare, within one mortal life. Branching outcomes are determined by world simulation; winning a war does not automatically make historical events unfold on fixed rails. This is a future design target, **not yet implemented**. See [the era-campaign specification](docs/CENTURY_WAR_ERA_CAMPAIGN_V0_1.md).

**Owner's current first-release target (2026-11-12):** one beautiful and genuinely playable MOBA-scale 3D battlefield with **512+512=1024 real soldiers**, differentiated attacks/animations/skills for nine weapon loadouts (sword, dao, staff, spear, long blade, bow, crossbow, sword+shield, dual swords), cavalry, chariots, city/siege gameplay, autonomous commanders, prebattle assignments, flags/horns/courier commands and non-annihilation win conditions. Close-up figures show faces, hands, clothing and actual weapons. Target **sustained 60 FPS on the owner's MacBook Air M5** during actual battle; this has **not been tested or achieved yet**. Story authorship is **deferred entirely to the owner**, with only one initial military scenario/root as a mechanical placeholder. This replaces the old 20v20/small narrative version as the current full initial release target. [Owner's authoritative battle specification](docs/BATTLE_FIRST_V1_OWNER_SPEC_20261112.md) · [Codex implementation handoff](docs/CODEX_BATTLE_FIRST_EXECUTION_HANDOFF.md).

## Historical initial prototype / current regression baseline (not the owner-approved final battle V1)

- One controllable 3D character with movement, basic attack, and three skills
- Two teams of soldiers in a small battlefield (target 20 vs 20 initially)
- Basic follow / attack / retreat commands
- Actual casualties carried into a simple after-battle report
- A repeatable build and test workflow

Out of scope for the initial milestone: a nationwide map, city economies, complex NPC politics, and a million independently simulated soldiers.

## Autonomous development

**Primary code developer: Codex** — explicitly authorized by the owner on 2026-11-12 to develop, optimize, test and deliver directly to this existing repository. Dot is optional for coordination/status, not a sole gatekeeper. Preserve existing Godot, v0.6, PR #10 and world/save tests; don't race edits on one branch. Neither developer gets paid services, extra accounts, personal Mac access, code publishing licenses or commercial release privileges by implication. Native Mac M5 performance validation is separate and **pending**.

Godot 4 and GDScript are the provisional choices. Platform: macOS first (Apple Silicon preferred for initial validation); iPhone/iOS is a future target. Keep input handling and UI layout adaptable for touch controls. Engine choice should be revisited only after a focused technical benchmark, not based on speculation.

**Canonical current handoff, updated 2026-11-12:** [battle-first V1 owner spec](docs/BATTLE_FIRST_V1_OWNER_SPEC_20261112.md) → [Codex primary execution](docs/CODEX_BATTLE_FIRST_EXECUTION_HANDOFF.md) → [Owner's locked product decisions](docs/PRODUCT_DECISIONS.md) → [one-life century-war epoch campaign](docs/CENTURY_WAR_ERA_CAMPAIGN_V0_1.md) → [owner's nine resolved creative decisions](docs/OWNER_CREATIVE_DECISIONS_PENDING.md) → [Pro final game design](docs/FINAL_GAME_DESIGN_SPEC.md) → [narrative and visual direction](docs/NARRATIVE_ART_DIRECTION.md) → [life-spanning narrative arc (owner-approved concepts)](docs/NARRATIVE_LIFE_ARC_V0_3.md) → [Tang-inspired court politics and rare captive branch](docs/NARRATIVE_WORLD_BIBLE_V0_2.md) → [simulation architecture contracts](docs/SIMULATION_CONTRACTS.md) → [acceptance matrix](docs/ACCEPTANCE_MATRIX.md) → [Dot direct-cloud handoff](docs/DOT_HANDOFF_FINAL.md). Historical/stage references: [delivery gates](docs/DELIVERY_PLAN.md), [full vision completion](docs/FINAL_VISION_ACCEPTANCE.md), [first independent code review](docs/PRO_TECH_REVIEW_001.md), [Dot cloud bootstrap](docs/DOT_BOOTSTRAP.md), [AGENTS.md](AGENTS.md), [initial game bible](docs/PRO_DESIGN_BIBLE.md), [original game vision](docs/GAME_VISION.md).

## Status

Godot 4.6.3 v0.8 integration: finite-HP combat and a playable youth military-life slice. The new “少年军旅 / 人生” entry follows enlistment, real patrol combat, disputed merit, four consequential responses, a real squad commission, dangerous combat/retreat and replacement from existing resources. A world-backed depot encounter now reserves actual soldiers and weapons, advances one clock and settles casualties/equipment exactly once in-process. Training remains a separate 20-vs-20 scene. Reproducible combat, world, transaction and routed scene tests are in `tools/test.sh`. See [verification](docs/VERIFICATION.md) for actual results and limitations.

### 河关战场

默认开场为河关战前部署。选择兵器，给各队分配任务，按 Enter 开战。WASD 移动，鼠标瞄准，左键或 J 普攻，Q、E、空格使用本兵器的三个动作。右键拖动镜头，滚轮缩放，C 回到主角。靠近马匹按 F，靠近战车按 V。Tab 打开军令，F5/F9 保存或恢复这场战斗。

默认双方各 512 名普通士兵，另有军官、玩家和载具。三城战役和旧存档可从右上角进入。河关以新军籍接入原有 WorldSim。其本局时钟、留在地面的兵器、真实兵员损失及守军沿道路的撤离均在战后结算。两种开场各自保存，切换会保留内存中的现场。源代码验证命令是 `./tools/test.sh`。Linux X11 图形测量使用 `./tools/test-field-render.sh`，需要 Xvfb、FFmpeg 和 GNU timeout。

### Play from source

1. Install Godot 4.6.3 (standard edition).
2. In a fresh checkout run `./tools/prepare-font.sh`, then import `project.godot` in Godot and press F5. Packaged games include the font and run offline.
3. In the legacy training mode, WASD/arrows move, mouse aims, left click or J strikes. Q performs a sweeping cut, E lunges, Space braces (50% damage reduction for 1 second on new early/late profiles).
4. 1 orders attack, 2 follow, 3 retreat. To withdraw, lead surviving troops to the green gate at the left edge. P/Esc pauses, H toggles help. R begins new training **after** it ends; in campaign combat R returns to the map without resetting casualties.

The standalone training battle has 20 friendly soldiers, 20 enemy soldiers, and one separately counted commander. The commander's death ends the encounter. Fallen soldiers remain in the casualty ledger; only a new encounter resets it.

New campaigns and normal training use **early_v1: 100 HP**, modest reach and capped skill targets. Stay with soldiers, keep distance and brace deliberately. Late offense is available only as an explicit training test: `godot --path . -- --training-profile=late_v1`; it still has 100 HP and the same defense. This is not an earned campaign upgrade or an XP system. Existing v0.6 saves retain their original 360 HP legacy profile, timers and RNG without conversion or automatic rewriting. See [profile/save integration](docs/HERO_PROFILE_INTEGRATION.md) and [calibration limits](docs/HERO_COMBAT_CALIBRATION.md).

### Reproduce tests

```sh
./tools/test.sh
./tools/calibrate-combat.sh
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

Press **M** to open the three-city campaign. Travel the river route for three hours and **Assault Hequ depot** to fight a real roster: 20 of the army's 60 people (including its commander) versus 15 actual defenders. With 30 weapons in the 60-person army, the deployment contains 10 armed and 10 genuinely unarmed people; 40 remain reserves. The outcome updates the same world once, including actual time, dead people, recovered/destroyed equipment and depot ownership. Physical retreat preserves survivors. Commander death ends the campaign after settlement. **R returns to the map, not a battle restart.** Explicit New Campaign is separate from training replay. Local city production now uses actual civilian labor, farmland/workshops and stability, with continuous integer work accrual and separate civilian/military food consumption. The local map shows effective rates and siege stoppage; no remote economic truth is leaked. Real shortage now causes visible hunger, fatigue/morale penalties and bounded gradual attrition; full meals during an entire safe stationary hour restore condition. No rest is credited during marches, siege, hostile presence or reserved combat. Named campaign saves, active-battle resume and life checkpoints are now implemented; F6 opens the save panel, F5 quicksaves and F9 quickloads. The first youth narrative slice is playable through its own entry; the complete life narrative remains pending. This is a reversible prototype under the final design, not owner approval of all creative choices or completion of the full game.

[Population economy and 90-day verification](docs/ECONOMY.md): fixed city output is replaced by constrained production. Original rescue timelines remain covered; demographic quantities and rates are compressed provisional test values, not final historical balance.

[Military condition and recovery](docs/HUNGER.md): both factions and city garrisons use the same real-ration rules; the first warning precedes casualties. Combat penalties are bounded entry snapshots, not a separate hunger clock.

[Campaign save format and verification](docs/CAMPAIGN_SAVES.md): free named slots and retained life checkpoints, atomic load, real battle/RNG resume and once-only receipts. Training is separate and is not stored. Saved active battles reopen paused; close the panel and press P to continue. Saves preserve complete90-day history; bounded size/complexity limits mean unrestricted multi-year lifetime scale is not yet accepted.


### Youth military life (v0.8)

Click **少年军旅 / 人生** at the top right. Choose conscription or volunteering,
then survival, merit or homeland as a motive. Starting archives the previous
campaign before creating a fifteen-year-old early-profile life. Story reading
pauses; march, preparation, choices and actual combat advance the shared world.

The first patrol has five real people, including the player. A recruit can signal
withdrawal but cannot issue attack/follow orders. Return to camp after earning
merit to choose endurance, appeal, private evidence or protection of a surviving
comrade. A later actual commission enables squad command. The dangerous mission
permits victory, physical retreat and death. Replacements draw from existing camp
people and equipment; dead comrades are never revived by a story action.

F5/F9 and named saves work throughout. Old World5/6 saves remain their original
technical campaigns and profiles, never silently rewritten as youth lives. The
short-slice endpoint is not the completed game. Important cast and fixed major
literary plots remain provisional for owner/Pro review.

[Youth systems](docs/YOUTH_LIFE_SLICE.md) · [Interface and controls](docs/YOUTH_INTERFACE.md)
