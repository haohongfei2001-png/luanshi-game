# One hero phase contract, default OFF

Technical experiment only. No default/controller/Battle edits, no production visual
acceptance, no change to rig, weights or cache. Based on region source 230de161.

Integration: create/configure `controlled_author_actor.gd` separately, instantiate
`author_unit_binding.gd`, explicitly enable it, call `update_once(battle, actor)`
after each fixed simulation step. Assign the returned `hidden_unit_id` to the
existing old-visual hide slot EVERY update. -1 means restore old visual. On removal,
call `disable(actor)`, restore the hide slot to -1, then release the actor. Do not
coexist with the static oracle or another owner of that hide slot. No default
integration is installed here. This adapter never touches that view or Battle.

`thrust_peak` defaults -1: thrust is unsupported until the integrator explicitly
supplies the source-evidence phase. Current rejected source's measured aimed
extension peak is **19/36**, not 0.5. See `tests/fixtures/author_thrust_peak.json`:
37 samples over 1.5s, source hash and full report hash, original measured centers
and axis. `tools/check_author_thrust_peak.py` verifies maximum projection only in
its aimed .30–.70 interval. The author animation's continuous extension peak is
.52; 19/36 is the actual discrete peak. This does NOT prove target contact.
The source is already known to intersect the torso. Use only to diagnose mapping.

WINDUP progress 0..1 maps 0..peak, RECOVER maps peak..1. True release remains
Battle's WINDUP→RECOVER transition; no extra hits, no event injection, no timer
write, no inference that a peak means a successful hit. Only spear, ordinary slot0,
nonstock, noncharging single thrust is represented. Missing evidence falls back.

Walk is 33 samples/1.333333s. It advances once per observed fixed tick ONLY while
actual displacement is nonzero, heading and displacement agree (dot >= .98),
heading change is small (dot >= .98), and `visual_run` is false. Strafe/backward,
sharp turns, running, stationary idle, skills, other weapons, mounts, hit flashes,
guard/stagger/rout/escaped/death explicitly fall back to the original visual.
Full-strength normal hero movement can be marked visual_run by existing Battle
hysteresis (>3.55 units/s entering run): it also falls back, not falsely called walk.
Repeated rendering of a tick does not advance phase. Actor origin/heading follows
the actual hero and existing ground function, scale1.07, zero ground lift and
zero extra root motion. Missing updates do not cause catch-up walk advancement.

Stopping phase advancement is NOT proof of planted feet. Source stride vs actual
speed is NOT calibrated. Existing source feet/ground and spear/torso failures are
NOT repaired. There is no blend at fallback boundaries or walk/thrust transitions;
no idle pose or turn/strafe action was fabricated. Native video is still required.

## Actual technical tests

Godot4.6.3 headless CPU, 600 ticks, two real deterministic Battle copies with
identical public inputs/actions. Every tick: snapshot bytes identical between
copies and before/after binding; actual position and facing checked for supported
frames; repeated update idempotent; unsupported/stop doesn't advance walk.
Additional fixture tests: all unsupported states, weapons, mounts, skills, missing
peak, peak continuity, turn/strafe/run, failed actor application, disable cleanup.
Actor is a lightweight ProbeActor: real shader/cache/GPU path NOT RUN.

```sh
python tools/check_author_thrust_peak.py
mkdir -p .test-data
XDG_DATA_HOME="$PWD/.test-data" timeout 20 godot --headless --path . \
  --script tests/author_unit_binding.gd
```

Initial default user-log path crashed before script start; explicit writable
XDG_DATA_HOME resolves it. Initial typing and fallback-fixture issues were corrected
and tests rerun. This is not a full repository regression or animation/art PASS.
M5 DEVICE_NOT_RUN; native visuals NOT_RUN; ART_REVIEW_REQUIRED.
