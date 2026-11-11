> Transfer publication, 2026-11-11 UTC: Development is **stopped**. Only this **text-only handoff projection** is being published, not a complete runnable release. The font and build packages are not uploaded; v0.14 remains incomplete and unvalidated. The required bundled font is absent. See [transfer status](../handoff/TRANSFER_STATUS.md) for provenance, missing assets, actual verification and WIP limits. Earlier local-only/publication statements below are preserved historical records.

# Development transfer: v0.14 earned combat growth WIP

## Stop and provenance

The owner requested development closeout and transfer on 2026-11-11 UTC.
Development and additional test execution stopped immediately after the active
editor-import call returned. All current changes are being committed as WIP.
No existing checkout, branch, earlier build or evidence was deleted or reset.

- Retained final v0.13: `e64a398a4b7c0f01abfac50decd516ea57c0ba3a`.
- Retained v0.13 tree: `4f20125643bac3d29fd4c2e11118e840c4d2d607`.
- v0.13 runtime independently audited: `b71a6c96c410808fba43beb96514962b7f75d05d`.
- New working branch: `work/earned-combat-growth`.
- Separate design-sync commit: `0e525a4ddf56c774dab3f87278447a3b29444cfc`.
- Read-only canonical main: `b32de2c1d6c08297d4550b36c02ea4ba6b5bb625`.
- Ten upstream design/status blobs were verified. Canonical design was integrated,
  while newer local implementation status, old evidence and launch instructions
  were preserved. Full provenance is in DESIGN_SYNC_V014.md.

## Source written, not runtime-verified

- `scripts/combat_growth.gd`: derived eligibility from an actually settled battle
  with a living player and either personal net injury or casualties on either
  participating side. It calls this shared combat experience, never personal kills.
  No merit-register prerequisite, enemy-count multiplier or XP currency is added.
- New immutable `practiced_v1` profile: basic damage 18→21, sweep 26→30,
  lunge 34→38, basic interval 0.72→0.66 seconds. Max HP stays 100; movement,
  targeting and guard/defense remain early-profile values. No training healing.
  Existing early/late/legacy profile values and preview/calibration lists remain.
- WorldSimulation has `train_combat(1 or 2)`, up to two fed continuous world-hours,
  with real clock/rations and active-battle, marching, hostile/siege/death guards.
  Growth is restricted to early lives. Reset cannot select the earned profile.
- Closed revision-1 training events and chronological per-battle profile checking
  replace the old assumption that every historical ticket equals the current
  commander. Clock replay starts from the earliest reservation's legal original
  profile, not the grown current profile. Active tickets still require current.
- This WIP retains World8 shape rather than adding a new world field. Older
  World6/7 profile/event shapes exclude new earned identities/events. Whether this
  event-extension boundary is sufficient remains an independent audit item.
- Youth causal timing recognizes training hours. Army mixed-activity flags are
  retained; no fabricated march-fatigue or personal HP regeneration is introduced.
- Technical/youth UI controls and `tests/test_growth_ui.gd` were written. They
  attempt to preserve original choices and first-viewport map usability.

## Actual verification

- PASS: `godot --headless --path . --editor --import`, Godot 4.6.3, Linux cloud,
  with existing writable XDG data/config/cache directories. Exit 0, no
  `SCRIPT ERROR`, `Parse Error` or `ERROR:` lines in the captured import log.
- PASS: `git diff --check`.
- BLOCKED BEFORE ASSERTIONS: UI worker attempted
  `godot --headless --path . --script tests/test_growth_ui.gd` without writable
  XDG directories. The engine failed at startup (exit 134); no assertions ran.
  It was not retried after the owner's transfer instruction.
- NOT RUN: new mechanism/adversarial tests; direct offense comparison; real
  surround/death test for the earned profile; old-save matrix; all regression
  scripts; youth font/input validation; 1,499 old calibration checks; full
  `tools/test.sh`; exports; package-process restart; independent final review.
- NOT RUN: actual graphics, native macOS, M5 hardware, subjective gameplay,
  hosted CI, signing or release acceptance.

## Missing deliverables and suggested next steps for the receiving developer

1. Inspect and execute the WIP, including the UI test with writable XDG paths.
   No functional pass is implied by editor import.
2. Add a mechanism suite for real trained/untrained next-battle comparison,
   qualification without injury, survival/death, no healing/HP growth, duplicate
   settlement/save-load protection, fractional-hour split equivalence and denied
   actions. Verify both youth and technical routes.
3. Attack save replay with forged profile/source/events/time/rations/inventory,
   malformed variants and long spans, including active-session atomic rejection.
   Check cancelled/historical snapshots, old World5/6/7/8 and combined wounds,
   hometown, couriers, appraisal and petition routes. Do not weaken old assertions.
4. Add growth separate-process smoke harnesses, full-suite/export/CI hooks,
   player instructions, public sanitized evidence and release/version metadata.
   These are not written yet. No v0.14 packages exist.
5. Run existing complete tests, youth font/input and unchanged 1,499 calibration,
   then independent review and exports/package restarts only when continuing work
   is again authorized in the destination workflow.

Core story remains owner-authored and deferred. E0–E7 is a synchronized future
single-life design goal, not implemented code or a fixed dynasty/war script.

## Publication boundary

This is local source only. PR10 still points to its previous published code;
project-status comments are not source publication. The platform-required font
confirmation remains unresolved. No font upload retry, alternative upload,
remote ref update, hosted CI trigger, user-computer access or new cost occurred.
Do not infer remote publication from the existence of this local checkpoint.
