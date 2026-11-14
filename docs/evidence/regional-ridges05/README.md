# Whole regional terrain / horizon study05, isolated and NOT ART ACCEPTED

The actual03 destination26 frame exposes an old chain of isolated ellipsoidal
hills, bare slopes, a horizontal cutoff, fragmented trees and a flat grey world
background. None of this is considered close to owner acceptance. This study is
separate from frozen04+portal+tree input287e2ae; it does not overwrite that run.

## Connected regional structure

`authored_ridge_profile.gd` defines continuous northern/southern ridge stations,
variable crest height, asymmetric long valley slopes and shorter outer dip
slopes, with connected talus shoulders. It is original authored topography,
**not a claimed photogrammetry master or finished geological realism**. No random
surface noise or color adjustment substitutes for its shape. The explicit
regional mask x>6, abs(z)>28 keeps bridge-to-gate terrain04, all city foundations,
old open-field saves and default behavior intact. Visible terrain, Ground support
and collision continue to share the same function.

Source study output `continuous-landform-13-regional-ridges.scn` SHA256
65eb5895dd5a844e5ca1055df27d2501c4ea91e713bd11516e924b19e89c6fa5:
266 terrain tiles/collision shapes,832542 ground triangles,163109 water triangles.
368982 reachable face samples have maximum9.353mm interpolation error; protected
road7.439mm, waterline4.405mm. Actual PhysicsServer travel360 steps/25.93m has
maximum4.664mm support gap. Original512-per-side400tick simulation passes with
287 crossings,hits[488,556],deaths[136,136]. These are actual headless gameplay
checks, not normal-camera art, input footage, frame rate or M5 evidence.

## Physical sky source instead of a grey backdrop

The sky-only [Kloofendal48d source](https://polyhaven.com/a/kloofendal_48d_partly_cloudy_puresky)
is by Greg Zaal with sky edits by Jarod Guest. Poly Haven's
[CC0 asset licence](https://polyhaven.com/license) covers source redistribution.
The exact original2K HDR is5,451,493B, SHA256
5244534e9cf5b606f2ff513aa00ddb161b0a4826ffd88a0d3bd03ac29247d198.
No account, fee, subscription, terrain photo composite or third-party game
resource is involved. The panorama contains sky, not a replacement for playable
geometry. Original source remains intact; restore URL and checksums are frozen.

The direct Godot HDR loader was rejected after measurement: its RGBE9995 image
format saturated the original73216 sun channel at65408. The original RGBE data
is now decoded exactly to float32, with no exposure/color correction. Godot
resource save/reload retains original radiance and mip levels. Source decoding
has positive high-range and malformed/truncated input tests. The first API enum
mistake and early-transform test failures are retained, not reported as passes.

The original sun peak is at(1218,239), azimuth214.189deg/elevation47.900deg. Existing
river-master DirectionalLight is rotation(-48,58,0), skyward azimuth122deg. The
sky shader samples through Y rotation-92.189deg, giving full vector mismatch
0.0996deg; this aligns azimuth AND elevation, not just a similar sun height.
Environment sky_rotation is explicitly zero to avoid applying a second rotation.
Source coordinate mapping follows the engine's documented equirectangular sky
convention; final GPU direction/appearance must still be verified in game.

The optional helper requires both authored-profile05 and
`LUANSHI_REGIONAL_SKY=1`. With the flag absent, the original Environment object
and default scene are unchanged. With it present, it replaces only the study's
background/ambient/reflection source; original Sun transform, camera and
exposure/tonemap settings are preserved. Radiance cube256 is a declared budget
candidate, not a measured quality/performance conclusion. Initial sky energy1
is not artist-approved calibration. A full actual-game image, normal movement,
whole-scene composition and material judgement must follow.

## Reproduction and next closed loop

```
python3 tools/art/regional_sky/restore_source.py /path/to/sky
python3 tools/art/regional_sky/decode_radiance.py \
 /path/to/sky/kloofendal_48d_partly_cloudy_puresky_2k.hdr /path/to/sky/linear.bin
GODOT --headless --path . --script tools/art/regional_sky/build_sky.gd -- \
 /path/to/sky/linear.bin /path/to/sky/sky.res
LUANSHI_AUTHORED_LANDFORM=1 LUANSHI_REGIONAL_SKY=1 GODOT --headless --path . \
 --script tests/art_reset/regional_sky.gd -- /path/to/sky/sky.res
```

Rebuild terrain AND woodland/grass for profile05, never mix04 root placement
scenes with05. Optional source-tree navigation additionally requires
`LUANSHI_NATIVE_WOODLAND=1`. It passed current musters, but migration of an old
battle save already containing a unit inside a new trunk footprint is **NOT_RUN**.
DefaultOFF old saves remain unchanged. No teleporting armies, deleting units or
changing historical casualties is authorized as a silent migration fix.

The next meaningful gate is the complete reconstructed scene in actual Godot,
including foreground banks, mature midground cover and a coherent distant
horizon, not this report or a sky resource alone. Background silhouette, sky
color, source-tree readability and performance remain NOT_RUN/NOT_ACCEPTED.
