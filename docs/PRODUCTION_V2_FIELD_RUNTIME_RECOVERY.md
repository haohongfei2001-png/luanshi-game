# Production-v2 functional Battle adapter (not visual acceptance)

This slice is default OFF. The shipping maps continue through per-Battle LegacyMapRuntime. There is no global terrain replacement or save migration.

## Actual verified scope

The frozen author terrain004 sidecar is a **functional prototype only**, with 17 architecture/gate footprints. It is not the new coherent art mother scene, lacks final tree/rock solids, and must never inherit the visual identity of the forthcoming mother mesh.

`authored_muster.gd` applies only to an unstarted new Battle. It retains all ordinary soldiers, hero/officers, weapons, HP and mounts; validates every placement before mutation; uses source spawn/reserve/goal/retreat semantics. Internal mode is explicitly open-gate, no ram, no siege and no campaign/world objective. These are initial mode restrictions, not attacks or destruction evidence. New snapshots use version 5 plus topology identity; writing a new-map quick save returns ERR_UNAVAILABLE before touching the old slot. Old versions remain legacy. New-map persistence and siege/world settlement are not delivered.

Final actual CPU runs using seed61112 and unchanged genuine combat:
- 20 ordinary per side, 43 entities: natural result at tick540,111 attacks,hits[47,45],losses[9,7],two delivered orders.
- 512 ordinary per side,1057 entities:400 ticks,697 attacks,hits[109,213],losses[60,24],two delivered orders. All active units remain on valid source support and outside solids.
- A continuous waypoint/travel probe crosses multiple lattice nodes, bridge and gateway in422 real movement steps. This guards the discovered nearest-node oscillation, rather than checking only existence of an AStar path.
- 19,872 source obstacle queries match the unindexed reference exactly. Source-volume segment rays now check flying projectiles above water rather than requiring walkable terrain underneath.
- All eight legacy cases (20/100/250/512 per side × both existing maps) have exact full Save snapshot hashes before/after the Battle/officer/save changes. See evidence/production-v2-map-runtime.

CPU total times include graph construction, continuous movement probe, muster, simulation and instrumentation. They are NOT FPS, GPU or MacBook Air M5 measurements. GPU has not run. The hero remains idle in these CPU army tests; these are not player input/animation proofs.

## Failed attempts retained

Initial20 and600-tick diagnostic never reached enemies because route[0] pulled moving units back to their closest lattice node. Fixed via reachable forward lookahead, never direct-through-wall goals. First512 timed out after300seconds; its200-tick partial counts are not a completed result. Broadphase point indexing and exact segment queries allowed the final400-tick run to finish. Final20 differs from the earlier sampled-ray result, so do not claim identical new-map combat across that geometry-query change. Subsequent performance optimizations must compare against this final baseline.

Earlier real20-forward JSON aliased checkpoint hit/loss arrays; final totals/raw log were correct. The final test duplicates arrays and records genuine per-checkpoint values.

## Reproduce

With the matching frozen source sidecar and scene_layout.json (not an arbitrary newer mother mesh):

```
godot --headless --path . --script tests/map_runtime/production_battle.gd -- SIDE_CAR_JSON SCENE_LAYOUT_JSON 512 400 OUTPUT_JSON
```

Use `tools/art/gate_structure/run_capture_checked.py LOG 300 --` around Godot to fail fast on script errors. Exact original files and full logs remain in the coordinator's shared recovery storage. Published summaries include full-evidence hashes, not a claim that the full source topology is checked into this branch.

## Next

Finish the complete default regression, then wire a default-OFF actual Controller entry to one complete authored mother scene and the new Skeleton hero. Preserve the mother's Sun, environment, material and geometry, validate map identity, and do not create old terrain behind it. Final mother topology revision2 must rerun capacity/travel/combat; terrain004 PASS does not transfer. One WIP new hero and old crowd is a diagnostic mixture, never completed army art.
