# Actual static AI asset Godot diagnostic, not gameplay acceptance

Two bounded Ubuntu runs executed actual Godot4.6.3 software rendering, not only
headless import. Raw alpha and explicit0.5019608 scissor each captured at native
2560×1440 and3840×2160. Camera is orthographic size12, position(0,12,10), aimed at
origin; this is a diagnostic candidate, not an approved Wild Rift screen scale.
All source PNG bytes match SHA91fce351c709de249798f64064251a89494fb141f9567dbd03cb68dcf5bff3b3.

## Actual finding and correction

Run43627386395 successfully rendered but was visually rejected: screen-facing
quads intersected the floor, cutting off feet/shaft below each mean foot anchor.
Both raw and scissor modes failed identically. This was not source tile cropping.
Artifact14126237296 preserves the failure; no image was offered as accepted art.

Run43627609770/head9f2c48a explicitly disables depth testing **for this isolated
readability diagnostic only**. Complete feet and shaft are now visible. Green
rings mark estimated ground anchors. Actual2K raw frame has been personally
inspected. Clothing, hands and armor layers are legible and visibly closer to
approved direction than the rejected3D plate shell. This does not establish
world ground contact, common body dimensions or camera-consistent directions.

Only color+alpha is supplied; there is no trustworthy per-pixel depth. Disabled
depth is NOT a game solution. In particular slopes, bridges, buildings and mutual
unit occlusion are untested/unsupported. A proper ground/depth representation
must be implemented separately rather than silently raising units or turning
all game depth off. Exact body scale/grip/rotation consistency remains unaccepted.
No animations beyond static stance exist. No battle state is connected.

Raw/scissor differences in the FIRST clipped run:2K1279 pixels differ by>10 in
any channel, max39;4K2863 pixels, max41. These are diagnostics, not proof that
scissor preserves all hair/cloth/tip edge pixels. Source alpha has residual haze.
No source image was modified, thresholded or claimed repaired.

## Single-heading walking attempt rejected before game integration

Generated original RGBA1536×1024 eight-phase attempt retained locally:
`generated_images/exec-9db4f5ab-117b-4188-97b4-512c5d5f44d5.png`, SHA256
`3e10ce22383889b369fb8588601b9305bc77739efef606d23e00e27289d8d7c3`.
Actual output was inspected: it loses the static asset's helmet plume, repeats
several leg poses instead of a reliably alternating cycle, and changes foot
orientation abruptly. Therefore it is **not** accepted as a walk animation.
An eight-image generation call is not evidence of coherent animation. Original
static PNG and this rejected attempt remain separate; no stretching, mirroring,
procedural repaint or false frame-completion claim is used to hide the failure.

M5:NOT_TESTED. True battle integration:NOT_TESTED. Art:NOT_ACCEPTED.

Second bounded correction attempt: `exec-6038a937-24ef-4029-abac-2f58a1efb82d.png`, SHA256`b65a3b9a81a8ec668293a34e9634fb6b11b77e25add7e2d094010e6067621ae8`. Helmet crest restored, but phases3/7 again lift the same apparent leg rather than alternating support. Rejected before gameplay/CI. Stop repeating uncontrolled eight-frame generation; neither attempt constitutes a usable authored walking cycle.
