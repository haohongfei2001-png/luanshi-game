# Complete gate portal recovery, not art acceptance

Restores the already authored, uncommitted portal-03 structure rather than restarting its work. The prior 4bbc scene has a rectangular door below a curved opening and the original authored solid orientation problem. The restored complete portal uses 26 individual curved-top boards in two leaves, rear stiles/ledges/diagonal braces, functional fixed/leaf hinge parts, 11 depth courses of 17 radial arch stones, and continuous masonry-to-joist bearing at 5.69m. Door and every movable leaf part stay under the HP-controlled pivot at (48,0,0). The 8m opening and 7.4m bridge roadway remain unobstructed; no raised gameplay threshold. The upper hall floor is 5.93m with adult 2.20m clear column height.

Two diagnosed derivation errors are additionally addressed: the large native 71-sided roof polygon is tessellated in original mesh-local space before world conversion, clipping and extension; original corner UV/normal indices are retained. Material projection picks the lowest axis within 1e-5 of the largest absolute normal component, avoiding a 90-degree wood-grain change under the exact pinned local/CI normal perturbations. The professional UVMap is untouched; this changes only the separate metre material channel. This is a candidate deterministic production fix, not a claim that a second hosted build has already matched bytes.

No lighting/exposure adjustment hides these changes. Native CC0 VVayToyek structure and Poly Haven wood/stone surfaces retain their original source/license records. Structure mother file remains editable, runtime batches remain separate, and the old 01/02/03 failed trials are preserved. Source mesh has 1,379 editable parts / 336,740 triangles before runtime batching, not a GPU draw-call count or performance result.

Verified locally with Blender 4.3.2 and official Godot 4.6.3 7d41c59c4:
- Four projection fixture tests and two authored-solid unit tests passed.
- 770 authored closed solids and 139 top-face checks passed after modifiers. Professional open surfaces are excluded deliberately, not silently repaired.
- 15 gate-opening / 12 walkway / 14 facade-bearing rays passed; 864 new spandrel UV triangles are nondegenerate. Contact checks show zero masonry/joist gap at the specified four bearing interfaces. These checks are not global collision or penetration proof.
- Original roof-band seam thresholds are unchanged: worst gap 0.779717mm, worst matched corner-normal angle 5.184024 degrees; six sampled join families pass. This is not visually seamless acceptance.
- Actual headless game HP 260/130/0/260 gives visible true/true/false/true and displacement 0/-0.225/-0.45/0. Surrounding buildings, ram, sun and simulation are unchanged;20v20,tick0. This is not a full siege playthrough.

## Next actual step

Integrate the exact new GLB with the independently verified new terrain recipe and capture real native 2K/4K using the current MOBA/body-preserving camera. The offline portal image is model inspection ONLY. It cannot replace the requested actual whole-game image. All art remains NOT_ACCEPTED; M5 not run; no performance/whole-army/official release claim. Main/default/RC24/RC25 unchanged.

## Reproduction

Use existing verified professional input and `source/wooden_pier` as in the complete-region workflow. Material originals and hashes are in `surface-sources.json`.

```sh
blender -b --factory-startup --disable-autoexec --python-exit-code 1 -t 2 --python tools/art/gate_structure/build_architecture.py -- assets/river_pass/pavilion/pavilion-source.fbx "$OUT" --no-preview --native-roof-band --complete-gate-masonry --complete-portal --surface-root "$SURFACES"
# Run each audit with "$OUT/source/architecture.blend" and its JSON output:
# audit_authored_solids.py, audit_gate_bearing.py, audit_portal_interfaces.py, audit_roof_band.py
LUANSHI_GATE_CONTRACT_GLB="$OUT/architecture.glb" godot --headless --path . --script tests/authored_gate_gameplay_contract.gd
```

## Material-compatible runtime 07: actual primary UV and original AO

Further verification found that a correct glTF `texCoord:1` declaration was insufficient: the official Godot 4.6.3 StandardMaterial3D importer loads TEXCOORD_0/1 into UV/UV2 but ignores per-texture `texCoord` for the PBR channels. Actual imported AO was enabled but `ao_on_uv2=false`. Earlier metre UV in channel1 therefore was not proven to be what the material sampled. Official source inspected: https://raw.githubusercontent.com/godotengine/godot/4.6.3-stable/modules/gltf/gltf_document.cpp , material import and texture attribute decode sections. This is not a renderer-performance claim.

Runtime export is now a reusable step after saving the unchanged editable mother. It promotes intended metre UV to primary `UVMap` BEFORE assembly merging, preserves original UV in `SourceUV_Original`, and points all PBR UV/normal-map nodes at primary UVMap. Native deck UV uses the same primary layer name. This matters: an initial per-object-only fix yielded duplicate timber materials using texCoord1 on joined bridge groups and was rejected. That failed 06 derivative is retained. The final 07 has exactly three masonry/timber/timber_cut materials whose normal/baseColor/roughness/AO all specify primary UV, including both bridge batches. Actual Godot import checks confirm primary and preserved source arrays present, source AO enabled on primary UV/red channel and normal/roughness intact.

Original hash-locked Poly Haven AO now goes to Blender's official `glTF Material Output` / `Occlusion` socket with Non-Color sampling. It is source material micro-occlusion, not architecture-to-ground contact shadow and not a substitute for SSAO. Albedo is byte-identical to 04, roughness green-channel bytes are identical, original normal pixels/strength are preserved. No multiplying AO into albedo, baked lighting, exposure compensation or made-up dirt. Exported red-channel ranges are masonry111..255 and timber5..255, not an empty white placeholder. Final native GPU appearance still PENDING. The required next step remains real whole-scene images, not an offline preview or this material test.

The reusable exporter can rebuild runtime from the preserved mother without rebaking geometry. Full production builder calls the same function. Local final GLB/import/HP receipts are in `material-*`; this runtime supersedes the previous local04 artifact for next integration. Blender reports unavailable optional Draco and combined ORM sampler warnings; Draco was not requested/used, and all source images use matching repeat/filter settings. Do not label Blender logs completely warning-free. Main/default/RC unchanged.

Final import gate also inspects actual `GLTFState.json` texture declarations; AO-on-primary after an importer ignores a bad texCoord declaration is NOT sufficient. The preserved bad05 asset is actually rejected with exit1 (`PBR texture declaration not supported primary UV: masonry`), while final07 exits0 with all three actual materials checked. No asset or production code changes in this gate addition.
