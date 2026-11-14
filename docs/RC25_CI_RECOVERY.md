# RC25 CI recovery, 2026-11-14

This patch repairs verification control flow. It does **not** fix software-renderer
performance or certify the art, the complete RC25 candidate, or an actual M5.
Base candidate: `d1c1895221c33386d471922807ed590a6987dbe1`. Formal PR test checkout:
`0532c0a94dacc8797d2f11671f22ba62fcad5d9b`.

## Observed failures, not inferred gameplay passes

[Formal run 43595547108](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43595547108):

- Footage job `132453651327` reached real combat. llvmpipe at1280x800/internal1.0
  measured13 frames/19.653s at20v20, mean1511.780ms;100v100 measured9 frames/19.756s,
  mean2195.074ms with42 hits during sampling. Simulation cost was1.011/4.296ms/tick.
  The capture asserted failure because the contact wait and measurement reused a
  single30-second deadline. This evidence indicates a severe software-rendering
  cost, not a frozen battle or acceptable real-time performance.
- Escort job `132453651347` expired at exactly100 seconds in the **preceding
  alternative-outcomes test**. `field_escort_gui.gd` had not started. No complete
  alternative result or escort result was produced by that job.
- Exported-input job `132453651209` kept recording and accepting real controls.
  Its last checkpoint was576/960 frames. GitHub canceled it at the35-minute job
  limit. The log's last controls and frame checkpoint show progress, not proof
  that the remaining384 frames or final assertions would pass.

Original failed evidence remains in artifacts14114872816,14114857789 and14116346503
of that run. Never substitute RC24 results for this exact RC25 source.

## Changes

1. Contact acquisition still has its own30-second bound. Once actual hits have
   occurred, measurement receives a fresh120-second maximum. Keep at least2.8s
   and **20 genuine rendered frames** (stronger than the prior10-frame assertion),
   visible fighting and additional hits. Retain unchanged roster sizes, resolution,
   camera, renderer, shadows, raw intervals, FPS and latency. Zero-frame failure
   can be recorded without an out-of-range exception. The budget is independently
   regression-tested for fast, observed-slow,5s/frame and deadline cases.
2. Alternative outcomes emit cumulative authoritative ticks across the two
   attempts, plus the current case, battle tick and frame. Snapshot progress is
   saved for failed runs. A150-second no-progress watchdog and1500-second total
   limit replace the unconditional100-second kill. Gameplay/end-state assertions,
   inputs, rosters, and1000-frame/1800-tick guards are unchanged.
3. The exported960-frame input capture retains native1280x800/internal1.0 and all
   inputs. It keeps the115-second no-new-frame limit, adds a75-minute total cap,
   and the job allows85 minutes including setup/encoding/archival. No frame count,
   output pixel count, combat assertion or video timing is reduced. This is a
   bounded offline recording allowance, not an FPS claim.
4. The shared progress supervisor now continues supervising when a child closes
   stdout but remains alive, rather than calling unbounded `wait()`. Nine real
   subprocess tests cover increasing/repeated/regressing ticks, total cap,
   silence, unrelated logs, split output, nonzero exit and closed stdout.

## Validation and recovery

Local Linux cloud with official Godot4.6.3:

- `python3 -m unittest discover -s tests -p test_record_progress.py -v`:9 tests pass.
- `godot --headless --path . --script tests/test_field_sample_budget.gd`:14 assertions pass.
- `godot --headless --editor --path . --import`:exit0, no engine/script errors.
- Both modified GDScript drivers pass `--check-only`.
- Python byte compilation, shell syntax, workflow YAML parsing and `git diff --check` pass.

The full `./tools/test.sh` aggregate completed with exit0 after these changes,
including existing four-scale field simulation, natural siege, officer/mission/
traffic/history, world/economy/hunger, save migration/corruption/restart, campaign
scene and youth compatibility suites. It logged no `SCRIPT ERROR`, `Parse Error`
or `ERROR:` markers. Two existing ObjectDB exit-leak warnings remain and are not
claimed fixed. Full output: [aggregate log](evidence/rc25-ci-recovery/aggregate.log).

No local GUI is
available in this cloud workspace (`DISPLAY` unset and Xvfb absent), so the three
repaired graphical paths are **NOT RERUN** here. Run the existing standard public
repository CI on the integrated exact source, inspect its raw records and all
three final results, and retain failures. Do not mark them passed on the strength
of parser/budget tests. RC24 remains the fallback, M5 is DEVICE_NOT_RUN, and art
remains ART_REVIEW_REQUIRED / OWNER_REJECTED.
