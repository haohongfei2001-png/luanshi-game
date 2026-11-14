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
