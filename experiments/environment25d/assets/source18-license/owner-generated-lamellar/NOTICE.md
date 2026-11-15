# Project AI lamellar material candidate

This is an original project AI material derived from the owner's approved
spearman design direction. It is **not a third-party CC0 texture**, measured PBR
scan, accepted final art, or a game screenshot. No endorsement is implied.
The reference is the repository's `docs/art-direction/owner-20261114/spearman-direction.png`;
its exact SHA256 is pinned in `source-manifest.json`. No private access links
or conversation identifiers are included.

The PNG is retained losslessly as small base64 source parts to make transfer
reliable. These parts are concatenated BEFORE decoding. `restore_png.py` checks
every part's length/SHA256/Git object SHA and the complete decoded PNG's size and
SHA256. It performs no resampling, cropping, color conversion or recompression.

From repository root:
```
python assets/owner_generated/lamellar-material-v2/restore_png.py /your/output/lamellar-color.png
```

Expected original: 2,873,363 bytes, 1774×887 PNG, SHA256
`f345b00aa714d05a81d2c1fc743da0b1f72eac35f42b3a046689882b875242a1`.

The image has eight plate columns/four courses. Actual production maps it with
UV scale 0.125/0.25 relative to per-plate UV. It contains some generated slot/contact
shading and fine color structure, despite requesting neutral diffuse color.
Its companion structural normal is separately authored, not a measured normal
map recovered from this image. See `tools/art/soldier_production_v2/AI_MATERIAL_CANDIDATE.md`.
Visual and dynamic-lighting evaluation remain necessary.
