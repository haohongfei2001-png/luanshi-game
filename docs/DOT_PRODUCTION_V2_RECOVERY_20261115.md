# Dot whole-scene production-v2 recovery — 2026-11-15 UTC

**State: ART_REBUILD_REQUIRED. No production-v2 playable art candidate has passed. This is a recovery checkpoint, not a release or acceptance report.**

This checkpoint supersedes the *next-art-action* recommendations in the older regional 04/05/06/07 experiments. It preserves their source and evidence. Read the current main `AGENTS.md`, `OWNER_MOBA_CAMERA_AND_ART_AUTHORITY_20261114.md`, the owner's latest matte-material authority in draft PR #67, the original Dot handoff, and Issue #12 together with this file. Codex remains **PAUSED**; Dot continues the authorized cloud development.

## 1. The owner's correction and the actual method change

The owner rejected the **entire** image: people, environment, buildings, materials, lighting and composition. The concept/reference is a minimum quality line, not proof that the game is close. Do not keep polishing the old rough terrain or geometry, shrink people to frame a whole army, or treat test counts and partial model changes as art progress.

The first production-v2 whole-scene authoring previews were also self-rejected. In particular, the terrain003 ground still used interpolated vertex colors with only a small multiplicative contribution from baked professional ground color. Replacing the bridge and trees did not make that a mature whole landscape. This method, including its pending variant, was stopped before a new visual GPU run.

The active reconstruction now requires:
- One coherent **editable mother scene**, with the full terrain, banks, bridge, fortress, background and ecology authored together. Derive visible geometry, walkable surfaces, actual obstacles, portals, deployment areas and semantic objectives from that same source. Do not force a mature scene back into the old global `Ground` coordinate boxes.
- Use the mature source ground's usable full form and original Dirt/Moss material system as a real production base, with documented stylistic adaptation and baking, not a token color overlay. Original film assets and licensing are an input, never a quality certificate.
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
