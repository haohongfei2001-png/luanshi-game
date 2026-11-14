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

## Measured cost/approximation boundary

`response_cost.py` examines SVD factors and coefficient magnitude pruning
against the same 25 held-out native poses, without changing original weights.
Rank 256 still gives 1.22 mm error; rank 384 returns to about 27 micrometers
but costs 2.98 MB and 2.23 million scalar MACs, worse than exact sparse
response's 208133 entries / 624399 scalar MACs. Thresholds through 1e-6
remove no entries. Threshold 1e-4 drops to 140169 entries but increases worst
cloth error to 0.722 mm, outside the near-view positional gate. These shortcuts
are not enabled. Row-L1 omitted coefficient bounds are recorded, not hidden.

Real GPU probe runs a complete DQ stage and an exact-nonzero sparse response
stage, with encoded position pixels read back against independent native
Blender evaluation. Its 5 micrometer cage threshold includes 24-bit position
transport quantization; CPU reference remains 2 micrometers. Coat threshold
stays 100 micrometers. This is not yet an actual garment material renderer.
First run 43621502775 failed before any source/GPU execution because the
Blender official CDN returned HTTP403. The upload step found no evidence files;
no artifact or graphics success is claimed. Recovery uses Ubuntu's official
signed Blender package with its actual version recorded, rebuilding both oracle
and response within that same run rather than pretending it is Blender4.3.2.

## First actual GPU result, still failed startup hygiene

Run 43621867652, artifact 14123794509: Ubuntu Blender4.0.2 rebuilt and passed
all native CPU gates. Patched same-source35e80 engine executed both GPU stages
under llvmpipe and all25 poses passed positional gates: cage maximum1.132um,
coat maximum23.188um. `first-gpu-arithmetic.json` retains every measurement.
The overall CI was correctly red because the template-only isolated project
emitted `Could not load global script cache`. Do not mislabel it a clean run.
The next harness bootstraps the exact empty global class cache (`list=[]`)
actually emitted by the local editor for this no-class_name project, and keeps
the strict ERROR log rejection; no warning/error filter was weakened.

The current proof's RGBAF padded shared textures occupy4,874,384 bytes,
including4,789,024 bytes for sparse response entries (index,coefficient,0,0).
Per-pose complete79-bone DQ input is2,528 bytes. These physical allocations are
larger than the theoretical compact pair table and are reported honestly.
Readback/reupload is deliberate for independent stage inspection, not a fast
production architecture. Four-frame software-render/readback wall times are
not frame rates or isolated shader timings.

CPU-only independent response microbenchmark (`cpu_response_cost.py`) covers
1/20/100/250/512 sets of cage points on the cloud AMD EPYC9V74 with OpenBLAS
single-thread settings. It excludes DQ, constraints, normals, Multires and draw.
Exact sparse CSR can be slower than dense BLAS despite lower MAC count; see
raw percentiles in `cpu-response-cost.json`. Neither is a full army result.

## Clean GPU closure

Run43622241297 at9fab3c1372a48266fabf83aa8e1682a43f074251 completed
all steps successfully. Artifact14124736263 is1,936,568 bytes; independently
downloaded ZIP SHA256 is0c8d0ffe7acb24c89b883c0556e5147256ccbd2615c49d2d13d9a1d550948165.
All25 actual GPU poses pass, maximum cage error1.131933um and coat23.187629um.
The final GPU log has no ERROR; cache startup repair did not alter shaders or
thresholds. `clean-gpu-arithmetic.json` retains exact final measurements.

This closes the coat-base arithmetic experiment, not complete character runtime.
The25 poses exercise upper-arm/forearm three-axis FK plus torso translations;
walking gait, foot contacts, mounted movement and nonrigid/scaled bone poses
are not validated. Next integration uses the stable original308/79 source rig
for complete-character walk/stop/turn/weapon attachment work. The character-art
branch's evolving garment cuts need their own source SHA/response, not this
old topology's H. Original19-mesh outfit components will be audited separately.
No production/default scene or macOS engine is changed.
