# Actual input follow-up: art not accepted

Real Metal run43649674554 / sourcee88b0d95 used interface47b7a6d2.
255 native2560x1440 frames/18.006729s;4 J downs,8 held physics ticks,
4 releases.39 authored thrust,143 idle fallback,73 strafe/backward fallback,
zero authored walk. Hero impacts0; nearest enemy30–34m. Not full control/contact.

Camera.unproject_position yields logical coordinates. Sending those directly
to Input.parse_input_event applies stretch again. Actual Godot4.6.3 headless
round trip at root2560x1440/logic1422x800:400,300 arrives222.1875,166.6667.
This turns aim away from movement and correctly triggers strafe fallback.
The opt-in harness now uses viewport.get_final_transform before the native
Input event. Correction: frozen6c53 only recorded the requested logical position;
its attempted actual-pointer logging edit was not present. Do not claim those
logs contain observed Controller coordinates. The separate contact harness adds
requested logical/native and observed Controller pointer/ground aim receipts.
Test proves unconverted route misses, corrected600,500 arrives600.0001,500.
No Battle writes, default Controller change or OS pointer warp. Actual Metal
05 retest run43652380636 still showed0 authoredWalk,69 strafe fallback,135 idle,
35 thrust and0 hero hits. Coordinate roundtrip is NOT a real-game fix claim.
Long8m aim can also hit intervening bank:2m/4m CPU ground targets inverted
correctly while8m hit a different surface. Original05 lacks observed pointer
receipts, so do not assert an OS overwrite as its cause. The next contact harness
uses short2m movement aim and observes both walking and attack ground hits.

Old body receipts incorrectly called ViewportTexture metadata4608x2592 native
attachment. Same-engine_drawn JPEGs are2560x1440. Screen fraction13.2892647%
is valid, actual projected height191.3654px, not344.46px. Keep old logs intact.
Future receipts explicitly label texture-reported metadata, not native size.
Join frame.pixels by engine_drawn for true pixels, without extra readback.
These are cached helmet/face/boot geometry projections, not silhouette masks.
The224MB43-surface oracle is one diagnostic actor, not army runtime. Materials
incomplete, art unaccepted, M5 untested.
