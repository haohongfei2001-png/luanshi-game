# Project status / resumable handoff

## 河关千人战场 · 2026-11-12 云端开发

直接启动默认进入河关战前部署。新军籍包含双方各 512 名普通士兵，另有 32 名军官与 1 名玩家。旧三城战役、训练、v0.6 存档与此前的工程分支仍可单独进入。当前候选、可下载包、录像、逐帧 JSON 与最后一次执行结果集中在 [战场 PR #18](https://github.com/haohongfei2001-png/luanshi-game/pull/18)。

| 已留下的证据 | 实际结果 |
| --- | --- |
| [原工程兼容修复 PR #17](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43077402767) | 原 PR #10 的提交与 main 的设计文档合并到接管分支。中文字体随包加载，1280×800 战略界面、旧档和跨进程恢复、Linux 导出、托管 macOS 原生运行通过。 |
| [河关可运行候选 de12785](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43083976264) | Ubuntu X11 实际执行九种兵器的鼠标普攻与 Q、骑乘切换、地图点选、右键拖动。原生 macOS 26.7.2 的 Apple M1 虚拟机用导出包开窗，在实际 1024×645、100% 渲染、动态阴影下采集 120 帧，平均 30.33 FPS，P95 57.65 ms，P99 87.42 ms，采样间有 515 次命中。 |
| [原生窗口与不同军令 e20cb98](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43087676463) | 九把兵器的坡地瞄准均通过。同一台 M1 虚拟机、同一个 1000×600 原生窗口、同一份包，两次原生 Metal 短测分别为 121.56、179.66 FPS，兼容路径为 40.70、31.06 FPS。这组结果用于选择 Mac 默认后端。完整攻城录像从部署到结算共 468 帧。另一次[不改游戏逻辑的部署对照](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43089432898)中，护送队的冲车实际撞门三次，撤出计划则让双方合计仅五名普通士兵阵亡。 |
| [千人攻城与视角对照 4cdeaef](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43086157942) | 种子 61112 从正常军籍部署，工兵与攻门部队接战。第 551 个 20 Hz 模拟步城门首次受损，第 677 步破门，第 934 步守军失去战斗能力。普通守军仍有 143 人生还，世界完成一次结算。36 种武器动作窗口、冲锋与定枪、军需守恒通过。该提交的云端图形检查发现低角度坡面瞄准偏差，枪和两种远程武器未通过真实鼠标检查。后续修复与复验见战场 PR。 |

源代码使用 Godot 4.6.3。开发环境先执行 `./tools/prepare-font.sh`，再以 `godot --path .` 启动。Ubuntu 24.04 执行 `./tools/test.sh`、`./tools/test-field-render.sh`、`./tools/export.sh`；后两项需要 Xvfb、Mesa、ffmpeg 和对应版本导出模板。录像使用固定采集步长，性能采样使用未锁帧的另一进程。可从原生 macOS 包传入 `-- --field-profile` 记录实际游玩的原始帧时间。详情见[中文操作说明](PLAYING_ZH.md)。

真实 MacBook Air M5 内屏与 4K 持续交战均为 **NOT_RUN**。美术和手感仍待玩家试玩。正式剧情由作者保留。


## Owner priority override — 2026-11-12 (design update only; NO claimed code implementation)

- **Codex is now explicitly authorized as the PRIMARY developer**; Dot may optionally help coordinate, not overwrite active Codex work. Current battle-first top-level owner spec: `docs/BATTLE_FIRST_V1_OWNER_SPEC_20261112.md`; direct development handoff: `docs/CODEX_BATTLE_FIRST_EXECUTION_HANDOFF.md`.
- **New V1 owner target**: one polished MOBA-scale 3D map with **512 vs 512 = 1024 real fighting soldiers** excluding player/officers/mounts, near-camera visible faces/hands/weapons/clothes, nine unique weapon kits, cavalry/chariots/siege, prebattle officer tasks, flag/horn/courier orders, non-annihilation outcomes, and actual **MacBook Air M5 sustained 60 FPS** performance evidence. See BF-01..BF-15 in `docs/ACCEPTANCE_MATRIX.md §7F`.
- **Formal story writing remains blank and exclusively reserved to Owner**. One neutral military opening/root and system branching interfaces only. The old youth/long-history narratives remain deferred visions and regression-compatible code, not Codex's present script-writing instructions.
- **Preserve existing code/data**: accepted v0.6 and existing open PR #10; last known PR #10 (historical `52f545fe58`) needs macOS font/CI verification and old-save migration. Check GitHub current state/CI before writing; a separate incomplete `handoff/cloud-transfer-20261111` branch is not by itself a release.
- **Important evidence boundary**: This commit only updated the design, acceptance and handoff documents. It did **NOT** implement 1024-person combat, art, nine weapon movesets, mounted/siege mechanics or M5 FPS. All BF tests remain NOT_RUN unless actual linked code/tests prove otherwise. [GitHub battle-first issue #12](https://github.com/haohongfei2001-png/luanshi-game/issues/12).
- The rest of this file is a historical developer status snapshot. It should be updated by the *actual* development agent after running the next verified work.

## Objective and execution boundaries

Continue the complete single-player life, warfare and independent-world game.
A prototype or the first two encounters are not completion. Work in the authorized
cloud and existing public GitHub resources, with no new costs, accounts, user
computer, Codex tasks, formal release or license changes. Major cast and fixed
literary plots remain reserved for owner/Pro review; ordinary implementation proceeds.
Read AGENTS, PRODUCT_DECISIONS v3.2, NARRATIVE_LIFE_ARC_V0_3, DOT_HANDOFF_FINAL and
ACCEPTANCE_MATRIX. Latest locked youth-life priorities override old captivity proposals.

## Current source and actual recovery (2026-11-09)

- Remote main was verified at `bfc7d5a`; no open PR and no active old Godot process.
  Finite profiles `c0c6d53`, youth core `e64070a` and UI `4222cf6` were present only
  in cloud checkouts. They are now integrated without overwriting dirty old folders.
- Local verified implementation: `bb6654f0cad1e79b00789935f096134bdf476c3f`, v0.8.
  Only evidence/provenance/status documentation changed after its full validation.
- Finite-profile public checkpoint: [`e337c3f`](https://github.com/haohongfei2001-png/luanshi-game/commit/e337c3f56accffa5ba7293f90bf85197397a0007),
  tree-identical to c0c6d53. Youth source `049fecc` is public in
  [draft PR10](https://github.com/haohongfei2001-png/luanshi-game/pull/10).
- Terminal push had no credentials; the already connected GitHub interface publishes
  exact verified trees instead. No credential/account change is needed.

## Newly implemented player behavior

- New campaigns/training use early 100 HP. Late offense remains a labeled 100 HP
  training tier, not earned progression. Genuine World5/6 saves preserve their
  original profiles, HP, RNG, timers, inventories, receipts and technical identity.
- 「少年军旅 / 人生」 starts age fifteen with forced/voluntary service and motive.
  Actual five-person patrol combat earns merit; reported merit and superior credit
  differ. Endure, appeal, evidence and protecting a survivor have distinct effects.
- Actual commission enables local squad command. Dangerous missions have real
  victory, withdrawal and death; replacements consume existing camp resources.
  Names, evidence, relationships and casualties survive ordinary saves/checkpoints.
- Long-combat starvation no longer makes the return journey roll back: named losses
  follow world losses, death stops pending actions, and failed protection records
  real elapsed time without inventing a survivor. Tactical extraction no longer
  falsely claims that the army has already marched back to camp.

## Completed local checks on the integrated implementation

Official Godot 4.6.3 / Linux cloud, with XDG_DATA_HOME=/workspace/shared/godot-data,
XDG_CONFIG_HOME=/workspace/shared/godot-config and XDG_CACHE_HOME=/workspace/shared/godot-cache:

- `./tools/test.sh`: PASS, including all prior battle/world/economy/hunger/transaction/
  save cases, 90 days and 14,007 events, 5,472 malformed-save mutations, 3,066 legacy
  profile/save checks; youth career 536, genuine World6 migration 40, youth corruption
  2,201, restart 13+14 and starvation restart 65+24 checks. No Godot error markers.
- `./tools/test-youth-ui.sh`: PASS, 59 actual-control scene assertions, seven text
  fixtures and the real input route with damage, actual casualties and physical retreat.
- `./tools/calibrate-combat.sh`: PASS, 1,499 profile/calibration/parity checks; repeated
  calibration hash 4db8d665b7d5de8aa01d7ba07cc98fde13658619ffbf9624608cffb99aef6b93.
- `./tools/export.sh`: PASS. Exported Linux training, campaign, old persistence and
  youth prepare/resume pass. Youth has 30+29 checks, exact World7 endpoint, 284 events,
  world time 72023.8479166667. Universal macOS 0.8 archive structure passes.
- Local macOS ZIP SHA256: 8f8d7f1bb01d55197a9b3a6ee419ce15c6d09aef74c72a9cd3eb90e0fa704303.
  Linux archive: 64f2e113b6a01db211b84ddae9e563ec3a5fb75d695b666c82947368b1352435.
  These are cloud build hashes, not native-test results. CI creates its own packages.

Evidence: [integrated source](evidence/youth-integrated-tests.log),
[UI/input](evidence/youth-integrated-ui.log), [calibration](evidence/youth-integrated-calibration.log),
[exports](evidence/youth-integrated-export.log), [youth behavior](YOUTH_LIFE_SLICE.md).
Initial environment-path and merge-order test failures were fixed and the full
final sequence rerun. No failure was relabeled a pass or old check removed.

## Remaining stage gates and immediate next action

1. [CI42546566552](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/42546566552)
   passed full simulation, calibration, strategic/battle/save graphics, but failed
   the youth graphical personal-damage assertion: X11 input produced zero damage.
   The PR remains draft; packaging and native macOS were correctly skipped.
   The input driver now moves the real OS cursor, sends held-key events and flushes
   buffered input. It also checks pointer error and actual movement frames.
   `./tools/test-youth-ui.sh` passed again (59 scene checks, seven presentation checks,
   99.47 personal damage, 419 moving frames, <0.001px headless pointer error).
   The cloud Xvfb process cannot create its local display socket, so graphical
   confirmation remains in GitHub CI. No runtime rule or pass assertion was weakened.
2. Inspect real current screenshots and native logs. Only then mark readiness/merge
   and replace the retained v0.6 playable with a verified artifact. No current v0.8
   graphical, native Mac, M5 or subjective-quality pass is claimed yet.
3. Continue world-backed, interceptable command transmission and limited knowledge,
   then superior appreciation/exploitation and autonomous comrades/hometown messages.
   Long-term politics, family, rare captivity and succession follow the locked priorities.

## Retained playable and acceptance limits

The last accepted playable remains v0.6 source e86a1ad (PR7 merge 465414d),
[CI42425639702](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/42425639702).
Its native-tested macOS ZIP SHA256 is
278daea3d44ccbbd6a98f36e2895f48df57121959b9bbf18352a28c3ea82956d.
The existing Space artifact remains retained. Old bounded native graphics probe
CI42427068166 finished successfully; job success alone is not its graphics verdict.

The source/UI headless checks and Linux archive execution are not actual rendered
playtesting. macOS cross-export is not native execution. M5 sustained frame time,
thermals, input feel, Finder/Gatekeeper and human quality remain unverified. No
Developer ID/notarization, iOS or formal release. 20v20 is still O(n²). Condition
penalties are battle-entry snapshots. Saves retain 16 MiB file/128 MiB raw/4 million
node limits; unlimited history, power-loss fsync and concurrent CAS are not promised.
Earned combat progression, persistent wounds, 4–6 fully autonomous important NPCs,
long-term life/politics/family and full G3/G4/F acceptance remain unfinished.

## Preserved stage history

PR1 bfb028a: first playable/world. PR2 0be9e51: real battle transactions.
PR4 ca3f21a: population economy. PR6 4174e98: hunger and recovery.
PR7 465414d: full campaign saves. See VERIFICATION and system evidence for details.

On resume fetch live main/PR/CI, inspect this file and dirty checkouts, then continue
the smallest unfinished gate. Record exact source, results and next command at every
checkpoint. A durable record enables recovery; it is not a claim of uninterrupted
compute or complete-game delivery. Routine progress stays in GitHub.
