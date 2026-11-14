# Complete original woody source intake, NOT game acceptance

The actual scene `e3d8d245` still fails as a whole. Its field-oak family is a new
assembly from a professional branch and 88 foliage sprays, not a recovered
complete mature tree. The original Sprite Fright tree has fantasy claw roots.
Neither is claimed adequate by provenance. These rejected/intermediate sources
remain unchanged for recovery.

This intake restores the already licensed Poly Haven `island_tree_01` by Rico
Cilliers and Rob Tuytel, CC0-1.0. It does not use the old derived canopy (one in
three leaves retained and then enlarged 2.1 times). Original glTF and geometry
MD5 match the previously frozen repository SOURCE.json. All nine original 2K
PBR textures are restored, including three normal and three ARM maps missing
from that old derived representation. Eleven files total 79,783,969 bytes.
Complete originals, new SHA256 and source URLs are in restoration.json.

First restoration failed with a 404 because texture dependencies do not share
the glTF URL directory. Nothing was relabelled successful: the original glTF
and geometry were already verified and reused, and exact texture URLs/MD5 were
then locked from the official API include manifest. Matching existing diffuse
files are reused locally before any download.

Blender 4.3.2, scripts disabled, actual whole original 1,599,403-triangle source
rendered with all original PBR maps. I inspected the complete image: naturally
asymmetric branching and mature trunk are useful; tiny leaves can still become
screen noise. This is a source candidate, not guaranteed Chinese species fidelity,
accepted forest art or real-time performance. Original source was not saved over.
Do not fill the map with expensive copies or inflate its leaves again. Any
candidate use needs metric-scale real Godot canopy/occlusion review, explicit
shared-resource/LOD budget, and a valid navigation/collision relationship.

Reproduce the OFFLINE diagnostic, which is not game footage:

```
python3 tools/art/native_woodland/restore_original_tree.py /path/to/original-tree
blender -b --factory-startup --disable-autoexec -t 2 --python-exit-code 1 \
 --python tools/art/native_woodland/inspect_original_tree.py -- \
 /path/to/original-tree /path/to/diagnostic
python3 tests/test_native_tree_restore.py
```

The local output is `sprite-production/original-island-tree01/diagnostic/`;
no new default asset, renderer, gameplay, accepted RC or user-facing failed frame
has been published by this intake. Terrain04 intake is separately frozen at
local57a7745. Its existing binary is168,951,813B,
SHA256 e9999c8940aa1299fef7658aa534bcec27f4177973a2d6cd23383832c6e09b97.
Rebuild terrain, grass and woodland under matching profile04 before next combined
capture; never combine03 support with04 water/navigation.
