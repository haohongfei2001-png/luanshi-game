# Independent per-joint grip and complete thrust review: failed

`grip_joint_fit.py` uses the original three controllable finger joints separately
for all eight fingers and two thumbs, neutral master scale1. No mesh/hand/bone
length changes. Wrist targets remain original. Full actor static Blender review
shows more enclosing fingers than the rejected uniform .80 experiment, but actual
38,346-vertex hand surface still penetrates the 14mm shaft 7.18mm at worst, 1,732
points beyond1mm. Bone centerline fitting alone is insufficient because full
finger thickness was not part of the objective. It is NOT an accepted grip.

Rendered every frame0..36 at authored24fps using render_author_motion.py and
encoded an un-interpolated 37-frame diagnostic. First-to-last authored duration
is1.5s. This is Blender authored-time playback, NOT actual realtime Godot footage.
Full double-hand/shaft/torso review exposes original attack-path failure: rotating
the shaft while moving its center back .20m drives the butt through the torso and
occludes the second hand. Nine measured phases retain7.16–7.27mm hand penetration.

A bounded alternative center offset(.42*q,-.08*q-.12*extension,0) was actually
rendered at0/18/36. It visibly breaks the other arm and misses wrist target by
269.8mm, therefore REJECTED and not integrated. Moving a rigid weapon sideways
without coordinated body/shoulder mechanics is not a solution. Next authoring
must include whole-body stance/torso/shoulder articulation with explicit hand
surface thickness and reach constraints; do not alter combat timing to conceal it.

Actual local diagnostics: character-diagnostics/sintel-guardian/grip-joints5/.
37 originals: motion/0000.png..0036.png; authored-time24fps-NOT-GODOT.mp4.
Editable joint-grip.blend and thrust/soldier-single-thrust.blend remain separate.
The current stable945b cache and field interface are untouched and still failed
artistically. All experiments default off.
