# Controlled full actor reconstruction, independent and NOT accepted

After two failed free-generated walking atlases, this route returns to the same
editable mature source actor. Original Guardian308 body/control bones and full
MakeHuman163 head-module bones remain. New own armor weights do not replace,
truncate or pretend to be the original cloth/cage deformation. Hidden imported
UAL65 donor is an authoring reference, not a new runtime skeleton requirement.

## Actual work and self-rejection

- `spearman_carrier_rebuild.py`: removes rejected KIT armor completely. New full
  circumferential breast/back/side carrier and short broad curved split tassets.
  Inner shoulder follows torso, outer follows upper-arm with graded weights,
  rather than binding an entire barrel rigidly to the arm. Source clothing and
  head remain editable. First trial stopped at missing underarm coat surface.
  Second rendered but its stepped neckline/floating flat plates were rejected.
  Third projects individual plate vertices to the underlying complete garment,
  reducing the floating cards. **Still rejected**: gray slab appearance, visible
  shoulder breaks and inadequate coherent shoulder/chest transition. It is not
  approved historical soldier armor or the desired finished normal-view art.
- `spearman_grip_study.py`: uses the ORIGINAL hand IK and native finger bend
  controls, with an actual complete2.86m wooden spear and forged point, no tassel.
  First target made right wrist unreachable by26.35mm. Second reaches both wrist
  goals (L7.66µm/R10.53µm), but real finger enclosure/contact remains visibly
  inadequate. Wrist-target error is NOT proof of a correct grip.
- `spearman_controlled_walk.py`: actual rest-aware UAL Walk on original author
  controls, complete source actor evaluated at33 phases/1.333333s. Imported donor
  is explicitly selected from newly imported objects, not mistaken for MH163.
  Original driver data retained. First trial correctly failed on nonexistent
  `neck` control; corrected to actual `neck.01`. Both half-cycle rendered poses
  personally inspected: legs genuinely alternate, not duplicated generated
  frames. Foot/shoe contact, armor clipping, posture and finger grip remain
  unaccepted. Target ankle maxima~0.429m are recorded, not concealed by lifting
  the ground or freezing feet.
- `spearman_single_thrust.py`: independently authored37 samples/1.5s aim/thrust/
  recovery, no game damage/timing changes. First trial rejected for weapon-parent
  transform error and76mm unreachable wrist. A corrected second trial explicitly
  sets parent-space bind and reduces extension within arm reach. Actual peak pose has now been inspected: maximum wrist target error fell to
  51.94µm, but rear shaft/body clearance and real palm/finger enclosure remain
  inadequate. It is NOT an accepted attack. Reachability alone does not prove
  weapon handling or coherent whole-body combat movement.

All trials are Blender authoring diagnostics, NOT Godot gameplay. New armor,
shoes/puttees, sleeves, material layering and hand contact still need real art
work. These scripts are not loaded by shipping. No old H response mapping is
reused on changed garment indices. Full source files stay unchanged.

## Reproduce from retained source stage

```
blender --background --disable-autoexec --python-exit-code 1 --python tools/art/sintel_guard/spearman_carrier_rebuild.py -- HELMET_EDITABLE.blend OUT/carrier
blender --background --disable-autoexec --python-exit-code 1 --python tools/art/sintel_guard/spearman_grip_study.py -- OUT/carrier/soldier-carrier-editable.blend OUT/grip
blender --background --disable-autoexec --python-exit-code 1 --python tools/art/sintel_guard/spearman_controlled_walk.py -- OUT/grip/soldier-grip-editable.blend assets/ubc_lab/source/UAL1_Standard.glb OUT/walk
blender --background --disable-autoexec --python-exit-code 1 --python tools/art/sintel_guard/spearman_single_thrust.py -- OUT/grip/soldier-grip-editable.blend OUT/thrust
```

HELMET_EDITABLE is the preserved young-head/helmet2 actor, SHA recorded by the
carrier report. Its upstream recovery remains recut_front.py, young_head_module.py,
spearman_helmet.py, exact CC-BY3 Guardian source and CC0 official MH source.
`actual-trials.json` records real generated file hashes and reports, not screenshots
claimed from a different runtime. No visual acceptance is inferred from tests.

## Continued actual inspection after publication

Grip3 fixes a substantive bind-space mistake: original finger controls curl toward
hand-local+Z, while prior shaft location was on the-Z/palm-back side. New shaft
center uses measured native finger-chain coordinates (localY0.165,Z+0.035).
Actual image now places shaft inside both curved finger regions. This remains
unaccepted exact skin contact, not permission to label the full actor finished.

Native2560x1440 Blender screen-scale frame (`moba-review1`) was rendered and
personally viewed before any new Godot art claim: camera orthographic width16,
pitch50°, yaw25°. Gray armor reads as a smooth slab and shoulder joins remain
poor. This is an explicitly rejected normal-pixel art result, not final camera
approval or a screenshot sent to the owner.

Shoulder method changed again from circular cap to original professional coat
surface fitting. Trials4/5 stopped because the proposed pattern exceeded the
actual garment footprint. Trials6/7 measure that footprint but actual stress
images expose discontinuous surface selection/large triangulated shards. Both
are rejected. The current experimental source preserves this failure; do not
treat it as a better approved shoulder or a runtime replacement. The complete
source rigs/garments remain untouched and the earlier trial3 oracle stays saved.
A new ray projection over disconnected folded source surfaces is not a substitute
for a coherent authored shoulder pattern. No detail/shine pass may hide this.

## Complete boot surface diagnostic and first controlled CI failure
Run 43631814340 / source 6737b2fb failed before source recovery: default curl
request for official Blender4.3.2 returned HTTP403. Godot was SKIPPED. The
empty artifact directory produced no artifact; the job log is the failure evidence.
One explicit public LuanshiAssetRecovery/1.0 client request to the same URL
returned200, length368852356, XZ magicfd377a58; no login/cookie/challenge.
Installation now logs from its first request and uses that truthful client label.

The original boots use MeshDeform and only vertex group `Group`; previous cache
per-foot minima are null, not contact evidence. `boot_contact.py` matches the two
2065-vertex complete boot islands once to original DEF-foot.L/R, then retains
identities through all33walk/37thrust phases. On the old grip2 source, walk
surface minima are -36.30mm(L), -32.79mm(R), maxima132.22/132.27mm. Thrust
both boots remain about-2.00mm. This is a real flat-ground penetration FAIL,
not terrain acceptance or proof of horizontal foot lock. No geometry/lift was
changed to hide it. New grip3 CI will measure its own source hashes separately.
