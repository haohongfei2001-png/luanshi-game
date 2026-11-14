# Complete gate assembly in progress

`build_architecture.py SOURCE.fbx OUTPUT --no-preview --native-roof-band --complete-gate-masonry` now builds continuous front/rear arch shoulders and high bearing courses beneath the native-derived timber gallery. Protected 8m gate opening and adult wall-walk route remain free in source BVH ray tests. `audit_gate_bearing.py OUTPUT/source/architecture.blend REPORT.json` verifies explicit samples and nondegenerate UV triangles; it is not proof of all continuous volumes or runtime gameplay.

New authored masonry surfaces have actual world-metre dominant-plane UVs; professional source UVs are retained. Old mixed X/(Z+Y) UV projection made vertical front faces nearly degenerate. Native-band roof has separate actual Godot evidence. These changes remain opt-in and not enabled in any delivered game.

Remaining: full stone/lime mortar/wood material system, actual normal-camera whole-scene review, complete source/runtime gameplay regression. Current plain material prototype is NOT an acceptable art candidate. Do not present it as finished structure merely because the gap is closed.
