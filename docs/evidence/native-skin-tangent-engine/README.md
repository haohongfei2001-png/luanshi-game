# Godot native Skin tangent diagnosis, not a shipping engine replacement

Official Godot 4.6.3 downloaded editor (reported hash 7d41c59c4) on Linux
llvmpipe Compatibility reproducibly changes an identity-bone triangle tangent.
Source vertex tangent [1,0,0,1], one identity bind, exact weights [1,0,0,0].
Static center RGB [1,.502,.502]; native Skin [.7765,.502,.0706]. A native
Skin rebuilt from identical arrays has the same incorrect output. No UBC/MH,
palette, animation retargeting or custom skin shader is involved in that probe.
Run 43614620176, artifact 14121359013; JSON preserved here.

The full UBC reference experiment retains the original native four-pose FAIL
(2 levels / 2 percent, unchanged). Independent complete CPU-deformed static
mesh with original materials versus batched weights passes all four poses:
1/3/4/7 pixels over two levels, MAE 0.69–1.97e-6. Run 43614764419,
artifact 14121661340. This is NOT a native Skin PASS or art acceptance.

## Source investigation and candidate patch

Official source tag `4.6.3-stable` resolves to
`35e80b3a8822a9df9be390814b62f44c0a9c69e8` (verified remote and local clone).
This hash differs from the downloaded editor's reported hash; do not claim
that the new source build is byte-identical to that downloaded release.
Original and patched source builds below both use the same verified tag SHA.

`drivers/gles3/storage/mesh_storage.cpp` packs normal/tangent together as four
normalized unsigned shorts at vertex location 1; it disables location 2.
The base skeleton shader instead declares location 1 vec2 and location 2 vec2.
The candidate patch consumes the existing combined location 1 correctly,
leaving separate integer blend-pass inputs unchanged. It also corrects the
UNORM tangent y/sign inverse (including the same 1/32767 encoding bias as
`Vector3::octahedron_tangent_encode`, preserving signed -Y boundary cases) and replaces two duplicated VERTEX mask terms
with TANGENT. No mesh, UV, weights, normal map or material is modified.

Patch SHA256: `d69c0b92025f5ec3732e557a5003fedada7021c8598806adfb0ed1a9c662663e`.
Godot's MIT license is retained alongside it. Algebra checks cover +/-X/Y/Z
with both tangent handedness signs after UNORM16 quantization. The original
negative-sign decoder fails, corrected inverse passes all 12 cases.

The isolated source-build workflow must run the original and patched engine
against the same minimal probe and full four-pose source material gate. Until
those results are inspected, this is an **UNVERIFIED ENGINE PATCH**, not a fix
claim. Build artifacts retain original/patched versions, source SHA, patch,
commands and logs. No upstream issue/PR is sent on the user's behalf. Neither
the default game engine nor macOS candidate is replaced.
