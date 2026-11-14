# Unified production reset recovery

This branch preserves a rejected runnable experiment as its code parent, NOT as an accepted visual foundation. Do not build another art candidate from the former Quaternius/old-fort/old-ground mixture.

Local development commits: `2034a795e8ab80a522f6e346854d32bb432cae28` (design), `cd66b492d91fc8828e90308f27ec3397f28617c7` (support/admission), `5fae2ab053cdb5efa464dbcfd4def60bec84cdc0` (cleanup). Remote publication overlays only the explicitly listed small text files onto existing remote `a3ef6216d3b55ebd141d983bf1851715410a922f`. Remote SHA is consequently different, not a claim of identical local ancestry. No old branch/main ref is changed.

Recover on the Dot cloud computer, not the owner's computer:

```sh
git fetch origin dot/river-authored-reset
git worktree add ../luanshi-authored-reset-recovery origin/dot/river-authored-reset
cd ../luanshi-authored-reset-recovery
python -m unittest discover -s tests/art_reset
godot --headless --path . --script tests/art_reset/asset_contract.gd
godot --headless --path . --script tests/art_reset/surface_authoring.gd
godot --headless --path . --script tools/art/authored_reset/bake_support_scene.gd
godot --headless --path . --script tests/art_reset/support_lifecycle.gd
blender -b -t 2 --python tools/art/authored_reset/build_design_blend.py -- /tmp/river-authored-design
```

Tools used locally: official Godot 4.6.3, installed Blender, Python 3. The bake produces a disposable `user://authored-reset-support.scn`; lifecycle test must follow the bake. On constrained cloud filesystem use writable XDG_DATA_HOME/XDG_CONFIG_HOME/XDG_CACHE_HOME. No network download is needed for these tests. No third-party image is included in this reset code.

Verified: four Python tests; asset admission, continuous support surface and three-cycle scene lifecycle tests; actual editable support .scn and non-game Blender design .blend generated. Not verified: complete game regression on this publication, professional finished environment, new actual Godot graphics, animation contact, performance, M5. Normal game code was not changed.

Next: obtain or author a coherent professional editable source foundation under verified public redistribution rights; admit it with exact SHA/units/UV/material/LOD inventory; author the whole scene to the common layout, run actual game same-camera 2K/4K and full input/performance evidence. Do not present gray volumes, synthetic test boxes, support meshes, inventory counts or passing tests as finished visual quality. No purchase/account/paid service/user-computer access is authorized by this file.
