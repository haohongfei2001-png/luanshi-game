# World-backed local battle transactions

## Implemented scope

The Hequ depot action now uses real world inventory and people through
`WorldSimulation → BattleTicket → BattleSimulation → BattleOutcome → WorldSimulation`.
It is a small local encounter, not an implementation of every battle in the final
specification. `docs/PRODUCT_DECISIONS.md`, the final design and the owner's resolved
creative-decision index remain authoritative. The current numbers are reversible prototype
balance, not final protagonist strength or approved final army scale.

The standalone training encounter remains 20 friendly soldiers, 20 enemies and a
separate commander. A **campaign** is different: relief's **60 people include its
commander**. A maximum 20-person friendly deployment therefore consists of 19 ordinary
soldiers plus that commander. His death removes one actual person, once. The initial
15-person depot deploys all 15 defenders; no placeholder enemy or weapon is added.

## UI boundary

```gdscript
var adapter := BattleAdapter.new(world)
var start := adapter.begin_local_depot()
if start.ok:
    var battle := adapter.simulation
    # The existing input actions and fixed-step loop operate this simulation.
    battle.step(BattleSimulation.FIXED_DELTA)
    adapter.sync_world()
    if battle.ended:
        var settlement := adapter.settle()
        # Show campaign ending only after settlement.ok.
```

- `begin_local_depot()`: `{ok: true, ticket}` or `{ok: false, reason}`.
- `simulation`: the actual simulation owned by this world's active transaction.
- `sync_world() -> bool`: consume only this battle's unconsumed elapsed time.
- `settle()`: `{ok, already_committed, battle_id, result, depot_captured,
  campaign_ended, elapsed_world_time, spoils: {weapons}}` on success. On refusal it
  returns `{ok: false, reason}` and leaves world state unchanged.
- `result`: `victory`, `retreat` or `commander_dead`. A local `victory` does **not**
  necessarily mean depot capture if unengaged defenders remain.
- `player_view()` adds `time_seconds`, `campaign_ended`, `commander` (alive/hp/max_hp/army)
  and `active_battle` (empty string or ticket ID). It still does not expose remote truth.
- `battle.report()` keeps the existing ordinary-soldier counts, excluding the separately
  reported commander. Use `alive_count(0, true)` for the full campaign deployment.

Lower-level WorldSim methods for tests/inspection:

- `create_battle_ticket(location = "hequ") -> Dictionary`
- `battle_ticket(battle_id) -> Dictionary`: detached canonical ticket copy.
- `start_battle(battle_id) -> BattleSimulation`: repeated starts return the same running
  object, never a fresh army; cancelled/committed/unknown IDs return null.
- `cancel_battle_ticket(battle_id) -> bool`: only before starting.
- `sync_battle_time(battle_id) -> bool`
- `validate_battle_outcome(outcome) -> Dictionary`: read-only validation and reason.
- `commit_battle_outcome(outcome) -> Dictionary`

A paused or closed strategy panel must not discard a running adapter. An explicit
**new campaign** resets the entire world and is distinct from replaying the standalone
training battle. Battle IDs include a campaign generation, so an old result cannot
settle against a new campaign on the same world instance.

## Reservation and equipment

Tickets record location, start time, stable battle ID, participating force IDs,
reserved individual roster entries, deterministic tactical seed and status. IDs for
aggregate ordinary soldiers are scoped to the encounter; the commander has a persistent
identity. Forces are not copied or deducted from world totals during reservation.

For each side, `count = min(20, world soldiers)`. Weapon allocation is proportional:
`floor(min(soldiers, weapons) * count / soldiers)`. Thus the initial relief force's
60 people and 30 weapons produce 10 armed and 10 unarmed participants. The other
40 people and 20 weapons remain in the world as reserves. The same rule applies to
large enemy forces. This avoids selecting a free fully armed elite while presenting
that as representative army scarcity.

A blank weapon string is actually unarmed: no spear or shield mesh, short reach and
reduced attack damage. An unarmed commander retains a basic punch and guard but cannot
use spear sweep or lunge. No cooldown is consumed by rejecting those weapon skills.
The world weapon category is still generic; assigning its existing stock the spear
silhouette is a prototype representation, not creation of an extra item.

While reserved/running, both forces are locked against another ticket, marching,
transfers and the legacy aggregate depot action. Free reserves remain available to
coarse-world attrition; reserved people and weapons cannot also be killed/destroyed
by that update. All reserved people remain included in world food/upkeep until
settlement. Battle-detailed per-casualty food consumption and hunger effects on the
local participants are not yet modeled.

## One clock and offscreen simulation

World time is in seconds (including fractions), with the original hourly simulation
processed at each actual hour boundary. Battle elapsed time is not rounded to a full
hour or taken from the display report. March and report deadlines retain the exact
second of departure/observation; intermediate deadlines are processed before the
next hourly economic tick. Legacy `arrives_at` is a ceiling-hour display estimate,
while `arrives_at_seconds` is the actual deadline. Reports also carry
`observed_at_seconds` and `reported_at_seconds`; within-hour freshness is respected.
Synchronizing twice at the same elapsed value
is a no-op. The UI synchronizes while combat proceeds; settlement synchronizes any
remainder. Strategic wait commands are rejected while the battle owns that clock.

The existing production, food, convoys, marching, siege and delayed reports continue
through those boundaries. A distant city may fall while the player fights. Locks only
protect the local reservation from duplicate losses; they do not freeze the world.
No remote truth is added to the player's view. Local post-battle observation is allowed.

## Settlement rules

1. Validate without changing world state: known running ticket, ended bound simulator,
   exact matching outcome, original roster/weapon/identity membership, bounded finite
   health/time, actual retreat extraction, unchanged force location/locks and audits.
2. Synchronize unconsumed battle time and subtract each actual dead participant once.
3. Apply equipment accounting:
   - Victory: dead friendly weapons are recovered into the same force inventory;
     dead enemy participants' weapons transfer from depot inventory to relief.
   - Retreat or commander death: dead participants' weapons are unrecovered and
     explicitly ledgered as destroyed. Surviving participants keep their weapons.
   - Depot food and nonparticipant equipment stay at the depot; no automatic loot
     teleports them to the army.
4. Only if all real garrison people are gone does a local victory change depot owner.
   Unengaged defenders stay alive and keep control after a partial local victory.
5. Release locks, persist commander health and record the complete outcome and receipt.
6. If the commander died, append the campaign-ending event **after** battle commit.
7. Run conservation audit. Any failed settlement audit restores the complete world
   snapshot, including clock, events and reports; the running session remains retryable.

Matching repeated commits return the saved receipt with `already_committed: true`
without changing anything. Conflicting repeated, forged, malformed, unknown and
unfinished outcomes are rejected. The result dictionary is data, not authority: it
must match the world's bound simulation. This is an in-process trusted-simulation
boundary, not a cryptographic anti-cheat or safe execution of hostile GDScript.

## Retreat and unsupported cases

Withdrawal requires the actual commander to pass x < -27 and all surviving ordinary
friendly participants to reach x ≤ -25.5 while under the retreat order. Closing a UI
or setting an arbitrary result string is not withdrawal. It preserves surviving
people, not dead equipment or imaginary spoils. Survivors remain in the same strategic
Hequ location; leaving for another city still requires a real route and travel time.

Commander death ends the local fight. Survivors are settled without inventing an
unseen continuation or capture, and the campaign then ends. Wounded/captured/missing
roster fields are explicitly empty at this stage. Ordinary soldiers' persistent injury,
reinforcement waves, enemy strategic response to repeated raids and retreat pursuit
remain pending. Commander HP does persist between encounters.

For aggregate world attrition, ordinary relief soldiers are removed first. If its
last person is lost, that person is the commander: health and alive state become zero/
false and the campaign-ending event records the actual cause, such as starvation.
The audit rejects a living commander with no remaining relief person. `advance()` and
`advance_seconds()` are autonomous simulation APIs, not player commands; they can
continue the independent world after this life ends for simulation/QA. The presentation
must block waiting and all other campaign actions once `campaign_ended` is true.

Anping siege combat is still the older aggregate scenario. The old `seize_depot()`
method remains a deterministic compatibility scenario for earlier world tests only;
the interactive depot button must use this adapter. It cannot bypass active locks.

Save/load of an in-progress bound battle and durable transaction receipts across a
process restart remain **pending**; a JSON world snapshot is debug data, not a claimed
complete campaign save implementation. Multi-world outcome import is unsupported.
No claim is made that WRL-07 save/reload acceptance or all G2/G3 requirements are done.

## Reproducible tests

Linux cloud, Godot 4.6.3:

```sh
export XDG_DATA_HOME=/workspace/shared/godot-data
export XDG_CONFIG_HOME=/workspace/shared/godot-config
export XDG_CACHE_HOME=/workspace/shared/godot-cache
/usr/local/bin/godot --headless --path . --script tests/test_battle_transactions.gd
/usr/local/bin/godot --headless --path . --script tests/test_battle.gd
/usr/local/bin/godot --headless --path . --script tests/test_world.gd
```

The transaction suite includes exact clock boundaries, repeat synchronization,
26-hour offscreen siege/attrition stress, local-only/no-teleport checks, representative
scarcity and missing weapon meshes, two-sided equipment accounting, reserve survival,
physical retreat, death ordering, malformed/forged/repeated outcomes with unchanged
snapshots, stale campaign IDs, repeated deterministic real AI battles and rollback.
Controlled damage fixtures isolate settlement arithmetic; separate real fixed-step
battles verify that actual combat can produce and settle a terminal outcome.
Headless assertions are not a claim of final combat feel, graphical acceptance or
MacBook Air M5 performance.

Latest focused verification: **293 transaction + 33 standalone combat + 526 original
world assertions**, all passing in the cloud. UI/aggregate CI are verified separately.
