# HF08 native complete-scene workflow: PREPARED, NOT RUN

Preparation branch `dot/production-v2-native-review` does NOT trigger this workflow.
The sole later activation branch is `dot/production-v2-native-run`, or explicit
workflow_dispatch when available. Do not activate while the existing independent
2.5D GPU control is running. Parent coordinator owns activation.

## Still blocked

`native_input_artifact.json` intentionally has status NOT_READY and zero mother
run/artifact IDs. The exact HF08139,477,998-byte ZIP exists locally and in Library,
but there is not yet a verified existing GitHub artifact for this workflow.
Never commit a private/expiring Library URL. Once legitimate transport is ready,
pin exact successful run/artifact IDs/name, retain ZIP SHA256
`f5ac12b501293da966a12072509550d91ac60fd5fafc283f8b55aa8475cb91f4`, and update status.
No new release, account, storage service or paid dependency is required here.

Actor source is the already-public exact gzip at commit
`16b1430166ab9d099452f7247ff0d3aa38990fbd`, under
`experiments/environment25d/assets`. Decompression must yield source18
`afb966396bf5ad656b3cb0cd2edc388fc6fa02eba59df8b81d9a23ac53f3be8b`.
Original timing and complete license packet (including restored UAL CRLF bytes)
are independently hashed. No regenerated/reshaded actor or 43-surface cache.

## Execution design

1. Restore exact HF08 package and source18 into distinct opt-in resource paths;
   validate ZIP manifest and original source/texture/license bytes.
2. Official4.6.3 Mac editor imports on THAT Mac. Collect complete actual
   transitive resource identities, including generated texture imports. Never
   copy Linux import hashes into a Mac manifest.
3. Export normal `application/run/main_loop_type=DotProductionV2NativeCapture`
   with inert bootstrap. Protected template silently ignores --script, so no
   CLI entry override is used. Original project/presets restored in finally.
4. Launch exported PCK with official editor from an independent empty cwd and
   validate exact mother/nav/actor/timing/texture closure and six ordinary IDs.
5. Reuse existing arm64 Mobile mutex-fix template from run43580708251 artifact
   `mobile-mutex-angle-template` or its exact existing cache; verify provenance
   and executable hash. No automatic engine compilation if unavailable.
6. Native executable uses `mobile`+`metal`, NOT GLES/ANGLE skin rendering.
   Host, adapter, focus, actual engine and original config restoration recorded.
   This is not the Linux-only GLES tangent-patch executable.
7. Real current-player stills at2560×1440 and3840×2160 share actual Battle state.
   Pixel dimensions come from get_image(), never misleading texture metadata.
   Actual author Sun/shadows remain unchanged. No whole-gate-fit camera gate.
8. Normal Controller physics and input-only pilot run. Source18 hero and up to
   three real foot SPEAR units per side are shown; others remain explicitly old
   diagnostic representations. No soldier type/HP/position/attack is fabricated.
9. Target24fps timestamped readback preserves actual wall-clock gaps as VFR video,
   with per-frame actual HP/action/pose/source-support/camera records. Missing
   attacks, hits, deaths or route failure are explicitly reported, not PASS.

Strict pixel, closure, or window failure remains failure. Rendering is not yet
run, art remains NOT_ACCEPTED, new-map large-battle performance and M5 untested.
Readback capture is instrumented, not an FPS benchmark. The fixed current-player
view may not contain every structure; this is not permission to shrink people.

## Preparation evidence

- GDScript native entry/recorder check-only clean on official4.6.3 Linux.
- Four Python tests: guarded normal entry, only macOS preset changed, wrong ZIP
  rejected before writes, and incomplete action/non-native dimensions rejected.
- Exact local HF08 ZIP + public-source18 gzip/timing/13 license files restored in
  independent temporary directory, with all hashes checked. Test copies cleaned,
  original source evidence retained. This is NOT a native/export-PCK PASS.
- Local whole-game source remained unchanged; default assets symlink is not part
  of any commit. Prepared workflow has not been dispatched.

## Release assertion audit (2026-11-15)

The native entry/host/Controller/actor/identity collector initialize via explicit
calls and error branches, never inside `assert`. A recursive static regression
now scans 67 GDScript dependencies and rejects new assertions. Its four legacy
predicate assertions are explicitly enumerated: Battle positive/fresh setup
(native entry checks the count before constructing a fresh Battle), two old-map
art helpers unused by the authored host, and a frustum argument predicate. None
performs initialization. This is not a claim that all legacy code is assert-free.
MapQuery abstract-method diagnostics now use persistent `push_error`, preserving
the previous conservative return values without a release-stripped diagnostic.
Five Python tests pass. Official Linux 4.6.3 editor parsing passes; actual entry
lifecycle tests reject absent opt-in and missing manifest with exit 2. These are
editor lifecycle tests, NOT release-template tests. No available local release
Linux template was established; existing tangent comparison binaries are debug.
Mac release/PCK execution remains pending. No CI was activated by this audit.
