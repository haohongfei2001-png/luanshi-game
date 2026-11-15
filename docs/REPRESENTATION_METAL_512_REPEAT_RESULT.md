# Bounded512 counterbalanced repeat: preserved result, no further matrix

Source2849d32c3415e1e50b56adc9e97f3e95804fc9e6; [actual successful run](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43654648297).
[Evidence artifact (GitHub login)](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43654648297/artifacts/14136804875).
ZIP SHA256131da6a6e975a2db3afcc62b1f3463afb45659092d79d6f7673cc5bae7499254,304600 bytes.

Same original UBC source/materials/LOD1/atlas/fixed lens/contact trajectory,512 ordinary troops each side.
Real Battle250–570,320ticks,16seconds, neutral hero inputs, no screenshot readback.
Same snapshot and camera-track hashes across all four. This is not Chinese-soldier art acceptance.
Mobile Metal Apple M1 Virtual; M5 NOT TESTED. Native2K pixel proof is from preceding43651982237,
not a new readback in this repeat.

| Order | Mode | FPS | P50/P95/P99 ms | Frames | maxRSS bytes |
|---|---|---:|---|---:|---:|
|1|sprite8|79.81|9.147/25.642/35.587|1278|522289152|
|2|shared3D|46.42|19.794/31.129/45.902|744|476020736|
|3|shared3D|47.89|19.819/26.763/37.728|767|429752320|
|4|sprite8|82.53|9.281/23.374/27.758|1321|475906048|

Independent nearest-rank percentiles; inverse-mean interval FPS.
All cases retain >120frames and >10seconds, no lowered gate.
Before/after swap usage0; queried free-memory percentages76–79%.
These are point-in-time host snapshots, not continuous pressure or GPU residency.
RSS is not VRAM. Simulation wallclock mean4.109/6.986/6.147/3.760ms;
view mean5.888/6.137/5.809/5.794ms. Different render sample counts include differing numbers
of zero-simulation frames; do not infer pure GPU causality from those wallclock blocks.

The preceding512 sprite51.27FPS/no-gain observation did not reproduce.
This repeat shows a benefit for this specific shared8way representation, so that earlier result
cannot justify rejecting sprites. It does not settle art quality, atlas budget, shadow/depth fidelity,
production costume/weapon cost or a final runtime route. No further matrix is authorized by this report.
Current priority is one complete production-v2 clothed natural-rig spear soldier with real basic
actions in the new whole scene. Technical control assets are not production candidates.

Recovery: unpack artifact and run `python tools/representation_metal/check_repeat.py <directory>`.
