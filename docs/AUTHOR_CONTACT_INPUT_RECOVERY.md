# Default-OFF real-input contact diagnostic

This is a separate harness, not a replacement for frozen18-second05 evidence.
Attach `scripts/review/author_contact_input_review.gd` as a Node, call the same
`begin(field, configured_actor, recorder, measured_cache_bytes, phase_fixture)`.
It does not set a camera projection/profile or calibrate actor size. Integration
owns those. Tested CPU candidate:45deg/FOV50/yaw-65/lookheight1/lead[1.5,0].

It reads existing opponents and Ground waypoints, then emits genuine four-way
movement actions, native-transformed pointer events, sprint and Space/J keys.
No assignments to Battle values, HP, unit positions, damage or AI. Route probes
are not applied as motion. First1.8seconds use normal walking, then sprint only
beyond8m. Aim is2m ahead while moving, actual target in attack range. J pulses
are intended600ms with800ms cadence but receipts, not intent, prove delivery.
Actual death/settlement ends the diagnostic honestly. Guard is a real skill,
not invulnerability. All owned keys and hide/follow state release on teardown.

Receipts distinguish requested logical/native pointer, observed Controller
pointer, walk/attack ground aim, real state/HP/timer/cooldowns/buffer and actual
hit counter. Both projection-derived texture metadata and frame.pixels must be
joined by engine_drawn; texture metadata is NOT verified attachment resolution.

## Evidence and limits
Boundary test PASS: movement/sprint/Space/J release on cancel/unload, no Battle
snapshot change. Route query test PASS:20-per-side seed default,71 legal probe
points to actual enemy26, no movement or damage applied by the planner.

Real Controller CPU test uses authored landform and real input/physics, but a
geometry-free ProbeActor. It is NOT rendered actor/GPU/art acceptance.
- Initial45deg guard approach:tick333 actual death,0hero hits,1J/5held ticks,
  min observed enemy distance2.07m;3walk mappings, mostly run/hit fallbacks.
- First1.8sec walk plus600ms attack pulse:tick371 death,0hits,2J/5held,
  107walk mappings. Attack has not been proven to complete before interruption.
- Same-input cleanup rerun:tick373 death,0hits. Sound voices stopped and allowed
  two process frames before shutdown; no ObjectDB warning. Timing is real wall
  input, not claimed deterministic equivalence across CPU scheduling.

Exact CPU raw logs/rows retained under shared author-contact-profile45-{guard,
held,cleanup}; original failures retained. Added final state/cooldown receipts
compile in boundary test; require subsequent actual Controller/native evidence.
Never treat zero hits as acceptance or tweak damage/HP to produce a pass.
Run/strafe/idle/guard/death unsupported by the two authored clips remain honest
old-visual fallbacks. The224MB evaluated43surface actor is an oracle, not a
shared-army production runtime, and its materials are incomplete.

Next: review genuine state interruption and legal operation, then integrate a
bounded actual native scene capture. No additional CI is launched by this file.
Art NOT ACCEPTED. MacBook Air M5 NOT TESTED.

## Follow-up: genuine attack reached, not survival/art acceptance
Independent state audit showed early6m Space starts spear slot3 and holds GUARD
for1.12s. J was correctly mapped but the remaining GUARD and subsequent STAGGER
consumed its buffer; the old plan was a poor operation sequence, not proof that
native pointer delivery failed. Disable only that automatic early brace.
The same authored-ground45deg CPU Controller now entered ordinary WINDUP at353
(timer0.22), RECOVER at358 and actual hero.impacts0→1. It still died naturally
at360.1J/7held physics ticks/1release,107walk_only and11ordinary_thrust mappings.
All inputs released; clean exit. No HP/AI/position/damage changes. The controller
run uses a geometry-free actor probe; real Metal new-character render NOT RUN.
Exact raw logs: author-contact-profile45-noearlybrace-rows.json and matching.log.
Keep prior death failures; do not claim survival, full authored clips or art pass.
