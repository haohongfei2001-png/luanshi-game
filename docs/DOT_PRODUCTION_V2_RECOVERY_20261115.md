# Dot whole-scene production-v2 recovery — 2026-11-15 UTC

**State: ART_REBUILD_REQUIRED. No production-v2 playable art candidate has passed. This is a recovery checkpoint, not a release or acceptance report.**

**Read section 9 first for the latest verified continuation. Earlier source tables and results are preserved checkpoints, not instructions to revert later work.**

This checkpoint supersedes the *next-art-action* recommendations in the older regional 04/05/06/07 experiments. It preserves their source and evidence. Read the current main `AGENTS.md`, `OWNER_MOBA_CAMERA_AND_ART_AUTHORITY_20261114.md`, the owner's latest matte-material authority in draft PR #67, the original Dot handoff, and Issue #12 together with this file. Codex remains **PAUSED**; Dot continues the authorized cloud development.

> Sections 7 and 8 are earlier checkpoints. They remain preserved, but their in-progress statements must not override section 9.

## 1. The owner's correction and the actual method change

The owner rejected the **entire** image: people, environment, buildings, materials, lighting and composition. The concept/reference is a minimum quality line, not proof that the game is close. Do not keep polishing the old rough terrain or geometry, shrink people to frame a whole army, or treat test counts and partial model changes as art progress.

The first production-v2 whole-scene authoring previews were also self-rejected. In particular, the terrain003 ground still used interpolated vertex colors with only a small multiplicative contribution from baked professional ground color. Replacing the bridge and trees did not make that a mature whole landscape. This method, including its pending variant, was stopped before a new visual GPU run.

The active reconstruction now requires:
- One coherent **editable mother scene**, with the full terrain, banks, bridge, fortress, background and ecology authored together. Derive visible geometry, walkable surfaces, actual obstacles, portals, deployment areas and semantic objectives from that same source. Do not force a mature scene back into the old global `Ground` coordinate boxes.
- Use genuinely mature ground/rock/vegetation forms and coherent full material systems as production inputs, with documented adaptation and baking, not a token color overlay. Build one authored battlefield from the approved visual reference; a ready-made film/demo set is not required. Do not remain loyal to an unsuitable source's style or compose unrelated parts randomly. Original assets and licensing are inputs, never a quality certificate.
- Rebuild the fortress as a coherent structure with legible stone/earth, timber and tile hierarchy and clean normal-camera lighting. A bridge/door clearance test does not accept its appearance.
- Build one complete natural adult infantry model from a full body, full garment topology and full rig. Adapt the whole military silhouette and coherent armor/cloth/leather materials; do not return to floating plate piles, barrel skirts or a professional head attached to an unrelated body.
- Establish readable idle, walking, held spear, attack, hit and death in that same real battle, then propagate to troop types and scale. An isolated static sprite or Blender beauty render cannot fulfill this.
- Ordinary spears need no red tassel. The white-robed/white-horse hero remains a direction, not an approved fixed story character. Formal literature stays blank.

Wild Rift is the primary **visual camera reference**, not a source of reusable game assets or published camera constants. The user's accepted whole-scene matte direction and ordinary-spearman reference govern the visual target. Normal gameplay pixels must show hands, weapon, armor, direction and action without oily darkness, noisy grit or painterly smearing. Shared 3D, multidirectional sprites and hybrids remain available approaches.

## 2. Source state verified at this checkpoint

All entries below are independent experimental branches, not a new main candidate. Re-read remote refs before resuming; do not overwrite later work.

| Purpose | Branch | Verified source/ref |
|---|---|---|
| Current main | `main` | `248d26aefbb8dfe7973141a63b40f3a220f0edc0` |
| Owner matte authority, still draft | `dot/owner-matte-material-authority`, PR #67 | `1cfda095b05a78dfe89da6f2ddd8f8cb89819180` |
| Per-Battle map identity/runtime | `dot/production-v2-map-runtime` | `d559a0776ace57742605f7290418d4933591319e` |
| Complete bridge/fortress mother collection | `dot/production-v2-gateway` | `66c3bf79f7870b413061eb969aeb737d6dd9db45` |
| Natural-body full coat fit and runtime LOD source | `dot/soldier-production-v2` | `120cc87a40d680915fba6ec792d156a5467f4f49` |
| Completed representation repeat evidence | `dot/representation-metal-repeat` | `8180cc273cfb78df4acf0df76220b15e2a3badfb` |
| Preserved rejected regional06 source | `archive/rejected-regional06-art-fail` | `0626c3b5781e1b4a0f3f618bdf95842817afa881` |

The complete new landscape and further runtime/armor/action changes still have local work in progress. They are **not** implied to be in the table's published commits. No production-v2 GPU image, full player-controlled battle or new macOS candidate exists at this checkpoint. No merge/promotion is implied by this document.

Protected recovery points:
- RC24: `4f3c0819cf44a89c24bd825c90f241d8974fbbb6`.
- RC25 / draft PR #59: `d1c1895221c33386d471922807ed590a6987dbe1`.
- Preserve all existing source, evidence, packages and old saves.

## 3. What the new components have actually established

### Environment and architecture
The new layout has enough planned space for both armies and does not require squeezing the entire scene into the normal camera. Current authoring bounds are approximately 140 by 112 metres, with the main bridge around 14 metres long and 7.2 metres clear width. The new entrance is a real opening, with separate gate-leaf blocking, turning defenses, courtyard and retreat route. These are authoring constraints, not fixed final art or a capacity result.

The complete architecture source has been rebuilt as one collection, imported in actual Godot, and checked at door/bridge/head-clearance samples. Its actual solid/support/walk/door contract has been consumed by the new map adapter. Early architecture errors and whole-scene failures are preserved. **Appearance is still under reconstruction.**

The first terrain and buildings can supply real support triangles, obstacles and route tests. Candidate spawn counts before the final scenery and solids are deducted must not be advertised as a passed 512-per-side muster. Environment collision preflight is not new gameplay acceptance.

### Map and old-save boundary
The new identity is per Battle, not a global `Ground` switch. Lock save compatibility by `map_id`, `topology_revision` and `topology_sha256`. Keep `visual_revision` and source SHA as separate provenance, so a material-only revision does not destroy save compatibility.

Missing-map-identity old saves retain their exact legacy map. Unknown new topology is rejected without mutating the input. Do not silently relocate units, reset history or claim v4/v5 ambiguity is migration. Real Godot identity, support-layer, roof/non-floor, catalog isolation and legacy snapshot tests have run.

Further local integration has verified the actual `Battle._move` adapter against the original in eight cases: both legacy maps at 20/100/250/512 ordinary soldiers per side, exact complete final snapshots including combat, losses and RNG. The 100-per-side field case naturally ended at tick 340; others reached 400. This is old-system preservation, **not a new-map combat pass**. These later changes must be published and rechecked before reuse.

The first new-map internal battle must retain real weapons, HP, casualties, orders and formation counts. Modes still tied to old traffic/siege/objective coordinates must be explicitly unsupported until semantically adapted, not secretly run against legacy coordinates. New-map siege/world writeback and the complete Controller/Battle path remain unfinished.

### Complete soldier and action source
The new natural MH163 body retains the complete rig and original usable actions. A full professional coat was fitted and visually inspected; the first armpit-breaking fit was rejected. Runtime derivation reduced the coat from 49,578 to 7,436 triangles and baked a genuine 2048-square tangent normal from the original high-poly folds. That proves a production path, not a finished soldier.

The first full armor/short-skirt/helmet version was also rejected for silhouette and fit problems. No unreviewed outfit is being propagated into the army. New full-body two-hand spear motion exists as an internal draft; elbow/wrist problems caused its rejection and rework. It is not a verified replacement for all spear actions.

## 4. Last actual game evidence is still the rejected old scene

The latest completed whole-game visual run remains [43652380636](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43652380636), source `93ee66b1418f6c6af818c59ddf63c0bb7788c7b0`, completed 2026-11-14 at 23:22 UTC. It produced actual native 2560×1440 and 3840×2160 frames and an approximately 18-second original-speed recording on hosted Apple M1 Virtual / Metal Mobile. It is **not production-v2 and not MacBook Air M5**.

Its terrain, dark structure, old people/horses and overall image remain rejected. Video encoding/check completion is separate from art approval. The observed player sequence had no successful hit and no new authored walking. Do not call it a verified combat action showcase.

A subsequent CPU-only real-Controller diagnosis showed the automated premature guard input blocked the intended attack, followed by stagger/death. Removing only that input produced one real spear hit and natural player death without changing HP, enemy position or damage. This explains one evidence failure; it is **not** new visual proof or a successful mission.

## 5. Preserve the sprite performance counterevidence

The same-source 3D/sprite controls are unclothed UBC technical models, not the accepted Chinese troops.

The initial 100/250/512 contact-scale matrix and the [512 ABBA repeat](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43654648297) must be read together. The repeat used source `2849d32c3415e1e50b56adc9e97f3e95804fc9e6`, identical real-Battle/camera hashes, native 2K, no frame readback in the timed 16-second intervals, and order sprite / 3D / 3D / sprite.

| Mode in observed order | Average FPS | P95 ms | P99 ms |
|---|---:|---:|---:|
| Sprite | 79.81 | 25.642 | 35.587 |
| Shared 3D | 46.42 | 31.129 | 45.902 |
| Shared 3D | 47.89 | 26.763 | 37.728 |
| Sprite | 82.53 | 23.374 | 27.758 |

The earlier roughly 51 FPS sprite sample was not stable enough to conclude that sprites offered no benefit. Conversely, this repeat does not establish visual acceptance, a final rendering route, M5 performance, or 1,024 simultaneously visible bodies. There were 512 real ordinary soldiers per side; actual alive on-screen centers ranged from 78 to 205 during the selected contact window. Cloud timing variability and substantial current atlas memory remain explicit. No further broad technical matrix should displace whole-scene/character production.

## 6. Resume without duplicate writers or false passes

```sh
git ls-remote origin refs/heads/main \
  refs/heads/dot/production-v2-map-runtime \
  refs/heads/dot/production-v2-gateway \
  refs/heads/dot/soldier-production-v2 \
  refs/heads/dot/representation-metal-repeat

git fetch origin dot/production-v2-map-runtime \
  dot/production-v2-gateway dot/soldier-production-v2 \
  dot/representation-metal-repeat
```

Inspect the source branch's current README/tests and uncommitted work before editing; use separate worktrees for independently owned components. Do not reset another active producer's checkout.

Next deliverable is one coherent complete new environment plus complete soldier in an **actual player-controlled Godot battle**, self-reviewed against the owner references before mass rollout. Record fixed source SHA, true input/hits, original-speed footage, exact native and internal pixels, same-state comparison, hardware, frame intervals and memory. Then test 20/100/250/512 each side with real offscreen war. Keep installation/export, functional tests, art acceptance and device performance as separate verdicts.

No new spending, account creation, user-computer access, unlicensed public assets, formal plot or commercial release is authorized. Public redistributable sources retain attribution, original notices and modification records. Third-party reference game pictures are private study only. **M5 DEVICE_NOT_RUN. OWNER ART NOT_ACCEPTED.**


## 7. Verified continuation update — 2026-11-15, 00:47 UTC

The earlier source table is the 00:10 checkpoint, not an instruction to revert newer work. The following refs have subsequently been verified on the remote:

- Map runtime and real new-map CPU battles: `dot/production-v2-map-runtime@37f1dc992db4fe300e20f852583a4385a1978a26`.
- Whole fortress mass and one-parent placement interface: `dot/production-v2-fortress-mass@c54e9025a1d03fc0d58b627b7e249a5ff82a0ddc`. The older gateway branch remains frozen at 66c3bf79.
- Full long-uniform production code: `dot/soldier-production-v2@287de5008af5a7e5c952269b2536a5c4f2a758e7`.
- MH163 complete spear action/runtime code: `dot/mh-spear-production-v2@9ecbb4f2ffe7e9c0a6b507069893556093a8db17`.

### Actual new-map Battle, not new-map art

The terrain004 **functional preflight** topology now runs real Battle instances, explicitly with an initially open gate and no siege/ram/world-objective mode. It is not the final visual mother scene.

The first 20-per-side run moved troops but produced zero attacks. The cause was a real path-following error: the nearest first grid point pulled a soldier backward before it could cross to the next cell. Safe forward lookahead along the computed path fixed this without teleporting troops or ignoring barriers. A real movement loop then crossed the bridge and entered the gate in 422 steps.

The current 20-per-side volumetric-LOS run produced 111 attacks, hits 47/45 and ordinary losses 9/7. The earlier sampled-LOS run produced 117 attacks and different losses; both are preserved, and they are not claimed equivalent.

The actual 512-per-side run completed 400 ticks with 1,057 total entities including officers/player, 697 attacks, hits 109/213, ordinary losses 60/24 and two delivered orders. An independent read of the final roster confirmed exactly those 84 ordinary deaths plus three enemy officer deaths. All active units retained valid ground support and avoided authored static solids. This does **not** mean units never overlap each other.

The approximately 151.94-second instrumented total includes graph construction, a continuous movement probe, initial muster, simulation and checks. It is not GPU FPS or proof of real-time performance. The previous 300-second timeout is preserved. Actual method-level timing and optimization remain necessary.

An independent single-snapshot crowd review found a maximum of seven alive units in a one-metre grid cell and eight within a half-metre radius centered on an actual unit. With corpses included, the maximum one-metre cell held twelve. These numbers are not a continuous congestion or visual acceptance verdict. Do not impose one-person-per-cell physics or discard real casualties to fabricate a pass.

Final comparison of the Battle/officer/save adapter changes again matched all eight complete legacy Save snapshots byte-for-byte. The complete default `tools/test.sh` regression on source 37f1dc9 finished with exit 0, including the campaign/youth/world tests. Its log SHA-256 is `742cf57f7d07efd08f1fd183ea272f42d5ad02cd30d847b8c3cbb19fed5912d5`. The first attempt failed because a sparse worktree lacked unchanged tracked data files; that failure was retained and the original data restored before retry. A later authored-scene host fixture separately passes identity/light/semantic-door tests, but is not part of this published source or evidence of gameplay art.

### Whole environment restoration, not a new naked-tree candidate

A concrete source-compatibility failure was found: Blender 4.3 reads the old Sprite Fright canopy Geometry Nodes as `NodeUndefined`. Blender 3.2 removed that legacy node compatibility. Installing a newer version would not restore those original systems.

The official, independently prepared portable **Blender 3.1.2** has now run successfully:
- Linux archive: 187,294,308 bytes.
- Official SHA-256: `c1d345b25c6f83708b2681d354d70a3e6023c04bb73cc7943366c0c19e542958`.
- Official [archive](https://download.blender.org/release/Blender3.1/blender-3.1.2-linux-x64.tar.xz) and [checksum table](https://download.blender.org/release/Blender3.1/blender-3.1.2.sha256).
- Original 4.3 installation and source scenes remain unchanged. Disable embedded automatic scripts.

The same complete 535-object source set audited with **zero undefined nodes** in 3.1.2. The original full-density render was killed with signal 9/exit 137 before producing a picture; that failure remains recorded. A diagnostic original-whole-layout render then completed at 1280×720 in 63.90 seconds, with measured process peak RSS 7,063,856 KiB. It explicitly uses 20% tree/branch leaves, 0.5% ground micro-scatter, 2% child particles, subdivision at most one and no film micro-moss geometry. This is neither full-original-density proof nor game performance.

The restored complete image was personally inspected and **rejected as a direct battlefield mother scene**: hollow fairy-tree village forms, shell-like canopies, path occlusion and noisy moss do not meet the owner's clean natural military-world target. Restoring a professional source is useful compatibility work, not art acceptance. Preserve this source and findings, but do not continue forcing it onto the battlefield merely because of its film provenance. The final coherent scene is still not frozen or rendered in Godot.

### Complete character boundary

Actual Godot testing caught the source's 120-fps animation frames being exported from a 24-fps derived scene, slowing motion fivefold. The corrected import now measures Walk 1.333 seconds, ordinary spear thrust 0.7 seconds and death 2.4 seconds. The rejected timing receipts remain separate.

The local complete long-uniform11 derivative has 163 bones, 14 clips after spear merge, approximately 60,480 triangles and 28 surfaces across 14 materials. It is **not** a thousand-character renderer and has not passed art review. Clothing intersections, overly soft armor deformation and foam-like equipment appearance are still being rebuilt. The original full body remains intact; the outfit is not being propagated as an accepted army sample.

Top-eight-weight export is an explicitly lossy derived representation, not preserved original weights. For four actual POSE-state checks of this source, the measured maximum displacement was 1.543 mm and the tested 180-pixel neutral silhouette threshold difference was zero. The earlier erroneous REST-state zero-error test was rejected. This is limited deformation evidence, not visual acceptance of all motion.

Published character refs currently preserve production code/provenance. Locally generated final blend/PNG/GLB assets must still be published or given a complete reproducible acquisition path before claiming a self-contained remote visual deliverable.

**Still missing: final coherent mother-scene art, complete player-controlled same-scene new character capture, native 2K/4K footage, actual new-scene GPU/performance evidence, finished siege/world integration, new macOS candidate and owner art approval. M5 remains DEVICE_NOT_RUN.**


## 8. Verified continuation — 2026-11-15, 01:21 UTC

### Published functional source and real limitations

- `dot/production-v2-map-runtime@087fc86dd81d90f2015a02f9f0c8d25a2af5bb09`: complete-mother host, explicit Controller/Skeleton entry, actual input, bridge-edge path correction and packed-resource closure.
- Latest on that branch: `9d86c168d64f700f731aa663636552aed0140abf`, adding bounded exact-coordinate/surface-ID support caching and genuine CPU profiling. The full default `tools/test.sh` on this published source completed with exit 0; log SHA-256 `cd356605bd9bf98dbc6cc456bcea4feb07048d0264cfda656605cdcffe20e55d`.
- Actor interface/input diagnostics: `dot/mh-spear-production-v2@d4dc3c60ac577272a8a69e68bf24d8b692a55aab`.
- Clothing production source and unchanged-threshold deformation checks: `dot/soldier-production-v2@b7cc1ae451cad00d5a517f5bbc38607b15472aa4`.

The first actual Controller run in the functional source004 fixture produced one hero hit followed by natural death. A second run stopped at tick23 with `no_legal_new_map_route` and no hit. This failure is retained, not hidden behind the first success. The cause was the earlier anti-oscillation fallback: at a legal bank position the only reachable first graph node was 0.713m away, but fallback wrongly required more than0.9m. Safe forward nodes remain the first choice; only when none are reachable does the corrected route rejoin its reachable first node. No collision radius, HP, enemy location or real damage was changed.

After correction, the same actual Controller/complete Skeleton path produced two real hero hits, four received hits and natural HP0 at tick280. The recorded death clip reached2.4seconds/phase1 and inputs were released. This is CPU/headless interface evidence, not a GPU action showcase, survival pass or art acceptance. See `docs/PRODUCTION_V2_CONTROLLER_RECOVERY.md`.

The current scene entry still presents only the hero with the new full Skeleton; ordinary troops remain explicitly labeled old visual diagnostics. A small cohort of **actual ordinary foot spearmen**, with separate real Unit state and shared mesh/material resources, is the next integration step. Do not substitute the spear appearance for other weapon classes or call this a rebuilt army.

### The new-map CPU problem is real and remains unresolved

Actual profiling isolated roughly5.5seconds of graph setup from172seconds of400 instrumented simulation steps. Inclusive nested hot spots were about139.6seconds in waypoint queries and104.2seconds across8.89million support queries; they must not be added together. AStar itself was only about4.96seconds.

After the separate route-correctness change, cache OFF and both bounded-cache variants produced the same complete Save SHA-256:
`838b746066cd11cd8f59828d2f30de381d1e796ec5a25af638cc95beeac7a5ec`.

The observed400-step CPU wall times were157.08seconds without cache and148.68seconds with exact coordinate plus per-map surface-ID caching, with a32768-entry total limit. Godot's reported static peak increased from210.44MB to234.62MB; this is not process RSS. The roughly5.3% difference is a limited observation in a shared, instrumented CPU environment, not a stable hardware benchmark or FPS. **The new prototype is still far from the real-time target.** Additional exact query optimization is under independent experiment; do not attribute it to this published source. See `docs/PRODUCTION_V2_QUERY_PROFILE.md`.

### Source completeness and character failures are preserved

The full generated armor material PNG is now actually recoverable from `assets/owner_generated/lamellar-material-v2/`, introduced in76ae431. Remote source parts were fetched, rebuilt and compared byte-for-byte:2,873,363bytes, SHA-256 `f345b00aa714d05a81d2c1fc743da0b1f72eac35f42b3a046689882b875242a1`. Its provenance remains generated project material, not an invented CC0 license.

Clothing15 was stopped before GPU/export after genuine Jog/Death needle deformation. A live shoulder Bevel was one cause; original pants and derived soft-cloth weight discontinuities were additional causes. These were repaired rather than hidden by disabling motion or deleting body parts. Source18 passed the same14-action/129-real-POSE deformation gate without widening thresholds, and complete dynamic images were inspected. It remains **ART_FAIL** for shape/material/coverage quality. Its full blend and later runtime export are still local work, not implied to be a complete published character asset by the code commit. A subsequent all-integer-frame check covered2,166POSE samples across the same14clips with zero failures; this is not cloth-collision or interpolated-frame acceptance. The cloth-only thrust picture has no weapon and cannot prove two-handed grip; the combined spear/rig's actual imported timing and poses must be checked. Its current export is also correcting missing tangents on derived n-gon surfaces and a duplicated action, so it is not yet claimed game-import clean.

An independent actual-character PCK test demonstrated that the current imported actor has eight external texture dependencies, not just one PackedScene. An empty-working-directory pack with the actual imported scene, eight textures, their import remaps and UID table loaded163bones/14clips without rawGLB/PNG source fallback. Intentionally omitting one texture was rejected. This is a resource-closure check, not a new whole-game candidate. Native imports must generate their own packed-resource hashes.

### Stop the unsuitable ready-made-scene loop

The complete Red Autumn Forest source was genuinely rendered with original EEVEE/camera/materials on hosted Metal in [run43661267243](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43661267243), source `592eedc1b8a05abd97ed5d5bc0cadc7ea8cd379c`. The850×312 original-source PNG is in [artifact14140152238](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43661267243/artifacts/14140152238). It is a Blender source review, **not Godot gameplay**. Its paper-like vegetation and strongly illustrative fantasy style were rejected as a direct battlefield mother. The preserved review is on `dot/red-autumn-source-review`; no second visual run is implied.

The production route is now a new unified, editable **stone-gate river battlefield**, governed by the owner's whole-image target: near-bank military road, wooden bridge,3–6m real stone landing, thick gate passage, coherent rock banks and forest edges. Rear courtyard/retreat space must exist for real armies but need not all fit in the normal camera. Do not shrink people to show an entire ring fortress. Existing mature redistributable inputs may be adapted into this coherent new scene; do not require or blindly reuse a complete film world. New full-scene authoring02/03 previews were also rejected, and are not Godot screenshots or accepted production-v2 candidates.

The45-degree/50-FOV/pixel-fraction camera is a development candidate, not an owner-approved constant. Preserve the requested roughly22-metre fixed-condition comparison; record any new camera experiment separately, at true native pixels. Next visual judgment must include actual ordinary troops and original-speed actions in the complete Godot scene.

**No new whole-scene Godot GPU result, new macOS candidate, final mother topology2, M5 device pass or owner art approval exists at this checkpoint. Main and PR67 are unchanged.**


## 9. Verified continuation — 2026-11-15, 01:41 UTC

**No new production-v2 whole-scene GPU image or accepted art candidate exists yet. Main remains `248d26aefbb8dfe7973141a63b40f3a220f0edc0`; draft PR #67 remains `1cfda095b05a78dfe89da6f2ddd8f8cb89819180`. Do not merge or promote this recovery document as a game release.**

### Stop the failed authoring method, not the project

Offline composition02 through05 were personally reviewed and rejected. They still produced a broad grey sandy platform, separated shoreline rocks, weak bridge/architecture and unreadable ecological transitions. The final05 paving also incorrectly used a rock-group atlas as a repeating stone texture. Repeated changes to that generator are not the whole-art rebuild the owner requested.

That authoring route is now **frozen at05**. All four05 views, the editable mother source, exact source manifests and failure records are retained; the queued06 run was cancelled before Blender and produced no scene or image. Its draft source is explicitly unexecuted. A new independent whole-scene author is rebuilding the human-scale bridge/gate, continuous landform and coherent materials from the target, without inheriting the old generator as a foundation. Mature source assets remain inputs, not visual approval. The next mother scene must export its actual visible/support/obstacle geometry and baked Godot-readable materials together.

Actual camera measurement corrected two false assumptions in05: the posed body bounds were 1.61365 m and approximately90.18 pixels in the1600×900 candidate view, not the assumed112.5 pixels. The file labeled `legacy_ortho22` actually had a39.111 m vertical span because of a Blender sensor-fit conversion error. It is **not** a valid22 m comparison. The45°/50-FOV/.125 camera remains a development proposal, not a fixed owner instruction; actual gameplay pixels and the owner's normal-view target govern the decision.

An isolated, default-OFF **2.5D feasibility experiment** is also underway. Its clean generated environment input is not game evidence. The experiment must test real actors, movement/combat, camera translation, support alignment and bridge/gate occlusion in Godot. Fixed direction and prelit background are explicit unsupported-feature boundaries, not silently removed capabilities of the main game. A pleasing fixed image that cannot survive real motion and occlusion fails. No route has been selected or visually accepted.

### Source18 is actually imported, and real ordinary troops are connected

- Soldier source/deformation checks: `dot/soldier-production-v2@38eb2a4f553c90b8e783e3884630be8995fa238c`.
- Source18 runtime receipt and real ordinary-unit adapter: `dot/mh-spear-production-v2@cf6dbed9abc3e5f9c61f7ef038e15522527dabf3`.
- Actual six-ordinary-soldier Controller integration: `dot/production-v2-map-runtime@bce27e7927f169b8b5e261b4c04120c629b558bc`.

The missing-tangent and duplicate-action problems noted in section8 were corrected and the rejected exports preserved. The actual final local GLB is14,173,132 bytes, SHA-256 `afb966396bf5ad656b3cb0cd2edc388fc6fa02eba59df8b81d9a23ac53f3be8b`, with163 bones,14 animations,35 surfaces and16 materials. Five actual Godot import/runtime logs are clean. Imported thrust lasts0.7 seconds with its measured peak at one third; death lasts2.4 seconds. This is not proof of finger collisions, art quality or a scalable thousand-Skeleton renderer. The complete generated GLB/mother source is not yet implied to be remotely published by those source-code refs.

Source18's lossy top-eight-weight derivative was independently checked again:3,682 vertices affected, maximum discarded weight1.9975%, and maximum actual tested pose displacement2.034 mm. The earlier source11 silhouette result does not apply to this changed source. Source18's materials, silhouette and cloth coverage remain **ART_FAIL** despite passing unchanged deformation thresholds.

The real Controller test now binds three actual ordinary foot SPEAR units per side to shared mesh/material resources, with separate Skeleton/animation/binding state. It does not give spear appearances to other weapon classes or rewrite HP. At460 actual Battle steps, the defenders retreated; four of the six bound soldiers naturally died and their real Death01 reached2.4 seconds/phase1. All six exhibited walking and hit states; five exhibited thrust. Applying presentation left complete Save state unchanged. A first terminal-position error of approximately14 cm was preserved, corrected and retested: all six final actor/source-support errors are below0.00001 m. Retreat animation remains explicitly unsupported.

This is **CPU/manual-step functional evidence**, not original-speed video or GPU art. The complete default regression on bce27e7 has now finished with exit0, including real legacy512 siege/world writeback, save migration and youth attrition restart checks. Its log SHA-256 is `696fcc42442df81bad51638c5e887eea3e0dac92b2dc2b92f1717d93cabecb15`; the new entry check-only also completed cleanly. The same frozen source18 is being prepared for the single coordinated hosted-Mac visual experiment rather than duplicating CI or showing old004 terrain as a new visual candidate.

**Still missing: accepted whole-scene art, the new actual 2K/4K original-speed game capture, final topology2, new-scene real-time performance, complete new-map siege/world integration, a new macOS candidate and owner visual approval. MacBook Air M5 remains untested.**
