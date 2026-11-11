# Project status / resumable handoff

## Objective and current source

Continue the full single-player life, warfare and independent-world game. This is an ongoing project, not completion of the final vision. Preserve the existing Godot 4.6.3 game. Work only in the authorized cloud and existing public GitHub resources; no new costs, extra accounts, user computer, Codex tasks or formal release.

- Current accepted gameplay: **v0.6**, source `e86a1ad2ecbeadfba53d59a1ed6b8cebee7f366b`, merged in [PR7](https://github.com/haohongfei2001-png/luanshi-game/pull/7) as `465414d9c7adf2fb1fcf17a1a221d9da30e77dec`.
- Latest design-only main `ebf89e1` is preserved in that merge. PRODUCT_DECISIONS v3.2 and NARRATIVE_LIFE_ARC_V0_3 take priority over the older Anping/captivity narrative proposals.
- Current technical work: v0.7 early/late finite-HP profiles and explicit genuine v0.6 save migration pass the full source suite; root integration/export/CI are underway. Youth core and presentation are being implemented separately. Native hosted-Mac graphical diagnostic is running in CI42427068166; no pass is claimed before results.
- Reproduction: matching official Godot 4.6.3 and export templates; `./tools/test.sh`, `./tools/export.sh`. Exact evidence is in VERIFICATION.md and docs/evidence. Read actual branch/PR/CI state before resuming.

## Accepted current capabilities

- Original procedural3D isometric battle, WASD/mouse, basic attack, Q/E/Space skills and three local squad orders. Separate20 vs 20 training. Current v0.6 legacy360 HP hero remains a fixture, not approved early balance.
- Three-city authoritative world with actual troops/equipment/food, travel, physical convoys, dated delayed reports and off-screen siege. Real battle locks20 of60 soldiers including the commander against15 actual depot defenders, leaving40 reserves. Casualties, equipment, clock, capture and physical retreat settle exactly once. Death ends the active life.
- Population/labor-dependent agricultural and weapon production, integer accrual, distinct civilian/military meals. Ninety-day conservation is covered. Hunger warns before bounded attrition; full meals plus an entire safe stationary hour recover fatigue/morale. Battle/march/siege do not grant free rest.
- Free named saves, F5/F9 quicksave/load, F6 panel, retained unique life checkpoints. Exact world numbers, RNG, full history, reports, movement, supplies, condition, reserved/running/pending/committed battles and receipts survive process restart. Training is separate. Loaded active fights reopen paused.
- First real persistence format: envelope 1, World 5. Strict bounded primitive codec and causal validation; no arbitrary object/resource loading. Future schema changes require explicit preservation or migration and genuine old-save fixtures.

## Latest verified artifact and tests

[CI42425639702](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/42425639702) passed both jobs for source `e86a1ad`. PR checkout/artifact suffix is `0b6dd7037ec40bc8fea5b2002fcd3a8c82a08fe4`, distinct from source head.

- 6,691 functional assertions,5,321 malformed-type mutations,107 file/codec boundaries,36 economy property scenarios and2,689 independent condition checks pass. Separate prepare/resume processes preserve battle settlement;90 days/14,007 events plus day 91 continuation are intact.
- Actual Ubuntu/Xvfb/llvmpipe images were inspected: named slots, life checkpoints, loaded paused fight, committed retreat result, and real campaign combat.1280×800 controls fit and remain readable. These are real rendered frames, not mockups.
- Exact exported app ran on native macOS26.7.2 arm64 in headless training/campaign and two-process persistence modes. Strict ad-hoc signature passed. Native persistence ends at world 10829.075 with42 events, matching the expected result.
- **Retained native-tested macOS ZIP SHA256:** `278daea3d44ccbbd6a98f36e2895f48df57121959b9bbf18352a28c3ea82956d`. This exact CI ZIP is the current playable in Space. CI Linux archive: `1c2ff114c60a194909e847e5c1de94ff3f02a918c7441eee43f13560d390661f`.

## Next executable work

1. Finish finite-HP early/late profile integration and full source/scene/render/export/native checks. Migrate real World 5 saves explicitly without clipping old360 HP characters, changing cooldowns/RNG or losing receipts. Keep v0.6 playable while validating.
2. Complete the bounded, separately recorded native hosted-Mac window/renderer probe. It cannot prove M5 performance, human feel, Finder/Gatekeeper behavior or audio. If unavailable, record exact evidence and continue gameplay work.
3. **First narrative slice:** age about 15 forced or voluntary enlistment, real first combat/earned merit, structurally unfair credit/reward, distinct endure/appeal/evidence/protect choices, actual first small-unit appointment, dangerous order, real casualties/retreat/replacements, persistent relationships and merit/army state. Use the existing world/battle/save authorities, not text-only branches or scripted squad wipes.
4. Then genuine superior appreciation/exploitation, autonomous comrades, physically delayed messages/reinforcement/supply and an off-screen hometown chain. Rare captivity, long-term family/politics/succession follow later. Death never switches control to an heir.

All major cast names and fixed imperial/romance/historical scripts remain provisional pending owner/Pro creative review. Ordinary characters, dialogue, side content and technical details can proceed autonomously. The Anping commander fixture is not the mandatory life opening.

## Open acceptance and limits

- OWNER-COMBAT-01 is under implementation; current v0.6 does not meet early1-vs-2 balance. No earned progression system yet.
- Current WRL-07/LIF-02/TECH-03 and OWNER-SAVE-01 evidence covers implemented systems and90 days, not unlimited lifetime or future NPC/story state.16 MiB file/128 MiB raw/4 million node bounds remain; long-history lossless compaction/segmentation is pending. Atomic rename is not a proven cross-platform power-loss fsync guarantee. Concurrent writes are last-writer-wins, not CAS.
- Remote couriers/interception, autonomous named NPCs, age/life/career, narrative choices, long-term politics/family, multi-month activity flow and full-game acceptance remain incomplete. New NAR-YOUTH/SQUAD/COMMAND/ARC rows are NOT RUN.
- Current live-battle condition penalties are entry snapshots. Populations/rates/timings are compressed provisional values.20 vs 20 simulation is O(n²); no large-army performance claim.
- Linux software-render evidence and native Mac headless execution are distinct. User M5 sustained graphics/thermals/input feel remain NOT RUN. No Developer ID/notarization, iOS verification or formal release. Cloud display socket restrictions are not bypassed; graphical checks use existing standard CI.
- Owner decision Issue3 and narrative Issue5 remain open until actual behavior is implemented, not merely because their documents were read.

## Durable continuation

Fetch main, read this file, AGENTS and latest prioritized design; inspect active branches, uncommitted changes, exact source CI and artifacts. Continue the smallest unfinished stage without restarting previous work or overwriting concurrent design updates. Run tests, commit verified code/evidence, retain the last playable and advance to the next stage. Check uncertain publication outcomes before retrying.

Routine progress belongs in GitHub; contact the owner only for reserved approvals or unavoidable blockers. A repository checkpoint supports recovery but cannot guarantee uninterrupted compute. If a platform limit stops work, leave exact last source, completed tests and next command here; never label the full project complete.

## Preserved stage history

- PR1 `bfb028a`: first playable and strategic/world foundation.
- PR2 `0be9e51`: real campaign battle transactions; CI42419804675.
- PR4 `ca3f21a`: population economy; CI42422010645.
- PR6 `4174e98`: staged military condition; CI42423403245.
- PR7 `465414d`: full implemented-campaign saves/checkpoints; CI42425639702.

Earlier exact results and discovered/fixed defects remain in VERIFICATION.md, system documents, tests and Git history; do not repeat already completed stages.

## v0.7 source integration checkpoint

Normal new campaigns and training use early 100 HP; late 100 HP is a clearly labeled training tier, not earned progression. World 6 preserves immutable profile references on commander, tickets and battle saves. Real World 5 files migrate to legacy 360 HP without clipping HP, timers, RNG or history. All 20 original fixture artifacts were reproduced byte-for-byte from public e86a1ad.

Isolated source integration passes 75,460 aggregate checks and 1,499 calibration/parity checks, including 1,773 exact original-engine continuation frames through settlement. Full root integration, exported builds and exact-head graphical/native acceptance are the next commands, before replacing the v0.6 playable. See HERO_PROFILE_INTEGRATION.md. No M5 or human quality claim.
