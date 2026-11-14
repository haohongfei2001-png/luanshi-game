# First Dot environment slice: actual Godot review

Candidate `70cdb716585d3a0ac0cdd75ab5a1c670d8e3768b` was rendered by
[run 43601296024](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43601296024).
Both the RC25 baseline and candidate jobs succeeded. Candidate native images,
hardware, import/test logs and metadata are in
[artifact 14116338395](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43601296024/artifacts/14116338395).
The download ZIP SHA256 is `1784c9d28c53a17bb004668af75f3d0fc09161f0f8612271f0992cfd1538982d`.

## What was actually compared

Eight full game frames were checked against freshly rendered RC25 source
`d1c1895221c33386d471922807ed590a6987dbe1`. All corresponding seed, tick,
ordinary roster, hit counts, camera center/size, native pixel dimensions and
internal-scale fields match exactly. Seed 61112, 512 ordinary soldiers per
side, normal bridge view 22 m, steps 50/135; 2560×1440 and 3840×2160, scale 1.0.
The step135 hit counts remain 189/228. These are actual Godot output pixels,
not concepts, offline model renders or upscaled images. Full-resolution game
images were saved for the owner as separate new/old 2K files and a native 4K file.
`visual-comparison.json` records untouched image hashes and capture metadata.

## Self-review: not accepted

The generated white willow crowns are gone, the continuous little rock necklace
is broken into local groups, and complete tree canopies replace the old repeated
forms. This is a real mesh/placement replacement with unchanged combat.

However, the normal 22 m view now has too little foliage inside its composition.
The bridge-to-gate ground still reads as an empty, flat lawn; large exposed rocks
remain abrupt. The wide view lacks convincing ground and background layers.
Dense corpses/riders and remaining character/animation issues are not fixed by
the environment replacement. **This does not reach the owner's reference.**

Continue rebuilding coherent banks, road shoulders and foreground/middle/background
vegetation, with shared actor/terrain contact and tested crossing behavior.
Do not merely move all trees outside the view to claim occlusion is solved.
Preserve this rejected first comparison as a recoverable checkpoint.

## Separate verdicts

- Engineering: full local aggregate, terrain compatibility, structural audit,
  real 512v512 crossing and natural settlement/save/march checks PASS.
- Native screenshot capture: PASS. New normal-speed action film: NOT_RUN.
- New environment realtime performance and macOS candidate: NOT_RUN.
- Owner art: ART_REBUILD_REQUIRED / prior OWNER_REJECTED; no approval implied.
- Actual MacBook Air M5: DEVICE_NOT_RUN.

Hosted Linux uses software rendering. Neither screenshot capture time nor a
fixed-rate movie is a realtime hardware FPS result. All former RC24/RC25
packages and their native benchmark evidence remain separate and preserved.
