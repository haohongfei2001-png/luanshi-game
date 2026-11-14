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

## Actual complete controlled actor Godot, internally rejected
Run43632177734, source2df44c52 actually completed all six graphical Godot
invocations on llvmpipe LLVM20.1.2. Four native2K/4K stills and two monotonic
motion sequences were recovered in artifact14128981177. Actual motion PNG
sampling has16frames over3.83/3.92seconds; this is not a smoothness/performance
PASS. Full original graphical logs were independently scanned and contain no
SCRIPT/SHADER/ERROR entries. The negated-grep CI gate is nevertheless replaced
in the next pipeline revision with explicit fail-closed branches.

Personal review of normal2K and both near4K frames rejects the appearance:
armor is dark and exhibits triangular overlap patterns, shoulder connections
remain disconnected, hand/face color differs, and spear grip/boot contact are
unaccepted. These are not owner-ready screenshots or a battle implementation.
`actual-godot-first.json` pins original pixels/artifact/source/durations.

A source-geometry diagnosis reveals that the donor UAL mannequin itself reaches
-26.56mm(L), -26.21mm(R) below sourceZ0 over the33walk phases. The target cannot
be corrected by assuming all donor foot height is ground-valid or globally
lifting the actor. `source_stance.py` measures source surfaces before any
correction. Coplanar armor is separate: projected corners discarded per-row
radial offsets, and constant-width neighboring columns overlapped on the same
surface. A new isolated physical-layer trial must remove that construction
error rather than hiding it with light, blur or Bevel.

## Independent physical-layer8 and original eye-alpha correction
`carrier-layered8` creates circumferential columns with explicit angular gaps
and2.2mm row separation for1.5mm thick lamellae. This removes the construction
error of projecting overlapping plates to an identical radial surface. Actual
Blender full-body stressed-arm render was personally inspected: chest layers
are now separated, but shoulder connection, sleeve/boot silhouette and full
appearance remain unaccepted. Failed shoulder4–7 projection is not reused.

Official `brown.mhmat` declares transparent/alphaToCoverage/shader transparency
true. Original brown_eye.png includes13238 alpha0 pixels whose RGB contains
blue. Earlier Eyes alpha=False caused those transparent source regions to
render blue. The face-module derivative now links the original image alpha,
keeping all source UV/vertices/weights. No invented mask or hidden garment
geometry is introduced; full original RGBA is preserved.

## Source-phase native-leg-IK experiment, default OFF
`stance_ik_experiment.py` is isolated, not called by the capture pipeline.
The donor T-pose sole is+0.461mm and Idle about-0.102..+0.460mm, confirming
that Walk's-26.56mm is not an authored-26mm ground plane. Only donor near-ground
phase candidates(<=4mm source sole height) receive a target native foot-IK
vertical constraint against the complete boot surface. Horizontal IK coordinates
and foot orientation are asserted unchanged. No body translation, foot freezing,
source motion overwrite, or gameplay change occurs. Maximum correction39.09mm;
65samples including mid-keys have worst surface+0.167mm, versus original-36.30mm.
This is NOT full contact acceptance: source-root-motion horizontal foot-lock,
knee continuity, original-speed visual playback and terrain are still required.
First attempt failed on nonexistent DEF-shin.L; corrected exact original name
DEF-shin.L.01. Failed log is preserved locally. New editable master is independent.

## Layer8 actual Godot and stricter IK rejection
Run43633075648/fdd1f54 actually completed graphics with explicit fail-closed
log gates. Artifact14128903050 is pinned in actual-godot-layer8.json. Personal
near4K review confirms eye-alpha repair removes the blue membrane; whole art
still fails. Triangular plate lighting persists despite physical layer spacing.
Same-geometry Blender no-Bevel A/B confirms smooth caps plus sidewalls inflate
thin plates; explicit flat cap normals eliminate that false bulging in the
Blender diagnostic. Next Godot LOD uses this declared normal construction,
not a source-normal preservation claim; source sculpt and editable high master
remain unchanged. A six-patch actual-engine StandardMaterial/custom shader/
source-color texture calibration is added before changing color conversion.

The isolated stance IK experiment is rejected after stronger65phase knee
comparison: max knee displacement118.97mm(L)/111.89mm(R), minimum bend direction
dot0.301/0.286. Removing penetration alone is insufficient. It remains OFF and
is NOT in the actor rebuild/capture pipeline. knee_continuity.py reproduces
this failure; original donor/source/target masters are retained.

## Complete source to shared-runtime boundary
`runtime-source-boundary.json` is actually read from the grip3 editable source,
with its exact SHA. It identifies43visible meshes and every modifier/dependency;
it does not pretend to be a latest-layer8 geometry hash. New armor topology must
be re-evaluated and rehashed independently.
- Boots/pants/sash retain original566point DQ cage→MeshDeform→Multires.
- Gauntlets retain cage→MeshDeform→Subsurf.
- Recut top uses independent566point DERIVED cloth envelope binding→Solidify;
  original1373top response cannot be reused.
- Hands retain MeshDeform→79deform DQ Armature→Subsurf, not plain Skin alone.
- MH face/eyes/brows/lashes use original163bone Armature; face has14vertices with
  nine influences. Neither truncation nor ordinary8weight native import suffices.
- Newly authored armor/helmet uses assigned Armature weights; spear is an intact
  rigid child with a separate controlled transform track.
No part is marked runtime_ready. Single-actor197MB pose geometry exists only as
an authoring oracle. Shared3D LOD2 needs an independently measured source→runtime
derivative and source-specific pose/normal/occlusion evidence, not one cache
per soldier or471CPU Skeleton3D instances per crowd member.

## Actual plate-normal result and proven color-input correction
Run43633929202/dc6904d6 completed real Godot on llvmpipe. Artifact14129526055,
SHA3cbdd663b3bf67cffccf9e7b43979ce81d042569145c491eab5a94853309dd29.
Personal near4K review confirms triangular bulging is gone after explicit plate
cap normals, though complete appearance remains unaccepted.

Actual six-patch calibration found a separate interface error. Source BSDF
linear(.44,.265,.17) passed without color semantics outputs approximately
(.439,.263,.165), while its correct encoded value(.69436,.55165,.44920) via
StandardMaterial or source_color uniform outputs(.69412,.55294,.45098).
Source-color texture and StandardMaterial texture agree to the same8bit values.
Therefore source BSDF colors are now CPU-encoded with linear_to_srgb and the
uniform declares source_color, matching the engine's authored color interface.
Source textures, physical light intensity and exposure remain unchanged. This
is not an arbitrary brightening or claim that full Blender shading is preserved.
