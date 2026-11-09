# Project status / resumable handoff

## Current v0.9 / World8 slice (2026-11-09)

Implemented in a new isolated cloud checkout based on public `049fecc`, with the
PR10 test-driver correction from public `52f545f` carried forward. Existing acceptance
checkouts and user devices were not modified. See [COURIER_ORDERS](COURIER_ORDERS.md).

- Optional superior→patrol courier and physical reply consume one existing camp soldier
  and ten existing rations; unified travel/meal timing, endpoint interception and return
  accounting are causal. No new force, reinforcement or city-command authority is created.
- Players see only arranged/received/sent/locally confirmed information. Secret loss stays
  unknown; receipt arrival does not magically inform a distant player.
- New battles use finite-range delayed flags, per-soldier received orders and actual
  extraction. Original active saves retain historical instruction timing until settlement.
- Explicit World5→6→7→8 migrations and genuine World7 fixture bytes preserve old lives,
  profiles, clocks, inventories and battle state. Adversarial receipt/authority/meal
  forgeries found during independent review have regression tests and are rejected.
- **Passed in Godot 4.6.3 Linux cloud:** full `tools/test.sh`, youth interface/input checks,
  repeated combat calibration and original legacy parity, Linux/macOS export, packaged
  scene/campaign/youth/courier separate-process save/restart. Exact logs are under
  `docs/evidence/courier-v09-*`.
- New focused checks: local flags 62, courier causality 194, genuine World7 migration 20,
  courier UI 113, transport process restart 34+26, flag restart 1+3. Packaged transport
  smoke passes 167+180 checks. Full regression remains separate from these counts.
- **Not yet verified at source commit time:** this branch's GitHub CI and new rendered
  courier screenshots; CI now includes delivered/reply/overdue screenshots. Local cloud
  has no usable graphical display socket. macOS archive has arm64+x86_64, but no M5
  device gameplay/performance test is claimed. No formal release or paid resource added.

Acceptance remains partial: this is the physical communication foundation, not arbitrary
remote subordinate command, terrain occlusion, route patrol simulation, mature political
response or the complete game. PR10 merge/CI is coordinated separately; this branch does
not modify PR10's branch or claim its pending hosted checks passed.

## Objective and execution boundaries

Continue the complete single-player life, warfare and independent-world game.
A prototype or the first two encounters are not completion. Work in the authorized
cloud and existing public GitHub resources, with no new costs, accounts, user
computer, Codex tasks, formal release or license changes. Major cast and fixed
literary plots remain reserved for owner/Pro review; ordinary implementation proceeds.
Read AGENTS, PRODUCT_DECISIONS v3.2, NARRATIVE_LIFE_ARC_V0_3, DOT_HANDOFF_FINAL and
ACCEPTANCE_MATRIX. Latest locked youth-life priorities override old captivity proposals.

## Previous v0.8 recovery record (historical, 2026-11-09)

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
