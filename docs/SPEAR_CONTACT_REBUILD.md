# Spear contact recovery, 2026-11-14

Base d1c1895221c33386d471922807ed590a6987dbe1. Do not merge the whole
7aaf21be experiment: it predates RC25's complete horses. This commit changes
only diagnostics/capture, not the shipped animation palette or game.

## Actual findings

Personally inspected before/after native-021 and normal-031 originals and
sampled the original after.mp4 (20 fps, 1.15 s). The close view's important
actor is behind the willow canopy; it cannot establish full-body acceptance.
The old capture is 2560x1600, not the owner's requested 2560x1440.

The existing chain audit improved subkey wrist separation from the first
rejected 0.029664 m to 0.000565 m. This does not address clip transitions.
The retained actual instance replay reproduces:

- tick 16 entering windup: left ankle 0.320271 -> 0.381637 m;
- tick 31 returning to idle: left/right 0.136224/0.136205 -> 0.048557/0.004981 m;
- tick 32 idle -> direction-walk clip 22, both state MARCH: left/right
  0.243927/0.595862 -> 0.439715/0.729024 m.

Old output filtered by state change and omitted tick 32. The new gate compares
all clip switches, including same-state switches. It intentionally does NOT
reject natural swinging feet inside an authored clip. Ankle movement is not
itself planted-foot slip: world translation, facing changes and real steps
must be separated before absolute contact acceptance. Even the baseline has
large jumps, so nonregression alone does not establish quality.

The original CC BY-SA 3.0 author curve has 65 samples, 1.666667 s, hip forward
extent 0.347115 m and left ankle forward extent 0.232967 m. Its hip and left
ankle start/end gaps are zero. Retargeting compresses source phase 0..0.65625
into the unchanged 0.22 s windup. Simply freezing source feet, changing damage
release, or adding more texture keys is not a valid transition fix.
`source.json` is a fresh audit of unchanged author data, not a new Godot render.

## Tests actually run

- `python3 tests/test_spear_transitions.py -v`: nine tests pass.
- Real captured instance replay against the two exact palettes: **expected
  exit 1**, rejecting the three transition regressions above.
- Baseline against itself: exit 0, NO_RELATIVE_REGRESSION, not art acceptance.
- Godot 4.6.3 import and capture script parse: pass after configuring writable
  XDG paths. First attempt without those paths crashed in Godot's user-data/log
  initialization; not a game failure or a successful run.
- GUI capture NOT_RUN here; no graphical socket available. Full gameplay
  aggregate not rerun for these diagnostics-only files. M5 DEVICE_NOT_RUN.

## Reproduce and capture

```bash
git show d1c1895:assets/river_gate/figures/company_motion.png >/tmp/spear-before.png
git show 7aaf21be:assets/river_gate/figures/company_motion.png >/tmp/spear-rejected.png
python3 tools/art/check_spear_transitions.py \
 tests/fixtures/native-spear-rejected/before.json /tmp/spear-before.png \
 tests/fixtures/native-spear-rejected/after.json /tmp/spear-rejected.png \
 --output /tmp/spear-rejection.json # expected exit 1
git show 7aaf21be:tools/art/source/wildfire_pike_curves.json >/tmp/pike-curves.json
python3 tools/art/audit_spear_source.py /tmp/pike-curves.json --output /tmp/source-audit.json
export XDG_DATA_HOME="$PWD/.local-data" XDG_CONFIG_HOME="$PWD/.local-config" XDG_CACHE_HOME="$PWD/.local-cache"
# On an available graphical runner, same command/config for both source SHAs.
SPEAR_ACTOR=548 SPEAR_START=10 SPEAR_FRAMES=41 SPEAR_SIZE=22 SPEAR_YAW=2.35619449 \
 godot --path . --rendering-method gl_compatibility --resolution 2560x1440 \
 --script tests/spear_contact_film.gd
ffmpeg -framerate 20 -i artifacts/spear-contact-film/frames/frame-%03d.png \
 -c:v libx264 -crf 18 -pix_fmt yuv420p /tmp/spear-contact.mp4
# Also capture 3840x2160, and size 6.3 near view, preserving identical A/B yaw.
```

This harness captures the real 512v512 battle without moving actors, hiding
foliage, or replacing live combat. Reverse yaw is a candidate for visibility,
NOT a claim of unobstructed evidence; inspect outputs and retain failed views.
PNG sequences preserve native pixels. Encoded 20 fps represents simulation
speed, not real-time performance. Normal real-time input footage and profiling
remain required separately. Capture output folder must be archived/renamed
between configurations to avoid overwriting evidence.

Next: opt-in presentation-only transition experiment with previous pose and
contact matching. It needs extra per-actor history plus GPU sampling; measure
those costs and all interrupted/directional transitions before activation.
