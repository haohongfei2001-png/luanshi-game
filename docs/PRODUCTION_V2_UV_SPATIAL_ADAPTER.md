# Isolated source18 per-texture UV adapter, default OFF

Frozen source18 GLB/geometry/skin/animations/images remain unchanged. This experiment
reuses the original Texture2D resources and applies two shared ShaderMaterials to
only the eighteen confirmed UV-mismatched surfaces. It does not enlarge images,
change colors/lights, touch other materials, alter Battle, or fix the GLES native
Skin tangent engine bug. GPU/backend and art acceptance are pending.

## Exact integration closure

Copy these three resources at their original project paths:
- `scripts/field/experimental/production_v2/uv_spatial/adapter.gd`
- `scripts/field/experimental/production_v2/uv_spatial/source18.gdshader`
- `scripts/field/experimental/production_v2/uv_spatial/source18_contract.json`

The2285-byte sidecar has SHA256
`6e499e13a720acdebfab6bad834d2a79d5971a3f51735f7d2cd7ccba292d83c7`.
It was extracted by `tools/art/mh_spear_v2/uv_audit/extract_shader_contract.py`
from exact GLB SHA256 `afb966396bf5ad656b3cb0cd2edc388fc6fa02eba59df8b81d9a23ac53f3be8b`.
PCKs need only this tiny sidecar plus the existing imported character resources,
not an extra raw14MB GLB. Runtime verifies the sidecar bytes; preparation/import
must continue to verify the original GLB source SHA. This is explicitly not a
claim that runtime read original GLB bytes after export remapping.

One adapter instance can serve all already-instantiated source18 actors:
```gdscript
var adapter = preload("res://scripts/field/experimental/production_v2/uv_spatial/adapter.gd").new()
var err = adapter.configure_contract("res://scripts/field/experimental/production_v2/uv_spatial/source18_contract.json")
if err != OK:
    push_error("Source18 material contract rejected")
    return
# Default OFF. For the explicit ON control only:
var receipt = adapter.apply(skeletal_actor, true)
if not receipt.get("applied", false) or receipt.get("surfaces", 0) != 18:
    push_error("Source18 material adaptation rejected")
    return
# After control capture, restore exact original shared material objects:
var restored = adapter.restore(skeletal_actor)
if restored != 18:
    push_error("Source18 material restore count mismatch")
    return
```
`apply(actor)` without true makes no changes; it does not implicitly undo a previous
ON call. Use `restore` for that. Reapplication onto existing overrides is rejected.
Validate every receipt and count. Failed validation is atomic before overrides.
Do not mark default gameplay or the army approved from this test.

## Preserved semantics and refusal boundary

Each base/normal/ORM texture has its own UV index, scale, rotation and offset.
UV indices0/1/2 read UV/UV2/CUSTOM0.xy respectively. `CUSTOM0` is passed from vertex
to fragment without modifying positions, normals, tangents or bone processing.
Base texture uses `source_color`; glTF base factors are already linear and are
NOT converted a second time. Normal and ORM remain linear, with original normal
scale, metallic factor, roughness factor and source channels. Source materials
are opaque/double-sided, Burley/Schlick-GGX, default depth, original repeat and
trilinear filtering; no ALPHA is written and no fictitious AO from ORM.R is added.
The unchanged eyebrows/eyes transparency and all unrelated materials stay intact.

This is deliberately not a general-purpose GLTF renderer. Only the frozen two
material descriptions are allowed. Nonopaque alpha, additional glTF fields or
extensions, emissive/AO/other features, changed sampler, render flags, nondefault
PBR modes, altered factors, existing overrides, missing UV/custom/texture data or
unexpected surface counts fail closed. Original Mesh materials and textures are
not mutated or duplicated. Shared shader material caching is by original material
identity; per-instance Skeleton/AnimationPlayer/binding remain independent.

## Actual tests and limitations

Godot4.6.3 headless compiled the shader front-end with22 uniforms. Eleven actual
foot-SPEAR Units from a real legacy Battle ran80 ticks with11 independent imported
source18 skeleton/bindings,198 adapted surfaces and only2 shared ShaderMaterials.
Unrelated materials, shared meshes/textures and simulation state were unchanged;
all198 overrides restored to original materials. Unsupported alpha/emission
contracts were rejected. This is not an HF08 Controller/GPU test.

Actual imported CUSTOM0.xy matches GLTF TEXCOORD_2 with max4.67e-15 error.
Independent GLTF expected sampling versus1253 adapter channel-coordinate samples:
max UV difference5.96e-8, max linear base/normal/ORM base-level sample difference
3.50e-6. No texture enlargement, new GLB, render or CI was performed. CPU raw-image
sampling does not prove hardware texture compression, mip behavior or final pixels.
See `docs/evidence/production-v2-uv-contract/spatial-adapter-receipt.json`.

Next gate: HF08 same Metal engine, tick, camera, pose, lights and actual roster,
OFF/ON native2K stills with only this material override changed. Restore materials
before the existing action run. Verify actual GPU compilation, source-color/PBR,
normal direction and shadows. No visual approval or whole-army deployment before
that evidence is reviewed.

## Godot 4.6.3 backface and normal decoding audit

Do not put configuration, apply, or restore calls inside `assert`: release builds
remove assert expressions. The example above executes and checks them explicitly.

The official `4.6.3-stable` source confirms that `cull_disabled` emits
`DO_SIDE_CHECK` for both StandardMaterial-generated and custom spatial shaders.
The renderer flips only interpolated NORMAL on backfaces before fragment code;
TANGENT and BINORMAL are not flipped. Adding our own FRONT_FACING flip would
therefore double-flip and be wrong. No manual flip was added.

StandardMaterial uses `hint_roughness_normal`, not just `hint_normal`. This adapter
now matches that hint exactly. Both hints use the same normal fallback and normal
texture detection; the roughness variant also participates in tools-only normal /
roughness import association. Existing imported textures remain the same objects.
Both material paths assign sampled RGB to NORMAL_MAP and normal scale to
NORMAL_MAP_DEPTH. The shared renderer remaps RG to [-1,1], reconstructs positive Z
with sqrt(max(0,1-dot(RG,RG))), then normalizes the depth-mixed TBN result. Thus it
ignores sampled B for RG-packed textures identically. No custom unpacking or
additional sRGB conversion is introduced. This is source-level equivalence,
not a GPU pixel/compression or art acceptance result.

Exact official references:
- [Standard material generation](https://github.com/godotengine/godot/blob/4.6.3-stable/scene/resources/material.cpp): lines 814-823, 1090-1095, 1745-1754.
- [Mobile compiler](https://github.com/godotengine/godot/blob/4.6.3-stable/servers/rendering/renderer_rd/forward_mobile/scene_shader_forward_mobile.cpp): lines 789-790.
- [Mobile renderer](https://github.com/godotengine/godot/blob/4.6.3-stable/servers/rendering/renderer_rd/shaders/forward_mobile/scene_forward_mobile.glsl): lines 1171-1186, 1410-1415.
- [GLES compiler / texture hints](https://github.com/godotengine/godot/blob/4.6.3-stable/drivers/gles3/storage/material_storage.cpp): lines 946-951, 1035-1039, 1393-1394.
- [GLES renderer](https://github.com/godotengine/godot/blob/4.6.3-stable/drivers/gles3/shaders/scene.glsl): lines 2050-2057, 2159-2164.
