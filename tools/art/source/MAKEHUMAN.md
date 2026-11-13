# MakeHuman HM08 hand geometry

The editable hand topology, digit weights and reference joint coordinates come from MakeHuman Community. The upstream OBJ identifies the HM08 basemesh and explicitly releases it under CC0 1.0. The rig and weights also identify their license as CC0. The game's mesh bake, finger pose, handle fit and three distance meshes are modifications. The game uses its existing wrist animation and cloth atlas.

| Upstream input | Pinned Git blob |
|---|---|
| [base.obj](https://github.com/makehumancommunity/makehuman/blob/a8bc2d54ff0ac92e78ff71431b1023eda42bf482/makehuman/data/3dobjs/base.obj) | `d26635e9326e3cca30778fd7b9c00062b03cce09` |
| [default.mhskel](https://github.com/makehumancommunity/makehuman/blob/a8bc2d54ff0ac92e78ff71431b1023eda42bf482/makehuman/data/rigs/default.mhskel) | `b02cbecae00143856410d7561adf006d83bf9b3e` |
| [default_weights.mhw](https://github.com/makehumancommunity/makehuman/blob/a8bc2d54ff0ac92e78ff71431b1023eda42bf482/makehuman/data/rigs/default_weights.mhw) | `66185806afacf87749be8e5cf6dbf66496b2a6b0` |
| [Asset license](https://github.com/makehumancommunity/makehuman/blob/a8bc2d54ff0ac92e78ff71431b1023eda42bf482/LICENSE.ASSETS.md) | `f3ede1fc3318f8d794e2cb51924186c62f02f71a` |

The named upstream rights holders are Data Collection AB, Joel Palmius and Jonas Hauquier. The source revision is `a8bc2d54ff0ac92e78ff71431b1023eda42bf482`. No store assets are required.

Run from the repository root on Ubuntu 24.04 with Blender 4.0 and Python 3/Pillow.

```sh
python3 tools/art/fetch_hand_source.py /tmp/river-hm08
blender -b -t 1 --python-exit-code 1 --python tools/art/makehuman_hands.py -- /tmp/river-hm08 tools/art/source/hand_grips.glb
python3 tools/art/bake_river_company.py --geometry-only
```
