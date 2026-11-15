## Red Autumn original EEVEE diagnostic

The official Red Autumn Forest source by Robin Tran is CC-BY-SA 3.0, as its
embedded README states. The current public file uses Blender5.2 despite the
historical2.91 URL:
https://download.blender.org/demo/splash/blender-2.91-splash.blend

Source SHA256 `b60bd6d566d202cc9cd8c0bd260a45be0ab8c37fc24e0d2e9c909efa41e94655`,
69359275 bytes. Read-only5.2.4 inspection:291 objects,23 materials,2 node groups,
zero undefined nodes,3 packed images, no external libraries. This is not visual
acceptance. Its ShaderToRGB materials require original EEVEE evaluation; a
Cycles substitution is not a valid quality comparison.

Linux background EEVEE failed with EGL_BAD_MATCH and subsequent SIGKILL after
75.984s, peak RSS6900604KiB; no PNG. The signal alone does not establish OOM.
No GUI/security bypass or shader replacement was attempted. The independent
`dot/red-autumn-source-macos` experiment uses the normal hosted macOS runner,
official Blender5.2.4 arm64 DMG SHA256
`e73d564f97061b2496ccc5a0bd738937d2d3d0acae23621a00bbc7534dfd135f`,
original camera/lights/engine/materials at850x312, with an explicit Python
error exit code, PNG chunk CRC/decompression checks and a completion marker.
The resource wrapper normalizes macOS RSS bytes versus Linux KiB.

Initial run: https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43661267243
Source commit592eedc1b8a05abd97ed5d5bc0cadc7ea8cd379c. Final status: SUCCESS. Actual source PNG850x312 SHA256
`2a8ec1f546557210df367a35ba45975e514b43e976c37b36c9678dfc94130f6d`.
Artifact14140152238 (14-day retention), archive SHA256
`98a4ed46be5bebcb76de240ec24a0c11b051fb0b49a6d5b19c10283ecd9f0fd2`.
Recorded GPU: METAL, Apple Paravirtual device, VirtualMac2,1,3 CPUs,7GiB RAM.
Child90.691s; peak RSS2902736896bytes. Source camera/lights/material count
identity unchanged; PNG CRC and decompression validation passed.

Internal visual review rejects direct use as a finished historical battlefield:
coherent forest edge and sloping ground are useful compositional evidence, but
strong orange-yellow flower meadows, paper-like flowers/grass, rounded graphic
clouds and fragmented upright canopies do not meet the requested natural,
restrained battlefield. Technical source-render success is not art approval. This is an offline original-art source
inspection, not a Godot game capture, game performance test, or M5 acceptance.
