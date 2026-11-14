# UBC/UAL complete native-rig prototype

Quaternius, Universal Base Characters Standard and Universal Animation Library
Standard. CC0 1.0, as explicitly licensed in these exact packages. Public source
model/animations and derivatives are permitted. This is not blanket permission
for other Quaternius packs under later QAL terms.

UBC author page: https://quaternius.itch.io/universal-base-characters
128968391 byte ZIP, SHA256
`fdbf1804c90dfc1ea03e992bff7da2dfd1a79318e13270a660180f9308455f40`.
Package license dated 2025-08-18.

UAL author page: https://quaternius.itch.io/universal-animation-library
15904933 byte ZIP, SHA256
`cc73fc4e495b82958207316596317a3f40b9fa38065bde1027937452da537724`.
Package license dated 2026-06-16. Exactly 43 clips, not the paid 120+ library.

Original selected UBC glTF/binary/textures and UAL GLB are retained in source/,
with exact extracted licenses. The upstream glTF references two missing
`*_Normal_png.png` filenames; builder explicitly resolves to the supplied
`*_Normal.png` bytes. No downloaded executable code is run.

Modifications: nine selected motions retargeted to complete 65-joint UBC with
world-rest-relative rotation deltas, original target bone lengths/binds and
all original vertex weights preserved. Root/pelvis displacement scaled by
pelvis rest height ratio. Target limb translation/scale is not replaced with
source limb channels. Geometry and texture bytes are unchanged. A fully editable
Blender scene is provided, with packed textures and nine actions.

NOT historical costume, NOT natural-proportion acceptance, NOT combat footage,
NOT visual/performance pass. Superhero anatomy exaggeration remains. Turn in
lab is an external presentation yaw, not an authored foot-planted turn clip.
