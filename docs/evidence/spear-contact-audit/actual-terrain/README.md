# Actual whole-game terrain rejects the old-chain patch

Source1d496bfb08b8a6079fdc1a4dc4608570e311f083; run43603906190 succeeded
at native2560x1440 normal22m and native3840x2160 close6.3m, scale1.0,
seed61112, 512 ordinary each side. Controls and treatment have identical real
simulation/actor/camera inputs. These are 41-frame / 2.05-second diagnostic
segments at simulation20fps, NOT long gameplay coverage or realtime FPS.

The rigid-shaft patch removed the tick32 discontinuity (0.4387/0.7308m in the
rejected native control becomes about0.00000012/0.00000095m). But live new-ground
sampling still rejects contact: minimum modeled sole-corner clearance-0.08604m,
116 of328 modeled corners below ground by more than2mm. The control is also
bad (-0.08718m and121/328). These are source-aware boot-corner probes, not a
claim to have pixel-measured every sole vertex after every shader correction.
The renderer's photographed pose, crowded puppets and foliage occlusion also
remain inadequate. No activation, no art PASS, no production performance claim.

Retain this failed experiment as engineering evidence. Owner's complete-scene
and complete-character rebuild direction replaces continued patching of this
old character chain. New mature source rig/weights and full authored motion
must be judged in real play, not excused by low numerical ankle discontinuity.

The first QHD raw artifact14117721877 is629,663,383 bytes, beyond connector's
512MiB download cap; it remains intact. No resimulation was done to recover
viewable files. Run43605782139 copied movies/logs/metadata and selected native
frames byte-for-byte, hashing every copy in UNCHANGED-BYTES.json:

- QHD artifact14117209823, ZIP SHA256
  28f185a5656ef1562e1b3b1b1f5254dc097a762bf344d3158a50f7bdfea26f8d
- UHD artifact14118058294, ZIP SHA256
  a77af31429caae8fbf4ca9f1a6c06967b14120d7351b2bc41929c6d00ef40d86

Original native PNG and MP4 files remain unchanged. Inspection JPEG made only
for the tool's image-size limit is not an original screenshot or acceptance
artifact. `report.json` retains all clip switch distances and ground readings.
