# Optional exact native query experiments: source-only candidate

This commit is based directly on public stage2 commit
`83fdcf026e44b5a4a8136f13edfeb46109d91139`. Its diff contains generic algorithms,
test code and this contract only. It provides no authored geometry, manifest,
nav-surface data, stored battle state, trace, raw performance report, binary,
workflow or deployment. No game constructor is switched by default.

## Build and local inputs

Tested scope: official Godot `4.6.3.stable.official.7d41c59c4`, Linux x86_64,
editor headless; godot-cpp `10.0.0-stable`, API4.6, template_release, single
precision, C++17, `-ffp-contract=off -fno-fast-math`. SCons is fixed at4.10.1.
The existing build recipe verifies the official dependency archive SHA256
`ebbf64f0f8f8b8b66bc4bc4d3797db97f95b19cf0dfb5b3f8cf56683d9df7db4`.
Use a clean vendor/build directory for a reproducible build; dependency sources,
objects and resulting binaries remain ignored. Retain `LICENSE.godot-cpp.md`
when distributing an independently built library. No engine build is required.

```sh
python3 -m pip install SCons==4.10.1
native/hf08_query/build.sh
python3 native/hf08_query/run_local_exact.py \
  --godot "$GODOT_BIN" --source "$AUTHORIZED_INPUT" \
  --output "$EXTERNAL_RESULTS" --checks boundary
```

Supply a **separately authorized local input** yourself. The runner never fetches
it, includes it in source, uploads anything, or falls back to another source.
Both input and generated evidence must be outside this checkout. It refuses a
changed engine, protected public core source, manifest SHA256 or topology:

- Input SHA256: `28f93aecc08a099b06aae9c70bb5ce070653a1850b0417baa3493f93a5e9b753`
- Topology: `0b1d24868d11505f3e980a8eb456df7e55035203490b1d1df8384ba5622bd140`

`--checks boundary` is the default. `--checks combat400` explicitly runs one
original-GDScript/fused pair of the fixed seed61112, 512 ordinary soldiers per
side, 1057 entities, 400 ticks, with a600-second bound per process. `--checks all`
requests both. No retry weakens a limit, source identity or equality check.
Generated local geometry-derived results are not intended for publication.

## Exact algorithm contract

Existing original GDScript validation, ordered triangles, solids and cells
remain authoritative. Default Battle, Save, muster, authored query, rendering
and Controller code are unchanged.

1. The public scalar-support kernel preserves float32 vector subtraction/cross,
   double scalar barycentric arithmetic and thresholds, then float32 position.
2. The public stage2 constructor batches identical ordered support points. It
   speculatively computes some points that a later body/slope rejection discards.
3. `experimental_native_obstacle_navigation.gd` optionally moves the body loop
   into a typed kernel. Containment and nearest-segment points call the same
   official Geometry2D engine methods. Candidates keep their original order.
   Scalar height/radius arithmetic stays double; vector distance stays float32.
   Gates, radius and height remain call-time inputs, not cached state.
4. `experimental_native_fused_navigation.gd` keeps portal admission and step-count
   arithmetic in the original caller. One native call performs point generation,
   from/to support, body and slope checks in original order, returning at the
   original first failure. Scalar coordinate differences remain double, Vector2
   construction/length float32, and the slope threshold double. No required
   sample, obstacle, damage, entity or early-return condition is removed.

Missing libraries, explicit disable and unsupported/extreme cases retain the
original fallback. Only the tested Linux x86_64 library is selected. Other
platforms need their own build and exact tests; no Mac/ARM/GPU/M5 claim is made.
Small synthetic test planes/rectangles are generated mathematically in test code;
none is derived from or encodes the unavailable authored map.

## Existing bounded evidence and reuse boundary

The implementation carried into this source-only candidate passed 507,887
support Variant-byte checks, 417,700 body Variant-byte checks, 55,915 sampled-point
byte checks, 2,622 travel decisions, all8,882 graph nodes and their ordered connections, four
continuous routes, 20/512 musters and missing-library fallback. An additional
2,652-case observer compared original and fused decisions plus exact planned,
visited, body, slope and first-rejection counts, including slope thresholds.

One shared Linux CPU pair observed stage3 **60.895603s** versus fused
**46.677878s** for400 instrumented ticks, a23.35% reduction in that pair, not a
stable benchmark, FPS or real-time result. It produced492 attacks, hits[93,139],
losses[38,22], two delivered orders and no illegal active units.

All6,687,085 body checks and16,955 shot-segment checks remained. Both planned
921,833 segments /8,920,771 samples. Fusion visited6,721,064 samples, avoiding only
2,199,707 speculative samples after the original early return. GDScript body
crossings became zero while native body checks stayed6,687,085. A missing
GDScript timing counter does **not** mean zero body CPU. The local verifier was
corrected to treat absent zero-call keys as zero; no candidate change or
workload rerun was used for that correction.

At ticks0/100/200/300/400, `var_to_bytes` of the unchanged original Save.snapshot,
a separate mapped-state supplement and the complete typed event stream matched
both the paired control and original GDScript. The final261,028-byte snapshot
hash was `c92536b9e0d54d01b07779f39bfe14fcb095d0c0e69d7e8aad0b1960651e38c6`.
No corresponding payload is provided here. Earlier JSON.stringify snapshot
comparisons were diagnostic JSON only, not type/precision or recovery proof.
These typed comparisons also do **not** prove actual Save.save/load/resume;
that is separate recovery work. The test keeps missing map fields separate,
without silently rewriting the old Save schema.

This source-only transposition reuses the byte-identical tested C++ algorithms;
its newly generated toy fixtures and standalone runner receive targeted checks.
It does not claim a new400-tick performance run simply because code is repackaged.
No source publication or CI is performed by these scripts.
