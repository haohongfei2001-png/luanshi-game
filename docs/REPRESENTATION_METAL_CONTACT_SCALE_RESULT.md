# Same-source representation: bounded contact-window Metal result

Source: 67f01c39130b27fe79be443ce5bc60767b388852.
[Successful actual run](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43651982237).
[Evidence artifact (GitHub login required)](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43651982237/artifacts/14137360159).
ZIP SHA256: 02183e6e51ecb9d93c94a9666722c0bdf977df42a52fe875368e05fe721e3d91.

Technical gates PASS. Art NOT ACCEPTED. Real MacBook Air M5 NOT TESTED.
This is unclothed UBC control geometry, not the new Chinese soldier and not a playable release.

## Fixed conditions
Existing Apple M1 Virtual, macOS 26.7.2, three cores, 7GB; Godot Mobile Metal.
Actual screenshots 2560×1440, internal scale1; independent profile contains no image readback.
Identical original source/materials, explicit shared3D LOD1, unchanged original8-direction atlas,
seed/input/Battle snapshots and exact fixed-tick camera trajectory verified per paired case.
320 actual simulation ticks over at least16 wall seconds, >120 rendered samples.
Real attacks, damage, death and settlement retained. Neutral hero input; not player-control acceptance.
Actual contacts determine camera focus without changing lens or squeezing the full roster onscreen.
Track generated from true Battle prepass before profiling; O(1) replay, visibility reuses existing projection.
100/250 use ticks50–370;512 uses250–570. Window selection is simulation-based, not FPS-based.
Across-count values are typical-contact cases, not a pure single-variable scaling curve.
The earlier20-per-side static-camera run is separate.

## Observed result
FPS = inverse mean frame interval. Percentiles here use nearest-rank; raw engine summary uses
floor(N−1), so its P95 may differ slightly. Both raw intervals and summaries are retained.

| Per side | Mode | FPS | P50/P95/P99 ms | max RSS bytes | visible alive min/median/max |
|---|---|---:|---|---:|---|
|100|shared3D|79.92|11.698/16.096/21.858|427540480|5/31/73|
|100|sprite8|107.62|8.849/12.233/15.930|472121344|5/32/73|
|250|shared3D|66.63|14.739/17.277/19.147|428818432|23/61/82|
|250|sprite8|95.27|10.349/14.606/17.016|474021888|23/61/82|
|512|shared3D|51.20|18.698/22.918/29.812|430522368|78/131/205|
|512|sprite8|51.27|14.448/37.256/49.662|475430912|78/131/205|

Alive visibility counts screen centers, not pixel-perfect occlusion. Conservative counts include corpses:
512 median526/527, max626. Full1024 ordinary roster is simulated, not all simultaneously visible.
All six native images were inspected: populated combat/death scenes, architecture/tree occlusion,
no blank or missing atlas pages. Sprite direction quantization and shadow/edge differences remain.

512 did not improve average FPS in this run and had worse tails. This is NOT a demonstrated GPU cause:
simulation wallclock mean increased5.147→8.434ms and view5.168→7.780ms as well.
Fixed run order and shared cloud scheduling/resource stalls can confound inference; a bounded
counterbalanced512 repeat is the next diagnostic, not an automatic whole-matrix rerun.

Shared palette349440 bytes; original high-resolution atlas308134592 compressed mip bytes.
~45MB RSS difference is NOT VRAM. Engine allocation counters are not measured GPU residency.
This atlas budget is a particular600px-class source choice, not the minimum possible sprite cost.
Alpha-edge fix, smaller frame sampling and near3D/mid-far hybrid remain separate experiments;
none changed this baseline. No route is selected as final.

## Recovery
Artifact contains scale-comparison.json, hardware.txt, per-case raw intervals and
visibility/camera records plus native captures. Recheck with:
`COMPARE_SCALE_MATRIX=1 python tools/representation_metal/check_smoke.py <unpacked-artifact>`
