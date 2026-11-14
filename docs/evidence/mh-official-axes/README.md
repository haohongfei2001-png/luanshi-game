# Correcting source rest-axis reconstruction

Read-only audit of fixed upstream MakeHuman `skeleton.py` revealed a real error in our importer. Official plane normal is a local-X reference; our Blender `align_roll` used it as local Z and reversed its winding. All 163 frozen skeleton bones differ from the documented convention by approximately90 degrees. Source vertex geometry, weights, bone count/head/tail hierarchy preservation did not establish authentic author bone axes. Earlier blanket “original rest preserved” wording must not be read as a comparison with the official exporter.

The explicit `--official-axes` builder option reconstructs local Z from the proper normal/X and head-to-tail Y basis before Blender roll alignment. Separate output `/tmp/mh-official-axis-source`; frozen source and default seed remain untouched while the new source version is tested. No importing or execution of upstream Python code, no copying its implementation into the project; audit uses an independently reconstructed orthonormal basis from documented source convention.

Actual result: all163 angular comparisons round to zero; maximum matrix component discrepancy1.46e-5, source head/tail discrepancy0.239 micrometres. 65 exported geometry/UV/weight/index accessor byte comparisons unchanged, joint order unchanged; inverse binds intentionally differ. Old GLB6853fbca; corrected static GLBddfd066205a7439195435bbf25558b38627260dc25fda8465993d2f6783a7de4. This is source-consistency validation, not a graphics or contact PASS.

```
blender -b --disable-autoexec --python-exit-code 1 --python tools/art/mh_character/master.py -- /tmp/mh-official-axis-source /tmp/mh-rebuild-source/core /tmp/mh-rebuild-source/selected /tmp/mh-rebuild-source/selected/clothes/mindfront_kimono --official-axes
blender -b --disable-autoexec --python-exit-code 1 --python tools/art/mh_character/source_axis_audit.py -- /tmp/mh-official-axis-source/source/mh_natural_editable.blend /tmp/mh-rebuild-source/core /tmp/mh-official-axis-verified.json
```

Reference: https://github.com/makehumancommunity/makehuman/blob/a8bc2d54ff0ac92e78ff71431b1023eda42bf482/makehuman/shared/skeleton.py . The asset files' own CC0 declarations govern source body/rig data; the upstream application code is not bundled here.

## Actual end-to-end verification

`build_official_seed.sh` actually completed with exit0: all40 pinned source files, official-axis editable master, 9 clips, exact export check, source-axis audit, Godot import, source-ID check and native animation test. It writes `assets/mh_official_axes_lab`, not the frozen `assets/mh_lab` baseline. Use the same MH_SOURCE_CACHE / UAL_GLB / MH_FETCH_OFFLINE variables as the legacy seed.

Native Godot: complete163 bones, all20159 split vertex IDs have zero position/UV mismatch, all9 clip durations preserved. Native8 diagnostic remains insufficient for all9 source influence slots.

Independently fetched reference implementation from public commit `a3665f4d8d9e5f27060e44763d923226b261aed5` and ran `MH_WEIGHT_FIXTURE=res://assets/mh_official_axes_lab godot --headless --path . --script res://tests/mh_full_pose_reference.gd`: **549063 checks, zero failures**,9 clips×3 phases, every20159 vertices and all33 >8-tail vertices. Parent reference code is not duplicated in this change; fetch its exact four source/test dependencies to repeat. This proves complete-weight pose consistency, not actual GPU pixel parity, feet contact, weapon grip, performance or art quality.
