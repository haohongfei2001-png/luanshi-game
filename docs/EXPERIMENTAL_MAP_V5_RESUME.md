# Default-off authored-map v5 continuation (local experiment)

This is a CPU-tested save subsystem, **not a released game mode or art approval**.
HF08 remains ART_FAIL. No source map payload, assets, workflow, public upload,
GPU capture or CI trigger is part of this change. This source-only branch does
not contain world data, PCKs, typed saves, trajectories or private test reports.
Reproduction requires the user's separately available, locally authorized HF08
input and a compatible locally available Godot executable. Default gameplay and
Controller/UI save paths remain disabled. A separate
explicit authored-Controller opt-in is documented in
[the Controller lifecycle check](EXPERIMENTAL_MAP_V5_CONTROLLER.md).

## Entry and boundaries

```gdscript
const ExperimentalSave = preload("res://scripts/field/experimental_map_save.gd")
var saves = ExperimentalSave.new() # disabled; every action refuses
# Only an explicitly opted-in internal caller may choose:
saves = ExperimentalSave.new(true)
var error = saves.save(existing_authored_battle, "resume")
var restored = saves.load_slot(already_verified_configured_runtime, "resume")
# Keep the old live object when restored == null. No object is adopted for you.
```

`restore(typed_snapshot, runtime)` is the corresponding in-memory explicit API.
The caller must supply the verified runtime; this module never finds, downloads,
constructs or guesses a map. Map ID, integer topology revision and topology SHA256
must all match before Battle allocation. Runtime must already have configured
navigation and the declared open gate. Navigation agent radius/height must match.
A visual/material/source revision alone does not invalidate the topology identity.

Normal `Save.restore` still accepts only versions 1–4, and `Save.save` still refuses
mapped Battles. This API does not silently enable UI paths, adopt a scene,
change the default map, or call `Campaign.bind`. The later, separate
[Controller opt-in](EXPERIMENTAL_MAP_V5_CONTROLLER.md) has bounded CPU lifecycle
coverage; exported native/UI screen acceptance remains NOT_RUN.

## Exact format, not a v5-to-v4 conversion

New authored `Save.snapshot` results remain version5 and additionally require
`mapped_state.schema == 1`. That state records each unit's authored station and
non-legacy jobs (`wall_post`, `engineer`, `ram_station`), company homes, the inert
original muster slots, sprint input and navigation agent dimensions. The normal
snapshot already includes actual positions, HP/dead state, ammo, RNG, officer
state, pending orders/projectiles, timers and command/casualty ledgers.

The shared loader allocates the same roster/weapon/stat definitions as before,
then applies saved state to the new object. It never calls `Battle.start` or
`AuthoredMuster.apply` to pretend to resume, never moves the saved positions through
legacy bank repair, never changes HP or troop counts, and never mutates the input.
The mapped branch validates and restores the saved homes/stations directly rather
than invoking legacy deployment placement. Derived spatial grids are rebuilt;
render-only transient gait/contact cues retain the existing reconstruction policy.

Earlier v5 snapshots lacked required continuation state. They are deliberately
rejected. `JSON.stringify(Save.snapshot(...))` diagnostic output is also rejected:
JSON loses Vector2/PackedArray typing and cannot safely preserve all int64 RNG
values. This change does **not** infer/repair those diagnostics or merge separately
observed fields into a claimed historical save. Use the new actual typed save.

Only `open_gate_field_no_campaign` is supported. World patrol, campaign/time/camp
changes, old bridgehead deployment, enabled world objectives, traffic/siege jobs,
closed gates and hero vehicle modes are refused. Ordinary riders, officers and
all independent ordinary troops remain present. Arbitrary new maps, topology
migration, closed-gate siege, campaign settlement and after-battle inventory work
are not implemented or claimed. Some unrelated officer validation still retains
legacy world bounds; HF08 lies within them. Do not infer arbitrary-map support.

## Independent storage and refusal behavior

Slots are always `user://experimental_map_v5/<slot>.bin`; there is no arbitrary
path API. Names contain only ASCII letters, digits, `_` and `-`, length1–48.
Even the leaf `river_gate_quick_v1` stays inside the experimental directory.
Old `user://river_gate_quick_v1.bin` and campaign files are untouched.

Files contain `LUANSHI_MAP_V5\n`, a 32-byte SHA256 digest, and a typed Variant
payload. The total file limit is8MiB. Writes validate the state first, flush a
same-directory temporary file and rename atomically. A refused state does not
overwrite an existing experiment. Reads verify header/size/digest before the
safe `bytes_to_var` decoder, never `bytes_to_var_with_objects`.
Unknown topology, incomplete schema, illegal support coordinates, invalid
casualty data, truncation, corruption and oversize return null/error. Saved
coordinates are rejected rather than relocated. Missing or disabled entry does
not touch disk. SHA256 detects corruption, not authenticated provenance.

## Reproduce the actual restart

No visual assets are needed. Supply the actual authorized navigation/source JSON
outside the checkout; do not copy or publish it as a test fixture.

```sh
python3 tools/test_experimental_map_save.py \
  --godot "$GODOT_EDITOR" \
  --source "$HF08_SOURCE_JSON" --output "$EVIDENCE_DIRECTORY" \
  --count 512 --ticks 400
```

The runner creates isolated XDG save directories, starts a writer Godot process,
waits for its successful exit, then starts a separate reader. Its
`process-restart.json` records actual process IDs, monotonic start/end times and
commands. Any engine/script error fails the runner, even if Godot prints PASS or
exits0. Reader reconstructs the runtime from source and loads the actual disk
slot; it does not inherit a live Battle or a dictionary from the writer process.
Repeat with `--count 20` in another evidence directory for the small fixture.

Writer also checks snapshots during marching with an in-flight courier, actual
contact with projectiles, and actual casualties. Each resumed branch and its
uninterrupted counterpart receive identical real inputs. Every continued tick
compares full typed Save plus a passive combat/command/projectile/RNG observation.
The restarted reader checks20 continuation ticks and the final exact typed bytes.
It also verifies pre-existing legacy quick-save bytes and a campaign-file sentinel
are untouched. The sentinel is isolation evidence, **not world settlement proof**.

To isolate legacy deserialization changes against the original loader:

```sh
git show a2d39ae2e2321dd59e55ed18352fa237d32c11b1:scripts/field/save.gd > tests/map_runtime/reference_save_unmodified.gd
# Set XDG_*_HOME to isolated test directories before invoking Godot.
"$GODOT" --headless --path . --script res://tests/map_runtime/legacy_save_version_parity.gd \
  -- res://tests/map_runtime/reference_save_unmodified.gd
```

The reference is a temporary local file, not part of this commit. This test uses
the same Battle engine for both loaders. It covers versions1–4, the originally
unsupported pre-v4 second-map boundary, both legacy v4 maps, historical missing
fields and terrain revisions1/2/3, comparing20 resumed ticks byte-for-byte.

## Actual checks (Godot4.6.3, Linux headless)

- Legacy version differential:138 checks,0 failures against original loader
  SHA256 `b611c23985b4eb76f71c61bf9662aab32b09c812383c76447d50601a1e37c267`.
- Existing tests: `map_runtime/legacy_save_boundary`, `identity_isolation`,
  `field_simulation`, `field_officers`, `field_cohort_muster`, `field_bridgehead`
  pass with no script errors. This includes real legacy512 battles, command,
  custody, world/roster regression and both original maps.
- New20-per-side:86 writer checks and49 restart checks,0 failures; tick420 has
  43 entities,17 attacks, hits[6,0], deaths[0,1]. Final typed snapshot SHA256
  `3fbd7063068c620c418fda857af5e473980e4cf054a7d4ad13911887e8b16af3`.
- New512-per-side:400tick save retains1057 entities and real existing casualties;
  after20 resumed ticks,570 attacks, hits[98,178], deaths[51,21]. Final typed
  snapshot SHA256 `79abb40a2acf1dc82cddd6a78e31b11f342463e16df11fa68c925ae8121aac29`.
  This fixture deliberately uses courier/control inputs, so it is not the earlier
  performance worker's different-input492-attack baseline.

Initial test failures were retained: a wrong header-length guard was fixed before
passing tests; the first sparse-checkout regression lacked Godot's global-class
cache and printed misleading PASS after script errors. A local headless class
scan fixed the test environment, then all affected regressions were rerun with
error scanning. No shared asset/import cache was rebuilt or deleted.

These backend-only tests did not perform native GPU, release-template, M5 frame
rate, Controller adoption, visual acceptance, world settlement or filesystem
power-loss simulation. See the later Controller check for its bounded CPU scope.
The separate
debug-template PCK checks are documented in `EXPERIMENTAL_MAP_V5_PACKED_CHECK.md`;
they do not establish any of those untested outcomes.

## Follow-up: preserve the wider MapQuery diagnostic boundary

Independent review identified that `MapQuery` does not promise `nav` or an
AuthoredRuntime. Snapshot enrichment now checks the concrete runtime type,
configured navigation, supported open-gate mode and valid topology identity.
Only that supported case gets `mapped_state`. Other non-legacy maps keep the
original version5 plus identity diagnostic, without fabricated mode/navigation
fields or a fallback to legacy. The helper itself also safely returns an empty
result for unsupported runtimes; experimental save/restore remains refused.
An unbound/incompletely identified AuthoredRuntime exposes an empty identity
instead of indexing missing source keys.

`tests/map_runtime/mapped_snapshot_boundary.gd` covers a non-authored stub with
no nav member, the base MapQuery, an unbound authored runtime, unconfigured
navigation, unsupported mode, closed gate and incomplete identity:66 checks,
0 failures. Existing512 tick400 typed output is byte-identical to the original
local checkpoint86ab3ae (307,712 bytes, SHA256
`6868c5982a37014271dc3f600d821b94208d34ef1f5b82becb49d43a504b0dfe`).
The real disk checkpoint again continues20 ticks identically (49 checks), and
v1–4 differential138 checks plus both legacy-map boundaries pass again.
The packed test defaults to `HEAD` and immediately resolves it to an exact Git
commit for dependency checks and the result receipt. An explicit
`--frozen-commit` remains available; an invalid revision or modified dependency
fails rather than silently skipping the check. Historical local checkpoint IDs
are provenance only and are not required in a public clone.
