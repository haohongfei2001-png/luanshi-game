> Publication note: ${WRITABLE_XDG_DATA}, ${WRITABLE_XDG_CONFIG}, ${WRITABLE_XDG_CACHE}, <PROJECT_WORKSPACE> and <HISTORICAL_RUNNER_HOST> are explicit placeholders for the historical environment. Substitute writable local directories as applicable. Only environment identifiers were sanitized; no test result was changed or rerun.

# Finite hero profiles: original calibration candidate v1

**Integration update:** These values now run in normal early-profile gameplay, with
explicit World5 save migration and late training test mode. The original experiment
below is preserved as evidence of scope at the time. Current verification and
remaining limits are in [HERO_PROFILE_INTEGRATION.md](HERO_PROFILE_INTEGRATION.md).
The integrated runner reproduces the same full calibration JSON hash.

2026-11-08. Isolated experiment on base `4d9c702263e016d78e92aed0d817c801e3d31078`,
Godot `4.6.3.stable.official.7d41c59c4`, cloud Linux. OWNER-03 approves the **direction**,
not these exact numbers or human gameplay feel. This is bounded evidence for
OWNER-COMBAT-01 and finite-HP risk, not completion of OWNER-COMBAT-02/03.

No WorldSim, persistence, UI, default gameplay selection, paid resources or remote
publication changed. The main scene and canonical campaign still use the old
fixture until an explicit compatible integration is made. This experiment must not
be marketed as already replacing normal campaign balance.

## Changes and exact provisional values

- `1b370b1`: `HeroCombatProfiles` data plus independent module tests.
- `8c3baaa`: **BattleSim-only experimental adapter**, separately reviewable. Apply
  its small diff to current code; never replace a newer serialized BattleSim with
  this old file. No save methods exist in this experiment's base.
- Calibration harness/tests, this report and evidence are a separate follow-up.

| Parameter | early_v1 | late_v1 | legacy_test_v0 |
| --- | ---: | ---: | ---: |
| HP / maximum HP | 100 / 100 | 100 / 100 | 360 / 360 |
| Move speed | 3 | 3 | 7 |
| Basic damage / cooldown / reach | 18 / .72s / 1.9 | 42 / .42s / 2.8 | 26 / .55s / 3.1 |
| Basic minimum facing dot / targets | .25 / 1 | .25 / 1 | .25 / unlimited |
| Sweep damage / cooldown / reach | 26 / 5s / 2.4 | 78 / 4s / 3.7 | 44 / 5s / 4.4 |
| Sweep minimum facing dot / targets | -.15 / 2 | -.35 / 5 | -.35 / unlimited |
| Lunge damage / cooldown / distance | 34 / 7s / 2.6 | 84 / 5s / 4.2 | 58 / 7s / 5.8 |
| Lunge hit radius / targets | .9 / 2 | 1.2 / 4 | 1.8 / unlimited |
| Guard duration / cooldown | 1s / 9s | 1s / 9s | 2.6s / 9s |
| Damage received while guarding | 50% | 50% | 25% |

Early and late have **identical HP, speed and defense**. Growth is attack power,
reach, cooldown and explicit skill target caps. There is no enemy-count input,
count-based multiplier, regeneration, extra life or difficulty-specific enemy
nerf. A zero target cap denotes unlimited hits **only in the legacy fixture**.
Finite caps choose nearest eligible targets, then ID for equal distance; lunge
selection measures from its start. Existing condition modifiers still multiply
basic damage, skill damage, move speed and lunge distance in the existing paths.

Ordinary opponents are unchanged: 100 HP, 13 base damage, speed 3, reach 1.65,
attack interval `.85 + U(0,.25)` seconds, damage `13 * U(.9,1.1)`. New profile IDs
return detached dictionaries. Unknown IDs fail without resetting an active battle.
The gameplay selector excludes legacy, which remains explicitly `test_only`.

## Repeatable actual-input measurement

`tests/combat_calibration.gd` constructs a battle fixture once, then exclusively
uses `set_player_input`, `use_action` and real `step(1/60)` combat. It never calls
`_hurt`, injects a damage total, respawns killed enemies or moves units by hand after
fixture setup. There are no friendly soldiers in these hero tests.

- Seeds: **184, 7, 19, 41, 73, 101, 227, 389, 613, 997**.
- Hero starts at `(0,0)`. Enemies start at `(3.6, (i-(N-1)/2)*1.2)` for N=1/2/5.
- The nearest living visible enemy is selected by distance, with stable ID order
  on exact ties. Movement/aim update every 60 Hz simulation frame.
- At most **one action per 100 ms**. Skill priority: guard if enemy within 1.9,
  sweep if in reach, forward lunge if within its distance and farther than .65,
  otherwise basic strike if in reach. Own cooldowns may reject an action.
- `advance_basic`: move toward target until within .85 of own attack reach;
  stop and use only basic attacks.
- `advance_skills`: same movement, with the above skill priority.
- `retreat_skills`: same approach, but back away when closer than .92 of own
  reach, with the same skill policy. Lunge still commits **forward**.
- No enemy cooldown/RNG inspection or future-event knowledge is used. Bots have
  perfect current positions/aim and frequent decisions, so they are not human
  playtest subjects. The field boundary and existing collision/separation apply.
- Horizon: 45 simulated seconds. No recorded run timed out.

### Results: wins / 10 seeds; mean final HP (including deaths)

| Profile / policy | 1 enemy | 2 enemies | 5 enemies |
| --- | --- | --- | --- |
| early / advance_basic | 10; 41.606 HP | 0; 0 HP | 0; 0 HP |
| early / advance_skills | 10; 76.264 HP | 9; 5.367 HP | 0; 0 HP |
| early / retreat_skills | 10; 87.469 HP | 10; 60.903 HP | 0; 0 HP |
| late / advance_basic | 10; 87.469 HP | 10; 48.114 HP | 0; 0 HP |
| late / advance_skills | 10; 100 HP | 10; 100 HP | 7; 6.677 HP |
| late / retreat_skills | 10; 100 HP | 10; 100 HP | 10; 67.792 HP |
| legacy / advance_basic | 10; 334.093 HP | 10; 308.114 HP | 10; 183.492 HP |
| legacy / advance_skills | 10; 360 HP | 10; 360 HP | 10; 343.763 HP |
| legacy / retreat_skills | 10; 360 HP | 10; 360 HP | 10; 360 HP |

Early retreat+skills takes 2.1s against one and 5.5s against two. Its five-enemy
loss takes mean 2.537s with zero kills. Late retreat+skills kills five in 3.8s,
ending at 66.802–68.931 HP. Late advance+skills dies in 3/10 trials and averages
4.7 kills. Thus positioning and action choice matter without adding any HP.
Late kills one/two in .1s with two actions; this reflects the existing instantaneous
skills and absent wind-up/recovery system, **not a claim of good animation timing**.

### Focused attacks and organized approach

The focus fixture places ten ordinary enemies at radius 1.6, all in real melee
reach and initially body-separated. Real soldier AI queues ten attacks in a single
60 Hz step. All ten seeds kill either gameplay profile without guard. With guard,
33.201–37.275 HP remains. No direct damage calls are used.

A separate 30-contact fixture queues 30 real attacks in one step and kills either
profile even with guard. **Those 30 bodies are intentionally crowded/overlapping**:
this is effective-hit resolver stress, not a physical 30-person melee formation or
an implemented arrow volley.

A more physically meaningful approach fixture starts ten separated bodies per
ring at radii 2.4, 3.6, 4.8 (outer rings rotated .12 radians). The hero stands and
uses guard once at the start. All following movement is ordinary soldier AI:

| Opponents | Early / late results, 10 seeds each | Actual scheduled hits |
| --- | --- | --- |
| 10 | all dead in 1.15–1.2667s | 13–15 total, max 9 in one step |
| 30 | all dead in .85s | 20 total, max 9 in one step |

Both profiles yield identical focused-hit results because defense and HP are equal.
This does not prove every possible escape policy loses, nor model real spear ranks,
body-blocked lunges, armor layers or archery.

## Evidence and reproduction

Run from the isolated project (or after porting the adapter safely):

```sh
XDG_DATA_HOME=${WRITABLE_XDG_DATA} \
XDG_CONFIG_HOME="$PWD/.local-config" XDG_CACHE_HOME="$PWD/.local-cache" \
  ./tools/calibrate-combat.sh
XDG_DATA_HOME=${WRITABLE_XDG_DATA} \
XDG_CONFIG_HOME="$PWD/.local-config" XDG_CACHE_HOME="$PWD/.local-cache" \
  ./tools/test.sh
```

The runner writes two independent complete 270-run matrices, 120 immediate-contact
cases and 40 organized-surround cases; their complete JSON outputs compare
byte-for-byte. Each ordinary run also records SHA-256 of every frame's unit states,
cooldowns, queued events and RNG state, plus movement distance and accepted actions.
No wall-clock timing is included in replay fingerprints.

- [Full seeds, summaries and traces](evidence/combat-calibration-v1.json)
- JSON SHA-256: `4db8d665b7d5de8aa01d7ba07cc98fde13658619ffbf9624608cffb99aef6b93`.
- [Profile, mechanics and parity tests](evidence/combat-calibration-tests.log):
  **59 + 320 + 1120 checks, zero failures**.
- Legacy parity compares complete states against source materialized read-only
  from base `4d9c702` for three scripted 20v20 battles. Original source is generated
  under ignored `artifacts/`, not copied into production.
- [Existing regression evidence](evidence/combat-profile-regression.log): all ten
  existing suites, **56,791 assertions/checks**, zero failures; headless training
  and campaign smoke tests pass. This is the pre-save base suite, not v0.6 save CI.
- Editor import and `git diff --check` pass. No GUI, Xvfb, exports, remote CI,
  MacBook gameplay, framerate or large-army performance claims are made.

An initial run inherited an unwritable XDG data path and Godot aborted before
profile tests. Re-running with the explicit isolated config/cache and shared data
variables above succeeded. No display retry or permissions bypass was used.

## Integration contract after v0.6 saves

The completed save implementation was inspected **read-only**. It has World schema
5 / envelope schema 1, closed-key typed validation, ticket-based reconstruction and
canonical outcome/receipt audit. Do not paste this experiment's BattleSim over it.

1. **Freeze meanings of saved IDs.** These are currently experimental values. Once
   released, keep `legacy_test_v0` (revision 0), `early_v1` and `late_v1` (revision 1)
   immutable. Later tuning creates a new ID/revision rather than altering an active
   saved encounter's combat semantics.
2. **Authoritative persistent identity.** Add a closed typed profile reference
   `{id: String, revision: int}` to the World commander and each reserved battle
   ticket (or its canonical hero entry). The ticket freezes the encounter's profile.
   BattleSim reconstructs its detached `hero_profile` from that reference; never
   trust a free-form saved stats dictionary. If the battle snapshot duplicates the
   reference, require exact equality with the canonical ticket. Persisting the
   entire profile dictionary is unnecessary while immutable versions are retained.
3. **Explicit old-save route.** v0.6 schema-5/envelope-1 saves have no reference:
   accept them only through an explicit versioned legacy loader/migration, preserving
   all commander HP/max HP, tickets (including committed/cancelled), units, cooldowns,
   active guard, RNG and queued events. Classify them `legacy_test_v0`; do not silently
   clamp 360 to 100, heal, recalculate outcomes, discard history, refresh cooldowns,
   or reinterpret missing fields on a current-version save. Keep existing saves
   untouched unless a normal successful save operation is requested. Unknown IDs or
   revisions must fail atomically without mutating the current world.
4. **Reset seam.** Experimental `reset(seed, profile_id = legacy) -> bool` selects a
   profile before constructing units and leaves state unchanged on unknown ID. Port
   that behavior without changing unrelated save code. `reset_from_ticket` must
   select the ticket's canonical reference **before** rebuilding hero base stats,
   applying existing unarmed rules and condition damage/speed modifiers once.
   This experiment intentionally leaves that existing function on legacy.
5. **Restore and bounds.** `export_campaign_state` / `restore_campaign_state` retain
   every existing field and validation. Reconstruct candidate identity from the
   ticket before checking immutable max HP/speed/damage/range. Replace `.55` /
   `SKILL_COOLDOWNS` validation maxima with the selected profile's cooldowns; validate
   hero guard duration against its profile (1s vs legacy 2.6s). Preserve saved timer
   values, not fresh cooldowns. Unit HP cannot exceed reserved initial HP or profile
   maximum. Ordinary soldier fields/timers remain unchanged.
6. **Canonical validation/audit.** Update closed-key ticket/commander schemas, HP
   bounds and all corresponding outcome/receipt/history consistency checks together.
   Current save code accepts hero ticket HP up to 360; new early/late tickets must
   be bounded by their selected 100 HP maximum. Historic legacy receipts remain
   interpreted under legacy rules. Keep resource/roster/settlement invariants intact.
7. **Gameplay wiring later.** New normal campaigns may explicitly choose early;
   legacy should be labeled a reproducibility/debug fixture. Existing 360 HP runs
   remain legacy rather than becoming an undocumented balance conversion. Late
   unlocks require a real equipment/experience progression system, not enemy count.
   Update help/profile labels and any hard-coded cooldown descriptions when wiring
   the live scene. Do not change all existing fixtures to early and call that parity.
8. **Required tests at integration.** Real v0.6 running, pending terminal, settled,
   cancelled, dead and life-node saves; full next-frame/whole-fight continuation;
   early/late save and fresh-process resume with active guard and skill cooldowns;
   unknown/wrong-type/mismatched profile references; oversized HP or cooldowns;
   condition modifiers applied once; no resurrection, loot replay or silent save
   rewrite. Re-run current aggregate save/scene/CI suites on the integrated head.

## Remaining gaps

No experience/unlock/equipment acquisition, late sustained multi-wave attrition,
realistic 10/30-angle attack choreography, archery, morale rout, stamina, collision
wind-up, movement-animation feel or human input study is implemented here. Early
five-enemy defeat under three policies does not prove no expert can ever win.
These seeded bots show operating space and failure risk, not statistical human win
rates or final fun. Test late cumulative kills separately before claiming the
owner's tens/hundreds progression experience. No large army scalability conclusion
can be drawn from these tiny simulations.
