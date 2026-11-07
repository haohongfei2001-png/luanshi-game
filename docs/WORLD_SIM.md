# WorldSim: Gate 2 simulation foundation

Status: implemented and headless-tested in Godot 4.6.3. This is a pure simulation module, **not yet a playable strategic interface or a completed narrative game**. The existing battle scene and its scripts are unchanged. No macOS device/playability claim follows from these tests.

## Run

From the repository root:

```sh
XDG_DATA_HOME=/workspace/shared/godot-data \
XDG_CONFIG_HOME=/workspace/shared/godot-config \
XDG_CACHE_HOME=/workspace/shared/godot-cache \
godot --headless --path . --script tests/test_world.gd
```

Verified command result on the Dot Linux cloud with Godot 4.6.3: **526 assertions, 0 failures**. Scenario logs reported timely relief at hour 6, late arrival at hour 16 after hour-15 capture, and supply retreat at hour 10 after hour-3 interception.

`WorldSimulation` in `scripts/world_sim.gd` extends `RefCounted`, has no scene/input dependency, and uses one integer hourly clock. Instantiate through preload (`Simulation.new(184)`). The seed is recorded for reproducibility; this first model contains **no random draws**, so different seeds intentionally do not change balance. The same seed and actions reproduce the complete snapshot, messages, audit ledger and event history.

## Public contract

- `reset(seed_value)` resets all inventories, clock, reports, casualties and IDs.
- `march(route_id) -> bool` orders the player's relief army along a connected bidirectional route. Supported IDs: `road` (平陵–安平, 6h), `mountain` (same endpoints, 18h), `river` (平陵–河曲, 3h), `grain_road` (河曲–安平, 5h). Cannot redirect while moving. Destination/arrival time are on the army's `march` record; its city location is empty in transit.
- `advance(hours) -> bool` advances 0–8760 hours in exact hourly steps. Per-hour order: production, enemy supply corridor, consumption/starvation, arrivals, siege resolution, report delivery. Thus an arrival at the current hour participates before that hour's siege damage. Invalid durations do nothing.
- `transfer(from_id, to_id, resource, amount) -> bool` moves actual `food` or `weapons` between allied, co-located cities/armies. IDs are the city keys or `relief`/`besiegers`. Positive quantities only; no shortages, remote transfers, self transfers or soldier cloning. City stocks include weapons available to its garrison, so withdrawing these really weakens that city's force.
- `seize_depot() -> bool` resolves a locally superior relief force's assault on enemy-owned 河曲. It costs soldiers/weapons, captures the surviving garrison as prisoners and changes ownership of existing supplies. Already-owned, remote or insufficient-force attempts fail without mutation. This is a deliberately minimal aggregate combat model, not the existing real-time battle.
- `observe_city(city_id, delay_hours=0) -> bool` requires the relief army to be present. It creates a frozen report with a real source and observation time; optional delivery delay is 0–8760 hours. It does not allow remote omniscient scouting.
- `player_view() -> Dictionary` returns detached own-army state, public routes, the physically occupied city’s current inventory/garrison (`local_city`, empty in transit), delivered reports and the newest observation per subject. It does **not** return remote world cities, enemy army, hidden event history, pending messages or true siege outcome. A report states what was observed, not what remains true now. The UI must label its age and source.
- `snapshot() -> Dictionary` is a detached **privileged truth** snapshot for debugging and future saves, not a UI API. All state is JSON-compatible; `version=1` identifies the format. There is no validated snapshot loader in this milestone. Future persistence must validate and restore the entire snapshot including pending reports and ledger; do not reconstruct a world from player knowledge.
- `totals()` and `audit()` expose developer accounting. `audit()` returns an empty array on success. They are not player intelligence APIs.

IDs: cities `anping` (安平), `pingling` (平陵), `hequ` (河曲); factions `sheng`, `bei`; armies `relief`, `besiegers`. Returned snapshots/views are deep copies and cannot mutate truth.

## Causal model and accounting

Initial relief force has 60 soldiers, 30 weapons and 120 ration units. Armed strength is one per armed soldier; unarmed strength is half, rounded down. All city garrisons and armies use this same rule. No reinforcement or equipment is created for a player's decision.

- Army/city troops eat `ceil(soldiers / 10)` ration units per hour. Every consumed unit is ledgered. Armies lose one soldier per hour beginning with their third consecutive short-ration hour. Starvation deaths lose at most one actual weapon each, explicitly recorded as destroyed/unrecoverable.
- 平陵 produces four ration units per hour, 河曲 two. Every 24 hours each non-besieged city produces one weapon. These are small aggregate production capacities, not a civilian economic simulation; civilian population/workforce inputs are deferred. No besieged production occurs.
- The 河曲 supply corridor dispatches up to eight actual food units per hour while the depot remains enemy-owned and the siege is active. Each convoy records ID, owner, origin/destination, departure and arrival, with the same five-hour journey as `grain_road`. Transit food is included in totals. The starting besiegers carry 48 food and require eight/hour. Capture stops new departures, but existing shipments still arrive. After retreat, cargo reaching friendly 安平 turns around for a further five-hour return journey; it is deposited at 河曲 even if a new owner now captures it. If 安平 has fallen to the enemy, incoming cargo is deposited in its actual city stock. No shipment follows a marching army or vanishes. Escorts, interception mid-road and wagon visuals are deferred.
- Siege pressure is `max(1, ceil((attacking strength - defending strength) / 10))` per hour when defenders are weaker. Fortification begins at 60. Starving attackers withdraw before an assault; sufficiently strong defenders repel the attack with real casualties. Otherwise the city surrenders when fortification or food reaches zero. Remaining garrison soldiers become prisoners, and weapons/food remain in the captured city.
- Retreating enemy survivors actually march for five hours toward 河曲 rather than disappear. Subsequent combat if that destination has changed owner, re-supply after retreat, recapture, diplomacy and independent strategic AI are **not implemented**. Arrival alone does not seize an enemy city.
- Event history records authoritative outcomes for debugging. Events never automatically become current player knowledge. Outcome messengers take twelve hours, and start with a report observed 72 hours ago. Newer received observations take precedence over older messages arriving later.

Conservation equations checked after every test hour:

```text
current city + army + in-transit food = initial food + produced food - consumed food
current weapons = initial weapons + produced weapons - destroyed weapons
current active soldiers + dead + prisoners = initial soldiers
```

Captured weapons are still physical city stocks. No separate battlefield loot, prisoner nationality, individual rosters, civilian food consumption, morale, aging or character mortality is claimed here. Initial 215 soldiers and 175 weapons include all garrisons and both armies.

## Reproducible causal scenarios

1. **Timely direct relief:** depart along `road` at hour 0. At hour 6, 45 relief strength plus 40 garrison strength beats 75 attacking strength. 安平 survives; relief troops fall from 60 to 53, their food from 120 to 84, attackers from 80 to 71 and begin retreat.
2. **Late direct relief:** wait ten hours, then depart along the same road. 安平 falls at hour 15 while the player is still marching, with 40 prisoners. Arrival at hour 16 cannot rewrite that fact. Player knowledge still says friendly ownership until local observation or the hour-27 messenger.
3. **Supply interception:** march via `river`; at hour 3 seize 河曲. Four relief soldiers and four weapons are lost, 15 defenders are captured. No food is created/destroyed by capture. Carried enemy food runs out and at hour 10 they retreat, saving 安平 without the player being there.
4. **Counterfactual controls:** taking the river route without seizing the depot loses 安平; the mountain route reaches it at hour 18, after it falls, and leaves only 12 relief rations. Taking the direct road on time but leaving all 30 weapons behind cannot repel the enemy: the city eventually surrenders from hunger. These prevent the implementation from treating a route or choice label as an automatic ending.

Tests also cover co-location/ownership checks, depleted inventory, invalid IDs/resources/durations, active-march rejection, snapshot/view isolation, delayed and stale report content, newest-observation ordering, hourly/batch equivalence, full-state deterministic replay, JSON serialization and a 96-hour starvation/production accounting run. Convoy tests verify five-hour delivery, conservation before and after departure, continued delivery of already-dispatched cargo after depot capture, five-hour return after retreat and eventual deposit. Local-city visibility follows physical location and returns detached data.

## Next integration seam

Build the strategic UI only on commands and `player_view()`. Expose the player's known report timestamps rather than live true owner/food bars. Then add a versioned save loader and an explicit battle transaction: reserve a real army roster/equipment snapshot, freeze or consistently account for world time, accept a validated result exactly once, and ledger casualties and spoils. **No battle transaction is provided by this milestone**; the standalone 20v20 encounter must not yet be presented as taking soldiers from this world.
