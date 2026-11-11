> Publication note: ${WRITABLE_XDG_DATA}, ${WRITABLE_XDG_CONFIG}, ${WRITABLE_XDG_CACHE}, <PROJECT_WORKSPACE> and <HISTORICAL_RUNNER_HOST> are explicit placeholders for the historical environment. Substitute writable local directories as applicable. Only environment identifiers were sanitized; no test result was changed or rerun.

# ECO-03: population-constrained economy

Status: implementation and deterministic headless verification for the bounded ECO-03 milestone. Staged military hunger/fatigue/morale is now documented in [HUNGER.md](HUNGER.md) (ECO-04). Recruitment, civilian demography, governance commands, durable saves and narrative work remain separate milestones. All demographic values, rates, ration priority and work allocation below are **PROVISIONAL**, not owner-approved historical or final game balance.

This document supersedes the fixed-production/civilian-deferred economic description in the older `WORLD_SIM.md`. `BATTLE_TRANSACTIONS.md` remains the guide to the existing real-time encounter and exactly-once settlement. This change preserves those APIs, original regression tests, and rescue scenarios.

## Data and authoritative state

`data/economy_rules.gd` contains the tunable scenario inputs, copied into each city by `WorldSimulation`. There is no resource creation in the UI or BattleSim. ECO-03 introduced snapshot schema **3** for civilian population, capacity, fractional work and consumption ledgers. ECO-04 now uses schema **4**, adding military condition and classified starvation deaths; see HUNGER.md. There is still no supported save loader or implicit old-schema migration.

Each city has:

- `population`: civilian residents only, excluding the separately counted garrison and field armies.
- `workable_population`: civilian labor available for the two production activities; must be between zero and population.
- `arable_land`: secured farmland measured in one-worker plots.
- `workshop_capacity`: one-worker crafting places.
- `stability`: integer 0–100 productive-condition percentage. Zero stops production.
- `production_rates`: whole units per productive worker per 30-day month (`food_per_farmer_month`, `weapons_per_crafter_month`).
- `production_progress`: integer unfinished work for food and weapons, never spendable inventory.
- `civilian_food_progress`: remaining person-hours below one whole ration unit.

The opening fixture has 50 civilians and 215 military personnel. These are **compressed military-post test demographics**, not a realistic regional civilian-to-army ratio. Anping is provisionally an import-dependent fortified town with no secured farmland; Pingling has 8 farm plots and 2 workshop places; Hequ has 4 and 2. Their civilian/working populations are 20/10, 20/10 and 10/6 respectively. Nothing spawns civilians or recruits soldiers in this milestone.

The same code, rate definitions and limitations apply regardless of faction. Capture changes ownership of existing people, labor capacity and stocks; it does not replace them with a new economy.

## Production rules

The single world clock still advances in seconds and processes economic work at each crossed hour. A month is provisionally 30 × 24 = 720 hours. Monthly capacities accrue by actual productive hours; this is a continuous aggregate supply model, **not** an implemented seasonal harvest calendar.

1. Farmers = min(workable population, secured farmland).
2. Crafters = min(remaining workable population, workshop capacity).
3. Effective condition = stability, or zero while this city is actively besieged.
4. Each resource accrues `workers × monthly rate × effective condition` work per hour.
5. Whole items = integer division of accumulated work by `720 × 100`. Only whole items enter stock and the production ledger. The remainder is retained exactly.

Farming-first labor priority is provisional and shared labor cannot work two jobs. Surplus population without usable capacity creates no production. Reduced stability affects food and weapons alike. A siege blocks both production streams, without accumulating an imaginary catch-up harvest. Previously completed fractional work remains, and can finish only after further productive hours. Workshops summarize the minimum labor/capacity requirements; mining, fuel, iron and other industrial inputs are not modeled yet.

At full capacity the default rates (360 food per farmer-month, 15 weapons per crafter-month) produce Pingling's former four food/hour and Hequ's two. Two crafters finish one weapon after 24 **productive** hours rather than receiving a calendar-day free item. Anping's fifteen-hour default siege therefore delays its first weapon until hour 39.

Each positive production event has a timestamp, city source, amounts, actual labor allocation, population/workable population, land/workshop limits, stability/siege condition, rates and before/after work remainder. Production and consumption alone create/remove food; transfers and convoys remain physical movements.

## Food consumption and shortage accounting

One provisional ration unit represents ten person-hours of food. Civilians and soldiers use this common base rate, with different settlement cadence:

- Existing military rationing is unchanged: each city garrison and field army consumes `ceil(soldiers / 10)` each hour, including reserved battle participants. Integer rounding remains the existing compressed military rule.
- At each full day boundary, civilians request `population × 24 / 10`, carrying the integer division remainder into the next day. One civilian therefore requests exactly 12 food over five days, not 15 independently rounded daily portions.
- Actual eaten food is `min(requested, physical stock)`. The balance is recorded as unmet demand, never negative inventory, never consumption of nonexistent food, and never debt that creates later food.
- On the daily boundary the existing hourly order is production → convoy deliveries/dispatches → city civilian meal → city garrison meal → field-army meals/condition and staged attrition → arrivals → siege resolution → reports. Civilian-first sharing of city stocks on that boundary is provisional. Convoy dispatch still precedes meals, as in the existing scenario.

`ledger.food_consumed` equals `food_consumed_civilian + food_consumed_military`. `food_shortfall_civilian` and `food_shortfall_military` separately count cumulative unmet demand. Each consumption event records entity ID, civilian/military category, current people, period, requested/eaten/shortfall and signed food delta. Events with zero eaten but positive demand explain shortages without inventing meals.

Civilian population remains fixed in this scope even when meals are missed. There are no civilian demographic deaths, hunger-driven civilian productivity changes or recruitment. Military meals now feed the staged fatigue/morale/attrition and recovery mechanism in HUNGER.md; its new effects do not change the actual-food conservation rules above.

## Conservation and validation

The existing audit continues to check:

```
physical food, including transit = initial food + produced − actually consumed
physical weapons = initial weapons + produced − destroyed
active soldiers + dead + prisoners = initial soldiers
```

It now also checks constant civilian population, the civilian/military consumption sum, integral/nonnegative population and stocks, valid labor/capacity/stability/rates and bounded integer remainders. Missing/wrong-type economic fields and negative cumulative consumption/shortfall ledgers are rejected before arithmetic. Integer safety ceilings (one billion people/capacity places, one million units per worker-month and 10^18 stock/ledger units) keep allowed work products inside signed 64-bit arithmetic; these are safety limits, not demonstrated game scale. World/battle clock entry refuses invalid economic state or insufficient numeric headroom without mutation; it does not silently clamp negative stocks. For a valid state near these safety ceilings, a conservative preflight bounds all production, possible convoy receipts and consumption/shortfall growth before the request starts. It assumes a siege could lift and does not spend space from future meals/casualties; therefore it may safely refuse some operations whose final net stock would fit. Fractional advances crossing no economic boundary remain allowed. Ordinary transfers also require destination headroom. The preflight splits work into quotient/remainder before multiplying elapsed hours to avoid intermediate overflow. This is runtime invariant validation, not a general untrusted save-file parser. Economic state, remainders, ledgers and events remain inside the existing atomic battle-settlement snapshot/rollback.

`player_view().local_city` exposes only the physically occupied city's current economic fields. Its derived `production_plan` includes farmers, crafters, effective condition and exact `food_per_month_numerator` / `weapons_per_month_numerator`, divided by `rate_denominator` (100). It also provides `hours_per_month` (720), `civilian_food_per_hour_numerator` (population), `civilian_food_rate_denominator` (10) and `hours_per_day` (24), so the UI need not read global configuration. The same calculation drives actual production. During travel local_city is empty. Remote plans, ledgers and real-time siege status are not added to delayed intelligence. Returned data is detached from truth. The UI can display this local summary without inventing a second economy.

## Reproduction and evidence

Baseline: `0383e85f1fea6c9fb2db3bd0a4f77a00423d83b5`, isolated cloud checkout. Godot: **4.6.3.stable.official.7d41c59c4**, Linux x86_64. No original test assertion or fixture was changed.

From this checkout:

```sh
XDG_DATA_HOME=${WRITABLE_XDG_DATA} \
XDG_CONFIG_HOME="$PWD/.local-config" \
XDG_CACHE_HOME="$PWD/.local-cache" \
./tools/test.sh
```

For only the new suite:

```sh
godot --headless --path . --script tests/tests_economy.gd
```

Verified result: **1,513 assertions, 0 failures** (the original 986 unchanged assertions plus 527 economy assertions), with both actual-combat smoke runs passing and no logged script errors. The new suite log is [economy-tests.log](evidence/economy-tests.log). An independent review also reran 98 malformed-input/battle-clock checks and 36 valid capacity/capture cases after its initial guard findings were repaired, followed by 17 additional stock/ledger-cap and battle/transfer boundary checks after the numeric-headroom correction.

The new suite is part of `tools/test.sh`, including nonzero-exit and logged-error detection. Its coverage includes:

- Workforce, civilian-population, farmland and workshop limits; shared labor; custom data rates; half/zero stability; zero population/production.
- A full month of sustained siege, local rescue re-enabling production, preserved partial work during interruption, and slow fractional production over three months.
- Exact daily civilian fractional meals; separate garrison/army consumption; explicit starvation demand without negative stock.
- Ninety daily conservation checks, independent production/consumption event reconstruction, identical whole-period/daily/fractional clock replays, and offscreen economic continuation after commander death.
- An actual reserved battle crossing the day/month boundary, all sixty military people fed once, duplicate synchronization read-only, and original transaction rollback/once-only tests.
- Invalid fields/stocks/rates rejected before clock mutation, atomic world/battle-clock rejection at numeric ceilings, exact headroom, transfer/convoy capacity, safe maximum-input duration arithmetic, detached local-view data and no remote knowledge leak.

The 90-day default no-command run produces **12,960 food and 269 weapons**, actually consumes **13,828 food**, and ends with **500 food and 50 civilians**. Pingling alone produces 8,640 food, consumes 4,320 civilian + 4,320 garrison food, and therefore retains its initial 500, with no replenishment script. Its 90 weapons come from 2 × 15 × 3 worker-months. The 269 global weapons reflect Anping's real fifteen-hour blockade.

Original causal outputs remain: direct relief at hour 6 (53 relief soldiers, 84 carried food), offscreen loss at hour 15 before late arrival at 16, and intercepted supply retreat at hour 10 after depot capture at hour 3. Existing tests are retained rather than weakened to fit the new mechanic.

This is headless simulation/scene verification. No new M5 hardware gameplay, macOS export, manual playability or final owner creative approval is claimed by this document. The parent milestone's exact published commit and CI/export evidence are recorded separately.
