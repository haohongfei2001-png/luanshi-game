# HF08 exact native support experiment

Opt-in Linux x86_64 prototype only. Default `authored_support.gd`, navigation,
Controller, rendering, ordinary counts and battle rules are untouched. No macOS,
Windows, ARM, GPU, real-time FPS or owner art acceptance is claimed.

## Build

Requires a C++17 compiler, Python 3 and official PyPI SCons 4.10.1. The build script
fetches official MIT godot-cpp `10.0.0-stable`, verifies its archive SHA256, and
uses API4.6, single-precision vectors and a minimal RefCounted/OS build profile.
It builds no engine. Source + dependency + Linux build occupied43MB here; the
shared library was2.3MB. Vendor sources, objects and binaries are ignored.

```sh
python3 -m pip install SCons==4.10.1 # use a project venv/target if preferred
native/hf08_query/build.sh
```

`-ffp-contract=off -fno-fast-math` protect the kernel's operation order. Shipping
on another architecture requires its own binary build and exact-regression run.
Retain `LICENSE.godot-cpp.md` with distributed binaries.

## Exact contract

The unchanged GDScript validator constructs triangles and1m cells. The native
kernel snapshots their float32 vectors, exact float64 denominators, surface IDs
and candidate-slot order. It changes no cell, acceptance threshold, obstacle,
portal, slope rule or sample count. Vector subtraction/cross round to float32;
u/v division, `1-u-v`, threshold comparisons and height interpolation stay
float64; the final Vector3 rounds height to float32. No fast-math/quantization.
Same-surface updates, coincident seams, explicit overpass errors, unknown tags,
and dictionary insertion order are preserved. Extreme cell coordinates and
non-finite input fall back to the original engine implementation. Invalid native
index input is rejected instead of permitting out-of-bounds access.

The adapter is selected only by an explicit test argument, not by the default
navigation constructor. Missing library or unsupported platform keeps the
GDScript path. `native_enabled=false` also selects that path. Native performance
tests assert the kernel was actually loaded, so fallback cannot fake a speedup.
The optional directory is excluded from automatic Godot resource scanning.

## Reproduce

Set writable XDG_DATA_HOME, XDG_CONFIG_HOME and XDG_CACHE_HOME before Godot.
Use official Godot4.6.3 and exact HF08 `mother-manifest.json`, SHA256
`28f93aecc08a099b06aae9c70bb5ce070653a1850b0417baa3493f93a5e9b753`.
`LAYOUT_JSON` is `{"bounds":{"x":[-60,84],"z":[-42,42]}}`.

```sh
godot --headless --path . --script tests/map_runtime/native_support_parity.gd -- SOURCE_JSON parity.json
godot --headless --path . --script tests/map_runtime/source_capacity_routes.gd -- SOURCE_JSON routes.json native
godot --headless --path . --script tests/map_runtime/production_battle.gd -- SOURCE_JSON LAYOUT_JSON 512 40 baseline.json profile
godot --headless --path . --script tests/map_runtime/production_battle.gd -- SOURCE_JSON LAYOUT_JSON 512 40 native.json profile-native
cmp baseline.json.snapshot.json native.json.snapshot.json
```

`native_support_unavailable.gd` tests the missing-binary fallback; run it with
the optional `.so` absent, then restore the binary before native tests.

## Measured boundary

507,887 byte-identical query comparisons (including1,000 explicit-fallback
queries), full HF08 triangle vertices/centers/edge midpoints, random points, cell
boundaries, layered/conflicting/reversed geometry and invalid input pass.
All4continuous routes and20/512 rosters match the original HF08 preflight.

Same40real Battle ticks, seed61112,512ordinary soldiers/side,1057entities:
17.824s baseline to11.211s native in one shared-cloud CPU pair (37.1% less).
Support calls and cache hits are unchanged; support inclusive time10.414s to3.766s.
A final guarded-source rerun took10.656s, with the same fullSave bytes. Do not
interpret the rerun as an additional stable speed estimate or an FPS result.

All Save bytes and unit states match exactly, SHA256:
`b177e17b8093cabb02a6f6d2c37183451e452518790ebea1a9963b5f9dc9fc3e`.
There were1056moving units, zero illegal positions and no attacks/hits/losses yet
in this early marching phase. This is not later combat/contact verification.

Godot's static allocator grew about8.36MB in the pair; native STL allocation is
not fully counted and this is not process RSS. The result clears the prespecified
20% small-workload gate but remains far from real-time thousand-person gameplay.
See `docs/evidence/production-v2/hf08-native-query.json` for exact measurements.

## Stage two: ordered segment batching (separate opt-in)

`experimental_native_navigation.gd` batches only immutable support calculation.
The original caller still computes the same `ceil(distance/.25)` step count;
native uses the same double ratio cast to float32 lerp weight. It returns packed
ordered sample coordinates, support errors and float32 positions in one call.
No sample is dropped. Portal admission stays before sampling; every body/gate
and slope check remains in GDScript in its original order, with current call-time
radius, height and gate state. No graph edge replaces an actual-position segment.

The batch speculatively computes support beyond an eventual obstacle failure.
This is safe only because configured support geometry is immutable. This changes
support-cache FIFO contents/hit counts, not query results or battle state. It is
not a byte-identical cache-instrumentation claim. No native obstacle/portal cache
or permanently captured gate state is introduced. Segments beyond65536steps or
safe coordinate range fall back rather than truncating or approximating.

```sh
native/hf08_query/build.sh
godot --headless --path . --script tests/map_runtime/native_segment_parity.gd -- SOURCE_JSON segments.json
godot --headless --path . --script tests/map_runtime/native_support_parity.gd -- SOURCE_JSON support.json
godot --headless --path . --script tests/map_runtime/source_capacity_routes.gd -- SOURCE_JSON routes.json native-batch
godot --headless --path . --script tests/map_runtime/production_battle.gd -- SOURCE_JSON LAYOUT_JSON 512 40 single.json profile-native
godot --headless --path . --script tests/map_runtime/production_battle.gd -- SOURCE_JSON LAYOUT_JSON 512 40 batch.json profile-native-batch
cmp single.json.snapshot.json batch.json.snapshot.json
```

55,915 sample-coordinate/error/position byte comparisons and2,622 complete
segment decisions match, including repeated gate changes and body dimensions.
All8,882graph nodes have exactly the original ordered connections. The507,887
scalar-support checks still pass after sharing the internal evaluator. Four
HF08routes and both army deployments match; missing-library support/navigation
fallback and explicit batch disable pass.

One new paired40tick observation: single native10.997s to batch7.170s (34.8%
less), with exactly the same231,048Save bytes and unit states as stage one and
the original baseline. All910,489body checks and2shot checks remain. Native
batch generated1,024,058support points. Additional speculative calculation is
not soldier or collision reduction. Query profile `support_us` now excludes
batched support work: never present that smaller counter as total support CPU.
Native counters are read after final validation and include those final probes.

This is still slow early marching, with no hits yet. It is not real-time/FPS,
later-contact, GPU, Mac or M5 evidence. The default constructor remains unchanged.
See `docs/evidence/production-v2/hf08-native-batch.json` for exact scoped results.
