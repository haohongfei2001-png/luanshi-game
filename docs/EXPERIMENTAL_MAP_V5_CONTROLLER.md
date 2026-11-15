# Explicit production-v2 Controller save lifecycle

This is a separate, default-off CPU integration, not an art milestone. The main
Controller, main menu, ordinary quick slot and v1–4 loader are unchanged. World
settlement remains UNSUPPORTED. No map/actor asset, typed save, trace or PCK is
included with this source change. Inputs must already be locally authorized.

## Enable only the isolated entry

The existing production-v2 entry still requires `LUANSHI_PRODUCTION_V2=1` and its
verified resource manifest. Add `--experimental-save-slot=controller_resume`
after `--` alongside that manifest. Without the additional flag, the authored
Controller's save/load buttons stay hidden and F5/F9 cannot read or write a save.
The parameter does not auto-load or alter the manifest/resource-identity checks.
This change was not tested as a complete exported production-v2 entry.

Programmatic setup, in this order:

1. Configure the authored Controller and its supplied mother, source18 hero and
   optional ordinary spear actors as before.
2. Configure ordinary actors, if any, before enabling saves.
3. Call `configure_experimental_saves("controller_resume")` before adding the
   Controller to the SceneTree. Check its Error result.

Only this opt-in exposes **实验保存 F5 / 实验读档 F9** and connects the HUD signals.
The direct `save_experimental()` and `load_experimental()` methods return an
Error and require a ready, configured Controller. They use only
`user://experimental_map_v5/<slot>.bin`. Paths and cross-namespace names cannot
escape the existing backend slot validation. Generic `_adopt()` still refuses.

## Restore transaction and state boundary

The existing backend decodes and validates the typed v5 file using the exact
configured runtime. The Controller also requires the active host's map ID,
topology revision and topology SHA to match, plus compatible source18 foot-spear
actor bindings and the same ordinary roster counts/actor team assignments.
A different-size army requires its own matching Controller setup; IDs are not
silently reassigned. Unknown/corrupt files or incompatible presentation leave the
old Battle, Figures and resources in place. Both save and load preflight every
configured source18 actor before any live writes. A disposable Binding and
read-only actor probe execute the same `update_unit` selection path; the probe
checks the real clip table without sampling or stopping a live AnimationPlayer.
GUARD, ROUT, ESCAPED, sideways/backwards walking and alternate attacks without a
matching source clip are refused, not adopted with a stale pose. Refused saves
retain the previous usable slot. This deliberately restricts Controller saves
more than the backend format; it is not a claim that source18 supports all actions.

Save/load status is a separate HUD message, never a mutation of the authoritative
Battle notice. Its visibility is explicit and lasts until the next save/load
attempt, independent of the ordinary notice's 52-tick timeout.

On successful load:

- Adopt the restored Battle, never call `Battle.start`, Muster or Campaign.bind.
- Build exactly one new Figures instance and immediately remove/free the old
  instance. Rebind HUD company entries; preserve hero and ordinary crowd
  exclusions so the supplied rigs do not acquire duplicate procedural actors.
- Reuse the mother, actors, Skeletons and shared mesh/material resources. Reset
  only binding animation history, stop previous animation playback, reset bone
  poses to rest, then sample
  the restored state. Walking reconstructs gait from saved stride/displacement;
  attacks use saved duration/timer and source timing; death uses saved lost_tick.
  Transient gait/blending is reconstructed, not claimed identical to uninterrupted
  presentation. Repeated loading the same checkpoint gives the same clip/phase.
- Pause, reset fixed-step/UI accumulators, drag/orbit/follow state, camera focus,
  stale audio and input actions. Resume using the existing pause/deploy controls.

The last point clears external held movement/attack/skill/sprint actions. It does
**not** clear saved `hero_move`, `aim`, `sprinting`, `buffered_slot`, `buffer_ticks`,
`buffer_aim` or `buffer_wall`: those are persisted simulation state and remain
byte-exact until the next normal Controller input sample. HP, positions, losses,
RNG, orders and projectiles are also restored unchanged. A new real device event
after loading is new input, not part of the checkpoint.

## Reproduce the bounded CPU test

Use an asset-complete checkout with its existing imported dependencies. In a
sparse checkout, existing assets/imported resources may be referenced read-only;
do not reimport shared caches or copy a large source package for this test.
`$SOURCE18_GLB` is the existing locally authorized actor and `$TIMING_JSON` its
matching source timing metadata. `$HF08_SOURCE` is the exact configured map input.
The test uses a tiny explicitly labelled identity host, not the full mother GLB.

```sh
TEST_ROOT="$(mktemp -d -t save5-controller-XXXXXX)"
mkdir -p "$TEST_ROOT/data" "$TEST_ROOT/config" "$TEST_ROOT/cache"
XDG_DATA_HOME="$TEST_ROOT/data" XDG_CONFIG_HOME="$TEST_ROOT/config" \
XDG_CACHE_HOME="$TEST_ROOT/cache" \
"$GODOT_EDITOR" --headless --path . \
  --script tests/map_runtime/controller_save_resume.gd -- \
  "$HF08_SOURCE" "$SOURCE18_GLB" "$TIMING_JSON" "$TEST_ROOT/report.json" \
  > "$TEST_ROOT/engine.log" 2>&1
```

Require exit 0, report `status=PASS`, zero failures, and **no** `SCRIPT ERROR` or
`ERROR:` in the log. Every invocation needs a fresh isolated test user directory;
the fixture deliberately checks that its experimental slot does not pre-exist.
No critical initialization is inside an `assert`.

Observed local Godot 4.6.3 headless run after review fixes: 440 checks, 20 ordinary troops per side,
43 real units, save checkpoints at ticks 29, 323 and 349; each restored Controller
continues six ticks with exact per-tick typed Save equality. Tick29 retains a
real buffered attack (slot0, four ticks). Actual input-event save and HUD-signal
load routes, default-off input refusal, corrupt/unknown-topology failures, old
quick/world sentinel bytes, and three repeated loads per checkpoint pass.

All checkpoints retain 474 scene nodes and seven source18 Skeletons, with the
same mother/actor/shared-mesh/material identities. Natural unit21 death is
observed at tick323; at tick349 the restored Death01 phase is 0.5416666451, not a
new standing pose. Hero source thrust and ordinary walking phases are checked.
A selected ordinary source18 actor attacking was NOT_COVERED in this bounded
sample; other states are not inferred from it. Mandatory coverage gates require
buffered attack, thrust from the actual hero ID, walking from a nonhero/nonofficer
ordinary unit, and natural/aged death. The report records the qualifying IDs in
`actor_role_coverage`; generic semantic presence cannot satisfy the identity
checks, and missing coverage cannot silently turn this test green.

A real guard key and subsequent physics produce backend-valid slot3 WINDUP and
GUARD saves. Real held sideways movement produces another valid MARCH save. All
three are refused by the Controller before adoption, and unsupported UI saves
cannot replace the previous slot. Negative comparisons cover every actual
163-by-7 local/global bone transform, actor transform, AnimationPlayer state,
binding history, input/clock state and shared/surface-override material identity.
They include a deliberately poisoned presentation-only death pose; no simulation
HP/death or position is fabricated. Success compares all actual bones against an
independent source actor sampled at the expected phase and repeats the comparison
after advancing the discarded presentation timeline. Corrupt and mismatched-map
files also preserve actual bones and input state. Expired ordinary HUD notices
cannot hide the save/load success/refusal messages (`is_visible_in_tree` checked).

The final whole-fixture result (`label=final` in the report) is tick382:
33 actual attacks, hits [12,8], ordinary losses [1,2]. This includes the later
legitimate guard/sideways refusal inputs, not only the positive resume path.
No HP/position edits stage these outcomes. ROUT and
ESCAPED lack actual-event coverage here; their refusal follows the same existing
unsupported-state branch, not an asserted gameplay/animation proof.

Legacy v1–4 differential: 138 checks pass against public native baseline
`a2d39ae2e2321dd59e55ed18352fa237d32c11b1` on the same engine. These results are
not complete-mother rendering, screen UI acceptance, exported/release execution,
512-Controller performance, GPU, M5, or art acceptance. ART_FAIL is unchanged.
