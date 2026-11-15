# Complete source18 spear soldier: attribution and modifications

Runtime GLB SHA256: `afb966396bf5ad656b3cb0cd2edc388fc6fa02eba59df8b81d9a23ac53f3be8b`.
This is a development-only art candidate, not final accepted art. Each original
license remains applicable to its respective component. No upstream endorsement
is implied; this assembled derivative is not collectively relabeled CC0.

- **Body, Asian adult macro shape, skin, eyes, eyebrows, eyelashes, MH163 skeleton and source skin weights:** MakeHuman Community official core/system assets, CC0. Core revision `a8bc2d54ff0ac92e78ff71431b1023eda42bf482`; https://github.com/makehumancommunity/makehuman . Pinned file URLs, member hashes and original asset records: `tools/art/mh_character/sources.json` and `NOTICE.md` in this license packet. These asset licenses are distinct from the software license.
- **Complete professional inner coat:** Sintel/Durian Guardians r854, © Blender Foundation, CC BY 3.0, https://creativecommons.org/licenses/by/3.0/ . Original release https://durian.blender.org/news/guardians-community-help/ ; rights-holder grant https://durian.blender.org/sharing/ . Exact original ZIP SHA256 `dd0796eba8f2b08a239470488559f3a1b2ccd7b1140fdb93360bbb177d4776b9`. Original source evidence and member hashes are in `tools/art/sintel_guard/`. This was an early r854 work-in-progress, not the final film character. Changes include adult-body fitting, long cross-collar tailoring, source-topology splits, new weights, LOD, original-fold normal baking and material adaptation. No external reference photograph is included.
- **Trousers:** MRT / MargaretToigo wool pants, CC0, with pinned original asset URL and member hashes in `tools/art/mh_character/sources.json`. Modified fit, skin weights and materials; not a claim of historically exact original design.
- **Footwear:** punkduck medieval boots, CC BY 4.0, https://creativecommons.org/licenses/by/4.0/ ; https://static.makehumancommunity.org/assets/assetpacks/shoes03.html . Derived cloth-shoe appearance, male fitting, ankle cuts and new weight transfer preserve this credit.
- **Original locomotion, hit and death animation basis:** Quaternius Universal Animation Library Standard, exact 2026-06-16 package with explicit CC0 license; ZIP SHA256 `cc73fc4e495b82958207316596317a3f40b9fa38065bde1027937452da537724`. Rest-aware MH163 retargeting and five additional spear clips are derivatives. Later generic-QAL packages are not substituted. The movements are not historical Chinese combat motion capture.
- **Armor outfit geometry, rigid spear shaft/blade, two-hand spear authoring, supporting structural maps and runtime integration:** project-authored additions. Spear locomotion retains the above licensed retargeted lower-body basis while arms/grip/thrust are newly authored. The weapon is parented to wrist.R. These additions carry no claim of third-party CC0 status.
- **AI lamellar base color:** original project-generated material following the owner's authorized design direction, not third-party CC0 or a measured PBR scan. Exact image SHA256 `f345b00aa714d05a81d2c1fc743da0b1f72eac35f42b3a046689882b875242a1`. See `owner-generated-lamellar/NOTICE.md`, `source-manifest.json` and `tools/art/soldier_production_v2/AI_MATERIAL_CANDIDATE.md`. The normal/structural map is separately authored.

Runtime-specific changes: eight-influence reduction and renormalization, explicit
triangulation for tangent-space normals, resource embedding, source120fps clips
exported with checked duration, and Godot presentation bindings. Full editable
source retains its original weights. The exact component provenance and license
notices must accompany this GLB and its derivatives. Disputed Viking clothing
and the unused Mindfront kimono are NOT rendered in this runtime GLB.
