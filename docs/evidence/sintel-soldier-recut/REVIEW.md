# Actual sewn-front replacement, still NOT accepted soldier art

Seven actual Blender production trials replaced the rejected overlay method.
The new method follows explicit shortest mesh-edge seam paths on the original
professional shirt, flood-removes the enclosed original front faces, and shares
original side-seam vertex IDs with both new front panels. The underlap's upper
edge is sewn to the original neckline path. It is one garment mesh with separate
free overlapping front edges, not another patch over an intact front shirt.
Original sleeve/back sculpt is sampled at Multires 2. This necessarily changes
indices: the original high Multires master remains unchanged in the source file;
we do NOT claim the new topology retains its original Multires hierarchy.

## What actually happened
1. Multires 1 trial removed 1,010 original front faces, sewed 39 edges on each side.
   Static render revealed an uncovered upper chest: rejected.
2. Multires 2 and full underlap closed the chest, but upper seam detached: rejected.
3. Upper edge actually shares the old neckline vertices. Static result improved,
   but the first real FK shoulder/elbow render exposed severe sleeve spikes from
   rebinding the evaluated sculpt to the author's control-mesh cage: rejected.
4. Explicit evaluated-neutral cage bind was pixel-identical to trial 3 and did NOT
   solve the spikes. The raw/evaluated neutral cage differs by up to 0.530444 m,
   but merely changing the bind snapshot was not a fix.
5. An INDEPENDENT 566-point garment envelope, offset 35 mm along original raw
   cage normals, retains all original groups and DQ Armature. The author's cage
   remains untouched for the other clothes. This actual FK render eliminated the
   previous sleeve spikes. This is one tested pose, not all-motion clearance.
6–7. Explicit matte cloth/leather/skin materials, original iris diffuse, modern
   transmissive cornea, original brow hair retained. These are new materials,
   NOT exact legacy shader reconstruction. Eyebrows remain visibly blocky and fail.

Trial 7 includes actual original 2560×1440 Blender output with the field camera's
77.5 m transform, pitch 50.775390625°, yaw −33°, vertical orthographic extent 22 m.
This is NOT Godot, and no pixel-equality with Godot lighting is claimed. Personally
inspected full-body rest/FK and the unscaled normal-frame output. Hands separate
from sleeves and garment masses remain visible; collar detail mostly disappears.
There is no armor, helmet, spear or authored grip yet. It is not the requested
finished Chinese ordinary soldier. No default integration, no art PASS, no M5 test.

The new derived envelope and topology require new response maps. Original H is
INCOMPATIBLE. Full 308-bone original interface is retained; motion work should use
that interface without adopting this unstable outfit as a completed character.

## Reproduction
```
blender --background --disable-autoexec --python-exit-code 1 \
 --python tools/art/sintel_guard/recut_front.py -- \
 /exact/guardians_r854/guardian_lao_tseu.blend /new/recut-output
```
Official exact source recovery, hashes and CC BY 3 attribution are in
`tools/art/sintel_guard/NOTICE.md` and `fetch_source.py`. No new paid assets used.
Outputs: editable independent blend, rest/FK full-body images, normal-pixel image,
and seam report. Every image is labelled Blender, not game. Local artifact hashes
include all rejected trials. No large source binary is committed.
