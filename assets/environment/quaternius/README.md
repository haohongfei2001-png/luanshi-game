# River valley broadleaves

The broad and upright trees use CommonTree_1 and CommonTree_3 by Quaternius from the free Stylized Nature MegaKit Standard. The author releases this pack under CC0. The game uses the artist's root shapes, branch structure and alpha-cut leaf UVs. The meadow and waterside willows use separate project materials. [Author’s page and license](https://quaternius.com/packs/stylizednaturemegakit.html) · [Godot Asset Store distribution](https://store.godotengine.org/asset/quaternius/stylized-nature-megakit/)

Download the Standard ZIP linked at the top of the import script. Run the following command from the project root. The script checks the ZIP's SHA-256 before importing, normalizes each tree to a metre, and writes the game mesh, reduced bark, leaf cutout, upstream license and source hashes alongside this file. The field combines these trees into the existing spatial grove batches.

```sh
blender -b --factory-startup --python-exit-code 7 --python tools/art/import_valley_grove.py -- /tmp/Stylized_Nature_MegaKitStandard.zip assets/environment/quaternius
```

The static batch reads the author’s original leaf UVs. Blender places wind weighting and the bark/leaf material tags into the second UV channel. The crown normals are blended across each branch crown, so individual leaf cards receive coherent illumination. Godot reduces both tree masters to fixed terrain-cell draws; tree geometry has no collision or battle-state identity. [Source manifest](sources.json) · [Upstream license](License_Standard.txt)
