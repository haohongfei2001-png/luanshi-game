# Full-garment tailoring trials: rejected, not a Chinese soldier delivery

Three actual Blender 4.3.2 full-body Cycles renders were personally inspected.
Original source remains byte-identical. The derivative removes actual torso-belt,
emblem, lacing, hood/cape and leg-buckle objects; it does not alpha-mask them.
The full original top's 1,373 vertices, UV and Multires sculpt are retained;
its existing hem is extended. Two explicitly UV-mapped front/facing pattern
pieces have 2.5 mm Solidify thickness and bind to the complete original 566-point
cage. All 308 rig bones remain. This proves editable construction, NOT art quality.

## Actual failures and revisions
- Initial pattern left the garment at x=.1882,z=1.41; strict support check stopped
  generation. The failed log is retained locally; no fallback to body snapping.
- Trial 1: narrow front patch reads pasted-on, film beard remains, extended blouse
  intersects the waist wrap. REJECTED.
- Trial 2: full diagonal front edge and source beard geometry removed, but the
  shoulder/collar join is still not a clean sewn cross-collar. Waist intersections
  remain. REJECTED.
- Trial 3: full original wrap refitted radially, fixing the visible waist blotches
  in this still. Face/eye diffuse maps restored as a NEW diffuse-only material,
  not an equivalent reconstruction of legacy skin. Eyes still fail. Front panel
  remains too flat, collar join is abrupt, hanging blouse is bulbous, wrist wraps
  and silhouette remain recognizably derived from the film. REJECTED.

No actual Godot run for these derivatives, no motion/grip verification, no
historical or owner art acceptance, no main/default integration. Existing source
Godot probes are separate and do not certify these new garments. Source attribution
and CC BY 3.0 terms remain in tools/art/sintel_guard/NOTICE.md.

Next construction must replace and sew the full front section into the professional
sleeve/back pattern, rather than keep stacking an overlay above the old shirt.
The current trial must not be propagated to armies or advertised as a late Tang
uniform. Face, cap/hair and real weapon holding are still unmade.

## Reproduce current trial
```
blender --background --disable-autoexec --python-exit-code 1 \
 --python tools/art/sintel_guard/soldier_garment_derivative.py -- \
 /path/to/exact/guardians_r854/guardian_lao_tseu.blend /new/output
```
Use fetch_source.py and the existing pinned member manifest to recover the source.
The output is an independent editable blend plus a clearly labelled Blender image.
Images/master hashes are in local-artifacts.json; no large binaries committed.
