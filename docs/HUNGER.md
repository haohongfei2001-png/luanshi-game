# ECO-04: military shortage, condition and recovery

Status: bounded authoritative simulation milestone, with deterministic headless evidence. The three-line strategic army panel consumes this contract, with headless shortage/recovery/layout coverage. This document does not claim rendered hunger UI or M5 gameplay acceptance until separate exact-source CI evidence is recorded. All rates and thresholds are **provisional compressed Anping-scenario balance**, not historical claims or owner-approved final values. Military condition is shared by both factions and city garrisons. Civilian population remains fixed; civilian starvation, recruitment, disease, desertion and detailed demography are not implemented here.

The existing short rescue scenarios and healthy legacy combat profile are preserved. **OWNER-COMBAT-01 remains separate work**: the current 360-HP commander is a legacy fixture, not proof of the approved early 1-vs-2 profile. No new army, item, story, courier or save system is introduced.

## Authoritative state and one clock

`data/condition_rules.gd` holds all condition tuning. `WorldSimulation` owns each military entity's `condition` dictionary. Snapshot schema becomes **4**, adding condition and a starvation-death ledger. There is no durable save loader or silent migration of schema 2/3.

- `fatigue`: integer 0–100, initially 0.
- `morale`: integer 0–100, initially 100.
- `hunger`: integer 0–6000. One thousand points represent one entirely missed hourly ration. This is a bounded deprivation measure, not an inventory debt or demand for repayment food.
- `stage`: `fed`, `shortage`, `weakened`, `attrition` or `recovering`.
- `last_needed`, `last_eaten`: actual whole food units at the last military meal.
- `last_activity`: the strongest activity observed during that meal's hour.
- `activity_flags`: activities actually observed during positive world-clock intervals since the last hourly boundary. These flags survive fractional advance and transaction rollback.

The existing world clock still processes hourly military meals: `needed = ceil(current soldiers / 10)`; `eaten = min(needed, physical food)`. Battle-reserved people are included exactly once. Existing food consumption and shortfall ledgers remain authoritative. Economic work, physical convoys, daily civilian meals, military meals and condition, arrivals, siege resolution and reports retain the existing hourly order. No UI call advances condition. A zero-duration advance is a no-op.

## Shortage to weakness to casualties

At each military meal with `missing = needed − eaten > 0`:

1. Hunger increases by `ceil(missing × 1000 / needed)`, capped at 6000.
2. Fatigue increases by `ceil(missing × 12 / needed)`, capped at 100.
3. Morale decreases by `ceil(missing × 10 / needed)`, floored at zero.
4. Stage is `shortage` below 2000 hunger, `weakened` from 2000, and `attrition` from 3000.
5. The condition event is recorded before any casualty. Only a meal with a current deficit and hunger at least 3000 may remove **at most one unreserved soldier per military entity per hour**. Existing `_lose_troops` limits people/equipment to real, unreserved stock. No full-force death or surrender is triggered by the condition mechanism.

The percentage terms round upward to their smallest integer unit; a tiny deficit is not rounded up to an entirely missing meal. Equal half-rations produce 500 hunger, +6 fatigue and −5 morale per hour, reaching the first death after six deficient meals rather than three. Saturated hunger stays finite. A force with no remaining people neither recovers nor creates further hunger deaths.

For an initially healthy 60-person force marching without food:

| Hour | Stage | Hunger | Fatigue | Morale | Survivors |
| --- | --- | ---: | ---: | ---: | ---: |
| Before departure | Low-food warning in view | 0 | 0 | 100 | 60 |
| 1 | shortage | 1000 | 14 | 90 | 60 |
| 2 | weakened | 2000 | 28 | 80 | 60 |
| 3 | attrition | 3000 | 42 | 70 | 59 |

Both earlier warnings are observable before first loss; actual entry-time combat penalties already apply at the first shortage. With normal opening supplies, `low_food` becomes true with three hourly rations left, before any hunger. Existing enemy siege behavior may still withdraw after its first actual shortage: it need not wait for its troops to die. This preserves the established hour-10 supply-interception outcome.

## Genuine rest and recovery

The activity priority is battle, march, siege, alert, rest. Every **positive** clock interval records its activity. The highest exertion observed anywhere in an hour adds fatigue once: battle +3, march +2, siege +1, alert/rest +0. This is deliberately coarse and conservative: even a brief part-hour battle prevents treating that whole hour as rest; this milestone does not model per-second fatigue physiology.

Rest requires a stationary military force in a friendly city, no active siege role, no battle reservation, and no living hostile field army at that location. A besieged garrison, besieging army, marching force, local battle, hostile depot visit or garrison facing a hostile army is not resting. A reservation is conservatively treated as battle activity; ordinary world advancement remains locked while a ticket exists.

With a full meal:

- Hunger decreases by 1000 toward zero, including while marching or fighting. This represents feeding, not resting.
- Only an hour whose observed activity consists entirely of `rest` reduces fatigue by 6 and increases morale by 4, within 0–100.
- A full meal stops new starvation deaths immediately, even while earlier hunger persists.
- `recovering` means either remaining hunger is being fed down, or a genuinely resting force still has fatigue/morale to restore. `fed` describes current ration status, not necessarily zero fatigue; callers also display fatigue, morale and activity.

Arrival a second before an hourly boundary cannot award an hour of recovery. The next full resting hour can. Transfers only move food; they do not reset hunger or condition. Viewing menus/reports, opening/closing a battle panel, cancelling an unstarted ticket and repeated clock synchronization grant no recovery. Recovery never revives soldiers or equipment. Enemy armies and garrisons use precisely the same rules.

## Battle entry and reservation boundary

Canonical battle roster entries carry detached condition and derived entry modifiers. The penalty in integer percentage points is:

`floor(max(0, fatigue − 40) / 3) + floor(max(0, 70 − morale) / 7) + floor(hunger / 500)`

Movement is at least 80% and damage at least 75% of the existing equipped/unarmed profile. Ordinary movement, basic attack, sweep damage, lunge displacement and lunge damage use those modifiers. HP, armor, reach and cooldowns are not inflated or secretly reduced. At healthy defaults and after the normal three-hour depot march, multipliers remain exactly 100%, retaining training and campaign smoke behavior. Equal conditions yield equal penalties for both factions.

This is an **entry snapshot**, not continuous local combat hunger/physiology. World condition continues to advance during battle and is retained afterward, but already-reserved people are not additionally killed or have HP changed by coarse hunger. Free reserves may suffer attrition. Reserved people/equipment cannot be removed twice. Long-battle live modifier refresh and individual food/casualty timing remain future work; the current limitation is explicit rather than inventing a second unsynchronized condition simulation.

## Player-view contract

`player_view().army.condition` provides the detached own-army condition plus:

- `activity`: current classification (which can differ from the last completed hour).
- `food_needed_per_hour`, `food_hours`: current military demand and carried-stock coverage, without promised future shipments.
- `low_food`: positive demand and at most three hours of physical carried food.
- `ration_scale`, `weakened_at`, `attrition_at`: 1000, 2000, 3000, so UI labels need not copy configuration.
- `modifiers`: `speed_percent` and `damage_percent` for a newly started battle.

No enemy army condition, global casualty ledger or unreceived reports are added to the view. The local city view omits military condition, including when standing at a hostile depot. Existing delayed report contents remain unchanged. A physically encountered enemy's tactical movement/damage can reflect condition without providing global army intelligence.

## Accounting, rejection and rollback

The existing `dead` and `weapons_destroyed` ledgers still account for every loss. `starvation_dead` is a classified subset of `dead`, never an extra subtraction from people. `starvation_attrition` events record entity, exact world time, lost people, destroyed weapons, current hunger/fatigue/morale and reserved people. `military_condition` events record the actual meal, pre/post condition, activity evidence and whether genuine rest occurred. They are detached historical copies.

Audits and world/battle clock guards reject missing/wrong-type condition, out-of-range fatigue/morale/hunger/meal numbers, invalid activity flags/stages and invalid loss ledgers before arithmetic. Numeric headroom bounds starvation, total death, prisoner and equipment-loss categories before hourly advancement. The former economy ceilings still apply. All new values are inside the existing atomic settlement snapshot, so a failure after elapsed-time hunger updates rolls condition, meals, casualties, events and activity flags back together. A safe retry applies the original facts once.

## Reproduction and acceptance evidence

Baseline: `0c8e240e820833f74e400b098be8108a934efeda`, isolated Linux cloud checkout. Engine: **Godot 4.6.3.stable.official.7d41c59c4**.

```sh
XDG_DATA_HOME=/workspace/shared/godot-data \
XDG_CONFIG_HOME="$PWD/.local-config" \
XDG_CACHE_HOME="$PWD/.local-cache" \
./tools/test.sh
```

Focused suite: `godot --headless --path . --script tests/tests_hunger.gd` with the same environment. It is included in `tools/test.sh` with process-exit and logged-error checks.

Verified: **1,871 functional assertions, zero failures** (existing 1,534 plus 337 hunger assertions), **36 seeded economy property scenarios with 52,194 audit assertions**, editor import and both actual-combat smoke runs. The only existing assertion adjustment is explicit snapshot schema 3→4; no old behavioral coverage was removed. [hunger-tests.log](evidence/hunger-tests.log) records the new suite. Integrated aggregate evidence (1,908 functional assertions with the condition UI) is [hunger-verification.log](evidence/hunger-verification.log).

Coverage includes complete and fractional meals, pre-loss warnings/penalties, bounded progressive death, full recovery without resurrection, hostile/active/partial-hour rest exclusion, equal faction/garrison rules, armed/unarmed and skill penalties, protected reservations, full-meal battle exclusion, atomic rollback/retry across actual hunger deaths, malformed condition and ledger bounds, maximum supported personnel arithmetic, deterministic whole/hourly/fractional replay, detached own data and no new enemy-intelligence leak.

Original causal outputs remain exactly: relief at hour 6 with 53 people/84 food; offscreen city loss at hour 15 before late arrival at 16; intercepted supply retreat at hour 10 following depot capture at hour 3. Default 90-day production/consumption totals also remain 12,960 food produced, 13,828 eaten, 269 weapons produced, 500 food remaining and 50 civilians: the opening garrisons either remain supplied or are captured before starving. New deliberately unfed garrison fixtures do lose people, rather than preserving the old immortal-garrison omission.

ECO-04 simulation/contract evidence is PASS. Rendered hunger UI and exact-commit CI/export verification are separate parent-integration steps. No local X11/Xvfb workaround, user computer, actual M5 device performance, manual game-feel acceptance or formal release is claimed.

Independent review also passed 2,689 oracle/validation checks over nine randomized personnel/ration scenarios (1 through the numeric safety ceiling, not a claimed playable army size), arbitrary subhour replay and battle-to-rest transitions. The persistent reproduction is `tests/test_hunger_properties.gd`, included in `tools/test.sh`; log: `evidence/hunger-independent.log`. No tracked implementation was changed by this audit.

The integrated strategy suite has 94 assertions (37 new): projected food hours, activity, fatigue/morale, visible warning before any death, real transfer and full-hour recovery, no mutation of authoritative or detached data, and initial viewport containment. `tests/strategy_visual.gd` uses actual wait clicks to exhaust carried food, verifies the pre-loss warning and resupply control, then writes `artifacts/condition-shortage-proof.png` during graphical CI.
