# Layered structure: actual Godot stage, still rejected

Source d5e8dc5bb829a7092f66ce2c56dc97b245d2d690, run43640792514, job132587693541 SUCCESS.
6 actual 2K/4K stills and 4 monotonic-time motion captures; actual engine logs independently checked clean.
The reviewer inspected walk, thrust and constrained-hit 4K, normal walk 2K and root-turn frame8.
This is not a Battle mapping or a full video visual acceptance. Motion captures are 15/16/16/16 frames over roughly4s, software rendering with image-readback overhead. No FPS benchmark or smoothness PASS.

Whole costume remains rejected: floating/penetrating shoulder edges, white cuff skin exposure, broken puttee coverage, sharp waist/skirt boundaries, known spear through chest. Keep945 rollback; do not send failed pictures as an approved update.

99 meshes,123989 vertices,209374 triangles,103 sampled poses;409567232 raw geometry-cache bytes. NOT a crowd architecture. Complete editable walk/thrust/hit sources and cache are retained in17 independent GitHub artifacts,404327767 archive bytes, SHA2562e9f6869630370babd71bf8021d84ad57d797a62a9e292801f2af8fef4414c27. Only evidence and manifest downloaded locally; full parts not locally reassembled due space.

## Actual next repair, not merely a failure report
Found and tested a surface contract violation: old puttee was fitted over source boots at Multires0; exporter unconditionally evaluates Multires1. Original right/left source modifiers remain fully editable. Fit/runtime must share an explicit derivative surface; increasing evaluation level is not innocuous refinement.
Same old rest-pose wrap/boot pairs at level0:56/152 intersections; level1:2222/1794; level3:5376/4697. New fitting explicitly uses level1, preserves all3 sculpt levels and records original settings. Actual new level1:142/142 intersections; high3 still1344/1664, so not a general high-resolution contact PASS. New full Blender still personally reviewed: broad ripped-through shin areas removed, ankle transition and remaining intersections still need work. No new Godot run yet for this fix. Original14 and945 unchanged.

Next: validate new wrap under actual leg poses, repair cuff/shoulder clearances in full source, then regenerate next whole-actor oracle. Do not hide surfaces or change combat for a visual pass.
