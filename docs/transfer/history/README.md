# Historical HEAD text recovery

This directory preserves the text states of 20 recorded development HEADs. It is a data archive, not executable application code. Original source bytes are unchanged. Documentation/evidence may be explicitly sanitized.

First-layer immutable publication: `71215500d18fda0c6aeb0de885a76b6430406c11` (tree `1d4d76f64adf8b5eefefc88c1eba9ab71c52c30a`). This differs from original source baseline `0e525a4`; source/evidence mappings are explicit.

## Contents

- `BASELINE.json`: tracked non-font text catalog for source baseline `0e525a4ddf56c774dab3f87278447a3b29444cfc`, with original and published hashes. Its source SHA is a provenance label, not the publication commit.
- `BASELINE_PUBLICATION.json`: immutable first-layer publication commit used by all `storage.baseline_path` references. Use that commit, never the second-layer WIP working tree.
- `heads/*.json`: per-HEAD additions/replacements, exclusions and paths absent from baseline, with executable modes and checksum inventories.
- `objects/*.txt`: deduplicated SHA-256-addressed UTF-8 text, including historical source. The `.txt` extension prevents accidental Godot script discovery.
- `HEADS.json`: branch labels, original HEAD/tree identifiers, and per-HEAD restoration fingerprints.
- `REDACTIONS.json`: original/published document checksums, line ranges and explicit replacement text. Removed private metadata is intentionally not reproduced; original line hashes identify it. This is an audit, not a reversible patch.
- `COMMITS_OUTSIDE_LATEST.json`: SHA, parents and subject metadata for 65 commits outside the latest source ancestor chain. This is not a transfer of their Git objects or full history.
- `VERIFICATION.json`: file-only, read-back reconstruction results for all 20 HEADs.
- `INVENTORY.md`: human-readable transfer scope and limitations.
- `SHA256SUMS`: checksums for the supplied files, excluding itself.

## Reconstruction procedure

1. Select one HEAD manifest. Create a new, empty recovery directory outside the active game checkout. Never overlay a historical state on the live project.
2. Start with the path-to-entry catalog from `BASELINE.json`. Remove only the catalog keys in `delete_from_baseline`, then replace or add keys from `replace_or_add`. The deletion list describes catalog membership, not a command to delete live files.
3. For each resulting entry, resolve `storage.object` relative to this directory, or read `storage.baseline_path` from the exact first-layer publication commit in `BASELINE_PUBLICATION.json`. Verify `published_sha256` before writing. All paths must remain relative, without parent-directory traversal.
4. Write bytes exactly and restore each entry's Git mode (`100644` or `100755`). Do not synthesize the omitted font or recover it from another encoding. Document differences are expected only where `byte_exact_to_original` is false and a redaction record is supplied.
5. Verify the canonical inventory hashes. Rows are sorted by relative path and encoded as UTF-8: path, NUL, Git mode, NUL, the file SHA-256, LF. `original_source_inventory_sha256` uses only `source_text` entries and must match byte-exact originals. `published_all_text_inventory_sha256` covers all reconstructed text, including sanitized documentation. The original all-text inventory is provenance and differs when documentation is sanitized.

## Verification and limits

Serialized manifests and on-disk text objects were read back and all 20 catalogs reconstructed in memory. Every path set and Git mode matched the original non-font tracked tree. All 3,211 source-file instances matched their original Git blob and SHA-256. No game code, tests, Godot imports, exports or existing project writes were performed.

The pool has 284 objects and 3,656,035 bytes of text. Forty document variants have explicit transformations. No font bytes, binary asset encodings, builds, bundles, ignored artifacts or raw private reports are included. One binary asset path, `assets/fonts/LuanshiUISCR-Regular.otf`, is omitted only from HEADs that originally contained it. Standard generic source defaults remain unchanged; environment-specific paths and runner identifiers in documents are sanitized.

This preserves 20 HEAD text states, not every intermediate commit, unreferenced object or complete original Git graph. Original SHA labels do not mean the original commits can be checked out from the publication repository. The missing font means the current stable/WIP text snapshots are not complete runnable or build-reproducible releases. Historical test evidence is not a fresh pass of this incomplete text transfer.
