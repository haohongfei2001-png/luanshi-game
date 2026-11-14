# Reviewed same-source Linux GPU result

Run [43618127716](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43618127716), source commit `5c59b7369cc9a19f9e5dcc93fec29b66d3d7aba9`, completed successfully. Artifact `14124017040` retains both executable binaries, original/patched images, build logs and provenance. Downloaded artifact ZIP SHA256 `86a1d627854559bbed35f6a360cea05fac0c9572bb165f1ed43c4984a0979909` (62,022,591 bytes). The binaries were independently rehashed after download; the patched Walk native/batch images were inspected.

Both engines were compiled from official source tag 4.6.3-stable, SHA `35e80b3a8822a9df9be390814b62f44c0a9c69e8`, using identical flags. Only the retained two-file patch differs. Both identify as `4.6.3.stable.custom_build.35e80b3a8`. This is NOT the previously downloaded official release executable reporting `7d41c59c4`; its original failure remains recorded separately. No version hash was overridden.

## Actual results

Renderer: Linux Xvfb, OpenGL Compatibility, llvmpipe (LLVM 20.1.2, 256 bits). These are correctness tests, not hardware FPS or art acceptance.

- Original identity and identical-array roundtrip Skin tangent error: 0.4314 each. Patched: zero each.
- Full original StandardMaterial, four exact character poses, existing 2-level / 2% gate unchanged: original 4/4 fail; patched 4/4 pass.
- Patched pixels exceeding 2 levels / visible pixels: Idle 5/12004; Walk 5/12248; Sword_Attack 10/10018; Death01 3/8716. Not claimed bit-identical.
- Nonzero blend shape (weight .35), optional nonidentity Skin, both tangent handedness signs, N/T/B versus CPU-static controls: original 6/12 fail; patched 12/12 pass with zero differing pixels.
- Algebra UNORM16 encode/decode regression: all 12 corrected cases pass.

`same-source-comparison.json` preserves exact original/patched measurements, including failures. `same-source-provenance.json` records binary/patch hashes and build flags. The bounded SCons cache save succeeded; future short probes can reuse the retained binaries without recompilation.

## Boundaries and recovery

No default game scene, main branch, original macOS candidate, or shipping engine was changed. No M5 test, army performance result, Chinese character visual acceptance, or upstream issue submission is implied. Batched rendering still rejects unbaked/live blend shapes; these synthetic tests cover the native engine patch only.

Download the artifact from the run, verify both binaries against provenance, mark executable if necessary, and use each with the same project checkout at the source commit. Rerun `tests/native_skin_tangent_probe.gd`, `tests/intact_native_gpu.gd`, and `tests/native_blend_skin_tangent_probe.gd` under Xvfb using the existing workflow commands. Do not substitute the official release binary when reproducing this same-source comparison. Review `tools/engine/verify_engine_comparison.py` for unchanged gates.
