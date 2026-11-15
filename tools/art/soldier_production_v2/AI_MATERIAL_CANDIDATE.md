# Isolated AI lamellar material input, not a final PBR claim

Source design authority: `docs/art-direction/owner-20261114/spearman-direction.png`,
SHA256 `fef54505bf0adb82646cd5c9e955170b255b3cbb8c5d6cfe1dc49c623167a932`.
The owner authorized this AI design direction for project use, not game acceptance.

New AI texture candidate SHA256:
`f345b00aa714d05a81d2c1fc743da0b1f72eac35f42b3a046689882b875242a1`.
Image dimensions 1774 × 887. Project-generated AI material, not external CC0.
It depicts eight columns and four courses of iron plates and brown lacing.
It is a literal material input, not a new character concept or game screenshot.
The full PNG is retained separately; it is NOT yet included in this source branch.

Generation requested flat front orthographic edge-to-edge 8×4 lamellar iron,
clear punched slots and small leather lacings, neutral basecolor, no perspective,
no cast shadows/specular highlight/background/text, no painterly smear or random
noise, seamless repeat. Actual output retains some slot/contact shading and fine
iron color structure despite those constraints. It is not calibrated pure albedo.

`apply_ai_lamellar_candidate.py SOURCE.blend TEXTURE.png OUTPUT_DIR` puts this
color input on the actual continuous skinned armor surfaces at matching plate
counts. Tangent normal is the independently authored structural construction
map from `lamellar_maps.py`, not a measured normal recovered from the AI image.
Cloth normal remains separately baked from actual complete professional cloth
geometry. Never call either AI color detail real individual-plate geometry.

Uniform06 improved plate/lacing readability but failed the complete costume
silhouette: short shirt, detached mantle, inflated lower wraps. The next source
changes the whole inner tunic, crossing collar, shoulder-to-chest coverage,
walking skirt, fitted wrists and lower legs. It is not justified by adding more
surface texture. Actual runtime/GPU and artistic acceptance remain outstanding.
