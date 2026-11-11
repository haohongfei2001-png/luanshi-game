# Project status / resumable handoff

## Owner priority override — 2026-11-12 (design update only; NO claimed code implementation)

- **Codex is now explicitly authorized as the PRIMARY developer**; Dot may optionally help coordinate, not overwrite active Codex work. Current battle-first top-level owner spec: `docs/BATTLE_FIRST_V1_OWNER_SPEC_20261112.md`; direct development handoff: `docs/CODEX_BATTLE_FIRST_EXECUTION_HANDOFF.md`.
- **New V1 owner target**: one polished MOBA-scale 3D map with **512 vs 512 = 1024 real fighting soldiers** excluding player/officers/mounts, near-camera visible faces/hands/weapons/clothes, nine unique weapon kits, cavalry/chariots/siege, prebattle officer tasks, flag/horn/courier orders, non-annihilation outcomes, and actual **MacBook Air M5 sustained 60 FPS** performance evidence. See BF-01..BF-15 in `docs/ACCEPTANCE_MATRIX.md §7F`.
- **Formal story writing remains blank and exclusively reserved to Owner**. One neutral military opening/root and system branching interfaces only. The old youth/long-history narratives remain deferred visions and regression-compatible code, not Codex's present script-writing instructions.
- **Preserve existing code/data**: accepted v0.6 and existing open PR #10; last known PR #10 (historical `52f545fe58`) needs macOS font/CI verification and old-save migration. Check GitHub current state/CI before writing; a separate incomplete `handoff/cloud-transfer-20261111` branch is not by itself a release.
- **Important evidence boundary**: This commit only updated the design, acceptance and handoff documents. It did **NOT** implement 1024-person combat, art, nine weapon movesets, mounted/siege mechanics or M5 FPS. All BF tests remain NOT_RUN unless actual linked code/tests prove otherwise. [GitHub battle-first issue #12](https://github.com/haohongfei2001-png/luanshi-game/issues/12).
- The rest of this file is a historical developer status snapshot. It should be updated by the *actual* development agent after running the next verified work.

## Objective and current source

Continue the full single-player life, warfare and independent-world game. This is an ongoing project, not completion of the final vision. Preserve the existing Godot 4.6.3 game. Work only in the authorized cloud and existing public GitHub resources; no new costs, extra accounts, user computer, Codex tasks or formal release.

- Current accepted gameplay: **v0.6**, source `e86a1ad2ecbeadfba53d59a1ed6b8cebee7f366b`, merged in [PR7](https://github.com/haohongfei2001-png/luanshi-game/pull/7) as `465414d9c7adf2fb1fcf17a1a221d9da30e77dec`.
- Latest design-only main `ebf89e1` is preserved in that merge. PRODUCT_DECISIONS v3.2 and NARRATIVE_LIFE_ARC_V0_3 take priority over the older Anping/captivity narrative proposals.
- Current technical work: explicit early/late finite-HP profiles and preservation/migration of genuine v0.6 saves. A separate bounded native macOS graphical diagnostic is being prepared; its preparation is not a graphical pass.
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
