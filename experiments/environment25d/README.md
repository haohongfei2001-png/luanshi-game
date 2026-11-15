# Isolated 2.5D feasibility, default OFF

Not an accepted map, not an owner-approved camera, not a game release. No main menu/config/core file is changed. This is a separate Godot project. The21 copied core files are byte-for-byte9d86c168 inputs recorded in SOURCE.json, not a new combat simulator. The production-v2 source18 bindings are read-only presentation. Core changes elsewhere do not propagate silently into this experiment.

Run with Godot4.6.3:

```sh
python3 experiments/environment25d/restore_assets.py
LUANSHI_25D_EXPERIMENT=1 godot --path experiments/environment25d --script app.gd -- --interactive
```

WASD and mouse aim/click call actual Battle input methods. Arrow keys pan. Escape exits. Without `--interactive`, a bounded waypoint input pilot runs through the same methods, while Node._physics_process advances the unchanged fixed-step Battle. No live Unit position, HP, kit or casualties are assigned. Initial source-aware placement uses AuthoredMuster. All19 actual units are rendered:11 true foot SPEAR actors including hero and8 explicitly diagnostic other-kit capsules. No other kit is dressed as a spear soldier.8v8 is a feasibility scenario, not512v512 validation or a reduction to the main game.

World-anchored clean AI environment material and hand-authored vector depth silhouettes use one fixed orthographic inverse projection to generate support, bridge-rail obstacles and visual masks. They are not a screen-space wallpaper. The image contains no people/animals/flags; dynamic units are actual3D scene actors. Projection algebra alone does not prove good occlusion: GPU images must be reviewed. Masks may fail at source silhouettes and will then be rejected.

The viewport is native2560×1440 or3840×2160 at internal scale1. The environment source is only1672×941: a4K output is NOT a4K background texture. Camera size22m and45° are candidate experiment settings. Finite source extent, fixed view direction, baked environment light/shadows and diagnostic non-SPEAR characters are explicit limitations. Rotation and dynamic environment lighting are unsupported here; no existing game capability is disabled elsewhere. Source18 remains ART_FAIL_WIP. Actual Mac host is not the owner's M5.

Source provenance: owner-authorized AI target edited using built-in image_gen. Prompt versions and SHA recorded. Generated image is only a material, never itself gameplay evidence. Original source at this experiment's authoring workspace remains preserved. Actor18 is the existing project's verified14MB embedded-resource GLB; source-specific notice travels with this project.

## First actual GPU run, retained failure

Run43688703476 at d161f76f imported the exact actor and rendered75 actual frames on hosted Mac ANGLE Metal/Apple Paravirtual GPU. The OS presentation window clamped to1024×645, so the strict requested2560×1440 gate FAILED;4K and traversal were not executed. These are not2K frames. Real combat produced29 hits and4 casualties at111 ticks; the hero died after only2/6 route points. The environment plate cannot pass traversal/occlusion from this alone. Subsequent capture explicitly fixes the GPU render target at2K/4K and separately records the smaller native window. Environment source remains1672×941. Wall-time timestamps now read monotonic engine ticks directly, not a sum of frame delta. The first UAL notice transmitted with normalized newlines; its original CRLF bytes are restored and all13 license hashes are now verified before import.

Viewport semantics: https://docs.godotengine.org/en/4.6/classes/class_window.html#class-window-property-content-scale-mode . This is native-resolution GPU viewport evidence shown in a smaller window, not a claim that the hosted desktop itself is4K.
