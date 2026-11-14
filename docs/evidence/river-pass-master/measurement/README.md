# Native measurement entry audit

These changes measure the game; they do not modify battle state, force counts, input policy, scene layout, LOD or resolution scale. Runtime art remains the frozen master. Local verification is parser/synthetic-only, not a graphical performance result.

## Existing coverage and actual gaps

The ordinary menu/button and mapped input route already selects the bridgehead, deploys 20/100/250/512 per side, observes attacks, blocks, casualties and uses the normal 22m camera. Real-time profiling lasts up to 45 wall-clock seconds and is independent of the Movie Maker recording. Existing frame logger measures raw frame intervals, hardware/adapter, render attachment, scale, engine CPU/GPU counters and simulation stages; macOS /usr/bin/time -l supplies peak RSS. Summary computes mean FPS and P50/P95/P99 from raw intervals, not movie cadence.

Previous delivery only profiled 2560x1440. Added optional native 3840x2160 full-size runs and parser support. Both validate actual attachment dimensions and scale=1. Added optional normal-entry master-scene assertion and scene identity in the capture receipt. Added snapshot offscreen-contact lower bounds without changing AI, troop visibility or combat. Fewer than 120 captured intervals or 10 engaged seconds is explicitly INSUFFICIENT_WINDOW rather than an apparently conclusive benchmark.

Coverage is still not a universal gameplay acceptance: existing drive inputs do not mount a horse or switch through nine weapons. Receipt explicitly says mounted_player_input/weapon_switching NOT_EXERCISED. Attack/block/contact requirements are stronger on complete footage than short real-time profiles. Snapshot offscreen contacts can miss events between samples and are a lower bound, not a complete war ledger.

Existing complete-battle footage uses Godot --fixed-fps 24 --write-movie. This is native game-rendered simulation-time playback and must NOT be represented as a wall-clock-speed recording or used for performance. Real-time profiling uses no --fixed-fps and no Movie Maker. An external normal-wall-clock screen recording, with any required capture permission, is a separate still-unfulfilled recording step. Do not speed up a slow host and call it real-time performance.

## Hosted macOS invocation

On the existing disposable, authorized macOS runner with the package, already verified engine patch and focus helper capability:
```
python tools/whole_native_delivery.py "$PACKAGE_ZIP" "$ENGINE_PATCH_DIR" "$OUTPUT_DIR" --profile-uhd --require-river-pass-master
```
This retains existing QHD20/100/250/512 and QHD512-camera-tour, adds UHD20/100/250/512, then retains the complete QHD simulation-time movie. Optional flags avoid unexpectedly multiplying existing CI cost. GITHUB_SHA and GITHUB_RUN_ID must describe the actual packaged source. The script is deliberately restricted to hosted macOS and does not access the user's computer.

Equivalent exported-game profile entry (with normal UI focus and RIVER_CAPTURE_OUT/RIVER_SOURCE_SHA set):
```
GAME --rendering-method mobile --rendering-driver metal --audio-driver Dummy --disable-vsync -- --whole-battle-review --native-uhd --real-time-profile --field-profile --field-size=512 --require-river-pass-master
```
Repeat field-size20/100/250/512 and native-qhd/native-uhd. Do not add fixed-fps to profile commands. Preserve package/source SHA, raw frame logs, resource-time log, receipts and incomplete attempts.

## Hardware constraints

This Linux workspace cannot initialize its display socket; graphical calls are NOT_RUN here. Hosted M1 Virtual/llvmpipe results must retain their exact adapter name and cannot imply MacBook Air M5 testing. llvmpipe frame time may be dominated by software rendering; short samples must remain insufficient. No graphics/FPS/memory figures were fabricated. Local parser compile and synthetic summary regression passed; the synthetic samples deliberately remain INSUFFICIENT_WINDOW.
