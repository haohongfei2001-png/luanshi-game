# Hosted intact source-rig review, 2026-11-14

This is a source-structure/import/animation technology lab, not Chinese character
art, real combat, foot-contact acceptance, performance approval or a release.
The original source human has bare upper body and shorts, no weapon or historical
clothes. The lab remains disconnected from the shipping scene. RC24/RC25, main
and prior source branches were not overwritten.

## Reproducible source

- Generated source branch `dot/character-native-source`:
  `bf520c13aa393c2fdc4b5c2596cfe5cbdb0bd7d9`.
- Seed `ad5266ad0f7ba748a3eacbc5c174a51c795e4200`.
- Build/still run 43610264795; source manifests and exact upstream license texts
  reside in the generated source commit.
- Actual Blender 4.0.2 signed Ubuntu package generated the editable scene.
  Official Blender 4.3.2 archive returned HTTP 403 in run 43609572840.
  Run 43609982782 then failed because distro Blender could not see numpy;
  explicit distro numpy/path fixed this, without changing runtime generation.
- Runtime GLB SHA256:
  `64705ebc4a20650b79f863bae4b6ec47df06dfefe0ed451fe73a04ebc46295c0`.
  This equals the independently rebuilt local full-source GLB.
- Editable Blender SHA256:
  `aa7311098776fd6c20dbda774764ca33ee4b11fd2e0f907cdffc31460d510504`.

## Verified scope

Godot 4.6.3 on Ubuntu llvmpipe LLVM 20.1.2, Compatibility renderer.
65 native joints and nine imported source clips. Read-only Battle adapter:
42144 assertions, zero failures, geometry/weights/Skin/rest unchanged and full
Battle/save/RNG snapshot equality. Passive 20-per-side test only observed
[43,0] hits and does NOT establish two-sided battle acceptance. 100/250/512
cases exercised the read-only adapter; no full-battle rendering performance
claim follows from these tests. Foot contact remains NOT_ACCEPTED, weapons
NOT_ATTACHED, riding clips missing, M5 DEVICE_NOT_RUN.

Stills artifact **14120435693** contains 28 actual Godot PNGs: fourteen each at
native 2560x1440 and 3840x2160, internal scale 1.0, orthographic size 3.4/22.0m,
seven exact clip poses. Pixel dimensions and source SHA independently checked
again after download. Inspected close Walk/Death and wide Sword_Attack: intact
human mesh/materials and limbs render; no claim of historical art adequacy.
These lab camera sizes do not imply same-camera battlefield comparison.

## MovieMaker resolution rejection and correction

First movie from run 43610264795 was 1280x800 because MovieMaker initializes
before the script sets its viewport. Although the later root viewport report
said 2560x1440, ffprobe disproved native-QHD output. That movie is rejected as
native-QHD evidence. This does not invalidate independently checked PNG pixels.

Corrected workflow commit `79bb747169a289147f68c772f21ddce2080dc2db`, run
**43611011643**, artifact **14120411531**, explicitly supplies boot-time
`override.cfg`, retaining its text/hash. Both 3.4m and 22m clips are independently
ffprobe-verified **2560x1440, 553 frames, 23.041667 seconds, fixed 24fps simulation
time**, source bf520c13, internal scale 1.0. This is not real-time performance.
Close capture took 2m16s on software rendering. Actual close attack frame was
opened for review. No fabricated weapon/contact or battlefield activity.

SHA256 close: `08bf526bd2c34f1cd34ac394897d21ae4b9e8cb23ee013c7c9d45bc6ffeb9b42`.
SHA256 wide: `3aa8038954d9f13e658a47b27b2ea1ccab86137a011edf91e57724a3ecc035db`.

## Resume

Fetch `dot/character-native-source` and checkout bf520c13. Do not rerun the seed
initial-create workflow against an existing source branch. Use the corrected
movie workflow or its explicit boot-time override and ffprobe hard gate.
Separate `dot/native-character-parity` work evaluates native Skin/materials
versus a complete-weight texture adapter. Its first graphics-bake gate failed;
that experiment is not a reason to enable this character in the shipping game.
