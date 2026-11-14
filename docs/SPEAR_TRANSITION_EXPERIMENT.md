# Opt-in spear transition research: REJECTED for activation

This is a runnable, isolated **single ordinary actor** presentation experiment,
not a production animation fix. Shipped shader, bank, scenes, battle, other
weapons and complete RC25 horses remain byte-for-byte unchanged. Default
`tests/spear_contact_film.gd` does not install the probe. Nothing is enabled by
normal gameplay. The author curve is retained unchanged, not foot-frozen.

## Implementation and cost

`experimental/spear_transition.gd` remembers sixteen displayed world-space bone
affines. On any clip change (including MARCH idle -> MARCH directional gait),
it records outgoing displayed minus incoming pose. A 150 ms quintic decay adds
that residual to **the still-advancing incoming animation**. Interruptions
restart from the actual previous displayed affines. Rewind or >200 ms culling
gaps invalidate history. Bone matrices and per-actor transforms remain separate.

`experimental/spear_probe.gd` duplicates only the selected ordinary actor's
material and mesh submission in a one-instance MultiMesh. It suppresses that
same actor's original submission and caster, never its simulation/roster, and
supplies a matching experimental caster. Existing actor data is saved before
replacement; exact applied offsets are included in capture JSON. Optional
SPEAR_PALETTE and SPEAR_SHADER let this one actor use the **isolated** rejected
native source without replacing the game-wide palette or deleting RC25 horses.

Added GPU cost: 48 vec4 uniforms = 768 bytes/actor, three dot products per bone
for position plus three for normal (twice for blended vertices), **zero added
texture reads**. Existing 4 reads/bone remain. CPU: 16 palette-bone decodes each
sample, each with 4 RGBA rows and up to 2 filtered pixels; sixteen affine history
and residual entries (~1536 raw numeric bytes, excluding Variant/Array overhead),
plus transient arrays. Probe adds one draw submission, potentially another
shadow draw; real driver costs and actual memory are NOT MEASURED. This per-actor
material path is deliberately not rolled out to 1024 actors. Bulk integration
would need a batch history texture/index channel, not 1024 new draw calls.

## What was actually measured

Godot 4.6.3 headless `tests/spear_transition_math.gd` runs on each original bank:

- 23 actual consecutive capture frames, ticks 10..32; matches preserved ankle
  decode within 0.1 mm. This is **23 frames, not 32 frames**.
- 480 additional synthetic walking/running direction and repeated-interruption
  samples across eight headings. Synthetic samples are not new Godot gameplay.
- 344 assertions per bank: decoder parity, clip-boundary continuity, interruption
  continuity, incoming motion remains active, exact decay expiry.

| Measure | RC25 baseline bank | Rejected native spear bank |
|---|---:|---:|
| Lowest boot sole Y, m | +0.006047 | **-0.015919** |
| Maximum boot basis length distortion | 0.1371% | **9.9565%** |
| Shin/boot seam, m | 0.000608 | 0.000608 |

These are CPU matrix measurements inside Godot, **not visual acceptance**. The
native result penetrates the ground and distorts the boot. Eliminating the
first discontinuity alone is insufficient. This prototype must stay OFF.
It is additive affine inertialization, **not contact IK**. Torso lean and cloth
flutter after skinning are not reconstructed in the CPU history, another
reason this is not an approved full-body chain. No attempt to hide failed soles
with a frozen foot, camera change or ground clamp was made.

## Exact reproduction

```bash
export XDG_DATA_HOME="$PWD/.local-data" XDG_CONFIG_HOME="$PWD/.local-config" XDG_CACHE_HOME="$PWD/.local-cache"
python3 tests/test_spear_transitions.py -v
godot --headless --path . --script tests/spear_transition_math.gd
git show 7aaf21be:assets/river_gate/figures/company_motion.png >/tmp/spear-rejected.png
SPEAR_TEST_PALETTE=/tmp/spear-rejected.png godot --headless --path . --script tests/spear_transition_math.gd
# Raw reports: artifacts/spear-transition-{before,after}.json
```

For a graphical runner, extract **only** the licensed source shader/bank for the
selected actor, not the old branch's horses, gameplay or other files:

```bash
git show 7aaf21be:scripts/field/company_skin.gdshader >/tmp/native-spear.gdshader
# A: isolated native source with no transition. Archive output before B.
SPEAR_PROBE=1 SPEAR_TRANSITION=0 SPEAR_PALETTE=/tmp/spear-rejected.png \
 SPEAR_SHADER=/tmp/native-spear.gdshader SPEAR_ACTOR=548 SPEAR_START=10 \
 SPEAR_FRAMES=41 SPEAR_SIZE=22 SPEAR_YAW=2.35619449 \
 godot --path . --rendering-method gl_compatibility --resolution 2560x1440 \
 --script tests/spear_contact_film.gd
# B: identical command except SPEAR_TRANSITION=1. Also capture 4K and size 6.3.
```

Inspect both raw videos; do not call a changed angle proof that obstruction is
fixed. Both sides must use the same source, seed, actor, time, size, yaw and
rosters. Existing simple palette audit cannot measure probe-applied residuals;
use capture `experiment.offset_matrices` or this math test and inspect real
pixels. The source-only film still needs true realtime controls/performance
recording; fixed-tick footage is not an FPS measurement. GUI shader compilation
and draw verification remain NOT_RUN in this restricted display environment.

## Next repair, not a claim of completion

Use previous contact state to solve a rigid two-link hip/knee/ankle chain,
keep sole support constraints and source swing timing, and re-solve the pelvis
when leg reach becomes infeasible. Preserve both-hand rigid shaft registration.
Measure knee/hip continuity, actual sole trajectories, limb lengths and grip
seams at transitions/interruption, not just a zero first-frame jump. Do not
correct the current failure by stretching bones or locking all feet. Only then
consider bulk GPU history and production activation after real visual review.

## Second iteration: rigid hierarchy plus source-supported clearance

`SPEAR_RIGID=1` explicitly selects the next isolated prototype, still requiring
`SPEAR_PROBE=1 SPEAR_TRANSITION=1`. No normal game scene references it.

Quaternion rotation residuals and the pelvis-pivot translation are separated.
The incoming animation continues advancing; children attach to their parent's
animated joint while each bone keeps its original rigid basis length. Source
boot soles within 18 mm of the actor's ground plane mark a support phase.
Only then may the whole pose move upward to preserve that source clearance;
neither foot's XZ coordinate is frozen and swing timing is unchanged. This is
not a terrain query/contact IK solution. It adds quaternion work per bone on
CPU; GPU uniform/storage/sampling and draw overhead remain as above.

Actual Godot numeric replay of the same native bank:

- Boot basis distortion **9.9565% -> 0.0000117%**.
- Lowest sole Y **-15.919 mm -> +4.596 mm**.
- Tick 32 boundary left/right residual jumps **0.000075 / 0.000958 mm**.
- Maximum support lift **35.820 mm**. This is disclosed pose translation, not
  hidden character teleportation in the simulation.
- **New failure**: support-hand distance from right-hand shaft axis grows from
  **0.119 mm in the source palette to 102.088 mm** during the rigid transition.
  Hierarchical rotation blending does not preserve the two-arm closed chain.
- The baseline bank similarly grows from 0.132 mm to 15.815 mm axis error.

Each bank passes 1972 diagnostic assertions, including 480 synthetic direction/
interruption samples, finite transforms, rigid axis lengths, decoding parity,
continued incoming motion and exact expiry. This is a **math/regression pass,
not an activation pass**. Reports explicitly retain `activation_allowed:false`
and list >2 mm shaft error as a rejection. Source poses, first affine failure
reports and all game defaults are preserved. GUI is still NOT_RUN.

```bash
SPEAR_RIGID=1 SPEAR_TEST_PALETTE=/tmp/spear-rejected.png \
 godot --headless --path . --script tests/spear_transition_math.gd
# Use the previous graphical B command plus SPEAR_RIGID=1 for this third view.
```

Next smallest correction is a shared rigid shaft target and reach-constrained
arm solution that preserves each elbow plane, not independent hand interpolation.
Keep the failed rigid version for A/B and do not activate it pending that repair
and real Godot capture. Full contact/path stability across repeated strikes and
actual performance remain unproven even after these two numeric improvements.

Final verification for this isolated iteration: complete `./tools/test.sh`
returned exit 0; nine Python transition-audit tests and capture-driver parse
also passed. The aggregate exercises the unchanged shipping game, while the
separate 1972-assertion runs exercise the opt-in prototype. Existing ObjectDB
exit warnings remain in aggregate.log; no SCRIPT ERROR / Parse Error / ERROR:
markers. This does not replace a real graphical run of the generated shader.

## Third iteration: shared shaft with rigid, reach-constrained arms

Explicit opt-in `SPEAR_SHAFT=1` selects this iteration (still requires
SPEAR_PROBE=1 SPEAR_TRANSITION=1). The prior failed affine and rigid versions
remain selectable and their original evidence remains unchanged.

`experimental/spear_shaft_transition.gd` keeps one rigid shaft rotation. It
preserves the original sliding-hand span, with a decaying outgoing span offset
at a transition. The two palms share that axis. Twenty-four alternating
reachable-sphere projections place the common shaft anchor; two-link upper/
forearm chains reach the wrists while retaining each incoming elbow plane.
Each bone's length remains fixed. Only the basic spear/idle/movement path is
solved, not guard/hit/death or unrelated weapons. It does not alter feet, hips,
author curves, attack timing or simulation. The extra CPU work is two analytic
arm solves and 48 sphere projections during the 150 ms transition. Shader
uniforms, texture reads and isolated-probe draw overhead are unchanged.

On the identical old RC25 capture with the isolated native spear palette:

| Measure | Rigid-only failure | Shared shaft iteration |
|---|---:|---:|
| Maximum hand/shaft axis error | 102.088 mm | **0.119 mm** |
| Maximum arm axis length distortion | not gated previously | **0.0000234%** |
| Maximum wrist seam | not gated previously | **0.698 mm** |
| Reach-sphere excess | not applicable | **0 m** |
| Lowest old-plane boot sole | +4.596 mm | **+4.596 mm, unchanged** |
| Maximum support lift | 35.820 mm | **35.820 mm, unchanged** |

Each palette passes 3366 assertions. The 480 synthetic direction samples now
also interrupt through windup, recovery and guard. Added tests check both wrist
seams, shared shaft grip, rigid arm lengths, and every actual captured ankle
against the prior rigid result (unchanged within 1 micrometre). Source bank
sampling, natural incoming movement and exact expiry remain tested. These are
real headless Godot math results, not graphics, motion attractiveness or FPS.

```bash
SPEAR_SHAFT=1 SPEAR_TEST_PALETTE=/tmp/spear-rejected.png \
 godot --headless --path . --script tests/spear_transition_math.gd
# Use graphical B command plus SPEAR_SHAFT=1 for this fourth view.
```

### New map and outstanding acceptance

The fixture is the **old RC25 planar terrain**, not the parent's 141031aaaa
road/shoulder terrain. A positive absolute Y does not prove contact on new
slopes. The live probe now records both ankle positions and all four modeled
boot-sole corners with **Ground.deck_height at each actual world XZ**, rather
than sampling only the actor origin. `terrain_contact_acceptance:false` remains
explicit. These modeled corners do not replace inspection of rendered boot
mesh pixels. The transition's support lift still uses the original actor-base
plane, so new-terrain penetration/hover is a possible failure for live capture.

No current numeric gate fails on this small old fixture, but activation stays
**false**: post-skin cloth/torso lean, new-terrain contact, broader natural actor
sequences, numerical stability across LOD/culling, visual grip/orientation,
real graphical shader compilation, actual performance and owner art review
are all still unverified. Do not label it a production-ready natural full-body
chain. Default shipping files and game behavior remain unchanged.
