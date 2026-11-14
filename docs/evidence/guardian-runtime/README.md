# Guardian complete-weight cage runtime investigation

Experimental, disabled in production. Original author source is unchanged.

The 566-point deformation cage uses 79 deform bones of the intact 308-bone
rig with **preserve volume enabled** (dual quaternion deformation). It is not
ordinary linear blend skinning. All 1139 nonzero input influences are retained;
the maximum is 5 per cage point. Original weights are retained verbatim.

25 deterministic held-out three-axis FK rotations and torso translations were
evaluated by Blender against the untouched author source. Algebraic folding
of the fixed 1373x566 cage response into per-bone homogeneous bind contributions
is exact for LBS, but changes the original authored deformation by up to
16.30 mm on the cloth (25.32 mm on cage). This route is rejected, not presented
as a faithful runtime conversion. The independent LBS formula agrees with
Blender's explicitly disabled-preserve-volume diagnostic to 0.425 micrometers.

An independent complete-influence dual-quaternion implementation instead
matches the original cage to 0.750 micrometers over those poses; followed by
fixed native cage response, garment position error is 27.21 micrometers. Gates
remain 2 micrometers for cage and 100 micrometers for this finite-difference
response. Matrix scale/shear is checked against 1e-5; arbitrary nonrigid poses
are NOT validated and must not be silently processed as rigid DQ.

The bounded representation retains the complete source rig and all influences.
Shared float32 response is 3,108,472 bytes (208133 exact nonzero coefficients,
no magnitude pruning). Native cage output costs 6,792 bytes per actor per frame;
79 3x4 matrices cost 3,792 bytes. Dense response costs 2,331,354 scalar MACs per
actor per frame, so this is NOT yet a proven thousand-soldier renderer. Static
response and rig data can be shared rather than a 178 MB per-person pose cache.

Next: implement exact-nonzero sparse response and DQ in an isolated real GPU
probe; retain source UV/materials and compare held-out poses. Evaluate costs
before choosing crowd tiers. Level 1 Multires, posed normals/tangents, full
outfit assembly, shader compilation and actual GPU speed are NOT covered by
this CPU positional experiment. No art acceptance or shipping enablement.

Reproduce with `blender --background --disable-autoexec --python-exit-code 1
--python tools/art/sintel_guard/fold_runtime_probe.py -- SOURCE_BLEND
FIXED_CAGE_RESPONSE_NPZ OUTPUT_DIR`. The original response is produced by
`cage_coefficients.py`. Original source hash and every pose error are in
`dq-cage-probe.json`; generated NPZ retains raw weights, names, reference
matrices and corresponding cage/top points for independent GPU comparison.
