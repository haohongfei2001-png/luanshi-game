# Development transfer: stopped v0.14 WIP, text-only publication

**Development is stopped. This is a source handoff, not a finished release.** Only project text has been published. The required font and exported packages have not been transferred; this branch is not a complete runnable or build-reproducible delivery. v0.14 is incomplete and unvalidated.

## Choose the correct starting point

1. **Last fully locally tested source projection:** [fixed v0.13 runtime + current design checkpoint `71215500`](https://github.com/haohongfei2001-png/luanshi-game/commit/71215500d18fda0c6aeb0de885a76b6430406c11). It projects local design-sync `0e525a4ddf56c774dab3f87278447a3b29444cfc`. Its 261 non-document runtime/test/configuration files match final local v0.13 `e64a398a4b7c0f01abfac50decd516ea57c0ba3a` exactly, apart from the separately excluded font. The runtime tested and independently reviewed was `b71a6c96c410808fba43beb96514962b7f75d05d`.
2. **Current branch tip:** the stopped v0.14 earned-combat-growth WIP from local `e8000836256587e9c721d34ce56b3ee8a2b4325d`, local tree `9e9976c005af7ced2f1e58f128b84bca293db07f`. It adds unfinished growth logic, replay/schema changes, UI and one UI test. It is **not** the fully tested v0.13 source. Read `docs/DEVELOPMENT_TRANSFER_V014_WIP.md` before continuing.
3. **Independent earlier work:** `legacy-checkpoints/` retains five separate WIP text diffs. `docs/transfer/history/` preserves the text state of all 20 checkout HEADs using a fixed baseline plus a deduplicated text pool and per-HEAD manifests. These are separate recovery materials, not changes automatically applied to the game.

The previous actually accepted playable remains v0.6. Later v0.13 local verification is not a replacement for native-Mac, M5-hardware or subjective acceptance. Earlier playable work is retained, not reset or overwritten.

## What was actually verified

**v0.13, in its original local environment with the font present:** complete `tools/test.sh`; wound mechanism 314 assertions; keyboard UI 22; source and Linux package wound restart 30+22; youth font/input validation; unchanged 1,499 combat calibration/parity checks; Linux/macOS exports and Linux package restarts. Independent review added 349 adversarial and 86 old-save/combined-route checks. See `docs/evidence/wounds-v013-validation.log`. These historical results are **not a test run against this incomplete remote projection**.

**v0.14 WIP:** only Godot 4.6.3 Linux editor import (`godot --headless --path . --editor --import`, with writable XDG directories) and `git diff --check` passed. An attempted UI-test launch failed before assertions with exit 134 because its default data directory was not writable. It was not retried after the transfer instruction.

**Not run for v0.14:** growth mechanism/adversarial suite; direct offense comparison and surround/death checks; old-save/replay matrix; full regression suite; youth font/input validation; 1,499 calibration checks; exports; package-process restart; independent final review; rendered graphics; hosted CI; native macOS; M5 hardware; signing or release acceptance. No functional pass is implied by import.

**Publication checks only:** UTF-8/binary exclusion and privacy review, exact file/blob/mode comparison, patch reconstruction, historical text-state reconstruction and GitHub tree/ref readback. No further game test or export was started during closeout. Native macOS acceptance of the current work remains open; historical native-Mac logs concern older stages.

## Missing asset and delivery limits

`assets/fonts/LuanshiUISCR-Regular.otf` is absent from both publication checkpoints:

- Bytes: 3,434,004.
- Git blob SHA-1: `2e57a30a73fe2784248ecf68eb75f89c901eb56a`.
- SHA-256: `830b4d3122ba9db8c24c1f39919e414566896ab00f9e9b079df5a797144d94a2`.
- Required platform confirmation remains unresolved. No font bytes, encoding, renamed copy, compressed archive, build package or Git bundle were transferred.

The existing OFL license, source builder, coverage manifest and import metadata are normal text project records; none substitutes for the missing asset. No v0.14 build exists. Local v0.13 exported packages were not uploaded because they contain the excluded asset. Do not claim the remote checkpoint can run or reproduce those packages until the required asset and environment are resolved through an authorized process and the receiving developer verifies them.

## Provenance and recovery

`SOURCE_MANIFEST.json` maps every current original text blob to its published blob, mode and checksum. `BASELINE_SOURCE_MANIFEST.json` records the first checkpoint. `CHECKPOINTS.json` identifies the source/verification checkpoints and links the historical recovery manifests.

The published trees are **not the original complete local trees**: the font is excluded, historical environment paths and runner identifiers in public documents/evidence are replaced with clearly marked placeholders, publication notices are added, and handoff material is new. Test outcomes have not been fabricated or altered. Local commit labels are provenance, not a promise that the complete local Git graph has been published.

History recovery uses the fixed first-publication commit `71215500d18fda0c6aeb0de885a76b6430406c11`, **not this WIP working tree**, to resolve inherited baseline paths. Preserve each manifest's explicit additions/replacements/deletions and modes. The 20 HEAD text states do not recreate all intervening commits, reflogs, ignored artifacts, binary assets or original private environment identifiers. Independent historical test scripts include diagnostics that exit zero without assertive gates; preservation does not make them accepted CI tests.

`tools/calibrate-combat.sh` retains its original generic `/workspace/shared/godot-data` fallback to preserve source identity. Override `XDG_DATA_HOME` with a writable receiving-environment directory. Sanitized commands use explicit `${WRITABLE_XDG_DATA}`, `${WRITABLE_XDG_CONFIG}`, `${WRITABLE_XDG_CACHE}` and `<PROJECT_WORKSPACE>` placeholders.

## Current product direction and stop instruction

Current canonical design was synchronized from main `b32de2c1d6c08297d4550b36c02ea4ba6b5bb625`. Core story is authored by the owner and deferred until last. Historical evolution supports dynamic paths and unfixed outcomes; E0–E7 is a synchronized future design goal, **not an implemented system or a fixed war/dynasty script**. Older narrative proposals and historical “continue next stage” sections do not override those constraints or authorize new work during transfer.

No main update, PR-head update, PR creation, merge, workflow dispatch, user-computer access, new paid service or new feature work is part of this handoff. The new branch is outside the workflows' push filters; branch workflow runs are checked separately after publication. Continue only under the receiving workflow's authorization.
