# Intact source-character state adapter, isolated and not shipping

This is an engineering integration experiment, not a finished soldier or an art
acceptance result. The ordinary game does not preload or instantiate it.

The adapter reads real `Battle.Unit` state, interpolated position/heading and the
shared deck height. It instantiates the complete imported 65-bone UBC source
character with its original native `Skin`, geometry, weights, materials, UVs and
nine retargeted clips. It does not reduce the rig to the old 16-bone shader.
The two named native hand attachments are empty frames, not validated weapon
grips. Future compatible full garments can replace the source model path.

## What was actually tested

Godot 4.6.3 headless observes real bridgehead battles at 20, 100, 250 and 512
ordinary soldiers per side. A full save snapshot, including RNG, unit state,
casualties, commands and projectiles, is byte-identical immediately before and
after every batch of adapter observations. Original mesh arrays, weights,
Skin bindings, bone parents/names and all 65 rest transforms remain unchanged.
The actual damage and death outcomes are retained in `state.json`.

The passive, no-hero-input 20-vs-20 fixture produced one-sided hits `[43, 0]`
after 600 ticks. An initial assumption that this passive scene would guarantee
two-sided contact failed. The adapter test records that limitation instead of
moving enemies, fabricating contact or altering rules. It is NOT the normal
player-input/performance acceptance gate. The other three fixtures observed
two-sided hits. No FPS, rendered foot contact or full input coverage is claimed.

## Explicit incompleteness

- Native GLSL/GPU real-game capture: **NOT_RUN**.
- All art and foot contact: **NOT_ACCEPTED**.
- Source character costume remains modern and is not historical game art.
- Sword attack is not relabeled as spear/guard/archery. Missing authored
  weapon-contact curves and native riding clips appear as explicit reasons.
- A missing action currently samples idle in this diagnostic only. It must
  never silently replace an existing shipping weapon action.
- Walk-cycle distance is the publisher's root-motion curve scaled by the
  documented retarget pelvis ratio, not an empirically approved foot lock.
  Jog/sprint source distances are retained, but not selected by the adapter.
- Static rest-floor compensation (~9.51 mm) is not animated sole grounding.
- This native Skeleton-per-actor probe is not a 1,024-person performance plan.

## Reproduce

```sh
godot --headless --editor --path . --import
godot --headless --path . --script tests/intact_character_state_adapter.gd
```

Require exit 0, the `INTACT_CHARACTER_STATE_PASS` marker, `failures: 0` and no
`ERROR:`/`SCRIPT ERROR` in the log. A GDScript `assert` inside a helper can return
from that helper without stopping its caller; this test counts failures and
sets a nonzero process exit instead of allowing a misleading final PASS.

Continue with an actually suitable complete garment and professional weapon
motions, then visually validate the intact actor in the normal battle before
any default game integration. Original RC24/RC25 and shipping presentation are
unchanged.
