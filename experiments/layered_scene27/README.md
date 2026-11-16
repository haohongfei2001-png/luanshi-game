# Bounded layered-scene27 projection experiment

**DEFAULT OFF / ART NOT ACCEPTED / NOT A PLAYABLE GAME.**

These are the exact two shader sources executed in the isolated27B Godot
experiment, plus a pure-Python interpolation reference and regression tests.
They are not installed in Battle, do not change assets/saves/combat, and do not
demonstrate that a single generated image can replace the complete3D world.

## Source vs render distinction

The actual experiment used a declared AI-generated1672x941 environment image
and eight independent existing3D control actors. Native EGL framebuffer was
2560x1440, internal scale1. This repository subdirectory contains **no generated
environment bitmap, character model, engine binary or completed scene**. The
provenance/evidence hashes identify the retained experiment, not public download
locations or a claim that its dependency closure is in this directory.

## Verified scope

Godot4.6.3 custom EGL/llvmpipe ran27B on2026-11-15T22:43:47Z–22:44:31Z,
43.387s/exit0. Three frames were captured. Eight actual input frames moved one
actor2.77333355m; physicalW/D both released, followed by one full frame with
zero further movement. This was automated input, not a human playthrough,
normal-speed video or performance benchmark. Real MacBook Air M5: NOT_TESTED.

The fixed capture matrix is `capture_camera_projection * inverse_capture_view`.
The vertex shader carries homogeneous capture coordinates. The fragment divides
by the interpolated capturew; ordinary perspective-interpolated imageUV is not
equivalent on a noncoplanar/sloping proxy. Keep the source matrix fixed when the
view camera changes. Using SCREEN_UV would hide rather than solve misregistration.

The ground shader uses already-lit source radiance and a stylized attenuation
floor. It is **not** a physical albedo material or dynamically relit environment.
Godot's light output is multiplied by ALBEDO by the renderer; multiplying again
inside `light()` caused27A's rejected whole-frame darkening. Contact shadows
still need an actual shadow-on/off image difference test and visual acceptance.

## Important negative result

The real0.5000003m camera-offset frame shows wall/rail/door discontinuities.
The experiment used a flat ground receiver and incomplete front-rail geometry,
not correct landscape/building depth. It therefore **fails free-camera use**.
These mapping fixes do not make that geometry correct or reconstruct hidden
surfaces.27C must test coherent bridge/ground/gate geometry and real openings;
camera freedom, dynamicwater/lighting, full Battle and army performance remain
unverified. The entire character control also remains ART_FAIL.

## Run the dependency-free regression tests

```sh
python3 -m unittest discover -s experiments/layered_scene27/tests -v
```

Tests cover200 deterministic random triangles, top-left image convention,
naiveUV failure, independent view/capture matrices, invalid inputs and shader
source invariants. They are mathematical/source tests, not GPU visual evidence.

## Exact retained evidence identifiers

- Input image SHA256: `882c8d56fa3f78ca0120b9e0d6410e64dab10d8b3a19e2e3b03eb83d4ab6cec6`.
- Control actorGLB SHA256: `1c3cee3583e02e7cd4cabeadf4ff6bb433c6adc94f56be276242dedd4bc4689a`.
- Actual after-motionPNG SHA256: `772e9fffab63fc475b69aa3fb4041801e31879858039a05e38f5927bcb18b639`.
- Actual side-cameraPNG SHA256: `49774327dfc3c57d472ef5a46dbc9150cf3c5578cae9967745835a3eb5c2f730`.
- Exact engineSHA256: `0ff65b61f7332db602ba6305f8f16c14716d96c036fce72fe8a4aae1bdb6bf0a`.

No copyrighted game imagery, restricted asset source, account information or
credential is included. This is original project code; reference:
[Godot spatial light shaders](https://docs.godotengine.org/en/4.6/tutorials/shaders/shader_reference/spatial_shader.html).


##27F retained negative experiment: source-centre depth consistency

The additional `center_aligned_capture.gdshader` is byte-identical to the shader
actually executed in reconstructed27F, not a newly validated generic renderer.
Its RF owner/depth textures use the exact1672x941 source capture. Depth is
recomputed by ray/plane intersection at that **same nearest texel centre**.
Comparing continuous fragment depth with texel-centre depth produced false gaps
on slopes; simply increasing the0.02m tolerance would conceal wrong surfaces.
The threshold and purple/orange unknown/invalid diagnostics remain unchanged.

`capture_depth_reference.py` adds a standard-library mathematical reference and
six tests, including1,800 perspective-depth cases, top-left/Y/sample conventions,
parallel/behind-ray handling and the incorrect continuous-depth comparison.
Together with the seven original tests,13 tests pass. The old shader invariant
assertion was amended to recognize a consistently divided homogeneous varying
by either name, rather than requiring one literal identifier. This is not a
weakened perspective/divide assertion or aGPU pixel-parity claim.

Reconstructed27F's actual three2560x1440/internal1 captures ran33.752s/exit0,
peakRSS1,174,478,848B with exact engineSHA already pinned above. Horizontal
visibility stripes disappeared. **The whole scene still FAILS:** thick canopy
shells reveal unsupported sides, gate eaves/background assignments tear on
half-metre camera translation, pier/water contact is wrong, and the independently
textured rear court does not match source lighting/space. The near-left willow
is absent. Surface queries are not physics traversal, input or combat.

Normal PNG SHA256: `8a87f1f3f1b2bface167be11e340e0a6f756a316330e616a08d0f951ecc7480b`.
Half-metre PNG: `049cba2eca29b8a2779b05240362388fec55c1d7553a4362b152b693f0b1fc82`.
Gate-query PNG: `778d9249ca81ce5ade25431a46ad976d8cd4933ff932bc8a731a479a5b06cd09`.
Large original PNG display exceeded review-tool output limits; visual review used
explicitly labelled same-pixel JPEG derivatives, while originals/hashes remain.

**Method boundary:** a single whole generated image cannot supply new near-field
surfaces uncovered by player/camera motion. These code fixes are retained as
negative-experiment recovery, not the main art production route. Near-field
bridge/rails/gate/tunnel/court require complete geometry, independent materials
and coherent lighting; layered imagery may be assessed for unreachable distance.
No default-game/Battle integration, new accepted art, full action film, army
benchmark, native4K trial or actualMacBookAirM5 test is supplied here.
