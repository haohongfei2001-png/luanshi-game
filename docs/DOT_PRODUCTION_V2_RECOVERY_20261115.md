# Dot whole-scene production-v2 recovery — 2026-11-15 UTC

**State: ART_REBUILD_REQUIRED. No production-v2 playable art candidate has passed. This is a recovery checkpoint, not a release or acceptance report.**

**Read section 26 first for the latest verified continuation. Earlier source tables and results are preserved checkpoints, not instructions to revert later work.**

This checkpoint supersedes the *next-art-action* recommendations in the older regional 04/05/06/07 experiments. It preserves their source and evidence. Read the current main `AGENTS.md`, `OWNER_MOBA_CAMERA_AND_ART_AUTHORITY_20261114.md`, the owner's latest matte-material authority in draft PR #67, the original Dot handoff, and Issue #12 together with this file. Codex remains **PAUSED**; Dot continues the authorized cloud development.

> Sections 7 and 8 are earlier checkpoints. They remain preserved, but their in-progress statements must not override the latest section.

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


## 10. Actual whole-source and first GPU checkpoint — 2026-11-15, 07:20 UTC

### HF08 is a new whole source, not accepted art

Author source is now `dot/river-valley-high-fidelity@79f8f0304693b5ad33a3634caebbb92d491a4033`, [draft PR #69](https://github.com/haohongfei2001-png/luanshi-game/pull/69). Actual independent runtime evidence is `dot/production-v2-map-runtime@b8c8cf02c12433265d0642fdae88104b5fb44f39`. The latest complete default regression remains bce27e7's pass; later source-identity and HF08 changes have their own focused checks, not an invented second aggregate pass.

HF08 rebuilds the terrain, continuous banks, bridge, thick gate, overlapping roof tiles and material atlas together. Its actual GLB is215,471,760 bytes, SHA-256 `cb89ed9ca8d045c28c684bc69d62b996bdad3d5e1a61bf47e5d14aa20d982755`. The clean nine-member runtime ZIP is139,477,998 bytes, SHA-256 `f5ac12b501293da966a12072509550d91ac60fd5fafc283f8b55aa8475cb91f4`, and has a durable private Library backup. It is not yet an anonymously retrievable GitHub artifact; do not fabricate a public download link or embed private transfer URLs.

Actual Godot checks of this new source, not old004, verified8,882 navigation nodes,33,862 support triangles and62 solids;20/512 ordinary soldiers per side deployed legally, with1,057 total characters in the larger case. Four source-defined bridge/gate/retreat routes reached their destinations. A real Controller/source18 cohort ran100 ticks with70 walking and30 idle observations, HP100 and zero hits. That is movement integration, not attack or original-speed performance acceptance.

HF05a's original Sun had shadows disabled. This was found by reading actual Godot properties, not inferred from Blender pictures. HF08's author wrapper now enables the existing sole Sun, with energy2.7, shadow mode2, maximum distance80 m, bias0.1 and normal bias0.6. The independent check confirms those properties and one WorldEnvironment; no runtime fill light was inserted. All four offline HF08 GLB-reimport views were inspected and remain **ART_FAIL**. HF08 itself has not yet run on GPU.

### First isolated2.5D GPU run genuinely happened, but failed

The separate opt-in prototype is `dot/25d-environment-feasibility@d161f76f805aaab49a5da87bbdda7db6dbe0d0d9`. [Run43688703476](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43688703476) imported source18 and ran actual Godot on hosted VirtualMac2,1 using official4.6.3 Compatibility/ANGLE on an Apple Paravirtual Metal device. [Artifact14151193154](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43688703476/artifacts/14151193154) preserves the original logs and75 frames, expiring2026-11-29. GitHub login may be required.

The actual screenshots were only1024×645 because the native window was clamped by the host desktop. The strict requested2560×1440 assertion correctly failed and4K was skipped. They were not resized. The process took51.15 real wall seconds, whereas the old report accumulated10.016 seconds of engine delta; those are not interchangeable, so the first run proves neither original-speed recording nor real-time performance.

It used a1672×941 AI-generated static environment image projected into world-aligned layers, real3D source18 spear actors, explicit diagnostic capsules for other weapon types, and real Battle state. It is **not a completed3D environment or a rebuilt army**. The actual run recorded29 hits/four ordinary losses and hero death at tick111; only two of six route points were reached. Fixed camera direction, finite image boundaries and prelit environment are explicit limitations. Full GPU traversal and acceptable occlusion remain unproven. The actual frame was inspected: the environment is readable, but people are fragmented/bright and visually inconsistent; all art remains rejected.

The first raw14 MB character Git blob request was rejected before any ref write because its base64 request exceeded the transport's16 MiB limit. Exact gzip compression resolved it without changing the GLB:10,442,257 bytes, SHA-256 `caf49a68890e78644448489a8df7e2bafe2d2dc1617f6270fa886248e65737d7`, Git blob `583d99e1ad15cbee89fa1d6189ca334c419a5382`. The experiment restores and verifies the original14,173,132-byte/afb966 GLB before import. Source notices retain CC0, CC BY3.0, CC BY4.0 and project-generated distinctions.

A second run at `16b1430166ab9d099452f7247ff0d3aa38990fbd` is now testing real independent2K/4K GPU viewports, monotonic wall-clock timestamps and byte-exact license manifests. Its result is still pending here. The existing official Compatibility native-Skin tangent defect also applies to this rendering path and must be controlled before blaming every bright fragment on the character material. Preserve original-engine evidence; compare an actually supported corrected/native rendering path without silently altering source art.

**Still not accepted: the whole image, people, final rendering route, native2K/4K motion evidence, HF08 GPU performance, a new macOS candidate or M5 performance. Main/PR67 and the RC24/RC25 recovery points remain unchanged.**


## 11. Actual Metal experiment completed and rejected; native HF08 remains separate (2026-11-15 07:50 UTC)

This section supersedes earlier pending-state descriptions, not their preserved failure evidence. No whole-scene art candidate has passed. Main remains `248d26aefbb8dfe7973141a63b40f3a220f0edc0`; draft PR #67 remains `1cfda095b05a78dfe89da6f2ddd8f8cb89819180`, both re-read remotely before this checkpoint. Neither was changed.

### Real GPU result, with a strict route rejection

The independent fixed-camera 2.5D experiment's corrected source is `1ce0ecc030db0b5ec5467fd34e1f6e3c396abc6a`. [Actual hosted-Mac Metal run 43690415954](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43690415954) completed successfully. [Original evidence artifact 14151854509](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43690415954/artifacts/14151854509) is 243,194,590 bytes, SHA256 `c5001a773e7c4aa45b04378b792ed252ccbaef6c5a9050aab246571da1148cfe`; verified not expired, expiry 2026-11-29 07:36:24 UTC. GitHub sign-in may be required to download. CI success does **not** mean visual acceptance.

- Actual direct GPU targets are 2560×1440 and 3840×2160; the projected AI-generated static background is still only 1672×941. This is **not** a render of the new editable HF08 3D mother scene. Camera angle and prelit environment are fixed, and bounds are finite.
- The 2K combat scene has 19 true Battle entities: 11 source18 spear actors plus 8 explicitly diagnostic capsules for other troop kits. Real combat produces 29 hits, 4 ordinary deaths and natural hero death. There are no HP/position cheats. This is not full troop-type art or 512-per-side rendering proof.
- The hero genuinely crosses the bridge and gate, reaches 5 of 6 traversal waypoints, and dies before the sixth. The moving camera is real. However, `2560-traversal/still-00048.png` visibly renders rear-court soldiers over the roof and cuts bodies at the lintel. The coordinator and experiment worker personally checked these actual pixels. Complete depth/occlusion and trustworthy visual ground contact **FAIL**.
- **Reject the current single-background-plus-fragmentary-occlusion scheme as a production mother scene.** Do not keep adding small masks or hiding the problem with framing. This does not prove all 2.5D methods impossible, but revisiting a fixed-camera hybrid would require coherent full-space depth/collision and adequate source resolution, not an attractive starting still. HF08 geometry-first integration remains separate.
- A separate 12.01154-second no-readback window records 638 process callbacks, 53.12 process Hz, median interval 16.704 ms and P95 20.892 ms. This is one short hosted-Mac, 19-unit observation, **not** certified presented FPS, sustained performance, 512-per-side or MacBook Air M5 evidence. Battle ends at tick 111 after hero death, so subsequent frozen Battle ticks are not a simulation slowdown ratio.
- The 2K combat and traversal videos are encoded from exact monotonic JPEG timestamps as variable-frame-rate 10.20-second and 10.04-second clips. Capture-start/readback stalls remain visible. No nominal-FPS respeeding, interpolation or generated frames were used. Encoding receipts preserve ffprobe and frame times. 4K captures are stills, not a motion benchmark.

The same-tick GLES/Metal images keep assets, materials, lights, camera and roster fixed, but switch engine **and renderer**. They are not an isolated test of the earlier GLES tangent patch. Actual Mac template feature/debug flags were not printed by this experiment; its provenance and binary hash are known, but do not label a directly measured release mode. The next independently planned native run records those flags. The earlier Linux packed test was positively identified as `template_debug`, not release, and the original assertion-side-effect initialization failure remains preserved.

### Character import correction, not a visual approval

The source18 GLB remains byte-identical: 14,173,132 bytes, SHA256 `afb966396bf5ad656b3cb0cd2edc388fc6fa02eba59df8b81d9a23ac53f3be8b`. The confirmed UV-contract mismatch in section 10 has an isolated default-off ShaderMaterial prototype: 11 real spear Units, independent bones, 80 Battle ticks, 198 affected surfaces sharing two shader materials; original meshes and texture objects are not copied, and the other 17 surfaces stay unchanged. Independent CPU sampling checks 1,253 cases with maximum UV error 5.96e-8 and base-level material error 3.50e-6; actual custom data is confirmed to contain TEXCOORD2. Unsupported material features are rejected, not silently simplified.

This is headless/import correctness only. No GPU shader/material acceptance is claimed. Save its exact source on an independent branch, then add same-tick, same-camera/light/roster 2K OFF/ON control frames to the already planned HF08 native test. Do not combine this comparison with light changes, edit source18, activate the unadopted source19 texture-copy proposal, or propagate an unreviewed material to all soldiers.

### Exact map-query optimization: second Linux stage, still not real time

Independent experimental commit `83fdcf026e44b5a4a8136f13edfeb46109d91139` batches exact ordered native support samples while retaining the original GDScript obstacle/gate/height checks. 55,915 sample-byte cases, 2,622 full segment decisions, all 8,882 navigation-node connections and the prior 507,887 support-query comparisons pass. The 512-per-side, 1,057-entity, 40-tick Battle snapshot is still exactly the same 231,048 bytes, SHA256 `b177e17b8093cabb02a6f6d2c37183451e452518790ebea1a9963b5f9dc9fc3e`. All 1,056 moving units remain legal. This early marching window has no attacks, hits or casualties.

One paired Linux observation improves the scalar native stage from 10.997 to 7.170 seconds, a further 34.8 percent reduction; all 910,489 body-obstacle checks and two shot checks remain. Static support may be evaluated beyond a later obstacle rejection, so cache counters are not identical although Battle state is. This is still far from real-time thousand-person simulation and not a GPU result. The original/default runtime remains unchanged. One isolated standard macos-15 ARM CPU-only verification is being prepared with the sanitized 1.29 MB manifest and necessary source, no large GLB or GPU work. It must record actual architecture/engine mode and byte equality before any integration.

### Actual native-world bottleneck and next command boundary

HF08 source `79f8f0304693b5ad33a3634caebbb92d491a4033`, exact runtime ZIP 139,477,998 bytes / SHA256 `f5ac12b501293da966a12072509550d91ac60fd5fafc283f8b55aa8475cb91f4`, original license notices and offline art failures remain frozen. Native review preparation is `b6a8e5e70459f135ad0f1cf39287e81fd5dd5ad8`; its input descriptor deliberately rejects missing artifact IDs. **No HF08 GPU result exists yet.**

The exact world package is durably retained. Transport to the existing GitHub Actions pipeline is not complete: a 6 MiB chunk request yielded, then its tool wait unexpectedly blocked about 532 seconds; after internal interruption, the expected blob was checked through the connected GitHub API and absent. A reduced 3 MiB request also yielded, then a later wait blocked about 551 seconds. Its outcome must be checked before retrying. No success or authorization denial is inferred from that stall. Preserve both attempt ledgers. The resource branch exists at the unchanged main base, without a completed resource commit/artifact. Do not duplicate writers, pass private download credentials into public source, or call the pipeline ready. Resume from the exact chunk ledger, then activate only the already prepared native job once the exact public artifact and notices are verified. Continue independent material/performance work while transport is blocked.


## 12. Geometry publication paused; actual typed restart checkpoint delivered (2026-11-15 09:10 UTC)

This section supersedes earlier instructions to resume geometry transport. Main remains `248d26aefbb8dfe7973141a63b40f3a220f0edc0`; draft PR #67 remains `1cfda095b05a78dfe89da6f2ddd8f8cb89819180`. RC24 and RC25 are preserved. No new complete-scene art candidate, HF08 GPU run or macOS playable package has passed.

### Stop boundary for unpublished map data

Publication of the HF08 topology manifest was explicitly denied during action review. The owner has been asked to authorize the concrete public disclosure; no confirming response has been received at this checkpoint. The complete HF08 ZIP contains that same payload, so its transport is also paused. Do not retry it through compression, splitting, another API, another branch or a different worker. Two of 533 small package blocks already exist; no upload is pending, and there is no resource commit, completed artifact or activated native run. Earlier long-call uncertainty was checked separately; it does not override the later explicit denial.

The bounded complete-depth 2.5D follow-up was also not promoted. Its CPU routes do not establish natural scale or sustained character visibility, and publication of its new geometry was denied. Some objects were created before that denial, but the public experiment branch was not advanced. Preserve the local checkpoint without retrying its publication. This is not an all-2.5D impossibility claim.

The only connected authorized cloud computer was checked for local rendering. It has no usable desktop/compositor session for the available Godot templates; headless mode is a dummy display, not GPU capture. No user computer, socket/security workaround, new service or paid resource was used. These two limits explain why HF08 has no new actual game image. Independent source-only work may continue, but must not carry the denied data.

### Delivered opt-in save implementation, with real restart rather than JSON equality

[Pure-source commit 158de27ade75accd3bdd7e10a918176ab8060946](https://github.com/haohongfei2001-png/luanshi-game/commit/158de27ade75accd3bdd7e10a918176ab8060946) is on `dot/experimental-save-v5-source`, based on public native preparation `a2d39ae2e2321dd59e55ed18352fa237d32c11b1`. Its 13 text files contain generic code, tests and instructions, not world geometry, assets, typed save samples, trajectories, PCKs or private reports. The exact full tree is `70681af6659e4e7e2232818e6b7e92cfeb149ac1`. Remote ref and tree were verified. No PR, main update or CI run was triggered.

The default-off API saves supported open-gate authored Battles into a separate experimental namespace. It requires an already verified runtime and exact map ID/topology revision/topology SHA, records the missing authored continuation state, preserves Variant types and RNG, and rejects incomplete, corrupt, unknown-topology or unsupported-mode data. The normal v1–v4 quick slot is unchanged. It does not activate Controller/UI loading or campaign settlement.

Actual Linux Godot testing used 512 ordinary troops per side, 1,057 total entities. A writer saved at tick 400, exited, and a new process loaded the disk file and continued to tick 420. Full typed state and the passive per-tick combat/order/projectile/RNG observations match an uninterrupted control. Final counts are 570 attacks, hits [98,178], losses [51,21], with final typed snapshot SHA256 `79abb40a2acf1dc82cddd6a78e31b11f342463e16df11fa68c925ae8121aac29`. These are this test's real inputs, not the different performance fixture's combat counts.

The final code was additionally packed into a small existing Linux **debug** template, booted through an inert main scene from an empty working directory, and loaded the same real disk checkpoint: 60 checks passed; independently missing-source and missing-oracle packs correctly refused. Original quick-save and campaign-sentinel bytes stayed unchanged. The legacy v1–v4 differential passed 138 checks, and unsupported MapQuery boundaries passed 66 checks. A sentinel proves file isolation, not world settlement. Detailed commands and limitations are in `docs/EXPERIMENTAL_MAP_V5_RESUME.md` and `docs/EXPERIMENTAL_MAP_V5_PACKED_CHECK.md` on the source branch. Locally authorized map input is required and deliberately not included.

Important correction to older diagnostic evidence: `JSON.stringify` equality is not complete typed save preservation or restart proof. Vector/PackedArray types and all int64 RNG values are not safely represented that way. The new tests compare actual typed Variant bytes and perform real separate-process loading. Earlier JSON-only performance observations remain diagnostic, not retrospectively upgraded.

### Exact-query CPU continuation, not a graphics result

Local body-query and fused-travel prototypes retain the original algorithm's gate, support, slope, early-return and boundary decisions. The fused checkpoint is `c6738d3c9ec0359ecf0c2db0fac816d4558ba4e1`, currently local only. A fresh 400-tick paired shared-Linux observation reduced the previous native-body stage from 60.895603 to 46.677878 seconds. All 6,687,085 required body checks and 16,955 shot checks remain. It avoids 2,199,707 speculative support samples after an original early rejection, not required collision work; 2,652 independent per-step decision/counter cases verify that distinction.

Typed snapshots and mapped state at ticks 0/100/200/300/400, plus the complete 401-row typed event stream, are byte-identical to both the paired control and the original full GDScript baseline. The final typed snapshot SHA256 is `c92536b9e0d54d01b07779f39bfe14fcb095d0c0e69d7e8aad0b1960651e38c6`. Actual combat has 492 attacks, hits [93,139], losses [38,22], with two delivered orders. This is still 46.7 wall seconds for 20 simulated seconds, not real time, FPS, a Mac result or M5 acceptance. Do not combine separate benchmark pairs into a fabricated single run. A separate pure-source checkpoint is being prepared without the denied manifest or evidence payloads; no public native binary is claimed.

### Most recent actual image and next independent visual check

The latest game image remains corrected Metal run 43690415954 described in section 11. Its complete original artifact has now been privately backed up with the exact existing SHA. The image and original-speed videos are rejected experiments, not the new HF08 scene. A further camera audit found the old overlay's “22m” misleading: the camera uses **orthographic size 22**, offset (0,40,40), with actual camera-to-target distance **56.5685 m**. Thus it is not the owner's requested 22 m camera-distance comparison. Original evidence is preserved unmodified; future captions must state projection, span and distance separately.

The already public source18 UV adapter is `dot/source18-uv-spatial@01fb175a8ee64ed65c67e16f76bf06ea37f2b6b5`. A small code-only OFF/ON control is being prepared from the existing public 2.5D test scene and assets, with identical Battle, bones, transforms, camera and light and with exact material restoration. It introduces no HF08 or denied geometry. It has **not run on GPU yet**. Its purpose is to verify UV/material rendering correctness, not to revive the rejected static-plate scene, conceal the whole-art gap or declare armor quality accepted. Whole-scene reconstruction remains the visual task; all art, actual M5 and full-army visual gates remain unpassed.


## 13. Actual same-pose Metal material control; whole art still fails (2026-11-15 09:34 UTC)

This is a technical continuation, not a new complete battlefield candidate. The geometry publication pause in section 12 remains in force. No HF08 GPU picture exists, no denied geometry was retransmitted, and main/PR67/RC24/RC25 are unchanged.

The eight-file code-only control at `fbd25aa6cf6a53456871df98f0d41e7d5fc62260`, tree `96126385e6947481d983f6feaca176bb27b7c05f`, reuses only the already public scene and source18 asset. [The single hosted-Mac run 43699172747](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43699172747) succeeded. [Original artifact 14155203811](https://github.com/haohongfei2001-png/luanshi-game/actions/runs/43699172747/artifacts/14155203811) is 15,045,767 bytes, SHA256 `548ac979c633bfeb499b0543953a6d5c998ee94353bad820c3e3653be79d0b8f`; expiry 2026-11-29 09:26:50 UTC, GitHub sign-in may be needed. The downloaded ZIP passed its exact hash and all CRCs, and original evidence plus the two review pictures were privately backed up. No automatic rerun is scheduled.

- Actual hardware: VirtualMac2,1, ARM64, 3 vCPUs, 7 GiB, Apple Paravirtual device (Apple5), Mobile/Metal. Runtime measured `debug_build=false`, `template_release=true`, `template_debug=false`, `release=true`, `single=true`. These are this run's observed flags, not an inference from its filename or a claim about the owner's MacBook Air M5.
- Three raw GPU images are 2560×1440 with internal scale 1.0. The presentation window is still 1024×645; the pictures come from the real 2K target, not a resized window screenshot. Environment source resolution remains 1672×941. TAA is off, MSAA3D enum2 and the original quality settings are unchanged. Orthographic size22 and actual camera-to-focus distance56.5685 m are recorded separately.
- All original 19 units and 11 source18 actors stay at tick0/Idle0.05 seconds. Exactly198 affected surfaces are switched OFF/ON/restored. Unit, bone, skin, mesh, transforms, camera, light and viewport signatures match across stages. The first and restored OFF pictures are byte-identical, including PNG bytes; 880 non-actor background tiles, totaling3,522,560 pixels, do not change.
- ON changes7,441 RGB pixels, about0.20185% of the full frame. That establishes a genuine isolated rendering effect, not temporal noise or changed framing. It does **not** independently prove every UV/PBR semantic or artistic correctness. The unchanged CPU UV contract and this GPU control answer different questions.
- Both reviewers personally inspected the full normal-size originals: **ART_FAIL**. Armor still reads primarily as gray/black blocks, hands as small bright shapes, with insufficient clear lamellar/cloth/leg-wrap material information. People and background remain inconsistent in scale, lighting and detail density. A UV correction alone cannot deliver the owner's whole-scene rebuild.
- This is frozen static evidence. The inherited HUD still lists WASD/attack controls, but the test deliberately never starts the battle. Do not present it as a playable demonstration, movement/attack/death validation, full troop-type art, a thousand-person benchmark or a new macOS candidate. The most recent actual motion evidence remains the rejected earlier run in section11.

The exact-query code is now saved separately as [pure-source commit936849f60f67a57c85f0a832f12736699c97e9c8](https://github.com/haohongfei2001-png/luanshi-game/commit/936849f60f67a57c85f0a832f12736699c97e9c8), branch `dot/experimental-exact-map-query-source`. Its 15 code/test/document files contain no authored data, binary, trajectory, stored save or workflow. Targeted boundary/runner checks passed; the existing400-tick evidence was reused honestly, not rerun or relabeled as a new benchmark. The default game is unchanged.

The save source branch now ends at `091532364f7f398d578d9841463b741483fd142d`: in addition to22 runtime files, the packed oracle consumer, builder and Python runner are frozen against the same exact source commit before output creation and every Godot launch. Dirty-harness and invalid-ref cases fail before execution. The final60 packed checks and both missing-resource negatives pass again. No new400-tick run, geometry publication, main integration or CI accompanies that two-file source follow-up.

Continue the whole-art task without promoting these small technical corrections. The bounded read-only no-display feasibility check found an installed EGL surfaceless extension entry, but no created context or rendered frame. The existing Godot headless backend explicitly selects dummy rendering, the existing custom template lacks Vulkan, and no installed software Vulkan ICD or reusable full engine object cache was found. A new isolated EGL display backend would require a full template build and several GB of working space; the current cloud disk cannot safely support that. Do not describe the extension string as a working renderer or retry display sockets/security workarounds. This candidate was not implemented, and no new engine, context or scene render ran. Public HF08 data transport remains paused until the required owner's confirmation.


## 14. Transactional Controller restore delivered; local renderer build in progress (2026-11-15 10:18 UTC)

The newest source checkpoint is [ea0d8e606947240c28490db4d70631ea2e96357b](https://github.com/haohongfei2001-png/luanshi-game/commit/ea0d8e606947240c28490db4d70631ea2e96357b) on `dot/experimental-save-v5-source`, parent `091532364f7f398d578d9841463b741483fd142d`, exact tree `536815493efba5c28c8a3232c853f1343814a51c`. The remote ref was verified. Six text source/test/document files only were published, with no map geometry, source package, typed save, trajectory, PCK, private report, workflow or new PR. The exact commit currently has zero Actions runs. Main remains `248d26aefbb8dfe7973141a63b40f3a220f0edc0`; PR67 and the RC24/RC25 recovery points remain unchanged.

The authored Controller now has a second explicit default-OFF opt-in for v5 save/load. The main Controller, Battle/Save backends, ordinary quick slot, main menu and world settlement are unchanged. Successful restore replaces exactly one Figures instance, preserves the mother and seven supplied source18 actors/shared resources, restores authoritative simulation inputs exactly, clears only external held input and transient UI clocks, and pauses. See `docs/EXPERIMENTAL_MAP_V5_CONTROLLER.md` on that branch for the entry flag and reproducible test.

Independent review blocked the first local candidate despite its 257 passing checks: unsupported valid actor states could be adopted without a correct skeletal pose; a separate save/load notice could be hidden by the ordinary HUD notice lifetime; tests could skip absent semantic coverage. These were fixed before public delivery. Every actor is now preflighted using disposable binding state and read-only clip access before any live scene write. Saving uses the same gate and cannot overwrite the prior slot with a presentation this Controller cannot restore. Valid guard WINDUP, GUARD and sideways MARCH fixtures are rejected transactionally. This restriction is explicit, not a claim of complete animation-state support.

The final same-runtime CPU SceneTree test passes **440 checks**. It uses real input events and HUD signals, 20 ordinary troops per side, seven actual source18 rigs and 163 local/global bone transforms per rig. Repeated restore preserves 474 nodes and seven Skeletons, with no double crowd actors; whole typed Battle continuation matches for six steps per checkpoint. Successful poses are compared with an independent source actor sample, not only a receipt. That remains lifecycle/actual sampling evidence, not an independent animation evaluator or an artistic correctness oracle. Mandatory role-qualified gates include actual hero thrust, ordinary nonhero/nonofficer walking, buffered action, natural death and an aged corpse. Death01 at tick349 retains phase0.5416666451. The whole fixture, including subsequent legal rejection inputs, ends at tick382 with33 attacks, hits[12,8] and losses[1,2]. Ordinary source18 attack and natural ROUT/ESCAPED events remain NOT_COVERED. Old v1–4 differential138 checks pass; no legacy runtime changed after that run. Whole-mother GPU rendering, exported entry, release execution of this Controller test, 512-person Controller performance and M5 remain untested.

### Distinct local rendering work, not a publication bypass

HF08 and new 2.5D geometry publication remain explicitly paused pending the owner's required confirmation. No denied payload was retried or transmitted through another format, branch, API or CI. The actual pictures remain section13's frozen Metal control, and **all art still fails**. No newer complete-scene image exists at this checkpoint.

A separately bounded test of already installed Mesa libraries successfully created an EGL1.5 surfaceless OpenGL4.5 llvmpipe context, cleared a2x2 buffer and read the expected pixels with GLerror0. It requested no desktop/display/network socket. This is only installed-library capability proof, not Godot rendering.

An isolated opt-in Godot display backend is now actually implemented and compiling from official `4.6.3-stable` source resolved as `35e80b3a8822a9df9be390814b62f44c0a9c69e8`; archive66,058,610 bytes, SHA256 `fa22b5f974125057087c9ef725eae582dbc5e39385dc377e8d5dbc295b367e1c`. This is not exact-source-equivalent to the installed editor reporting `7d41c59c4`, despite the same4.6.3 version label. The custom backend and GLES3 units compiled; the full release template is still building. No build completion or SceneTree rendering is claimed. Existing SCons was reused, with no package install, new service, account, cost, security change or user computer. A resource guard bounds the one-job build; original binaries remain untouched. A later incremental step may use two jobs only within the same limits.

The separate actual-game local runner is prepared using the unchanged complete Host/Controller/Battle and strict software-renderer identity labels, same-state2K/4K capture, input-only actions and exact source18/HF08 identity checks. Eight small static tests pass; dependency import, runtime rendering and action capture have not run. It does not weaken or repurpose the existing macOS/focus acceptance gates. Normal release startup, not a silently ignored `--script` override, is required. Software rendering/readback will not be presented as GPU performance or M5 validation.

To make independent work possible, only exact closed-worktree duplicate assets/imports were removed after current-file and retained-backup hash verification plus real Git/ZIP restore drills and refusal-to-overwrite tests. 775 files totaling1,307,400,424 bytes were recovered from disk; all unique material, failure evidence, current sources, active assets/imports, complete Git objects and original ZIPs remain preserved with an exact per-file restore record. Do not fetch large Git histories or run GC to fill these intentionally missing duplicates.

Next: finish the isolated engine, first prove genuine normal SceneTree geometry/UI/motion and pixel readback, then run the complete authored game scene locally with exact input identities. Only then review its actual whole image against the accepted minimum direction and continue full reconstruction. Do not turn storage cleanup, save tests, an EGL clear, compilation or another material correction into an art milestone. The required shared3D-versus-animation-sprite/hybrid comparison at actual gameplay pixels and real army scale remains pending; no representation has been selected by assumption.


## 15. Actual local full-scene capture obtained and rejected; complete reconstruction restarted (2026-11-15 11:02 UTC)

This supersedes the in-progress rendering statements in section 14. Main is still `248d26aefbb8dfe7973141a63b40f3a220f0edc0`, draft PR67 is still `1cfda095b05a78dfe89da6f2ddd8f8cb89819180`, and the opt-in save source remains `ea0d8e606947240c28490db4d70631ea2e96357b`. All three refs were checked again; no in-progress Actions run was present. RC24/RC25 remain intact. **No new playable art candidate is accepted.** The geometry publication pause remains in force; local work does not grant permission to retransmit the denied payload.

### Working isolated engine, not a desktop or GPU claim

The isolated official-source Godot release engine completed. Its opt-in EGL surfaceless backend explicitly creates a Mesa pbuffer and uses the real GLES3 renderer, without a desktop, window-system/socket fallback or the dummy headless renderer. Source remains the exact official `35e80b3a8822a9df9be390814b62f44c0a9c69e8` archive identified in section 14. The baseline binary SHA256 is `1b6ebba5bd463f17f06a0e2f481be4d78a176c8beae0c45cc412fcf6d5b0f860`; the separate build with the existing native tangent patch is `0ff65b61f7332db602ba6305f8f16c14716d96c036fce72fe8a4aae1bdb6bf0a`. The originals and exact source/license records are preserved. This tool does not change the production engine or macOS package.

A genuine normal SceneTree proof draws lit meshes, shadows and UI, changes mesh position, and reads real frame pixels. The same process resizes through 768x432, 1280x720, 2560x1440 and 3840x2160, with queried EGL, root and captured image sizes agreeing at internal scale 1.0. Synthetic Godot mouse/key press and release reach callbacks and cached input state. This is not physical OS input or window-focus validation. Both baseline and tangent proofs exit successfully with no engine errors. An earlier failed proof fixture remains recorded separately; it is not retrospectively marked passed.

### Complete actual game scene, raw 2K and 4K pictures

The real full HF08 mother, authored Controller, Battle and source18 actor dependencies were staged and imported independently. Import took 68.37 seconds and passed with no engine errors after an earlier preserved attempt stopped on an unwritable default cache path. Only process-local writable HOME/XDG locations were changed. No original source or shared import option changed. A strict clip-name mismatch then stopped the first capture before any picture; the exact normal importer mappings were documented and verified rather than accepting arbitrary missing animations.

The successful full-scene process took 108.45 seconds, exited zero and produced two untouched native-resolution PNGs. It uses seed61112, tick0, 20 ordinary troops per side, one source18 hero and six source18 ordinary actors; the remaining ordinary figures still use old diagnostic art. This is the complete scene loaded at the **initial player view**, not a claim that the entire castle fits in the frame. Actual CPU host: Linux AMD EPYC 9V74, nine logical CPUs, 10,451,427,328 bytes RAM; Mesa llvmpipe LLVM19.1.7 software renderer. **Not GPU, real-time performance, Mac or M5 evidence.**

- 2560x1440 at internal scale1.0, captured 2026-11-15 10:40:29 UTC; 7,499,754 bytes, SHA256 `f17141beb0fcde3d12bbecdd29eeefcf24e1fca8d7610f57510335cc5fa104ec`.
- 3840x2160 at internal scale1.0, captured 2026-11-15 10:41:07 UTC; 15,745,516 bytes, SHA256 `6e73ed9431e5c4076613b1f123c1af27f5d2b4a93f280b8fca7f7b35fc7853eb`.
- Both frames have the same complete Battle signature, actor-bone/camera/light state, perspective pitch45/FOV50, and unchanged authored sun/shadow settings. **Actual camera-to-hero-foot distance is 15.5619326 metres, not22 metres.** Do not relabel these pictures. New review calibration will separately measure a true22.000m radial distance and record world matrices, look-target distance and body pixel height.

Both raw originals were privately backed up for owner delivery; their exact identities are retained. The PNGs are not resized, retouched, AI-generated or substituted by offline renders. Review of their actual pixels gives **ART_FAIL**: broad flat yellow-green ground, fragmented foliage and hard-shadow noise, canopy occlusion of bodies, a disconnected-looking pale bridge approach, inconsistent gray/blue troops and insufficient coherent terrain/defense/material hierarchy. The full-scene renderer now exposes the failure; it does not make the art close to accepted. HF08 is frozen as failed evidence, not a base for another series of color or lighting adjustments.

A subsequent real input probe has only two 2K frames, separated by13.870525 seconds, and26.603938 seconds of input observation. It observes real player displacement, a J press/release, source18 spear WINDUP and ordinary walking, but ends at Battle tick5 with no hits or casualties. Its process exits zero with no engine errors. This is **INCOMPLETE functional evidence**, not fluid play, contact/hit/death coverage or a benchmark. No video was manufactured from the two frames. All import, capture and encoding jobs from this checkpoint have ended.

### New whole-source work, not polish on the rejected scene

The new environment foundation is an authored continuous military road, cut banks, bank-integrated timber bridge, load-bearing gate and terrain enclosure, with complete source structural segments and one material hierarchy. HF08 geometry and generated atlases are excluded. No ready-made high-quality complete ancient Chinese battlefield has been acquired; the new scene is being authored and must not be described as an already mature sourced mother. Its first structural source exists, but material, final visual, real Battle traversal and512-per-side checks remain pending.

A new complete editable character source exists with all old source18 outfit, armor, helmet and straps removed; lawful mature anatomy/full weights and14 source motions are retained. The first standalone Godot22m diagnostic was self-rejected for inflated cloth silhouette, armor/cloth penetration, obscured skirt armor, an insufficient helmet and nonclosed spear grip. It is not gameplay or an accepted soldier. Complete costume/armor construction continues from the owner's reference, not a recolor of source18. Ordinary spears remain without tassels; the white hero/horse is a direction, not a fixed approved protagonist.

Next: finish coherent whole environment and complete character sources, inspect them at genuine normal-camera pixels, reject structural failures internally, then integrate the same sources into the actual Battle and repeat native2K/4K stills and original-speed action evidence. Preserve authoring source, exact runtime identity, failed attempts and recovery commands. Shared3D versus directional-animation sprites/hybrids remains an actual comparison to perform, not a representation decision already made. No new installation candidate, full-army graphics result or M5 test is claimed.


## 16. Reproducible local-rendering tooling saved independently (2026-11-15 11:21 UTC)

[Source commit f7c6d8e29124221f3982fc57f98ec44f4f30c2ba](https://github.com/haohongfei2001-png/luanshi-game/commit/f7c6d8e29124221f3982fc57f98ec44f4f30c2ba), branch `dot/local-surfaceless-render-tooling`, is based directly on unchanged main `248d26aefbb8dfe7973141a63b40f3a220f0edc0`. Its exact tree is `36c5760d86155da1cb3c99b83523433b9ac3d15c`. All15 added UTF-8 text files under `tools/local_surfaceless/` were verified against the remote Git blob identities, totaling177,155 bytes. No assets, geometry, image, archive, binary, stored save, private report, workflow, main merge or new PR is included. The exact commit has zero observed Actions runs. The geometry publication pause is unchanged.

The folder provides the separately hash-pinned surfaceless and tangent patches, portable preparation/build/resource guard, normal-main-scene proof, pixel QA, small tests and MIT/third-party notices. It requires existing dependencies and a separately verified official archive; scripts do not install packages or silently fetch a renderer. The README gives exact reproduction commands. Fresh output directories and exclusive file creation protect original baseline binaries. HOME/XDG are isolated. Full engine compilation was not repeated for packaging; original successful engine and SceneTree evidence remain section15's results.

Read-only review found and actually reproduced one guard defect before publication: a leader could exit after SIGINT while a same-process-group descendant kept running. The final guard now checks and cleans only its own newly created group on stop, timeout, normal leader exit or monitoring failure. Remaining descendants prevent PASS; INT/TERM/KILL escalation continues even after the leader exits. Four negative scenarios with deliberately signal-ignoring descendants passed, while separate control processes stayed alive. The coordinator independently reproduced the original timeout and normal-leader-exit scenarios against the final code; both correctly stop the descendant without affecting unrelated work. Six small tests, Python/bash syntax checks, exact upstream zero-fuzz patch application/reversal, and retained primitive-image positive/negative QA pass. Final guard SHA256 is `6816c9175d979d95d10a0f4fc98d5443098166b2c5124c9a77084c5eeca041c3`.

This preserves the ability to run actual local Godot inspection without mistaking dummy headless execution for rendering. It is **not** a new game-art or performance result. Read section15 for the latest complete HF08 game pictures and their ART_FAIL verdict. New whole environment and character authoring continue locally with rejected structural/character diagnostics retained; neither is accepted. A bounded alternative directional-sprite quality trial is also being tested at normal gameplay pixel size, not selected as the final representation. No normal-speed new whole-scene footage, complete troop set, new macOS package,512-per-side visual acceptance or M5 result is claimed.


## 17. Art-first continuation, whole-scene and character failures retained (2026-11-15 13:00 UTC)

The owner's latest priority is **“你先把美术弄达标”**: make the art meet the target first. Long CPU, 512-per-side and new Mac performance work is deferred. Keep only the small rendering and source-integrity checks required for actual art production. Main remains `248d26aefbb8dfe7973141a63b40f3a220f0edc0`; PR67 is still draft at `1cfda095b05a78dfe89da6f2ddd8f8cb89819180`, verified again before this update. No game default, RC24/RC25, release or acceptance status changes.

### Actual whole environment, not a playable art candidate

A new complete author scene has now been rendered in actual Godot at native 2560x1440, internal scale1.0, measured camera-to-feet distance22.000m, pitch45 and FOV50. It combines continuous riverbed/shallows/banks, the road, a structural timber bridge, thick masonry arch/gate, adapted complete native roof/eaves/beam source, original full tree/rock dependencies and a first vegetation community. This is a local author-scene diagnostic with an explicitly rejected source18 scale actor, **not new Battle integration, a rebuilt army or acceptance**.

The P3-07 raw frame was captured at12:45:25 UTC, 7,554,106 bytes, SHA256 `d42ebe1adfb52b7c2cbf9bc2b8fb4d5577835b2e86340e1575c58b72ef81309a`. It took84.62 seconds to complete the guarded capture, with observed peak RSS about2791MiB. Host/renderer remain Linux AMD EPYC9V74 and Mesa llvmpipe software; this is not an FPS measurement, Mac GPU result or M5 test. Exact source/dependency closure, raw picture and failure records are retained privately.

**ART_FAIL.** The river's previous double-lighting was corrected and the bed/depth became legible, but that does not make the image acceptable. Grass reads as dark dots, the broad bare banks and forest lack convincing ecological layers, materials are not yet coherent, and composition is structurally wrong. The old author constraint left only4.9m between bridge exit and gate, instead of the actual bridgehead battle apron visible in the target. The next complete layout is being rebuilt with a real approximately16–18m deployment/fighting apron, a widening then narrowing military road, continuous riverbank/grass/shrub/forest regions and corresponding source support. This is a change to world geometry, not a camera trick or same-geometry A/B. A complete original wide-leaf grass source and its full material bake replace the rejected needle-grass approach; counts and source provenance are not art acceptance.

The previous current-source wall material had also accidentally reused an already rejected slate choice, and old tree derivatives had removed original normal/ARM maps. Those mistakes were identified and separated from the original professional sources. Do not infer that every source was intrinsically poor from a damaged conversion, or that retaining an original source guarantees quality.

### Whole character, not more roughness adjustments

Complete character14b produced actual normal22m and close diagnostic images in two poses. The normal relaxed image at12:41:31 UTC is79,497 bytes, SHA256 `db9ebf8d87daac9642247d9d2e5c37f86eb9273d4e884516f9c9320099259567`; its close diagnostic SHA256 is `850ca2bef8e577586cef60c309c98b50760f420561400c1a3ebd8fa0d479aa13`. **Both poses and the whole outfit fail art review.** These are not normal-speed animation, combat or a final soldier.

Two source regressions were separately corrected: mesh joining had redirected the lamellar texture to the wrong UV channel, and the offline cloth process had saved a30fps scene despite120fps source curves. The corrected separate native source restores120fps, with all14 original action-curve hashes unchanged. Failed sources are preserved; no slowed full-action asset was shipped or integrated. Those corrections establish source integrity only.

A same-topology garment comparison isolates another real conversion problem: nearest-body weight transfer can assign sleeve points to torso/leg regions and adds visible sharp waist/skirt deformation. The original garment binding is more continuous but still intersects in the tested poses and its wide long-robe cut is not the approved military outfit. It is therefore not accepted as a shortcut. Complete garment fit, silhouette and semantic deformation must be authored together.

Independent review also finds that most cloth, trousers, boots, wraps, helmet and wood still have uniform base-color materials, despite high roughness. The professional garment import had cleared original material assignments. Further roughness changes or increasing mesh detail cannot supply the missing medium-scale folds, seams, layered garment relationships and cloth/iron/leather content. The next whole-character pass addresses these together. Ordinary spear tassels remain absent; fixed hero/story decisions remain unapproved.

### Alternative representation and honest capture limits

The bounded directional-sprite experiment is retained as an alternative, not rejected in principle. Its four-direction static and single eight-frame walk candidates reach readable normal-sized pixels, but identity, foot contact and natural gait do not yet pass. A first fixed-rate encode was rejected because capture was slower than the assumed rate. The corrected wall-clock run captured only17 of32 phases; the retained variable-frame-rate file follows actual timestamps and is explicitly **INCOMPLETE_CAPTURE**, not a complete original-speed action demonstration. No interpolation or invented intermediate frames were substituted.

The eventual route may use shared3D, deterministic multidirectional sprites or a hybrid. Baking the current failed3D mother or freely regenerating independent poses does not solve art consistency. Establish one coherent whole-character mother first, then prove actual directions, held weapons, movement, contact, shielding, hits, riding and mass battle without reducing simulation.

### Narrow publication and recovery status

The owner's specific authorization for the historical HF08 geometry fixture was fulfilled and verified at [49d8d3c6957f9ea2b913382c7cdc84245025ce5c](https://github.com/haohongfei2001-png/luanshi-game/commit/49d8d3c6957f9ea2b913382c7cdc84245025ce5c), branch `dot/hf08-approved-geometry-fixture`. Its225,624-byte XZ expands to the exact1,287,052-byte JSON, SHA256 `28f93aecc08a099b06aae9c70bb5ce070653a1850b0417baa3493f93a5e9b753`. Only that fixture and explanatory README were added. This is not permission to merge PR67 or publish the held complete HF08/new visual asset payloads.

Closed generated import/tree caches and four earlier native character sources were safely archived with whole-file hashes, complete archive verification and actual restore drills before local redundant copies were reclaimed. All unique data, originals, failure evidence and recovery instructions remain preserved. Old cached scenes need the documented restoration step before replay; do not claim every old import cache is still installed.

Continue from the newest sole-writer authoring state, not an old table in this document. Do not repeat or overwrite current work. The next meaningful milestone is a self-reviewed coherent new battlefield and complete person at actual gameplay pixels, followed by integration of those exact accepted sources into the real Battle. **No new playable art pass, new macOS candidate, full-army visual acceptance or M5 result is claimed.**


## 18. New whole scene and complete character viewed together; still rejected (2026-11-15 13:50 UTC)

**The whole image remains ART_FAIL.** The owner has not accepted a rebuilt environment, a complete new soldier, an installation package or a playable art candidate. Art-first production continues. Main `248d26aefbb8dfe7973141a63b40f3a220f0edc0` and draft PR67 `1cfda095b05a78dfe89da6f2ddd8f8cb89819180` were reverified before this checkpoint; no merge or source promotion is included.

### Actual combined whole-source picture

P3-10 now displays the new complete character17 in the new whole author scene, rather than the old source18 scale actor. The actual Godot PNG was captured at13:47:35 UTC, native2560x1440, internal scale1.0, true camera-to-feet22.000m, pitch45 and FOV50. Raw image:7,180,798 bytes, SHA256 `76e00a63ea7f0f35c077c39acc22b0d9460cad68eca9e32a6c720d63bdbcbbcb`. The complete actor GLB is SHA256 `ec04b49ea6660eaf155bfb1bbac6cb4ce46aab6191fd8a1c51265aa89651eef5`; the whole authored dependency closure is `f3eb5a3acaa576f843da597554cab422dde524f4eaae14d7a260894b601bdc86`. Exact source and failure evidence remain frozen. This is **actual author-scene rendering, not Battle integration, army replacement or gameplay acceptance**.

The scene retains a real18.9m bridgehead fighting apron. New work includes a reauthored coherent broadleaf crown using the original branch structure, seven complete native grass/clover source variants, root-zone communities and revisions to the shore and military-road boundary. The derived crown is explicitly new artwork, not an unchanged original professional asset. Geometry count, complete source provenance and correct foot support are not visual approval. The new actor projects to46.85x97.78 pixels in this whole scene; its lowest vertex and the exact visible support triangles agree within approximately0.5 micrometres.

The coordinator and environment author independently reject the actual whole image. Vegetation reads as an excessively bright green carpet beside dark, heavy tree crowns; the material values do not form a coherent natural scene. Road and banks still read as broad regular bands and a uniform platform. Rocks remain too much like placed props, and the large gray masonry gate lacks the target's distinct stone foundation, earth/brick wall, wood construction and ceramic roof hierarchy. The next complete production pass addresses those relationships together. Merely reducing green saturation, increasing plant counts, changing exposure or retaining a source unchanged is not an acceptable completion criterion.

P3-09 and09a failed their internal3GiB process guard before producing images. The separately bounded09b attempt completed and was visually rejected. Based on its observed first-draw memory requirement, P3-10 used a one-run4GiB process guard with at least2GiB global available RAM,350MiB disk reserve, an exclusive heavy-work slot and180-second limit. It completed in92.158 seconds, peak sampled RSS3,682,746,368 bytes, lowest global available RAM2,938,675,200 bytes. A nonfatal global-script-cache error remains recorded; this is not a zero-error claim. These authoring capture figures are **not FPS, gameplay performance or a hardware acceptance result**. Renderer remains Linux AMD EPYC9V74 / Mesa llvmpipe software, not Mac GPU or M5.

### Whole-character restoration and an actual consumer failure

Character16 preserves five complete native garments, original UV/material regions, editable semantic cage binding and original surface texture content. Its whole pictures were rejected because the newly built armour was fitted to the body rather than the dressed silhouette and disappeared into clothing. Character17 restores visible chest and skirt armour but follows clothing folds too closely, distorting the plate arrangement. Further work replaces that relationship with coherent regional load-bearing surfaces, not an indiscriminate inflated shell. Upper-chest/strap organization, footwear, helmet/material quality and the whole normal-pixel silhouette still need art review.

The apparent broken second grip was separately traced through saved Blender source, exported GLB and actual Godot bones. Saved/exported palm-to-shaft distances remained about2.38cm, but switching the diagnostic player's animation left old bone poses and produced a9.86cm gap in Godot. Explicitly resetting all Skeleton poses before applying the selected clip at time zero restores the intended high/low grip in the actual17c pictures and in P3-10. The17c normal22m raw image is82,205 bytes, SHA256 `206e9d55bfc0bca9b9ddf940e1c1c7ae1fea0ed4cd67cb19b92b62cd3ca7442a`; the close diagnostic SHA256 is `6061c21c863a2265e03d2ff1a9b410a3edbe16bcbaecf46ea7b5687b8ef1c1c1`.

This fix is verified in the **new-character diagnostic consumer**, not a claim that all existing game animation transitions have been changed or validated. Only the recorded static poses are established; a correct grip measurement does not prove natural fingers, continuous motion or accepted art. Character18 whole armour/garment/material production continues from frozen17; do not alter the frozen input already used for the combined scene.

### Deterministic2.5D alternative retained as a failed implementation

A bounded complete single-texture2.5D skeletal mother was actually implemented and rendered, reusing one existing static atlas cell without another image-generation call. Its continuous textured mesh, deterministic hip/knee/ankle controls and fixed support feet avoid changing identity or inventing independently generated animation frames. Nevertheless, its actual motion is a paper-puppet-like in-place step with compressed trouser/boot transitions and pointed skirt distortion. A single visible surface cannot supply missing hidden limbs or independent cloth occlusion. **This implementation is rejected**, not declared a natural walking character and not used to rule out properly authored layered2.5D or hybrid representations.

The retained native2K variable-frame-rate file contains15 actual wall-clock frames over3.585 seconds, with0.241–0.272-second capture intervals and less than0.483ms encoding timestamp error. There are no interpolated or invented frames. This is about4fps image readback, not fluid8fps footage, translation walking,360-degree coverage or a gameplay benchmark. Source, actual times and failures are retained; that bounded trial has ended rather than continuing to adjust the same inadequate single-surface puppet.

Continue the two existing whole-environment and whole-character writers, with one heavy rendering process at a time. Keep current sources, original assets, failed attempts and recovery evidence. No additional paid service/account, user computer, formal release, fixed literary story, held asset publication or PR67 merge is authorized by this checkpoint. The exact historical HF08 fixture publication in section17 remains separate. **No new accepted game-art result, full-army replacement, macOS candidate or M5 test is claimed.**


## 19. Whole-source failures preserved, camera authority restored (2026-11-15 14:35 UTC)

**ART_FAIL remains the whole-image verdict.** Main and draft PR67 were rechecked and remain unchanged at `248d26aefbb8dfe7973141a63b40f3a220f0edc0` and `1cfda095b05a78dfe89da6f2ddd8f8cb89819180`. Art-first work continues; no default replacement, merge, RC promotion, installation candidate or release is included.

### The22m pictures are controls, not the new primary-camera art gate

Re-reading the current main [owner camera authority](OWNER_MOBA_CAMERA_AND_ART_AUTHORITY_20261114.md) exposed an overly rigid continuation assumption. The owner's primary reference is **Wild Rift's actual character-to-screen relationship**. Historical orthographic size22 was never a physical22m distance and does not prescribe the new camera. The recent explicitly measured22m perspective pictures remain useful fixed controls, but calling them the required normal-gameplay scale would be wrong. Their roughly98–102px adult figures at1440px image height must not become a hard ceiling or a way to fit an entire army into one frame.

Preserve those originals. Separately calibrate the primary playable camera against trustworthy official gameplay, record the actual character pixel bounds and all projection/world matrices, and label comparisons with changed cameras honestly. Reference-derived screen ratios are estimates, not published Riot FOV or distance constants. Do not enlarge the camera view to conceal inferior models or present a camera change as improved geometry. Total battle strength, offscreen warfare and the20/100/250/512-per-side validation requirements remain unchanged.

### P3-13: new whole structure and full-source material content, still rejected

P3-13 includes1004 authored masonry block faces combined into one mesh, real bevels/recessed joints/corners, a newly organized branch-layer leaf canopy, and the frozen complete18b soldier. Professional original trunk/branch sources, original material maps and previous failures remain retained. The new canopy is an explicit authored derivative, not an unchanged professional tree or a quality certificate.

The actual Godot control PNG was captured at14:30:02 UTC, native2560x1440/internal1.0, true camera-to-feet22.000m. It is7,431,368 bytes, SHA256 `52fd5160c293f71d145f4946673a0564b90f99dc594b5ca7823976f31d2bc0dc`. The18b runtime actor is `62beaacacfe6905fba6554547b8c464ccb3cfa23c0067339b8e59098c311351e`, projecting to47.95x98.217px in this scene, not the separate diagnostic's101.53px. The150-file,469,080,117-byte dependency closure was independently rehashed without mismatch; its manifest SHA256 is `9a1d4038a6b4a7786682d88df0c76586999cc8e4e1e3274a4217e3e1b7f8a75f`.

The guarded process completed in118.445 seconds with exit0, sampled peak RSS3,776,679,936 bytes and minimum global available RAM2,654,208,000 bytes. A nonfatal global-script-cache error is retained. These are authoring-process measurements on Linux AMD EPYC9V74 / Mesa llvmpipe software, **not gameplay FPS, GPU/Mac performance or M5 evidence**. This is still an author scene, not new Battle integration or a complete army.

Independent visual review rejects the whole picture: a broad yellowish ground carpet and sparse thin grass, overly regular shore, isolated boulder props and smooth road still fail the target's natural, coherent environment. Tree and masonry construction changes are real but not enough. New integrated structure, source content and composition continue to be authored; counts, provenance and correct foot support do not imply art acceptance.

### A confirmed material-contract mistake, not a substitute for art rebuilding

The actual GLES3 engine source shows Compatibility decoding user ALBEDO/EMISSION from sRGB after the custom fragment stage, then encoding the lit output. Earlier custom environment shaders incorrectly passed raw linear pigment constants into that interface. The resulting repeated decoding darkened vegetation and wall materials. P3-13 corrects the single decode/mix/encode contract with the same Sun/Sky, without changing the engine or exposure.

A second content loss was also corrected: reducing complete original grass/forest RGB maps to a single hue times compressed luminance erased the source's bare soil, litter and plant relationships. Current source restores original multichannel material content with explicit restrained grading. Neither fix explains away the remaining structural failures or establishes an art pass.

The separate actual vertex-domain readback sampled0 of12 expected positions. **It is NOT VERIFIED**, despite zero reported error in an empty sample set. Preserve that failed audit and investigate position matching once without another render; do not relax navigation or claim a data-contract pass. Frozen13 inputs remain unchanged.

### Complete characters19–20 rejected; exact18b native recovery preserved

The complete19 character was actually rendered under the shared production lighting in both static poses. Its larger support construction became thick backpack-like shoulder pads instead of fitted armor and clear narrow load-bearing straps; footwear and helmet hierarchy also remain unfinished. The full source and failed images are preserved. Continue whole torso/shoulder/helmet/footwear construction, not another isolated roughness or color adjustment. A subsequent20 actual control removes the broad shoulder pads but reveals the new lining crossing in front of the chest plates; that complete fitting layer is being reworked against the armor surface and thickness, with the failed20 source preserved. Hands and the untasseled spear's established static axis remain intact; continuous movement, attack, contact and armor deformation are not yet accepted.

The exact18b native source, SHA256 `1691f4c5bf6272bd0983a33a5c364245d52fedd9745b555cc7db15bd559cfeea`, has a persistent internal recovery backup with17 actions at120fps, full163-bone rig,32 packed images and the exact remaining external old-material image. Its two-static-pose GLB is clearly separated from the full native motion source. The102,920,824-byte archive SHA256 is `9c4d56cc10816374214cfae96fdf343c063a29619236d66943ba20fe2f19e25c`; every archive entry passed CRC/decoded-SHA validation and the largest native file passed actual extraction/readback. No current source was deleted. Thirteen closed earlier native files were separately archived, verified and restore-tested before redundant local copies were reclaimed; all unique work remains recoverable.

Next: continue the existing whole-environment and whole-character writers, establish the proper primary-camera scale, self-reject whole-frame failures, then validate the same sources in real Battle once coherent art exists. Use one bounded heavy rendering process at a time. No owner art pass, full-army replacement, new macOS build, M5 result, public held-asset upload, PR67 merge, new fee/account, user-computer access or fixed literary story is claimed or authorized by this checkpoint.

## 20. Proper screen-scale trial and whole-motion defects verified (2026-11-15 15:08 UTC)

**The entire rebuilt image remains ART_FAIL.** Main `248d26aefbb8dfe7973141a63b40f3a220f0edc0`, draft PR67 `1cfda095b05a78dfe89da6f2ddd8f8cb89819180`, and the preceding recovery head `195a66204d2cbbaa15dc97be518c48761e6aac6b` were reverified. This update changes recovery documentation only. No art, gameplay, package, default replacement or M5 acceptance is implied.

### Actual new main-camera whole scene

P3-14 was captured by actual Godot at14:54:38 UTC, native2560x1440/internal1.0, true camera-to-feet15.000m, pitch45/FOV50. Its frozen complete18b actor projects to72.73x144.19px, approximately10.01% of frame height. Raw PNG:7,922,674 bytes, SHA256 `ab9d122d9644a462740c093dea981fd6e6db9f477707ddd5b511aa251aec9cb1`. The152-file,478,630,372-byte source closure passed an independent complete rehash; manifest SHA256 `e9f8b3aff14388f4e73dd4b503493f9e08496971147d25a6ab7e01b04ca3c26c`. It is an author scene, **not Battle or continuous player-controlled gameplay**. The separate newer20b person was not substituted during this running capture.

The9–11% frame-height trial is a production choice informed by two official Riot published game images: the [Ionia map update](https://wildrift.leagueoflegends.com/en-sg/news/game-updates/patch-7-0-aaa-aram-and-rift-updates/) and [Irelia controls development article](https://wildrift.leagueoflegends.com/en-us/news/dev/dev-irelia-dances-her-way-to-wild-rift/). Those images do not certify an uncropped default player camera or publish FOV/distance. Do not claim these trial values are Riot constants. Keep old22m pictures as controls;14 versus13 changes both scene source and camera and is not a same-state A/B.

14 preserves the complete acquired original tree topology/UV/material maps, with a documented branch-layer normal/tangent derivative, and introduces complete rooted plant communities and new shoreline geometry. Those facts are not a visual pass. The actual image still has a high-frequency yellow grass carpet, evenly distributed roots, unnaturally cut narrow banks, disconnected rocks, overly smooth road and an incoherent fortress/landscape relationship. Coordinator and environment author both reject the whole frame. Next15 rebuilds continuous riverbed, sediment bays, rock shoulders, military-road cross-sections and ecological regions together rather than scattering detail over the same weak composition. It must not merely restore the previously rejected13 leaf forms or adjust exposure. The18.9m battle apron and real adult scale remain preserved.

The actual process exited0 after166.918s, sampled peak RSS3,926,114,304 bytes, minimum global available RAM2,264,100,864 bytes; the nonfatal script-cache warning remains recorded. Linux AMD EPYC9V74 / Mesa llvmpipe is software rendering, not GPU/gameplay FPS or Mac/M5 evidence. The importer-domain audit now genuinely matched12 of12 samples one-to-one: maximum position difference3.274mm, color error0.003157 within oneRGBA8 step, UV2 error0.00001975. This is imported-array evidence, not raster correctness or changed navigation tolerance. The previous zero-sample audit and timed-out probe remain failures in history.

### Complete20b original-action keyposes and the next whole outfit

20b corrects the lining/plate layer order and was actually viewed at15.5m: standing152.66px, original Walk keyposes134.31/137.63px and Thrust141.38px. Normal images are native2K/internal1.0. Motion GLB SHA256 `8efd67fe87d2eaa1dd67e6654dd73ea2e3af661541cf10bd6d3cc746b379b11c` retains the same geometry/material binary prefix and matches all163 bones plus the root rest transforms before adding original-curve30Hz samples. Original Walk1.333s and Thrust0.700s timing is not retimed. These are **seeked original-action keyposes, not continuous wall-clock movement, foot-speed calibration, real combat or motion acceptance**.

The images expose stiff lower armor, floating shoulders and unreliable grasp. An independent actual8-weight skinning analysis matches Godot wrists within0.685 micrometre and shaft bounds within1.016 micrometres, so substantial finger penetration is not a coordinate-conversion artifact. A fitted-cylinder approximation alone cannot establish anatomically correct closure; a thumb need not touch bare shaft if it naturally rests against another finger. No blind uniform tightening or numerical contact-only pass is authorized.

21 therefore reconstructs the complete shoulder support and independently hanging front garment/armor panels with coherent lining, borders and ties, preserving original full-body and professional garment weight structures. Its grip candidate search may reject all candidates without modifying the action. Evaluate the whole person and action line at the established normal pixels, not by zooming farther in or reporting isolated finger numbers. At this checkpoint21 has not yet produced an accepted actual picture.

Closed19/20 failed native sources were verified, actually restore-tested and persistently backed up before redundant originals were reclaimed. The138,324,597-byte archive SHA256 is `ed7b5edd219c2515939f94347a36ebeb7baba8d1d0e4032d0c1bd7eb6f4ea0de`. Historical19/20 and20b source-building replay requires restoring those exact relative paths first. Current20b,18b, earlier mothers, code, source materials and images remain intact. Failure archives are not self-contained texture packages or playable builds.

Continue the two existing whole-art writers with exclusive bounded heavy rendering, truthful self-review and recoverable source. Do not start a new long performance matrix while whole art is unresolved. Held public assets, PR67 merge, extra fees/accounts, the user's computer and formal story remain outside this checkpoint. **No new accepted whole-game picture, army replacement, macOS candidate or M5 result exists.**

## 21. Whole-scene failures preserved, original-source hypotheses tested (2026-11-15 15:59 UTC)

**Entire art remains ART_FAIL.** Main `248d26aefbb8dfe7973141a63b40f3a220f0edc0`, draft PR67 `1cfda095b05a78dfe89da6f2ddd8f8cb89819180` and preceding recovery head `bb5a9652a1b250967c73795a4668f579642ffd48` were reverified. No held asset payload or PR67 merge was attempted. The owner's instruction remains to get the complete art right first, not to substitute more simulation tests or isolated shoulder variations.

### P3-15a exact whole scene and the actual bridge route

The first15 process produced no picture: the global available-memory guard stopped it after78.28s. Preserve this failure. The recovery did not lower visual quality or raise limits: four unreferenced tree accessors and unused material/image records were removed, while every used primitive attribute/index, normalized active material/image/sampler, node and scene was independently verified identical. The original source remains available.

15a then completed actual native2560x1440/internal1.0 capture at15:25:28 UTC:104.256s, exit0, sampled peak RSS3,850,436,608B, minimum available RAM2,339,110,912B. Raw7,016,175-byte PNG SHA256 `4fe9228f7d4182ea54957d75b82fc5a42601e67f0cd91c5b5254d2fd9e968cfd`. The same complete20b actor is150.36px high at true15m/45deg/FOV50. Separate same-source bridge-front, bridge-center and gate-front native2K views also completed in113.415s. They establish that the source includes a continuous bridge/water/gate route and18.9m battle apron; they are **static author views, not traversal or Battle**. Bridge support was queried from the actual source triangles, not an outdated landmark elevation.

All four whole views fail. Regular grass islands, smooth channel walls, repeated rock display spacing, overly simple bridge-to-bank transitions and immature fortress structure are not a coherent natural battlefield. Procedural leaf balls and elliptical grass patches are stopped as the production direction. The next whole terrain source must establish continuous rock heads/sediment bays, road crown/drainage/shoulders and rooted ecological transitions. Six mature rock pieces must be transformed once from their original3x2 inventory display into authored embedded geological structure; random scattering is not the replacement method.

The exact167-file render closure and additional original editable inputs, licenses, engine and approved references were persistently backed up in a346,675,800-byte recovery archive, SHA256 `f3ca97e42a2f7685bca7535a8c0263fe7a76d14e1ed9b102b4d70bf937f152d2`. All288 logical files passed decoded-SHA/CRC verification and all current originals were rehashed after upload; the largest60,709,812-byte entry passed actual extraction/readback. A checked restore helper refuses different existing content and path escapes. Its fixture restore tests passed; the full347MB bundle has not been restored end-to-end. This archive is exact author-source recovery, **not a portable game, macOS installer or full native20b dependency package**. Mixed licenses remain distinct; do not describe every input asCC0.

### Complete person22/23, not another accepted soldier

22 and23 each produced six actual Godot original-action keyposes.22's inflated shoulder strips and rounded plastic highlights were rejected.23 has local sleeve/upper-arm following improvements but still fails as a whole: helmet/collar/shoulder support, chest-to-waist and long garment hierarchy, natural material weight, grasp and complete stance do not match the approved normal-view target. Coordinator and character author both reviewed normal and close pictures. **Stop treating serial shoulder-panel changes as the whole-person production method.** Before another large export, define the complete helmet/neck, torso/waist, layered long armor/cloth, trousers/boots and natural full-body weight/weapon relationship together, preserving the full professional body/garment source and rig. Do not solve it by zooming the camera or changing exposure.

23 retains the original motion curves. Its actual wall-clock Walk/Thrust attempt yielded only five native2K frames: three Walk and two Thrust, roughly1.1–1.2 seconds apart on software rendering. This is severely incomplete motion evidence, not smooth original-speed footage. Preserve the original timestamps; do not interpolate, retime or label it gameplay/performance acceptance. Actual new whole-scene Battle, full-army replacement, attack/hit/riding footage and M5 tests remain missing.

Closed22 native69,661,189B, SHA256 `253bffb83471415f13c3e60bc08eda07f59c070605053cd824bd90f326a98c8a`, was uploaded and then independently materialized back in full from persistent storage. Only after exact size/SHA confirmation and the writer's confirmation that23 reads21, not22, was the redundant local native reclaimed. Restore that exact file before historical22 source replay. Current21/23/20b, all shared inputs and failure evidence remain intact. Actual20b dependency inspection now confirms29 images/28 packed, one retained external lamellar image, no linked libraries and18 actions at120fps; this is not inferred from18b's different inventory.

### Rendering hypotheses, not an art certificate

The untouched original tree's leaf material actually imports as Godot Depth Pre-Pass4, not no-depth simple Alpha. A same-source, same-camera, original-PBR opacity-only A/B changed it to Disabled0. Both actual frames retain the sparse fine crown. Opacity mode is not the main explanation; do not revive procedural leaf balls or claim that a professional license certifies useful final-pixel form. The original source has44,168 complete leaves with a median maximum span4.14cm, and no verified botanical species name. Existing complete native forest mothers are being examined without new downloads or destructive reduction.

A separate minimal actual renderer test reproduces fine diagonal stripes on a completely untextured flat ground. Turning off only that plane's shadow casting removes the pattern while preserving directional light and received shadows. Raising the directional depth format from16 to24 bits (the actual GLES3 false-setting path, not32 bits) does not fix it. These tests identify the self-shadow chain, not a license to disable all real terrain shadows or declare the whole image improved. A bounded independent bias test also found depth bias0.1→0.2 ineffective. Normal bias0.6→1.2 reduced flat-ground stripe variation by86.4%, with box shadow-mask overlap0.9918, but left residual patterns and did not validate thin weapons, feet or sloped terrain. It is only a next actual-scene candidate; production settings remain unchanged. This rendering investigation must not replace the complete art reconstruction.

Continue the existing two art writers, exclusive resource guards and complete actual-image self-review. Preserve the historical RC24/RC25 rollback sources, old-save compatibility and offscreen real combat. No art approval, new playable/macOS candidate, M5 result, new paid resource/account, user-computer access or fixed formal story is claimed.

## 22. Verified continuation: complete 24/24b, whole-source 16, and intact native forest recovery

The latest owner priority remains **make the art meet the accepted reference first**. The entire battlefield and character image is still not accepted. No milestone below is a new playable candidate, complete-army replacement, original-speed action movie, MacBook Air M5 result, or authorization to merge PR #67. Main remains `248d26aefbb8dfe7973141a63b40f3a220f0edc0`; the work continues in isolated production sources and this draft recovery record.

### Actual complete character, not a shoulder-only patch

Complete24 was authored from the preserved natural-body/full-garment source and exact20b base, rather than continuing23 shoulder variants. It retained the original163 body-bone identities and existing curves, adding six explicitly named experimental skirt auxiliaries. Whole cloth cuts, gravity/body-and-pants contact, torso/skirt armor, puttees, shoes and a full-body spear carry were regenerated together. Actual native2K Godot key-pose frames exposed a poor whole-layer relationship and a white material-export fallback. Complete24 is **ART_FAIL**, not an accepted intermediate body.

Complete24b then changed the shared whole cloth/armor envelope and suspension, whole puttees and carry anatomy without rotating the actor toward the fixed camera. It explicitly bakes the actual source material graph into full-resolution base colors or constant factors instead of letting unsupported node combinations export white. The first full-array bake exceeded the existing1GiB process guard and stopped at12.29s without a new native file. A block64-row implementation preserved the source pixel content, resolution and same guard; it completed in71.64s with769,097,728B peak RSS. It did not solve memory pressure by lowering texture resolution or increasing the limit.

- Complete24 native:82,577,633B, SHA256 `3e54fccc0ec931726e474892a52172e5081f65174c17443e40462f80cf95647e`.
- Complete24b native:111,302,519B, SHA256 `8b0eef5aac2ffda87956cf43c45c8563a1d71fd449c15085027084e3e6951aef`; actual manifest40/40 images packed.
- Single24b runtimeGLB:52,185,460B, SHA256 `27c4c1fae9c19f7888b89cba59e98842d9d62e01c4411ff4343548768d3f452a`;19 surfaces/four experimental clips. Export completed80.69s, peak1,004,212,224B. Eleven visible material semantics, including the shared shoe alias, matched the expected factors and full embeddedPNG RGBA hashes with zero mismatches. This is export correctness, not art acceptance.

Six actual native2560×1440 Godot author-scene key-pose frames were captured at16:41UTC. Main-camera radius to feet15.5m, pitch45°, FOV50; measured body height150.02px. The separate4m frames are diagnostic close views and are never substituted for normal-camera evidence. Same-camera24/24b comparison now shows the complete spear and anatomically higher/lower hands more clearly, without the white export fallback. **The whole outfit still fails**: rigid skirt-board construction and thick side cloth, inconsistent armor/sleeve/puttee form, and visibly open/unresolved fingers during the thrust. Palm-to-shaft distance alone does not validate a grip. The next full-person revision must solve coherent overlapping armor/soft-cloth/leg layers and actual articulated hand semantics, not add isolated plates, zoom the camera, or change exposure.

These are genuine Godot authoring scenes on LinuxEPYC/llvmpipe software, not the real `Battle` scene or smooth wall-clock action playback. Complete24b has not replaced the rejected frozen20b actor in the whole-world authoring scene. Ordinary spears still have no tassel; a formal protagonist or story remains unapproved.

The exact previously extracted UAL member record has now been recovered and independently rehashed. Manifest SHA256 `987fb8f8f1bad8633463f2bdec75fa35730f854cfa634a762be27cae8297b41c` locks the15,904,933B CC0 package SHA256 `cc73fc4e495b82958207316596317a3f40b9fa38065bde1027937452da537724` and its7,618,436B in-place member SHA256 `69591853d817488edaa8fd9bf8fc1d821eaeaf789f8627b3cd23b41c4ed67997`. This closes the missing member-identity link; it is not a new ZIP CRC check, blanket licensing of current packages, or a validated hand-retarget result. The unverified donor pose remains **OFF**.

### Whole landscape16 and professional source version recovery

The new continuous river/road/landform source and slope-following fortress/bridge bearing source have been generated together. The geometry file is30,539,488B, SHA256 `e000540cc8f671581a33db99c3c52c56489c71292541a5ac48eb956ee0d6263a`, with516 meshes. That initial output was explicitly geometry-only. Subsequent whole16 assembly froze210 files/389,846,702B, manifest SHA256 `3fdcb470d42380c3ac03355dd2dfb1d9a6601b16847cb6cf7e0fe456d508d530`, and now has one actual native2K Godot main-camera frame. The old15a whole image and procedural leaf-ball construction remain rejected.

The earlier Blender4.3 bare-tree images were not faithful pictures of the professional native forest mother. Read-only inspection identified61 undefined legacy Geometry Nodes, including the terminal leaf-instancing chain; source leaf prototypes, branches, libraries, nonzero densities and render visibility were present. The existing exact official Blender3.1.2 archive was restored after verified duplicate consolidation, with no new download. In the compatible version the undefined-node count is zero and the two complete original mothers produce31,968 and20,957 leaf instances. The26.02M/17.03M earlier triangle figures describe enabled **viewport-subdivision equivalent instances**, not actual runtime mesh budgets or final render triangle counts.

Two genuine native3.1 original-mother2K diagnostic pictures now exist,63.30s and49.24s respectively. Their restored crowns are dense hanging curtains; neither is accepted unchanged as a near-road tree. The selected editable young-tree mother was adapted with its intact trunk, branch structure, actual generated leaf positions and shared prototypes. Road-side clearance and original-fork negative space must be explicit, not an evenly cropped umbrella, random density reduction, or replacement leaf ball. Original mother data and both pictures remain preserved. These two original-mother pictures are source diagnostics, not game screenshots or proof of final quality. The subsequent runtime derivative retained24 shared prototypes and20,524 instances per tree. Its actual16,449,750 triangles per tree across21 trees is an explicitly unacceptable final real-time budget, not an inferred motherboard count. Keep the complete editable mother, but derive reversible actual-pixel LOD from original lower-level topology/normal baking rather than deleting trees or arbitrarily thinning crowns.

### Actual whole16 frame and method-level rejection

The actual2560×1440/internal-scale1.0 A frame was saved at16:53:49UTC,6,958,817B, SHA256 `bbe120141d93fe3c3c24f072fb0a20a931da5c8fcecddfc196d3cf0cd3a1e4ea`. Fixed main camera remains15m/45°/FOV50, frozen20b body150.36px. It is a full Godot **author scene**, not real battle. The run ended at104.379s/exit−15 when global available memory reached2,059,698,176B, below its2GiB guard; process peak3,678,961,664B remained below4GiB. A then-existing194MB temporary archival package in the shared RAM-backed temporary volume also contributed to global memory use. Do not misreport this as a process-limit violation or prove intrinsic hardware failure from it. That temporary package has since been safely reclaimed after independent persistent readback. B did not complete. **No whole16 A/B conclusion exists**, and the rejected whole scene will not be rerun just to obtain B. The A counters895,211,426 rendered primitives/3,052 draw calls include rendering work such as shadows and are not a1024-soldier performance test.

The coordinator and environment writer both viewed the actual A picture beside the accepted whole reference and rejected the **entire image**. Exact authoring causes are now identified:
- A walkable battle-width field also flattened the full corridor to road height and suppressed vegetation by97%, mistakenly making usable battle space into a broad bare road.
- The bank remained a sweep between two smooth cross-sections. Placed rocks did not establish the actual bank cross-section; distant macro-ridges did not repair the near-view uniform slope.
- The upper fortress face still used a flat surface with ground-dirt coloring and no masonry normal. A masonry region label was not masonry construction.
- An old stone-abutment box still exposed its2.40m top. Adding a separate lower buried bearing did not remove the original broad white bridgehead band.

Next whole17 must replace those old assumptions in one complete riverbank/road/fort/bridge source: low-grass traversable battle shoulders distinct from compacted tracks; rock-bearing slopes, slope feet and water-edge sediment forming the actual terrain; volumetric masonry/voussoirs, doors and timber construction as one building hierarchy; and a complete timber bridge/abutment seam. This is not a new tree, mask, color or lighting patch over16. Whole16 remains frozen with its image and failure record.

Complete-person25 likewise starts a new curved-waist whole-garment and continuous flexible row-support method, not another ring around24b's incorrect rectangular cloth core. The existing source-hand audit has proved that the old pose code omitted the entire thumb chain and24b restored that old finger basis. New hand semantics must include actual thumb opposition and full skin contact, while preserving original action data. The isolated semantic helper is a structure validator, **not a solved grip**. No25 native or image is claimed at this checkpoint.

### Recoverability and limits

The exact24/24b editable native stage, author-code snapshot and license/source notes have a verified persistent194,127,450B archive, SHA256 `f10b4dd6fe0d4493bb828ee4aebd4d6dd1223ee5d52cbc9a75c0f2236b16507e`. AllZIP CRC/member hashes and unchanged original sources were checked. Current24b remains in place. The frozen24/24b replay companion adds the final file list, original hand-rest data, UV helper, source cloth map and final reports; exact20b is separately preserved. Closed21 native,24 native and24 runtime were independently read back from persistent storage and SHA-checked before193,872,111B of local redundant files were reclaimed. Native24 was also actually extracted from the remotely retrieved archive and SHA-checked. Restore the exact old files before historical replay. This preserves editable results and recorded replay inputs, not a new release package. No public asset promotion is implied.

Closed23 native and two runtime files were each persisted and independently downloaded back in full. Only after all original/download byte counts and SHA256 matched, and the current writer confirmed no24b dependency, were156,463,860B of redundant local closed files reclaimed. Original23 images, code, reports and exact restore identities remain. Closed21/22 runtimes were handled with the same independent full-readback rule. Three other exact duplicate packages/scenes were replaced only by verified links to their retained identical primary bytes; no unique original was lost. Do not remove or write through their primary/alias paths without checking the recovery record.

The isolated shadow diagnostic also checked the normal-bias candidate on actual23 relaxed/thrust frames. Main foot/body shadows remained visible, but thin spear shadows weakened in some pixels and residual artifacts remained. This is not a universal terrain/lighting fix or production-default change. The attempted whole16 comparison retained the same frozen source, but B did not complete and therefore supplies no additional A/B conclusion.

Continue whole-scene and complete-person production under the exclusive heavy-job/resource guards. Preserve source/art failures honestly and produce actual whole-scene evidence before claiming an improvement to the battlefield. RC24/RC25 recovery, real/offscreen combat, old saves, held public asset actions and held PR #67 merge remain unchanged. No owner action is currently required for the independent work.

## 23. Actual whole-place17 and complete-person25: both self-rejected, source preserved

The owner's art-first instruction remains the controlling priority. Neither the following authoring scene nor character is an accepted battlefield or playable candidate. The approved reference is a minimum, not merely a color palette. No user screening or testing is needed to identify these failures.

### Whole-place17, actual native2K

Whole17 replaced the old corridor construction assumptions with a new complete landform, traversable living shoulders distinct from worn tracks, rock-bearing banks, a cambered timber bridge, and volumetric coursed gate masonry/deep arch and wing walls. The first geometry exposed a float32-coordinate deduplication defect; the invalid complete draft is retained. The corrected source closure contains205 files/422,730,428B; manifest SHA256 `608f32a7ea06b58fb56c6931c275aa38075b8b179d0833104af46254a7ec9e8a`. This is an exact local author-source identity, not a published game or runtime-navigation approval.

An actual Godot4.6.3 author-scene frame was captured at17:30:51UTC on2026-11-15: native2560×1440, internal scale1.0, unchanged true15m/45-degree/FOV50 main camera, frozen20b actor150.36px high. Original PNG8,308,654B, SHA256 `b7a45f61f299e1dac55d9a0a67da2d8a0111b2cdfab21f4048de92769a9ae0ad`. The complete process exited0 in110.651s, peak groupRSS3,665,698,816B, minimum global availableRAM2,452,287,488B and disk870,105,088B; no resource guard triggered. The retained global-script-cache warning means this was not warning-free. Actual domain readback matched12/12 samples. This is importer/material correctness, not visual acceptance.

Both author and coordinator viewed the actual image beside the accepted reference and marked the **entire image ART_FAIL**. The worn route and grass shoulders now separate, and actual masonry appears, but yellow-bright fine grass repeats across the image; the shore still reads as a smooth ribbon with a row of rocks; dense hanging crowns obscure natural branch structure; the broad bridge-to-gate field lacks the reference's coherent passage, bank/woodwork hierarchy and material clarity. Do not promote17 or call it nearly accepted. Same-source normal-camera bridge-approach/bridge diagnostic positions are next, followed by an integrated whole-place revision, not isolated scatter, color or light patches.

Reversible reduction of the original leaf prototypes retains original instance matrices and editable mother data. Four leaf meshes changed from808 triangles each to580/420/420/420 under a2.5mm sampled bidirectional surface-error bound. This does not certify exact silhouette equivalence or a sensible final realtime budget. Actual frame counters remain460,277,586 rendered primitives/1,830 draw calls, including rendering passes. They are not a1024-person benchmark or GPU frame rate. The renderer is Linux AMD EPYC9V74/llvmpipe software, not a Mac or M5.

### Complete-person25 and evidence-based whole-layer replacement

Complete25 rebuilt the measured waist, soft-cloth contact, continuous carrier and row-level armor together. The first native attempt stopped at the unchanged180s guard without an artifact. After avoiding redundant per-row dependency evaluation, the second saved a native source in78.35s, then hit a report-variable error: OS exit0 does not make that script clean. The actual saved native was subsequently reopened and independently checked during the necessary runtime export.

- Native25:117,319,792B, SHA256 `eab24a74b61842f051dbd58ac0e1e0699fc34b19fbe10ee016387a23b08ee61b`.
- Single runtime25:50,569,244B, SHA256 `bd573976401ad9acfb1fbd6ff307013c9c7caa5ef5a864a9f91078c3b238f7de`.
- Actual original163 body-bone names/rest/parent/length matched with zero rest error; six retained auxiliaries and60 explicitly new row helpers make229 total bones. Twelve runtime material-factor/embedded-pixel comparisons matched. These facts do not establish visual quality.

Six actual native2K Godot keyposes were captured at17:12–17:13UTC. The full character is **ART_FAIL_REGRESSION**: torn/disconnected-looking skirt, trousers visibly outside their covering, poor head/shoulder form and unresolved hands. It has not replaced20b in the environment. A copied preview-label replacement accidentally changed1024 to1025 inside guard arithmetic; the original script and samples are retained. Actual samples stayed inside the original limits; future scripts are corrected. This was not a deliberate guard relaxation or a reason to rerender the rejected figure.

Actual native/GLB row-frame audits found micrometer-scale head differences and the expected fixed bind basis, excluding a gross repeated transform as the main skirt cause. The carrier and iron are double-sided. Sampled actual layer checks instead found1,704 pants vertices more than10mm outside the carrier already at bind rest, and more in walk/thrust. The nearest-triangle method has edge limits, so this is not a complete collision guarantee, but it proves the layer envelope is wrong before motion. New25b therefore starts inside-out from the real full pants/inner clothes, then robe, thin carrier and iron sharing the same surface attachment. It does not hide holes by thickening or recoloring plates. New25b code exists; no new25b native or image is claimed here.

The default-OFF hand candidate solver now includes the actual thumb opposition chain and full skin evaluation. Four actual25 pose parity checks agree within0.351micrometer, and geometric unit tests pass. A real grip is still **INPUT_INCOMPLETE**, not solved: anatomical finger-pad labels and opposition axes require actual visual review before any candidate can be applied. The first small labeling batch encountered a real GDScript builtin-name conflict and produced no image; its failure is retained, the naming collision is corrected, and the bounded retry continues. No donor pose or unverified contact is enabled.

### Recovery and unfinished acceptance stages

The full original SpriteFright archive has been persisted and independently downloaded back, all64 member CRCs verified. Three closed movie-animation extracts were each actually restored from that remote archive and SHA-checked before593,344,797B of redundant extracts were removed, with both source workers confirming no current dependency. The original ZIP and all environment libraries remain local and intact; restore those exact movie extracts before historical full-shot replay.

Whole16's frozen runtime closure, author code, actual evidence, source/license records and exact Linux engine have a persistent315,544,683B content-addressed archive, SHA256 `6074cd151e6d2cfd4168d29bb9d25adc9f9349f77c2735790d5e59d4d1df2524`. All local archive CRC/blob checks and largest-file extraction passed; the complete native mother and20b are preserved separately. No independent remote readback or full446MB restoration of this new archive is claimed. All original16 inputs remain intact. The generic restore helper passed check-only and small real restore/idempotence/conflict/path-safety tests. These are recoverability facts, not an internal game package.

New17/24b/25 have only native2K author-scene rejection evidence. New4K, realBattle integration, original-speed continuous moving/attacking/riding/large-army video and20/100/250/512-per-side benchmarks are **NOT_RUN** on these rejected sources. No claim of the full requested acceptance loop, final art approval, M5 performance or a new macOS candidate is made. Continue the existing two writers, whole-place/whole-person redesign and exclusive heavy-job guards. Preserve RC24/RC25, real and offscreen battle, old saves, all held new public asset actions and the held PR67 merge. No owner action is currently required for independent work.

## 24. Actual25b together with whole18; rejected production method and withdrawn hand semantics

**The entire image remains ART_FAIL.** The owner-approved reference is still the minimum. Technical completion, fewer visible clothing defects, and successful co-location are not art approval or a new playable candidate.

### Complete25b actual source and actual normal-camera pictures

The new whole garment envelope starts outside the actual dressed pants and inner clothes, rather than inside them or against naked-leg capsules. The robe, thin carrier and iron share a continuous attachment field. The complete native source finished82.98s with887,238,656B peak RSS, preserving the actual32-frame cloth work and original body anatomy.

- Native25b:121,899,711B, SHA256 `3fce11215f183ec7f20c74c4d07cffd6eb060ea85dfd782e0294caa4dc449d92`.
- Single runtime25b:54,207,580B, SHA256 `1c3cee3583e02e7cd4cabeadf4ff6bb433c6adc94f56be276242dedd4bc4689a`.
- Main actual2K PNG:810,785B, SHA256 `4b31fa6937ffa7746f693f8d39a47b68010ce5f8f294f84cd41353f94b2f0767`, captured17:49:25UTC on2026-11-15.

The first runtime export exceeded the original1GiB process guard at1,077,936,128B after80.442s and produced noGLB. Completed readback/snapshot Python objects were then released before export. The same geometry, texture resolution, actions and limit were retained; the retry completed92.56s at1,071,755,264B peak. Both attempts remain recorded. Six actual Godot2K keyposes then completed36.46s/exit0, peak1,006,796,800B. This is Linux/llvmpipe authoring, not smooth wall-clock playback or a Mac test.

The coordinator and writer viewed the normal-camera, close relaxed and thrust frames. The previous large fragmented-skirt/trouser-breakthrough regression is visibly reduced, and the garment layer is more continuous. **The whole figure still fails:** bucket-like skirt volume, shell-like helmet and shoulder construction, coarse pale spearhead, inconsistent limb wrapping and unresolved natural grip/stance. Close diagnostics do not replace normal pixels. Complete26 will continue a whole-body/equipment/grip relationship, not isolated shoulder plates. The frozen25b WIP is allowed only as an explicitly unaccepted actor in the next authoring scene; old20b stays available, and neither is promoted to realBattle.

### Whole18 and25b in the same actual engine scene

Whole18 changed the entire bridgehead arrangement, landform, bridge bearings, masonry/wood layering and ecology, keeping the15m/45-degree/FOV50 camera and original Sun/World contract. It shortened the bridge-to-gate axial space to11.4m and redistributed author-space into a lateral forecourt; this is not an inherited topology or verified512-person deployment capacity. Source closure208 files/437,476,364B, manifest SHA256 `e5f6ed25afb50d28cb282abe2359ea8569df876f78fc17b39bf2272537222bd7`. The original assembly report's staleWHOLE17 label/count is preserved with an explicit correction tied to the actual18 builder and placements, not silently rewritten or globally number-replaced.

One actual native2560×1440/internal-scale1.0 frame with the exact25b runtime was saved17:58:32UTC. Original PNG7,043,887B, SHA256 `2cb4b13ae75609e8e784a05bd164e70f0b8d4dce8f421a9919bca0af2a3f9546`. Measured body148.37px, true15m camera. Process68.525s/exit0; peak3,795,324,928B, minimum global availableRAM2,334,846,976B, minimum disk731,439,104B; no guard. Importer-domain samples12/12. Render counters375,569,992 primitives/2,256 draw calls include passes and are not a full-army benchmark.

This is a real same-scene authoring picture, **notBattle, traversal, video, or same-state17 A/B**: both geometry and actor changed. It is again **ART_FAIL**. A more compact passage and deeper water channel do not overcome continuous same-species grass carpet, visibly inserted bank rocks, flat panel-like upper gate construction and a plain bridge surface. There is no claim of nearing the reference.

### Method correction, not another low-quality procedural draft

Repeatedly regenerating an entire source file does not make parameterized box walls, scattered rocks and repeated grass a professional complete place. That main art route is now stopped; a new numbered box-wall draft is not the next step. The architectural work must use a genuinely complete, editable professional structure/place mother, retaining its construction hierarchy, UVs and material system before coherent Chinese battlefield adaptation. Taking only a roof from a good source and placing it on inferior new walls is not sufficient.

The presently verified complete pavilion is not a fortress gate; the modular pier source is not a complete military bridge. A professional KCISA gate candidate exists publicly, but its anonymous original-package retrieval and package-level licence chain are still not closed. A transient official-portal503 is not evidence of a login requirement. No restricted download is retried, viewer data extracted, account created or fee incurred. The bounded source check is complete: the public model metadata says downloadable and CC BY4.0, but authentication is only a necessary condition for that route, not a source-package guarantee. Existing-account login is held, no new account is created, and the owner is not asked to intervene while independent alternatives remain. This does not stop independent work: existing complete professional native forest-place sets are being evaluated in their compatible original version, retaining actual spatial/ground/tree/understory relationships rather than reducing them to individual inventory objects and random scatter. Their suitability and resource cost still require actual review; no source-library name or licence is an art certificate.

### Important explicit hand-semantic retraction

The earlier densely overlaid hand-label review was wrong. A new unobscured original-surface view exposes the nails and proves that the direction called the palmar normal was actually dorsal. That label confirmation and all dependent26 palm-frame/approximately94-degree/80mm interpretations are **RETRACTED_SEMANTIC_INPUT_ERROR**. Old files and numeric results are retained with visible warnings; their hashes are not quietly replaced. No candidate or donor was applied to a native character or game.

The original skin-parity checks and18 actual fixed-metacarpal-weight surface points intersecting the rod remain independent of that semantic label. Their maximum6.459mm penetration means finger-only motion cannot remove those intersections while the wrist/metacarpals/rod are fixed; it does not prove that all whole-hand grips are impossible. Do not call those points anatomical palm contact without renewed observation. Unobscured nail/palm views and corrected anatomical labels must be reviewed before a new complete hand/wrist/arm/shaft candidate. The original natural mesh and bone lengths remain protected, tolerances are not loosened, and all candidates stayOFF. This correction does not change the25b garment bytes or actual image verdicts.

### Durable stages and boundaries

Whole17 has a persistent345,232,043B exact source/evidence archive, SHA256 `db80bd3fac5da4eb3c4d03e787ca539d7b86669aa0f0e59f0a4f738f571c2a61`:329 logical files/318 unique blobs, all CRC/decoded SHA checks, actual largest54,441,960B extraction and complete helper check-only passed. A separately persisted restore helper passed real small restore/idempotence/conflict/path-safety tests. Full498MB helper restoration and independent remote readback are not claimed; all original17 files remain.

Closed25's164,820,167B archive, SHA256 `b5bae73c5e9b4b7309785ac3a5aa79c4c0964c4d42b835c42b5babde17309832`, was independently downloaded back, all77 members CRC/SHA-verified, and both native/runtime actually extracted and matched to the originals. Only after the writer confirmed26 reads25b were167,889,036B of those two redundant local files reclaimed. All25 code, JSON, original images and exact restore records remain. Historical25/native/runtime and the first failedGLB hand-label replay require restoration first.

Current25b's complete62-file stage has a persistent173,118,702B archive, SHA256 `05fc8c423b89e79c60397edcbe5177e7f12e875a30f315c2d6e99385137ec032`; all original62 hashes and archive member checks passed. All25b originals remain for26/18, and no independent remote readback is claimed. A subsequent advisory explicitly records the withdrawn hand semantics. These are private recovery stages, not public asset promotion, a release or new macOS installer.

New4K, realBattle, continuous original-speed movement/attack/hit/riding/army footage and20/100/250/512-per-side benchmarks remainNOT_RUN on18/25b. No M5 result or owner art acceptance is claimed. Continue independent whole-person and complete-place production while preserving RC24/RC25, actual/offscreen war, old saves, the held new public asset payloads and held PR67 merge.


## 25. Whole26 actual author frames rejected; professional-place instance adaptation and safe recovery

### Complete26 is a real editable source, not accepted art

A new complete26 source integrates the helmet, whole shoulder/chest support, articulated skirt armor, thin arm/leg bindings, shoe boundaries and spear as a single character. Earlier complete-build checks stopped on head/ear/nape/shoulder projection assumptions; their exact failed runs remain. A later check also rejected an inherited skin material simply because its graph used MIX. Read-only verification established that it is a factor-one MULTIPLY and the actual25b export already preserves its texture and RGB factor(.78,.74,.70). This inherited graph was not evidence of broken new equipment. The full diagnostic source was then saved, without overwriting25b or claiming acceptance.

- Complete native26:127,064,997B, SHA256 `7bdb7a7a63be93606f7cae42b247ce67a2d86f42206c7d2b8052598323fee8b5`;39.897s, exit0, peakRSS1,027,121,152B.41 images packed and no linked libraries.229 bones and32 native actions remain. Body/professional-derived component identity comparisons are against the frozen25b input, not a claim that all prior retargeting was lossless relative to upstream art.
- Actual single runtime26:55,159,120B, SHA256 `91194fe484a1785409ed4527d4c0c699a3aca23331885e457aa45154047858c3`; export79.143s, exit0, four experimental runtime clips. The real skin texture pixels and RGB factor match25b; an initial material-comparison name-suffix mismatch is retained and corrected, not hidden by changing materials.
- Six actual Godot author keyposes:2026-11-15 18:39–18:40UTC, native2560×1440/internal1.0, Linux AMD EPYC9V74/llvmpipe software, not M5. Complete capture35.695787s, exit0, peakRSS1,010,335,744B, minimum availableRAM6,252,650,496B, minimum disk479,477,760B. Main camera15.5m radius,45 degrees,FOV50. Actual relaxed body146.05px, walk125.55px, thrust132.84px; do not label every pose150px.
- Main relaxed PNG810,104B, SHA256 `5403906c492dc05188da6c074f63af064ee72e10df8587587fb7dadc6d73323b`; close diagnostic PNG693,658B, SHA256 `f279501288df8f7a0ca56c3e948096b45beb49d57a738e37f55fd36e7265b282`.

The author and coordinator actually viewed these images and reject the **whole character**. Shoulder iron reads as broken folded triangles, the upper garment and supporting layers have broken/overlapping coverage, the skirt remains shell-like, the helmet cap-like, the spear blade becomes an unreadable dark needle at normal distance, and the inherited full grip/stance is not natural. Do not promote26 to the game or call the source-save/export success a visual pass.

The next method change is a whole clothing/support/armor deformation and surface reconstruction, not another isolated cap/shoulder-count/color/lighting tweak. Initial actual native analysis finds shoulder quads already folded by up to78 degrees at rest, before animation, and numerous garment/support/iron triangle intersections at rest. Intersection counts are diagnostic, not penetration-depth or collision acceptance. Iron must not be created by projecting every underlying cloth wrinkle directly into its own surface. The original sources, rig and failed26 remain preserved;27 is separate work.

Corrected hand labels were reviewed with unobscured palm/back surfaces; the earlier c35a confirmation and all dependent frames stay retracted. One bounded new donor-based wrist/finger experiment took32.97s/89 evaluations and was rejected for14.18mm sampled shaft penetration,20.87mm thumb-support gap and self-intersection. A final numpy-int serialization error is retained; only the persisted metrics were recovered, not missing wrist arrays or an invented repeat run. It remainsOFF and was not applied. Failure of this one finite search is not proof that a natural whole grip is impossible.

### Complete professional natural-place intake is not yet a new picture

The selected original professional native grove and its background retain their complete placement and material relationships, not inventory-object scatter. One initially selected corridor was excluded from faithful preview because its active ground/moss mask is absent even in the original package. The selected grove's reachable active image closure is present; missing film-only props are explicitly excluded. This is still a forest-place source, not an existing Chinese gate, military bridge or finished battlefield.

Four bounded whole-place preview attempts produced **no PNG**. Two stopped on global available-memory guards; a terminal-leaf subdivision derivative later exceeded the4GiB process guard even after RAM was safely recovered. A pixel-based ground-moss-density derivative also exceeded that process guard before Cycles samples. Neither hardware guard stop nor a professional source name determines art quality. Do not claim to have seen or accepted the whole original place.

Actual isolated evidence now distinguishes the costs:

- The original ground controller makes the high-resolution complementary patch empty at its original helper scale; the remaining emitter is4,928 faces. Do not blame an assumed full6-level ground subdivision.
- The ground-moss census actually emitted4,904,612 logical points over553.923m² in41.243s. Each picks one of five small moss prototypes, not all five. This is micro-groundcover, not combat entities or a complete-scene memory measurement.
- Scatter groups independently read the original base emitter and union their output; the inspected graphs do not support an exponential re-scatter explanation. Original camera/ground-controller masks do not automatically crop those distributions.
- One original tree-moss volume-base chain actually produced69,622 faces/139,244 triangles in2.014s. It is a separate potential cost, not proven to be the whole4GiB failure.
- Recursive non-evaluating placement counts found24,817 collection-instance occurrences and50,843 explicit object occurrences from323 top-level placements, with1,145 unique datablocks. Datablocks, logical scatter points and actual rendered instances are different quantities.

The next work is one coherent near/mid/far screen-space representation and instance budget for the complete native place, preserving the full editable source and making all culling/density/prototype changes explicit. Original Scene/ViewLayer exclusion flags are being checked because linking a library root into a fresh scene is not automatically equivalent to the original visible assembly. Do not keep performing blind whole-scene retries or claim an unseen source is faithful simply because seeds and transforms were retained.

### Recovery, published scope and still-unrun stages

Four older RAM-resident archive copies totaling1,329,013,881B were independently retrieved from persistent storage, matched by full archive SHA, checked by member CRC/decoded SHA and actual source extraction, then removed only after both active writers confirmed no dependency. Exact source members restored in the checks included241,182,974B and248,712,034B tree scenes,79,652,363B imported terrain and36,690,083B native character. Unique current source data and persistent recovery copies remain; historical replay must materialize the protected exact archives first. No resource guard or art acceptance criterion was lowered.

Whole18 now has an exact21,297,157B delta archive, SHA256 `336a784b8f2b52c76e0529a51d18138a6f6029eebba28f243e1c00bf2fc3d106`, explicitly requiring the existing17 source and25b character archives. It covers319 logical files/493,729,398B, with44 new blobs/67,481,138B. All current source hashes and new decoded blobs were checked; the46,311,340B new geometry was actually extracted. A small three-archive helper fixture passed restoration, repeat/conflict/hash/path-safety checks. Full production-chain restoration and independent remote readback are not claimed, and all18 originals remain.

The exact native26 is privately persisted, original retained. Its106-file/62,378,102B author/runtime/evidence companion is separately persisted as50,887,041B, SHA256 `0c7a5db4153f524282faaab3257f0f6f12acbdaa12e43b1170b00fd71fbc42b0`, with all local decoded CRC/SHA checks and source rehashes passed. A small source extraction was checked, but independent remote readback and complete restoration are not claimed; all original inputs remain. Its native and25b parent are explicit separate dependencies. These recoverability stages are not a new installer, public asset approval or art acceptance.

Only the recovery document is published by this checkpoint. The latest actual whole-scene image is still18 with25b;26 has isolated actual author keyposes only. New4K, realBattle integration, original-speed complete-action/riding/large-army footage,20/100/250/512-per-side benchmarks and realM5 testing remainNOT_RUN for these rejected sources. Preserve RC24/RC25, genuine and offscreen combat, legacy saves, all held new public asset payloads and the held PR67 merge. Continue the existing unique writers; no new account, fee, owner-computer access or owner screening of failed drafts is required.


## 26. First complete professional-grove preview rendered, reviewed and rejected; whole27 remains in production

### A real new source picture, explicitly not a game picture

After a fifth default-guard attempt stopped at 4,325,183,488 B without a PNG, a single offline preview was authorized with a 4.5 GiB process cap. Its other limits remained global available memory at least 2 GiB, disk at least 350 MiB and 180 seconds. This authorization applied only to this one source preview and is now exhausted; it is not a general increase for subsequent work.

The same complete representation01 derivative finished on 2026-11-15 after starting at 19:01:30 UTC. Actual terminal result: exit 0, 169.442663 seconds, peak process-group RSS 4,641,697,792 B (4.323 GiB), minimum global available memory 2,729,746,432 B and minimum disk 690,847,744 B. No guard fired. Original native source SHA remained unchanged. Cycles completed four of eight requested samples before its existing 120-second render time limit, so Monte Carlo grain must not be called an original texture defect.

- Original PNG: 2560 × 1440, 8,453,216 B, SHA256 `ddcc6711155854e2ca2428f285c52895c408bb2c80061cc0f1b7a7e366d0c4ac`.
- Source: compatible Blender 3.1.2, complete selected professional grove and native background, not the entire movie Scene.
- Camera: 15.000001 m radius, approximately 45-degree optical pitch, FOV50. A 1.76 m calibration segment projects to 125.01 px; there was no actual character whose bounding box could be measured.
- Representation changes are explicit: shared near/mid/far native leaf/branch/volume detail, regenerated reduced micro-groundcover and original material values. Complete macro placements remain, but this is not an unchanged-source fidelity certificate.

Both the author and coordinator actually viewed the resulting complete image. **The whole proposed environment fails.** Low-hanging forest crowns occlude almost the entire normal tactical view, the exposed clearing is too small, and a monumental hollow tree has a fairy-tale setting identity. This is not a readable military approach, bridgehead or battle composition. No complete Chinese gate or military bridge has appeared. The native ecology remains useful as an editable edge/background source, but the closed forest stage must not be mass-converted and called an accepted battlefield.

The next environment work physically reconstructs a complete tactical clearing, shoreline and bridge-to-gate approach under the same normal camera. It must retain coherent natural stand relationships at the edges, not hide crowns or shrink soldiers to fake suitability. Structural placeholders are explicitly unfinished and do not count as a successful new art picture. The previous parameterized box-wall/scatter route stays stopped. No new Godot19 picture exists at this checkpoint.

### Whole27 is a structural production change, not another accepted outfit

Actual native26 analysis separated two independent causes: iron already folds at rest because it follows garment creases, while late runtime weight truncation adds an export-layer deformation mismatch. The original professional 1,373-point garment control surface, its multiresolution structure and 566-point cage remain available. Whole27 returns to that continuous coarse fitting structure, fixes the derived runtime-weight contract before layer fitting, and uses separate smooth support surfaces and whole-plate motion instead of copying every cloth wrinkle into rigid iron.

The first complete27 source batch actually ran 23.547 seconds, peak approximately 877 MB, without a resource guard. It stopped before saving a native source because a closed chart was requested across the real open front skirt slit. That failure is preserved; the implementation is being corrected to keep the original opening and join only real side seams. The reported sub-micrometre fitting residual demonstrates execution of that fit, not natural clothing or art acceptance. There is no saved27 runtime or actual27 picture yet. The rejected hand donor remains OFF, not silently applied.

### Exact recovery and current scope

The complete77-file grove preview/code/failure/evidence companion is privately persisted: 8,926,928 B, SHA256 `33fb75213200c5d030999d8ad4e6495b7776a0f7d1e670f3479405a8bbd73dec`. All local archive CRC, decoded-member SHA and original-source rechecks passed. It includes the unmodified PNG, but the protected original source package and official Blender binary remain explicit separate dependencies. No independent remote readback or full source restoration is claimed. All current source files remain.

Closed24b and25b native duplicates were reclaimed only after fresh independent retrieval of their persistent archives, full archive/member verification, actual native extraction and exact original SHA equality, plus confirmation that27 reads26 and the whole18 runtime reads the retained25b GLB. This freed 233,202,230 B. Native24b (111,302,519 B, SHA `8b0eef5aac2ffda87956cf43c45c8563a1d71fd449c15085027084e3e6951aef`) and native25b (121,899,711 B, SHA `3fce11215f183ec7f20c74c4d07cffd6eb060ea85dfd782e0294caa4dc449d92`) now require their recorded exact restoration before historical replay. Current26 and the exact25b runtime remain local and protected; no unique work was discarded.

Only this recovery document is published. Current actual Godot whole-scene evidence is still rejected18 with25b, and the latest isolated actual Godot character is rejected26. The new grove picture is an offline source preview, not realBattle, not continuous motion, not a benchmark or installer. New 4K, realBattle integration, original-speed complete-action/riding/large-army footage, 20/100/250/512-per-side benchmarks and real M5 testing remain NOT_RUN for the new sources. RC24/RC25, genuine/offscreen war, old saves and all held merges/assets remain protected.
