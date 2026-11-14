# Intact source rig: opt-in batched rendering experiment

This is NOT shipping character art, not a Chinese costume, not a full-battle
performance pass, and not yet a GPU parity pass. Default gameplay is unchanged.

## Why a separate weight texture

The real UBC eye and eyebrow meshes have authored custom UV attributes in
CUSTOM0. The original custom-channel adapter correctly rejects these; overwriting
that channel would lose the author's data. A separate static float texture now
retains every vertex attribute, original LOD index buffer/distance, and up to
16 explicit source influences per vertex. Nine, twelve and sixteen influences
and joint index 299 are covered by synthetic tests. Unknown expression rigs,
invalid weight sums, or more than 16 influences are rejected, not silently cut.
A future MakeHuman source with >8 weights MUST provide exact imported vertex
mapping; this UBC fixture does NOT prove that future mapping.

Actual UBC source: 65 original bones, 8,483 vertices in 3 original meshes,
18 original imported LOD levels, extra UVs, 9 clips sampled at 36 exact phases.
`intact_native_palette.gd`: 68,047 assertions, zero failures. CPU palette
roundtrip matched direct native-bone linear blending exactly in float32.
`intact_weight_texture.gd`: 125 assertions, zero failures, including 32-bit LOD
index retention, 9/12/16 complete influences, custom-channel retention, and
rejection rather than loss of an unsupported transparent material.

Headless Godot has no valid RenderingServer skeleton RID. The native engine
`bake_mesh_from_current_skeleton_pose` comparison is therefore NOT_RUN locally;
the test explicitly labels its direct CPU blend reference. Actual GPU validation
is required for VERTEX_ID, LOD drawing, normal/tangent basis, and material parity.

The material adapter intentionally accepts only the original opaque two-sided
UBC features present here: vertex color, base color, normal, roughness, metallic
and their original textures/channel selectors. Unsupported non-default material
features are rejected. The GPU test compares native StandardMaterial3D/Skin
against the isolated batched implementation in four exact poses. It does not
approximate or accept gameplay attacks, locomotion, interpolation or ground
contact. Source optimized shadow meshes are not transferred; this is reported,
and full shadow/performance regression remains pending.

## Reproduce

    ./tools/prepare-font.sh
    godot --headless --editor --path . --import
    godot --headless --path . --script tests/intact_weight_texture.gd
    godot --headless --path . --script tests/intact_native_palette.gd
    # Requires actual graphics, not a headless dummy:
    godot --path . --script tests/intact_native_gpu.gd

Source UBC and UAL licenses remain attached to `assets/ubc_lab/source`.
MakeHuman, costumes and future action libraries are NOT included here.
