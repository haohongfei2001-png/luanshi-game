# Youth military life slice (World7)

This is a playable systems milestone, not the complete life narrative or a final
literary script. The ordinary names and dialogue remain provisional. It extends
WorldSim, the existing BattleAdapter, real-time battle, economy and free saves;
it does not replace the three-city technical scenario.

## New life and authority

`World.new(seed, profile)` still creates the original technical campaign. Its
commander receives no invented age. `start_youth(enlistment, motivation)` is legal
only on a pristine new World7 early-profile campaign. Migrated World5/6 saves have
`origin=legacy_campaign`; even an untouched old save cannot silently become a
fifteen-year-old life. Starting another life requires a real reset/new campaign.

Enlistment is `forced` or `volunteer`; motivation is `survival`, `merit`, or
`homeland`. All begin at fifteen, with age subsequently derived from world time.
The profile remains `early_v1`, 100 maximum HP. Forced/volunteer service changes
initial food and military standing. Survival changes actual rations, merit
changes standing, and homeland changes comrades' initial trust.

The existing 60-person relief force is reorganized, not duplicated: 55 soldiers,
25 weapons and the unused food return to allied Pingling. The patrol retains the
player and four individually identified soldiers, five real weapons and 10–16
food. The recruit can signal a preauthorized withdrawal but cannot order attack
or follow. Its initial attack order is the superior's. BattleSim enforces this,
not merely disabled buttons.

## Real sequence

1. Three hours down the river, with normal feeding, fatigue and off-screen war.
2. A real 5-versus-3/4 patrol combat. Enemy soldiers and weapons are reserved from
   Hequ's existing 15-person garrison. Undeployed defenders remain there. Winning
   this patrol does not capture the whole city. Merit is actual enemy deaths plus
   one for victory, not a dialogue reward. An empty-handed withdrawal or death
   is a legitimate early endpoint.
3. Three hours back to camp. The officer and clerk learn the result only when the
   player returns. The officer credits most unregistered merit to himself. The
   player record and the officer's `reported_merit` are distinct persisted facts.
4. One meaningful response, using real time and food rather than four labels on
   the same outcome:
   - Endure: one hour, two food from camp, standing +2; a survivor's trust -1 and
     the clerk's respect -1, no evidence.
   - Appeal: six hours, six food, standing -2; a living witness recovers up to two
     merit and gains respect +2. With no witness, the contested roster recovers
     only one. The superior loses the corresponding credited merit.
   - Keep evidence: two hours, one food, a private roster copy and survivor
     trust +1. No private evidence is automatically disclosed to the officer.
   - Protect a comrade: three hours, no food award, standing -3; one actual
     survivor transfers to camp and gains trust +3. The temporary squad cap is
     four rather than six. With no surviving comrade this action is unavailable.
5. Two hours of preparation and an actual commission from the superior. Existing
   Pingling manpower fills the authorized cap; equipment shortfalls and up to
   twelve food are transferred from its actual pool. Repeating the action cannot
   create another appointment or duplicate its resources.
6. Three hours to the dangerous mission, against 6/7 existing enemy soldiers.
   Victory, extraction and commander death come from combat. The same individual
   allies carry through both battles; exact dead IDs determine character deaths,
   survivor trust/respect/grievance and the remaining roster.
7. Survivors take three hours back. Four-hour replenishment draws new identities,
   people, weapons and up to eight food from the real camp pool. Alternatively,
   finish without replacements. Refusing the order beforehand returns the
   soldiers and removes the appointment's command authority.

The short-slice endpoint preserves army state, losses, evidence, merit,
relationships and timeline. A living endpoint ends this content slice, not the
character's entire life. Actual commander death ends the run. Free loading of an
old checkpoint restores the whole earlier world; it never resurrects a person
inside the current world's chronology.

## Public presentation API

- `world.youth_view()`: player-known stage, available `choices` (id, label,
  description, hours, enabled, reason), battle readiness, age, rank, merit,
  standing, evidence, appointment, relationships, incident account and endpoint.
- `world.youth_action(id)`: atomic legal action, returning `ok` or a refusal reason.
- Existing `adapter.begin_local_depot()`, `sync_world()`, `settle()` and `resume()`
  handle both youth encounters. Ticket `purpose` and `command_authority` describe
  their authority. No UI writes narrative facts or resource quantities.
- Existing CampaignStore slots and complete-life checkpoints remain free and
  include active and finished-but-uncommitted battles.

## Persistence and audit

World7 adds explicit mode, origin, youth state and ticket purpose/authority.
Transport envelope v1 is unchanged. World5 migrates through the exact World6
legacy-profile migration; World6 then receives technical-mode metadata only.
Genuine World5 fixtures and genuine World6 fixtures retain their original bytes,
complete state and reproducible combat continuation.

The youth reducer is replayed from bounded, typed world events on detached load.
It checks phase order, authored action duration, issued authority, exact roster
identity, battle receipts, evidence, public/private knowledge and every derived
relationship. Resource replay verifies the relief force and Pingling inventories,
Hequ's actual casualties, transfers, production and food consumption. Global
population, equipment, food, clock, reservation and once-only-receipt checks still
apply. Invalid input never partially adopts a candidate world.

## Verified controls and honest limits

Run `bash tools/test_youth.sh` with Godot 4.6.3, or the full `tools/test.sh` suite.
The combat driver uses only movement, aim, orders and the four combat actions.
No HP, position, kill or result injection is used for gameplay proofs.

Measured seed184 examples:
- First patrol: 5v3 victory in 8.8 seconds, no allied deaths, 12 undeployed enemy
  soldiers remain. The officer does not know it before the report returns.
- Dangerous mission: timed guard/attack/sweep/lunge wins 6v6 in 11.67 seconds,
  93.32 player HP, three named comrades dead. Their replacements are new people.
- A four-person protected-comrade squad delaying withdrawal loses three actual
  field comrades and extracts; the protected soldier remains at camp.
- Reckless movement in the same six-person mission produces actual player death.

The first provisional 8-enemy patrol was measured as excessively lethal for the
current early profile and simple tactical controls. It was explicitly calibrated
to 6/7 before acceptance; no hero stat, hidden immunity or forced casualty rule
was introduced. This is not a broad difficulty/user-feel acceptance claim.

One separately labeled validation fixture injects terminal unit damage to test
the no-surviving-witness branch. It is excluded from real-combat proof records.
Headless checks are not graphical playtesting or MacBook Air M5 verification.
This slice does not implement captivity, family, romance, inheritance, large
politics, currency wages, ordinary-soldier persistent wound recovery, or a full
independent long-term NPC life simulation. Those remain later milestones.

## Verification record

Frozen source `97726ee` passed the complete `tools/test.sh` suite on Linux cloud,
Godot 4.6.3, with exit code 0 and no Godot error markers. This includes the
existing world, economy, hunger, transaction, save, invalid-type, boundary,
profile, genuine World5 continuation and scene regressions, plus 536 youth career
checks, 40 genuine World6 migration checks, 2,201 youth corruption/atomicity
checks and 13 + 14 checks across separate save/restart processes. The 12 World6
fixture files were also regenerated from source `84cc5f8` and matched their
committed SHA-256 digests byte for byte.

Evidence: [full log](evidence/youth-core-full-tests.log) and
[real-control outcomes](evidence/youth-combat-results.json). The earlier test
failures found during implementation (typed-event checks and migrated-origin
expectations) were fixed and the entire frozen source rerun; no old test was
removed or weakened. This record does not replace the separate integrated
presentation and graphics checks.


## Integrated v0.8 verification (2026-11-09)

Implementation `bb6654f` combines the finite-profile, youth core and actual UI.
The complete source suite, youth UI/input suite, deterministic calibration and
macOS/Linux exports all passed on official Godot 4.6.3 in the Linux cloud.
Evidence: [source](evidence/youth-integrated-tests.log),
[UI/input](evidence/youth-integrated-ui.log),
[calibration](evidence/youth-integrated-calibration.log), and
[exported runtime](evidence/youth-integrated-export.log).

The integrated review found and fixed two observable defects: empty-handed
withdrawal claimed an unperformed march to camp; prolonged fighting could exhaust
rations and then make the actual return journey roll back because named losses
were not recorded. Starvation now removes the same named people as the world
loss event, stops narrative time/actions on actual protagonist death, and records
protection interrupted by a witness dying. No rewards are granted after death.
The new clock-boundary fixture deliberately stretches a legal tactical time step;
it is not a claim about normal combat duration or balance. Its 65 + 24 checks
include independent-process continuation, cause/identity corruption and duplicate
loss rejection. Presentation fixtures separately distinguish starvation and combat.

Source UI: 59 scene assertions, seven isolated text checks, actual movement/aim,
first-battle damage, dangerous-mission casualties and physical retreat. Packaged
Linux prepare/resume: 30 + 29 checks, identical complete World7 endpoint with 284
events and world time 72023.8479166667. Packaged acceptance has no dependency on
test files, which are excluded from the exported game. The same entry points are
now required by native macOS CI. Neither headless result proves graphics, M5
performance or human enjoyment; exact integrated graphical/native CI is pending.
