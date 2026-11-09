# Genuine v0.6 saves

Originally generated with Godot 4.6.3 stable official (`7d41c59c4`) using
local source commit `37beae24b60f841a5d9e1137a747271acb00695c`.
That local commit is not required for public reproduction. Published v0.6 commit
[`e86a1ad2ecbeadfba53d59a1ed6b8cebee7f366b`](https://github.com/haohongfei2001-png/luanshi-game/commit/e86a1ad2ecbeadfba53d59a1ed6b8cebee7f366b)
has the identical Git tree: `8b5bcf4f3298bf68bd9c4198e1828e5c66cda7df`.

All envelopes are schema 1, World version 5. These are real
`CampaignStore.save_slot` / `save_checkpoint` outputs, not reconstructed envelopes.
Every fixture passes the source's full restore validation and world audit.
No fixture edits HP, stats, RNG, receipts, inventory, or serialized state.
Combat deaths/victory occur through simulation.

For each name:
- `.save.json`: original compressed disk bytes.
- `.state.codec.json`: complete expected decoded campaign, encoded with the
  original `CampaignValueCodec` to preserve float/vector bits and int64 values.
- `.continuation.codec.json`: complete expected state after the operation below.
- `running.trace.json`: SHA-256 of complete exported campaign Codec JSON after
  every continuation frame's step and sync, before settlement. Array index is
  the zero-based frame index, including the first 120 frames.
- `running.whole_fight.codec.json`: complete terminal campaign after settlement.
- `manifest.json`: SHA-256 of compact Codec JSON (without trailing newline),
  plus the whole-fight trace's compact JSON hash and frame count. `source_commit`
  names the public reproduction source, `original_generation_source_commit`
  preserves the original local provenance, and `source_tree` records their
  verified identical tree.

Decode expected files with `Codec.new().decode(JSON.parse_string(text)).value`.
Do not compare these expectations using ordinary JSON numeric conversion.
A newer schema may add metadata; compare original fields after migration while
checking newly required profile/identity fields separately.

## Exact continuation operations

All initial worlds use seed 184, `advance_seconds(0.125)`,
`observe_city("pingling", 8)`, `march("river")`, `advance(3)`.

- `running`: attack order; 330 fixed steps, each synced; set movement
  `(0.3,-0.2)` and aim `(1.0,0.2)`; invoke attack, sweep, lunge, guard; step
  `0.03125` without sync. RNG has advanced, guard and all cooldowns are active.
  Continue for 120 frames exactly as `continue_running` in the generator:
  guard every 19th frame, attack every 23rd, input `(0.25,-0.125)` aiming
  `(1.0,0.35)`, fixed step, sync. Counters begin at zero. For whole-fight verification, continue this identical
  policy with frame indices 120 through 17999, stopping immediately when ended.
  Compare each full exported state's Codec JSON hash against `state_sha256` in
  `running.trace.json`, then commit the terminal outcome exactly once and
  compare against `running.whole_fight.codec.json`. No extra simulation frame
  occurs between the trace's terminal state and settlement.
- `pending`: genuine terminal victory with an uncommitted outcome. Continue by
  committing the loaded battle's `outcome()` once. Expected state equals
  `committed.state.codec.json` exactly.
- `committed`: the above victory receipt committed once. Continue by submitting
  the same outcome again; expect `ok`, `already_committed`, and unchanged state.
  Obtain the original outcome from the loaded `pending` session.
- `cancelled`: reserved ticket cancelled. Continue by advancing
  `7 * 3600.0 + 0.3456789012` seconds.
- `dead`: natural commander death with settled receipt and ended campaign.
  Continue by loading the `life_node` checkpoint. Expected state equals
  `life_node.state.codec.json` exactly.
- `life_node`: real checkpoint namespace save before issuing a battle ticket.
  Continue by advancing `7 * 3600.0 + 0.3456789012` seconds.

The full executable recipe is `../generate_v06.gd`; terminal combat input is
specified there, including actual skill use and isolated-commander death.

## Reproduce without running the new core

From a public repository checkout, fetch the published source if it is absent:

```sh
PUBLIC_V06=e86a1ad2ecbeadfba53d59a1ed6b8cebee7f366b
git cat-file -e "$PUBLIC_V06^{commit}" 2>/dev/null || git fetch origin "$PUBLIC_V06"
test "$(git rev-parse "$PUBLIC_V06^{tree}")" = 8b5bcf4f3298bf68bd9c4198e1828e5c66cda7df
SOURCE=$(mktemp -d /tmp/luanshi-v06-source.XXXXXX)
OUTPUT=$(mktemp -d /tmp/luanshi-v06-output.XXXXXX)
git archive "$PUBLIC_V06" | tar -x -C "$SOURCE"
cp tests/fixtures/generate_v06.gd "$SOURCE/generate_v06.gd"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$SOURCE/data}"
export XDG_CONFIG_HOME="$SOURCE/config"
export XDG_CACHE_HOME="$SOURCE/cache"
godot --headless --path "$SOURCE" --editor --import --quit
godot --headless --path "$SOURCE" --script res://generate_v06.gd -- "$OUTPUT"
diff -qr --exclude=README.md tests/fixtures/v06 "$OUTPUT"
```

The generator uses only its dedicated `v06_fixture_generation` campaign beneath
`user://`. It does not touch another campaign. A second generation was checked
byte-for-byte against the first on Linux with the Godot build above; all six
save envelopes, all thirteen expected-state artifacts and the per-frame trace
matched.

## Verified public-source regeneration

After verifying tree equality, the generator was actually rerun against an archive
of published `e86a1ad2ecbeadfba53d59a1ed6b8cebee7f366b`, using the same Godot build
and unchanged gameplay-generation logic. Its provenance metadata now records the
public source while retaining the original local source. All 20 gameplay artifacts
(six saves, thirteen complete state expectations and the per-frame trace) matched
the original committed bytes. Every fixture hash and the 1,773-frame trace remained
unchanged. Only the manifest's provenance fields changed.

See [the comparison evidence](../../../docs/evidence/v06-public-source-reproduction.log).
No test was changed to accept different gameplay state. Public regeneration no
longer requires access to the local-only commit.
