# Production-v2 full natural-rig spear chain (WIP, not accepted)

This is independent of the old224MB43-surface evaluated oracle. Source MH163 is
read-only and all original nine actions/163 rest bones are preserved. New actions
cover spear idle, forward walk/jog/sprint and ordinary thrust. Existing real
hit/death actions remain. Rigid weapon is actually attached to wrist.R. Ordinary
infantry has no red tassel. No formal character/story decision is encoded.

`author.py -- MH_SOURCE.blend OUTPUT` writes a full editable derivative and action
contract. `merge_uniform.py -- UNIFORM.blend ACTION.blend OUTPUT` adds these to the
complete clothed mother, not a head-only shell. Always preserve scene FPS120 and
fps_base1: appending Actions alone does NOT preserve timing. A24fps intermediate
was rejected after Godot showed Walk6.667s and Death12s. Correct imported lengths
are idle2.5, walk1.333333, jog.933333, sprint.666667, thrust.7, hit.333/.433, death2.4s.

Original four-joint IK elbow/wrist draft and direct Sword_Idle crouched body trial
were rejected after actual full-body Blender images. Current source is a draft
using a natural idle body base, bounded arm lengths, measured shaft-aligned palm
and finger chain placement. Forward locomotion keeps the complete original
lower-body animation, not a vertex-pose cache. Hand/shoulder/stance/art quality
still needs the complete new mother-scene game view and continuous animation.
Authoring previews are NOT actual Godot game footage and must not be presented as it.

## Standard runtime
`shared_skeletal_actor.gd` instantiates a PackedScene with one Skeleton3D and an
AnimationPlayer. Mesh/material resources remain shared. `mh_spear_battle_binding.gd`
is defaultOFF and only reads real Battle. It needs an exact imported-GLB timing
metadata hash and the new mother scene's height resolver Callable. There is no
old-map fallback. The imported blade peak must be measured, not copied from
Guardian or assumed to equal the original120Hz author key after import resampling.
Transform interpolation only changes the presentation. Death presentation can
continue after actual Battle stops, without advancing simulation or resurrecting.

Supported forward ordinary-foot-spear states are idle, locomotion, ordinary
windup/recovery, generic chest hit reaction and death. Location-specific hits,
strafe/backwards, skills/guard, cavalry and alternate weapons are NOT completed;
unsupported samples are explicitly reported and never called real new actions.
Existing game systems/default rendering are untouched. No automatic army hookup.

Godot cold import of the complete uniform05+weapon derivative found14 actual
animations,163bones,32surfaces and16 normal-enabled material surfaces. At120fps
source export, actual clip lengths match the values above. This is a resource
contract check, NOT art, GPU performance or a playable new-scene acceptance.
The uniform05 mother is itself rejected as a final visual; later complete uniform
sources may be merged without changing the original rig or reauthoring actions.

## Actual cost and next production step
Current intermediate:56,320tri/31,903exported vertices/32surfaces/14materials.
Body mesh15,440tri (not a claim all are pixel-visible); complete coat7,436;
boots6,884;cuirass5,456;trousers2,674;helmet2,544;eyes2,040;lashes368;brows192;
weapon66. Same-material pieces are NOT already automatically batched:
lamellar9surfaces, cloth7, leather3, iron2, bindings2 plus single materials.

Do not instantiate1000 complete163-bone/32surface nodes and call that a shared
army runtime. First finish/read one complete character in the new mother scene.
Then use the same mother source: material-group mesh consolidation, view-dependent
whole-outfit LOD preserving hands/weapon/armor silhouette, reduction of tiny eyes/
boots/actually covered skin, and shared GPU palette+material MultiMesh at distance.
Eight skin influences and proper transformed tangent/normal material channels
must survive. Those LOD/crowd steps are NOT implemented or accepted by this draft.
No old incomplete-normal sprite atlas is promoted to Chinese-soldier production.

Actual Metal512 control repeat is archived separately. No further empty-body
matrix is part of this work. M5 NOT TESTED. New whole-scene GPU NOT RUN.
