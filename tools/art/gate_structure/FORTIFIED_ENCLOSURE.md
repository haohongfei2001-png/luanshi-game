# Complete fortified entrance experiment

Status: isolated, default OFF, ART NOT ACCEPTED. Does not supersede frozen
architecture 07 / RC24 / RC25 or the owner's actual-game acceptance.

## Why this is structural, not a lighting patch

Native run 43649674554, source e88b0d95, runtime 287e2ae3 showed the corrected
curved gate and roof, but a thin straight facade, black upper hall and a naked
background. The generator replaced only the front visual wall while Ground's
side/rear collision survived. This experiment restores a complete enclosure in
that existing footprint and makes the upper hall a sheltered three-bay room
behind a gallery, retaining the editable professional roof/frame and bridges.

This is a fictional late-Tang-inspired military compound, not a reconstruction
of a named monument. Thick continuous front masonry and solid-backed real ramps
join side returns and a rear wall with an open retreat postern. No new gameplay
wall, fake walkable upper room or inaccessible expanded fort footprint is added.
The rear postern is 3.36 m wide and 3.70 m clear high; front gate retains 8 m.
Environment owner sampled all four foundations with actual Ground05/Surface:
all heights zero. Foundation bottom -0.55 m is buried; no terrain relocation.

All original licensed material pixels, roughness, normal strength and source AO
remain unchanged. No exposure/albedo lift to hide missing environment lighting.
Roof cropping is allowed artistically; diagnostic all_bounds_inside does not
justify flattening the gate. Sky05 and normal-camera actual rendering must still
be reviewed together. Offline structure images are NOT Godot/gameplay evidence.

## Reproduce

Append `--fort-enclosure` to the frozen 07 build command, retaining
`--native-roof-band --complete-gate-masonry --complete-portal --surface-root ...`.
The new flag is OFF unless explicitly provided; frozen behavior remains in else.
Run `tests/fort_enclosure_navigation_samples.gd -- OUTPUT.json` with Godot,
then Blender `audit_enclosure_navigation.py -- source/architecture.blend
OUTPUT.json AUDIT.json`. This uses real Ground functions and actual solid face
planes, not merely comparing duplicated metadata constants. It is a finite
sample audit, not a full mounted siege or global collision proof.

Retain authored-solid, roof seam, portal-interface, bearing, source-PBR-byte
and actual Godot AO-import / gate-HP tests. Runtime mesh grouping remains in
export_runtime_architecture.py; source entity count is not GPU draw-call count.
Final acceptance requires actual native scene traversal, siege and normal-camera
same-condition image/film and performance; none is implied by these contracts.

## Verified isolated revision 02

Local Blender 4.3.2 build succeeded. GLB SHA256
`2385bbad4f5d4a90333bfcbd04b59aca5d1584eea91d22a287cc8ad2a891cc73`;
editable mother SHA256
`513a6f9068d95717014ddc0785244d681ffb4c947eac4334f68fa4a3a0889c4d`.
846 authored closed-solid checks; 15 gate-clear, 12 walkway-clear and 14 bearing
rays passed, plus portal-interface and original roof-band audits. 11,930 actual
Ground points yielded 41,200 open body samples at 0.07/1/2.5/3.4 m across 157
new solids; zero sampled obstruction, ramp height error 0.000000210 m.
Official Godot 4.6.3 headless HP 260/130/0/260 hide/restore test passed (20v20,
tick zero, NOT a battle). Actual AO import and byte-preserved source albedo /
roughness / normal checks passed. No native GPU rendering/performance yet.
01 offline full-fort self-review established continuous return-wall depth and
hall gallery, but does not establish game quality; 02 only raises and supports
rear postern headroom. Keep 01 and 07 as recoverable baselines.
