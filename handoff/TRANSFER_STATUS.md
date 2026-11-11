# Text-only transfer checkpoint: verified v0.13 runtime + current design

This is the first publication checkpoint for development transfer on 2026-11-11 UTC. It preserves the final verified v0.13 runtime with the current design synchronization, before unfinished v0.14 work. **This branch is not a complete runnable game delivery.**

## Source and verification provenance

- Local source snapshot: `0e525a4ddf56c774dab3f87278447a3b29444cfc`.
- Local source tree: `c9eb913e6389e4682dd12d2ffa8ffcfdcd98b2a1`.
- Last fully tested local v0.13 checkpoint: `e64a398a4b7c0f01abfac50decd516ea57c0ba3a`.
- Audited/runtime-tested v0.13 source: `b71a6c96c410808fba43beb96514962b7f75d05d`.
- Current canonical design reference: main `b32de2c1d6c08297d4550b36c02ea4ba6b5bb625`.
- All 261 non-document runtime, tests and configuration files match final v0.13 byte-for-byte, excluding the separately identified font. `SOURCE_MANIFEST.json` records every original/published file blob, checksum and transformation.

The v0.13 local result passed complete `tools/test.sh`, wound mechanism 314 assertions, keyboard UI 22, source/package wound restart 30+22, youth font/input checks, 1,499 calibration/parity checks, Linux/macOS exports and Linux package restarts. Independent review added 349 adversarial and 86 old-save/combined-route checks. The recorded evidence is `docs/evidence/wounds-v013-validation.log`. These historical local tests included the locally available font. They were **not rerun against this incomplete remote checkpoint**.

Actual graphics, native macOS execution for the current v0.13/v0.14 work, the user's Apple M5 hardware, subjective playability, signing and formal acceptance are **not verified**. Older native-macOS logs concern older stages and are not acceptance of this checkpoint. No hosted CI is requested or triggered for this handoff.

## Required asset missing

`assets/fonts/LuanshiUISCR-Regular.otf` is intentionally absent:

- Size: 3,434,004 bytes.
- Git blob SHA-1: `2e57a30a73fe2784248ecf68eb75f89c901eb56a`.
- SHA-256: `830b4d3122ba9db8c24c1f39919e414566896ab00f9e9b079df5a797144d94a2`.
- Required platform confirmation is unresolved. No font bytes, alternate encoding, archive, package or bundle were transferred. The source builder, OFL license, coverage manifest and import metadata are text project records, not the font itself.

This checkpoint cannot be called complete, runnable, or build-reproducible. It includes no exported build packages. The receiving developer must resolve the missing asset through an authorized process before claiming runtime or export reproduction.

## Deliberate differences from the local tree

The font is omitted. Historical environment paths and runner host identifiers in project documents/evidence are replaced with explicitly marked placeholders; test outcomes are unchanged. README/status carry a publication notice, and handoff files are added. Therefore this published tree and commit are **not equal to** the original local tree and commit. Local SHA references are provenance labels, not a promise that the complete local Git history exists on GitHub.

`tools/calibrate-combat.sh` retains its original generic `/workspace/shared/godot-data` fallback for source identity; set `XDG_DATA_HOME` to a writable local path in the receiving environment. Reproduction commands in sanitized documentation use `${WRITABLE_XDG_DATA}`, `${WRITABLE_XDG_CONFIG}` and `${WRITABLE_XDG_CACHE}` as explicitly substituted paths.

## Transfer behavior

Development is stopped. No feature work, PR creation, merge, main update, PR-head update, hosted workflow dispatch, paid service or user-device access is part of publication. A later handoff commit may preserve the stopped v0.14 WIP and the independent legacy text patches. That WIP is not a validated release; use this first checkpoint when reviewing the verified runtime baseline.
