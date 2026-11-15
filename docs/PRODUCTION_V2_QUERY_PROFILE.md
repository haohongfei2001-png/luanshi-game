# Source004 query profile and bounded exact cache

CPU only, shared cloud machine, actual512 ordinary soldiers per side,1057 total entities,seed61112,400 actual Battle ticks. No readback/GPU/M5/FPS claim. Times include instrumentation and other cloud workloads; one pair is not a statistically stable hardware benchmark.

The initial full phase split showed navigation configure5.507s, continuous422-step probe0.301s, setup/muster0.172s, actual400-step loop172.012s. Nested inclusive query times must not be added: waypoint139.56s,8.89million support calls104.24s,6.56million body checks12.84s,32,148AStar calls4.96s,72,966LOS rays0.867s. Thus AStar itself was not the main measured cost.

The source bridge-bank connector correctness fix is separate and changes legitimate unit paths/hits. After that fix, a new identical-input baseline was taken. Cache OFF and both cache versions have the exact same full Save SHA:

`838b746066cd11cd8f59828d2f30de381d1e796ec5a25af638cc95beeac7a5ec`

All per-unit states, checkpoints, attacks, hits and losses are also equal. There were101/216hits and60/24losses. This is genuine combat, not a reduced or frozen army.

## Exact cache

Per immutable support instance, key is exact float32 Vector2 coordinates plus that instance's tagged surface ID, encoded in a Vector3 without coordinate quantization. No same-cell/nearest-height substitution. Different overpass surface IDs never share a result. Unknown/unconfigured queries do not poison later configuration. Results are read-only. A fixed32,768-entry FIFO bounds memory; no unbounded global dictionary or every-step full cache clearing.

40,000 uncached/cached exact support queries, repeated hits, eviction/recompute, original layered-surface tests, and cold-unconfigured lookup tests pass. The actual400-step full snapshot above also matches exactly.

Measured400-step instrumented wall times:
- cache OFF:157.076s;Godot static allocator peak210.436MB.
- first empty-surface-only cache:149.573s;peak234.724MB.
- final exact-coordinate+surface-ID cache:148.679s;peak234.620MB.

Final support cache hit2,361,634 /8,884,233=26.58%, peak32768entries. Improvement is only about5.3% in this observation, with roughly24MB additional allocator memory. This does not meet a fluid real-time thousand-person target and is not a performance victory. Godot static allocation is NOT process RSS; process RSS was not captured by this fixture.

The remaining structural cost is many full source can_travel segments for each actual-position-to-lookahead waypoint. Future optimization must retain the actual moving point's valid connector and obstacle/portal checks. Do not infer that a prevalidated graph edge makes a diagonal from an arbitrary nearby soldier position safe. Any changed path-selection semantics require separately disclosed correctness/causal evidence, not a false identical-result claim.

Reproduce with `tests/map_runtime/production_battle.gd -- SOURCE_JSON LAYOUT_JSON 512 400 OUTPUT_JSON profile-nocache` versus `profile` (explicit sixth argument). Both keep real battles and only enable query timing during the simulation section. Source004 remains a functional prototype, not final topology2 or art.
