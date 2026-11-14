# Bounded native Mac engineering baseline

This independent source branch descends from `735143aaad3e25a3d66671e336bf30cbf8dce86a`, not from an assumed byte-identical local scene. Its scene and pavilion binaries are retained unchanged. The five prior instrumentation commits are cherry-picked without activating any character experiment. The current art remains **ART_REBUILD_REQUIRED**, actual MacBook Air M5 **DEVICE_NOT_RUN**. No commercial release or main/RC overwrite occurs.

## Execution

The dedicated `dot-native-review.yml` triggers only on `dot/river-native-review-source` or manual dispatch. Existing standard public hosted Ubuntu exports after complete regression; standard `macos-latest` then uses the existing checksum/provenance-verified native engine cache, original artifact run `43580708251`, or pinned official source rebuild. It never writes repository refs or releases.

`whole_native_delivery.py` receives `--profile-uhd --wall-clock-video --wall-clock-uhd --wall-clock-action --require-river-pass-master`. Profiles are separate no-readback processes, 45 seconds each at 20/100/250/512 per side in QHD and UHD, plus the existing QHD camera tour. Readback captures target 24 samples/s but record actual monotonic timestamps and achieved sampling rate. Encoded VFR duration comes from those timestamps, not target cadence. Missing attacks, shields, damage, movement or riding remain explicit coverage limits. The fixed-step full-battle movie is separate evidence, not a real-time FPS measurement. All actual hardware, rendering resolution/scale and performance statistics are collected by the existing tools. Every profiling/capture path asserts the master when this option is supplied; full battle now receives the option too.

## Bounded recovery

No full raw JPEG sequence is uploaded. `native_evidence_bundle.py` retains complete encoded movies, timing journals, all sampled JPEG hashes and selected native JPEGs. JPEG/H264 are lossy, never described as lossless raw frames. Interrupted journals are preserved, and partial captures do not become successful evidence.

`bounded_artifact_groups.py` splits files into 60 MiB chunks and groups them into at most 120 MiB payloads, leaving 8 MiB headroom under the strict 128 MiB artifact limit. Each group is a separate upload with compression disabled. The 32-group ceiling is explicit and fails rather than silently dropping bytes. Source package, patched internal package, export logs and curated evidence have separate artifact namespaces. Failure paths run curation/upload with `always()`; missing packages are explicitly `NOT_CREATED`.

Download all groups of one namespace into one directory (`merge-multiple: true`), then:

```
python3 tools/bounded_artifact_groups.py restore downloaded-groups restored
```

The recovery manifest validates every chunk and complete original file. For curated movies already split by the curation layer, concatenate the `chunks` listed for that movie in `restored/bundle.json` and verify its complete SHA256. This is byte concatenation, not trimming or re-encoding. Never combine all persistent groups into an oversized artifact. A nonzero workflow/capture outcome remains a failure even if its diagnostic artifacts restore correctly.

## Local verification and limits

Python tests exercise exact multi-group restoration, corruption rejection, path traversal rejection, explicit overflow failure, interrupted journals and synthetic VFR timing. They are transport tests, not game footage. Full Godot regression runs against this branch's real inherited assets before publication. Hosted native measurements are still pending until the new workflow actually runs; no M5 or visual acceptance is implied by an engineering pass.
