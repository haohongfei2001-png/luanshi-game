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

## Hosted renderer reference correction

Run 43611350338 passed CPU structure checks but failed raw bake comparison by
77.161 micrometres. Godot 4.6.3 `scene/3d/mesh_instance_3d.cpp` CPU bake starts
from source and accumulates `source.lerp(Tsource,w)-source`; GLES3
`drivers/gles3/shaders/skeleton.glsl` sums weighted matrices directly. With
source UNORM16 weights not summing exactly to one, these are distinct. The test
now preserves raw bake error and checks the exact predicted CPU bake
`palette_p + source_vertex*(1-sumWeights)` at the unchanged 2e-5 m threshold.
No source weights, palette or shader are normalized or altered by this fix.
The independent actual renderer 2-level/2-percent pixel gate remains mandatory.
Source: https://github.com/godotengine/godot/blob/4.6.3-stable/scene/3d/mesh_instance_3d.cpp
and https://github.com/godotengine/godot/blob/4.6.3-stable/drivers/gles3/shaders/skeleton.glsl


## MH163 full-weight bridge, separately verified CPU prototype

`full_source_weights.gd` requires the v2 normalized-runtime sidecar and exact
UV2 source IDs supplied by the frozen MH production mother. It maps author bone
names to actual Skin bind slots, never assumes skeleton/bind order. Original
UV0, all native indices and rest positions are checked. Every declared runtime
weight must equal its retained raw transferred Blender group times the explicit
recorded normalization factor. No normalization or tail removal happens inside
the adapter. Raw transferred groups are NOT original author skin weights: the
initial clothing transfer clipped signed proxy weights in the wrong order;
the v2 sidecar explicitly records the correction rather than blaming the author.

On the frozen 7-mesh source (20,159 rendered seam-split vertices), 173,163
assertions passed. All 33 rendered vertices having 9 source influences retain
their tail: body14, robe11, boots2, trousers6. Rest deformation error is at most
0.956 micrometres. Exact GLB and v2 sidecar hashes are in `mh-full-source.json`.
The source GLB exporter omits tiny influences at 38 original source vertices;
that GLB/native8 output is NOT treated as a complete weight reference. The full
explicit normalized sidecar is retained instead.

The artwork remains rejected as a whole. This CPU/data result says nothing about
Chinese soldier quality, garment deformations, native GPU material parity, or
full-battle performance. Source Mother binaries are intentionally not included
in this code-only commit. Reproduce the licensed mother via the MH production
branch's pinned-source scripts, then run:

    MH_WEIGHT_FIXTURE=res://assets/mh_lab godot --headless --path . --script tests/mh_complete_weights.gd


## Independent complete-weight pose oracle (diagnostic only)

`full_weight_reference.gd` is a deliberately slow CPU oracle, not a shipping
renderer. It deforms position/normal/tangent using every explicit source
influence, retains tangent handedness, original UV/custom channels, topology,
LOD indices and material references, and removes Skin attributes from the posed
copy to prevent double skinning. It does not guess an eight-slot approximation.
The eighteen fixed-value unit checks include a nonzero ninth influence at bind
299, preserved LODs, invalid sums/negative weights, and refusing >16 influences.

The frozen animated MH source `b735dc82ca668bf2417ce4ad6bd68aa0005a9188c7cbb5eec23f15711eb20f11`
and explicit sidecar `8a580adf35abee5cc661d15a24f3f77d304c2f28ae78057edc50edc59d9093db`
were actually sampled in nine imported Godot clips at three phases each.
549,063 data assertions passed, zero failed: every sample retained all 20,159
rendered vertices and all 33 >8-influence vertices; input files/arrays and
original non-deforming attributes/material references were unchanged.
`mh-full-pose-reference.json` contains all 27 per-part posed bounds. These are
finite-data and preservation tests, NOT valid foot contacts, weapon contacts,
visual parity or performance tests. The first local test correctly failed when
it requested GLTF names ending `_Loop`; Godot import strips that suffix. The
rerun uses the actual imported names listed in the report, not skipped clips.

Important source audit correction: this frozen fixture's 163 joints/weights are
intact, but the production audit subsequently found its generated bone roll
uses a different local-axis convention from the original MakeHuman default.
Therefore these tests prove internal consistency for the exact frozen fixture,
NOT original-author rest-axis fidelity. An independently corrected mother must
be retested under its own hashes. The frozen fixture is neither shipping nor
art-approved, and no default gameplay path calls this reference implementation.

    godot --headless --path . --script tests/full_weight_reference_unit.gd
    MH_WEIGHT_FIXTURE=res://assets/mh_lab godot --headless --path . --script tests/mh_full_pose_reference.gd
