# One complete actor in the actual field, experimental only

`scripts/field/experimental/controlled_author_actor.gd` extracts the complete
actor loader from the standalone probe. It intentionally creates no camera,
light, plane, controls, battle mutations or automatic action mapping. This is
one authoring oracle, not the shared3D LOD2 production architecture.

```gdscript
var actor = load("res://scripts/field/experimental/controlled_author_actor.gd").new()
field.add_child(actor)
var configure_error = actor.configure_author_oracle(cache_directory)
if configure_error != OK:
    push_error("Oracle cache configuration failed: %s" % configure_error)
    return
# Caller supplies the actual field/unit transform and actual existing camera.
actor.global_transform = verified_actor_transform
var phase_error = actor.apply_author_phase("walk", phase_0_to_1)
if phase_error != OK:
    push_error("Oracle phase failed: %s" % phase_error)
    return
print(actor.receipt())
```

Generate cache from the source-pinned `rebuild.sh`. Keep the exact returned
source SHAs, cache budget and camera receipt with field captures. Do not substitute
old geometry while claiming the latest source. Parent transform is independent
of the cached source-space animation; no source motion/geometry is normalized
or lifted by this adapter. Source coordinates are converted BlenderZ-up to
GodotY-up. Validate facing against the actual unit rather than assuming an old
programmatic actor's convention. Source foot penetration and grip remain failed.

The exposed `thrust` name is an unaccepted authored visual experiment, not an
approved hit/contact animation. There is no link to battle damage, attack timing,
unit count, orders, save data or RNG. Do not silently map unavailable attack,
defend, death, mount or shield/bow states to this clip. No shipping entry imports
this script. Do not instantiate224MB of cached poses for every soldier.

Headless adapter check actually loaded43complete meshes, both clips at0/.5/1,
rejected unknown/out-of-range phase requests and duplicate configuration, retained
parent transform and created only mesh children. It used the explicitly recorded
older197.5MB local fixture, not latest flat-normal geometry; it is API validation,
not actual-field graphics acceptance. The standalone whole-actor captures are
actual Godot but still do not constitute this field integration.

Cache directory must be an external absolute path or user:// raw data, not res:// imported PNGs. PNG bytes are explicitly decoded, independent of import remapping. The runtime shader is in scripts/field/experimental so tools/art/.gdignore cannot remove it. Empty-cwd exported-PCK validation remains required before packaging.

Actual Linux Godot 4.6.3 headless PCK check: explicitly packed only project,
loader, exportable shader and test; launched with --main-pack from empty cwd.
43 meshes and both clips at 0/.5/1 loaded; raw external PNG decoding succeeded.
See actor-adapter-empty-cwd-pck.log. This proves runtime resource isolation for
this PCK, not a macOS export preset, actual GPU rendering or latest cache geometry.
All test operations now execute outside assertions, including negative cases.
