# Eight-direction static asset experiment, default OFF

This is an **AI-generated asset** diagnostic, not a concept-game screenshot,
not an animated soldier, and not the same-source Guardian 3D/sprite comparison.
Original unchanged atlas SHA256:
`91fce351c709de249798f64064251a89494fb141f9567dbd03cb68dcf5bff3b3`.
No source PNG is included in this text-only commit. The producer retains the
original RGBA PNG; exact bytes must be delivered separately, not regenerated
and assumed equivalent. Atlas is 1536×1024, eight 384×512 cells.

## Actual checks

- All eight alpha≥128 foreground bounds stay inside their cells; cell-edge alpha
  is only 1. Entire spear boundaries are retained at that threshold.
- Low-alpha generated background haze exists. Probe discards alpha below128/255;
  original source bytes are preserved. This is **not** proof of clean Godot edges.
- Godot4.6.3 headless import and actual startup load all eight quads without errors.
  No graphical run or pixel acceptance has occurred yet.
- Foot-contact anchors are manually estimated, not ground-truth calibration.
  Common pixel scale intentionally reveals per-direction height drift.
- Intended angles are labels, not proof of exact45° rotations. Grip/stance and
  camera consistency still require visual rejection/repair.
- Only static stance exists. Walk, stopping/turning transitions, attack, defense,
  hit and death do not exist. No battle state or shipping code loads this probe.
- Source has helmet plume but **no spear tassel**, following ordinary-soldier rule.

## Reproduce

```
python tools/art/spearman_sprite_probe/audit_atlas.py EXACT.png --out tools/art/spearman_sprite_probe/manifest.json
SPEARMAN_ATLAS=/absolute/EXACT.png godot --headless --path tools/art/spearman_sprite_probe --quit-after 3
SPEARMAN_ATLAS=/absolute/EXACT.png SPEARMAN_CAPTURE=/absolute/frame.png godot --path tools/art/spearman_sprite_probe --resolution 2560x1440
```

Graphical screenshot uses a bounded12-unit orthographic diagnostic (not the
obsolete mandatory22 camera, and not a claimed approved Wild Rift camera),
unlit baked sprites on neutral matte ground. It is not a lighting comparison
or a full scene. Actual source PNG must pass SHA gate. Do not label this as
full animation, gameplay integration, art PASS or hardware performance evidence.
